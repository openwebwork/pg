################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2018 The WeBWorK Project, http://openwebwork.sf.net/
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

new 
  Create one alias object per question (and per PGcore object since there is a unique PGcore per question.)
  Check that information is intact
  Construct unique id stub seeds -- the id stub seed is for this PGalias object which is 
       attached to all the resource files (except equations) for this question.
  Maintain list of links to external resources

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
	$self->{problemSeed}         = $envir->{problemSeed};
	$self->{problemUUID}         = $envir->{problemUUID}//0;
	
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
				  $self->{problemSeed},
				  $self->{problemUUID},
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
sub make_resource_object {
	my $self = shift;
	my $aux_file_id =shift;
	my $ext = shift;
	my $resource = PGresource->new(
		$self,                    #parent alias of resource
		$aux_file_id,             # resource file name
		$ext,                     # resource type
		WARNING_messages => $self->{WARNING_messages},  #connect warning message channels
		DEBUG_messages   => $self->{DEBUG_messages},
	);	
	return $resource;
}


=head2 make_alias

This is the workhorse of the PGalias module.  It's front end is alias() in PG.pl.
 
make_alias magically takes a name of an external resource ( html file, png file, etc.)
and creates full directory addresses and uri's appropriate to the current displayMode.
It also does any necessary conversions behind the scenes. 

Returns the uri of the resource.

=cut

sub make_alias {
   	my $self = shift;   	
   	my $aux_file_id = shift;
	#$self->debug_message("make alias for file $aux_file_id");
	$self->warning_message( "Empty string used as input into the function alias") unless $aux_file_id;
	
	my $displayMode         = $self->{displayMode}; 
    
	# $adr_output is a url in HTML  mode
	# and a complete directory path in TEX mode.
	my $adr_output;
	my $ext='';
	
#######################################################################	
	# determine file type
	# determine display mode
	# dispatch	
#######################################################################
	# determine extension, if there is one
	# if extension exists use the value for $ext
	# files without extensions are flagged with errors.
	# The extension is retained as part of  aux_file_id 
	
	#$self->debug_message("This auxiliary file id is $aux_file_id" );
	if ($aux_file_id =~ m/\.([^\.]+)$/ ) {
		$ext = $1;
	} else {
		$self->warning_message( "The file name $aux_file_id did not have an extension.<BR> " .
		     "Every file name used as an argument to alias must have an extension.<BR> " .
		     "The permissable extensions are .jpg, .pdf, .gif, .png, .mpg, .mp4, .ogg, .webm and .html .<BR>");
		$ext  = undef;
		return undef;  #quit;
	}
	# $self->debug_message("This auxiliary file id is $aux_file_id of type $ext" );
	
###################################################################
# Create resource object
###################################################################
	#$self->debug_message("creating resource with id $aux_file_id");
	
	###################################################################
	# This section checks to see if a resource exists (in this question) 
	# for this particular aux_file_id.
	# If so, we simply return the appropriate uri for the file.
	# The displayMode will be the same throughout the processing of the .pg file
	# This effectively cache's auxiliary files within a single PG question.
	###################################################################
	unless ( defined $self->get_resource($aux_file_id) ) {
    	$self->add_resource($aux_file_id, 
    						$self->make_resource_object(
    							$aux_file_id,  # resource file name
    							$ext           # resource type
    						)
    	                   
    	);

    } else {
    	#$self->debug_message( "found existing resource_object $aux_file_id");
    	return $self->get_resource($aux_file_id)->uri() ; 
    }
	###################################################################

	
	if ($ext eq 'html' 		    ) {
	   $adr_output = $self->alias_for_html($aux_file_id,$ext)
	} elsif ($ext =~ /^(gif|jpg|png|svg|pdf|mp4|mpg|ogg|webm|css|js|nb|tgz)$/) {
		if ($displayMode =~ /^HTML/ or $displayMode eq 'PTX') {
			 $adr_output=$self->alias_for_html($aux_file_id, $ext);
		} elsif ($displayMode eq 'TeX') {
			################################################################################
			# .gif FILES in TeX mode
			################################################################################
            $adr_output=$self->alias_for_tex($aux_file_id, $ext);		
		} else {
			die "Error in alias: PGalias.pm: unrecognizable displayMode = $displayMode";
		}
# 	} elsif ($ext eq 'svg') {
# 		if ($displayMode =~/HTML/) {
# 			$self->warning_message("The image $aux_file_id of type $ext cannot yet be displayed in HTML mode");
# 			# svg images need an embed tag not an image tag -- need to modify image for this also
# 			# an alternative (not desirable) is to convert svg to png
# 		} elsif ($displayMode eq 'TeX') {
# 			$self->warning_message("The image $aux_file_id of type $ext cannot yet be displayed in TeX mode");
# 		} else {
# 			die "Error in alias: PGalias.pm: unrecognizable displayMode = $displayMode";
# 		}
	
	} else { # $ext is not recognized
		################################################################################
		# FILES  with unrecognized file extensions in any display modes
		################################################################################

		warn "Error in the macro alias. Alias does not understand how to process files with extension $ext.  
		      (Path to problem file is  ". $self->{envir}->{pgFileName}. ") ";
	}

	$self->warning_message( "The macro alias was unable to form a URL for the auxiliary file |$aux_file_id| used in this problem.") unless $adr_output;

	# $adr_output is a url in HTML  modes
	# and a complete path in TEX mode.
	my $resource_object = $self->get_resource($aux_file_id);
	# TEXT(alias() ) is expecting only a single item not an array
	# so the code immediately below for adding extra information to alias is a bad idea.
	#return (wantarray) ? ($adr_output, $resource_object): $adr_output;
	# Instead we'll implement a get_resource() command in PGcore and PG
	return($adr_output);
}



