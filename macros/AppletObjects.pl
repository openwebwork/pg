################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2020 The WeBWorK Project, http://openwebwork.sf.net/
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

The subroutines in this file provide mechanisms to insert Flash applets, Java applets, HTML 5
Canvas applets, and Geogebra web applets into a WeBWorK problem.

See also L<Applet.pm>.

=cut

# Add basic functionality to the header of the question
sub _AppletObjects_init{
	ADD_JS_FILE("js/apps/Base64/Base64.js");
	ADD_JS_FILE("js/apps/AppletSupport/ww_applet_support.js");
};

=head3  FlashApplet

    Useage:    $applet = FlashApplet(...);

=cut

sub FlashApplet {
	ADD_JS_FILE("js/apps/AppletSupport/AC_RunActiveContent.js");
	return new FlashApplet(@_);
}

=head3  JavaApplet

    Useage:    $applet = JavaApplet(...);

=cut

sub JavaApplet {
	return new JavaApplet(@_);
}

=head3  CanvasApplet

    Useage:    $applet = CanvasApplet(...);

=cut

sub CanvasApplet {
	return new CanvasApplet(@_);
}

=head3  GeogebraWebApplet

    Useage:    $applet = GeogebraWebApplet(...);

=cut

sub GeogebraWebApplet {
	ADD_JS_FILE("https://www.geogebra.org/apps/latest/web/web.nocache.js", 1);
	return new GeogebraWebApplet(@_);
}

package Applet;

=head1 Methods

=cut

# This method is defined in this file because it uses methods in PG.pl and PGbasicmacros.pl that
# are not available to Applet.pm when it is compiled (at the time the apache child process is
# first initialized).

=head3  insertAll

    Useage:  TEXT($applet->insertAll());
             \{ $applet->insertAll() \}  (used within BEGIN_TEXT/END_TEXT blocks)

=cut

=pod

Inserts applet at this point in the HTML code.  (In TeX mode a message "Applet" is written.)
This method also adds the applets header material into the header portion of the HTML page. It
effectively inserts the outputs of both C<$applet-E<gt>insertHeader> and
C<$applet-E<gt>insertObject> (defined in L<Applet.pm>) in the appropriate places. In addition it
creates a hidden answer blank for storing the state of the applet and provides mechanisms for
revealing the state while debugging the applet.

=cut

