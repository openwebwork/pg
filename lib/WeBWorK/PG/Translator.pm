################################################################################
# WeBWorK mod_perl (c) 2000-2012 The Open WeBWorK Project (openwebwork.org)
# $Id$
################################################################################

package WeBWorK::PG::Translator;

use strict;
use warnings;
use Opcode;
use WWSafe;
use Net::SMTP;
use WeBWorK::PG::IO;

#use PadWalker;     # used for processing error messages
#use Data::Dumper;


# loading GD within the Safe compartment has occasionally caused infinite recursion
# Putting these use statements here seems to avoid this problem
# It is not clear that this is essential once things are working properly.
#use Exporter;
#use DynaLoader;


=head1 NAME

WeBWorK::PG::Translator - Evaluate PG code and evaluate answers safely

=head1 SYNPOSIS

    my $pt = new WeBWorK::PG::Translator;      # create a translator;
    $pt->environment(\%envir);      # provide the environment variable for the problem
    $pt->initialize();              # initialize the translator
    $pt-> set_mask();               # set the operation mask for the translator safe compartment
    $pt->source_string($source);    # provide the source string for the problem

    $pt -> unrestricted_load("${courseScriptsDirectory}PG.pl");
                                    # load the unprotected macro files
                                    # these files are evaluated with the Safe compartment wide open
                                    # other macros are loaded from within the problem using loadMacros

    $pt ->translate();              # translate the problem (the out following 4 pieces of information are created)
    
    $PG_PROBLEM_TEXT_ARRAY_REF = $pt->ra_text();              # output text for the body of the HTML file (in array form)
    $PG_PROBLEM_TEXT_REF = $pt->r_text();                     # output text for the body of the HTML file
    $PG_HEADER_TEXT_REF = $pt->r_header;#\$PG_HEADER_TEXT;    # text for the header of the HTML file
    $PG_POST_HEADER_TEXT_REF = $pt->r_post_header
    $PG_ANSWER_HASH_REF = $pt->rh_correct_answers;            # a hash of answer evaluators
    $PG_FLAGS_REF = $pt ->rh_flags;                           # misc. status flags.

    $pt -> process_answers(\%inputs);    # evaluates all of the answers using submitted answers from %input
    
    my $rh_answer_results = $pt->rh_evaluated_answers;  # provides a hash of the results of evaluating the answers.
    my $rh_problem_result = $pt->grade_problem;         # grades the problem using the default problem grading method.

=head1 DESCRIPTION

This module defines an object which will translate a problem written in the Problem Generating (PG) language

=cut

=head2 be_strict

This creates a substitute for C<use strict;> which cannot be used in PG problem
sets or PG macro files.  Use this way to imitate the behavior of C<use strict;>

	BEGIN {
		be_strict(); # an alias for use strict.
		             # This means that all global variable
		             # must contain main:: as a prefix.
	}

=cut

BEGIN {
	# allows the use of strict within macro packages.
	sub be_strict {
		require 'ww_strict.pm';
		strict::import();
	}
	
	# also define in Main::, for PG modules.
	sub Main::be_strict { &be_strict }
}

=head2 evaluate_modules

	Usage:  $obj -> evaluate_modules('WWPlot', 'Fun', 'Circle');
	        $obj -> evaluate_modules('reset');

Adds the modules WWPlot.pm, Fun.pm and Circle.pm in the courseScripts directory to the list of modules
which can be used by the PG problems.  The keyword 'reset' or 'erase' erases the list of modules already loaded

=cut


sub evaluate_modules {
	my $self = shift;
	my @modules = @_;
	local $SIG{__DIE__} = "DEFAULT"; # we're going to be eval()ing code
	foreach (@modules) {
		#warn "attempting to load $_\n";
		# ensure that the name is in fact a base name
		s/\.pm$// and warn "fixing your broken package name: $_.pm => $_";
		# call runtime_use on the package name
		# don't worry -- runtime_use won't load a package twice!
		#eval { runtime_use $_ };                   # 
		eval "package Main; require $_; import $_"; # change for WW1
		warn "Failed to evaluate module $_: $@" if $@;
		# record this in the appropriate place
		push @{$self->{ra_included_modules}}, "\%${_}::";
	}
}
#      old code for runtime_use
# 		if ( -r  "${courseScriptsDirectory}${module_name}.pm"   ) {
# 			eval(qq! require "${courseScriptsDirectory}${module_name}.pm";  import ${module_name};! );
# 			warn "Errors in including the module ${courseScriptsDirectory}$module_name.pm $@" if $@;
# 		} else {
# 			eval(qq! require "${module_name}.pm";  import ${module_name};! );
# 			warn "Errors in including either the module $module_name.pm or ${courseScriptsDirectory}${module_name}.pm $@" if $@;
# 		}
=head2 load_extra_packages

	Usage:  $obj -> load_extra_packages('AlgParserWithImplicitExpand',
	                                    'Expr','ExprWithImplicitExpand');

Loads extra packages for modules that contain more than one package.  Works in conjunction with
evaluate_modules.  It is assumed that the file containing the extra packages (along with the base
pachage name which is the same as the name of the file minus the .pm extension) has already been
loaded using evaluate_modules
=cut

sub load_extra_packages{
	my $self = shift;
	my @package_list = @_;
	my $package_name;
	
	foreach (@package_list) {
		# ensure that the name is in fact a base name
		s/\.pm$// and warn "fixing your broken package name: $_.pm => $_";
		# import symbols from the extra package
		import $_;
		warn "Failed to evaluate module $_: $@" if $@;
		# record this in the appropriate place
		push @{$self->{ra_included_modules}}, "\%${_}::";
	}
}

=head2  new
	Creates the translator object.

=cut


sub new {
	my $class = shift;
	my $safe_cmpt = new WWSafe; #('PG_priv');
	my $self = {
	    preprocess_code           =>  \&default_preprocess_code,
	    postprocess_code           => \&default_postprocess_code,
		envir                     => undef,
		PG_PROBLEM_TEXT_ARRAY_REF => [],
		PG_PROBLEM_TEXT_REF       => 0,
		PG_HEADER_TEXT_REF        => 0,
		PG_POST_HEADER_TEXT_REF   => 0,
		PG_ANSWER_HASH_REF        => {},
		PG_FLAGS_REF              => {},
		rh_pgcore                 => undef,    # ref to PGcore object
		safe                      => $safe_cmpt,
		safe_compartment_name     => $safe_cmpt->root,
		errors                    => "",
		source                    => "",
		rh_correct_answers        => {},
		rh_student_answers        => {},
		rh_evaluated_answers      => {},
		rh_problem_result         => {},
		rh_problem_state          => {
			recorded_score       => 0, # the score recorded in the data base
			num_of_correct_ans   => 0, # the number of correct attempts at doing the problem
			num_of_incorrect_ans => 0, # the number of incorrect attempts
		},
		rf_problem_grader         => \&std_problem_grader,
		rf_safety_filter          => \&safetyFilter,
		# ra_included_modules is now populated independantly of @class_modules:
		ra_included_modules       => [], # [ @class_modules ],
		#rh_directories            => {},
	};
	bless $self, $class;
}

=pod

(b) The following routines defined within the PG module are shared:

	&be_strict
	&read_whole_problem_file
	&convertPath
	&surePathToTmpFile
	&fileFromPath
	&directoryFromPath
	&createFile

	&includePGtext

	&PG_answer_eval
	&PG_restricted_eval

	&send_mail_to
	&PGsort

In addition the environment hash C<%envir> is shared.  This variable is unpacked
when PG.pl is run and provides most of the environment variables for each problem
template.

=for html

	<A href =
	"${Global::webworkDocsURL}techdescription/pglanguage/PGenvironment.html"> environment variables</A>

=cut


=pod

(c) Sharing macros:

The macros shared with the safe compartment are

	'&read_whole_problem_file'
	'&convertPath'
	'&surePathToTmpFile'
	'&fileFromPath'
	'&directoryFromPath'
	'&createFile'
	'&PG_answer_eval'
	'&PG_restricted_eval'
	'&be_strict'
	'&send_mail_to'
	'&PGsort'
	'&dumpvar'
	'&includePGtext'

=cut

