################################################################################
# WeBWorK Online Homework Delivery System
# Copyright © 2000-2012 The WeBWorK Project, http://openwebwork.org
# $CVSHeader: pg/lib/PGloadfiles.pm,v 1.1 2010/05/14 11:39:02 gage Exp $
# 
# This program is free software; you can redistribute it and/or modify it under
# the terms of either: (a) the GNU General Public License as published by the
# Free Software Foundation; either version 2, or (at your option) any later
# version, or (b) the "Artistic License" which comes with this package.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See either the GNU General Public License or the
# Artistic License for more details.
################################################################################

=head2

=cut

=head2 loadMacros

	loadMacros(@macroFiles)

loadMacros takes a list of file names and evaluates the contents of each file. 
This is used to load macros which define and augment the PG language. The macro
files are searched for in the directories specified by the array referenced by
$macrosPath, which by default is the current course's macros directory followed
by WeBWorK's pg/macros directory. The latter is where the default behaviour of
the PG language is defined. The default path is set in the global.conf file.

Macro files named PG.pl or IO.pl will be loaded with no opcode restrictions,
hence any code in those files will be able to execute privileged operations.
This is true no matter which macro directory the file is in. For example,
if $macrosPath contains the path to a problem library macros directory which
contains a PG.pl file, this file will be loaded and allowed to engage in
privileged behavior.

=head3 Overloading macro files

An individual course can modify the PG language, for that course only, by
duplicating one of the macro files in the system-wide macros directory and
placing this file in the macros directory for the course. The new file in the
course's macros directory will now be used instead of the file in the
system-wide macros directory.

The new file in the course macros directory can by modified by adding macros or
modifying existing macros.

=head3 Modifying existing macros

I<Modifying macros is for users with some experience.>

Modifying existing macros might break other standard macros or problems which
depend on the unmodified behavior of these macors so do this with great caution.
In addition problems which use new macros defined in these files or which depend
on the modified behavior of existing macros will not work in other courses
unless the macros are also transferred to the new course.  It helps to document
the  problems by indicating any special macros which the problems require.

There is no facility for modifying or overloading a single macro. The entire
file containing the macro must be overloaded.

Modifications to files in the course macros directory affect only that course,
they will not interfere with the normal behavior of WeBWorK in other courses.

=cut

our $debugON =0;

package PGloadfiles;
use strict;
use Exporter;
use PGcore;
use WeBWorK::PG::Translator;
use WeBWorK::PG::IO;

our @ISA = qw ( PGcore  ) ;  # look up features in PGcore -- in this case we want the environment.



# new 
#   Create one loadfiles object per question (and per PGcore object)
#   Process macro files
#   Keep list of macro files processed.
sub new {
	my $class = shift;	
	my $envir = shift;  #pointer to environment hash
	warn "PGloadmacros must be called with an environment" unless ref($envir) eq 'HASH';
	my $self = {
		envir		=>	$envir,
		macroFileList    => {},    # records macros used in compilation
		pgFileName       => '',    # current pg file being processed
		server_root_url  => '',    # how do we find this?
		macrosPath       => '',
		pwd              => '',    # current directory -- defined in initialize
	};
	bless $self, $class;
	$self->initialize;
	#$self->check_parameters;
	return $self;
}

sub initialize {
	my $self = shift;
	my $templateDirectory = $self->{envir}->{templateDirectory};
	my $pwd = $self->{envir}->{fileName};
	$pwd =~ s!/[^/]*$!!;
    $pwd = $templateDirectory.$pwd unless substr($pwd,0,1) eq '/';
    $pwd =~ s!/tmpEdit/!/!;
	$self->{pwd} = $pwd;	
	$self->{macrosPath} = $self->{envir}->{pgDirectories}->{macrosPath};
	
}

sub PG_restricted_eval {
	my $self = shift;
	WeBWorK::PG::Translator::PG_restricted_eval(@_);
}

sub PG_macro_file_eval {
	my $self = shift;
	WeBWorK::PG::Translator::PG_macro_file_eval(@_);
}