# Inserts both header text and object text.
sub insertAll {
	my $self = shift;
	my %options = @_;

	# Determine debug mode
	# debugMode can be turned on by setting it to 1 in either the applet definition or at insertAll time
	my $debugMode = (defined($options{debug}) && $options{debug} > 0) ? $options{debug} : 0;
	my $includeAnswerBox = (defined($options{includeAnswerBox}) && $options{includeAnswerBox} == 1) ? 1 : 0;
	$debugMode = $debugMode || $self->debugMode;
	$self->debugMode($debugMode);

	my $reset_button = $options{reinitialize_button} || 0;
	warn qq! please change  "reset_button => 1" to "reinitialize_button => 1" in the applet->installAll() command \n!
	if defined($options{reset_button});

	# Get data to be interpolated into the HTML code defined in this subroutine.
	# This consists of the name of the applet and the names of the routines to get and set State
	# of the applet (which is done every time the question page is refreshed and to get and set
	# Config  which is the initial configuration the applet is placed in when the question is
	# first viewed.  It is also the state which is returned to when the reset button is pressed.

	# Prepare html code for storing state.
	my $appletName = $self->appletName;
	# The name of the hidden "answer" blank storing state.
	$self->{stateInput} = "$main::PG->{QUIZ_PREFIX}${appletName}_state";
	my $appletStateName = $self->{stateInput};

	# Names of routines for this applet
	my $getState = $self->getStateAlias;
	my $setState = $self->setStateAlias;
	my $getConfig = $self->getConfigAlias;
	my $setConfig = $self->setConfigAlias;

	my $base64_initialState = encode_base64($self->initialState);
	# This insures that the state will be saved from one invocation to the next.
	# FIXME -- with PGcore the persistant data mechanism can be used instead
	main::RECORD_FORM_LABEL($appletStateName);
	my $answer_value = '';

	# Implement the sticky answer mechanism for maintaining the applet state when the question
	# page is refreshed This is important for guest users for whom no permanent record of
	# answers is recorded.
	if (defined(${$main::inputs_ref}{$appletStateName}) && ${$main::inputs_ref}{$appletStateName} =~ /\S/) {
		$answer_value = ${$main::inputs_ref}{$appletStateName};
	} elsif (defined($main::rh_sticky_answers->{$appletStateName})) {
		warn "type of sticky answers is ", ref($main::rh_sticky_answers->{$appletStateName});
		$answer_value = shift(@{$main::rh_sticky_answers->{$appletStateName}});
	}
	$answer_value =~ tr/\\$@`//d; # Make sure student answers can not be interpolated by e.g. EV3
	$answer_value =~ s/\s+/ /g; # Remove excessive whitespace from student answer

	# Insert a hidden answer blank to hold the applet's state.
	# (debug => 1 makes it visible for debugging and provides debugging buttons)

	# Regularize the applet's state which could be in either XML format or in XML format encoded by base64.
	# In rare cases it might be simple string.  Protect against that by putting xml tags around the state.
	# The result:
	# $base_64_encoded_answer_value -- a base64 encoded xml string
	# $decoded_answer_value         -- an xml string

	my $base_64_encoded_answer_value;
	my $decoded_answer_value;
	if ($answer_value =~ /<XML|<?xml/i) {
		$base_64_encoded_answer_value = encode_base64($answer_value);
		$decoded_answer_value = $answer_value;
	} else {
		$decoded_answer_value = decode_base64($answer_value);
		if ($decoded_answer_value =~/<XML|<?xml/i) {
			# Great, we've decoded the answer to obtain an xml string
			$base_64_encoded_answer_value = $answer_value;
		} else {
			#WTF??  apparently we don't have XML tags
			$answer_value = "<xml>$answer_value</xml>";
			$base_64_encoded_answer_value = encode_base64($answer_value);
			$decoded_answer_value = $answer_value;
		}
	}
	$base_64_encoded_answer_value =~ s/\r|\n//g; # Get rid of line returns

	# Construct answer blank for storing state -- in both regular (answer blank hidden)
	# and debug (answer blank displayed) modes.

	# Debug version of the applet state answerBox and controls (all displayed) stored in
	# $debug_input_element

	# When submitting we want everything to be in the base64 mode for safety.
	my $debug_input_element  = qq!\n<textarea  rows="4" cols="80"
		name="$appletStateName" id="$appletStateName">$answer_value</textarea><br/>!;

	if ($getState =~ /\S/) {
		$debug_input_element .= qq!<input type="button"  value="$getState"
			onClick="debugText=''; ww_applet_list['$appletName'].getState(); if (debugText) {alert(debugText)};"/>!;
	}
	if ($setState =~ /\S/) {
		$debug_input_element .= qq!<input type="button"  value="$setState"
			onClick="debugText=''; ww_applet_list['$appletName'].setState(); if (debugText) {alert(debugText)};"/>!;
	}
	if ($getConfig=~/\S/) {
		$debug_input_element .= qq!<input type="button"  value="$getConfig"
			onClick="debugText=''; ww_applet_list['$appletName'].getConfig(); if (debugText) {alert(debugText)};"/>!;
	}
	if ($setConfig=~/\S/) {
		$debug_input_element .= qq!<input type="button"  value="$setConfig"
			onClick="debugText=''; ww_applet_list['$appletName'].setConfig(); if (debugText) {alert(debugText)};"/>!;
	}

	# Construct answerblank for storing state using either the debug version (defined above) or
	# the non-debug version where the state variable is hidden and the definition is very
	# simple.
	my $state_input_element = ($debugMode) ? $debug_input_element :
		qq!\n<input type="hidden" name="$appletStateName" id="$appletStateName"  value="$base_64_encoded_answer_value">!;

	# Construct the reset button string (this is blank if the button is not to be displayed).
	my $reset_button_str = ($reset_button) ?
		qq!<button type='button' id='resetAppletState' class='btn btn-primary'
		onClick="setHTMLAppletState('$appletName');document.getElementsByName('previewAnswers')[0].click();">
		return this question to its initial state</button><br/>!
		: '';

	# Combine the state_input_button and the reset button into one string.
	my $state_storage_html_code = qq!<input type="hidden" name="previous_$appletStateName"
		id="previous_$appletStateName" value = "$base_64_encoded_answer_value">!
		. $state_input_element . $reset_button_str;

	# Construct the answerBox (if it is requested).  This is a default input box for interacting
	# with the applet.  It is separate from maintaining state but it often contains similar
	# data.  Additional answer boxes or buttons can be defined but they must be explicitly
	# connected to the applet with additional JavaScript commands.
	my $answerBox_code = '';
	if ($includeAnswerBox) {
		if ($debugMode) {
			$answerBox_code = $main::BR . main::NAMED_ANS_RULE($self->{answerBoxAlias}, 50);
			$answerBox_code .= qq!<br/><input type="button" value="get Answer from applet"
				onClick="eval(ww_applet_list['$appletName'].submitActionScript )"/><br/>!;
		} else {
			$answerBox_code = main::NAMED_HIDDEN_ANS_RULE($self->{answerBoxAlias}, 50);
		}
	}

	# Insert header material
	main::HEADER_TEXT($self->insertHeader());
	# Update the debug mode for this applet.
	main::HEADER_TEXT(qq!<script>ww_applet_list["$appletName"].debugMode = $debugMode;\n</script>!);

	# Return HTML or TeX strings to be included in the body of the page
	return main::MODES(
		TeX => ' {\bf ' . $self->{type} . ' applet } ',
		HTML => $self->insertObject . $main::BR . $state_storage_html_code . $answerBox_code,
		PTX => ' applet '
	);
}

=head3 Example problem

=cut

=pod

    DOCUMENT();

    # Load whatever macros you need for the problem
    loadMacros(
        "PGstandard.pl",
        "MathObjects.pl",
		"AppletObjects.pl",
        "PGcourse.pl",
    );

    TEXT(beginproblem());

    ###################################
    # Standard PG problem setup. Random parameters, answers, and such.
    ###################################

    $ans = Compute("0");

    ###################################
    # $appletName can be anything reasonable, but should try to choose a name that will not be
    # used by other problems.  If multiple problems appear on the same page in a gateway quiz
    # that use the same name, one of the applets will not work.
    ###################################

    $appletName = "myUniqueAppletName";

    ###################################
    # Generate the answer box name to use.  This is only needed if the applet returns an answer
    # that will be checked by WeBWorK.  The approach of using NEW_ANS_NAME guarantees that you
    # will get an answer name that will work in any problem, including a gateway quiz.  If there
    # are other answers in the problem, this may cause issues with the order of the answers in
    # the results table as NEW_ANS_NAME records the answer now.  If that is the case you may use
    # any name you want, but make sure that you prefix it with $PG->{QUIZ_PREFIX}.
    # (Eg: $answerBox = $PG->{QUIZ_PREFIX} . 'answerBox';)
    ###################################

    $answerBox = NEW_ANS_NAME();

    ###################################
    # Create the perlApplet object
    ###################################

    $applet = GeogebraWebApplet(
        appletName => $appletName,
        onInit => 'myUniqueAppletOnInit',
        answerBoxAlias => $answerBox,
        submitActionScript => qq{ getQE('$answerBox').value = getAppletValues() },
        selfLoading => 1,
        params => {
            ggbBase64 => "...", // The long base 64 encoded string for your applet.
            enableShiftDragZoom => "false",
            enableRightClick => "false" ,
            enableLabelDrags => "false",
            showMenuBar => "false" ,
            showToolBar => "false",
            showAlgebraInput => "false",
            useBrowserForJS => "true", // Required or the onInit handler will not be called.
        },
    );

    ###################################
    # Add additional JavaScript functions to header section of HTML.
    ###################################

    $applet->header(<<'END_HEADER');
    <script>
        // The applet name is passed to this function, although it is not really neccessary to
        // check it, as the method will only be called for this applet.  The applet name is only
        // provided for backwards compatibility.
        function myUniqueAppletOnInit(appletName) {
            applet_loaded(param,1);  // report that applet is ready. 
            ww_applet_list[param].safe_applet_initialize(2);
        }
        function getAppletValues() {
            var applet = getApplet("$appletName");
            ...
            JavaScript code to extract answer from applet
            ...
            return answer;
        }
    </script>
    END_HEADER

    ###################################
    # Write the text for the problem
    ###################################

    BEGIN_TEXT

    The applet will appear below.  You can put other problem text here.

    $PAR
    \{ $applet->insertAll(debug => 0, reinitialize_button => 0, includeAnswerBox => 1) \}
    $PAR

    More problem text.

    END_TEXT

    LABELED_ANS($answerBox, $ans->cmp);

    ENDDOCUMENT();

=cut