sub alias_for_html {
	my $self = shift; #handed alias object
	my $aux_file_id = shift; #handed the name of the resource object
	                         # case 1:  aux_file_id is complete or relative path to file
	                         # case 2:  aux_file_id is file name alone relative to the templates directory.
	my $ext = shift;
    #$self->debug_message("handling $aux_file_id of type $ext");
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
# retrieve PGresponse resource object
#######################
	my ($resource_uri  );
	my $resource_object = $self->get_resource($aux_file_id);
    # $self->debug_message( "\nresource for $aux_file_id is ", ref($resource_object), $resource_object );

##############################################
# Find complete path to the original files
##############################################

	# get the directories that might contain html files
	my $dirPath = '';
		if ($ext eq 'html') {
			$dirPath = 'htmlPath';
		} else {
			$dirPath = 'imagesPath';
		}
	my @aux_files_directories = @{$self->{envir}->{$dirPath}};

	# replace "." with the current pg question directory
	my $current_pg_directory =  $self->directoryFromPath($pgFileName);
	$current_pg_directory  = $self->{templateDirectory}."/".$current_pg_directory;
	@aux_files_directories = map { ($_ eq '.')?$current_pg_directory:$_ } @aux_files_directories;
	#$self->debug_message("search directories", @aux_files_directories);

	# Find complete path to the original file
	my $file_path;
	if ( $aux_file_id =~ /https?:/ ) { #external link_file
		$resource_object->uri($aux_file_id);           #no unique id is needed -- external link doc		
		$resource_object->{copy_link}->{type} = 'external';
		$resource_object->{uri}->{is_accessible} = $self->check_url($resource_object->uri());
		return $resource_object->uri; # external links need no further processing
	} elsif ( $aux_file_id =~ m|^/|) {
		$file_path = $aux_file_id;
	} else {
		$file_path = $self->find_file_in_directories($aux_file_id,\@aux_files_directories);
	}
	# $self->debug_message("file path is $file_path");

##################### Case1: we've got a full pathname to a file in either the temp directory or the htmlDirectory
##################### Case2: we assume the file is in the same directory as the problem source file
##################### Case3: the file could have an external url

##############################################
# store the complete path to the original file
# calculate the uri (which is a url suitable for the browser relative to the current site) 
# store the uri.
# record status of the resource
##############################################
	if ( $file_path   =~ m|^$tempDirectory| ) { #case: file is stored in the course temporary directory
		$resource_uri   = $file_path;
		$resource_uri   =~ s|$tempDirectory|$tempURL/|;
		$resource_object->uri($resource_uri);           #no unique id is needed -- public doc
		$resource_object->path($file_path);		
		$resource_object->{copy_link}->{type} = 'orig';
		$resource_object->{path}->{is_complete} = (-r $resource_object->path);		
	} elsif ($file_path =~ m|^$htmlDirectory| ) { #case: file is under the course html directory
		$resource_uri     = $file_path;
		$resource_uri     =~ s|$htmlDirectory|$htmlURL|;
		$resource_object->uri($resource_uri);			
		$resource_object->path($file_path);
		$resource_object->{copy_link}->{type} = 'orig';
		$resource_object->{path}->{is_complete}= (-r $resource_object->path);
	####################################################
	# one can add more public locations such as the site htdocs directory here in the elsif chain
	####################################################
	} else {#case: resource is in a  directory which is not public
			 #      most often this is the directory containing the .pg file
			 #      these files require a link to the temp Directory	
		# $self->debug_message("source file path ", $sourceFilePath);
		$resource_object->path($file_path);
		$resource_object->{copy_link}->{type} = 'link';
		$resource_object->{path}->{is_complete}=0;
		$resource_object->{uri}->{is_complete}=0;
		warn "$ext not defined" unless $ext;
		$resource_object->create_unique_id($ext);
		# notice the resource uri is not yet defined -- we have to make the link first
	}
		
##############################################
# Create links for objects of "link" type.
# between private directories such as myCourse/template
# and public directories (such as   wwtmp/courseName or myCourse/html
# The location of the links depends on the type and location of the file
##############################################
	# create_link_to_tmp_file()
	#input: resource object, ext, (html) (tempURL), 
	#return: uri
	if ( $resource_object->{copy_link}->{type} eq 'link') {
	    # this creates a link from the original file to an alias in the tmp/html directory
	    # and places information about the path and the uri in the PGresponse object $resource_object
	    my $subdir ='';
	    if ($ext eq 'html') {
	    	$subdir = 'html';
	    } else { 
	    	$subdir = 'images';
	    }
		$self->create_link_to_tmp_file(resource=>$resource_object, subdir=>$subdir);
	}
################################################################################
# Return full url to image file  (resource_id)
################################################################################

	# $self->debug_message("link created --alias_for_image_html: url is ".$resource_object->uri(). " check =".$self->check_url($resource_object->uri()) );
	$resource_object->uri();  # return the uri of the resource -- in this case the URL for the file in the temp directory
}
	

