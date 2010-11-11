################################################################################
# WeBWorK Online Homework Delivery System
# Copyright © 2000-2007 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader: pg/macros/dangerousMacros.pl,v 1.58 2009/11/04 17:54:42 dpvc Exp $
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

=head1 NAME

dangerousMacros.pl - Macros which require elevated permissions to execute.

=head1 SYNPOSIS

	loadMacros(macrofile1,macrofile2,...)
	
	insertGraph(graphObject); # returns a path to the file containing the graph image.
	
	tth(texString); # returns an HTML version of the tex code passed to it.
	
	alias(pathToFile); # returns URL which links to that file

=head1 DESCRIPTION

dangerousMacros.pl contains macros that use potentially dangerous functions like
require and eval. They can reference disk files for reading and writing, create
links, and execute commands. It may be necessary to modify certain addresses in
this file to make the scripts run properly in different environments.

This file is loaded implicitly every time a new problem is rendered.

=for comment

FIXME this information belongs in global.conf where modules to load are listed.
I don't see why this shows up here.

=head2 Sharing modules

Most modules are loaded by dangerousMacros.pl

The modules must be loaded using require (not use) since the
courseScriptsDirectory is defined at run time.

The following considerations come into play.

=over

=item *

One needs to limit the access to modules for safety -- hence only modules in the
F<courseScriptsDirectory> can be loaded.

=item *

Loading them in dangerousMacros.pl is wasteful, since the modules would need to
be reloaded everytime a new safe compartment is created. (I believe that using
require takes care of this.)

=item *

Loading GD within a safeCompartment creates infinite recurrsion in AUTOLOAD
(probably a bug) hence this module is loaded by translate.pl and then shared
with the safe compartment.

=item *

Other modules loaded by translate.pl are C<Exporter> and C<DynaLoader>.

=item *

PGrandom is loaded by F<PG.pl>, since it is needed there.

=back

The module name spaces loaded in dangerousMacros are:

	PGrandom (if not previously loaded)
	WWPlot
	Fun
	Label
	Circle

in addition the subroutine &evaluate_units is shared from the module Units.

=cut

# 
# BEGIN {
# 	be_strict(); # an alias for use strict.  This means that all global variable must contain main:: as a prefix.
# 	
# }
# 
# # ^variable my $debugON
# my $debugON = 0;
# 
# # grab read only variables from the current safe compartment
# 
# # ^variable my $macrosPath
# my ($macrosPath,
#     # ^variable my $pwd
#     $pwd,
#     # ^variable my $appletPath
#     $appletPath,
#     # ^variable my $server_root_url
#     $server_root_url,
# 	# ^variable my $templateDirectory
# 	$templateDirectory,
# 	# ^variable my $scriptDirectory
# 	$scriptDirectory,
# 	# ^variable my $externalTTHPath
# 	$externalTTHPath,
# 	);
# 
# # ^function _dangerousMacros_init
# # ^uses %envir
# # ^uses $macrosPath
# # ^uses $pwd
# # ^uses $appletPath
# # ^uses $server_root_url
# # ^uses $templateDirectory
# # ^uses $scriptDirectory
# # ^uses $externalTTHPath
# # ^uses $debugON

sub _dangerousMacros_init {   #use  envir instead of local variables?
#     # will allow easy addition of new directories -- is this too liberal? do some pg directories need to be protected?
#     $macrosPath               = eval('$main::envir{pgDirectories}{macrosPath}'); 
#     # will allow easy addition of new directories -- is this too liberal? do some pg directories need to be protected?
#     $pwd                      = eval('$main::envir{fileName}'); $pwd =~ s!/[^/]*$!!;
#     $appletPath               = eval('$main::envir{pgDirectories}{appletPath}');
#     $server_root_url          = eval('$main::envir{server_root_url}');
# 
#     $templateDirectory        = eval('$main::envir{templateDirectory}');
#     $scriptDirectory          = eval('$main::envir{scriptDirectory}');
#     $externalTTHPath          = eval('$main::envir{externalTTHPath}');
#     $pwd = $templateDirectory.$pwd unless substr($pwd,0,1) eq '/';
#     $pwd =~ s!/tmpEdit/!/!;
#     warn "dangerousmacros initialized" if $debugON;
#     warn eval(q! "dangerousmacros.pl externalTTHPath is ".$main::externalTTHPath;!) if $debugON;
#     warn eval(q! "dangerousmacros.pl:  The envir variable $main::{envir} is".join(" ",%main::envir)!) if $debugON; 

 }
 
