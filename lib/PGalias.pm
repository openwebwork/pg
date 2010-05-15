################################################################################
# WeBWorK Online Homework Delivery System
# Copyright © 2000-2007 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader: pg/lib/PGalias.pm,v 1.4 2010/05/14 15:44:55 gage Exp $
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

package PGresource;
use strict;
use Exporter;
use PGcore;

sub new {
	my $class = shift;	
	my $aux_file_name = shift;  #pointer to auxiliary fle
	my $self = {
		type        =>  'png', # gif eps pdf html pg (macro: pl) (applets: java js fla geogebra )
		path		=>  { content => undef,
						  is_complete=>0,
						  is_accessible => 0,
						},
		url			=>  { content => undef,
						  is_complete=>0,
						  is_accessible => 0,
						},
		return_uri  =>  '',
		recorded_uri => '',
		convert      => { needed  => 0,
						  from_type => undef,
						  from_path => undef,
						  to_type	=> undef,
						  to_path	=> undef,
						},
		copy_link   =>  { type => undef,  # copy or link or ??
						  link_to_path => undef,
						  copy_to_path => undef,
						},
		cache_info	=>  {},
		unique_id   =>  undef,
	};
	bless $self, $class;
	# $self->initialize;
	# $self->check_parameters;
	return $self;
}

package PGalias;
use strict;
use Exporter;
use PGcore;
#use WeBWorK::PG::IO;

our @ISA =  qw ( PGcore  );  # look up features in PGcore -- in this case we want the environment.

# new 
#   Create one alias object per question (and per PGcore object)
#   Check that information is intact
#   Construct unique id stubs
#   Keep list of external links
sub new {
	my $class = shift;	
	my $envir = shift;  #pointer to environment hash
	warn "PGlias must be called with an environment" unless ref($envir) eq 'HASH';
	my $self = {
		envir		=>	$envir,
		searchList  =>  [{url=>'foo',dir=>'.'}],   # for subclasses -> list of url/directories to search
		resourceList => {},

	};
	bless $self, $class;
	$self->initialize;
	$self->check_parameters;
	return $self;
}

# methods
#     make_alias   -- outputs url and does what needs to be done
#     normalize paths (remove extra precursors to the path)
#     search directories for item
#     make_links   -- in those cases where links need to be made
#     create_files  -- e.g. when printing hardcopy
#     dispatcher -- decides what needs to be done based on displayMode and file type
#     alias_for_html
#     alias_for_image_in_html   image includes gif, png, jpg, swf, svg, flv?? ogg??
#     alias_for_image_in_tex 


sub initialize {
	my $self = shift;
	my $envir = $self->{envir};
	# warn "envir-- ", join(" ", %$envir);
	$self->{fileName}            = $envir->{probFileName};
	$self->{htmlDirectory}       = $envir->{htmlDirectory};
	$self->{htmlURL}             = $envir->{htmlURL};
	$self->{tempDirectory}       = $envir->{tempDirectory};
	$self->{templateDirectory}   = $envir->{templateDirectory};
	$self->{tempURL}             = $envir->{tempURL};
	$self->{studentLogin}        = $envir->{studentLogin};
	$self->{psvnNumber}          = $envir->{psvnNumber};
	$self->{setNumber}           = $envir->{setNumber};
	$self->{probNum}             = $envir->{probNum};
	$self->{displayMode}         = $envir->{displayMode};
	$self->{externalGif2EpsPath} = $envir->{externalGif2EpsPath};
	$self->{externalPng2EpsPath} = $envir->{externalPng2EpsPath};	
	#
	#  Find auxiliary files even when the main file is in tempates/tmpEdit
	#
	$self->{fileName} =~ s!(^|/)tmpEdit/!$1!;
	
	$self->{ext}      = "";
	
	# create uniqeID stub    "gif/uniqIDstub-filePath"
	$self->{uniqIDstub} = join("-",   
							   $self->{studentLogin},
							   $self->{psvnNumber},
							   'set'.$self->{setNumber},
							   'prob'.$self->{probNum}
	);
				   

}