# SHARE variables and routines with safe compartment
# 
# Some symbols are defined here (or in the IO module), and used inside the safe
# compartment. Under WeBWorK 1.x, functions defined here had access to the
# Global:: namespace, which contained course-specific data such things as
# directory locations, the address of the SMTP server, and so on. Under WeBWorK
# 2, there is no longer a global namespace. To get around this, IO functions
# which need access to course-specific data are now defined in the IO.pl macro
# file, which has access to the problem environment. Several entries have been
# added to the problem environment to support this move.
# 


# Useful for timing portions of the translating process
# The timer $WeBWorK::timer is defined in the module WeBWorK.pm
# You must make sure that the code in that script for initialzing the 
# timer is active.

sub time_it {
	my $msg = shift;	
	$WeBWorK::timer->continue("PG macro:". $msg) if defined($WeBWorK::timer);
}

my %shared_subroutine_hash = (
	'time_it'                  => __PACKAGE__,
	'&PG_answer_eval'          => __PACKAGE__,
	'&PG_restricted_eval'      => __PACKAGE__,
	'&PG_macro_file_eval'       => __PACKAGE__,     
	'&be_strict'               => __PACKAGE__,
	'&PGsort'                  => __PACKAGE__,
	'&dumpvar'                 => __PACKAGE__,
	%WeBWorK::PG::IO::SHARE, # add names from WeBWorK::PG::IO and WeBWorK::PG::IO::*
);

sub initialize {
    my $self = shift;
    my $safe_cmpt = $self->{safe};
    #print "initializing safeCompartment",$safe_cmpt -> root(), "\n";

    $safe_cmpt -> share(keys %shared_subroutine_hash);
    no strict;
    local(%envir) = %{ $self ->{envir} };
	$safe_cmpt -> share('%envir');
	#local($rf_answer_eval) = sub { $self->PG_answer_eval(@_); };
	#local($rf_restricted_eval) = sub { $self->PG_restricted_eval(@_); };
	local($PREPROCESS_CODE) = sub {&{$self->{preprocess_code}} ( @_ ) };
	$safe_cmpt -> share ('$PREPROCESS_CODE'); # for the benefit of IO::includePGtext()
	#$safe_cmpt -> share('$rf_answer_eval');
	#$safe_cmpt -> share('$rf_restricted_eval');
	use strict;
    	
	$safe_cmpt -> share_from('main', $self->{ra_included_modules} );
		# the above line will get changed when we fix the PG modules thing. heh heh.
}


################################################################
#  Preloading the macro files
################################################################

#  Preloading the macro files can significantly speed up the translation process.
#  Files are read into a separate safe compartment (typically Safe::Root1::)
#  This means that all non-explicit subroutine references and those explicitly prefixed by main::
#  are prefixed by Safe::Root1::
#  These subroutines (but not the constants) are then explicitly exported to the current
#  safe compartment Safe::Rootx::

#  Although it is not large, it is important to import PG.pl into the 
#  cached safe compartment as well.  This is because a call in PGbasicmacros.pl to NEW_ANSWER_NAME
#  which is defined in PG.pl would actually be a call to Safe::Root1::NEW_ANSWER_NAME since
#  PGbasicmacros is compiled into the SAfe::Root1:: compartment.  If PG.pl has only been compiled into
#  the current Safe compartment, this call will fail.  There are many calls between PG.pl,
#  PGbasicmacros and PGanswermacros so it is easiest to have all of them defined in Safe::Root1::
#  There subroutines are still available in the current safe compartment.
#  Sharing the hash %Safe::Root1:: in the current compartment means that any references to Safe::Root1::NEW_ANSWER_NAME
#  will be found as long as NEW_ANSWER_NAME has been defined in Safe::Root1::
#  
#  Constants and references to subroutines in other macro files have to be handled carefully in preloaded files.
#  For example a call to main::display_matrix (defined in PGmatrixmacros.pl) will become Safe::Root1::display_matrix and
#  will fail since PGmatrixmacros.pl is loaded only into the current safe compartment Safe::Rootx::.  
#  The value of main:: has to be evaluated at runtime in order to make this work.  Hence  something like
#  my $temp_code  = eval('\&main::display_matrix');
#  &$temp_code($matrix_object_to_be_displayed);
#  in PGanswermacros.pl
#  would reference the run time value of main::, namely Safe::Rootx::
#  There may be a clearer or more efficient way to obtain the runtime value of main::


sub pre_load_macro_files {
    time_it("Begin pre_load_macro_files");
	my $self                = shift;
	my $cached_safe_cmpt    = shift;
	my $dirName             = shift;
	my @fileNameList        = @_;
	my $debugON			    = 0;    # This helps with debugging the loading of macro files

################################################################
#    prepare safe_cache
################################################################
	$cached_safe_cmpt -> share(keys %shared_subroutine_hash);
    no strict;
    local(%envir) = %{ $self ->{envir} };
	$cached_safe_cmpt -> share('%envir');
	use strict;
    $cached_safe_cmpt -> share_from('main', $self->{ra_included_modules} );
    $cached_safe_cmpt->mask(Opcode::full_opset());  # allow no operations
    $cached_safe_cmpt->permit(qw(   :default ));
    $cached_safe_cmpt->permit(qw(time));  # used to determine whether solutions are visible.
	$cached_safe_cmpt->permit(qw( atan2 sin cos exp log sqrt ));

	# just to make sure we'll deny some things specifically
	$cached_safe_cmpt->deny(qw(entereval));
	$cached_safe_cmpt->deny(qw (  unlink symlink system exec ));
	$cached_safe_cmpt->deny(qw(print require));

################################################################
#    read in macro files
################################################################

	foreach my $fileName (@fileNameList)   {
	    # determine whether the file has already been loaded by checking for
	    # subroutine named _${macro_file_name}_init
		my $macro_file_name = $fileName;
		$macro_file_name =~s/\.pl//;  # trim off the extension
		$macro_file_name =~s/\.pg//;  # sometimes the extension is .pg (e.g. CAPA files)
		my $init_subroutine_name      = "_${macro_file_name}_init";
        my $macro_file_loaded = defined(&{$cached_safe_cmpt->root."::$init_subroutine_name"}) ? 1 : 0; 
	
	    
		if ( $macro_file_loaded  )     {
			warn "$macro_file_name is already loaded" if $debugON;
		 }else {
			warn "reading and evaluating $macro_file_name from $dirName/$fileName" if $debugON;
			### read in file
			my $filePath = "$dirName/$fileName";
			local(*MACROFILE);
			local($/);
			$/ = undef;   # allows us to treat the file as a single line
			open(MACROFILE, "<$filePath") || die "Cannot open file: $filePath";
			my $string = <MACROFILE>;
			close(MACROFILE);
			

################################################################
#    Evaluate macro files
################################################################
#    FIXME  The following hardwired behavior should be modifiable
#    either in the procedure call or in global.conf:
# 
#    PG.pl, IO.pl are loaded without restriction;
#    all other files are loaded with restriction
#     
			# construct a regex that matches only these three files safely
			my @unrestricted_files = (); #  no longer needed? FIXME w/PG.pl IO.pl/;
			my $unrestricted_files = join("|", map { quotemeta } @unrestricted_files);
			
			my $store_mask; 
			if ($fileName =~ /^($unrestricted_files)$/) {
	        	$store_mask = $cached_safe_cmpt->mask();
				$cached_safe_cmpt ->mask(Opcode::empty_opset());
	        } 			
			$cached_safe_cmpt -> reval('BEGIN{push @main::__eval__,__FILE__}; package main; ' .$string);
			warn "preload Macros: errors in compiling $macro_file_name:<br/> $@" if $@;
			$self->{envir}{__files__}{$cached_safe_cmpt->reval('pop @main::__eval__')} = $filePath;
			if ($fileName =~ /^($unrestricted_files)$/) {
	        	$cached_safe_cmpt ->mask($store_mask);
	        	warn "mask restored after $fileName" if $debugON;
	        }
			

		}
 	}
 	
################################################################################
# load symbol table
################################################################################
	warn "begin loading symbol table "  if $debugON;
	no strict 'refs';
	my %symbolHash  = %{$cached_safe_cmpt->root.'::'};
	use strict 'refs';
	my @subroutine_names;

	foreach my $name (keys %symbolHash) {
		# weed out internal symbols
		next if $name =~ /^(INC|_|__ANON__|main::)$/;
		if ( defined(&{*{$symbolHash{$name}}})  )  {
#			    warn "subroutine $name" if $debugON;;
			push(@subroutine_names, "&$name");		
		}	   
	}
	
	warn "Loading symbols into active safe compartment:<br/> ", join(" ",sort @subroutine_names) if $debugON;
	$self->{safe} -> share_from($cached_safe_cmpt->root,[@subroutine_names]);
	
	# Also need to share the cached safe compartment symbol hash in the current safe compartment. 
	# This is necessary because the macro files have been read into the cached safe compartment
	# So all subroutines have the implied names  Safe::Root1::subroutine
	# When they call each other we need to make sure that they can reach each other
	# through the Safe::Root1 symbol table.

	$self->{safe} -> share('%'.$cached_safe_cmpt->root.'::');
	warn 'Sharing '.'%'. $cached_safe_cmpt->root. '::'  if $debugON;
	time_it("End pre_load_macro_files");
	# return empty string.
	'';
}

