################################################################################
# WeBWorK Online Homework Delivery System
# Copyright © 2000-2007 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader: pg/macros/AppletObjects.pl,v 1.24 2010/01/03 17:13:46 gage Exp $
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
file provide mechanisms to insert Flash applets (and  Java applets)
into a WeBWorK problem.


See also L<http://webwork.maa.org/pod/pg_TRUNK/lib/Applet.html>.

=cut

#########################################################################
#
# Add basic functionality to the header of the question
#
# don't reload this file
#########################################################################

sub _AppletObjects_init{ 

main::HEADER_TEXT(<<'END_HEADER_TEXT');
  <script language="javascript">AC_FL_RunContent = 0;</script>
    <script src="/webwork2_files/applets/AC_RunActiveContent.js" language="javascript">
    </script>
END_HEADER_TEXT

};

=head3  FlashApplet

	Useage:    $applet = FlashApplet();

=cut

sub FlashApplet {
	return new FlashApplet(@_);

}

=head3  JavaApplet

	Useage:    $applet = JavaApplet(
	
	
	);

=cut

sub JavaApplet {
	return new JavaApplet(@_);

}

=head3  CanvasApplet

	Useage:    $applet = CanvasApplet(
	
	
	);

=cut

sub CanvasApplet {
	return new CanvasApplet(@_);
}

=head3  GeogebraWebApplet

	Useage:    $applet = GeogebraWebApplet(
	
	
	);

=cut

sub GeogebraWebApplet {
	return new GeogebraWebApplet(@_);
}

package Applet;



=head1 Methods

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
in the appropriate places. In addition it creates a hidden answer blank for storing the state of the applet
and provides mechanisms for revealing the state while debugging the applet.

Note: This method is defined here rather than in Applet.pl because it 
      requires access to the RECORD_FORM_LABEL subroutine
      and to the routine accessing the stored values of the answers.  These are defined in main::.
      FIXME -- with the creation of the PGcore object this can now be rewritten

=cut