sub check_parameters {
	my $self = shift;

	# problem specific data
	warn "The path to the current problem file template is not defined."     unless $self->{fileName};
	warn "The current studentLogin is not defined "                          unless $self->{studentLogin};
	warn "The current problem set number is not defined"                     if $self->{setNumber} eq ""; # allow for sets equal to 0
	warn "The current problem number is not defined"                         if $self->{probNum} eq "";
	warn "The current problem set version number (psvn) is not defined"      unless defined($self->{psvnNumber});
	warn "The displayMode is not defined"                                    unless $self->{displayMode};

	# required macros
#	warn "The macro &surePathToTmpFile can't be found"                    unless defined(&{$self->surePathToTmpFile()} );
#	warn "The macro &convertPath can't be found"                          unless defined(&{$self->convertPath()});
#	warn "The macro &directoryFromPath can't be found"                    unless defined(&{$self->directoryFromPath()});
#    warn $self->surePathToTmpFile("foo");
	# warn "The webwork server does not have permission to execute the gif2eps script at  ${externalGif2EpsPath}." unless ( -x "${externalGif2EpsPath}" );
	# warn "The webwork server does not have permission to execute the png2eps script at ${externalPng2EpsPath}." unless ( -x "${externalPng2EpsPath}" );

	# required directory addresses (and URL address)
	warn "htmlDirectory is not defined." unless $self->{htmlDirectory};
	warn "htmlURL is not defined." unless $self->{htmlURL};
	warn "tempURL is not defined." unless $self->{tempURL};
}

sub make_alias {
   	my $self = shift;   	
   	# input is a path to the original auxiliary file
   	my $aux_file_path = shift @_;
   	my $resource_alias = new PGresource($aux_file_path);  # just call it alias? FIXME -- not in use yet.
   	
   	# warn "make alias for $aux_file_path";
	warn "Empty string used as input into the function alias" unless $aux_file_path;
	
	my $displayMode         = $self->{displayMode};
    my $fileName            = $self->{fileName};    # name of .pg file
	my $envir               = $self->{envir};
	my $htmlDirectory       = $envir->{htmlDirectory};
	my $htmlURL             = $envir->{htmlURL};
	my $tempDirectory       = $envir->{tempDirectory};
	my $tempURL             = $envir->{tempURL};
	my $studentLogin        = $envir->{studentLogin};
	my $psvnNumber          = $envir->{psvnNumber};
	my $setNumber           = $envir->{setNumber};
	my $probNum             = $envir->{probNum};
    my $externalGif2EpsPath = $envir->{externalGif2EpsPath};
    my $externalPng2EpsPath = $envir->{externalPng2EpsPath};
    
    my $templateDirectory   = $self->{templateDirectory};
    
	# $adr_output is a url in HTML and Latex2HTML modes
	# and a complete path in TEX mode.
	my $adr_output;
	my $ext;
	
	# determine file type
	# determine display mode
	# dispatch	

	# determine extension, if there is one
	# if extension exists, strip and use the value for $ext
	# files without extensions are considered to be picture files:


	if ($aux_file_path =~ s/\.([^\.]*)$// ) {
		$ext = $1;
	} else {
		warn "This file name $aux_file_path did not have an extension.<BR> " .
		     "Every file name used as an argument to alias must have an extension.<BR> " .
		     "The permissable extensions are .gif, .png, and .html .<BR>";
		$ext  = "gif";
	}


	# in order to facilitate maintenance of this macro the routines for handling
	# different file types are defined separately.  This involves some redundancy
	# in the code but it makes it easier to define special handling for a new file
	# type, (but harder to change the behavior for all of the file types at once
	# (sigh)  ).

	if ($ext eq 'html') {
	   $adr_output = $self->alias_for_html($aux_file_path)
	} elsif ($ext eq 'gif') {
		if ( $displayMode eq 'HTML' ||
		     $displayMode eq 'HTML_tth'||
		     $displayMode eq 'HTML_dpng'||
		     $displayMode eq 'HTML_asciimath'||
		     $displayMode eq 'HTML_LaTeXMathML'||
		     $displayMode eq 'HTML_jsMath'||
		     $displayMode eq 'HTML_img') {
			################################################################################
			# .gif FILES in HTML; HTML_tth; HTML_dpng; HTML_img; and Latex2HTML modes
			################################################################################
			$adr_output=$self->alias_for_gif_in_html_mode($aux_file_path);
		
		} elsif ($displayMode eq 'TeX') {
			################################################################################
			# .gif FILES in TeX mode
			################################################################################
            $adr_output=$self->alias_for_gif_in_tex_mode($aux_file_path);
		
		} else {
			die "Error in alias: dangerousMacros.pl: unrecognizable displayMode = $displayMode";
		}
	} elsif ($ext eq 'png') {
		if ( $displayMode eq 'HTML' ||
		     $displayMode eq 'HTML_tth'||
		     $displayMode eq 'HTML_dpng'||
		     $displayMode eq 'HTML_asciimath'||
		     $displayMode eq 'HTML_LaTeXMathML'||
		     $displayMode eq 'HTML_jsMath'||
		     $displayMode eq 'HTML_img' )  {
		    $adr_output = $self->alias_for_png_in_html_mode($aux_file_path);
		} elsif ($displayMode eq 'TeX') {
			$adr_output = $self->alias_for_png_in_tex_mode($aux_file_path);
		
		} else {
			warn  "Error in alias: dangerousMacros.pl","unrecognizable displayMode = $displayMode","";
		}
	} else { # $ext is not recognized
		################################################################################
		# FILES  with unrecognized file extensions in any display modes
		################################################################################

		warn "Error in the macro alias. Alias does not understand how to process files with extension $ext.  (Path ot problem file is  $fileName) ";
	}

	warn "The macro alias was unable to form a URL for some auxiliary file used in this problem." unless $adr_output;
	return $adr_output;
}