sub environment{
	my $self = shift;
	my $envirref = shift;
	if ( defined($envirref) )  {
		if (ref($envirref) eq 'HASH') {
			%{ $self -> {envir} } = %$envirref;
		} else {
			$self ->{errors} .= "ERROR: The environment method for PG_translate objects requires a reference to a hash";
		}
	}
	$self->{envir} ; #reference to current environment
}

=head2   Safe compartment pass through macros



=cut

sub mask {
	my $self = shift;
	my $mask = shift;
	my $safe_compartment = $self->{safe};
	$safe_compartment->mask($mask);
}
sub permit {
	my $self = shift;
	my @array = shift;
	my $safe_compartment = $self->{safe};
	$safe_compartment->permit(@array);
}
sub deny {

	my $self = shift;
	my @array = shift;
	my $safe_compartment = $self->{safe};
	$safe_compartment->deny(@array);
}
sub share_from {
	my $self = shift;
	my $pckg_name = shift;
	my $array_ref =shift;
	my $safe_compartment = $self->{safe};
	$safe_compartment->share_from($pckg_name,$array_ref);
}

sub source_string {
	my $self = shift;
	my $temp = shift;
	my $out;
	if ( ref($temp) eq 'SCALAR') {
		$self->{source} = $$temp;
		$out = $self->{source};
	} elsif ($temp) {
		$self->{source} = $temp;
		$out = $self->{source};
	}
	$self -> {source};
}

sub source_file {
	my $self = shift;
	my $filePath = shift;
 	local(*SOURCEFILE);
 	local($/);
 	$/ = undef;   # allows us to treat the file as a single line
 	my $err = "";
 	if ( open(SOURCEFILE, "<$filePath") ) {
 		$self -> {source} = <SOURCEFILE>;
 		close(SOURCEFILE);
 	} else {
 		$self->{errors} .= "Can't open file: $filePath";
 		croak( "Can't open file: $filePath\n" );
 	}



 	$err;
}



sub unrestricted_load {
	my $self = shift;
	my $filePath = shift;
	my $safe_cmpt = $self ->{safe};
	my $store_mask = $safe_cmpt->mask();
	$safe_cmpt->mask(Opcode::empty_opset());
	my $safe_cmpt_package_name = $safe_cmpt->root();
	
	my $macro_file_name = fileFromPath($filePath);
	$macro_file_name =~s/\.pl//;  # trim off the extenstion
	my $export_subroutine_name = "_${macro_file_name}_export";
	my $init_subroutine_name = "${safe_cmpt_package_name}::_${macro_file_name}_init";

	my $local_errors = "";
	no strict;

	my $init_subroutine  = eval { \&{$init_subroutine_name} };
	warn "No init routine for $init_subroutine_name: $@" if  $debugON and $@;
	use strict;
    my $macro_file_loaded = ref($init_subroutine) =~ /CODE/;

	#print STDERR "$macro_file_name   has not yet been loaded\n" unless $macro_file_loaded;	
	unless ($macro_file_loaded) {
		## load the $filePath file
		## Using rdo insures that the $filePath file is loaded for every problem, allowing initializations to occur.
		## Ordinary mortals should not be fooling with the fundamental macros in these files.  
		my $local_errors = "";
		if (-r $filePath ) {
			my $rdoResult = $safe_cmpt->rdo($filePath);
            #warn "unrestricted load:  $filePath\n";
			$local_errors ="\nThere were problems compiling the file:\n $filePath\n $@\n" if $@;
			$self ->{errors} .= $local_errors if $local_errors;
			use strict;
		} else {
			$local_errors = "Can't open file $filePath for reading\n";
			$self ->{errors} .= $local_errors if $local_errors;
		}
		$safe_cmpt -> mask($store_mask);
		
	}
	# try again to define the initization subroutine
	$init_subroutine  = eval { \&{"$init_subroutine_name"} };
	$macro_file_loaded	= ref($init_subroutine) =~ /CODE/;
	if ( $macro_file_loaded ) {

		    #warn "unrestricted load:  initializing $macro_file_name  $init_subroutine" ;
		    &$init_subroutine();
	}
	$local_errors .= "\nUnknown error.  Unable to load $filePath\n" if ($local_errors eq '' and not $macro_file_loaded);
	#print STDERR "$filePath is properly loaded\n\n" if $macro_file_loaded;
	$local_errors;
}

sub nameSpace {
	my $self = shift;
	$self->{safe}->root;
}

sub a_text {
	my $self  = shift;
	@{$self->{PG_PROBLEM_TEXT_ARRAY_REF}};
}

sub header {
	my $self = shift;
	${$self->{PG_HEADER_TEXT_REF}};
}

sub post_header {
	my $self = shift;
	${$self->{PG_POST_HEADER_TEXT_REF}};
}
sub h_flags {
	my $self = shift;
	%{$self->{PG_FLAGS_REF}};
}

sub rh_flags {
	my $self = shift;
	$self->{PG_FLAGS_REF};
}
sub h_answers{
	my $self = shift;
	%{$self->{PG_ANSWER_HASH_REF}};
}

sub ra_text {
	my $self  = shift;
    $self->{PG_PROBLEM_TEXT_ARRAY_REF};

}

sub r_text {
	my $self  = shift;
    $self->{PG_PROBLEM_TEXT_REF};
}

sub r_header {
	my $self = shift;
	$self->{PG_HEADER_TEXT_REF};
}
sub r_post_header {
	my $self = shift;
	$self->{PG_POST_HEADER_TEXT_REF};
}

sub rh_correct_answers {
	my $self = shift;
	my @in = @_;
	return $self->{rh_correct_answers} if @in == 0;

	if ( ref($in[0]) eq 'HASH' ) {
		$self->{rh_correct_answers} = { %{ $in[0] } }; # store a copy of the hash
	} else {
		$self->{rh_correct_answers} = { @in }; # store a copy of the hash
	}
	$self->{rh_correct_answers}
}

sub rf_problem_grader {
	my $self = shift;
	my $in = shift;
	return $self->{rf_problem_grader} unless defined($in);
	if (ref($in) =~/CODE/ ) {
		$self->{rf_problem_grader} = $in;
	} else {
		die "ERROR: Attempted to install a problem grader which was not a reference to a subroutine.";
	}
	$self->{rf_problem_grader}
}


sub errors{
	my $self = shift;
	$self->{errors};
}



=head2  set_mask






(e) Now we close the safe compartment.  Only the certain operations can be used
within PG problems and the PG macro files.  These include the subroutines
shared with the safe compartment as defined above and most Perl commands which
do not involve file access, access to the system or evaluation.

Specifically the following are allowed

	time()
		# gives the current Unix time
		# used to determine whether solutions are visible.
	atan, sin cos exp log sqrt
		# arithemetic commands -- more are defined in PGauxiliaryFunctions.pl

The following are specifically not allowed:

	eval()
	unlink, symlink, system, exec
	print require



=cut

##############################################################################

	        ## restrict the operations allowed within the safe compartment

sub set_mask {
	my $self = shift;
	my $safe_cmpt = $self ->{safe};
    $safe_cmpt->mask(Opcode::full_opset());  # allow no operations
    $safe_cmpt->permit(qw(   :default ));
    $safe_cmpt->permit(qw(time));  # used to determine whether solutions are visible.
	$safe_cmpt->permit(qw( atan2 sin cos exp log sqrt ));

	# just to make sure we'll deny some things specifically
	$safe_cmpt->deny(qw(entereval));
	$safe_cmpt->deny(qw (  unlink symlink system exec ));
	$safe_cmpt->deny(qw(print require));
}