################################################################################
# alias for image in tex mode
################################################################################




sub alias_for_tex {
	my $self = shift; #handed alias object
	my $aux_file_id = shift; #handed the name of the resource object
	                         # case 1:  aux_file_id is complete or relative path to file
	                         # case 2:  aux_file_id is file name alone relative to the templates directory.
	my $ext = shift;
	
    my $from_file_type       = $ext ;
    my $to_file_type         = "png" ;           # needed for conversion cases
    
    my $convert_fileQ        = ($ext   eq   'gif' # gif files need to be converted
#                                   or $ext eq   'pdf' # other image types for tex
#                                   or $ext eq   'jpg'
#                                   or $ext eq   'svg'
#                                   or $ext eq   'html'
                                )? 1: 0   ;      # does this file need conversion
    
    my $link_fileQ =0;                                            # does this file need to be linked?
    my $targetDirectory      = ($ext eq 'html')?'html':'images' ; # subdirectory of tmp directory
        
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
# retrieve PGresponse resource object
#######################
	my ($resource_uri  );
	my $resource_object = $self->get_resource($aux_file_id);
    #warn ( "\nresource for $aux_file_id is ", ref($resource_object), $resource_object );

				        
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

	# get the directories that might contain html files
	my $dirPath = '';
		if ($ext eq 'html') {
			$dirPath = 'htmlPath';
		} else {
			$dirPath = 'imagesPath';
		}
	my @aux_files_directories = @{$self->{envir}->{$dirPath}};

	# replace "." with the current pg question directory
	my $current_pg_directory =  $self->directoryFromPath($pgFileName);
	$current_pg_directory  = $self->{templateDirectory}."/".$current_pg_directory;
	@aux_files_directories = map { ($_ eq '.')?$current_pg_directory:$_ } @aux_files_directories;
	#$self->debug_message("search directories", @aux_files_directories);

	# Find complete path to the original file
	my $file_path;
	if ( $aux_file_id =~ /https?:/ ) { # external link_file
		$resource_object->uri($aux_file_id);           #no unique id is needed -- external link doc		
		$resource_object->{copy_link}->{type} = 'external';
		$resource_object->{uri}->{is_accessible} = $self->check_url($resource_object->uri());
		return $resource_object->uri; # external links need no further processing
	} elsif ( $aux_file_id =~ m|^/|) {
		$file_path = $aux_file_id;
	} else {
		$file_path = $self->find_file_in_directories($aux_file_id,\@aux_files_directories);
	}
	#warn ("file path is $file_path");

##################### Case1: we've got a full pathname to a file in either the temp directory or the htmlDirectory
##################### Case2: we assume the file is in the same directory as the problem source file
##################### Case3: the file could have an external url

##############################################
# store the complete path to the original file
# calculate the uri (which is a url suitable for the browser relative to the current site) 
# store the uri.
# record status of the resource
##############################################

	if ( $file_path      =~ m|^$tempDirectory| ) { #case: file is stored in the course temporary directory

		my $sourceFilePath =  $file_path;	
		$resource_object->path($sourceFilePath);
		$resource_object->{path}->{is_complete}  = 1;
		#warn("tempDir   filePath ",$resource_object->path, "\n");
# Gif files always need to be converted to png files for inclusion in pdflatex documents.
		
		$resource_object->{convert}->{needed}    = $convert_fileQ;
		$resource_object->{convert}->{from_path} = $sourceFilePath;
		$resource_object->{convert}->{from_type} = $from_file_type;
		$resource_object->{convert}->{to_path}   = '';  #define later
		$resource_object->{convert}->{to_type}   = $to_file_type;
	} elsif ($file_path =~ m|^$htmlDirectory| ) { #case: file is under the course html directory

		my $sourceFilePath = $aux_file_id;
		$resource_object->path($sourceFilePath);
		$resource_object->{path}->{is_complete}=1;
				
		$resource_object->{convert}->{needed}    = $convert_fileQ;
		$resource_object->{convert}->{from_path} = $sourceFilePath;
		$resource_object->{convert}->{from_type} = $from_file_type;
		$resource_object->{convert}->{to_path}   = '';  #define later
		$resource_object->{convert}->{to_type}   = $to_file_type;
		#warn ("htmlDir   filePath ",$resource_object->path, "\n");
	
	} else {
		
		$resource_object->path($file_path);
		$resource_object->{path}->{is_complete}=(-r $resource_object->path);
		

		$resource_object->{convert}->{needed}     = $convert_fileQ;
		$resource_object->{convert}->{from_path}  = $resource_object->path();
		$resource_object->{convert}->{from_type}  = $from_file_type;
		$resource_object->{convert}->{to_path}    = '';  #define later
		$resource_object->{convert}->{to_type}    = $to_file_type;
		#warn ("templateDir   filePath ",$resource_object->path, "\n");
		# notice the resource uri is not yet defined -- we have to make the link first
	}
################################################################################
# Convert images to .png files if needed
################################################################################
    
	if ($resource_object->{convert}->{needed} ) {	#convert .gif to .png
	
		$self -> convert_file_to_png_for_tex(
	         resource => $resource_object,
	         targetDirectory => $targetDirectory
	    );	
	} else { # no conversion needed
		$resource_object->uri($resource_object->path());  #path and uri are the same in this case.
		$resource_object->{uri}->{is_complete} =1;
		$resource_object->{uri}->{is_accessible} = (-r $resource_object->uri() );
	}
################################################################################
# Don't need to create aliases in this case because nothing is being served over the web
################################################################################
	# Return full path to image file  (resource_id)
################################################################################
	#warn ("final   filePath ", $resource_object->uri(), "\n");
	#warn "file is a accessible ", $resource_object->{uri}->{is_accessible},"\n";
	# returns a file path 
	($resource_object->{uri}->{is_accessible} == 1 ) ? $resource_object->uri() : "";

}

