################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2022 The WeBWorK Project, https://github.com/openwebwork
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

The subroutines in this file provide mechanisms to insert Geogebra web applets
into a WeBWorK problem.

See also L<Applet.pm>.

=cut

# Add basic functionality to the header of the question
sub _AppletObjects_init {
	ADD_JS_FILE("js/apps/AppletSupport/ww_applet_support.js");
}

=head3  GeogebraWebApplet

    Useage:    $applet = GeogebraWebApplet(...);

=cut

sub GeogebraWebApplet {
	ADD_JS_FILE("https://www.geogebra.org/apps/deployggb.js", 1);
	return GeogebraWebAppletBase->new(@_);
}

# Deprecated applets (these are just stubs to show a warning if used)
sub FlashApplet {
	warn 'Flash applets are no longer supported';
	return PGApplet->new(type => 'flash');
}

sub JavaApplet {
	warn 'Java applets are no longer supported';
	return PGApplet->new(type => 'java');
}

sub CanvasApplet {
	warn 'Canvas applets are no longer supported';
	return PGApplet->new(type => 'canvas');
}

package PGApplet;
our @ISA = qw(Applet);

=head1 Methods

This method is defined in this file because it uses methods in PG.pl and PGbasicmacros.pl that
are not available to Applet.pm when it is compiled (at the time the apache child process is
first initialized).

=head3  insertAll

    Useage:  TEXT($applet->insertAll());
             \{ $applet->insertAll() \}  (used within BEGIN_TEXT/END_TEXT blocks)

Inserts applet at this point in the HTML code.  (In TeX mode a message "Applet" is written.)
This method also adds the applets header material into the header portion of the HTML page. It
effectively inserts the outputs of both C<$applet-E<gt>insertHeader> and
C<$applet-E<gt>insertObject> (defined in L<Applet.pm>) in the appropriate places. In addition it
creates a hidden answer blank for storing the state of the applet.

=cut

# Inserts both header text and object text.
sub insertAll {
	my $self    = shift;
	my %options = @_;

	my $includeAnswerBox = (defined($options{includeAnswerBox}) && $options{includeAnswerBox} == 1) ? 1 : 0;

	my $reset_button = $options{reinitialize_button} || 0;

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
	my $getState  = $self->getStateAlias;
	my $setState  = $self->setStateAlias;
	my $getConfig = $self->getConfigAlias;
	my $setConfig = $self->setConfigAlias;

	my $base64_initialState = $self->base64_encode($self->initialState);
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
		$answer_value = shift(@{ $main::rh_sticky_answers->{$appletStateName} });
	}
	$answer_value =~ tr/\\$@`//d;    # Make sure student answers can not be interpolated by e.g. EV3
	$answer_value =~ s/\s+/ /g;      # Remove excessive whitespace from student answer

	# Regularize the applet's state which could be in either XML format or in XML format encoded by base64.
	# In rare cases it might be simple string.  Protect against that by putting xml tags around the state.
	# The result:
	# $base_64_encoded_answer_value -- a base64 encoded xml string
	# $decoded_answer_value         -- an xml string

	my $base_64_encoded_answer_value;
	my $decoded_answer_value;
	if ($answer_value =~ /<XML|<?xml/i) {
		$base_64_encoded_answer_value = $self->base64_encode($answer_value);
		$decoded_answer_value         = $answer_value;
	} else {
		$decoded_answer_value = $self->base64_decode($answer_value);
		if ($decoded_answer_value =~ /<XML|<?xml/i) {
			# Great, we've decoded the answer to obtain an xml string
			$base_64_encoded_answer_value = $answer_value;
		} else {
			#WTF??  apparently we don't have XML tags
			$answer_value                 = "<xml>$answer_value</xml>";
			$base_64_encoded_answer_value = $self->base64_encode($answer_value);
			$decoded_answer_value         = $answer_value;
		}
	}
	$base_64_encoded_answer_value =~ s/\r|\n//g;    # Get rid of line returns

	# Construct the reset button string (this is blank if the button is not to be displayed).
	my $reset_button_str = $reset_button
		? qq!<button type='button' class='btn btn-primary applet-reset-btn' data-applet-name="$appletName">
		Return this question to its initial state</button><br/>!
		: '';

	# Combine the state_input_button and the reset button into one string.
	my $state_storage_html_code = qq!<input type="hidden" name="previous_$appletStateName"
		id="previous_$appletStateName" value = "$base_64_encoded_answer_value">!
		. qq!<input type="hidden" name="$appletStateName" id="$appletStateName" value="$base_64_encoded_answer_value">!
		. $reset_button_str;

	# Construct the answerBox (if it is requested).  This is a default input box for interacting
	# with the applet.  It is separate from maintaining state but it often contains similar
	# data.  Additional answer boxes or buttons can be defined but they must be explicitly
	# connected to the applet with additional JavaScript commands.
	my $answerBox_code = $includeAnswerBox
		? $answerBox_code = main::NAMED_HIDDEN_ANS_RULE($self->{answerBoxAlias}, 50)
		: '';

	# Insert header material
	main::HEADER_TEXT($self->insertHeader());

	# Return HTML or TeX strings to be included in the body of the page
	return main::MODES(
		TeX  => ' {\bf ' . $self->{type} . ' applet } ',
		HTML => $self->insertObject . $main::BR . $state_storage_html_code . $answerBox_code,
		PTX  => ' applet '
	);
}

# GeogebraWeb APPLET PACKAGE
package GeogebraWebAppletBase;
our @ISA = qw(PGApplet);

sub new {
	my $class = shift;
	$class->SUPER::new(
		objectText => << 'END_OBJECT_TEXT',
<div id="$appletName"
	data-id="$appletName"
	data-width="$width"
	data-height="$height"
	$webgeogebraParameters></div>
END_OBJECT_TEXT
		type => 'geogebraweb',
		@_
	);
}

=head3 Example problem

    DOCUMENT();

    # Load macros
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
    # that use the same name, one of the applets will not work.  So to ensure uniqueness the
	# applet name should be prefixed with the quiz prefix.
    ###################################

    $appletName = $PG->{QUIZ_PREFIX} . "myUniqueAppletName";

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

    $applet->header(<<END_HEADER);
    <script>
        // The applet name is passed to this function, although it is not really neccessary to
        // check it, as the method will only be called for this applet.  The applet name is only
        // provided for backwards compatibility.
        function myUniqueAppletOnInit(appletName) {
            ww_applet_list[param].safe_applet_initialize();
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
    \{ $applet->insertAll(reinitialize_button => 0, includeAnswerBox => 1) \}
    $PAR

    More problem text.

    END_TEXT

    LABELED_ANS($answerBox, $ans->cmp);

    ENDDOCUMENT();

=cut

1;