# 
# # ^function _dangerousMacros_export
# sub _dangerousMacros_export {
# 	my @EXPORT= (
# 	    '&_dangerousMacros_init',
# 		'&alias',
# 		'&compile_file',
# 		'&insertGraph',
# 		'&loadMacros',
# 		'&HEADER_TEXT',
# 		'&sourceAlias',
# 		'&tth',
# 	);
# 	@EXPORT;
# }
# 
# 
# =head2 loadMacros
# 
# 	loadMacros(@macroFiles)
# 
# loadMacros takes a list of file names and evaluates the contents of each file. 
# This is used to load macros which define and augment the PG language. The macro
# files are searched for in the directories specified by the array referenced by
# $macrosPath, which by default is the current course's macros directory followed
# by WeBWorK's pg/macros directory. The latter is where the default behaviour of
# the PG language is defined. The default path is set in the global.conf file.
# 
# Macro files named PG.pl, IO.pl, or dangerousMacros.pl will be loaded with no
# opcode restrictions, hence any code in those files will be able to execute
# privileged operations. This is true no matter which macro directory the file is
# in. For example, if $macrosPath contains the path to a problem library macros
# directory which contains a PG.pl file, this file will be loaded and allowed to
# engage in privileged behavior.
# 
# =head3 Overloading macro files
# 
# An individual course can modify the PG language, for that course only, by
# duplicating one of the macro files in the system-wide macros directory and
# placing this file in the macros directory for the course. The new file in the
# course's macros directory will now be used instead of the file in the
# system-wide macros directory.
# 
# The new file in the course macros directory can by modified by adding macros or
# modifying existing macros.
# 
# =head3 Modifying existing macros
# 
# I<Modifying macros is for users with some experience.>
# 
# Modifying existing macros might break other standard macros or problems which
# depend on the unmodified behavior of these macors so do this with great caution.
# In addition problems which use new macros defined in these files or which depend
# on the modified behavior of existing macros will not work in other courses
# unless the macros are also transferred to the new course.  It helps to document
# the  problems by indicating any special macros which the problems require.
# 
# There is no facility for modifying or overloading a single macro. The entire
# file containing the macro must be overloaded.
# 
# Modifications to files in the course macros directory affect only that course,
# they will not interfere with the normal behavior of WeBWorK in other courses.
# 
# =cut
# 
# # Global variables used
# #   ${main::macrosPath}
# # Global macros used
# #	None
# 
# # Because of the need to use the directory variables it is tricky to define this
# # in translate.pl since, as currently written, the directories are not available
# # at that time.  Perhaps if I rewrite translate as an object that method will work.
# 
# # The only difficulty with defining loadMacros inside the Safe compartment is that
# # the error reporting does not work with syntax errors.
# # A kludge using require works around this problem
# 
# 
# # ^function loadMacros
# # ^uses time_it
# # ^uses $debugON
# # ^uses $externalTTHPath
# # ^uses findMacroFile
# sub loadMacros {
#     my @files = @_;
#     my $fileName;
#     eval {main::time_it("begin load macros");};
#     ###############################################################################
# 	# At this point the directories have been defined from %envir and we can define
# 	# the directories for this file
# 	###############################################################################
#    
# 	# special case inits
# 	foreach my $file ('PG.pl','dangerousMacros.pl','IO.pl') {
# 	    my $macro_file_name = $file;
# 		$macro_file_name =~s/\.pl//;  # trim off the extension
# 		$macro_file_name =~s/\.pg//;  # sometimes the extension is .pg (e.g. CAPA files)
# 		my $init_subroutine_name = "_${macro_file_name}_init";
#     	my $init_subroutine  = eval { \&{$init_subroutine_name} };
# 		use strict;
#         my $macro_file_loaded = defined($init_subroutine);
#         warn "dangerousMacros: macro init $init_subroutine_name defined |$init_subroutine| |$macro_file_loaded|" if $debugON;
#  		if ( defined($init_subroutine) && defined( &{$init_subroutine} ) ) {
# 
# 		    warn "dangerousMacros:  initializing $macro_file_name"  if $debugON;
# 		    &$init_subroutine();
# 		}
# 	}
#     unless (defined( $externalTTHPath)){
#     	warn "WARNING::Please make sure that the DOCUMENT() statement comes before<BR>\n" .
#     	     " the loadMacros() statement in the problem template.<p>" .
#     	     " The externalTTHPath variable |$externalTTHPath| was\n".
#     	     " not defined which usually indicates the problem above.<br>\n";
# 
#     }
#     #warn "running load macros";
#     while (@files) {
#         $fileName = shift @files;
#         next  if ($fileName =~ /^PG.pl$/) ;    # the PG.pl macro package is already loaded.
# 
#         my $macro_file_name = $fileName;
# 		$macro_file_name =~s/\.pl//;  # trim off the extension
# 		$macro_file_name =~s/\.pg//;  # sometimes the extension is .pg (e.g. CAPA files)
# 		my $init_subroutine_name = "_${macro_file_name}_init";
# 		$init_subroutine_name =~ s![^a-zA-Z0-9_]!_!g;  # remove dangerous chars
# 
#  		###############################################################################
# 		# For some reason the "no stict" which works on webwork-db doesn't work on
# 		# webwork.  For this reason the constuction &{$init_subroutine_name}
# 		# was abandoned and replaced by eval.  This is considerably more dangerous
# 		# since one could hide something nasty in a file name.
# 		#  Keep an eye on this ???
# 		# webwork-db used perl 5.6.1 and webwork used perl 5.6.0 
# 		###############################################################################
# 
# 		# compile initialization subroutine. (5.6.0 version)
# 
# 		
# #		eval( q{ \$init_subroutine = \\&main::}.$init_subroutine_name);
# #		warn "dangerousMacros: failed to compile $init_subroutine_name. $@" if $@;
# 
# 
# 		###############################################################################
# 		#compile initialization subroutine. (5.6.1 version) also works with 5.6.0
# 
# # 		no strict;
#  		my $init_subroutine  = eval { \&{'main::'.$init_subroutine_name} };
# # 		use strict;
# 
# 		###############################################################################
# 
#         # macros are searched for in the directories listed in the $macrosPath array reference.
#         
#         my $macro_file_loaded = defined($init_subroutine) && defined(&$init_subroutine);
#         warn "dangerousMacros: macro init $init_subroutine_name defined |$init_subroutine| |$macro_file_loaded|"  if $debugON;
#         unless ($macro_file_loaded) {
#         	warn "loadMacros: loading macro file $fileName\n" if $debugON;
# 		my $filePath = findMacroFile($fileName);
# 		#### (check for renamed files here?) ####
# 		if ($filePath) {
# 			compile_file($filePath); 
# 			#warn "loadMacros is compiling $filePath\n";
# 		}
# 		else {
# 		  die "Can't locate macro file |$fileName| via path: |".join("|, |",@{$macrosPath})."|";
# 		}
# 		}
# 		###############################################################################
# 		# Try again to define the initialization subroutine. (5.6.0 version)
# 		
# #		eval( q{ \$init_subroutine = \\&main::}.$init_subroutine_name );
# #		warn "dangerousMacros: failed to compile $init_subroutine_name. $@" if $@;
# #		$init_subroutine = $temp::rf_init_subroutine;
# 		###############################################################################
# 		# Try again to define the initialization subroutine. (5.6.1 version) also works with 5.6.0	
# 			
# # 		no strict;            
#  		$init_subroutine  = eval { \&{'main::'.$init_subroutine_name} };
# # 		use strict;
# 		###############################################################################
# 		#warn "loadMacros: defining \$temp::rf_init_subroutine ",$temp::rf_init_subroutine;
#        $macro_file_loaded = defined($init_subroutine) && defined(&$init_subroutine);
#        warn "dangerousMacros: macro init $init_subroutine_name defined |$init_subroutine| |$macro_file_loaded|" if $debugON;
# 
# 		if ( defined($init_subroutine) && defined( &{$init_subroutine} ) ) {
# 		    warn "dangerousMacros:  initializing $macro_file_name" if $debugON;
# 		    &$init_subroutine();
# 		}
# 		#warn "main:: contains <br>\n $macro_file_name ".join("<br>\n $macro_file_name ", %main::);
# 	}
# 	eval{main::time_it("end load macros");};
# }
# 
# #
# #  Look for a macro file in the directories specified in the macros path
# #
# 
# # ^function findMacroFile
# # ^uses $macrosPath
# # ^uses $pwd
# sub findMacroFile {
#   my $fileName = shift;
#   my $filePath;
#   foreach my $dir (@{$macrosPath}) {
#     $filePath = "$dir/$fileName";
#     $filePath =~ s!^\.\.?/!$pwd/!;
#     return $filePath if (-r $filePath);
#   }
#   return;  # no file found
# }
# 
# # ^function check_url
# # ^uses %envir
# sub check_url {
# 	my $url  = shift;
# 	return undef if $url =~ /;/;   # make sure we can't get a second command in the url
# 	#FIXME -- check for other exploits of the system call
# 	#FIXME -- ALARM feature so that the response cannot be held up for too long.
# 	#FIXME doesn't seem to work with relative addresses.
# 	#FIXME  Can we get the machine name of the server?
# 
# 	 my $check_url_command = $envir{externalCheckUrl};
# 	 my $response = system("$check_url_command $url"); 
# 	return ($response) ? 0 : 1; # 0 indicates success, 256 is failure possibly more checks can be made
# }
# 
# # ^variable our %appletCodebaseLocations
# our %appletCodebaseLocations = ();
# # ^function findAppletCodebase
# # ^uses %appletCodebaseLocations
# # ^uses $appletPath
# # ^uses $server_root_url
# # ^uses check_url
# sub findAppletCodebase {
# 	my $fileName = shift;  # probably the name of a jar file
# 	return $appletCodebaseLocations{$fileName}    #check cache first
# 		if defined($appletCodebaseLocations{$fileName})
# 			and $appletCodebaseLocations{$fileName} =~/\S/;
# 	
# 	foreach my $appletLocation (@{$appletPath}) {
# 		if ($appletLocation =~ m|^/|) {
# 			$appletLocation = "$server_root_url$appletLocation";
# 		}
# 		return $appletLocation;  # --hack workaround -- just pick the first location and use that -- no checks
# #hack to workaround conflict between lwp-request and apache2
# # comment out the check_url block
# # 		my $url = "$appletLocation/$fileName";
# # 		if (check_url($url)) {
# # 				$appletCodebaseLocations{$fileName} = $appletLocation; #update cache
# # 			return $appletLocation	 # return codebase part of url
# # 		}
#  	}
#  	return "Error: $fileName not found at ". join(",	", @{$appletPath} );	# no file found
# }
# # errors in compiling macros is not always being reported.
# # ^function compile_file
# # ^uses @__eval__
# # ^uses PG_restricted_eval
# # ^uses $__files__
# sub compile_file {
#  	my $filePath = shift;
#  	warn "loading $filePath" if $debugON; 
#  	local(*MACROFILE);
#  	local($/);
#  	$/ = undef;   # allows us to treat the file as a single line
#  	open(MACROFILE, "<$filePath") || die "Cannot open file: $filePath";
#  	my $string = 'BEGIN {push @__eval__, __FILE__};' . "\n" . <MACROFILE>;
#  	my ($result,$error,$fullerror) = &PG_restricted_eval($string);
# 	eval ('$main::__files__->{pop @main::__eval__} = $filePath');
#  	if ($error) {    # the $fullerror report has formatting and is never empty
#                 # this is now handled by PG_errorMessage() in the PG translator
#  		#$fullerror =~ s/\(eval \d+\)/ $filePath\n/;   # attempt to insert file name instead of eval number
#  		die "Error detected while loading $filePath:\n$fullerror";
# 
#  	}
# 
#  	close(MACROFILE);
# 
# }
# 
# # This creates on the fly graphs
# 
# =head2 insertGraph
# 
# 	# returns a path to the file containing the graph image.
# 	$filePath = insertGraph($graphObject);
# 
# insertGraph writes a GIF or PNG image file to the gif subdirectory of the
# current course's HTML temp directory. The file name is obtained from the graph
# object. Warnings are issued if errors occur while writing to the file.
# 
# Returns a string containing the full path to the temporary file containing the
# image. This is most often used in the construct
# 
# 	TEXT(alias(insertGraph($graph)));
# 
# where alias converts the directory address to a URL when serving HTML pages and
# insures that an EPS file is generated when creating TeX code for downloading.
# 
# =cut
# 
# # ^function insertGraph
# # ^uses $WWPlot::use_png
# # ^uses convertPath
# # ^uses surePathToTmpFile
# # ^uses PG_restricted_eval
# # ^uses $refreshCachedImages
# # ^uses $templateDirectory
# # ^uses %envir
# sub insertGraph {
# 		    # Convert the image to GIF and print it on standard output
# 	my $graph = shift;
# 	my $extension = ($WWPlot::use_png) ? '.png' : '.gif';
# 	my $fileName = $graph->imageName  . $extension;
# 	my $filePath = convertPath("gif/$fileName");
# 	$filePath = &surePathToTmpFile( $filePath );
# 	my $refreshCachedImages = PG_restricted_eval(q!$refreshCachedImages!);
# 	# Check to see if we already have this graph, or if we have to make it
# 	if( not -e $filePath # does it exist?
# 	  or ((stat "$templateDirectory"."$main::envir{fileName}")[9] > (stat $filePath)[9]) # source has changed
# 	  or $graph->imageName =~ /Undefined_Set/ # problems from SetMaker and its ilk should always be redone
# 	  or $refreshCachedImages
# 	) {
#  		#createFile($filePath, $main::tmp_file_permission, $main::numericalGroupID);
# 		local(*OUTPUT);  # create local file handle so it won't overwrite other open files.
#  		open(OUTPUT, ">$filePath")||warn ("$0","Can't open $filePath<BR>","");
#  		chmod( 0777, $filePath);
#  		print OUTPUT $graph->draw|| warn("$0","Can't print graph to $filePath<BR>","");
#  		close(OUTPUT)||warn("$0","Can't close $filePath<BR>","");
# 	}
# 	$filePath;
# }
# 
# =head2 [DEPRECATED] tth
# 
# 	# returns an HTML version of the TeX code passed to it.
# 	tth($texString);
# 
# This macro sends $texString to the filter program TtH, a TeX to HTML translator
# written by Ian Hutchinson. TtH is available free of change non-commerical
# use at L<http://hutchinson.belmont.ma.us/tth/>.
# 
# The purpose of TtH is to translate text in the TeX or LaTeX markup language into
# HTML markup as best as possible.  Some symbols, such as square root symbols are
# not translated completely.  Macintosh users must use the "MacRoman" encoding
# (available in 4.0 and higher browsers) in order to view the symbols correctly. 
# WeBWorK attempts to force Macintosh browsers to use this encoding when such a
# browser is detected.
# 
# The contents of the file F<tthPreamble.tex> in the courses template directory
# are prepended to each string.  This allows one to define TeX macros which can be
# used in every problem. Currently there is no default F<tthPreamble.tex> file, so
# if the file is not present in the course template directory no TeX macro
# definitions are prepended. TtH already understands most LaTeX commands, but will
# not in general know AMS-LaTeX commands.
# 
# This macro contains code which is system dependent and may need to be modified
# to run on different systems.
# 
# =cut
# 
# # the contents of this file will not change during problem compilation it
# # only needs to be read once. however, the contents of the file may change,
# # and indeed the file refered to may change, between rendering passes. thus,
# # we need to keep track of the file name and the mtime as well.
# # ^variable my $tthPreambleFile
# # ^variable my $tthPreambleMtime
# # ^variable my $tthPreambleContents
# my ($tthPreambleFile, $tthPreambleMtime, $tthPreambleContents);
# 
# # ^function tth
# # ^uses $templateDirectory
# # ^uses $envir{externalTTHPath}
# # ^uses $tthPreambleFile
# # ^uses $tthPreambleMtime
# # ^uses $tthPreambleContents
# sub tth {
# 	my $inputString = shift;
# 	
# 	my $thisFile = "${templateDirectory}tthPreamble.tex" if -r "${templateDirectory}tthPreamble.tex";
# 	
# 	if (defined $thisFile) {
# 		my $thisMtime = (stat $thisFile)[9];
# 		my $load = 
# 			# load preamble if we haven't loaded it ever
# 			(not defined $tthPreambleFile or not defined $tthPreambleMtime or not defined $tthPreambleContents)
# 				||
# 			# load if the file path has changed
# 			($tthPreambleFile ne $thisFile)
# 				||
# 			# load if the file has been modified
# 			($tthPreambleMtime < $thisMtime);
# 		
# 		if ($load) {
# 			local(*TTHIN);
# 			open (TTHIN, "${templateDirectory}tthPreamble.tex") || die "Can't open file ${templateDirectory}tthPreamble.tex";
# 			local($/);
# 			$/ = undef;
# 			$tthPreambleContents = <TTHIN>;
# 			close(TTHIN);
# 
# 			$tthPreambleContents =~ s/(.)\n/$1%\n/g;  # thanks to Jim Martino
# 			                                          # each line in the definition file
# 			                                          # should end with a % to prevent
# 			                                          # adding supurious paragraphs to output.
# 
# 			$tthPreambleContents .="%\n";             # solves the problem if the file doesn't end with a return.
# 		}
# 	} else {
# 		$tthPreambleContents = "";
# 	}
# 	
#     $inputString = $tthPreambleContents . $inputString;
#     $inputString    = "<<END_OF_TTH_INPUT_STRING;\n\n\n" . $inputString . "\nEND_OF_TTH_INPUT_STRING\necho \"\" >/dev/null"; #it's not clear why another command is needed.
# 
# 	# $tthpath is now taken from $Global::externalTTHPath via %envir.
#     my $tthpath     = $envir{externalTTHPath};
#     my $out;
# 
#     if (-x $tthpath ) {
#     	my $tthcmd      = "$tthpath -L -f5 -u -r  2>/dev/null " . $inputString;
#     	if (open(TTH, "$tthcmd   |")) {
#     	    local($/);
# 			$/ = undef;
# 			$out = <TTH>;
# 			$/ = "\n";
# 			close(TTH);
# 	    }else {
# 	        $out = "<BR>there has been an error in executing $tthcmd<BR>";
# 	    }
# 	} else {
# 		$out = "<BR> Can't execute the program tth at |$tthpath|<BR>";
#     }
# 
#     $out;
# }
# 
# # possible solution to the tth font problem?  Works only for iCab.
# # ^function symbolConvert
# sub symbolConvert {
# 	my	$string = shift;
# 	$string =~ s/\x5C/\&#092;/g;		#\      92                       &#092;
# 	$string =~ s/\x7B/\&#123;/g;		#{      123                       &#123;
# 	$string =~ s/\x7D/\&#125;/g;		#}      125                       &#125;
# 	$string =~ s/\xE7/\&#193;/g;		#Á      231                       &#193;
# 	$string =~ s/\xE6/\&#202;/g;		#Ê      230                       &#202;
# 	$string =~ s/\xE8/\&#203;/g;		#Ë      232                       &#203;
# 	$string =~ s/\xF3/\&#219;/g;		#Û      243                       &#219;
# 	$string =~ s/\xA5/\&bull;/g;		#€      165                       &bull;
# 	$string =~ s/\xB2/\&le;/g;			#¾      178                       &le;
# 	$string =~ s/\xB3/\&ge;/g;			#„      179                       &ge;
# 	$string =~ s/\xB6/\&part;/g;		#      182                       &part;
# 	$string =~ s/\xCE/\&#338;/g;		#‘      206                       &#338;
# 	$string =~ s/\xD6/\&#732/g;			#÷      214                       &#732;
# 	$string =~ s/\xD9/\&Yuml;/g;		#      217                       &Yuml;
# 	$string =~ s/\xDA/\&frasl;/g;		#Ž      218                       &frasl;
# 	$string =~ s/\xF5/\&#305;/g;		#ž      245                       &#305
# 	$string =~ s/\xF6/\&#710;/g;		#–      246                       &#710;
# 	$string =~ s/\xF7/\&#193;/g;		#—      247                       &#193;
# 	$string =~ s/\xF8/\&#175;/g;		#¯      248                       &#175;
# 	$string =~ s/\xF9/\&#728;/g;		#˜      249                       &#728;
# 	$string =~ s/\xFA/\&#729;/g;		#™      250                       &#729;
# 	$string =~ s/\xFB/\&#730;;/g;		#š      251                       &#730;
# 	$string;
# }
# 
# # ----- ----- ----- -----
# 
# =head2 [DEPRECATED] math2img
# 
# 	# returns an IMG tag pointing to an image version of the supplied TeX
# 	math2img($texString);
# 
# This macro was used by the HTML_img display mode, which no longer exists.
# 
# =cut
# 
# # ^variable my $math2imgCount
# my $math2imgCount = 0;
# 
# # ^function math2img
# # ^uses $math2imgCount
# # ^uses $envir{templateDirectory}
# # ^uses $envir{fileName}
# # ^uses $envir{studentLogin}
# # ^uses $envir{setNumber}
# # ^uses $envir{probNum}
# # ^uses $envir{tempURL}
# # ^uses $envir{refreshMath2img}
# # ^uses $envir{dvipngTempDir}
# # ^uses $envir{externalLaTeXPath}
# # ^uses $envir{externalDvipngPath}
# sub math2img {
# 	my $tex = shift;
# 	my $mode = shift;
# 
# 	my $sourcePath = $envir{templateDirectory} . "/" . $envir{fileName};
# 	my $tempFile = "m2i/$envir{studentLogin}.$envir{setNumber}.$envir{probNum}."
# 		. $math2imgCount++ . ".png";
# 	my $tempPath = surePathToTmpFile($tempFile); #my $tempPath = "$envir{tempDirectory}$tempFile";
# 	my $tempURL = "$envir{tempURL}/$tempFile";
# 	my $forceRefresh = $envir{refreshMath2img};
# 	my $imageMissing = not -e $tempPath;
# 	my $imageStale   = (stat $sourcePath)[9] > (stat $tempPath)[9] if -e $tempPath;
# 	if ($forceRefresh or $imageMissing or $imageStale) {
# 		# image file doesn't exist, or source file is newer then image file
# 		#warn "math2img: refreshMath2img forcing image generation for $tempFile\n" if $forceRefresh;
# 		#warn "math2img: $tempFile doesn't exist, so generating it\n" if $imageMissing;
# 		#warn "math2img: source file (", (stat $sourcePath)[9], ") is newer than image file (",
# 		#	(stat $tempPath)[9], ") so re-generating image\n" if $imageStale;
# 		if (-e $tempPath) {
# 			unlink $tempPath or die "Failed to delete stale math2img file $tempPath: $!";
# 		}
# 		dvipng(
# 			$envir{dvipngTempDir}, $envir{externalLaTeXPath},
# 			$envir{externalDvipngPath}, $tex, $tempPath
# 		);
# 	}
# 
# 	if (-e $tempPath) {
# 		return "<img align=\"middle\" src=\"$tempURL\" alt=\"$tex\">"            if $mode eq "inline";
# 		return "<div align=\"center\"><img src=\"$tempURL\" alt=\"$tex\"></div>" if $mode eq "display";
# 	} else {
# 		return "<b>[math2img failed]</b>";
# 		# it might be nice to call tth here as a fallback instead:
# 		#return tth($tex);
# 	}
# };
# 
# =head2 [DEPRECATED] dvipng
# 
# 	dvipng($working_directory, $latex_path, $dvipng_path, $tex_string, $target_path)
# 
# This macro was used by the HTML_img display mode, which no longer exists.
# 
# =cut
# 
# # copied from IO.pm for backward compatibility with WeBWorK1.8;
# # ^function dvipng
# sub dvipng($$$$$) {
# 	my (
# 		$wd,        # working directory, for latex and dvipng garbage
# 		            # (must already exist!)
# 		$latex,     # path to latex binary
# 		$dvipng,    # path to dvipng binary
# 		$tex,       # tex string representing equation
# 		$targetPath # location of resulting image file
# 	) = @_;
# 
# 	my $dvipngBroken = 0;
# 
# 	my $texFile  = "$wd/equation.tex";
# 	my $dviFile  = "$wd/equation.dvi";
# 	my $dviFile2 = "$wd/equationequation.dvi";
# 	my $dviCall  = "equation";
# 	my $pngFile  = "$wd/equation1.png";
# 
# 	unless (-e $wd) {
# 		die "dvipng working directory $wd doesn't exist -- caller should have created it for us!\n";
# 		return 0;
# 	}
# 
# 	# write the tex file
# 	local *TEX;
# 	open TEX, ">", $texFile or warn "Failed to create $texFile: $!";
# 	print TEX <<'EOF';
# % BEGIN HEADER
# \batchmode
# \documentclass[12pt]{article}
# \usepackage{amsmath,amsfonts,amssymb}
# \def\gt{>}
# \def\lt{<}
# \usepackage[active,textmath,displaymath]{preview}
# \begin{document}
# % END HEADER
# EOF
# 	print TEX "\\( \\displaystyle{$tex} \\)\n";
# 	print TEX <<'EOF';
# % BEGIN FOOTER
# \end{document}
# % END FOOTER
# EOF
# 	close TEX;
# 
# 	# call latex
# 	system "cd $wd && $latex $texFile > /dev/null"
# 		and warn "Failed to call $latex with $texFile: $!";
# 
# 	unless (-e $dviFile) {
# 		warn "Failed to generate DVI file $dviFile";
# 		return 0;
# 	}
# 
# 	if ($dvipngBroken) {
# 		# change the name of the DVI file to get around dvipng's
# 		# crackheadedness. This is no longer needed with the newest
# 		# version of dvipng (10 something)
# 		system "/bin/mv", $dviFile, $dviFile2;
# 	}
# 
# 	# call dvipng -- using warn instead of die passes some extra information
# 	# back to the user the complete warning is still printed in the apache
# 	# error log and a simple message (math2img failed) is returned to the
# 	# webpage.
# 	my $cmdout;
# 	$cmdout = system "cd $wd && $dvipng $dviCall > /dev/null"
# 		and warn "Failed to call$dvipng with $dviCall: $! with signal $cmdout";
# 
# 	unless (-e $pngFile) {
# 		warn "Failed to create PNG file $pngFile";
# 		return 0;
# 	}
# 
# 	$cmdout = system "/bin/mv", $pngFile, $targetPath and warn "Failed to mv: /bin/mv  $pngFile $targetPath $!. Call returned $cmdout. \n";
# }
# 
# ----- ----- ----- -----
# 
# =head2  alias
# 
# 	# In HTML modes, returns the URL of a web-friendly version of the specified file.
# 	# In TeX mode, returns the path to a TeX-friendly version of the specified file.
# 	alias($pathToFile);
# 
# alias allows you to refer to auxiliary files which are in a directory along with
# the problem definition. In addition alias creates an EPS version of GIF or PNG
# files when called in TeX mode.
# 
# As a rule auxiliary files that are used by a number of problems in a course
# should be placed in C<html/gif> or C<html> or in a subdirectory of the C<html>
# directory, while auxiliary files which are used in only one problem should be
# placed in the same directory as the problem in order to make the problem more
# portable.
# 
# =head3 Specific behavior of the alias macro
# 
# =head4 Files in the html subdirectory
# 
# =over
# 
# =item When not in TeX mode
# 
# If the file lies under the F<html> subdirectory, then the approriate URL for the
# file is returned. Since the F<html> subdirectory is already accessible to the
# webserver no other changes need to be made. The file path for this type of file
# should be the complete file path. The path should start with the prefix defined
# in $courseDirs{html_temp} in global.conf.
# 
# =item When in TeX mode
# 
# GIF and PNG files will be translated into EPS files and placed in the directory
# F<tmp/eps>. The full path to this file is returned for use by TeX in producing
# the hard copy. The conversion is done by a system dependent commands defined in
# F<global.conf> $externalPrograms{gif2eps} (for GIF images) or
# $externalPrograms{png2eps} (for PNG images). The URLs for the other files are
# produced as in non-TeX mode but will of course not be usable to TeX.
# 
# =back
# 
# =head4 Files in the tmp subdirectory
# 
# =over
# 
# =item When not in TeX mode
# 
# If the file lies under the F<tmp> subdirectory, then the approriate URL for the
# file is created. Since the F<tmp> subdirectory is already accessible to the
# webserver no other changes need to be made. The file path for this type of file
# should be the complete file path. The path should start with the prefix defined
# in $courseDirs{html_temp} in global.conf.
# 
# =item When in TeX mode
# 
# GIF and PNG files will be translated into EPS files and placed in the directory
# F<tmp/eps>. The full path to this file is returned for use by TeX in producing
# the hard copy. The conversion is done by a system dependent commands defined in
# F<global.conf> $externalPrograms{gif2eps} (for GIF images) or
# $externalPrograms{png2eps} (for PNG images). The URLs for the other files are
# produced as in non-TeX mode but will of course not be usable to TeX.
# 
# =back
# 
# =head4 Files in the course template subdirectory
# 
# =over
# 
# =item When not in TeX mode
# 
# If the file lies under the course templates subdirectory, it is assumed to lie
# in subdirectory rooted in the directory containing the problem template file. An
# alias is created under the F<html/tmp/gif> or F<html/tmp/html> directory and
# linked to the original file. The file path for this type of file is a relative
# path rooted at the directory containing the problem template file.
# 
# =item When in TeX mode
# 
# GIF and PNG files will be translated into EPS files and placed in the directory
# F<tmp/eps>. The full path to this file is returned for use by TeX in producing
# the hard copy. The conversion is done by a system dependent commands defined in
# F<global.conf> $externalPrograms{gif2eps} (for GIF images) or
# $externalPrograms{png2eps} (for PNG images). The URLs for the other files are
# produced as in non-TeX mode but will of course not be usable to TeX.
# 
# =back
# 
# =cut
# 

