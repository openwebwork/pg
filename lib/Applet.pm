################################################################################
# WeBWorK Online Homework Delivery System
# Copyright © 2000-2007 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader: pg/lib/Applet.pm,v 1.14 2009/01/28 17:07:08 gage Exp $
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

    initializeWWquestion()        -- calls the initialize action of the applets

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

        configAlias  (default: config ) names the applet command called with the contents of $self->config
                     to configure the applet.  The parameters are passed to the applet in plain text using <xml>
                     The outer tags must be   <xml> .....   </xml>
        state        state consists of those customizable attributes of the applet which change
                     as the applet is used.  It is stored by the calling .pg question so that 
                     when revisiting the question the applet
                     will be restored to the same state it was left in when the question was last 
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
		base64_state       =>  undef,     # this is an state to use for initializing the first occurence of the question.
		base64_config      =>  undef,     # this is the initial (and final?) configuration
		getStateAlias      =>  'getXML',
		setStateAlias      =>  'setXML',
		configAlias        =>  'config',
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
	$self->state('<xml></xml>');
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
	$self->{configAlias} = shift ||$self->{configAlias}; # replace the current contents if non-empty
    $self->{configAlias};
}
sub returnFieldName {
	my $self = shift;
	$self->{answerBox} = shift ||$self->{answerBox}; # replace the current contents if non-empty
    $self->{answerBox};
}
sub answerBox {
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
sub config {
	my $self = shift;
	my $str = shift;
	$self->{base64_config} =  encode_base64($str)   || $self->{base64_config}; # replace the current string if non-empty
	$self->{base64_config} =~ s/\n//g;
    decode_base64($self->{base64_config});
}
sub base64_config {
	my $self = shift;
	$self->{base64_config} = shift ||$self->{base64_config}; # replace the current string if non-empty
	$self->{base64_config} =$self->{base64_config};
    $self->{base64_config};
}
#FIXME
# need to be able to adjust header material

sub insertHeader {
    my $self = shift;
    my $codebase         =  $self->codebase;
    my $appletId         =  $self->appletId;
    my $appletName       =  $self->appletName;
    my $base64_initialState     = $self->base64_state;
    my $initializeAction =  $self->initializeActionAlias;
    my $submitAction     =  $self->submitActionAlias;
    my $submitActionScript = $self->submitActionScript;
    my $setState         =  $self->setStateAlias;
    my $getState         =  $self->getStateAlias;
    my $config           =  $self->configAlias;
    my $base64_config    =  $self->base64_config;
    my $debugMode        =  ($self->debug) ? "1": "0";
    my $returnFieldName  =  $self->{returnFieldName};
    my $answerBox        =  $self->{answerBox};
    my $headerText       =  $self->header();
    
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
  	<script src="/webwork2_files/js/ww_applet_support.js">
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
	ww_applet_list["$appletName"].getStateAlias = "$getState";
	ww_applet_list["$appletName"].setStateAlias = "$setState";
	ww_applet_list["$appletName"].configAlias   = "$config";
	ww_applet_list["$appletName"].initializeActionAlias = "$initializeAction";
	ww_applet_list["$appletName"].submitActionAlias = "$submitAction";
	ww_applet_list["$appletName"].submitActionScript = "$submitActionScript";
	ww_applet_list["$appletName"].answerBox = "$answerBox";
	ww_applet_list["$appletName"].debug = "$debugMode";	

	
	//////////////////////////////////////////////////////////
	//CONFIGURATIONS
	//
    // configurations are "permanent"
    //////////////////////////////////////////////////////////
    
//     applet_config_list["$appletName"]   = function() {
//         debug_add("applet_config_list:\n attempt to configure $appletName . $config ( $base64_config ) if config function is defined: " 
//         );
//     	try {  
//     	    if (( typeof(getApplet("$appletName").$config)  == "function" ) ) {
//     	        debug_add("CONFIGURE $appletName");
//     			getApplet("$appletName").$config(Base64.decode("$base64_config"));
//     		}
//     	} catch(e) {
//     		alert("Error executing configuration command $config for $appletName: " + e );
//     	}
//     }
//     ////////////////////////////////////////////////////////////
//     //
//     //STATE:
//     // state can vary as the applet is manipulated -- it is reset from the questions _state values
//     //
//     //////////////////////////////////////////////////////////
//     
//     applet_setState_list["$appletName"] = function(state) {  
// 		debug_add("Begin setState for applet $appletName");
// 		debug_add("Obtain state from $appletName"+"_state");
// 		state =  state || getQE("$appletName"+"_state").value;
// 		if ( base64Q(state) ) { 
// 			state=Base64.decode(state);
// 		}
// 		if (state.match(/<xml/i) || state.match(/<?xml/i) ) {  // if state starts with <?xml
// 		
// 			debug_add("applet_setState_list: \n set (decoded) state for $appletName to " + 
// 					 state +"\nfunction type is " +typeof(getApplet("$appletName").$setState)
// 			);
// 			try {
// 			if (( typeof(getApplet("$appletName").$setState)  =="function" ) ) {
// 				debug_add("setState for $appletName");
// 				getApplet("$appletName").$setState( state );
// 			}
// 			} catch(e) {
// 			alert("Error in setting state of $appletName using command $setState : " + e );
// 			}
// 		} else if (debug) {
// 			alert("new state was empty string or did not begin with <xml-- state was not reset");
// 		}
// 	};
// 	applet_getState_list["$appletName"] = function () {  
// 		debug_add("get current state for applet $appletName and store it in $appletName"+"_state");
// 		var applet = getApplet("$appletName");
// 		try {
// 			if (( typeof(applet.$getState)  == "function" ) ) {  // there may be no state function
// 				state  = applet.$getState();                     // get state in xml format
// 				debug_add("state has type " + typeof(state));
// 				state  = String(state);                          // geogebra returned an object type instead of a string type
// 				debug_add("state converted to type " + typeof(state));
// 			}   
// 			
// 			if (!debug) {
// 				state = Base64.encode(state);	
// 			};   // replace state by encoded version unless in debug mode
// 
// 			debug_add("state is "+state);                  // this should still be in plain text
// 			getQE("$appletName"+"_state").value = state;   //place state in input item (debug: textarea, otherwise: hidden)
// 		} catch (e) {
// 			alert("Error in getting state for $appletName " + e );
// 		}
//     };
//     
//     ////////////////////////////////////////////////////////////
//     //
//     //INITIALIZE
//     //
//     ////////////////////////////////////////////////////////////
//     
// 
//     applet_checkLoaded_list["$appletName"] = function() { // this function returns 0 unless:
//                                                       // applet has already been flagged as ready in applet_isReady_list
//                                                       // applet.config is defined  (or alias for .config)
//                                                       // applet.setState is defined
//                                                       // applet.isActive is defined
//                                                       // applet reported that it is loaded by calling loadQ()
//     	var ready = 0;
//     	var applet = getApplet("$appletName");
//     	    if (!debug && applet_isReady_list["$appletName"]) {return(1)}; // memorize readiness in non-debug mode
//     		if ( typeof(applet.$config) == "function") {
//     		    debug_add( "applet.config is " + typeof(applet.$config) );
//     			ready = 1;
//     		}
//     		if( typeof(applet.$getState) == "function") {
//     		    debug_add( "applet.getState is " + typeof(applet.$getState) );
//     			ready =1;
//     		} 
//     		if (typeof(applet.isActive) == "function" && applet.isActive ) {
//     			debug_add( "applet.isActive is " + typeof(applet.isActive) );
//     			ready =1;
//     		} 
//     		if (typeof(applet_reportsLoaded_list["$appletName"]) !="undefined" && applet_reportsLoaded_list["$appletName"] != 0 ) {
//     			debug_add( "applet reports that it is loaded " + applet_reportsLoaded_list["$appletName"] );
//     			ready =1;
//     		}
//     	applet_isReady_list["$appletName"]= ready;
//     	return(ready);
//     }
//     	
//     applet_initializeAction_list["$appletName"] = function (state) {
//           applet_setState_list["$appletName"](state);
// 	};
// 	
// 	applet_submitAction_list["$appletName"] = function () {  
// 	      if (! applet_isReady_list["$appletName"]  ) {
// 	      	alert("$appletName is not ready");
// 	      }
//           applet_getState_list["$appletName"]();
//           $submitActionScript
// 		  //getQE("$answerBox").value = getApplet("$appletName").getAnswer();  //FIXME -- not needed in general?
//     };
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
				 <param name="bgcolor" value="#869ca7" />
				 <param name="allowScriptAccess" value="sameDomain" />
				 <embed src="$codebase/$appletName.swf" quality="high" bgcolor="#869ca7"
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
         <param name="bgcolor" value="#869ca7" />
         <param name="allowScriptAccess" value="sameDomain" />
         <param name="FlashVars" value="$flashParameters"/>
         <embed src="$codebase/$appletName.swf" quality="high" bgcolor="#869ca7"
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