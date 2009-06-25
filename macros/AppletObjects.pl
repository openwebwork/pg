################################################################################
# WeBWorK Online Homework Delivery System
# Copyright © 2000-2007 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader: pg/macros/AppletObjects.pl,v 1.20 2009/03/22 18:33:06 gage Exp $
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


=head1 SEE ALSO

L<Applets.pm>.

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
    <script src="/webwork2_files/js/Base64.js" language="javascript">
    </script> 	
  	<script src="/webwork2_files/js/ww_applet_support.js">
  	    //upload functions stored in /opt/webwork/webwork2/htdocs/js ...
		
    </script>
END_HEADER_TEXT

};

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
	
	# debugMode can be turned on by setting it to 1 in either the applet definition or at insertAll time
	my $debugMode = (defined($options{debug}) and $options{debug}==1) ? 1 : 0;
	my $includeAnswerBox = (defined($options{includeAnswerBox}) and $options{includeAnswerBox}==1) ? 1 : 0;
	$debugMode = $debugMode || $self->debugMode;
    $self->debugMode( $debugMode);

	
	my $reset_button = $options{reinitialize_button} || 0;
	warn qq! please change  "reset_button=>1" to "reinitialize_button=>1" in the applet->installAll() command ! if defined($options{reset_button});
	# prepare html code for storing state 
	my $appletName      = $self->appletName;
	my $appletStateName = "${appletName}_state";
	my $getState        = $self->getStateAlias;
	my $setState        = $self->setStateAlias;
	my $getConfig       = $self->getConfigAlias;
	my $setConfig       = $self->setConfigAlias;

	my $base64_initialState     = encode_base64($self->initialState);
	main::RECORD_FORM_LABEL($appletStateName);            #this insures that they'll be saved from one invocation to the next
    my $answer_value = '';
    
    if ( defined( ${$main::inputs_ref}{$appletStateName} ) and ${$main::inputs_ref}{$appletStateName} =~ /\S/ ) {   
		$answer_value = ${$main::inputs_ref}{$appletStateName};
	} elsif ( defined( $main::rh_sticky_answers->{$appletStateName} )  ) {
	    warn "type of sticky answers is ", ref( $main::rh_sticky_answers->{$appletStateName} );
		$answer_value = shift( @{ $main::rh_sticky_answers->{$appletStateName} });
	}
	$answer_value =~ tr/\\$@`//d;   #`## make sure student answers can not be interpolated by e.g. EV3
	$answer_value =~ s/\s+/ /g;     ## remove excessive whitespace from student answer
	#######
	# insert a hidden variable to hold the applet's state (debug =>1 makes it visible for debugging and provides debugging buttons)
	#######
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
    # debug version of the applet state answerBox and controls
    my $debug_input_element  = qq!\n<textarea  rows="4" cols="80" 
	   name = "$appletStateName">$decoded_answer_value</textarea><br/>
	        <input type="button"  value="$getState" 
	               onClick="debugText=''; 
	                        ww_applet_list['$appletName'].getState(); 
	                        alert(debugText);"
	        >
	        <input type="button"  value="$setState" 
	               onClick="debugText='';
	                        ww_applet_list['$appletName'].setState();
	                        alert(debugText);"
	        >
	        <input type="button"  value="$getConfig" 
	               onClick="debugText=''; 
	                        ww_applet_list['$appletName'].getConfig()";	                       "
	        >
		    <input type="button"  value="$setConfig" 
	               onClick="debugText='';
	                        ww_applet_list['$appletName'].setConfig();
	                        alert(debugText);"
            >
	  !;
	        
	my $state_input_element = ($debugMode) ? $debug_input_element :
	      qq!\n<input type="hidden" name = "$appletStateName" value ="$base_64_encoded_answer_value">!;
    my $reset_button_str = ($reset_button) ?
            qq!<input type='submit' name='previewAnswers' value='return this question to its initial state' onClick="setAppletStateToRestart('$appletName')"><br/>!
            : ''  ;
            # <input type="button" value="reinitialize applet" onClick="getQE('$appletStateName').value='$base64_initialState'"/><br/>
	# always base64 encode the hidden answer value to prevent problems with quotes. 
    #
    $state_storage_html_code = qq!<input type="hidden"  name="previous_$appletStateName" value = "$base_64_encoded_answer_value">!              
                              . $state_input_element. $reset_button_str
                             ;
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
    #######
    # insert header material
    #######
	main::HEADER_TEXT($self->insertHeader());
	# update the debug mode for this applet.
    main::HEADER_TEXT(qq!<script> ww_applet_list["$appletName"].debugMode = $debugMode;\n</script>!);
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