# ^function loadMacros
# ^uses time_it
# ^uses $debugON
# ^uses $externalTTHPath
# ^uses findMacroFile
sub loadMacros {
    my $self = shift;
    my @files = @_;
    my $fileName;
    my $macrosPath = $self->{envir}->{macrosPath};
    eval {main::time_it("begin load macros");};
    ###############################################################################
    # At this point the directories have been defined from %envir and we can define
    # the directories for this file
    ###############################################################################
   
    while (@files) {
        $fileName = shift @files;
        next  if ($fileName =~ /^PG.pl$/) ;    # the PG.pl macro package is already loaded.

        my $macro_file_name = $fileName;
	$macro_file_name =~s/\.pl//;  # trim off the extension
	$macro_file_name =~s/\.pg//;  # sometimes the extension is .pg (e.g. CAPA files)
	my $init_subroutine_name = "_${macro_file_name}_init";
	$init_subroutine_name =~ s![^a-zA-Z0-9_]!_!g;  # remove dangerous chars
	
	my $init_subroutine  = eval { \&{'main::'.$init_subroutine_name} };

	###############################################################################

        # macros are searched for in the directories listed in the $macrosPath array reference.

        my $macro_file_loaded = defined($init_subroutine) && defined(&$init_subroutine);
        warn "PGloadfiles: macro init $init_subroutine_name defined |$init_subroutine| |$macro_file_loaded|" if $debugON;
        unless ($macro_file_loaded) {
	    warn "loadMacros: loading macro file $fileName" if $debugON;
	    my $filePath = $self->findMacroFile($fileName);
	    #### (check for renamed files here?) ####
	    if ($filePath) {
	        $self->compile_file($filePath); 
		warn "loadMacros is compiling $filePath" if $debugON;
	    }
	    else {
	        die "Can't locate macro file |$fileName| via path: |".join("|, |",@{$macrosPath})."|";
	    }
	}
           
	$init_subroutine  = eval { \&{'main::'.$init_subroutine_name} };
	
	###############################################################################

	$macro_file_loaded = defined($init_subroutine) && defined(&$init_subroutine);
	warn "PGloadfiles: macro init $init_subroutine_name defined |$init_subroutine| |$macro_file_loaded|"if $debugON;

	if ( $macro_file_loaded ) {
	    warn "PGloadfiles:  $macro_file_name loaded, initializing $macro_file_name\n" if $debugON;
	    &$init_subroutine();
	}
	#warn "main:: contains <br>\n $macro_file_name ".join("<br>\n $macro_file_name ", %main::);
    }
    #warn "files loaded:", join(" ", keys %{ $self->{macroFileList} });
    eval{main::time_it("end load macros");};
}


# ^function findMacroFile
# ^uses $macrosPath
# ^uses $pwd
sub findMacroFile {
  my $self   = shift;
  my $macroFileName = shift;
  my $macroFilePath;
  my $pwd = $self->{pwd};
  foreach my $dir (@{$self->{macrosPath} } ) {
      $macroFilePath = "$dir/$macroFileName";
      $macroFilePath =~ s!^\.\.?/!$pwd/!;
      return $macroFilePath if (-r $macroFilePath);
  }
  return;  # no file found
}
# errors in compiling macros is not always being reported.
# ^function compile_file
# ^uses @__eval__
# ^uses PG_restricted_eval
# ^uses $__files__
sub compile_file {
    my $self     = shift;
 	my $filePath = shift;
 	warn "loading $filePath" if $debugON; 
 	local(*MACROFILE);
 	local($/);
 	$/ = undef;   # allows us to treat the file as a single line
 	open(MACROFILE, "<$filePath") || die "Cannot open file: $filePath";
 	my $string = <MACROFILE>;
 	#warn "compiling $string";
 	my ($result,$error,$fullerror) = $self->PG_macro_file_eval($string);
	#eval ('$main::__files__->{pop @main::__eval__} = $filePath');
 	if ($error) {    # the $fullerror report has formatting and is never empty
                # this is now handled by PG_errorMessage() in the PG translator
 		#$fullerror =~ s/\(eval \d+\)/ $filePath\n/;   # attempt to insert file name instead of eval number
 		die "Error detected while loading $filePath:\n$fullerror";
 	}
	$self->{macroFileList}->{$filePath} =1;
 	close(MACROFILE);

}






=head2 sourceAlias

	sourceAlias($path_to_PG_file);

Returns a relative URL to the F<source.pl> script, which may be installed in a
course's F<html> directory to allow formatted viewing of the problem source.

=cut

# ^function sourceAlias
# ^uses PG_restricted_eval
# ^uses %envir
# ^uses $envir{inputs_ref}
# ^uses $envir{psvn}
# ^uses $envir{probNum}
# ^uses $envir{displayMode}
# ^uses $envir{courseName}
# ^uses $envir{sessionKey}
sub sourceAlias {
	my $self         = shift;
	my $path_to_file = shift;
	my $envir        =  PG_restricted_eval(q!\%main::envir!);
	my $user         = $envir->{inputs_ref}->{user};
	$user            = " " unless defined($user);
    my $out = 'source.pl?probSetKey='  . $envir->{psvn}.
  			  '&amp;probNum='          . $envir->{probNum} .
   			  '&amp;Mode='             . $envir->{displayMode} .
   			  '&amp;course='           . $envir->{courseName} .
    		  '&amp;user='             . $user .
			  '&amp;displayPath='      . $path_to_file .
	   		  '&amp;key='              . $envir->{sessionKey};

 	 $out;
}


1;