sub alias_for_html {
	my $self = shift;
	my $aux_file_path = shift;
    # warn "aux_file for html $aux_file_path";
	my $envir               = $self->{envir};  	
	my $fileName            = $self->{fileName};
	my $htmlDirectory       = $envir->{htmlDirectory};
	my $htmlURL             = $envir->{htmlURL};
	my $tempDirectory       = $envir->{tempDirectory};
	my $tempURL             = $envir->{tempURL};
	my $studentLogin        = $envir->{studentLogin};
	my $psvnNumber          = $envir->{psvnNumber};
	my $setNumber           = $envir->{setNumber};
	my $probNum             = $envir->{probNum};
	my $displayMode         = $envir->{displayMode};
    my $externalGif2EpsPath = $envir->{externalGif2EpsPath};
    my $externalPng2EpsPath = $envir->{externalPng2EpsPath};
     
    my $templateDirectory   = $self->{templateDirectory};
    
   
	# $adr_output is a url in HTML and Latex2HTML modes
	# and a complete path in TEX mode.
	my $adr_output;
	my $ext                 =   "html";
		################################################################################
		# .html FILES in HTML, HTML_tth, HTML_dpng, HTML_img, etc. and Latex2HTML mode
		################################################################################

		# No changes are made for auxiliary files in the
		# ${Global::htmlDirectory} subtree.
		if ( $aux_file_path =~ m|^$tempDirectory| ) {
			$adr_output = $aux_file_path,
			$adr_output =~ s|$tempDirectory|$tempURL/|,
			$adr_output .= ".$ext",
		} elsif ($aux_file_path =~ m|^$htmlDirectory| ) {
			$adr_output = $aux_file_path,
			$adr_output =~ s|$htmlDirectory|$htmlURL|,
			$adr_output .= ".$ext",
		} else {
			# HTML files not in the htmlDirectory are assumed under live under the
			# templateDirectory in the same directory as the problem.
			# Create an alias file (link) in the directory html/tmp/html which
			# points to the original file and return the URL of this alias.
			# Create all of the subdirectories of html/tmp/html which are needed
			# using sure file to path.

			# $fileName is obtained from environment for PGeval
			# it gives the  full path to the current problem
			my $filePath = $self->directoryFromPath($fileName);
			my $htmlFileSource = $self->convertPath("$templateDirectory${filePath}$aux_file_path.html");
			my $link = "html/".$self->{uniqIDstub}."-$aux_file_path.$ext";
			my $linkPath = $self->surePathToTmpFile($link);
			$adr_output = "${tempURL}$link";
			if (-e $htmlFileSource) {
				if (-e $linkPath) {
					unlink($linkPath) || warn "Unable to unlink alias file at |$linkPath|";
					# destroy the old link.
				}
				symlink( $htmlFileSource, $linkPath)
			    		|| warn "The macro alias cannot create a link from |$linkPath|  to |$htmlFileSource| <BR>" ;
			} else {
				warn("The macro alias cannot find an HTML file at: |$htmlFileSource|");
			}
		}
	$adr_output;
}


