################################################################################
# WeBWorK Online Homework Delivery System
# Copyright © 2000-2007 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader: pg/lib/Applet.pm,v 1.1 2007/10/30 15:57:04 gage Exp $
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

Applet.pl - Provides code for inserting FlashApplets and JavaApplets into webwork problems

=head1 SYNPOSIS

  ###################################
  # Create  link to applet 
  ###################################
  my $appletName = "LineThruPointsWW";
  $applet = new FlashApplet(
     codebase   => findAppletCodebase("$appletName.swf"),
     appletName => $appletName,
     appletId   => $appletName,
     submitActionAlias => 'checkAnswer',
  );
  
  ###################################
  # Configure applet
  ###################################
  
  #xml data to set up the problem-rac
  $applet->xmlString(qq{<XML> 
  <point xval='$xval_1' yval='$yval_1' />
  <point xval='$xval_2' yval='$yval_2' />
  </XML>});
  
  
  ###################################
  # insert applet header material
  ###################################
  HEADER_TEXT($applet->insertHeader );
  
  ###################################
  # Text section
  #
  
  ###################################
  #insert applet into body
  ###################################
  TEXT( MODES(TeX=>'object code', HTML=>$applet->insertObject));


=head1 DESCRIPTION

This file provides an object to store in one place
all of the information needed to call an applet.

The object FlashApplet has defaults for inserting flash applets.

=over

=item *

=item *

=back

(not yet completed)

The module JavaApplet has defaults for inserting java applets.

The module Applet will store common code for the two types of applet.

=head1 USAGE

This file is included by listing it in the modules section of global.conf.

=cut



package Applet;


package FlashApplet;


use MIME::Base64 qw( encode_base64 decode_base64);

use constant DEFAULT_HEADER_TEXT =><<'END_HEADER_SCRIPT';
    <script language="javascript">AC_FL_RunContent = 0;</script>
    <script src="http://hosted2.webwork.rochester.edu/webwork2_files/applets/AC_RunActiveContent.js" language="javascript">
    </script>

 	
	<script language="JavaScript">
	
	var flash;
	function getFlashMovie(movieName) {
		  var isIE = navigator.appName.indexOf("Microsoft") != -1;
		  return (isIE) ? window[movieName] : window.document[movieName];
		  //return window.document[movieName];
	 }	
 
	
	function initialize() {
		  getFlashMovie("$appletId").$initializeAction("$base64_xmlString");
	}
	function submitAction() {
	  document.problemMainForm.$returnFieldName.value = getFlashMovie("$appletId").$submitAction();
	 }

    </script>
	
END_HEADER_SCRIPT


# 	<object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000" codebase="http://fpdownload.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=9,0,0,0" 
# 				   width="550" height="400" id="$appletId" align="middle">
# 			<param name="allowScriptAccess" value="sameDomain" />
# 			<param name="allowFullScreen" value="false" />
# 			<param name="movie" value="$appletName.swf" />
# 			<param name="quality" value="high" />
# 			<param name="bgcolor" value="#ffffcc" />	
# 			<embed src="$codebase/$appletName.swf" quality="high" bgcolor="#ffffcc" width="550" height="400" name="$appletName" 
# 				 align="middle"  id="$appletId",  
# 				 align="middle" allowScriptAccess="sameDomain" 
# 				 allowFullScreen="false" 
# 				type="application/x-shockwave-flash" pluginspage="http://www.macromedia.com/go/getflashplayer" />
# 				<param name="quality" value="high" /><param name="bgcolor" value="#ffffcc" />
# 		</object>

use constant DEFAULT_OBJECT_TEXT =><<'END_OBJECT_TEXT';
  <form></form>
  <object classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000"
             id="ExternalInterface" width="500" height="375"
             codebase="http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab">
         <param name="movie" value="$codebase/$appletName.swf" />
         <param name="quality" value="high" />
         <param name="bgcolor" value="#869ca7" />
         <param name="allowScriptAccess" value="sameDomain" />
         <embed src="$codebase/$appletName.swf" quality="high" bgcolor="#869ca7"
             width="550" height="400" name="$appletName" align="middle" id="$appletID"
             play="true" loop="false" quality="high" allowScriptAccess="sameDomain"
             type="application/x-shockwave-flash"
             pluginspage="http://www.macromedia.com/go/getflashplayer">
         </embed>

     </object>
END_OBJECT_TEXT


sub new {
	 my $class = shift; 
	 my $self = { 
		host =>'',
		port => '',
		path => '',
		appletName =>'',
		codebase=>'',
		appletId  =>'',
		params    =>undef,
		base64_xmlString => 'foobar',
		initializeActionAlias => 'setupProblem',
		submitActionAlias  => 'checkAnswer',
		returnFieldName    => 'receivedField',
		headerText   => DEFAULT_HEADER_TEXT(),
		objectText   => DEFAULT_OBJECT_TEXT(),
		@_,
	};
	bless $self, $class;
	#$self -> _initialize(@_);
	return $self;
}

