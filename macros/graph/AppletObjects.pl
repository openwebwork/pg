
=head1 NAME

AppletObjects.pl - Macro-based front end for the Applet.pm module.

=head1 DESCRIPTION

The subroutines in this file provide mechanisms to insert Geogebra web applets
into a WeBWorK problem.

See also L<Applet.pm>.

=cut

# Add basic functionality to the header of the question
sub _AppletObjects_init {
	ADD_JS_FILE("js/AppletSupport/ww_applet_support.js");
}

=head2  GeogebraWebApplet

Usage:    C<$applet = GeogebraWebApplet(...);>

=cut

sub GeogebraWebApplet {
	ADD_JS_FILE("https://cdn.geogebra.org/apps/deployggb.js", 1);
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

=head2 insertAll

Usage:  C<S<< TEXT($applet->insertAll()); >>>

    \{ $applet->insertAll() \}  (used within BEGIN_TEXT/END_TEXT blocks)

Inserts applet at this point in the HTML code.  (In TeX mode a message "Applet" is written.)
This method also adds the applets header material into the header portion of the HTML page. It
effectively inserts the outputs of both C<$applet-E<gt>insertHeader> and
C<$applet-E<gt>insertObject> (defined in L<Applet.pm>) in the appropriate places. In addition it
creates a hidden answer blank for storing the state of the applet.

=cut

# Inserts both header text and object text.
sub insertAll {
	my ($self, %options) = @_;

	# Prepare html code for storing state.
	my $appletName = $self->appletName;
	# The name of the hidden "answer" blank storing state.
	$self->{stateInput} = "$main::PG->{QUIZ_PREFIX}${appletName}_state";

	# This insures that the state will be saved from one invocation to the next.
	my $answer_value = ${$main::inputs_ref}{ $self->{stateInput} } // '';
	if ($answer_value !~ /\S/ && defined(my $persistent_data = main::persistent_data($self->{stateInput}))) {
		$answer_value = $persistent_data;
	}
	$answer_value =~ tr/\\$@`//d;    # Make sure student answers cannot be interpolated by e.g. EV3
	$answer_value =~ s/\s+/ /g;      # Remove excessive whitespace from student answer

	# Regularize the applet's state which could be in either XML format or in XML format encoded by base64.
	# In rare cases it might be a simple string.  Protect against that by putting xml tags around the state.
	my $base_64_encoded_answer_value;
	my $decoded_answer_value;
	if ($answer_value =~ /<\??xml/i) {
		$base_64_encoded_answer_value = $self->base64_encode($answer_value);
		$decoded_answer_value         = $answer_value;
	} else {
		$decoded_answer_value = $self->base64_decode($answer_value);
		if ($decoded_answer_value =~ /<\??xml/i) {
			$base_64_encoded_answer_value = $answer_value;
		} else {
			$answer_value                 = "<xml>$answer_value</xml>";
			$base_64_encoded_answer_value = $self->base64_encode($answer_value);
			$decoded_answer_value         = $answer_value;
		}
	}
	$base_64_encoded_answer_value =~ s/\r|\n//g;    # Get rid of line returns

	main::persistent_data($self->{stateInput} => $base_64_encoded_answer_value);

	# Construct the reset button string (this is blank if the button is not to be displayed).
	my $reset_button_str = $options{reinitialize_button}
		? main::tag(
			'button',
			type               => 'button',
			class              => 'btn btn-primary applet-reset-btn mt-3',
			'data-applet-name' => $appletName,
			'Return this question to its initial state'
		)
		: '';

	# Construct the state storage hidden input.
	my $state_storage_html_code = main::tag(
		'input',
		type  => 'hidden',
		name  => $self->{stateInput},
		id    => $self->{stateInput},
		value => $base_64_encoded_answer_value
	);

	# Construct the answerBox (if it is requested).  This is a default input box for interacting
	# with the applet.  It is separate from maintaining state but it often contains similar
	# data.  Additional answer boxes or buttons can be defined but they must be explicitly
	# connected to the applet with additional JavaScript commands.
	my $answerBox_code = $options{includeAnswerBox} ? main::NAMED_HIDDEN_ANS_RULE($self->{answerBoxAlias}, 50) : '';

	# Insert header material
	main::HEADER_TEXT($self->insertHeader());

	# Return HTML or TeX strings to be included in the body of the page
	return main::MODES(
		TeX  => ' {\bf ' . $self->{type} . ' applet } ',
		HTML => $self->insertObject . $state_storage_html_code . $reset_button_str . $answerBox_code,
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