sub alias_for_gif_in_html_mode {
	my $self = shift;
	my $aux_file_path = shift;
#    warn "entering alias_for_gif_in_html_mode $aux_file_path";
    
	my $envir               = $self->{envir};  	
	my $fileName            = $self->{fileName};
	my $htmlDirectory       = $envir->{htmlDirectory};
	my $htmlURL             = $envir->{htmlURL};
	my $tempDirectory       = $envir->{tempDirectory};
	my $tempURL             = $envir->{tempURL};
	my $studentLogin        = $envir->{studentLogin};
	my $psvnNumber          = $envir->{psvnNumber};
	my $setNumber           = $envir->{setNumber};
	my $probNum             = $envir->{probNum};
	my $displayMode         = $envir->{displayMode};
    my $externalGif2EpsPath = $envir->{externalGif2EpsPath};
    my $externalPng2EpsPath = $envir->{externalPng2EpsPath};
    
    my $templateDirectory   = $self->{templateDirectory};
    
    
	# $adr_output is a url in HTML and Latex2HTML modes
	# and a complete path in TEX mode.
	my $adr_output;
	my $ext                 = "gif";
	
			################################################################################
			# .gif FILES in HTML, HTML_tth, HTML_dpng, HTML_img, and Latex2HTML modes
			################################################################################

			#warn "tempDirectory is $tempDirectory";
			#warn "file Path for auxiliary file is $aux_file_path";

			# No changes are made for auxiliary files in the htmlDirectory or in the tempDirectory subtree.
			if ( $aux_file_path =~ m|^$tempDirectory| ) {
				$adr_output = $aux_file_path;
				$adr_output =~ s|$tempDirectory|$tempURL|;
				$adr_output .= ".$ext";
				#warn "adress out is $adr_output",
			} elsif ($aux_file_path =~ m|^$htmlDirectory| ) {
				$adr_output = $aux_file_path;
				$adr_output =~ s|$htmlDirectory|$htmlURL|;
				$adr_output .= ".$ext";
			} else {
				# files not in the htmlDirectory sub tree are assumed to live under the templateDirectory
				# subtree in the same directory as the problem.

				# For a gif file the alias macro creates an alias under the html/images directory
				# which points to the gif file in the problem directory.
				# All of the subdirectories of html/tmp/gif which are needed are also created.
		  #warn "fileName is $fileName   $self";
				my $filePath = ( $self->directoryFromPath($fileName) );
          #warn "filePath is $filePath";
				# $fileName is obtained from environment for PGeval
				# it gives the full path to the current problem
				my $gifSourceFile = $self->convertPath("$templateDirectory${filePath}$aux_file_path.gif");
				#my $link = "gif/$studentLogin-$psvnNumber-set$setNumber-prob$probNum-$aux_file_path.$ext";
		   #warn "fileName is $fileName filePath is $filePath gifSourceFile is $gifSourceFile";

				#  Make file names work in Library Browser when the images in several
				#  files have the same names.
				my $libFix = "";
				if ($setNumber eq "Undefined_Set") {
				  $libFix = $fileName;
				  $libFix =~ s!.*/!!, $libFix =~ s!\.pg(\..*)?$!!;
				  $libFix =~ s![^a-zA-Z0-9._-]!!g;
				  $libFix .= '-';
				}

				my $link = "gif/$setNumber-prob$probNum-$libFix$aux_file_path.$ext";

				my $linkPath = $self->surePathToTmpFile($link);
				$adr_output = "${tempURL}$link";
				#warn "linkPath is $linkPath";
				#warn "adr_output is $adr_output";
				if (-e $gifSourceFile) {
					if (-e $linkPath) {
						unlink($linkPath) || warn "Unable to unlink old alias file at $linkPath";
					}
					symlink($gifSourceFile, $linkPath)
						|| warn "The macro alias cannot create a link from |$linkPath|  to |$gifSourceFile| <BR>" ;
				} else {
					warn("The macro alias cannot find a GIF file at: |$gifSourceFile|");
				}
			}
		$adr_output;
}

