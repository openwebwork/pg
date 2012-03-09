################################################################################
# WeBWorK Online Homework Delivery System
# Copyright © 2000-2007 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader: pg/lib/PGalias.pm,v 1.6 2010/05/15 18:41:23 gage Exp $
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
	my $self = {
		type        =>  'png', # gif eps pdf html pg (macro: pl) (applets: java js fla geogebra (ggb) )
		parent_file => '',  # file id for the file requesting the resource
		path		=>  { content => undef,       # file path to resource
						  is_complete=>0,
						  is_accessible => 0,
						},
		uri			=>  { content => undef,       # usually url path to resource
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
		copy_link   =>  { type => undef,  # copy or link or orig (original file, no copy or link needed)
						  link_to_path => undef,   # the path of the alias 
						  copy_to_path => undef,   # the path of the duplicate file
						},
		cache_info	=>  {},
		unique_id   =>  undef, 
	};
	bless $self, $class;
	# $self->initialize;
	# $self->check_parameters;
	return $self;
}

sub uri {
	my $self = shift;
	my $uri = shift;
	$self->{uri}->{content}=$uri if $uri;
	$self->{uri}->{content};
}
sub path {
	my $self = shift;
	my $url = shift;
	$self->{path}->{content}=$url if $url;
	$self->{path}->{content};
}
package PGalias;
use strict;
use Exporter;
use UUID::Tiny  ':std';
use PGcore;

our @ISA =  qw ( PGcore  );  # look up features in PGcore -- in this case we want the environment.

=head2 

# new 
#   Create one alias object per question (and per PGcore object)
#   Check that information is intact
#   Construct unique id stubs -- the id stub is for this PGalias object which is 
#        attached to all the resource files (except equations) for this question.
#   Keep list of external links

=cut

sub new {
	my $class = shift;	
	my $envir = shift;  #pointer to environment hash
	my %options = @_;
	warn "PGlias must be called with an environment" unless ref($envir) eq 'HASH';
	my $self = {
		envir		=>	$envir,
		search_list  =>  [{url=>'foo',dir=>'.'}],   # for subclasses -> list of url/directories to search
		resource_list => {},
		%options,

	};
	bless $self, $class;
	$self->initialize;
	$self->check_parameters;
	return $self;
}


sub add_resource {
	my $self = shift;
	my ($aux_file_id,$resource) =@_;
	if ( ref($resource) =~/PGresource/ ) {
		$self->{resource_list}->{$aux_file_id} = $resource;
	} else {
		$self->warning_message("$aux_file_id does not refer to a a valid resource $resource");
	}
}
sub get_resource {
	my $self = shift;
	my $aux_file_id =shift;
	$self->{resource_list}->{$aux_file_id};
}
# methods
#     make_alias   -- outputs url and does what needs to be done
#     normalize paths (remove extra precursors to the path)
#     search directories for item
#     make_links   -- in those cases where links need to be made
#     create_files  -- e.g. when printing hardcopy
#     dispatcher -- decides what needs to be done based on displayMode and file type
#     alias_for_html
#     alias_for_image_in_html   image includes gif, png, jpg, swf, svg, flv?? ogg??, js
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
	$self->{psvn}                = $envir->{psvn};
	$self->{setNumber}           = $envir->{setNumber};
	$self->{probNum}             = $envir->{probNum};
	$self->{displayMode}         = $envir->{displayMode};
	$self->{externalGif2EpsPath} = $envir->{externalGif2EpsPath};
	$self->{externalPng2EpsPath} = $envir->{externalPng2EpsPath};
	$self->{courseID}            = $envir->{courseName};	
	
	$self->{appletPath} = $self->{envir}->{pgDirectories}->{appletPath};
	#
	#  Find auxiliary files even when the main file is in tempates/tmpEdit
	#
	$self->{fileName} =~ s!(^|/)tmpEdit/!$1!;
	
	$self->{ext}      = "";