# 
# # Currently gif, html and types are supported.
# #
# # If the auxiliary file path has not extension then the extension .gif isassumed.
# #
# # If the auxiliary file path leads to a file in the ${Global::htmlDirectory}
# # no changes are made to the file path.
# #
# # If the auxiliary file path is not complete, than it is assumed that it refers
# # to a subdirectoy of the directory containing the problem..
# #
# # The output is either the correct URL for the file
# # or (in TeX mode) the complete path to the eps version of the file
# # and can be used as input into the image macro.
# #
# # surePathToTmpFile takes a path and outputs the complete path:
# # ${main::htmlDirectory}/tmp/path
# # It insures that all of the directories in the path have been created,
# # but does not create the
# # final file.
# 
# # For postscript printing, alias generates an eps version of the gif image and places
# # it in the directory eps.  This slows down downloading postscript versions somewhat,
# # but not excessivevly.
# # Alias does not do any garbage collection, so files and alias may accumulate and
# # need to be removed manually or by a reaper daemon.
# 
# # This subroutine  has commands which will not work on non-UNIX environments.
# # system("cat $gifSourceFile  | /usr/math/bin/giftopnm | /usr/math/bin/pnmdepth 1 | /usr/math/bin/pnmtops -noturn>$adr_output") &&
# 
# # ^function alias
# # ^uses %envir
# # ^uses $envir{fileName}
# # ^uses $envir{htmlDirectory}
# # ^uses $envir{htmlURL}
# # ^uses $envir{tempDirectory}
# # ^uses $envir{tempURL}
# # ^uses $envir{studentLogin}
# # ^uses $envir{psvnNumber}
# # ^uses $envir{setNumber}
# # ^uses $envir{probNum}
# # ^uses $envir{displayMode}
# # ^uses $envir{externalGif2EpsPath}
# # ^uses $envir{externalPng2EpsPath}
# # ^uses &surePathToTmpFile
# # ^uses &convertPath
# # ^uses &directoryFromPath
# # ^uses &fileFromPath
# # ^uses $envir{texDisposition}