sub alias_for_gif_in_tex_mode {
	my $self = shift;
	my $aux_file_path = shift;

	my $envir               = $self->{envir};  	my $fileName            = $envir->{fileName};
	my $htmlDirectory       = $envir->{htmlDirectory};
	my $htmlURL             = $envir->{htmlURL};
	my $tempDirectory       = $envir->{tempDirectory};
	my $tempURL             = $envir->{tempURL};
	my $studentLogin        = $envir->{studentLogin};
	my $psvnNumber          = $envir->{psvnNumber};
	my $setNumber           = $envir->{setNumber};
	my $probNum             = $envir->{probNum};
	my $displayMode         = $envir->{displayMode};
    my $externalGif2EpsPath = $envir->{externalGif2EpsPath};
    my $externalPng2EpsPath = $envir->{externalPng2EpsPath};
    
    my $templateDirectory   = $self->{templateDirectory};
    
    
	# $adr_output is a url in HTML and Latex2HTML modes
	# and a complete path in TEX mode.
	my $adr_output;
	my $ext                 = "gif";
			################################################################################
			# .gif FILES in TeX mode
			################################################################################

		        $setNumber =~ s/\./_/g;  ## extra dots confuse latex's graphics package
			if ($envir->{texDisposition} eq "pdf") {
				# We're going to create PDF files with our TeX (using pdflatex); so we
				# need images in PNG format.

				my $gifFilePath;

				if ($aux_file_path =~ m/^$htmlDirectory/ or $aux_file_path =~ m/^$tempDirectory/) {
					# we've got a full pathname to a file
					$gifFilePath = "$aux_file_path.gif";
				} else {
					# we assume the file is in the same directory as the problem source file
					$gifFilePath = $templateDirectory . ($self->directoryFromPath($fileName)) . "$aux_file_path.gif";
				}

				my $gifFileName = $self->fileFromPath($gifFilePath);

				$gifFileName =~ /^(.*)\.gif$/;
				my $pngFilePath = $self->surePathToTmpFile("${tempDirectory}png/$setNumber-$probNum-$1.png");
				my $returnCode = system "cat $gifFilePath | ${$envir->{externalGif2PngPath}} > $pngFilePath";

				if ($returnCode or not -e $pngFilePath) {
					die "failed to convert $gifFilePath to $pngFilePath using gif->png with ${$envir->{externalGif2PngPath}}: $!\n";
				}

				$adr_output = $pngFilePath;
			} else {
				# Since we're not creating PDF files; we're probably just using a plain
				# vanilla latex. Hence; we need EPS images.

				################################################################################
				# This is statement used below is system dependent.
				# Notice that the range of colors is restricted when converting to postscript to keep the files small
				# "cat $gifSourceFile  | /usr/math/bin/giftopnm | /usr/math/bin/pnmtops -noturn > $adr_output"
				# "cat $gifSourceFile  | /usr/math/bin/giftopnm | /usr/math/bin/pnmdepth 1 | /usr/math/bin/pnmtops -noturn > $adr_output"
				################################################################################
				if ($aux_file_path =~  m|^$htmlDirectory|  or $aux_file_path =~  m|^$tempDirectory|)  {
					# To serve an eps file copy an eps version of the gif file to the subdirectory of eps/
					my $linkPath = $self->directoryFromPath($fileName);

					my $gifSourceFile = "$aux_file_path.gif";
					my $gifFileName = $self->fileFromPath($gifSourceFile);
					$adr_output = surePathToTmpFile("$tempDirectory/eps/$studentLogin-$psvnNumber-$gifFileName.eps") ;

					if (-e $gifSourceFile) {
						#system("cat $gifSourceFile  | /usr/math/bin/giftopnm | /usr/math/bin/pnmdepth 1 | /usr/math/bin/pnmtops -noturn>$adr_output")
						system("cat $gifSourceFile | ${externalGif2EpsPath} > $adr_output" )
							&& die "Unable to create eps file:\n |$adr_output| from file\n |$gifSourceFile|\n in problem $probNum " .
							       "using the system dependent script\n |${externalGif2EpsPath}| \n";
					} else {
						die "|$gifSourceFile| cannot be found.  Problem number: |$probNum|";
					}
				} else {
					# To serve an eps file copy an eps version of the gif file to  a subdirectory of eps/
					my $filePath = $self->directoryFromPath($fileName);
					my $gifSourceFile = "${templateDirectory}${filePath}$aux_file_path.gif";
					#print "content-type: text/plain \n\nfileName = $fileName and aux_file_path =$aux_file_path<BR>";
					$adr_output = surePathToTmpFile("eps/$studentLogin-$psvnNumber-set$setNumber-prob$probNum-$aux_file_path.eps");

					if (-e $gifSourceFile) {
						#system("cat $gifSourceFile  | /usr/math/bin/giftopnm | /usr/math/bin/pnmdepth 1 | /usr/math/bin/pnmtops -noturn>$adr_output") &&
						#warn "Unable to create eps file: |$adr_output|\n from file\n |$gifSourceFile|\n in problem $probNum";
						#warn "Help ${:externalGif2EpsPath}" unless -x "${main::externalGif2EpsPath}";
						system("cat $gifSourceFile | ${externalGif2EpsPath} > $adr_output" )
							&& die "Unable to create eps file:\n |$adr_output| from file\n |$gifSourceFile|\n in problem $probNum " .
							       "using the system dependent commands \n |${externalGif2EpsPath}| \n ";
					}  else {
						die "|$gifSourceFile| cannot be found.  Problem number: |$probNum|";
					}
				}
			}
	$adr_output;

} 
sub alias_for_png_in_html_mode {
	my $self = shift;
	my $aux_file_path = shift;

	my $envir               = $self->{envir};  	my $fileName            = $envir->{fileName};
	my $htmlDirectory       = $envir->{htmlDirectory};
	my $htmlURL             = $envir->{htmlURL};
	my $tempDirectory       = $envir->{tempDirectory};
	my $tempURL             = $envir->{tempURL};
	my $studentLogin        = $envir->{studentLogin};
	my $psvnNumber          = $envir->{psvnNumber};
	my $setNumber           = $envir->{setNumber};
	my $probNum             = $envir->{probNum};
	my $displayMode         = $envir->{displayMode};
    my $externalGif2EpsPath = $envir->{externalGif2EpsPath};
    my $externalPng2EpsPath = $envir->{externalPng2EpsPath};
     
    my $templateDirectory   = $self->{templateDirectory};
    
   
	# $adr_output is a url in HTML and Latex2HTML modes
	# and a complete path in TEX mode.
	my $adr_output;
	my $ext                 = "png";
			################################################################################
			# .png FILES in HTML; HTML_tth; HTML_dpng; HTML_img; etc. and Latex2HTML modes
			################################################################################

			#warn "tempDirectory is $tempDirectory";
			#warn "file Path for auxiliary file is $aux_file_path";

			# No changes are made for auxiliary files in the htmlDirectory or in the tempDirectory subtree.
			if ( $aux_file_path =~ m|^$tempDirectory| ) {
			$adr_output = $aux_file_path;
				$adr_output =~ s|$tempDirectory|$tempURL|;
				$adr_output .= ".$ext";
				#warn "adress out is $adr_output";
			} elsif ($aux_file_path =~ m|^$htmlDirectory| ) {
				$adr_output = $aux_file_path;
				$adr_output =~ s|$htmlDirectory|$htmlURL|;
				$adr_output .= ".$ext";
			} else {
				# files not in the htmlDirectory sub tree are assumed to live under the templateDirectory
				# subtree in the same directory as the problem.

				# For a png file the alias macro creates an alias under the html/images directory
				# which points to the png file in the problem directory.
				# All of the subdirectories of html/tmp/gif which are needed are also created.
				my $filePath = $self->directoryFromPath($fileName);

				# $fileName is obtained from environment for PGeval
				# it gives the full path to the current problem
				my $pngSourceFile = $self->convertPath("$templateDirectory${filePath}$aux_file_path.png");
				my $link = "gif/".$self->{uniqIDstub}."-$aux_file_path.$ext";
				my $linkPath = $self->surePathToTmpFile($link);
				$adr_output = "${tempURL}$link";
				#warn "linkPath is $linkPath";
				#warn "adr_output is $adr_output";
				if (-e $pngSourceFile) {
					if (-e $linkPath) {
						unlink($linkPath) || warn "Unable to unlink old alias file at $linkPath";
					}
					symlink($pngSourceFile, $linkPath)
					|| warn "The macro alias cannot create a link from |$linkPath|  to |$pngSourceFile| <BR>" ;
				} else {
					warn("The macro alias cannot find a PNG file at: |$pngSourceFile|");
				}
			}
	$adr_output;

}