sub  header {
	my $self = shift;
	if ($_[0] eq "reset") {  # $applet->header('reset');  erases default header text.
		$self->{headerText}='';
	} else {	
		$self->{headerText} .= join("",@_);  # $applet->header(new_text); concatenates new_text to existing header.
	}
    $self->{headerText};
}
sub  object {
	my $self = shift;
	if ($_[0] eq "reset") {
		$self->{objectText}='';
	} else {	
		$self->{objectText} .= join("",@_);
	}
    $self->{objectText};
}
sub params {
	my $self = shift;
	if (ref($_[0]) =~/HASH/) {
		$self->{params} = shift;
	} elsif ( $_[0] =~ '') {
		# do nothing (read)
	} else {
		warn "You must enter a reference to a hash for the parameter list";
	}
	$self->{params};
}
	
sub initializeActionAlias {
	my $self = shift;
	$self->{initializeActionAlias} = shift ||$self->{initializeActionAlias}; # replace the current contents if non-empty
    $self->{initializeActionAlias};
}

sub submitActionAlias {
	my $self = shift;
	$self->{submitActionAlias} = shift ||$self->{submitActionAlias}; # replace the current contents if non-empty
    $self->{submitActionAlias};
}
sub returnFieldName {
	my $self = shift;
	$self->{returnFieldName} = shift ||$self->{returnFieldName}; # replace the current contents if non-empty
    $self->{returnFieldName};
}
sub codebase {
	my $self = shift;
	$self->{codebase} = shift ||$self->{codebase}; # replace the current codebase if non-empty
    $self->{codebase};
}
sub appletName {
	my $self = shift;
	$self->{appletName} = shift ||$self->{appletName}; # replace the current appletName if non-empty
    $self->{appletName};
}
sub appletId {
	my $self = shift;
	$self->{appletId} = shift ||$self->{appletId}; # replace the current appletName if non-empty
    $self->{appletId};
}
sub xmlString {
	my $self = shift;
	my $str = shift;
	$self->{base64_xmlString} =  encode_base64($str)   ||$self->{base64_xmlString}; # replace the current string if non-empty
	$self->{base64_xmlString} =~ s/\n//g;
    decode_base64($self->{base64_xmlString});
}

sub base64_xmlString{
	my $self = shift;
	$self->{base64_xmlString} = shift ||$self->{base64_xmlString}; # replace the current string if non-empty
    $self->{base64_xmlString};
}

#FIXME
# need to be able to adjust header material

sub insertHeader {
    my $self = shift;
    my $codebase = $self->{codebase};
    my $appletId = $self->{appletId};
    my $appletName = $self->{appletName};
    my $base64_xmlString = $self->{base64_xmlString};
    my $initializeAction = $self->{initializeActionAlias};
    my $submitAction = $self->{submitActionAlias};
    my $returnFieldName= $self->{returnFieldName};
    my $headerText = $self->header();
    $headerText =~ s/(\$\w+)/$1/gee;   # interpolate variables p17 of Cookbook
  
    return $headerText;


}


# <script language="javascript">
# 	if (AC_FL_RunContent == 0) {
# 		alert("This page requires AC_RunActiveContent.js.");
# 	} else {
# 		AC_FL_RunContent(
# 			'codebase', 'http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=9,0,0,0',
# 			'width', '100%',
# 			'height', '100%',
# 			'src', 'http://$codebase/$appletName',
# 			'quality', 'high',
# 			'pluginspage', 'http://www.macromedia.com/go/getflashplayer',
# 			'align', 'middle',
# 			'play', 'true',
# 			'loop', 'true',
# 			'scale', 'showall',
# 			'wmode', 'window',
# 			'devicefont', 'false',
# 			'id', '$appletId',
# 			'bgcolor', '#ffffcc',
# 			'name', '$appletName',
# 			'menu', 'true',
# 			'allowFullScreen', 'false',
# 			'allowScriptAccess','sameDomain',
# 			'movie', '$appletName',
# 			'salign', ''
# 			); //end AC code
# 	}
# </script>
sub insertObject {
    my $self = shift;
    my $codebase = $self->{codebase};
    my $appletId = $self->{appletId};
    my $appletName = $self->{appletName};
    $codebase = findAppletCodebase("$appletName.swf") unless $codebase;
    $objectText = $self->{objectText};
    $objectText =~ s/(\$\w+)/$1/gee;
    return $objectText;
}

sub initialize  {
    my $self = shift;
	return q{	
		<script>
			initialize();
			// this should really be done in the <body> tag 
		</script>
	};

}

1;