# 	
# 	# create uniqeID stub    "gif/uniqIDstub-filePath"
# 				#  Make file names work in Library Browser when the images in several
# 				#  files have the same names.
# 				my $libFix = "";
# 				if ($self->{setNumber} eq "Undefined_Set") {
# 				  $libFix = $self->{fileName};
# 				  $libFix =~ s!.*/!!, $libFix =~ s!\.pg(\..*)?$!!;
# 				  $libFix =~ s![^a-zA-Z0-9._-]!!g;
# 				  $libFix .= '-';
# 				}
	my $uniqIDseed = join("-",   
							   $self->{studentLogin},
							   $self->{psvn},
							   $self->{courseID},
							   'set'.$self->{setNumber},
							   'prob'.$self->{probNum},
	);

##################################
# Cached vs. uncached uuid's -- or should the uuid be unique to each file/psvn/login, but always the same?
# If every uuid is uniqu then the same file will be linked to multiple times and it will be important
# to use asynchronous garbage cleanup to remove all links that won't be used again
# If one tries to reuse links then one can get duplicates, for example if many files using the same name
# (prob3.pg) appear in a list of library problems. 
###################################

##########################
# create an ID which is unique to the student and context for the problem
##########################
	my $uniqIDstub = create_uuid_as_string(UUID_V3, UUID_NS_URL, $uniqIDseed);
	$self->{uniqIDstub} = $uniqIDstub;		   

}