# sub alias {
# 	# input is a path to the original auxiliary file
# 	my $envir               = eval(q!\%main::envir!);  # get the current root environment
#   	my $fileName            = $envir->{fileName};
# 	my $htmlDirectory       = $envir->{htmlDirectory};
# 	my $htmlURL             = $envir->{htmlURL};
# 	my $tempDirectory       = $envir->{tempDirectory};
# 	my $tempURL             = $envir->{tempURL};
# 	my $studentLogin        = $envir->{studentLogin};
# 	my $psvnNumber          = $envir->{psvnNumber};
# 	my $setNumber           = $envir->{setNumber};
# 	my $probNum             = $envir->{probNum};
# 	my $displayMode         = $envir->{displayMode};
#     my $externalGif2EpsPath = $envir->{externalGif2EpsPath};
#     my $externalPng2EpsPath = $envir->{externalPng2EpsPath};
# 
# 	my $aux_file_path = shift @_;
# 	warn "Empty string used as input into the function alias" unless $aux_file_path;
# 	#
# 	#  Find auxiliary files even when the main file is in tempates/tmpEdit
# 	#
# 	$fileName =~ s!(^|/)tmpEdit/!\1!;
# 
# 	# problem specific data
# 	warn "The path to the current problem file template is not defined."     unless $fileName;
# 	warn "The current studentLogin is not defined "                          unless $studentLogin;
# 	warn "The current problem set number is not defined"                     if $setNumber eq ""; # allow for sets equal to 0
# 	warn "The current problem number is not defined"                         if $probNum eq "";
# 	warn "The current problem set version number (psvn) is not defined"      unless defined($psvnNumber);
# 	warn "The displayMode is not defined"                                    unless $displayMode;
# 
# 	# required macros
# 	warn "The macro &surePathToTmpFile can't be found" unless defined(&surePathToTmpFile);
# 	warn "The macro &convertPath can't be found" unless defined(&convertPath);
# 	warn "The macro &directoryFromPath can't be found" unless defined(&directoryFromPath);
# 	# warn "The webwork server does not have permission to execute the gif2eps script at  ${externalGif2EpsPath}." unless ( -x "${externalGif2EpsPath}" );
# 	# warn "The webwork server does not have permission to execute the png2eps script at ${externalPng2EpsPath}." unless ( -x "${externalPng2EpsPath}" );
# 
# 	# required directory addresses (and URL address)
# 	warn "htmlDirectory is not defined in $htmlDirectory" unless $htmlDirectory;
# 	warn "htmlURL is not defined in \$htmlURL" unless $htmlURL;
# 	warn "tempURL is not defined in \$tempURL" unless $tempURL;
# 
# 	# determine extension, if there is one
# 	# if extension exists, strip and use the value for $ext
# 	# files without extensions are considered to be picture files:
# 
# 	my $ext;
# 	if ($aux_file_path =~ s/\.([^\.]*)$// ) {
# 		$ext = $1;
# 	} else {
# 		warn "This file name $aux_file_path did not have an extension.<BR> " .
# 		     "Every file name used as an argument to alias must have an extension.<BR> " .
# 		     "The permissable extensions are .gif, .png, and .html .<BR>";
# 		$ext  = "gif";
# 	}
# 
# 	# $adr_output is a url in HTML and Latex2HTML modes
# 	# and a complete path in TEX mode.
# 	my $adr_output;
# 
# 	# in order to facilitate maintenance of this macro the routines for handling
# 	# different file types are defined separately.  This involves some redundancy
# 	# in the code but it makes it easier to define special handling for a new file
# 	# type, (but harder to change the behavior for all of the file types at once
# 	# (sigh)  ).
# 
# 
# 	if ($ext eq 'html') {
# 		################################################################################
# 		# .html FILES in HTML, HTML_tth, HTML_dpng, HTML_img, etc. and Latex2HTML mode
# 		################################################################################
# 
# 		# No changes are made for auxiliary files in the
# 		# ${Global::htmlDirectory} subtree.
# 		if ( $aux_file_path =~ m|^$tempDirectory| ) {
# 			$adr_output = $aux_file_path;
# 			$adr_output =~ s|$tempDirectory|$tempURL/|;
# 			$adr_output .= ".$ext";
# 		} elsif ($aux_file_path =~ m|^$htmlDirectory| ) {
# 			$adr_output = $aux_file_path;
# 			$adr_output =~ s|$htmlDirectory|$htmlURL|;
# 			$adr_output .= ".$ext";
# 		} else {
# 			# HTML files not in the htmlDirectory are assumed under live under the
# 			# templateDirectory in the same directory as the problem.
# 			# Create an alias file (link) in the directory html/tmp/html which
# 			# points to the original file and return the URL of this alias.
# 			# Create all of the subdirectories of html/tmp/html which are needed
# 			# using sure file to path.
# 
# 			# $fileName is obtained from environment for PGeval
# 			# it gives the  full path to the current problem
# 			my $filePath = directoryFromPath($fileName);
# 			my $htmlFileSource = convertPath("$templateDirectory${filePath}$aux_file_path.html");
# 			my $link = "html/$studentLogin-$psvnNumber-set$setNumber-prob$probNum-$aux_file_path.$ext";
# 			my $linkPath = surePathToTmpFile($link);
# 			$adr_output = "${tempURL}$link";
# 			if (-e $htmlFileSource) {
# 				if (-e $linkPath) {
# 					unlink($linkPath) || warn "Unable to unlink alias file at |$linkPath|";
# 					# destroy the old link.
# 				}
# 				symlink( $htmlFileSource, $linkPath)
# 			    		|| warn "The macro alias cannot create a link from |$linkPath|  to |$htmlFileSource| <BR>" ;
# 			} else {
# 				warn("The macro alias cannot find an HTML file at: |$htmlFileSource|");
# 			}
# 		}
# 	} elsif ($ext eq 'gif') {
# 		if ( $displayMode eq 'HTML' ||
# 		     $displayMode eq 'HTML_tth'||
# 		     $displayMode eq 'HTML_dpng'||
# 		     $displayMode eq 'HTML_asciimath'||
# 		     $displayMode eq 'HTML_LaTeXMathML'||
# 		     $displayMode eq 'HTML_jsMath'||
# 		     $displayMode eq 'HTML_img'||
# 		     $displayMode eq 'Latex2HTML')  {
# 			################################################################################
# 			# .gif FILES in HTML, HTML_tth, HTML_dpng, HTML_img, and Latex2HTML modes
# 			################################################################################
# 
# 			#warn "tempDirectory is $tempDirectory";
# 			#warn "file Path for auxiliary file is $aux_file_path";
# 
# 			# No changes are made for auxiliary files in the htmlDirectory or in the tempDirectory subtree.
# 			if ( $aux_file_path =~ m|^$tempDirectory| ) {
# 				$adr_output = $aux_file_path;
# 				$adr_output =~ s|$tempDirectory|$tempURL|;
# 				$adr_output .= ".$ext";
# 				#warn "adress out is $adr_output";
# 			} elsif ($aux_file_path =~ m|^$htmlDirectory| ) {
# 				$adr_output = $aux_file_path;
# 				$adr_output =~ s|$htmlDirectory|$htmlURL|;
# 				$adr_output .= ".$ext";
# 			} else {
# 				# files not in the htmlDirectory sub tree are assumed to live under the templateDirectory
# 				# subtree in the same directory as the problem.
# 
# 				# For a gif file the alias macro creates an alias under the html/images directory
# 				# which points to the gif file in the problem directory.
# 				# All of the subdirectories of html/tmp/gif which are needed are also created.
# 				my $filePath = directoryFromPath($fileName);
# 
# 				# $fileName is obtained from environment for PGeval
# 				# it gives the full path to the current problem
# 				my $gifSourceFile = convertPath("$templateDirectory${filePath}$aux_file_path.gif");
# 				#my $link = "gif/$studentLogin-$psvnNumber-set$setNumber-prob$probNum-$aux_file_path.$ext";
# 
# 				#  Make file names work in Library Browser when the images in several
# 				#  files have the same names.
# 				my $libFix = "";
# 				if ($setNumber eq "Undefined_Set") {
# 				  $libFix = $fileName;
# 				  $libFix =~ s!.*/!!; $libFix =~ s!\.pg(\..*)?$!!;
# 				  $libFix =~ s![^a-zA-Z0-9._-]!!g;
# 				  $libFix .= '-';
# 				}
# 
# 				my $link = "gif/$setNumber-prob$probNum-$libFix$aux_file_path.$ext";
# 
# 				my $linkPath = surePathToTmpFile($link);
# 				$adr_output = "${tempURL}$link";
# 				#warn "linkPath is $linkPath";
# 				#warn "adr_output is $adr_output";
# 				if (-e $gifSourceFile) {
# 					if (-e $linkPath) {
# 						unlink($linkPath) || warn "Unable to unlink old alias file at $linkPath";
# 					}
# 					symlink($gifSourceFile, $linkPath)
# 						|| warn "The macro alias cannot create a link from |$linkPath|  to |$gifSourceFile| <BR>" ;
# 				} else {
# 					warn("The macro alias cannot find a GIF file at: |$gifSourceFile|");
# 				}
# 			}
# 		} elsif ($displayMode eq 'TeX') {
# 			################################################################################
# 			# .gif FILES in TeX mode
# 			################################################################################
# 
# 		        $setNumber =~ s/\./_/g;  ## extra dots confuse latex's graphics package
# 			if ($envir{texDisposition} eq "pdf") {
# 				# We're going to create PDF files with our TeX (using pdflatex), so we
# 				# need images in PNG format.
# 
# 				my $gifFilePath;
# 
# 				if ($aux_file_path =~ m/^$htmlDirectory/ or $aux_file_path =~ m/^$tempDirectory/) {
# 					# we've got a full pathname to a file
# 					$gifFilePath = "$aux_file_path.gif";
# 				} else {
# 					# we assume the file is in the same directory as the problem source file
# 					$gifFilePath = $templateDirectory . directoryFromPath($fileName) . "$aux_file_path.gif";
# 				}
# 
# 				my $gifFileName = fileFromPath($gifFilePath);
# 
# 				$gifFileName =~ /^(.*)\.gif$/;
# #				my $pngFilePath = surePathToTmpFile("${tempDirectory}png/$probNum-$1.png");
# 				my $pngFilePath = surePathToTmpFile("${tempDirectory}png/$setNumber-$probNum-$1.png");
# 				my $returnCode = system "cat $gifFilePath | $envir{externalGif2PngPath} > $pngFilePath";
# 
# 				if ($returnCode or not -e $pngFilePath) {
# 					die "failed to convert $gifFilePath to $pngFilePath using gif->png with $envir{externalGif2PngPath}: $!\n";
# 				}
# 
# 				$adr_output = $pngFilePath;
# 			} else {
# 				# Since we're not creating PDF files, we're probably just using a plain
# 				# vanilla latex. Hence, we need EPS images.
# 
# 				################################################################################
# 				# This is statement used below is system dependent.
# 				# Notice that the range of colors is restricted when converting to postscript to keep the files small
# 				# "cat $gifSourceFile  | /usr/math/bin/giftopnm | /usr/math/bin/pnmtops -noturn > $adr_output"
# 				# "cat $gifSourceFile  | /usr/math/bin/giftopnm | /usr/math/bin/pnmdepth 1 | /usr/math/bin/pnmtops -noturn > $adr_output"
# 				################################################################################
# 				if ($aux_file_path =~  m|^$htmlDirectory|  or $aux_file_path =~  m|^$tempDirectory|)  {
# 					# To serve an eps file copy an eps version of the gif file to the subdirectory of eps/
# 					my $linkPath = directoryFromPath($fileName);
# 
# 					my $gifSourceFile = "$aux_file_path.gif";
# 					my $gifFileName = fileFromPath($gifSourceFile);
# 					$adr_output = surePathToTmpFile("$tempDirectory/eps/$studentLogin-$psvnNumber-$gifFileName.eps") ;
# 
# 					if (-e $gifSourceFile) {
# 						#system("cat $gifSourceFile  | /usr/math/bin/giftopnm | /usr/math/bin/pnmdepth 1 | /usr/math/bin/pnmtops -noturn>$adr_output")
# 						system("cat $gifSourceFile | ${externalGif2EpsPath} > $adr_output" )
# 							&& die "Unable to create eps file:\n |$adr_output| from file\n |$gifSourceFile|\n in problem $probNum " .
# 							       "using the system dependent script\n |${externalGif2EpsPath}| \n";
# 					} else {
# 						die "|$gifSourceFile| cannot be found.  Problem number: |$probNum|";
# 					}
# 				} else {
# 					# To serve an eps file copy an eps version of the gif file to  a subdirectory of eps/
# 					my $filePath = directoryFromPath($fileName);
# 					my $gifSourceFile = "${templateDirectory}${filePath}$aux_file_path.gif";
# 					#print "content-type: text/plain \n\nfileName = $fileName and aux_file_path =$aux_file_path<BR>";
# 					$adr_output = surePathToTmpFile("eps/$studentLogin-$psvnNumber-set$setNumber-prob$probNum-$aux_file_path.eps");
# 
# 					if (-e $gifSourceFile) {
# 						#system("cat $gifSourceFile  | /usr/math/bin/giftopnm | /usr/math/bin/pnmdepth 1 | /usr/math/bin/pnmtops -noturn>$adr_output") &&
# 						#warn "Unable to create eps file: |$adr_output|\n from file\n |$gifSourceFile|\n in problem $probNum";
# 						#warn "Help ${:externalGif2EpsPath}" unless -x "${main::externalGif2EpsPath}";
# 						system("cat $gifSourceFile | ${externalGif2EpsPath} > $adr_output" )
# 							&& die "Unable to create eps file:\n |$adr_output| from file\n |$gifSourceFile|\n in problem $probNum " .
# 							       "using the system dependent commands \n |${externalGif2EpsPath}| \n ";
# 					}  else {
# 						die "|$gifSourceFile| cannot be found.  Problem number: |$probNum|";
# 					}
# 				}
# 			}
# 		} else {
# 			die "Error in alias: dangerousMacros.pl: unrecognizable displayMode = $displayMode";
# 		}
# 	} elsif ($ext eq 'png') {
# 		if ( $displayMode eq 'HTML' ||
# 		     $displayMode eq 'HTML_tth'||
# 		     $displayMode eq 'HTML_dpng'||
# 		     $displayMode eq 'HTML_asciimath'||
# 		     $displayMode eq 'HTML_LaTeXMathML'||
# 		     $displayMode eq 'HTML_jsMath'||
# 		     $displayMode eq 'HTML_img'||
# 		     $displayMode eq 'Latex2HTML')  {
# 			################################################################################
# 			# .png FILES in HTML, HTML_tth, HTML_dpng, HTML_img, etc. and Latex2HTML modes
# 			################################################################################
# 
# 			#warn "tempDirectory is $tempDirectory";
# 			#warn "file Path for auxiliary file is $aux_file_path";
# 
# 			# No changes are made for auxiliary files in the htmlDirectory or in the tempDirectory subtree.
# 			if ( $aux_file_path =~ m|^$tempDirectory| ) {
# 			$adr_output = $aux_file_path;
# 				$adr_output =~ s|$tempDirectory|$tempURL|;
# 				$adr_output .= ".$ext";
# 				#warn "adress out is $adr_output";
# 			} elsif ($aux_file_path =~ m|^$htmlDirectory| ) {
# 				$adr_output = $aux_file_path;
# 				$adr_output =~ s|$htmlDirectory|$htmlURL|;
# 				$adr_output .= ".$ext";
# 			} else {
# 				# files not in the htmlDirectory sub tree are assumed to live under the templateDirectory
# 				# subtree in the same directory as the problem.
# 
# 				# For a png file the alias macro creates an alias under the html/images directory
# 				# which points to the png file in the problem directory.
# 				# All of the subdirectories of html/tmp/gif which are needed are also created.
# 				my $filePath = directoryFromPath($fileName);
# 
# 				# $fileName is obtained from environment for PGeval
# 				# it gives the full path to the current problem
# 				my $pngSourceFile = convertPath("$templateDirectory${filePath}$aux_file_path.png");
# 				my $link = "gif/$studentLogin-$psvnNumber-set$setNumber-prob$probNum-$aux_file_path.$ext";
# 				my $linkPath = surePathToTmpFile($link);
# 				$adr_output = "${tempURL}$link";
# 				#warn "linkPath is $linkPath";
# 				#warn "adr_output is $adr_output";
# 				if (-e $pngSourceFile) {
# 					if (-e $linkPath) {
# 						unlink($linkPath) || warn "Unable to unlink old alias file at $linkPath";
# 					}
# 					symlink($pngSourceFile, $linkPath)
# 					|| warn "The macro alias cannot create a link from |$linkPath|  to |$pngSourceFile| <BR>" ;
# 				} else {
# 					warn("The macro alias cannot find a PNG file at: |$pngSourceFile|");
# 				}
# 			}
# 		} elsif ($displayMode eq 'TeX') {
# 			################################################################################
# 			# .png FILES in TeX mode
# 			################################################################################
# 
# 		        $setNumber =~ s/\./_/g;  ## extra dots confuse latex's graphics package
# 			if ($envir{texDisposition} eq "pdf") {
# 				# We're going to create PDF files with our TeX (using pdflatex), so we
# 				# need images in PNG format. what luck! they're already in PDF format!
# 
# 				my $pngFilePath;
# 
# 				if ($aux_file_path =~ m/^$htmlDirectory/ or $aux_file_path =~ m/^$tempDirectory/) {
# 					# we've got a full pathname to a file
# 					$pngFilePath = "$aux_file_path.png";
# 				} else {
# 					# we assume the file is in the same directory as the problem source file
# 					$pngFilePath = $templateDirectory . directoryFromPath($fileName) . "$aux_file_path.png";
# 				}
# 
# 				$adr_output = $pngFilePath;
# 			} else {
# 				# Since we're not creating PDF files, we're probably just using a plain
# 				# vanilla latex. Hence, we need EPS images.
# 
# 				################################################################################
# 				# This is statement used below is system dependent.
# 				# Notice that the range of colors is restricted when converting to postscript to keep the files small
# 				# "cat $pngSourceFile  | /usr/math/bin/pngtopnm | /usr/math/bin/pnmtops -noturn > $adr_output"
# 				# "cat $pngSourceFile  | /usr/math/bin/pngtopnm | /usr/math/bin/pnmdepth 1 | /usr/math/bin/pnmtops -noturn > $adr_output"
# 				################################################################################
# 
# 				if ($aux_file_path =~  m|^$htmlDirectory|  or $aux_file_path =~  m|^$tempDirectory|)  {
# 					# To serve an eps file copy an eps version of the png file to the subdirectory of eps/
# 					my $linkPath = directoryFromPath($fileName);
# 
# 					my $pngSourceFile = "$aux_file_path.png";
# 					my $pngFileName = fileFromPath($pngSourceFile);
# 					$adr_output = surePathToTmpFile("$tempDirectory/eps/$studentLogin-$psvnNumber-$pngFileName.eps") ;
# 
# 					if (-e $pngSourceFile) {
# 						#system("cat $pngSourceFile  | /usr/math/bin/pngtopnm | /usr/math/bin/pnmdepth 1 | /usr/math/bin/pnmtops -noturn>$adr_output")
# 						system("cat $pngSourceFile | ${externalPng2EpsPath} > $adr_output" )
# 							&& die "Unable to create eps file:\n |$adr_output| from file\n |$pngSourceFile|\n in problem $probNum " .
# 							       "using the system dependent commands\n |${externalPng2EpsPath}| \n";
# 					} else {
# 						die "|$pngSourceFile| cannot be found.  Problem number: |$probNum|";
# 					}
# 				} else {
# 					# To serve an eps file copy an eps version of the png file to  a subdirectory of eps/
# 					my $filePath = directoryFromPath($fileName);
# 					my $pngSourceFile = "${templateDirectory}${filePath}$aux_file_path.png";
# 					#print "content-type: text/plain \n\nfileName = $fileName and aux_file_path =$aux_file_path<BR>";
# 					$adr_output = surePathToTmpFile("eps/$studentLogin-$psvnNumber-set$setNumber-prob$probNum-$aux_file_path.eps") ;
# 					if (-e $pngSourceFile) {
# 						#system("cat $pngSourceFile  | /usr/math/bin/pngtopnm | /usr/math/bin/pnmdepth 1 | /usr/math/bin/pnmtops -noturn>$adr_output") &&
# 						#warn "Unable to create eps file: |$adr_output|\n from file\n |$pngSourceFile|\n in problem $probNum";
# 						#warn "Help ${externalPng2EpsPath}" unless -x "${externalPng2EpsPath}";
# 						system("cat $pngSourceFile | ${externalPng2EpsPath} > $adr_output" )
# 							&& die "Unable to create eps file:\n |$adr_output| from file\n |$pngSourceFile|\n in problem $probNum " .
# 							       "using the system dependent commands\n |${externalPng2EpsPath}| \n ";
# 					} else {
# 						die "|$pngSourceFile| cannot be found.  Problem number: |$probNum|";
# 					}
# 				}
# 			}
# 		} else {
# 			warn  "Error in alias: dangerousMacros.pl","unrecognizable displayMode = $displayMode","";
# 		}
# 	} else { # $ext is not recognized
# 		################################################################################
# 		# FILES  with unrecognized file extensions in any display modes
# 		################################################################################
# 
# 		warn "Error in the macro alias. Alias does not understand how to process files with extension $ext.  (Path ot problem file is  $fileName) ";
# 	}
# 
# 	warn "The macro alias was unable to form a URL for some auxiliary file used in this problem." unless $adr_output;
# 	return $adr_output;
# }
# 
# =head2 sourceAlias
# 
# 	sourceAlias($path_to_PG_file);
# 
# Returns a relative URL to the F<source.pl> script, which may be installed in a
# course's F<html> directory to allow formatted viewing of the problem source.
# 
# =cut
# 
# # ^function sourceAlias
# # ^uses PG_restricted_eval
# # ^uses %envir
# # ^uses $envir{inputs_ref}
# # ^uses $envir{psvn}
# # ^uses $envir{probNum}
# # ^uses $envir{displayMode}
# # ^uses $envir{courseName}
# # ^uses $envir{sessionKey}
# sub sourceAlias {
# 	my $path_to_file = shift;
# 	my $envir        =  PG_restricted_eval(q!\%main::envir!);
# 	my $user         = $envir->{inputs_ref}->{user};
# 	$user            = " " unless defined($user);
#     my $out = 'source.pl?probSetKey='  . $envir->{psvn}.
#   			  '&amp;probNum='          . $envir->{probNum} .
#    			  '&amp;Mode='             . $envir->{displayMode} .
#    			  '&amp;course='           . $envir->{courseName} .
#     		  '&amp;user='             . $user .
# 			  '&amp;displayPath='      . $path_to_file .
# 	   		  '&amp;key='              . $envir->{sessionKey};
# 
#  	 $out;
# }

