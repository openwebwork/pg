################################################################################
# WeBWorK Online Homework Delivery System
# Copyright © 2000-2007 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader: pg/macros/AppletObjects.pl,v 1.7 2008/04/26 21:19:14 gage Exp $
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

AppletObjects.pl - Macro-based front end for the Applet.pm module.


=head1 DESCRIPTION

This subroutines in this 
file provide mechanisms to insert Flash applets (and later Java applets)
into a WeBWorK problem.


=head1 SEE ALSO

L<Applets.pm>.

=cut


sub _AppletObjects_init{}; # don't reload this file


main::HEADER_TEXT(<<'END_HEADER_TEXT');
  <script language="javascript">AC_FL_RunContent = 0;</script>
    <script src="/webwork2_files/applets/AC_RunActiveContent.js" language="javascript">
    </script>
    <script src="/webwork2_files/js/Base64.js" language="javascript">
    </script>
    
<script language="JavaScript">

//////////////////////////////////////////////////////////
// applet lists
//////////////////////////////////////////////////////////

    var  applet_initializeAction_list = new Object;  // functions for initializing question with an applet
    var  applet_submitAction_list     = new Object;  // functions for submitting question with applet
    var  applet_setState_list         = new Object;  // functions for setting state (XML) from applets
    var  applet_getState_list         = new Object;  // functions for getting state (XML) from applets
    var  applet_config_list           = new Object;  // functions for  configuring on applets
	var  applet_checkLoaded_list      = new Object;  // functions for probing the applet to see if it is loaded
	var  applet_reportsLoaded_list    = new Object;  // flag set by applet
	var  applet_isReady_list          = new Object;  // flag set by javaScript in checkLoaded 
    
//////////////////////////////////////////////////////////
// DEBUGGING tools
//////////////////////////////////////////////////////////
	var debug;
	var debugText = "";
	function set_debug(num) { // setting debug for any applet sets it for all of them
		if (num) {
			debug =1;
		}
	}
	function debug_add(str) {
		if (debug) {
			debugText = debugText + "\n\n" +str;
		}
	}
	
//////////////////////////////////////////////////////////
// INITIALIZE and SUBMIT actions
//////////////////////////////////////////////////////////

    function submitAction()  {
        //alert("submit Action" );
		for (var applet in applet_submitAction_list)  {
			 //alert(applet);
			 applet_submitAction_list[applet]();
		}
    	
    }
    function initializeAction() {
        var iMax = 10;
        debugText="start intializeAction() with up to " +iMax + " attempts\n";
    	for (var appletName in applet_initializeAction_list)  {		
			safe_applet_initialize(appletName, iMax);
    	}

    }
   	
   	// applet can set isReady flag by calling applet_loaded(appletName, loaded);
    function applet_loaded(appletName,loaded) {
        applet_reportsLoaded_list[appletName] = loaded; // 0 means not loaded
    	debug_add("applet reporting that it has been loaded = " + loaded );
    }
    
    // insures that applet is loaded before initializing it
	function safe_applet_initialize(appletName, i) {
		debug_add("Iteration " + i + " of safe_applet_initialize with applet " + appletName );
		
		i--;
		var applet_loaded = applet_checkLoaded_list[appletName]();
		debug_add("applet is ready = " + applet_loaded  );
	
		if ( 0 < i && !applet_loaded ) { // wait until applet is loaded
			debug_add("applet " + appletName + "not ready try again");
			window.setTimeout( "safe_applet_initialize(\"" + appletName + "\"," + i +  ")",1);
		} else if( 0 < i ){  // now that applet is loaded configure it and initialize it with saved data.
			debug_add(" Ready to initialize applet " + appletName + " with " + i +  " iterations left. "); 
			
			// in-line handler -- configure and initialize
			try{
				if (debug && typeof(getApplet(appletName).debug) == "function" ) {
					getApplet(appletName).debug(1);
				}					
			} catch(e) {
				alert("Unable to set debug mode for applet " + appletName);
			}
			try{
				applet_config_list[appletName]();
			} catch(e) {
				alert("Unable to configure " + appletName + " \n " +e );  
			}
			try{
				applet_initializeAction_list[appletName]();
			} catch(e) {
				alert("unable to initialize " + appletName + " \n " +e );  
			}
			
		} else {
			if (debug) {alert("Error: timed out waiting for applet " +appletName + " to load");}
		}
		if (debug) {alert(debugText); debugText="";};
	}
   