############################################################################

=head2  PG_errorMessage

This routine processes error messages by fixing file names and adding
traceback information.  It loops through the function calls via
caller() in order to give more information about where the error
occurred.  Since the loadMacros() files and the .pg file itself are
handled via various kinds of eval calls, the caller() information does
not contain the file names.  So we have saved them in the
$main::__files__ hash, which we look up here and use to replace the
(eval nnn) file names that are in the caller stack.  We shorten the
filenames by removing the templates or root directories when possible,
so they are easier to read.

We skip any nested calls to Parser:: or Value:: so that these act more like
perl built-in functions.

We stop when we find a routine in the WeBWorK:: package, or an __ANON__
routine, in order to avoid reporting the PG translator calls that
surround the pg file.  Finally, there is usually one more eval before
that, so we remove it as well.

File names are shortened, when possible, by replacing the templates
directory with [TMPL], the WeBWorK root directory by [WW] and
the PG root directory by [PG].
  
=cut

sub PG_errorMessage {
  my $return = shift; my $frame = 2; # return can be 'message' or 'traceback'
  my $message = join("\n",@_); $message =~ s/\.?\s+$//;
  my $files = eval ('$main::__files__'); $files = {} unless $files;
  my $tmpl = $files->{tmpl} || '$';
  my $root = $files->{root} || '$';
  my $pg   = $files->{pg}   || '$';
  #
  #  Fix initial message file names
  #
  $message =~ s! $tmpl! [TMPL]!g; $message =~ s! $root! [WW]!g; $message =~ s! $pg! [PG]!g;
  $message =~ s/(\(eval \d+\)) (line (\d+))/$2 of $1/;
  while ($message =~ m/of (?:file )?(\(eval \d+\))/ && defined($files->{$1})) {
    my $name = $files->{$1};
    $name =~ s!^$tmpl![TMPL]!; $name =~ s!^$root![WW]!; $name =~ s!^$pg![PG]!;
    $message =~ s/\(eval \d+\)/$name/g;
  }
  #
  #  Return just the message if that's all we want, or
  #   if the message already includes a stack trace
  #
  return $message."\n" if $return eq 'message' || $message =~ m/\n   Died within/;
  #
  #  Look through caller stack for traceback information
  #
  my @trace = ($message);
  my $skipParser = (caller(3))[3] =~ m/^(Parser|Value)::/;
  while (my ($pkg,$file,$line,$subname) = caller($frame++)) {
    last if ($subname =~ m/^(Safe::reval|main::__ANON__)/);
    next if $skipParser && $subname =~ m/^(Parser|Value)::/;  # skip Parser and Value calls
    next if $subname =~ m/__ANON__/;
    $file = $files->{$file} || $file;
    $file =~ s!^$tmpl![TMPL]!; $file =~ s!^$root![WW]!; $file =~ s!^$pg![PG]!;
    $message =  "   from within $subname called at line $line of $file";
    push @trace, $message; $skipParser = 0;
  }
  splice(@trace,1,1) while $trace[1] && $trace[1] =~ m/within \(eval\)/;
  pop @trace while $trace[-1] && $trace[-1] =~ m/within \(eval\)/;
  $trace[1] =~ s/   from/   Died/ if $trace[1];
  #
  #  report the full traceback
  #
  return join("\n",@trace,'');
}

=head2 PG_undef_var_check

=pod

 Produces warnings of this type in order to help you guess which local variable is undefined
 Warning: Use of uninitialized value in concatenation (.) or string at mpu.cgi line 25.
 Possible variables are:
           '$GLOBAL_VARIABLE' => \'global',
           '$t' => \undef,
           '$s' => \'regular output'
 



=cut

sub PG_undef_var_check {
	if($_[0] !~ /^Use of uninitialized value/) {
		return @_;
	} else {
		# If there are objects, the output can be VERY large when you increase this
		local $Data::Dumper::Maxdepth = 2;
		# takes all lexical variables from caller-nemaspace
		my $possibles = Data::Dumper::Dumper({ %{PadWalker::peek_my(1)}, %{PadWalker::peek_our(1)} });
		
		$possibles ne "\$VAR1 = {};\n" ? ($possibles =~ s/^.*?\n(.*)\n.*?\n$/$1/ms) : ($possibles = '');
		return "Warning: " . join(', ', @_) . "Possible variables are:\n$possibles\n";
	}

}
############################################################################

=head2  Translate


=cut