sub alias_for_png_in_tex_mode {

  	my $self = shift;
	my $aux_file_path = shift;

	my $envir               = $self->{envir};  	my $fileName            = $envir->{fileName};
	my $htmlDirectory       = $envir->{htmlDirectory};
	my $htmlURL             = $envir->{htmlURL};
	my $tempDirectory       = $envir->{tempDirectory};
	my $tempURL             = $envir->{tempURL};
	my $studentLogin        = $envir->{studentLogin};
	my $psvnNumber          = $envir->{psvnNumber};
	my $setNumber           = $envir->{setNumber};
	my $probNum             = $envir->{probNum};
	my $displayMode         = $envir->{displayMode};
    my $externalGif2EpsPath = $envir->{externalGif2EpsPath};
    my $externalPng2EpsPath = $envir->{externalPng2EpsPath};
     
    my $templateDirectory   = $self->{templateDirectory};
    
   
	# $adr_output is a url in HTML and Latex2HTML modes
	# and a complete path in TEX mode.
	my $adr_output;
 	my $ext                 = "png";          
            ################################################################################
			# .png FILES in TeX mode
			################################################################################

		        $setNumber =~ s/\./_/g;  ## extra dots confuse latex's graphics package
			if ($envir->{texDisposition} eq "pdf") {
				# We're going to create PDF files with our TeX (using pdflatex); so we
				# need images in PNG format. what luck! they're already in PDF format!

				my $pngFilePath;

				if ($aux_file_path =~ m/^$htmlDirectory/ or $aux_file_path =~ m/^$tempDirectory/) {
					# we've got a full pathname to a file
					$pngFilePath = "$aux_file_path.png";
				} else {
					# we assume the file is in the same directory as the problem source file
					$pngFilePath = $templateDirectory . ($self->directoryFromPath($fileName)) . "$aux_file_path.png";
				}

				$adr_output = $pngFilePath;
			} else {
				# Since we're not creating PDF files; we're probably just using a plain
				# vanilla latex. Hence; we need EPS images.

				################################################################################
				# This is statement used below is system dependent.
				# Notice that the range of colors is restricted when converting to postscript to keep the files small
				# "cat $pngSourceFile  | /usr/math/bin/pngtopnm | /usr/math/bin/pnmtops -noturn > $adr_output"
				# "cat $pngSourceFile  | /usr/math/bin/pngtopnm | /usr/math/bin/pnmdepth 1 | /usr/math/bin/pnmtops -noturn > $adr_output"
				################################################################################

				if ($aux_file_path =~  m|^$htmlDirectory|  or $aux_file_path =~  m|^$tempDirectory|)  {
					# To serve an eps file copy an eps version of the png file to the subdirectory of eps/
					my $linkPath = $self->directoryFromPath($fileName);

					my $pngSourceFile = "$aux_file_path.png";
					my $pngFileName = fileFromPath($pngSourceFile);
					$adr_output = $self->surePathToTmpFile("$tempDirectory/eps/$studentLogin-$psvnNumber-$pngFileName.eps") ;

					if (-e $pngSourceFile) {
						#system("cat $pngSourceFile  | /usr/math/bin/pngtopnm | /usr/math/bin/pnmdepth 1 | /usr/math/bin/pnmtops -noturn>$adr_output")
						system("cat $pngSourceFile | ${externalPng2EpsPath} > $adr_output" )
							&& die "Unable to create eps file:\n |$adr_output| from file\n |$pngSourceFile|\n in problem $probNum " .
							       "using the system dependent commands\n |${externalPng2EpsPath}| \n";
					} else {
						die "|$pngSourceFile| cannot be found.  Problem number: |$probNum|";
					}
				} else {
					# To serve an eps file copy an eps version of the png file to  a subdirectory of eps/
					my $filePath = $self->directoryFromPath($fileName);
					my $pngSourceFile = "${templateDirectory}${filePath}$aux_file_path.png";
					#print "content-type: text/plain \n\nfileName = $fileName and aux_file_path =$aux_file_path<BR>";
					$adr_output = $self->surePathToTmpFile("eps/$studentLogin-$psvnNumber-set$setNumber-prob$probNum-$aux_file_path.eps") ;
					if (-e $pngSourceFile) {
						#system("cat $pngSourceFile  | /usr/math/bin/pngtopnm | /usr/math/bin/pnmdepth 1 | /usr/math/bin/pnmtops -noturn>$adr_output") &&
						#warn "Unable to create eps file: |$adr_output|\n from file\n |$pngSourceFile|\n in problem $probNum";
						#warn "Help ${externalPng2EpsPath}" unless -x "${externalPng2EpsPath}";
						system("cat $pngSourceFile | ${externalPng2EpsPath} > $adr_output" )
							&& die "Unable to create eps file:\n |$adr_output| from file\n |$pngSourceFile|\n in problem $probNum " .
							       "using the system dependent commands\n |${externalPng2EpsPath}| \n ";
					} else {
						die "|$pngSourceFile| cannot be found.  Problem number: |$probNum|";
					}
				}
			}
	$adr_output;

}