sub insertAll {  ## inserts both header text and object text
	my $self = shift;
	my %options = @_;
	
	
	##########################
	# determine debug mode
	# debugMode can be turned on by setting it to 1 in either the applet definition or at insertAll time
	##########################

	my $debugMode = (defined($options{debug}) and $options{debug}>0) ? $options{debug} : 0;
	my $includeAnswerBox = (defined($options{includeAnswerBox}) and $options{includeAnswerBox}==1) ? 1 : 0;
	$debugMode = $debugMode || $self->debugMode;
    $self->debugMode( $debugMode);

	
	my $reset_button = $options{reinitialize_button} || 0;
	warn qq! please change  "reset_button=>1" to "reinitialize_button=>1" in the applet->installAll() command \n! if defined($options{reset_button});

	##########################
	# Get data to be interpolated into the HTML code defined in this subroutine
	#
    # This consists of the name of the applet and the names of the routines 
    # to get and set State of the applet (which is done every time the question page is refreshed
    # and to get and set Config  which is the initial configuration the applet is placed in 
    # when the question is first viewed.  It is also the state which is returned to when the 
    # reset button is pressed.
	##########################

	# prepare html code for storing state 
	my $appletName      = $self->appletName;
	my $appletStateName = "${appletName}_state";   # the name of the hidden "answer" blank storing state FIXME -- use persistent data instead
	my $getState        = $self->getStateAlias;    # names of routines for this applet
	my $setState        = $self->setStateAlias;
	my $getConfig       = $self->getConfigAlias;
	my $setConfig       = $self->setConfigAlias;

	my $base64_initialState     = encode_base64($self->initialState);
	main::RECORD_FORM_LABEL($appletStateName);            #this insures that the state will be saved from one invocation to the next
	                                                      # FIXME -- with PGcore the persistant data mechanism can be used instead
    my $answer_value = '';

	##########################
	# implement the sticky answer mechanism for maintaining the applet state when the question page is refreshed
	# This is important for guest users for whom no permanent record of answers is recorded.
	##########################
	
    if ( defined( ${$main::inputs_ref}{$appletStateName} ) and ${$main::inputs_ref}{$appletStateName} =~ /\S/ ) {   
		$answer_value = ${$main::inputs_ref}{$appletStateName};
	} elsif ( defined( $main::rh_sticky_answers->{$appletStateName} )  ) {
	    warn "type of sticky answers is ", ref( $main::rh_sticky_answers->{$appletStateName} );
		$answer_value = shift( @{ $main::rh_sticky_answers->{$appletStateName} });
	}
	$answer_value =~ tr/\\$@`//d;   #`## make sure student answers can not be interpolated by e.g. EV3
	$answer_value =~ s/\s+/ /g;     ## remove excessive whitespace from student answer
	
	##########################
	# insert a hidden answer blank to hold the applet's state 
	# (debug =>1 makes it visible for debugging and provides debugging buttons)
	##########################


	##########################
	# Regularize the applet's state -- which could be in either XML format or in XML format encoded by base64
	# In rare cases it might be simple string -- protect against that by putting xml tags around the state
	# The result:
	# $base_64_encoded_answer_value -- a base64 encoded xml string
	# $decoded_answer_value         -- and xml string
	##########################
    	
	my $base_64_encoded_answer_value;
	my $decoded_answer_value;
	if ( $answer_value =~/<XML|<?xml/i) {
		$base_64_encoded_answer_value = encode_base64($answer_value);
		$decoded_answer_value = $answer_value;
	} else {
		$decoded_answer_value = decode_base64($answer_value);
		if ( $decoded_answer_value =~/<XML|<?xml/i) {  # great, we've decoded the answer to obtain an xml string
			$base_64_encoded_answer_value = $answer_value;
		} else {    #WTF??  apparently we don't have XML tags
			$answer_value = "<xml>$answer_value</xml>";
			$base_64_encoded_answer_value = encode_base64($answer_value);
			$decoded_answer_value = $answer_value;
		}
	}	
	$base_64_encoded_answer_value =~ s/\r|\n//g;    # get rid of line returns

	##########################
    # Construct answer blank for storing state -- in both regular (answer blank hidden) 
    # and debug (answer blank displayed) modes.
	##########################
	
	##########################
    # debug version of the applet state answerBox and controls (all displayed)
    # stored in 
    # $debug_input_element
	##########################

#     my $debug_input_element  = qq!\n<textarea  rows="4" cols="80" 
# 	   name = "$appletStateName" id = "$appletStateName">$decoded_answer_value</textarea><br/>!;
#  conversion to base64 is now being done in the setState module
#  when submitting we want everything to be in the base64 mode for safety
    my $debug_input_element  = qq!\n<textarea  rows="4" cols="80" 
	   name = "$appletStateName" id = "$appletStateName">$answer_value</textarea><br/>!;

	if ($getState=~/\S/) {   # if getStateAlias is not an empty string
		$debug_input_element .= qq!
	        <input type="button"  value="$getState" 
	               onClick=" debugText=''; 
	                         ww_applet_list['$appletName'].getState() ; 
	                        if (debugText) {alert(debugText)};"
	        />!;
	}
	if ($setState=~/\S/) {   # if setStateAlias is not an empty string
		$debug_input_element .= qq!
	        <input type="button"  value="$setState" 
	               onClick="debugText='';
	                        ww_applet_list['$appletName'].setState();
	                        if (debugText) {alert(debugText)};"
	        />!;
	}
	if ($getConfig=~/\S/) {   # if getConfigAlias is not an empty string
		$debug_input_element .= qq!
	        <input type="button"  value="$getConfig" 
	               onClick="debugText=''; 
	                        ww_applet_list['$appletName'].getConfig();
	                        if (debugText) {alert(debugText)};"
	        />!;
	}
	if ($setConfig=~/\S/) {   # if setConfigAlias is not an empty string
		$debug_input_element .= qq!
		    <input type="button"  value="$setConfig" 
	               onClick="debugText='';
	                        ww_applet_list['$appletName'].setConfig();
	                        if (debugText) {alert(debugText)};"
            />!;
    }
    
	##########################
    # Construct answerblank for storing state
    # using either the debug version (defined above) or the non-debug version
    # where the state variable is hidden and the definition is very simple
    # stored in 
    # $state_input_element
	##########################
	        
	my $state_input_element = ($debugMode) ? $debug_input_element :
	      qq!\n<input type="hidden" name = "$appletStateName" id = "$appletStateName"  value ="$base_64_encoded_answer_value">!;
	      
	##########################
    # Construct the reset button string (this is blank if the button is not to be displayed
    # $reset_button_str
	##########################

    my $reset_button_str = ($reset_button) ?
            qq!<input type='submit' name='previewAnswers' id ='previewAnswers' value='return this question to its initial state' 
                 onClick="setHTMLAppletStateToRestart('$appletName')"><br/>!
            : ''  ;

	##########################
	# Combine the state_input_button and the reset button into one string
	# $state_storage_html_code
	##########################


    $state_storage_html_code = qq!<input type="hidden"  name="previous_$appletStateName" id = "previous_$appletStateName"  value = "$base_64_encoded_answer_value">!              
                              . $state_input_element. $reset_button_str
                             ;
	##########################
	# Construct the answerBox (if it is requested).  This is a default input box for interacting 
	# with the applet.  It is separate from maintaining state but it often contains similar data.
	# Additional answer boxes or buttons can be defined but they must be explicitly connected to 
	# the applet with additional javaScript commands.
	# Result: $answerBox_code
	##########################

    my $answerBox_code ='';
    if ($includeAnswerBox) {
		if ($debugMode) {
		
			$answerBox_code = $main::BR . main::NAMED_ANS_RULE('answerBox', 50 );
			$answerBox_code .= qq!
							 <br/><input type="button" value="get Answer from applet" onClick="eval(ww_applet_list['$appletName'].submitActionScript )"/>
							 <br/>
							!;
		} else {
			$answerBox_code = main::NAMED_HIDDEN_ANS_RULE('answerBox', 50 );
		}
	}
	
	##########################
    # insert header material
	##########################
	main::HEADER_TEXT($self->insertHeader());
	# update the debug mode for this applet.
    main::HEADER_TEXT(qq!<script language="javascript"> ww_applet_list["$appletName"].debugMode = $debugMode;\n</script>!);
    
	##########################
    # Return HTML or TeX strings to be included in the body of the page
	##########################
        
    return main::MODES(TeX=>' {\bf  applet } ', HTML=>$self->insertObject.$main::BR.$state_storage_html_code.$answerBox_code);
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
	<script language="javascript" src="https://devel.webwork.rochester.edu:8002/webwork2_files/js/BrowserSniffer.js">
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