sub translate {
	my $self = shift;
	my @PROBLEM_TEXT_OUTPUT = ();
	my $safe_cmpt = $self ->{safe};
	my $evalString = $self -> {source};
	$self ->{errors} .= qq{ERROR:  This problem file was empty!\n} unless ($evalString) ;
	$self ->{errors} .= qq{ERROR:  You must define the environment before translating.}
	     unless defined( $self->{envir} );
    
	# install handlers for warn and die that call PG_errorMessage.
	# if the existing signal handler is not a coderef, the built-in warn or
	# die function is called. this does not account for the case where the
	# handler is set to "IGNORE" or to the name of a function. in these cases
	# the built-in function will be called.
	
	my $outer_sig_warn = $SIG{__WARN__};
	local $SIG{__WARN__} = sub {
		ref $outer_sig_warn eq "CODE"
			? &$outer_sig_warn(PG_errorMessage('message', $_[0]))
			: warn PG_errorMessage('message', $_[0]);
	};
	
	my $outer_sig_die = $SIG{__DIE__};
	local $SIG{__DIE__} = sub {
		ref $outer_sig_die eq "CODE"
			? &$outer_sig_die(PG_errorMessage('traceback', $_[0]))
			: die PG_errorMessage('traceback', $_[0]);
	};

=pod

(3) B<Preprocess the problem text>

The input text is subjected to two global replacements.
First every incidence of

	BEGIN_TEXT
	problem text
	END_TEXT

is replaced by

   	TEXT( EV3( <<'END_TEXT' ) );
	problem text
	END_TEXT

The first construction is syntactic sugar for the second. This is explained
in C<PGbasicmacros.pl>.

Second every incidence
of \ (backslash) is replaced by \\ (double backslash).  Third each incidence of
~~ is replaced by a single backslash.

This is done to alleviate a basic
incompatibility between TeX and Perl. TeX uses backslashes constantly to denote
a command word (as opposed to text which is to be entered literally).  Perl
uses backslash to escape the following symbol.  This escape
mechanism takes place immediately when a Perl script is compiled and takes
place throughout the code and within every quoted string (both double and single
quoted strings) with the single exception of single quoted "here" documents.
That is backlashes which appear in

    TEXT(<<'EOF');
    ... text including \{   \} for example
    EOF

are the only ones not immediately evaluated.  This behavior makes it very difficult
to use TeX notation for defining mathematics within text.

The initial global
replacement, before compiling a PG problem, allows one to use backslashes within
text without doubling them. (The anomolous behavior inside single quoted "here"
documents is compensated for by the behavior of the evaluation macro EV3.) This
makes typing TeX easy, but introduces one difficulty in entering normal Perl code.

The second global replacement provides a work around for this -- use ~~ when you
would ordinarily use a backslash in Perl code.
In order to define a carriage return use ~~n rather than \n; in order to define
a reference to a variable you must use ~~@array rather than \@array. This is
annoying and a source of simple compiler errors, but must be lived with.

The problems are not evaluated in strict mode, so global variables can be used
without warnings.



=cut

############################################################################


		    ##########################################
		    ###### PG preprocessing code #############
		    ##########################################
		    
		        $evalString = &{$self->{preprocess_code}}($evalString);

		     
#               # default_preprocess_code
#		        # BEGIN_TEXT and END_TEXT must occur on a line by themselves.
#		        $evalString =~ s/\n\s*END_TEXT[\s;]*\n/\nEND_TEXT\n/g;
#		    	$evalString =~ s/\n\s*BEGIN_TEXT[\s;]*\n/\nTEXT\(EV3\(<<'END_TEXT'\)\);\n/g;
#		    	$evalString =~ s/ENDDOCUMENT.*/ENDDOCUMENT();/s; # remove text after ENDDOCUMENT
#
#				$evalString =~ s/\\/\\\\/g;    # \ can't be used for escapes because of TeX conflict
#		        $evalString =~ s/~~/\\/g;      # use ~~ as escape instead, use # for comments


=pod

(4) B<Evaluate the problem text>

Evaluate the text within the safe compartment.  Save the errors. The safe
compartment is a new one unless the $safeCompartment was set to zero in which
case the previously defined safe compartment is used. (See item 1.)

=cut

				my ($PG_PROBLEM_TEXT_REF, $PG_HEADER_TEXT_REF, $PG_POST_HEADER_TEXT_REF,$PG_ANSWER_HASH_REF, $PG_FLAGS_REF, $PGcore)
				      =$safe_cmpt->reval("   $evalString");
				      

# This section could use some more error messages.  In particular if a problem doesn't produce the right output, the user needs
# information about which problem was at fault.
#
#

#################
# FIXME The various warning message tracks are still being sorted out
# WARNING and DEBUG tracks are being handled elsewhere (in Problem.pm?)
#################
				$self->{errors} .= $@;

				
# 				$self->{errors}.=join(CGI::br(), @{$PGcore->{WARNING_messages}} );
# 				$self->{errors}.=join(CGI::br(), @{$PGcore->{DEBUG_messages  }} );
#######################################################################

#		    	push(@PROBLEM_TEXT_OUTPUT   ,   split(/(\n)/,$$PG_PROBLEM_TEXT_REF)  ) if  defined($$PG_PROBLEM_TEXT_REF  );
		    	push(@PROBLEM_TEXT_OUTPUT   ,   split(/^/,$$PG_PROBLEM_TEXT_REF)  ) if  ref($PG_PROBLEM_TEXT_REF  ) eq 'SCALAR';
		    	                                                                 ## This is better than using defined($$PG_PROBLEM_TEXT_REF)
		    	                                                                 ## Because more pleasant feedback is given
		    	                                                                 ## when the problem doesn't render.
		    	 # try to get the \n to appear at the end of the line

        use strict;
        #############################################################################
        ##########  end  EVALUATION code                                  ###########
        #############################################################################

		    ##########################################
		    ###### PG postprocessing code #############
		    ##########################################
			$PG_PROBLEM_TEXT_REF = &{$self->{postprocess_code}}($PG_PROBLEM_TEXT_REF);


=pod

(5) B<Process errors>

The error provided by Perl
is truncated slightly and returned. In the text
string which would normally contain the rendered problem.

The original text string is given line numbers and concatenated to
the errors.

=cut


        ##########################################
	###### PG error processing code ##########
	##########################################
        my (@input,$lineNumber,$line);
        if ($self -> {errors}) {
                #($self -> {errors}) =~ s/</&lt/g;
                #($self -> {errors}) =~ s/>/&gt/g;
	        #try to clean up errors so they will look ok
                $self ->{errors} =~ s/\[[^\]]+?\] [^ ]+?\.pl://gm;   #erase [Fri Dec 31 12:58:30 1999] processProblem7.pl:
                #$self -> {errors} =~ s/eval\s+'(.|[\n|r])*$//;
		#end trying to clean up errors so they will look ok


                push(@PROBLEM_TEXT_OUTPUT   ,  qq!\n<A NAME="problem! .
                    $self->{envir} ->{'probNum'} .
                    qq!"><pre>        Problem!.
                    $self->{envir} ->{'probNum'}.
                    qq!\nERROR caught by Translator while processing problem file:! .
                	$self->{envir}->{'probFileName'}.
                	"\n****************\r\n" .
                	$self -> {errors}."\r\n" .
		        "****************<br/>\n");

               push(@PROBLEM_TEXT_OUTPUT   , "------Input Read\r\n");
               $self->{source} =~ s/</&lt;/g;
               @input=split("\n", $self->{source});
               $lineNumber = 1;
                foreach $line (@input) {
                    chomp($line);
                    push(@PROBLEM_TEXT_OUTPUT, "$lineNumber\t\t$line\r\n");
                    $lineNumber ++;
                }
                push(@PROBLEM_TEXT_OUTPUT  ,"\n-----<br/></pre>\r\n");



        }

=pod

(6) B<Prepare return values>

	Returns:
			$PG_PROBLEM_TEXT_ARRAY_REF -- Reference to a string containing the rendered text.
			$PG_HEADER_TEXT_REF -- Reference to a string containing material to placed in the header (for use by JavaScript)
			$PG_POST_HEADER_TEXT_REF -- Reference to a string containing material to placed in body above form (for use by Sage)
			$PG_ANSWER_HASH_REF -- Reference to an array containing the answer evaluators.
			$PG_FLAGS_REF -- Reference to a hash containing flags and other references:
				'error_flag' is set to 1 if there were errors in rendering
			$PGcore -- the PGcore object

=cut

        ## we need to make sure that the other output variables are defined

                ## If the eval failed with errors, one or more of these variables won't be defined.
                $PG_ANSWER_HASH_REF = {}      unless defined($PG_ANSWER_HASH_REF);
                $PG_HEADER_TEXT_REF = \( "" ) unless defined($PG_HEADER_TEXT_REF);
                $PG_POST_HEADER_TEXT_REF = \( "" ) unless defined($PG_POST_HEADER_TEXT_REF);
                $PG_FLAGS_REF = {}            unless defined($PG_FLAGS_REF);

         		$PG_FLAGS_REF->{'error_flag'} = 1 	  if $self -> {errors};
        my $PG_PROBLEM_TEXT                     = join("",@PROBLEM_TEXT_OUTPUT);


        $self ->{ PG_PROBLEM_TEXT_REF	} 		= \$PG_PROBLEM_TEXT;
        $self ->{ PG_PROBLEM_TEXT_ARRAY_REF	} 	= \@PROBLEM_TEXT_OUTPUT;
	    $self ->{ PG_HEADER_TEXT_REF 	}		= $PG_HEADER_TEXT_REF;
	    $self ->{ PG_POST_HEADER_TEXT_REF 	}	= $PG_POST_HEADER_TEXT_REF;
	    $self ->{ rh_correct_answers	}		= $PG_ANSWER_HASH_REF;
	    $self ->{ PG_FLAGS_REF			}		= $PG_FLAGS_REF;
	    $self ->{ rh_pgcore             }       = $PGcore;
	    
	    #warn "PGcore is ", ref($PGcore), " in Translator";
	    #$self ->{errors};
}  # end translate


=head2   Answer evaluation methods

=cut

=head3  access methods

	$obj->rh_student_answers

=cut



sub rh_evaluated_answers {
	my $self = shift;
	my @in = @_;
	return $self->{rh_evaluated_answers} if @in == 0;

	if ( ref($in[0]) eq 'HASH' ) {
		$self->{rh_evaluated_answers} = { %{ $in[0] } }; # store a copy of the hash
	} else {
		$self->{rh_evaluated_answers} = { @in }; # store a copy of the hash
	}
	$self->{rh_evaluated_answers};
}
sub rh_problem_result {
	my $self = shift;
	my @in = @_;
	return $self->{rh_problem_result} if @in == 0;

	if ( ref($in[0]) eq 'HASH' ) {
		$self->{rh_problem_result} = { %{ $in[0] } }; # store a copy of the hash
	} else {
		$self->{rh_problem_result} = { @in }; # store a copy of the hash
	}
	$self->{rh_problem_result};
}
sub rh_problem_state {
	my $self = shift;
	my @in = @_;
	return $self->{rh_problem_state} if @in == 0;

	if ( ref($in[0]) eq 'HASH' ) {
		$self->{rh_problem_state} = { %{ $in[0] } }; # store a copy of the hash
	} else {
		$self->{rh_problem_state} = { @in }; # store a copy of the hash
	}
	$self->{rh_problem_state};
}


=head3 process_answers


	$obj->process_answers()


=cut