# 
# #
# #  Some constants that can be used in perl experssions
# #
# 
# # ^function i
# # ^uses $_parser_loaded
# # ^uses &Complex::i
# # ^uses &Value::Package
# sub i () {
#   #  check if Parser.pl is loaded, otherwise use Complex package
#   if (!eval(q!$main::_parser_loaded!)) {return Complex::i}
#   return Value->Package("Formula")->new('i')->eval;
# }
# 
# # ^function j
# # ^uses $_parser_loaded
# # ^uses &Value::Package
# sub j () {
#   if (!eval(q!$main::_parser_loaded!)) {return 'j'}
#   Value->Package("Formula")->new('j')->eval;
# }
# 
# # ^function k
# # ^uses $_parser_loaded
# # ^uses &Value::Package
# sub k () {
#   if (!eval(q!$main::_parser_loaded!)) {return 'k'}
#   Value->Package("Formula")->new('k')->eval;
# }
# 
# # ^function pi
# # ^uses &Value::Package
# sub pi () {Value->Package("Formula")->new('pi')->eval}
# 
# # ^function Infinity
# # ^uses &Value::Package
# sub Infinity () {Value->Package("Infinity")->new()}
# 
# 
# # ^function abs
# # ^function sqrt
# # ^function exp
# # ^function log
# # ^function sin
# # ^function cos
# # ^function atan2
# #
# #  Allow these functions to be overridden
# #  (needed for log() to implement $useBaseTenLog)
# #
# use subs 'abs', 'sqrt', 'exp', 'log', 'sin', 'cos', 'atan2';
# sub abs($)  {return CORE::abs($_[0])};
# sub sqrt($) {return CORE::sqrt($_[0])};
# sub exp($)  {return CORE::exp($_[0])};
# sub log($)  {return CORE::log($_[0])};
# sub sin($)  {return CORE::sin($_[0])};
# sub cos($)  {return CORE::cos($_[0])};
# sub atan2($$) {return CORE::atan2($_[0],$_[1])};
# 
# sub Parser::defineLog {eval {sub log($) {CommonFunction->Call("log",@_)}}};
sub foobar {
	my $self = shift;

}
1;