///////////////////////////////////////////////////////
// Utility functions
///////////////////////////////////////////////////////   
    

	function getApplet(appletName) {
		  var isIE = navigator.appName.indexOf("Microsoft") != -1;
		  var obj = (isIE) ? window[appletName] : window.document[appletName];
		  //return window.document[appletName];
		  if (obj && (obj.name = appletName)) {
			  return( obj );
		  } else {
			 // alert ("can't find applet " + appletName);		  
		  }
	 }	
	
	function listQuestionElements() { // list all HTML input and textarea elements in main problem form
	   var isIE = navigator.appName.indexOf("Microsoft") != -1;
	   var elementList = (isIE) ?  document.getElementsByTagName("input") : document.problemMainForm.getElementsByTagName("input");
	   var str=elementList.length +" Question Elements\n type | name = value  < id > \n";
	   for( var i=0; i< elementList.length; i++) {
		   str = str + " "+i+" " + elementList[i].type 
						   + " | " + elementList[i].name 
						   + "= " + elementList[i].value + 
						   " <" + elementList[i].id + ">\n";
	   }
	   elementList = (isIE) ?  document.getElementsByTagName("textarea") : document.problemMainForm.getElementsByTagName("textarea");
	   for( var i=0; i< elementList.length; i++) {
		   str = str + " "+i+" " + elementList[i].type 
						   + " | " + elementList[i].name 
						   + "= " + elementList[i].value + 
						   " <" + elementList[i].id + ">\n";
	   }
	   alert(str +"\n Place listQuestionElements() at end of document in order to get all form elements!");
	}
	
	function base64Q(str) {
		return ( !str.match(/<XML/i) && !str.match(/<?xml/i));
	}
	function setEmptyState(appletName){
		var newState = "<xml></xml>";
		applet_setState_list[appletName](newState);
		var applet = getApplet(appletName);
		getQE(appletName+"_state").value = newState;
		getQE("previous_" + appletName + "_state").value = newState
	}
	
	function getQE(name1) { // get Question Element in problemMainForm by name
		var isIE = navigator.appName.indexOf("Microsoft") != -1;
		var obj = (isIE) ? document.getElementById(name1)
							:document.problemMainForm[name1]; 
		// needed for IE -- searches id and name space so it can be unreliable if names are not unique
		if (!obj || obj.name != name1) {
			alert("Can't find element " + name1);
			listQuestionElements();		
		} else {
			return( obj );
		}
		
	}
	function getQuestionElement(name1) {
		return getQE(name1);
	}

 </script>
 
END_HEADER_TEXT



=head3
	FlashApplet

	Useage:    $applet = FlashApplet();

=cut

sub FlashApplet {
	return new FlashApplet(@_);

}

sub JavaApplet {
	return new JavaApplet(@_);

}

package Applet;


 
=head2 Methods

=cut

## this method is defined in this file 
## because the main subroutines HEADER_TEXT and MODES are 
## not available to the module FlashApplet when that file
## is compiled (at the time the apache child process is first initialized)

=head3  insertAll

	Useage:   TEXT( $applet->insertAll() );
	          \{ $applet->insertAll() \}     (used within BEGIN_TEXT/END_TEXT blocks)

=cut 

=pod 

Inserts applet at this point in the HTML code.  (In TeX mode a message "Applet" is written.)  This method
also adds the applets header material into the header portion of the HTML page. It effectively inserts
the outputs of both C<$applet-E<gt>insertHeader> and C<$applet-E<gt>insertObject> (defined in L<Applet.pm> ) 
in the appropriate places.

Note: This method is defined here rather than in Applet.pl because it 
      requires access to the RECORD_FORM_LABEL subroutine
      and to the routine accessing the stored values of the answers.  These are defined in main::.

=cut