sub process_answers{
	my $self = shift;
	my @in = @_;
	my %h_student_answers;
	if (ref($in[0]) eq 'HASH' ) {
		%h_student_answers = %{ $in[0] };  #receiving a reference to a hash of answers
	} else {
		%h_student_answers = @in;          # receiving a hash of answers
	}
	my $rh_correct_answers = $self->rh_correct_answers();
	my @answer_entry_order = ( defined($self->{PG_FLAGS_REF}->{ANSWER_ENTRY_ORDER}) ) ?
	                      @{$self->{PG_FLAGS_REF}->{ANSWER_ENTRY_ORDER}} : keys %{$rh_correct_answers};

	# define custom warn/die handlers for answer evaluation. these used to be inside
	# the foreach loop around the conditional involving $rf_fun, but for efficiency
	# we've moved it out here. This means that the handlers will be active during the
	# code before and after the actual answer evaluation.
	
	my $outer_sig_warn = $SIG{__WARN__};
	local $SIG{__WARN__} = sub {
		ref $outer_sig_warn eq "CODE"
			? &$outer_sig_warn(PG_errorMessage('message', $_[0]))
			: warn PG_errorMessage('message', $_[0]);
	};
	
	# the die handler is a closure over %errorTable and $outer_sig_die.
	# 
	# %errorTable accumulates a "full" error message for each error that occurs during
	# answer evaluation. then, right after the evaluation (which is done within a call
	# to Safe::reval), $@ is checked and it's value is looked up in %errorTable to get
	# the full error to report.
	# 
	# my question: why is this a hash? this is die, so once one occurs, we exit the reval.
	# wouldn't it be sufficient to have a scalar like $backtrace_for_last_error?
	# 
	# Note that %errorTable is cleared for each answer.
	my %errorTable;
	my $outer_sig_die = $SIG{__DIE__};
	local $SIG{__DIE__} = sub {
		
		# this chunk taken from dpvc's original handler
		my $fullerror = PG_errorMessage('traceback', @_);
		my ($error,$traceback) = split /\n/, $fullerror, 2;
		$fullerror =~ s/\n	 /<br\/>&nbsp;&nbsp;&nbsp;/g; $fullerror =~ s/\n/<br\/>/g;
		$error .= "\n";
		$errorTable{$error} = $fullerror;
		# end of dpvc's original code
		
		ref $outer_sig_die eq "CODE"
			? &$outer_sig_die($error)
			: die $error;
	};
	
 	# apply each instructors answer to the corresponding student answer
	
 	foreach my $ans_name ( @answer_entry_order ) {
		my ($ans, $errors) = $self->filter_answer( $h_student_answers{$ans_name} );
		no strict;
		# evaluate the answers inside the safe compartment.
		local($rf_fun,$temp_ans) = (undef,undef);
		if ( defined($rh_correct_answers ->{$ans_name} ) ) {
			$rf_fun  = $rh_correct_answers->{$ans_name};
		} else {
			warn "There is no answer evaluator for the question labeled $ans_name";
		}
		$temp_ans  = $ans;
		$temp_ans = '' unless defined($temp_ans); #make sure that answer is always defined
		                                          # in case the answer evaluator forgets to check
		$self->{safe}->share('$rf_fun','$temp_ans');
 	    
 	    # clear %errorTable for each problem
 	    %errorTable = (); # is the error table being used? perhaps by math objects?
 	    
		my $rh_ans_evaluation_result;
		if (ref($rf_fun) eq 'CODE' ) {
			$rh_ans_evaluation_result = $self->{safe} ->reval( '&{ $rf_fun }($temp_ans, ans_label => \''.$ans_name.'\')' ) ;
			warn "Error in Translator.pm::process_answers: Answer $ans_name: |$temp_ans|\n $@\n" if $@;
		} elsif (ref($rf_fun) =~ /AnswerEvaluator/)   {
			$rh_ans_evaluation_result = $self->{safe} ->reval('$rf_fun->evaluate($temp_ans, ans_label => \''.$ans_name.'\')');
			$@ = $errorTable{$@} if $@ && defined($errorTable{$@});  #Are we redefining error messages here?
			warn "Error in Translator.pm::process_answers: Answer $ans_name: |$temp_ans|\n $@\n" if $@;
			warn "Evaluation error: Answer $ans_name:<br/>\n",
				$rh_ans_evaluation_result->error_flag(), " :: ",
				$rh_ans_evaluation_result->error_message(),"<br/>\n"
					if defined($rh_ans_evaluation_result)  
						and defined($rh_ans_evaluation_result->error_flag());
		} else {
			warn "Error in Translator.pm::process_answers: Answer $ans_name:<br/>\n Unrecognized evaluator type |", ref($rf_fun), "|";
		}	
  	    
		use strict;
		unless ( ( ref($rh_ans_evaluation_result) eq 'HASH') or ( ref($rh_ans_evaluation_result) eq 'AnswerHash') ) {
			warn "Error in Translator.pm::process_answers: Answer $ans_name:<br/>\n
				Answer evaluators must return a hash or an AnswerHash type, not type |", 
				ref($rh_ans_evaluation_result), "|";
		}
		$rh_ans_evaluation_result ->{ans_message} .= "$errors \n" if $errors;
		$rh_ans_evaluation_result ->{ans_name} = $ans_name;
		$self->{rh_evaluated_answers}->{$ans_name} = $rh_ans_evaluation_result;
	}
	$self->rh_evaluated_answers;
}



=head3 grade_problem

	$obj->rh_problem_state(%problem_state);  # sets the current problem state
	$obj->grade_problem(%form_options);


=cut


sub grade_problem {
	my $self = shift;
	no strict;
	local %rf_options = @_;
	local $rf_grader = $self->{rf_problem_grader};
	local $rh_answers = $self->{rh_evaluated_answers};
	local $rh_state = $self->{rh_problem_state};
	$self->{safe}->share('$rf_grader','$rh_answers','$rh_state','%rf_options');
############################################
#
# FIXME
# warning messages are not being transmitted from this evaluation
# ??????
############################################

	($self->{rh_problem_result},$self->{rh_problem_state}) =
		$self->{safe}->reval('&{$rf_grader}($rh_answers,$rh_state,%rf_options)');
	use strict;
	die $@ if $@;
	($self->{rh_problem_result}, $self->{rh_problem_state});
}

sub rf_std_problem_grader {
    my $self = shift;
	return \&std_problem_grader;
}
sub old_std_problem_grader{
	my $rh_evaluated_answers = shift;
	my %flags = @_;  # not doing anything with these yet
	my %evaluated_answers = %{$rh_evaluated_answers};
	my	$allAnswersCorrectQ=1;
	foreach my $ans_name (keys %evaluated_answers) {
	# I'm not sure if this check is really useful.
	    if (ref($evaluated_answers{$ans_name} ) eq 'HASH' ) {
	   		$allAnswersCorrectQ = 0 unless( 1 == $evaluated_answers{$ans_name}->{score} );
	   	} else {
	   		warn "Error: Answer $ans_name is not a hash";
	   		warn "$evaluated_answers{$ans_name}";
	   	}
	}
	# Notice that "all answers are correct" if there are no questions.
	{ score 			=> $allAnswersCorrectQ,
	  prev_tries 		=> 0,
	  partial_credit 	=> $allAnswersCorrectQ,
	  errors			=>	"",
	  type              => 'old_std_problem_grader',
	  flags				=> {}, # not doing anything with these yet
	};  # hash output

}

#####################################
# This is a model for plug-in problem graders
#####################################