############################################################################
# Utility for creating link from original file to alias in publically accessible temp directory
############################################################################
sub create_link_to_tmp_file {
	my $self = shift;
	my %args = @_;
	my $resource_object = $args{resource};
	# warn "resource_object =", ref($resource_object);
	my $unique_id       = $resource_object->{unique_id};
	my $ext       		= $resource_object->{type};
	my $subdir    		= $args{subdir};
	my $link           	= "$subdir/$unique_id";
	#################
	# construct resource uri
	#################
		my $resource_uri   = $self->{tempURL}; 
		$resource_uri      =~  s|/$||; #remove trailing slash, if any
		$resource_uri      = "$resource_uri/$link"; 
	################# 
	# insure that linkPath exists and all intermediate directories have been created
	#################
	my $linkPath       = $self->surePathToTmpFile($link);
	
	if (-e $resource_object->path( )) { 
	# if resource file exists
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
		if (symlink( $resource_object->path(), $linkPath)) {  #create the symlink
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
	# if the resource file doesn't exist
		my $message = ($resource_object->path())? " at |".$resource_object->path()."|" : " anywhere";
		$self->warning_message("The macro alias cannot find the file: |".
		         ($resource_object->fileName).'|'.$message);
		$resource_object->{path}->{is_accessible}= 0;
		$resource_object->{uri}->{is_accessible} = 0;
		# we should delete the resource object in this case?
	}
	
}


############################################################################
# Utility for converting .gif files to .png for tex
############################################################################


sub convert_file_to_png_for_tex {
	my $self = shift;
	my %args = @_;
	my $resource_object = $args{resource};
	my $targetDirectory = $args{targetDirectory};
	my $conversion_command   = $self->{externalGif2PngPath};
		################################################################################
		# Create path to new .png file 
		# Create  new .png file 
		# We may not have permission to do this in the template directory
		# so we create the file in the course temp directory.
		################################################################################
		my $ext = $resource_object->{type};
    	$resource_object->create_unique_id($ext);
    	my $unique_id                          = $resource_object->{unique_id};
    	$unique_id =~ s|\.[^/\.]*$|.png|;
		my $link                               = "$targetDirectory/$unique_id";                  
		my $targetFilePath                     = $self->surePathToTmpFile($link);
		$resource_object->{convert}->{to_path} = $targetFilePath;
		$self->debug_message("target  filePath ",$targetFilePath, "\n");
		my $sourceFilePath = $resource_object->{convert}->{from_path};
		$self->debug_message("convert   filePath ",$sourceFilePath, "\n");
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
    $filePath =~ s!^\.\.?/!$pwd/!;  # defined for PGloadFiles but not here
    #FIXME? where is $pwd defined? why did it want to replace ../ with current directory
    return $filePath if (-r $filePath);
  }
  return;  # no file found
}

sub find_file_in_directories {
	my $self = shift;
	my $file_name = shift;
	my $directories = shift; 
	my $file_path;
	foreach my $dir (@$directories) {
		$dir =~ s|/$||; # remove final / if present
		$file_path = "$dir/$file_name";
		return $file_path if (-r $file_path);
	}
	return; # no file found
}


# ^function check_url
# ^uses %envir
sub check_url {
	my $self = shift;
	my $url  = shift;
	my $OK_CONSTANT = "200 OK";
	return undef if $url =~ /;/;   # make sure we can't get a second command in the url
	return undef unless $url =~/\S/;
	#FIXME -- check for other exploits of the system call	#FIXME -- ALARM feature so that the response cannot be held up for too long.
	#ALARM: /opt/local/bin/lwp-request -d -t 40 -mHEAD ";  
	# the -t 40 means the call times out after 40 seconds.  
	# Set this alarm in site.conf
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
	 return ($response =~ /$OK_CONSTANT/) ? 1 : 0; 
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