################################################

# More resource search macros

################################################

#
#  Look for a macro file in the directories specified in the macros path
#

# ^variable my $macrosPath
our ($macrosPath,
    # ^variable my $pwd
    $pwd,
    # ^variable my $appletPath
    $appletPath,
    # ^variable my $server_root_url
    $server_root_url,
	# ^variable my $templateDirectory
	$templateDirectory,
	# ^variable my $scriptDirectory
	$scriptDirectory,
	# ^variable my $externalTTHPath
	$externalTTHPath,
	);

# ^function findMacroFile
# ^uses $macrosPath
# ^uses $pwd
sub findMacroFile {
	my $self   = shift;
  my $fileName = shift;
  my $filePath;
  foreach my $dir (@{$macrosPath}) {
    $filePath = "$dir/$fileName";
    $filePath =~ s!^\.\.?/!$pwd/!;
    return $filePath if (-r $filePath);
  }
  return;  # no file found
}

# ^function check_url
# ^uses %envir
sub check_url {
	my $self = shift;
	my $url  = shift;
	return undef if $url =~ /;/;   # make sure we can't get a second command in the url
	#FIXME -- check for other exploits of the system call
	#FIXME -- ALARM feature so that the response cannot be held up for too long.
	#FIXME doesn't seem to work with relative addresses.
	#FIXME  Can we get the machine name of the server?

	 my $check_url_command = $self->{envir}->{externalCheckUrl};
	 my $response = system("$check_url_command $url"); 
	return ($response) ? 0 : 1; # 0 indicates success, 256 is failure possibly more checks can be made
}

# ^variable our %appletCodebaseLocations
our %appletCodebaseLocations = ();
# ^function findAppletCodebase
# ^uses %appletCodebaseLocations
# ^uses $appletPath
# ^uses $server_root_url
# ^uses check_url
sub findAppletCodebase {
	my $self     = shift;
	my $fileName = shift;  # probably the name of a jar file
	return $appletCodebaseLocations{$fileName}    #check cache first
		if defined($appletCodebaseLocations{$fileName})
			and $appletCodebaseLocations{$fileName} =~/\S/;
	
	foreach my $appletLocation (@{$appletPath}) {
		if ($appletLocation =~ m|^/|) {
			$appletLocation = "$server_root_url$appletLocation";
		}
		return $appletLocation;  # --hack workaround -- just pick the first location and use that -- no checks
#hack to workaround conflict between lwp-request and apache2
# comment out the check_url block
# 		my $url = "$appletLocation/$fileName";
# 		if ($self->check_url($url)) {
# 				$appletCodebaseLocations{$fileName} = $appletLocation; #update cache
# 			return $appletLocation	 # return codebase part of url
# 		}
 	}
 	return "Error: $fileName not found at ". join(",	", @{$appletPath} );	# no file found
}


1;