sub std_problem_grader{
	my $rh_evaluated_answers = shift;
	my $rh_problem_state = shift;
	my %form_options = @_;
	my %evaluated_answers = %{$rh_evaluated_answers};
	#  The hash $rh_evaluated_answers typically contains:
	#      'answer1' => 34, 'answer2'=> 'Mozart', etc.

	# By default the  old problem state is simply passed back out again.
	my %problem_state = %$rh_problem_state;


 	# %form_options might include
 	# The user login name
 	# The permission level of the user
 	# The studentLogin name for this psvn.
 	# Whether the form is asking for a refresh or is submitting a new answer.

 	# initial setup of the answer
 	my %problem_result = ( score 				=> 0,
 						   errors 				=> '',
 						   type   				=> 'std_problem_grader',
 						   msg					=> '',
 						 );
 	# Checks

 	my $ansCount = keys %evaluated_answers;  # get the number of answers
 	unless ($ansCount > 0 ) {
 		$problem_result{msg} = "This problem did not ask any questions.";
 		return(\%problem_result,\%problem_state);
 	}

 	if ($ansCount > 1 ) {
 		$problem_result{msg} = 'In order to get credit for this problem all answers must be correct.' ;
 	}

 	unless (defined( $form_options{answers_submitted}) and $form_options{answers_submitted} == 1) {
 		return(\%problem_result,\%problem_state);
 	}

	my	$allAnswersCorrectQ=1;
	foreach my $ans_name (keys %evaluated_answers) {
	# I'm not sure if this check is really useful.
	    if ( ( ref($evaluated_answers{$ans_name} ) eq 'HASH' ) or ( ref($evaluated_answers{$ans_name}) eq 'AnswerHash' ) ) {
	   		$allAnswersCorrectQ = 0 unless( 1 == $evaluated_answers{$ans_name}->{score} );
	   	} else {
	   		warn "Error: Answer $ans_name is not a hash";
	   		warn "$evaluated_answers{$ans_name}";
	   		warn "This probably means that the answer evaluator is for this answer is not working correctly.";
	   		$problem_result{error} = "Error: Answer $ans_name is not a hash: $evaluated_answers{$ans_name}";
	   	}
	}
	# report the results
	$problem_result{score} = $allAnswersCorrectQ;

	# I don't like to put in this bit of code.
	# It makes it hard to construct error free problem graders
	# I would prefer to know that the problem score was numeric.
    unless ($problem_state{recorded_score} =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/ ) {
    	$problem_state{recorded_score} = 0;  # This gets rid of non-numeric scores
    }
    #
	if ($allAnswersCorrectQ == 1 or $problem_state{recorded_score} == 1) {
		$problem_state{recorded_score} = 1;
	} else {
		$problem_state{recorded_score} = 0;
	}

	$problem_state{num_of_correct_ans}++ if $allAnswersCorrectQ == 1;
	$problem_state{num_of_incorrect_ans}++ if $allAnswersCorrectQ == 0;
	(\%problem_result, \%problem_state);
}

sub rf_avg_problem_grader {
    my $self = shift;
	return \&avg_problem_grader;
}

sub avg_problem_grader{
	my $rh_evaluated_answers = shift;
	my $rh_problem_state = shift;
	my %form_options = @_;
	my %evaluated_answers = %{$rh_evaluated_answers};
	#  The hash $rh_evaluated_answers typically contains:
	#      'answer1' => 34, 'answer2'=> 'Mozart', etc.

	# By default the  old problem state is simply passed back out again.
	my %problem_state = %$rh_problem_state;


 	# %form_options might include
 	# The user login name
 	# The permission level of the user
 	# The studentLogin name for this psvn.
 	# Whether the form is asking for a refresh or is submitting a new answer.

 	# initial setup of the answer
 	my	$total=0;
 	my %problem_result = (
		score => 0,
		errors => '',
		type => 'avg_problem_grader',
		msg => '',
	);
	my $count = keys %evaluated_answers;
	$problem_result{msg} = 'You can earn partial credit on this problem.' if $count >1;
	# Return unless answers have been submitted
	unless ($form_options{answers_submitted} == 1) {
 		return(\%problem_result,\%problem_state);
 	}
 	# Answers have been submitted -- process them.
	foreach my $ans_name (keys %evaluated_answers) {
		$total += $evaluated_answers{$ans_name}->{score};
	}
	# Calculate score rounded to three places to avoid roundoff problems
	$problem_result{score} = ($count) ? $total/$count : 0 ; # give zero if no answers have been evaluated.
	# increase recorded score if the current score is greater.
	$problem_state{recorded_score}=0 unless defined $problem_state{recorded_score};
	$problem_state{recorded_score} = $problem_result{score} if $problem_result{score} > $problem_state{recorded_score};


	$problem_state{num_of_correct_ans}++ if $total == $count;
	$problem_state{num_of_incorrect_ans}++ if $total < $count ;
	warn "Error in grading this problem the total $total is larger than $count" if $total > $count;
	(\%problem_result, \%problem_state);

}
=head3 safetyFilter

	($filtered_ans, $errors) = $obj ->filter_ans($ans)
                               $obj ->rf_safety_filter()

=cut

sub filter_answer {
	my $self = shift;
	my $ans = shift;
	my @filtered_answers;
	my $errors='';
	if (ref($ans) eq 'ARRAY') {   #handle the case where the answer comes from several inputs with the same name
								  # In many cases this will be passed as a reference to an array
								  # if it is passed as a single string (separated by \0 characters) as 
								  # some early versions of CGI behave, then 
								  # it is unclear what will happen when the answer is filtered.
		foreach my $item (@{$ans}) {
			my ($filtered_ans, $error) = &{ $self->{rf_safety_filter} } ($item);
			push(@filtered_answers, $filtered_ans);
			$errors .= " ". $error if $error;  # add error message if error is non-zero.
		}
		(\@filtered_answers,$errors);
	
	} else {
		&{ $self->{rf_safety_filter} } ($ans);
	}
	
}

sub rf_safety_filter {
	my $self = shift;
	my $rf_filter = shift;
	$self->{rf_safety_filter} = $rf_filter if $rf_filter and ref($rf_filter) eq 'CODE';
	warn "The safety_filter must be a reference to a subroutine" unless ref($rf_filter) eq 'CODE' ;
	$self->{rf_safety_filter}
}

sub safetyFilter {
        my $answer = shift;  # accepts one answer and checks it
	my $submittedAnswer = $answer;
	$answer = '' unless defined $answer;
	my ($errorno);
	$answer =~ tr/\000-\037/ /;
	#### Return if answer field is empty ########
	unless ($answer =~ /\S/) {
	     # $errorno = "<br/>No answer was submitted.";
   	     $errorno = 0;  ## don't report blank answer as error
	     return ($answer,$errorno);
	}
	######### replace ^ with **    (for exponentiation)
	# 	$answer =~ s/\^/**/g;
	######### Return if  forbidden characters are found
	unless ($answer =~ /^[a-zA-Z0-9_\-\+ \t\/@%\*\.\n^\(\)]+$/ )  {
	      $answer =~ tr/a-zA-Z0-9_\-\+ \t\/@%\*\.\n^\(\)/#/c;
	      $errorno = "<br/>There are forbidden characters in your answer: $submittedAnswer<br/>";
	      return ($answer,$errorno);
	}

	$errorno = 0;
	return($answer, $errorno);
}

##   Check submittedAnswer for forbidden characters, etc.
#     ($submittedAnswer,$errorno) = safetyFilter($submittedAnswer);
#     	$errors .= "No answer was submitted.<br/>" if $errorno == 1;
#     	$errors .= "There are forbidden characters in your answer: $submittedAnswer<br/>" if $errorno ==2;
#
##   Check correctAnswer for forbidden characters, etc.
#     unless (ref($correctAnswer) ) {  #skip check if $correctAnswer is a function
#     	($correctAnswer,$errorno) = safetyFilter($correctAnswer);
#     	$errors .= "No correct answer is given in the statement of the problem.
#     	            Please report this to your instructor.<br/>" if $errorno == 1;
#     	$errors .= "There are forbidden characters in the problems answer.
#     	            Please report this to your instructor.<br/>" if $errorno == 2;
#     }



=head2 PGsort

Because of the way sort is optimized in Perl, the symbols $a and $b
have special significance.

C<sort {$a<=>$b} @list>
C<sort {$a cmp $b} @list>

sorts the list numerically and lexically respectively. 

If C<my $a;> is used in a problem, before the sort routine is defined in a macro, then
things get badly confused.  To correct this the macro PGsort is defined below.  It is 
evaluated before the problem template is read.  In PGbasicmacros.pl, the two subroutines

	PGsort sub { $_[0] < $_[1] }, @list;
	PGsort sub { $_[0] lt $_[1] }, @list;

(called num_sort and lex_sort) provide slightly slower, but safer, routines for the PG language. 
(The subroutines for ordering are B<required>. Note the commas!)

=cut

# This sort can cause troubles because of its special use of $a and $b.
# In particular ANS( ans_eva1 ans_eval2) caused trouble.
# One answer at a time did not --- very strange.
# This was replaced by a quick sort routine because the original subroutine
# did not work with Safe when Perl was built with ithreads

#sub PGsort {
#	my $sort_order = shift;
#	die "Must supply an ordering function with PGsort: PGsort sub {\$a cmp \$b }, \@list\n" unless ref($sort_order) eq 'CODE';
#	sort {&$sort_order($a,$b)} @_;
#}

