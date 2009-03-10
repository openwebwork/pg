################################################################################
# WeBWorK Online Homework Delivery System
# Copyright © 2000-2007 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader: pg/lib/Applet.pm,v 1.17 2009/02/19 16:35:26 gage Exp $
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
     # can be replaced by $applet =FlashApplet() when using AppletObjects.pl
     codebase   => findAppletCodebase("$appletName.swf"),
     appletName => $appletName,
     appletId   => $appletName,
     submitActionAlias => 'checkAnswer',
  );
  
  ###################################
  # Configure applet
  ###################################
  
  #xml data to set up the problem-rac
  $applet->config(qq{<XML> 
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

The module Applet stores common code for the two types of applet.

=head1 USAGE

These modules are activate by listing it in the modules section of global.conf and rebooting the server.
The companion file to this one is macros/AppletObjects.pl

qw(Applet FlashApplet JavaApplet)

=cut



package Applet;

use URI::Escape;



use MIME::Base64 qw( encode_base64 decode_base64);


=head2 Default javaScript functions placed in header

=pod

These functions are automatically defined for use for 
any javaScript placed in the text of a PG question.

    getApplet(appletName)  -- finds the applet path in the DOM

    submitAction()            -- calls the submit action of the applets

    initializeWWquestion()    -- calls the initialize action of the applets

    getQE(name)               -- gets an HTML element of the question by name
                                 or by id.  Be sure to keep all names and ids
                                 unique within a given PG question.

    getQuestionElement(name)  -- long form of getQE(name)

    listQuestionElements()    -- for discovering the names of inputs in the 
                                 PG question.  An alert dialog will list all
                                 of the elements.
      Usage: Place this at the END of the question, just before END_DOCUMENT():

                TEXT(qq!<script> listQuestionElements() </script>!);
                ENDDOCUMENT();
             to obtain a list of all of the HTML elements in the question
    
    ----------------------------------------------------------------------------
    
    
    List of  accessor methods made available by the FlashApplet class:
        Usage:  $current_value = $applet->method(new_value or empty)
        These can also be set when creating the class -- for exampe:
             $applet = new FlashApplet( 
                       # can be replaced by $applet =FlashApplet() when using AppletObjects.pl
                       codebase   => findAppletCodebase("$appletName.swf"),
                       appletName => $appletName,
                       appletId   => $appletName,
                       submitActionAlias => 'checkAnswer',
            );


        appletId         for simplicity and reliability appletId and appletName are always the same
        appletName
        archive      the name of the .jar file containing the applet code
        code         the name of the applet code in the .jar archive
        codebase     a prefix url used to find the archive and the applet itself

        height       rectangle alloted in the html page for displaying the applet

        params       an anonymous array containing name/value pairs 
                     to configure the applet [name =>'value, ...]

        header       stores the text to be added to the header section of the html page
        object       stores the text which places the applet on the html page

        debug        in debug mode several alerts mark progress through the procedure of calling the applet

        config       configuration are those customizable attributes of the applet which don't 
                     change as it is used.  When stored in hidden answer fields 
                     it is usually stored in base64 encoded format.
        base64_config base64 encode version of the contents of config

        configAlias  (default: setConfig ) names the applet command called with the contents of $self->config
                     to configure the applet.  The parameters are passed to the applet in plain text using <xml>
                     The outer tags must be   <xml> .....   </xml>
        setConfigAlias (default: setConfig) -- a synonym for configAlias
        getConfigAlias (default: getConfig) -- retrieves the configuration from the applet.  This is used
                     mainly for debugging.  In principal the configuration remains the same for a given instance
                     of the applet -- i.e. for the homework question for a single student.  The state however
                     will change depending on the interactions between the student and the applet.
        initialState  the state consists of those customizable attributes of the applet which change
                     as the applet is used by the student.  It is stored by the calling .pg question so that 
                     when revisiting the question the applet will be restored to the same state it was left in when the question was last 
                     viewed.

        getStateAlias  (default: getState) alias for command called to read the current state of the applet.
                       The state is passed in plain text xml format with outer tags: <xml>....</xml>
        setStateAlias  (default: setState) alias for the command called to reset the  state of the applet.
                       The state is passed in plain text in xml format with outer tags: <xml>....</xml>

        base64_state   returns the base64 encoded version of the state stored in the applet object.

        initializeActionAlias  -- (default: initializeAction) the name of the javaScript subroutine called to initialize the applet (some overlap with config/ and setState
        submitActionAlias      -- (default: submitAction)the name of the javaScript subroutine called when the submit button of the
                                  .pg question is pressed.
        answerBox              -- name of answer box to return answer to: default defaultAnswerBox 
        getAnswer              -- (formerly sendData) get student answer from applet and place in answerBox
        returnFieldName        -- (deprecated) synonmym for answerBox


=cut

=head4 More details 

There are three different "images" of the applet.  The first is the java or flash applet itself.  The object that actually does the work.
The second is a perl image of the applet -- henceforth the perlApplet -- which is configured in the .pg file and allows a WeBWorK question
to communicate with the applet.  The third image is a javaScript image of the applet -- henceforth the jsApplet which is a mirror of the perlApplet
but is available to the javaScript code setup and executed in the virtual HTML page defined by the .pg file of the WeBWorK question. One can think of 
the jsApplet as a runtime version of the perlApplet since it can be accessed and modified after the virtual HTML page has been created by 
the PG rendering process.

The perlApplet is initialized by   $newApplet = new flashApplet( appletName=>'myApplet',..... ); The jsApplet is automatically defined in 
ww_applet_list["myApplet"] by copying the instance variables of $newApplet to a corresponding javaScript object.  So  $newApplet->{appletName}
corresponds to ww_applet_list["myApplet"].appletName.  (This paragraph is not yet fully implemented :-().

Currently all messages read by the applet are xml text.  If some of the code needs to be printed in the HTML header than it is converted
to a base64 constant and then converted back to text form when it is read by an javaScript subroutine.

=cut

=head4 Requirements for applets

The following methods are desirable in an applet that preserves state in a WW question.  None of them are required.

	setState(str)   (default: setXML)  
	                   -- set the current state of the applet from an xml string
	                   -- should be able to accept an empty string or a string of
	                      the form <XML>.....</XML> without creating errors
	                   -- can be designed to receive other forms of input if it is 
	                      coordinated with the WW question.
	getState()      (default: getXML)
	     	           -- return the current state of the applet in an xml string.
	                   -- an empty string or a string of the form <XML>.....</XML> 
	                      are the standard responses.
	                   -- can be designed to return other strings if it is 
	                      coordinated with the WW question.
	setConfig(str) (default: setConfig) 
	                   -- If the applet allows configuration this configures the applet
	                      from an xml string
      	               -- should be able to accept an empty string or a string of the 
      	                  form <XML>.....</XML> without creating errors
	                   -- can be designed to receive other forms of input if it is 
	                      coordinated with the WW question.
    getConfig      (default: getConfig) 
	                   -- This returns a string defining the configuration of the 
	                      applet in an xml string
  	                   -- an empty string or a string of the form <XML>.....</XML> 
  	                      are the standard responses.
	                   -- can be designed to return other strings if it is 
	                      coordinated with the WW question.
	                   -- this method is used for debugging to ensure that 
	                      the configuration was set as expected.
	getAnswer      (default: getAnswer)
	                   -- Returns a string (usually NOT xml) which is the 
	                      response that the student is submitting to answer
	                      the WW question.


=cut

sub new {
	 my $class = shift; 
	 my $self = { 
		appletName =>'',
		code=>'',
		codebase=>'',
#		appletId  =>'',   #always use identical applet Id's and applet Names
		params    =>undef,
		width     => 550,
		height    => 400,
		bgcolor   => "#869ca7",
		base64_state       =>  undef,     # this is a state to use for initializing the first occurence of the question.
		base64_config      =>  undef,     # this is the initial (and final?) configuration
#		configuration      => '',         # configuration defining the applet
		initialState       => '',         # initial state.  (I'm considering storing everything as ascii and converting on the fly to base64 when needed.)
		getStateAlias      =>  'getXML',
		setStateAlias      =>  'setXML',
		configAlias        =>  '',
		getConfigAlias     =>  'getConfig',
		setConfigAlias     =>  'setConfig',
		initializeActionAlias => 'setXML',
		submitActionAlias  =>  'getXML',
		submitActionScript  =>  '',        # script executed on submitting the WW question
		answerBox          =>  'answerBox',
		headerText         =>  DEFAULT_HEADER_TEXT(),
		objectText         => '',
		debug              => 0,
		@_,
	};
	bless $self, $class;
	$self->initialState('<xml></xml>');
	if ($self->{configAlias}) { # backward compatibility
		warn "use setConfigAlias instead of configAlias";
		$self->{configAlias}='';
	}
	$self->config('<xml></xml>');
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
	} elsif ( !defined($_[0]) or $_[0] =~ '') {
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
sub submitActionScript {
	my $self = shift;
	$self->{submitActionScript} = shift ||$self->{submitActionScript}; # replace the current contents if non-empty
    $self->{submitActionScript};
}
sub getStateAlias {
	my $self = shift;
	$self->{getStateAlias} = shift ||$self->{getStateAlias}; # replace the current contents if non-empty
    $self->{getStateAlias};
}

sub setStateAlias {
	my $self = shift;
	$self->{setStateAlias} = shift ||$self->{setStateAlias}; # replace the current contents if non-empty
    $self->{setStateAlias};
}
sub configAlias {
	my $self = shift;
	$self->{setConfigAlias} = shift ||$self->{setConfigAlias}; # replace the current contents if non-empty
    $self->{setConfigAlias};
}
sub setConfigAlias {
	my $self = shift;
	$self->{setConfigAlias} = shift ||$self->{setConfigAlias}; # replace the current contents if non-empty
    $self->{setConfigAlias};
}
sub getConfigAlias {
	my $self = shift;
	$self->{getConfigAlias} = shift ||$self->{getConfigAlias}; # replace the current contents if non-empty
    $self->{getConfigAlias};
}

sub answerBoxName {
	my $self = shift;
	$self->{answerBox} = shift ||$self->{answerBox}; # replace the current contents if non-empty
    $self->{answerBox};
}
sub codebase {
	my $self = shift;
	$self->{codebase} = shift ||$self->{codebase}; # replace the current codebase if non-empty
    $self->{codebase};
}
sub code {
	my $self = shift;
	$self->{code} = shift ||$self->{code}; # replace the current code if non-empty
    $self->{code};
}
sub height {
	my $self = shift;
	$self->{height} = shift ||$self->{height}; # replace the current height if non-empty
    $self->{height};
}
sub width {
	my $self = shift;
	$self->{width} = shift ||$self->{width}; # replace the current width if non-empty
    $self->{width};
}
sub bgcolor {
	my $self = shift;
	$self->{bgcolor} = shift ||$self->{bgcolor}; # replace the current background color if non-empty
    $self->{bgcolor};
}
sub archive {
	my $self = shift;
	$self->{archive} = shift ||$self->{archive}; # replace the current archive if non-empty
    $self->{archive};
}
sub appletName {
	my $self = shift;
	$self->{appletName} = shift ||$self->{appletName}; # replace the current appletName if non-empty
    $self->{appletName};
}
sub debug {
	my $self = shift;
	my $new_flag = shift;
	$self->{debug} = $new_flag if defined($new_flag);
	$self->{debug};
}
sub appletId {  
	appletName(@_);
}

sub initialState {
	my $self = shift;
	my $str = shift;
	$self->{initialState} = $str   ||$self->{initialState}; # replace the current string if non-empty
    $self->{initialState};
}

sub config {
	my $self = shift;
	my $str = shift;
	$self->{base64_config} =  encode_base64($str)   || $self->{base64_config}; # replace the current string if non-empty
	$self->{base64_config} =~ s/\n//g;
    decode_base64($self->{base64_config});
}
#######################
# soon to be deprecated?
#######################
sub state {
	my $self = shift;
	my $str = shift;
	$self->{base64_state} =  encode_base64($str)   ||$self->{base64_state}; # replace the current string if non-empty
	$self->{base64_state} =~ s/\n//g;
    decode_base64($self->{base64_state});
}
sub base64_state{
	my $self = shift;
	$self->{base64_state} = shift ||$self->{base64_state}; # replace the current string if non-empty
    $self->{base64_state};
}

sub base64_config {
	my $self = shift;
	$self->{base64_config} = shift ||$self->{base64_config}; # replace the current string if non-empty
	$self->{base64_config} =$self->{base64_config};
    $self->{base64_config};
}

sub returnFieldName {
	my $self = shift;
    warn "use  answerBoxName  instead of returnFieldName";
}
sub answerBox {
	my $self = shift;
    warn "use  answerBoxName  instead of AnswerBox";
}
#########################
#FIXME
# need to be able to adjust header material

sub insertHeader {
    my $self = shift;

    my $codebase              =  $self->codebase;
    my $appletId              =  $self->appletId;
    my $appletName            =  $self->appletName;
    my $base64_initialState   = $self->base64_state;
    my $initializeAction      =  $self->initializeActionAlias;
    my $submitActionAlias     =  $self->submitActionAlias;
    my $submitActionScript    = $self->submitActionScript;
    my $setStateAlias         =  $self->setStateAlias;
    my $getStateAlias         =  $self->getStateAlias;

    my $setConfigAlias        =  $self->setConfigAlias;
    my $getConfigAlias        =  $self->getConfigAlias;
    my $base64_config         =  $self->base64_config;
    my $debugMode             =  ($self->debug) ? "1": "0";
    my $returnFieldName       =  $self->{returnFieldName};
    my $answerBox             =  $self->{answerBox};
    my $headerText            =  $self->header();
    
    
    $submitActionScript =~ s/"/\\"/g;    # escape quotes for ActionScript
                                         # other variables should not have quotes.
                                         
    $submitActionScript =~ s/\n/ /g;     # replace returns with spaces -- returns in the wrong spot can cause trouble with javaScript
    $submitActionScript =~ s/\r/ /g;     # replace returns with spaces -- returns can cause trouble
    
    $headerText =~ s/(\$\w+)/$1/gee;   # interpolate variables p17 of Cookbook
  
    return $headerText;


}

sub insertObject {
    my $self       = shift;
    my $code       = $self->{code};
    my $codebase   = $self->{codebase};
    my $appletId   = $self->{appletName};
    my $appletName = $self->{appletName};
    my $archive    = $self->{archive};
    my $width      = $self->{width};
    my $height     = $self->{height};
    my $applet_bgcolor = $self->{bgcolor};
    my $javaParameters = '';
    my $flashParameters = '';
    my %param_hash = %{$self->params()};
    foreach my $key (keys %param_hash) {
    	$javaParameters .= qq!<param name ="$key"  value = "$param_hash{$key}">\n!;
    	$flashParameters .= uri_escape($key).'='.uri_escape($param_hash{$key}).'&';
    }
    $flashParameters =~ s/\&$//;    # trim last &

   
    $objectText = $self->{objectText};
    $objectText =~ s/(\$\w+)/$1/gee;
    return $objectText;
}
# sub initialize  {
#     my $self = shift;
# 	return q{	
# 		<script>
# 			initializeAllApplets();
# 			// this should really be done in the <body> tag 
# 		</script>
# 	};
# 
# }
########################################################
# HEADER material for one flash or java applet
########################################################

use constant DEFAULT_HEADER_TEXT =><<'END_HEADER_SCRIPT';
  	<script src="/webwork2_files/js/Base64.js" language="javascript">
    </script> 	
  	<script src="/webwork2_files/js/ww_applet_support.js" language="javascript">
  	    //upload functions stored in /opt/webwork/webwork2/htdocs/js ...
  	    
     </script>
	<script language="JavaScript">
	
	// set debug mode for this applet
		set_debug($debugMode);
		
   	//////////////////////////////////////////////////////////
	//TEST code
	//
    // 
    //////////////////////////////////////////////////////////
   
    ww_applet_list["$appletName"] = new ww_applet("$appletName");
    
    
	ww_applet_list["$appletName"].code = "$code";
	ww_applet_list["$appletName"].codebase = "$codebase";
    ww_applet_list["$appletName"].appletID = "$appletID";
	ww_applet_list["$appletName"].base64_state = "$base64_initializationState";
	ww_applet_list["$appletName"].base64_config = "$base64_config";
	ww_applet_list["$appletName"].getStateAlias = "$getStateAlias";
	ww_applet_list["$appletName"].setStateAlias = "$setStateAlias";
	ww_applet_list["$appletName"].setConfigAlias   = "$setConfigAlias";
	ww_applet_list["$appletName"].getConfigAlias   = "$getConfigAlias";
	ww_applet_list["$appletName"].initializeActionAlias = "$initializeAction";
	ww_applet_list["$appletName"].submitActionAlias = "$submitActionAlias";
	ww_applet_list["$appletName"].submitActionScript = "$submitActionScript";
	ww_applet_list["$appletName"].answerBox = "$answerBox";
	ww_applet_list["$appletName"].debug = "$debugMode";	

    </script>
	
END_HEADER_SCRIPT

package FlashApplet;
@ISA = qw(Applet);


=head2 Insertion HTML code for FlashApplet

=pod

The secret to making this applet work with IE in addition to normal browsers
is the addition of the C(<form></form>) construct just before the object.

For some reason IE has trouble locating a flash object which is contained
within a form.  Adding this second blank form with the larger problemMainForm
seems to solve the problem.  

This follows method2 of the advice given in url(http://kb.adobe.com/selfservice/viewContent.do?externalId=kb400730&sliceId=2)
Method1 and methods involving SWFObject(Geoff Stearns) and SWFFormFix (Steve Kamerman) have yet to be fully investigated:
http://devel.teratechnologies.net/swfformfix/swfobject_swfformfix_source.js
http://www.teratechnologies.net/stevekamerman/index.php?m=01&y=07&entry=entry070101-033933

		use constant DEFAULT_OBJECT_TEXT =><<'END_OBJECT_TEXT';
		  <form></form>
		  <object classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000"
					 id="$appletName" width="500" height="375"
					 codebase="http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab">
				 <param name="movie" value="$codebase/$appletName.swf" />
				 <param name="quality" value="high" />
				 <param name="bgcolor" value="$applet_bgcolor" />
				 <param name="allowScriptAccess" value="sameDomain" />
				 <embed src="$codebase/$appletName.swf" quality="high" bgcolor="$applet_bgcolor"
					 width="$width" height="$height" name="$appletName" align="middle" id="$appletName"
					 play="true" loop="false" quality="high" allowScriptAccess="sameDomain"
					 type="application/x-shockwave-flash"
					 pluginspage="http://www.macromedia.com/go/getflashplayer">
				 </embed>
		
			 </object>
		END_OBJECT_TEXT


=cut

use constant DEFAULT_OBJECT_TEXT =><<'END_OBJECT_TEXT';
  <form></form>
  <object classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000"
             id="$appletName" width="500" height="375"
             codebase="http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab">
         <param name="movie" value="$codebase/$appletName.swf" />
         <param name="quality" value="high" />
         <param name="bgcolor" value="$applet_bgcolor" />
         <param name="allowScriptAccess" value="sameDomain" />
         <param name="FlashVars" value="$flashParameters"/>
         <embed src="$codebase/$appletName.swf" quality="high" bgcolor="$applet_bgcolor"
             width="$width" height="$height" name="$appletName" align="middle" id="$appletName"
             play="true" loop="false" quality="high" allowScriptAccess="sameDomain"
             type="application/x-shockwave-flash"
             pluginspage="http://www.macromedia.com/go/getflashplayer"
             FlashVars="$flashParameters">
         </embed>

     </object>
END_OBJECT_TEXT

sub new {
    my $class = shift;
	$class -> SUPER::new(	objectText   => DEFAULT_OBJECT_TEXT(),
		        			@_
	);

}


package JavaApplet;
@ISA = qw(Applet);

=head2 Insertion HTML code for JavaApplet

=pod

The secret to making this applet work with IE in addition to normal browsers
is the addition of the C(<form></form>) construct just before the object.

For some reason IE has trouble locating a flash object which is contained
within a form.  Adding this second blank form with the larger problemMainForm
seems to solve the problem.  

This follows method2 of the advice given in url(http://kb.adobe.com/selfservice/viewContent.do?externalId=kb400730&sliceId=2)
Method1 and methods involving SWFObject(Geoff Stearns) and SWFFormFix (Steve Kamerman) have yet to be fully investigated:
http://devel.teratechnologies.net/swfformfix/swfobject_swfformfix_source.js
http://www.teratechnologies.net/stevekamerman/index.php?m=01&y=07&entry=entry070101-033933

		use constant DEFAULT_OBJECT_TEXT =><<'END_OBJECT_TEXT';
		  <form></form>
		 <applet
			code     = "$code"
			codebase = "$codebase"
			archive  = "$archive"
			name     = "$appletName"
			id       = "$appletName"
			width    = "$width"
			height   = "$height"
			MAYSCRIPT
		 >
		  $javaParameters
		 </applet>
		END_OBJECT_TEXT

=cut

use constant DEFAULT_OBJECT_TEXT =><<'END_OBJECT_TEXT';
  <form></form>
 <applet
 	code     = "$code"
 	codebase = "$codebase"
 	archive  = "$archive"
 	name     = "$appletName"
    id       = "$appletName"
    width    = "$width"
    height   = "$height"
    bgcolor  = "$applet_bgcolor"
    MAYSCRIPT
 >
  $javaParameters
  
  Sorry, the Applet could not be started. Please make sure that
Java 1.4.2 (or later) is installed and activated. 
(<a href="http://java.sun.com/getjava">click here to install Java now</a>)
 </applet>
END_OBJECT_TEXT

sub new {
    my $class = shift;
	$class -> SUPER::new(	objectText   => DEFAULT_OBJECT_TEXT(),
		        			@_
	);

}



1;