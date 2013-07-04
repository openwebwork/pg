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


package PGalias;
use strict;
use Exporter;
use UUID::Tiny  ':std';
use PGcore;
use PGresource;

our @ISA =  qw ( PGcore  );  # look up features in PGcore -- in this case we want the environment.

=head2 

# new 
#   Create one alias object per question (and per PGcore object)
#   Check that information is intact
#   Construct unique id stub seeds -- the id stub seed is for this PGalias object which is 
#        attached to all the resource files (except equations) for this question.
#   Keep list of external links

=cut

sub new {
	my $class = shift;	
	my $envir = shift;  #pointer to environment hash
	my %options = @_;
	warn "PGlias must be called with an environment" unless ref($envir) =~ /HASH/;
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
		#$self->debug_message("$aux_file_id resource added");
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
	$self->{pgFileName}          = $envir->{probFileName};
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
	$self->{externalGif2PngPath} = $envir->{externalGif2PngPath};
	$self->{courseID}            = $envir->{courseName};	
	
	$self->{appletPath} = $self->{envir}->{pgDirectories}->{appletPath};
	#
	#  Find auxiliary files even when the main file is in tempates/tmpEdit
	#
	$self->{pgFileName} =~ s!(^|/)tmpEdit/!$1!;
	
	$self->{ext}      = "";

	my $unique_id_seed = join("-",   
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
	my $unique_id_stub = create_uuid_as_string(UUID_V3, UUID_NS_URL, $unique_id_seed);
	$self->{unique_id_stub} = $unique_id_stub;		   

}

sub check_parameters {
	my $self = shift;

	# problem specific data
	$self->warning_message( "The path to the current problem file template probFileName is not defined." )    unless $self->{pgFileName};
	$self->warning_message( "The current studentLogin is not defined " )                         unless $self->{studentLogin};
	$self->warning_message( "The current problem set number setNumber is not defined" )                    if $self->{setNumber} eq ""; # allow for sets equal to 0
	$self->warning_message( "The current problem number probNum is not defined"  )                       if $self->{probNum} eq "";
	$self->warning_message( "The current problem set version number (psvn) is not defined" )     unless defined($self->{psvn});
	$self->warning_message( "The displayMode is not defined" )                                   unless $self->{displayMode};

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
   	my $aux_file_id = shift;
	#$self->debug_message("make alias for file $aux_file_id");
	$self->warning_message( "Empty string used as input into the function alias") unless $aux_file_id;
	
	my $envir               = $self->{envir}; 
	my $displayMode         = $self->{displayMode}; 
	my $pgFileName          = $self->{pgFileName};    # name of .pg file
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
	my $ext='';
	
#######################################################################	
	# determine file type
	# determine display mode
	# dispatch	
#######################################################################
	# determine extension, if there is one
	# if extension exists, strip and use the value for $ext
	# files without extensions are flagged with errors.

	#      								$self->debug_message("This auxiliary file id is $aux_file_id" );
	if ($aux_file_id =~ s/\.([^\.]+)$// ) {
		$ext = $1;
	} else {
		$self->warning_message( "The file name $aux_file_id did not have an extension.<BR> " .
		     "Every file name used as an argument to alias must have an extension.<BR> " .
		     "The permissable extensions are .jpg, .pdf, .gif, .png, and .html .<BR>");
		$ext  = undef;
		return undef;  #quit;
	}
	#      								$self->debug_message("This auxiliary file id is $aux_file_id of type $ext" );

	# in order to facilitate maintenance of this macro the routines for handling
	# different file types are defined separately.  This involves some redundancy
	# in the code but it makes it easier to define special handling for a new file
	# type, (but harder to change the behavior for all of the file types at once
	# (sigh)  ).
	
###################################################################
# Create resource object
###################################################################
	
	
	###################################################################
	# This section checks to see if a resource exists (in this problem) 
	#for this particular aux_file_id.
	# If so, we simply return the appropriate uri for the file.
	# The displayMode will be the same throughout the processing of the .pg file
	# This effectively cache's auxiliary files within a single PG question.
	###################################################################
	unless ( defined $self->get_resource($aux_file_id.".$ext") ) {
    	$self->add_resource($aux_file_id.".$ext", 
    	                    PGresource->new(
    	                            $self,                    #parent alias of resource
    	                            $aux_file_id,             # resource file name
    	                            $ext,                     # resource type
    	                            WARNING_messages => $self->{WARNING_messages},  #connect warning message channels
                                    DEBUG_messages   => $self->{DEBUG_messages},
    	));

    } else {
    	#$self->debug_message( "found existing resource_object $aux_file_id");
    	return $self->get_resource($aux_file_id.".$ext")->uri() ; 
    }
###################################################################
# Create resource object if it has not already been defined
###################################################################
    #warn "next line\n\n";
    #warn "resource list contains ", %{ $self->{resource_list} };
	###################################################################
	
	if ($ext eq 'html') {
	   $adr_output = $self->alias_for_html($aux_file_id)
	} elsif (   $ext eq 'gif'  
		     or $ext eq 'jpg' 
		     or $ext eq 'png'
		    ) {
		if ($displayMode =~ /^HTML/ ) {
			################################################################################
			# image FILES in HTML; HTML_tth; HTML_dpng; HTML_img; HTML_asciimath; 
			# HTML_LaTeXMathML; HTML_jsMath; HTML_img
			################################################################################
			 
			 $adr_output=$self->alias_for_image_in_html_mode($aux_file_id, $ext);
		
		} elsif ($displayMode eq 'TeX') {
			################################################################################
			# .gif FILES in TeX mode
			################################################################################
            $adr_output=$self->alias_for_image_in_tex_mode($aux_file_id, $ext);
		
		} else {
			die "Error in alias: PGalias.pm: unrecognizable displayMode = $displayMode";
		}
	} elsif ($ext eq 'svg') {
		if ($displayMode =~/HTML/) {
			$self->warning_message("The image $aux_file_id of type $ext cannot yet be displayed in HTML mode");
			# svg images need an embed tag not an image tag -- need to modify image for this also
			# an alternative (not desirable) is to convert svg to png
		} elsif ($displayMode eq 'TeX') {
			$self->warning_message("The image $aux_file_id of type $ext cannot yet be displayed in TeX mode");
		} else {
			die "Error in alias: PGalias.pm: unrecognizable displayMode = $displayMode";
		}
	
	} elsif ($ext eq 'pdf') {
		if ($displayMode =~/HTML/) {
			$self->warning_message("The image $aux_file_id of type pdf cannot yet be displayed in HTML mode");
		} elsif ($displayMode eq 'TeX') {
			$adr_output=$self->alias_for_image_in_tex_mode($aux_file_id, $ext);
		} else {
			die "Error in alias: PGalias.pm: unrecognizable displayMode = $displayMode";
		}
	
	} else { # $ext is not recognized
		################################################################################
		# FILES  with unrecognized file extensions in any display modes
		################################################################################

		warn "Error in the macro alias. Alias does not understand how to process files with extension $ext.  
		      (Path to problem file is  $pgFileName) ";
	}

	warn "The macro alias was unable to form a URL for some auxiliary file used in this problem." unless $adr_output;

	# $adr_output is a url in HTML  modes
	# and a complete path in TEX mode.
	return $adr_output;
}



sub alias_for_html {
	my $self = shift; #handed alias object
	my $aux_file_id = shift; #handed the name of the resource object
	                         # case 1:  aux_file_id is complete or relative path to file
	                         # case 2:  aux_file_id is file name alone relative to the templates directory.
    
#######################
#   gather needed data and declare it locally
#######################
	my $htmlURL       = $self->{htmlURL};
	my $htmlDirectory = $self->{htmlDirectory};
	my $pgFileName    = $self->{pgFileName};
	my $tempURL       = $self->{tempURL};
	my $tempDirectory = $self->{tempDirectory};
	my $templateDirectory = $self->{templateDirectory};
	
#######################
# update html resource object
#######################
	my ($resource_uri, $htmlFileSource, );
	my $ext   =   "html";
	my $resource_object = $self->get_resource($aux_file_id.".$ext");
	#$self->debug_message( "\nresource for $aux_file_id is ", ref($resource_object), $resource_object );

   
   

##############################################
# Find complete path to the original files
##############################################

# Find a complete path to the auxiliary file by searching for it in the appropriate
# libraries.  
# Store the result in auxiliary_uri  FIXME: TO BE DONE
# not yet completely implemented
# current implementation accepts only the course html directory, the directory containing the .pg file 
# and the temp directory as places to look for html files



# $resource_uri is a url in HTML  mode
# and a complete path in TEX mode.

# No linking or copying action is needed for auxiliary files in the
# ${Global::htmlDirectory} subtree.

##################### Case1: we've got a full pathname to a file in either the temp directory or the htmlDirectory
##################### Case2: we assume the file is in the same directory as the problem source file

# store the complete path to the original file
	if ( $aux_file_id     =~ m|^$tempDirectory| ) { #case: file is stored in the course temporary directory
		$resource_uri     =  $aux_file_id,
		$resource_uri     =~ s|$tempDirectory|$tempURL/|;
		$resource_uri    .=  ".$ext";
		$resource_object->uri($resource_uri);           #no unique id is needed -- public doc

		$htmlFileSource   = $aux_file_id;		
		$resource_object->path($htmlFileSource.".$ext");
		$resource_object->{copy_link}->{type}      = 'orig'; # no copying required
		$resource_object->{path}->{is_complete}    =      1;
		
	} elsif ($aux_file_id =~ m|^$htmlDirectory| ) { #case: file is under the course html directory
		$resource_uri    = $aux_file_id,
		$resource_uri    =~ s|$htmlDirectory|$htmlURL|,
		$resource_uri   .= ".$ext",
		$resource_object->uri($resource_uri); #no unique id is needed -- public doc
		
		$htmlFileSource = $aux_file_id;
		$resource_object->path($htmlFileSource);
		$resource_object->{copy_link}->{type} = 'orig';
		$resource_object->{path}->{is_complete}=1;
	} else {
		# HTML files not in the htmlDirectory are assumed under live under the
		# templateDirectory in the same directory as the problem.
		# Create an alias file (link) in the directory html/tmp/html which
		# points to the original file and return the URI of this alias.
		# ---  Create all of the subdirectories of html/tmp/html which are needed
		# ---  using sure file to path.  This gives too much information away.
		# use a uniquID instead.
	
		# $pgFileName is obtained from environment and
		# is the path to the .pg file
		# it gives the  relative path to the current PG problem from the template directory
		my $directoryPath = $self->directoryFromPath($pgFileName);

		$htmlFileSource = "$templateDirectory${directoryPath}$aux_file_id";
		$resource_object->path($htmlFileSource.".$ext");
		$resource_object->{copy_link}->{type} = 'link';
		$resource_object->{path}->{is_complete}=0;
		$resource_object->{uri}->{is_complete}=0;
		$resource_object->create_unique_id();
		# notice the resource uri is not yet defined -- we have to make the link first
	}



##############################################
# Create links, 
# between private directories such as myCourse/template
# and public directories (such as   wwtmp/courseName or myCourse/html
# The location of the links depends on the type and location of the file
##############################################

	if ( $resource_object->{copy_link}->{type} eq 'link') {
		my $unique_id      = $resource_object->{unique_id};
		my $link           = "html/$unique_id.$ext";
		my $resource_uri   = "${tempURL}$link"; #FIXME -- insure that the slash is at the end of $tempURL
		my $linkPath       = $self->surePathToTmpFile($link);
		
		if (-e $resource_object->path()) {

#################
# destroy the old link.
#################
			if (-e $linkPath) {
				unlink($linkPath) || $self->warning_message( "Unable to unlink alias file at |$linkPath|");
				
			}
#################
# create new link.
# create uri to this link
#################
			if (symlink( $resource_object->path(), $linkPath)) {
				$resource_object->{path}->{is_accessible}       =1;
				$resource_object->{copy_link}->{link_to_path}   = $linkPath;
				$resource_object->{path}->{is_accessible}       = (-r $linkPath);
				
				$resource_object->uri($resource_uri);
				$resource_object->{uri}->{is_accessible}        = $self->check_url($resource_object->uri());
				$resource_object->{path}->{is_complete}         = 1;
				$resource_object->{uri}->{is_complete}          = 1;
			} else {
				$self->warning_message( "The macro alias cannot create a link from |$linkPath|  to |".$resource_object->path()."|<BR>") ;
			}
		} else {
			$self->warning_message("The macro alias cannot find an HTML file at: |".$resource_object->path()."|");
			$resource_object->{path}->{is_accessible}= 0;
			$resource_object->{uri}->{is_accessible} = 0;
			# we should delete the resource object in this case?
		}
		
	}
	# $self->debug_message("alias_for_html: url is ".$resource_object->uri(). " check ".$self->check_url($resource_object->uri()) );

	$resource_object->uri();  # return the uri of the resource -- in this case the URL for the file in the temp directory
}

sub alias_for_image_in_html_mode {
	my $self        = shift;
	my $aux_file_id = shift;
	my $ext         = shift;
	#$self->debug_message("entering alias_for_image_in_html_mode with file $aux_file_id of type $ext");
#######################
# gather needed data and declare it locally
#######################
	my $htmlURL            = $self->{htmlURL};
    my $htmlDirectory      = $self->{htmlDirectory};
	my $pgFileName         = $self->{pgFileName};
	my $tempURL            = $self->{tempURL};
	my $tempDirectory      = $self->{tempDirectory};
	my $templateDirectory  = $self->{templateDirectory};
   
#######################
# update image resource object
#######################
	my ($resource_uri  );
	my $resource_object = $self->get_resource($aux_file_id.".$ext");
    #$self->debug_message( "\nresource for $aux_file_id is ", ref($resource_object), $resource_object );

##############################################
# Find complete path to the original files
##############################################

# Find a complete path to the auxiliary file by searching for it in the appropriate
# libraries.  
# Store the result in auxiliary_uri  FIXME: TO BE DONE
# not yet completely implemented
# current implementation accepts only the course html directory, the file containing the .pg file 
# and the temp directory as places to look for html files



# $resource_uri is a url in HTML  mode
# and a complete path in TEX mode.



# No linking or copying action is needed for auxiliary files in the
# ${Global::htmlDirectory} subtree.

# $self->debug_message("find full path to file $aux_file_id");
# store the complete path to the original file
	if ( $aux_file_id   =~ m|^$tempDirectory| ) { #case: file is stored in the course temporary directory
		$resource_uri   = $aux_file_id;
		$resource_uri   =~ s|$tempDirectory|$tempURL/|;
		$resource_uri  .= ".$ext";
		$resource_object->uri($resource_uri);           #no unique id is needed -- public doc
		

		$resource_object->path($aux_file_id.".$ext");		
		$resource_object->{copy_link}->{type} = 'orig';
		$resource_object->{path}->{is_complete} = 1;
		
	} elsif ($aux_file_id =~ m|^$htmlDirectory| ) { #case: file is under the course html directory
		$resource_uri     = $aux_file_id;
		$resource_uri     =~ s|$htmlDirectory|$htmlURL|;
		$resource_uri    .= ".$ext";
		$resource_object->uri($resource_uri);
				
		$resource_object->path($aux_file_id.".$ext");
		$resource_object->{copy_link}->{type} = 'orig';
		$resource_object->{path}->{is_complete}=1;

	} else {

		# image files not in the htmlDirectory sub tree are assumed to live under the templateDirectory
		# subtree in the same directory as the problem.
		# Create an alias file (link) in the directory html/images which
		# points to the original image file in the template directory and and return the URI of this alias.
		# --- All of the subdirectories of html/tmp/img which are needed are also created.
		# use a unique_id instead
	
		# $pgFileName was obtained from environment originally and
		# it gives the  relative path to the current PG problem from the template directory
		
		my $directoryPath = $self->directoryFromPath($pgFileName);
		my $sourceFilePath    = "$templateDirectory${directoryPath}$aux_file_id";
		$resource_object->path($sourceFilePath.".$ext");
		$resource_object->{path}->{is_complete}=0;
		$resource_object->{copy_link}->{type} = 'link';
		$resource_object->{path}->{is_complete}=0;
		$resource_object->create_unique_id();
		# notice the resource uri is not yet defined -- we have to make the link first
	}
		
##############################################
# Create links for objects of "link" type.
# between private directories such as myCourse/template
# and public directories (such as   wwtmp/courseName or myCourse/html
# The location of the links depends on the type and location of the file
##############################################

	if ( $resource_object->{copy_link}->{type} eq 'link') {
	
		my $unique_id     = $resource_object->{unique_id};
		my $link          = "img/$unique_id.$ext";
		my $linkPath      = $self->surePathToTmpFile($link); # create img directory if needed.

		my $resource_uri  = "${tempURL}$link"; #FIXME -- insure that the slash is at the end of $tempURL

#################
# destroy the old link.
# create new link.
# create uri to this link
#################

		if (-e $resource_object->path()) {
		
			if (-e $linkPath) {
				unlink($linkPath) || warn "Unable to unlink old alias file at $linkPath";
			}
			if (symlink( $resource_object->path(), $linkPath)) {
				$resource_object->{copy_link}->{link_to_path}    = $linkPath;
				$resource_object->{path}->{is_accessible}        = (-r $linkPath);
				$resource_object->{path}->{is_complete}          = 1;
				
				$resource_object->uri($resource_uri);
				$resource_object->{uri}->{is_accessible}         = $self->check_url($resource_object->uri());
				$resource_object->{uri}->{is_complete}           = 1;
			} else {
				$self->warning_message( "The macro alias cannot create a link from |$linkPath|  to |".$resource_object->path."|.") ;
			}
		} else {
			$self->warning_message("The macro alias cannot find an image $ext file at: |".$resource_object->path."|");
			$resource_object->{path}->{is_accessible}=0;
			# we should delete the resource object in this case?
		}
	# $self->debug_message("alias_for_image_in_html: $aux_file_id is given url  ".$resource_object->uri(). " linkPath is $linkPath" );
		
	}
	$resource_object->uri();  # return the uri of the resource
}



################################################################################
# alias for image in tex mode
################################################################################




sub alias_for_image_in_tex_mode {
	my $self         = shift;
	my $aux_file_id  = shift;
	my $ext          = shift;

	# $self->debug_message( "entering alias_for_gif_in_tex_mode $aux_file_id, ext=$ext");
 ##### other things we need #########
 
    my $from_file_type       = $ext ;
    my $to_file_type         = "png" ;           # needed for conversion cases
    
    my $convert_fileQ        = ($ext      eq   'png' # graphic types accepted by 
                                  or $ext eq   'pdf'
                                  or $ext eq   'jpg'
                                )? 0: 1   ;      # does this file need conversion
    
    my $link_fileQ =0        ;      # does this file need to be linked?
    my $targetDirectory      = "images" ;      # subdirectory of tmp directory
    my $conversion_command   = $self->{externalGif2PngPath};
#######################
# gather needed data and declare it locally
#######################
	my $htmlURL           = $self->{htmlURL};
    my $htmlDirectory     = $self->{htmlDirectory};
	my $pgFileName        = $self->{pgFileName};
	my $tempURL           = $self->{tempURL};
	my $tempDirectory     = $self->{tempDirectory};
	my $templateDirectory = $self->{templateDirectory};

#######################
# update resource object
#######################
	my ($resource_uri,  );
	my $resource_object = $self->get_resource($aux_file_id.".$ext");

		        
################################################################################
# Create PDF output directly -- convert .gif to .png format which pdflatex accepts natively
################################################################################

	unless ($self->{envir}->{texDisposition} eq "pdf") {
		$self->warning_message("Support for pure latex output (as opposed to pdflatex output) is not implemented.");
		return ""; # blank resource_uri
	}
	# We're going to create PDF files with our TeX (using pdflatex); so we
	# need images in PNG format.
	# No longer support for pure latex/DVI construction


##############################################
# Find complete path to the original files
##############################################

# Find a complete path to the auxiliary file by searching for it in the appropriate
# libraries.  
# Store the result in auxiliary_uri  FIXME: TO BE DONE
# not yet completely implemented
# current implementation accepts only the course html directory, the file containing the .pg file 
# and the temp directory as places to look for html files



# $resource_uri is a url in HTML  mode
# and a complete path in TEX mode.

# No linking or copying action is needed for auxiliary files in the
# ${Global::htmlDirectory} subtree.

##################### Case1: we've got a full pathname to a file in either the temp directory or the htmlDirectory
##################### Case2: we assume the file is in the same directory as the problem source file

# store the complete path to the original file

	if ( $aux_file_id      =~ m|^$tempDirectory| ) { #case: file is stored in the course temporary directory

		my $sourceFilePath =  $aux_file_id;	
		$resource_object->path($sourceFilePath.".$ext");
		$resource_object->{path}->{is_complete}  = 1;
# Gif files always need to be converted to png files for inclusion in pdflatex documents.
		
		$resource_object->{convert}->{needed}    = $convert_fileQ;
		$resource_object->{convert}->{from_path} = $sourceFilePath.".$ext";
		$resource_object->{convert}->{from_type} = $from_file_type;
		$resource_object->{convert}->{to_path}   = '';  #define later
		$resource_object->{convert}->{to_type}   = $to_file_type;

	} elsif ($aux_file_id =~ m|^$htmlDirectory| ) { #case: file is under the course html directory

		my $sourceFilePath = $aux_file_id;
		$resource_object->path($sourceFilePath.".$ext");
		$resource_object->{path}->{is_complete}=1;
				
		$resource_object->{convert}->{needed}    = $convert_fileQ;
		$resource_object->{convert}->{from_path} = $sourceFilePath.".$ext";
		$resource_object->{convert}->{from_type} = $from_file_type;
		$resource_object->{convert}->{to_path}   = '';  #define later
		$resource_object->{convert}->{to_type}   = $to_file_type;
		
	
	} else {
		
		# GIF files not in the htmlDirectory sub tree are assumed to live under the templateDirectory
		# subtree in the same directory as the problem.
		# Create an alias file (link) in the directory html/images which
		# points to the original gif file in the template directory and and return the URI of this alias.
		# --- All of the subdirectories of html/tmp/gif which are needed are also created.
		# use a unique_id instead
	
		# $pgFileName was obtained from environment originally and
		# it gives the  relative path to the current PG problem from the template directory
		
		my $directoryPath = $self->directoryFromPath($pgFileName);
		my $sourceFilePath = "$templateDirectory${directoryPath}$aux_file_id";
							#my $link = "gif/$studentLogin-$psvn-set$setNumber-prob$probNum-$aux_file_id.$ext";
							#warn "pgFileName is $pgFileName filePath is $pgFileName gifSourceFile is $gifFileSource";
		$resource_object->path($sourceFilePath.".$ext");
		$resource_object->{path}->{is_complete}=1;
		

		$resource_object->{convert}->{needed}     = $convert_fileQ;
		$resource_object->{convert}->{from_path}  = $resource_object->path();
		$resource_object->{convert}->{from_type}  = $from_file_type;
		$resource_object->{convert}->{to_path}    = '';  #define later
		$resource_object->{convert}->{to_type}    = $to_file_type;

		# notice the resource uri is not yet defined -- we have to make the link first
	}

	if ($resource_object->{convert}->{needed} ) {	
		################################################################################
		# Create path to new .png file 
		# Create  new .png file 
		# We may not have permission to do this in the template directory
		# so we create the file in the course temp directory.
		################################################################################
    	$resource_object->create_unique_id();
    	my $unique_id                          = $resource_object->{unique_id};
		my $link                               = "$targetDirectory/$unique_id.png";                  
		my $targetFilePath                     = $self->surePathToTmpFile($link);
		$resource_object->{convert}->{to_path} = $targetFilePath;
		my $sourceFilePath = $resource_object->{convert}->{from_path};
		# conversion_command is imported into this subroutine from the config files.
		#$self->debug_message("cat $sourceFilePath | $conversion_command > $targetFilePath");
		my $returnCode = system "cat $sourceFilePath | $conversion_command > $targetFilePath";
		#$resource_object->debug_message( "FILE path $targetFilePath  created =", -e $targetFilePath );
		#$resource_object->debug_message( "return Code $returnCode from cat $sourceFilePath | $command > $targetFilePath");
		if ($returnCode or not -e $targetFilePath) {
			$resource_object->warning_message( "returnCode $returnCode: failed to convert $sourceFilePath to $targetFilePath using gif->png with $conversion_command: $!");
		}
	
	
		$resource_object->uri($resource_object->{convert}->{to_path});
		$resource_object->{uri}->{is_complete} =1;
		$resource_object->{uri}->{is_accessible} = (-r $resource_object->uri() );
	} else { # no conversion needed
		$resource_object->uri($resource_object->path());
		$resource_object->{uri}->{is_complete} =1;
		$resource_object->{uri}->{is_accessible} = (-r $resource_object->uri() );
	}
	
################################################################################
	# Return full path to image file  (resource_id)
################################################################################

	($resource_object->{uri}->{is_accessible} == 1 ) ? $resource_object->uri() : "";
	

}

################################################################################
# .gif FILES in TeX mode
################################################################################



#################################################################################
# support for pure latex output (as opposed to pdflatexoutput
#################################################################################
# 			
# 				# Since we're not creating PDF files; we're probably just using a plain
# 				# vanilla latex. Hence; we need EPS images.
# 
# 				################################################################################
# 				# This  statement used below is system dependent.
# 				# Notice that the range of colors is restricted when converting to postscript to keep the files small
# 				# "cat $gifSourceFile  | /usr/math/bin/giftopnm | /usr/math/bin/pnmtops -noturn > $adr_output"
# 				# "cat $gifSourceFile  | /usr/math/bin/giftopnm | /usr/math/bin/pnmdepth 1 | /usr/math/bin/pnmtops -noturn > $adr_output"
# 				################################################################################
# ################################################################################
# 		# Find path to .gif file
# ################################################################################
# ##################### Case1: we've got a full pathname to a file
# ##################### Case2: we assume the file is in the same directory as the problem source file
# 
# 				if ($aux_file_id =~  m|^$htmlDirectory|  or $aux_file_id =~  m|^$tempDirectory|)  {
# 					# To serve an eps file copy an eps version of the gif file to the subdirectory of eps/
# 					my $linkPath = $self->directoryFromPath($pgFileName);
# 					
# ################################################################################
# 		# Create path to new .EPS file
# ################################################################################
# 
# 					my $gifSourceFile = "$aux_file_id.gif";
# 					my $gifFileName = $self->fileFromPath($gifSourceFile);
# 					$adr_output = $self->surePathToTmpFile("$tempDirectory/eps/$studentLogin-$psvn-$gifFileName.eps") ;
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
# 					my $filePath = $self->directoryFromPath($pgFileName);
# 					my $gifSourceFile = "${templateDirectory}${filePath}$aux_file_id.gif";
# 					#print "content-type: text/plain \n\npgFileName = $pgFileName and aux_file_id =$aux_file_id<BR>";
# 					$adr_output = $self->surePathToTmpFile("eps/$studentLogin-$psvn-set$setNumber-prob$probNum-$aux_file_id.eps");
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
# 	$adr_output;




################################################################################
# Creating HTML output  using png file
################################################################################




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
	return undef unless $url =~/\S/;
	#FIXME -- check for other exploits of the system call
	#FIXME -- ALARM feature so that the response cannot be held up for too long.
	#FIXME doesn't seem to work with relative addresses.
	#FIXME  Can we get the machine name of the server?
	 $server_root_url=$self->envir("server_root_url");
	 $self->warning_message("check_url: server_root_url is not defined in site.conf") unless $server_root_url;
	 unless ($url =~ /^http/ ) {
	 	# $self->debug_message("check_url: augmenting url $url");
	 	$url = "$server_root_url/$url";
	 
	 }
	 my $check_url_command = $self->{envir}->{externalCheckUrl};
#	 $self->warning_message("check_url_command: $check_url_command -- externalCheckUrl is not properly defined in configuration file")
#	 	unless (-x $check_url_command );
	 my $response = `$check_url_command $url`; 
	 # $self->debug_message("check_url: response for url $url is  $response");
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