# quicksort
sub PGsort {
         my $cmp = shift;
	 die "Must supply an ordering function with PGsort: PGsort  sub {\$_[0]  < \$_[1] }, \@list\n" unless ref($cmp) eq 'CODE';
         if (@_ == 0) { return () }
         else {
           my $b_item = shift;
           my ($small, $large);
           my $a_item;
           for $a_item (@_) {
             push @{&$cmp($a_item, $b_item) ? $small : $large}, $a_item;
           }
           return (PGsort($cmp, @$small), $b_item, PGsort($cmp, @$large));
         }
       }



# no strict;   # this is important -- I guess because eval operates on code which is not written with strict in mind.


=head2 PG_restricted_eval

	PG_restricted_eval($string)

Evaluated in package 'main'. Result of last statement is returned.
When called from within a safe compartment the safe compartment package
is 'main'.


=cut

# Remember, eval STRING evaluates code in the current lexical context, so any
# lexicals available here will also be available in the evaluated code. So we
# move the actual eval into a helper function called PG_restricted_eval_helper,
# which doesn't need to have any lexicals.
sub PG_restricted_eval {
	my $string = shift;
	my $out = PG_restricted_eval_helper($string);
	my $err = $@;
	my $err_report = $err if $err =~ /\S/;
	return wantarray ? ($out, $err, $err_report) : $out;
}

# This is a helper that doesn't use any lexicals. See above.
sub PG_restricted_eval_helper {
	no strict;
	local $SIG{__WARN__} = "DEFAULT";
	local $SIG{__DIE__} = "DEFAULT";
	return eval("package main;\n" . $_[0]);
}

sub PG_macro_file_eval {      # would like to modify this so that it requires use strict on the files that it evaluates.
    my $string = shift;
    my ($pck,$file,$line) = caller;
	
	local $SIG{__WARN__} = "DEFAULT";
	local $SIG{__DIE__} = "DEFAULT";
	
    no strict;
    my $out = eval  ("package main; be_strict();\n" . $string );
    my $errors =$@;
    my $full_error_report = "PG_macro_file_eval detected error at line $line of file $file \n"
                . $errors .
                "The calling package is $pck\n" if defined($errors) && $errors =~/\S/;
    use strict;
    
    return (wantarray) ?  ($out, $errors,$full_error_report) : $out;
}
=head2 PG_answer_eval


	PG_answer_eval($string)

Evaluated in package defined by the current safe compartment.
Result of last statement is returned.
When called from within a safe compartment the safe compartment package
is 'main'.

There is still some confusion about how these two evaluation subroutines work
and how best to define them.  It is useful to have two evaluation procedures
since at some point one might like to make the answer evaluations more stringent.

=cut


sub PG_answer_eval {
   my($string) = shift;   # I made this local just in case -- see PG_restricted_eval
   my $errors = '';
   my $full_error_report = '';
   my ($pck,$file,$line) = caller; 
    # Because of the global variable $PG::compartment_name and $PG::safe_cmpt
    # only one problem safe compartment can be active at a time.
    # This might cause problems at some point.  In that case a cleverer way
    # of insuring that the package stays in scope until the answer is evaluated
    # will be required.
    
    # This is pretty tricky and doesn't always work right.
    # We seem to need PG_priv instead of main when PG_answer_eval is called within a completion
    # 'package PG_priv; '
    
    local $SIG{__WARN__} = sub {die(@_)};  # make warn die, so all errors are reported.
	local $SIG{__DIE__} = "DEFAULT";
	
    no strict;
    my $out = eval('package main;'.$string);
    $out = '' unless defined($out);
    $errors .= $@;
    $full_error_report = "ERROR: at line $line of file $file
                $errors
                The calling package is $pck\n" if defined($errors) && $errors =~/\S/;
    use strict;
    
    return (wantarray) ?  ($out, $errors,$full_error_report) : $out;


}

# sub original_preprocess_code {
# 	my $evalString = shift;
# 	# BEGIN_TEXT and END_TEXT must occur on a line by themselves.
# 	$evalString =~ s/\n\s*END_TEXT[\s;]*\n/\nEND_TEXT\n/g;
# 	$evalString =~ s/\n\s*BEGIN_TEXT[\s;]*\n/\nTEXT\(EV3\(<<'END_TEXT'\)\);\n/g;
# 	$evalString =~ s/ENDDOCUMENT.*/ENDDOCUMENT();/s; # remove text after ENDDOCUMENT
# 
# 	$evalString =~ s/\\/\\\\/g;    # \ can't be used for escapes because of TeX conflict
# 	$evalString =~ s/~~/\\/g;      # use ~~ as escape instead, use # for comments
# 	$evalString;
# }
sub default_preprocess_code {
	my $evalString = shift;
	# BEGIN_TEXT and END_TEXT must occur on a line by themselves.
	$evalString =~ s/\n\s*END_TEXT[\s;]*\n/\nEND_TEXT\n/g;
	$evalString =~ s/\n\s*END_PGML[\s;]*\n/\nEND_PGML\n/g;
	$evalString =~ s/\n\s*END_PGML_SOLUTION[\s;]*\n/\nEND_PGML_SOLUTION\n/g;
	$evalString =~ s/\n\s*END_PGML_HINT[\s;]*\n/\nEND_PGML_HINT\n/g;
	$evalString =~ s/\n\s*END_SOLUTION[\s;]*\n/\nEND_SOLUTION\n/g;
	$evalString =~ s/\n\s*END_HINT[\s;]*\n/\nEND_HINT\n/g;
	$evalString =~ s/\n\s*BEGIN_TEXT[\s;]*\n/\nTEXT\(EV3P\(<<'END_TEXT'\)\);\n/g;
	$evalString =~ s/\n\s*BEGIN_PGML[\s;]*\n/\nTEXT\(PGML::Format2\(<<'END_PGML'\)\);\n/g;
	$evalString =~ s/\n\s*BEGIN_PGML_SOLUTION[\s;]*\n/\nSOLUTION\(PGML::Format2\(<<'END_PGML_SOLUTION'\)\);\n/g;
	$evalString =~ s/\n\s*BEGIN_PGML_HINT[\s;]*\n/\nHINT\(PGML::Format2\(<<'END_PGML_SOLUTION'\)\);\n/g;
	$evalString =~ s/\n\s*BEGIN_SOLUTION[\s;]*\n/\nSOLUTION\(EV3P\(<<'END_SOLUTION'\)\);\n/g;
	$evalString =~ s/\n\s*BEGIN_HINT[\s;]*\n/\nHINT\(EV3P\(<<'END_HINT'\)\);\n/g;
	$evalString =~ s/ENDDOCUMENT.*/ENDDOCUMENT();/s; # remove text after ENDDOCUMENT

	$evalString =~ s/\\/\\\\/g;    # \ can't be used for escapes because of TeX conflict
	$evalString =~ s/~~/\\/g;      # use ~~ as escape instead, use # for comments
	$evalString;
}
sub default_postprocess_code {
	my $evalString_ref = shift;
	$evalString_ref;
}

no strict;   
sub dumpvar {
    my ($packageName) = @_;

    local(*alias);
    
    sub emit {
    	print @_;
    }
    
    *stash = *{"${packageName}::"};
    $, = "  ";
    
    emit "Content-type: text/html\n\n<pre>\n";
    
    
    while ( ($varName, $globValue) = each %stash) {
        emit "$varName\n";
        
	*alias = $globValue;
	next if $varName=~/main/;
	
	#if (defined($alias) ) {  # get rid of defined since this is deprecated
	if ($alias ) {
	    emit "  \$$varName $alias \n";
	}
	
	if ( @alias) {
	    emit "  \@$varName @alias \n";
	}
	if (%alias ) {
	    emit "  %$varName \n";
	    foreach $key (keys %alias) {
	        emit "    $key => $alias{$key}\n";
	    }
	}
    }
    emit "</pre></pre>";


}
use strict;

#### for error checking and debugging purposes
# sub pretty_print_rh {
# 	my $rh = shift;
# 	foreach my $key (sort keys %{$rh})  {
# 		warn "  $key => ",$rh->{$key},"\n";
# 	}
# }
# end evaluation subroutines
1;