sub insertAll {  ## inserts both header text and object text
	my $self = shift;
	my %options = @_;
	$self->debug( (defined($options{debug}) and $options{debug}==1) ? 1 : 0 );
	my $reset_button = $options{reset_button} || 0;
	# prepare html code for storing state 
	my $appletName      = $self->appletName;
	my $appletStateName = "${appletName}_state";
	my $getState        = $self->getStateAlias;
	my $setState        = $self->setStateAlias;
	my $base64_initialState     = $self->base64_state;
	main::RECORD_FORM_LABEL($appletStateName);            #this insures that they'll be saved from one invocation to the next
	#main::RECORD_FORM_LABEL("previous_$appletStateName");
    my $answer_value = '';
	$answer_value = ${$main::inputs_ref}{$appletStateName} if defined(${$main::inputs_ref}{$appletStateName});
	
	if ( defined( $main::rh_sticky_answers->{$appletStateName} ) ) {
		$answer_value = shift( @{ $main::rh_sticky_answers->{$appletStateName} });
		$answer_value = '' unless defined($answer_value);
	}
	$answer_value =~ tr/\\$@`//d;   #`## make sure student answers can not be interpolated by e.g. EV3
	$answer_value =~ s/\s+/ /g;     ## remove excessive whitespace from student answer
	
	#######
	# insert a hidden variable to hold the applet's state (debug =>1 makes it visible for debugging and provides debugging buttons)
	#######
	my $base_64_encoded_answer_value = ($answer_value =~/<XML>/i)? encode_base64($answer_value) : $answer_value;
	my $decoded_answer_value         = ($answer_value =~/<XML>/i) ? $answer_value : decode_base64($answer_value);
    my $debug_input_element  = qq!\n<textarea  rows="4" cols="80" 
	   name = "$appletStateName">$decoded_answer_value</textarea><br/>
	        <input type="button"  value="$getState" 
	               onClick="applet_getState_list['$appletName']()"
	        >
	        <input type="button"  value="$setState" 
	               onClick="var tmp = getQE('$appletStateName').value;
	                        applet_setState_list['$appletName'](tmp);"
	        >
	  !;
	my $state_input_element = ($self->debug == 1) ? $debug_input_element :
	      qq!\n<input type="hidden" name = "$appletStateName" value ="$base_64_encoded_answer_value">!;
    my $reset_button_str = ($reset_button) ?
            qq!<br/><input type='button' value='set applet state empty' onClick="setEmptyState('$appletName')">
                    <input type="button" value="reinitialize applet" onClick="getQE('$appletStateName').value='$base64_initialState'"/>!
            : '' 
    ;
	# always base64 encode the hidden answer value to prevent problems with quotes. 
    #
	$state_storage_html_code = 
	                    $reset_button_str.
	                    $state_input_element.
                        qq!<input type="hidden"  name="previous_$appletStateName" value = "$base_64_encoded_answer_value">!;
    #######
    # insert header material
    #######
	main::HEADER_TEXT($self->insertHeader());
    return main::MODES(TeX=>' {\bf  applet } ', HTML=>$self->insertObject.$main::BR.$state_storage_html_code);
}

=head3 Example problem


=cut



=pod


	DOCUMENT();
	
	# Load whatever macros you need for the problem
	loadMacros("PG.pl",
			   "PGbasicmacros.pl",
			   "PGchoicemacros.pl",
			   "PGanswermacros.pl",
			   "AppletObjects.pl",
			   "MathObjects.pl",
			   "source.pl"
			  );
	 
	## Do NOT show partial correct answers
	$showPartialCorrectAnswers = 0;
	
	
	
	###################################
	# Create  link to applet 
	###################################
	
	$applet = FlashApplet();
	my $appletName = "ExternalInterface";
	$applet->codebase(findAppletCodebase("$appletName.swf"));
	$applet->appletName($appletName);
	$applet->appletId($appletName);
	
	# findAppletCodebase looks for the applet in a list
	# of locations specified in global.conf
	
	###################################
	# Add additional javaScript functions to header section of HTML to 
	# communicate with the "ExternalInterface" applet.
	###################################
	
	$applet->header(<<'END_HEADER');
	<script type="text/javascript" src="https://devel.webwork.rochester.edu:8002/webwork2_files/js/BrowserSniffer.js">
	</script>
	
	
	<script language="JavaScript">
		function getBrowser() {
			  //alert("look for sniffer");
		  var sniffer = new BrowserSniffer();
		  //alert("found sniffer" +sniffer);
		  return sniffer;
		}
	
		function updateStatus(sMessage) {
			  getQE("playbackStatus").value = sMessage;
		}
		
		function newColor() {

		  getApplet("ExternalInterface").updateColor(Math.round(Math.random() * 0xFFFFFF));
		}
		
	</script>
	END_HEADER
	
	###################################
	# Configure applet
	###################################
	
	# not used here.  Allows for uploading an xml string for the applet
	
	
	
	
	###################################
	# write the text for the problem
	###################################
	
	TEXT(beginproblem());
	
	
	 
	BEGIN_TEXT
	\{ $applet->insertAll() \}
	  $PAR
	
	  The Flash object operates above this line.  The box and button below this line are part of 
	  the WeBWorK problem.  They communicate with the Flash object.
	  $HR
	  Status <input type="text" id="playbackStatus" value="started" /><br />
	  Color <input type="button" value="new color" name="newColorButton" onClick="newColor()" />
	   $PAR $HR
	   This flash applet was created by Barbara Kaskosz. 
	
	END_TEXT
	
	ENDDOCUMENT();




=cut