sub check_parameters {
	my $self = shift;

	# problem specific data
	warn "The path to the current problem file template is not defined."     unless $self->{fileName};
	warn "The current studentLogin is not defined "                          unless $self->{studentLogin};
	warn "The current problem set number is not defined"                     if $self->{setNumber} eq ""; # allow for sets equal to 0
	warn "The current problem number is not defined"                         if $self->{probNum} eq "";
	warn "The current problem set version number (psvn) is not defined"      unless defined($self->{psvn});
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
   	my $aux_file_id = shift @_;
   	# warn "aux_file_id = $aux_file_id";

	$self->warning_message( "Empty string used as input into the function alias") unless $aux_file_id;
	
	my $envir               = $self->{envir}; 
	my $displayMode         = $self->{displayMode}; 
    my $fileName            = $self->{fileName};    # name of .pg file
	my $envir               = $self->{envir};
	my $htmlDirectory       = $self->{htmlDirectory};
	my $htmlURL             = $self->{htmlURL};
	my $tempDirectory       = $self->{tempDirectory};
	my $tempURL             = $self->{tempURL};
	my $studentLogin        = $self->{studentLogin};
	my $psvn                = $self->{psvn};
	my $setNumber           = $self->{setNumber};
	my $probNum             = $self->{probNum};
    my $externalGif2EpsPath = $self->{externalGif2EpsPath};
    my $externalPng2EpsPath = $self->{externalPng2EpsPath}; 
    my $templateDirectory   = $self->{templateDirectory};
    
	# $adr_output is a url in HTML and Latex2HTML modes
	# and a complete path in TEX mode.
	my $adr_output;
	my $ext;
	
#######################################################################	
	# determine file type
	# determine display mode
	# dispatch	
#######################################################################
	# determine extension, if there is one
	# if extension exists, strip and use the value for $ext
	# files without extensions are considered to be picture files:


	if ($aux_file_id =~ s/\.([^\.]*)$// ) {
		$ext = $1;
	} else {
		$self->warning_message( "This file name $aux_file_id did not have an extension.<BR> " .
		     "Every file name used as an argument to alias must have an extension.<BR> " .
		     "The permissable extensions are .gif, .png, and .html .<BR>");
		$ext  = "gif";
		return undef;
	}


	# in order to facilitate maintenance of this macro the routines for handling
	# different file types are defined separately.  This involves some redundancy
	# in the code but it makes it easier to define special handling for a new file
	# type, (but harder to change the behavior for all of the file types at once
	# (sigh)  ).
	
	###################################################################
	# This section checks to see if a resource has already been made (in this problem) for 
	# this particular aux_file_id.
	# If so, we simply return the appropriate uri for the file.
	# The displayMode will be the same throughout the processing of the .pg file
	# This effectively cache's auxiliary files within a single PG question.
	###################################################################
	unless ( defined $self->get_resource($aux_file_id) ) {
    	$self->add_resource($aux_file_id, PGresource->new());
    	#warn "adding new resource_object $aux_file_id";
    } else {
    	#warn "found existing resource_object $aux_file_id";
    	return $self->get_resource($aux_file_id)->uri() ; 
    }
    # warn "next line\n\n";
    # warn "resource list contains ", %{ $self->{resource_list} };
	###################################################################
	
	if ($ext eq 'html') {
	   $adr_output = $self->alias_for_html($aux_file_id)
	} elsif ($ext eq 'gif') {
		if ( $displayMode eq 'HTML_MathJax'||
		     $displayMode eq 'HTML_dpng'||
		     $displayMode eq 'HTML' ||
		     $displayMode eq 'HTML_tth'||
		     $displayMode eq 'HTML_asciimath'||
		     $displayMode eq 'HTML_LaTeXMathML'||
		     $displayMode eq 'HTML_jsMath'||
		     $displayMode eq 'HTML_img') {
			################################################################################
			# .gif FILES in HTML; HTML_tth; HTML_dpng; HTML_img; and Latex2HTML modes
			################################################################################
			$adr_output=$self->alias_for_gif_in_html_mode($aux_file_id);
		
		} elsif ($displayMode eq 'TeX') {
			################################################################################
			# .gif FILES in TeX mode
			################################################################################
            $adr_output=$self->alias_for_gif_in_tex_mode($aux_file_id);
		
		} else {
			die "Error in alias: dangerousMacros.pl: unrecognizable displayMode = $displayMode";
		}
	} elsif ($ext eq 'png') {
		if ( $displayMode eq 'HTML_MathJax'||
		     $displayMode eq 'HTML_dpng'||
		     $displayMode eq 'HTML' ||
		     $displayMode eq 'HTML_tth'||
		     $displayMode eq 'HTML_asciimath'||
		     $displayMode eq 'HTML_LaTeXMathML'||
		     $displayMode eq 'HTML_jsMath'||
		     $displayMode eq 'HTML_img' )  {
		    $adr_output = $self->alias_for_png_in_html_mode($aux_file_id);
		} elsif ($displayMode eq 'TeX') {
			$adr_output = $self->alias_for_png_in_tex_mode($aux_file_id);
		
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

	# $adr_output is a url in HTML  modes
	# and a complete path in TEX mode.
	return $adr_output;
}



sub alias_for_html {
	my $self = shift;
	my $aux_file_id = shift;
    
	#######################
	#   gather needed data	
	#######################
	my $envir               = $self->{envir}; 
	my $fileName            = $self->{fileName};  #FIXME: this is really filePath to PG problem ??rename to filePath
	my $htmlDirectory       = $self->{htmlDirectory};
	my $htmlURL             = $self->{htmlURL};
	my $tempDirectory       = $self->{tempDirectory};
	my $tempURL             = $self->{tempURL};
	my $studentLogin        = $self->{studentLogin};
	my $psvn                = $self->{psvn};
	my $setNumber           = $self->{setNumber};
	my $probNum             = $self->{probNum};
    my $displayMode         = $self->{displayMode};
    my $externalGif2EpsPath = $self->{externalGif2EpsPath};
    my $externalPng2EpsPath = $self->{externalPng2EpsPath};     
    my $templateDirectory   = $self->{templateDirectory};

	#######################
	# update resource object
	my $resource_object = $self->get_resource($aux_file_id);
	# $self->warning_message( "\nresource for $aux_file_id is ", ref($resource_object), $resource_object );
    $resource_object->{type}='html';
    $resource_object->{parent_file}=$fileName;
    
   
	# $resource_uri is a url in HTML  modes
	# and a complete path in TEX mode.
	
	# Find a complete path to the auxiliary file by searching for it in the appropriate
	# libraries.  
	# Store the result in auxiliary_uri

##############################################
# Find complete path to the original files
##############################################
	my ($resource_uri, $htmlFileSource, );
	my $ext   =   "html";

# not yet completely implemented
# current implementation accepts only the course html directory, the file containing the .pg file 
# and the temp directory as places to look for html files

# No additional action is needed for auxiliary files in the
# ${Global::htmlDirectory} subtree.
	if ( $aux_file_id =~ m|^$tempDirectory| ) {
		$resource_uri = $aux_file_id,
		$htmlFileSource = $aux_file_id;
		$resource_uri =~ s|$tempDirectory|$tempURL/|,
		$resource_uri .= ".$ext",
		$resource_object->path($htmlFileSource);
		$resource_object->uri($resource_uri);
		$resource_object->{copy_link}->{type} = 'orig';
		$resource_object->{path}->{is_complete}=1;
	} elsif ($aux_file_id =~ m|^$htmlDirectory| ) {
		$resource_uri = $aux_file_id,
		$htmlFileSource = $aux_file_id;
		$resource_uri =~ s|$htmlDirectory|$htmlURL|,
		$resource_uri .= ".$ext",
		$resource_object->path($htmlFileSource);
		$resource_object->uri($resource_uri);
		$resource_object->{copy_link}->{type} = 'orig';
		$resource_object->{path}->{is_complete}=1;
	} else {
		# HTML files not in the htmlDirectory are assumed under live under the
		# templateDirectory in the same directory as the problem.
		# Create an alias file (link) in the directory html/tmp/html which
		# points to the original file and return the URL of this alias.
		# ---  Create all of the subdirectories of html/tmp/html which are needed
		# --- using sure file to path.  This gives too much information away.
		# use a uniquID instead.
	
		# $fileName is obtained from environment and
		# is the path to the .pg file
		# it gives the  relative path to the current PG problem from the template directory
		my $directoryPath = $self->directoryFromPath($fileName);
		$htmlFileSource = $self->convertPath("$templateDirectory${directoryPath}$aux_file_id.html");
		$htmlFileSource = "$templateDirectory${directoryPath}$aux_file_id.html";
		$resource_object->path($htmlFileSource);
		$resource_object->{copy_link}->{type} = 'link';
		$resource_object->{path}->{is_complete}=1;
		# notice the resource uri is not yet defined -- we have to make the link first
	}

# Create a unique id which depends on the parent fileName and path to the resource file
# The uniqueID  also depends on the student, the course name and  the psvn through the uniqeID stub, because 
# if the problem is recreated the specific file linked to might change.
# You  also want students linked to the same file to NOT be aware of that fact.


	my $uniqIDseed = $resource_object->path() . $resource_object->{parent_file}.$self->{psvn};
	$resource_object->{uniqID} = $self->{uniqIDstub} .
	      '___'. create_uuid_as_string( UUID_V3, UUID_NS_URL, $uniqIDseed );


##############################################
# Create links, between private directories such as myCourse/template
# and public directories (such as   wwtmp/courseName or myCourse/html
# The location of the links depends on the type and location of the file
##############################################

	if ( $resource_object->{copy_link}->{type} eq 'link') {
		my $uniqID = $resource_object->{uniqID};
		my $link = "html/$uniqID";
		my $resource_uri = "${tempURL}$link"; #FIXME -- insure that the slash is at the end of $tempURL
		my $linkPath = $self->surePathToTmpFile($link);
		
		if (-e $htmlFileSource) {
			if (-e $linkPath) {
				unlink($linkPath) || warn "Unable to unlink alias file at |$linkPath|";
				# destroy the old link.
			}
			if (symlink( $htmlFileSource, $linkPath)) {
				$resource_object->{path}->{is_accessible}=1;
				$resource_object->{copy_link}->{link_to_path}= $linkPath;
				$resource_object->uri($resource_uri);
			} else {
				$self->warning_message( "The macro alias cannot create a link from |$linkPath|  to |$htmlFileSource| <BR>") ;
			}
		} else {
			$self->warning_message("The macro alias cannot find an HTML file at: |$htmlFileSource|");
			$resource_object->{path}->{is_accessible}=0;
			# we should delete the resource object in this case?
		}
		$resource_object->uri();  # return the uri of the resource
	}
}


sub alias_for_gif_in_html_mode {
	my $self = shift;
	my $aux_file_id = shift;
#    warn "entering alias_for_gif_in_html_mode $aux_file_id";
    
	my $envir               = $self->{envir};  	
	my $fileName            = $self->{fileName};
	my $htmlDirectory       = $envir->{htmlDirectory};
	my $htmlURL             = $envir->{htmlURL};
	my $tempDirectory       = $envir->{tempDirectory};
	my $tempURL             = $envir->{tempURL};
	my $studentLogin        = $envir->{studentLogin};
	my $psvn          = $envir->{psvn};
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
			#warn "file Path for auxiliary file is $aux_file_id";

			# No changes are made for auxiliary files in the htmlDirectory or in the tempDirectory subtree.
			if ( $aux_file_id =~ m|^$tempDirectory| ) {
				$adr_output = $aux_file_id;
				$adr_output =~ s|$tempDirectory|$tempURL|;
				$adr_output .= ".$ext";
				#warn "adress out is $adr_output",
			} elsif ($aux_file_id =~ m|^$htmlDirectory| ) {
				$adr_output = $aux_file_id;
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
				my $gifSourceFile = $self->convertPath("$templateDirectory${filePath}$aux_file_id.gif");
				#my $link = "gif/$studentLogin-$psvn-set$setNumber-prob$probNum-$aux_file_id.$ext";
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

				# my $link = "gif/$setNumber-prob$probNum-$libFix$aux_file_id.$ext";
			    my $uniqIDstub = $self->{uniqIDstub};
				my $link = "gif/${uniqIDstub}-$aux_file_id.$ext";
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
	my $aux_file_id = shift;

	my $envir               = $self->{envir};  	my $fileName            = $envir->{fileName};
	my $htmlDirectory       = $envir->{htmlDirectory};
	my $htmlURL             = $envir->{htmlURL};
	my $tempDirectory       = $envir->{tempDirectory};
	my $tempURL             = $envir->{tempURL};
	my $studentLogin        = $envir->{studentLogin};
	my $psvn          = $envir->{psvn};
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

				if ($aux_file_id =~ m/^$htmlDirectory/ or $aux_file_id =~ m/^$tempDirectory/) {
					# we've got a full pathname to a file
					$gifFilePath = "$aux_file_id.gif";
				} else {
					# we assume the file is in the same directory as the problem source file
					my $dir = $self->directoryFromPath($fileName);
					$gifFilePath = "$templateDirectory${dir}$aux_file_id.gif";
				}

				my $gifFileName = $self->fileFromPath($gifFilePath);
				$gifFileName =~ /^(.*)\.gif$/;
					my $pngFilePath = $self->surePathToTmpFile("${tempDirectory}png/$setNumber-$probNum-$1.png");
				my $command = $envir->{externalGif2PngPath};
				my $returnCode = system "cat $gifFilePath | $command > $pngFilePath";
			#warn "FILE path $pngFilePath  exists =", -e $pngFilePath;
				if ($returnCode or not -e $pngFilePath) {
					warn "returnCode $returnCode: failed to convert $gifFilePath to $pngFilePath using gif->png with $command: $!";
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
				if ($aux_file_id =~  m|^$htmlDirectory|  or $aux_file_id =~  m|^$tempDirectory|)  {
					# To serve an eps file copy an eps version of the gif file to the subdirectory of eps/
					my $linkPath = $self->directoryFromPath($fileName);

					my $gifSourceFile = "$aux_file_id.gif";
					my $gifFileName = $self->fileFromPath($gifSourceFile);
					$adr_output = $self->surePathToTmpFile("$tempDirectory/eps/$studentLogin-$psvn-$gifFileName.eps") ;

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
					my $gifSourceFile = "${templateDirectory}${filePath}$aux_file_id.gif";
					#print "content-type: text/plain \n\nfileName = $fileName and aux_file_id =$aux_file_id<BR>";
					$adr_output = $self->surePathToTmpFile("eps/$studentLogin-$psvn-set$setNumber-prob$probNum-$aux_file_id.eps");

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
	my $aux_file_id = shift;

	my $envir               = $self->{envir};  	my $fileName            = $envir->{fileName};
	my $htmlDirectory       = $envir->{htmlDirectory};
	my $htmlURL             = $envir->{htmlURL};
	my $tempDirectory       = $envir->{tempDirectory};
	my $tempURL             = $envir->{tempURL};
	my $studentLogin        = $envir->{studentLogin};
	my $psvn          = $envir->{psvn};
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
			#warn "file Path for auxiliary file is $aux_file_id";

			# No changes are made for auxiliary files in the htmlDirectory or in the tempDirectory subtree.
			if ( $aux_file_id =~ m|^$tempDirectory| ) {
			$adr_output = $aux_file_id;
				$adr_output =~ s|$tempDirectory|$tempURL|;
				$adr_output .= ".$ext";
				#warn "adress out is $adr_output";
			} elsif ($aux_file_id =~ m|^$htmlDirectory| ) {
				$adr_output = $aux_file_id;
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
				my $pngSourceFile = $self->convertPath("$templateDirectory${filePath}$aux_file_id.png");
				my $uniqIDstub = $self->{uniqIDstub};
				my $link = "gif/${uniqIDstub}-$aux_file_id.$ext";
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
	my $aux_file_id = shift;

	my $envir               = $self->{envir};  	my $fileName            = $envir->{fileName};
	my $htmlDirectory       = $envir->{htmlDirectory};
	my $htmlURL             = $envir->{htmlURL};
	my $tempDirectory       = $envir->{tempDirectory};
	my $tempURL             = $envir->{tempURL};
	my $studentLogin        = $envir->{studentLogin};
	my $psvn          = $envir->{psvn};
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

				if ($aux_file_id =~ m/^$htmlDirectory/ or $aux_file_id =~ m/^$tempDirectory/) {
					# we've got a full pathname to a file
					$pngFilePath = "$aux_file_id.png";
				} else {
					# we assume the file is in the same directory as the problem source file
					my $dir = $self->directoryFromPath($fileName);
					$pngFilePath = "$templateDirectory${dir}$aux_file_id.png";
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

				if ($aux_file_id =~  m|^$htmlDirectory|  or $aux_file_id =~  m|^$tempDirectory|)  {
					# To serve an eps file copy an eps version of the png file to the subdirectory of eps/
					my $linkPath = $self->directoryFromPath($fileName);

					my $pngSourceFile = "$aux_file_id.png";
					my $pngFileName = fileFromPath($pngSourceFile);
					$adr_output = $self->surePathToTmpFile("$tempDirectory/eps/$studentLogin-$psvn-$pngFileName.eps") ;

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
					my $pngSourceFile = "${templateDirectory}${filePath}$aux_file_id.png";
					#print "content-type: text/plain \n\nfileName = $fileName and aux_file_id =$aux_file_id<BR>";
					$adr_output = $self->surePathToTmpFile("eps/$studentLogin-$psvn-set$setNumber-prob$probNum-$aux_file_id.eps") ;
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
	my $OK_CONSTANT = "200 OK";
	return undef if $url =~ /;/;   # make sure we can't get a second command in the url
	#FIXME -- check for other exploits of the system call
	#FIXME -- ALARM feature so that the response cannot be held up for too long.
	#FIXME doesn't seem to work with relative addresses.
	#FIXME  Can we get the machine name of the server?

	 my $check_url_command = $self->{envir}->{externalCheckUrl};
	 my $response = `$check_url_command $url`; 
	return ($response =~ /^$OK_CONSTANT/) ? 1 : 0; 
}

# ^variable our %appletCodebaseLocations

# ^function findAppletCodebase
# ^uses %appletCodebaseLocations
# ^uses $appletPath
# ^uses $server_root_url
# ^uses check_url

our %appletCodebaseLocations = ();   # cache for found applets (lasts until the child exits
sub findAppletCodebase {
	my $self     = shift;
	my $fileName = shift;  # probably the name of a jar file
	$server_root_url=$self->envir("server_root_url");
	#check cache first
	if (defined($appletCodebaseLocations{$fileName})  
	      and $appletCodebaseLocations{$fileName} =~/\S/  )
	{
	   	return $appletCodebaseLocations{$fileName};	# return if found in cache
	}
	my $appletPath = $self->{appletPath};
	foreach my $appletLocation (@{$appletPath}) {
		if ($appletLocation =~ m|^/|) {
			$appletLocation = "$server_root_url$appletLocation";
		}
		my $url = "$appletLocation/$fileName";

 		if ($self->check_url($url)) {
 				$appletCodebaseLocations{$fileName} = $appletLocation; #update cache
 			return $appletLocation	 # return codebase part of url
 		}
 	}
 	warn "findAppletCodebase Error: $fileName not found after searching ". join(",	", @{$appletPath} );
 	return "";
}


1;