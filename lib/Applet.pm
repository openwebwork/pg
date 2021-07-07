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

Applet.pl - Provides code for inserting FlashApplets, JavaApplets, CanvasApplets, and
GeogebraWebApplets into webwork problems

=head1 SYNPOSIS

    ###################################
    # Create the applet object
    ###################################
    $appletName = "PointGraph";
    $applet = FlashApplet(
        codebase           => findAppletCodebase("$appletName.swf"),
        appletName         => $appletName,
        setStateAlias      => 'setXML',
        getStateAlias      => 'getXML',
        setConfigAlias     => 'config',
        answerBoxAlias     => 'answerBox',
        submitActionScript => qq{ getQE('answerBox').value = getApplet("$appletName").getAnswer() },
    );

    ###################################
    # Configure applet
    ###################################

    # Data to set up the equation
    $applet->configuration(qq{<XML expr='(x - $a)^3 + $b/$a * x' />});
    # Initial points
    $applet->intialState(qq{<XML> </XML>});

    ###################################
    # Insert applet into body
    ###################################

    BEGIN_TEXT
    \{ $applet->insertAll(includeAnswerBox => 1, debug => 0, reinitialize_button => 1) \}
    END_TEXT

=head1 DESCRIPTION

This file provides an object to store in one place all of the information needed to call an
applet.

The module FlashApplet has defaults for inserting flash applets.

The module JavaApplet has defaults for inserting java applets.

The module CanvasApplet has defaults for inserting HTML 5 canvas applets.

The module GeogebraWebApplet has defaults for inserting Geogebra web applets.

The module Applet stores common code for the different types of applets.

=cut

package Applet;
use URI::Escape;
use MIME::Base64 qw(encode_base64 decode_base64);
use PGcore;
@ISA = qw(PGcore);

=head2 Default JavaScript functions placed in header

=pod

These JavaScript functions are defined for use by any JavaScript placed in the text of a PG
question.

    getApplet(appletName)    -- finds the applet path in the DOM

    getQE(name)              -- gets an HTML element of the question by name or by id.  Be sure
                                to keep all names and ids unique within a given PG question.

    getQuestionElement(name) -- long form of getQE(name)

    listQuestionElements()   -- for discovering the names of inputs in the PG question.  An
                                alert dialog will list all of the elements.

        Usage: Place this at the END of the question, just before END_DOCUMENT():

                TEXT(qq!<script>listQuestionElements()</script>!);
                ENDDOCUMENT();

        to obtain a list of all of the HTML elements in the question

=head2 List of options for the Applet class:

    These options can be set using the accessor methods defined in the class.

    Usage:  $current_value = $applet->method(new_value or empty)

    These can also be set when creating the class.  For example:
        $applet = new FlashApplet(
            codebase          => findAppletCodebase("$appletName.swf"),
            appletName        => $appletName,
            submitActionAlias => 'checkAnswer'
        );

    When using AppletObjects.pl this can be replaced by $applet = FlashApplet(...).

    appletName   The name of the applet

    archive      The name of the .jar file containing the applet code
                 (only used for java applets)

    code         The name of the applet code in the .jar archive
                 (only used for java applets)

    codebase     A prefix url used to find the archive and the applet itself.
                 (only used for flash or java applets)

    params       A reference to a hash containing name/value pairs to configure the applet.
                 For example: { name => 'value', ... }

    width        (default: 550) Width of the html element that will contain the applet.
    height       (default: 400) Height of the html element that will contain the applet.

    bgcolor      (default: "#869ca7") Background color of the applet rectangle.
                 (only used for flash or java applets)

    type         The type of the applet (must be one of 'flash', 'java', 'html5canvas', or
                 'geogebraweb')

    header       Stores the text to be added to the header section of the html page.  Calling
                 $applet->header('reset') sets the header to '', and calling
                 $applet->header('text to add', 'more text', ...) appends the arguments to the
                 current value of header.

    objectText   Stores the text which places the applet on the html page.  The accessor function
                 is named 'object'.  Calling $applet->object('reset') sets the objectText to '',
                 and calling $applet->object('text to add', 'more text', ...) appends the
                 arguments to the current value of objectText.

    configuration  Configuration contains those customizable attributes of the applet which
                   don't change as it is used.  When stored in hidden answer fields it is
                   usually stored in base64 encoded format.

    initialState   The state consists of those customizable attributes of the applet which
                   change as the applet is used by the student.  It is stored by the calling
                   pg question so that when revisiting the question the applet will be
                   restored to the same state it was left in when the question was last
                   viewed.

    getStateAlias  (default: 'getXML') Alias for command called to read the current state of
                   the applet.  The state is passed in plain text xml format with outer
                   tags: <xml>...</xml>

    setStateAlias  (default: 'setXML') Alias for the command called to reset the state of
                   the applet.  The state is passed in plain text in xml format with outer
                   tags: <xml>...</xml>

    getConfigAlias (default: 'getConfig') Retrieves the configuration from the applet.
                   This is used mainly for debugging.  In principal the configuration
                   remains the same for a given instance of the applet -- i.e. for the
                   homework question for a single student.  The state however will change
                   depending on the interactions between the student and the applet.

    setConfigAlias (default: 'setConfig') Names the applet command called with the contents
                   of $self->setConfig to configure the applet.  The parameters are passed
                   to the applet in plain text using <xml>.  The outer tags must be
                   <xml>...</xml>.

    initializeActionAlias  (default: 'setXML') The name of the JavaScript subroutine
                           called to initialize the applet (some overlap with config/ and
                           setState).

    maxInitializationAttempts  (default: 5) Number attempts to test applet to see if it is
                               installed.  If isActive() exists then the WW question waits
                               until the return value is 1 before calling the applet's
                               confguration commands.  Because some applets have isActive
                               return 0 even when they are ready, if isActive() exists but
                               does not return 1 then the applet's configuration commands
                               are called after maxInitializationAttempts number of times.
                               If none of the configuration commands of the applet can be
                               detected then the WW question gives up after
                               maxInitializationAttempts.

    submitActionAlias  (default: 'getXML') Applet subroutine called when the submit button of
                       the pg question is pressed.

    submitActionScript (default: '') Javascript code to be execute when problem answers are
                       submitted.  For example:
                           qq{ getQE('answerBox').value = getApplet("$appletName").getAnswer() }

    answerBoxAlias    (default: 'answerBox') Name of answer box to return answer to.

    onInit            (default: '') This can either be the name of a global JavaScript function
                      that will be called to initialize the applet, or JavaScript code that will
                      be executed to initialize the applet.  For Geogebra web applets if this is
                      the name of a global JavaScript function defined in the problem, it should
                      NOT be named ggbOnInit.  (For WeBWorK versions 2.15 and before the global
                      JavaScript function had to be named ggbOnInit, and this parameter was
                      boolean in usage.)

    debugMode         (default: 0)
                      For debugMode == 1 the answerBox and the box preserving the applet
                      state between questions are made visible along with some buttons for
                      manually getting the state of the applet and setting the state of the
                      applet.

                      For debugMode==2, in addition to the answerBox and stateBox there are
                      several alerts which mark progress through the procedures of calling
                      the applet.  Useful for troubleshooting where in the chain of command
                      a communication failure occurs

=head2 List of methods made available by the Applet class:

    insertHeader    Inserts text in header section of HTML page
    insertObject    Inserts <article></article> tag in body of the HTML page
    insertAll       (defined in AppletObject.pl) Installs applet by inserting both header
                    text and the object text

        Usage:    $applet->insertAll(
                          includeAnswerBox     => 0,
                          debugMode            => 0,
                          reinitialize_button  => 0
                  );

=cut

=head2 More details

There are three different "images" of the applet.  The first is the applet itself.  The object
that actually does the work.  The second is a perl image of the applet (henceforth the
perlApplet) which is configured in the pg file and allows a WeBWorK question to communicate with
the applet.  The third image is a JavaScript image of the applet (henceforth the jsApplet) which
is a mirror of the perlApplet but is available to the JavaScript code setup and executed in the
virtual HTML page defined by the pg file of the WeBWorK question. One can think of the jsApplet
as a runtime version of the perlApplet since it can be accessed and modified after the virtual
HTML page has been created by the PG rendering process.

The perlApplet is initialized by
    $newApplet = new flashApplet(appletName => 'myApplet', ...);
The jsApplet is automatically defined in ww_applet_list["myApplet"] by copying the instance
variables of $newApplet to a corresponding JavaScript object.  So $newApplet->{appletName}
corresponds to ww_applet_list["myApplet"].appletName.  (This paragraph is not yet fully
implemented :-().

Currently all messages read by the applet are xml text.  If some of the code needs to be printed
in the HTML header than it is converted to a base64 constant and then converted back to text
form when it is read by a JavaScript subroutine.

The perlApplet has  methods that help place the jsApplet code on the HTML page and create the
link to the applet itself.  In particular instance variables such as "setStateAlias",
"getStateAlias" connect the WW default of "setState" to subroutine name chosen by the applet
designer.  The aim is to make it easier to connect to applets previously designed to work with
JavaScript in an HTML page or other  systems.

The jsApplet acts as an intermediary for commands directed at the applet.  It is not necessary
for the minimal operations of configuring the applet and maintaining state from one viewing of
the WW question to address the applet directly.  The methods such as "setState", "getState",
"setConfig" which are part of the jsApplet take care of the book keeping details.  It is also
possible to make direct calls to the applet from handcrafted JavaScript subroutines, but it may
be convenient to store these as additional methods in the jsApplet.

=cut

=head3 Detecting that the applet is ready

Timing issues are among the pitfalls awaiting when using flash or java applets in WW questions.
It is important that the WW question does not issue any commands to the applet until the applet
is fully loaded, including the uploading of any additional configuration information from XML
files.  This can be tricky since the timing issues usually don't arise when initiating the
applet from an HTML page.

The WW API performs the following actions to determine if the applet is loaded:

    Check the ww_applet_list[appletName].isReady flag (1 == applet is ready).
        -- This caches the readiness information so that it doesn't have to be repeated within a
           given viewing of a WW question If this is 1 then the applet is ready.

    Determine whether the applet's isActive subroutine is defined AND returns 1 when called.
        -- If the return value is 1 the applet is ready, if it is zero or no response then the
           applet is NOT ready
        -- If the applet has an isActive() subroutine (there is no alias for this) then it must
           return 1 as soon as the applet is ready.  Otherwise the applet will timeout.

    Determine whether the applet's setConfig subroutine is defined.
        -- $applet->{setConfigAlias}

    Determine whether the applet's setState subroutine is defined.

    Determine whether the jsApplet's ww_applet_list[appletName].reportsLoaded flag is set to 1
        -- This can be set by the applet if it calls the JavaScript function
           applet_loaded(appletName, loaded_status).  The loaded_status is 1 or 0.

    Logic for determining applet status:
        If any one of the above checks succeeds (or returns 1) then the applet is consdered to
        be ready UNLESS the isActive() exists and the call returns a 0 or no response. In this
        case the applet is assumed to be loading additional data and is not yet ready.

        For this reason if the isActive subroutine is defined in the applet it must return a 1
        once the applet is prepared to accept additional commands.

        (Since there are some extent flashApplets with non-functioning isActive() subroutines a
        temporary workaround assumes that after C<maxInitializationAttempts> (5 by default) the
        applet is in fact ready but the isActive() subroutine is non functioning.  This can give
        rise to false "readiness" signals if the applet takes a long time to load auxiliary
        files.)

The applet itself can take measures to insure that the setConfig subroutine is prepared to
respond immediately once the applet is loaded.  It can include timers that delay execution of
the configuring actions until all of the auxiliary files needed by the applet are loaded.

=cut

=head3 Instance variables in the JavaScript applet ww_applet_list[appletName]

    Most of the instance variables in the perl version of the applet are transferred to the
    JavaScript applet

=cut

=head3 Methods defined for the JavaScript applet ww_applet_list[appletName]

This is not a comprehensive list

    setConfig  -- Transmits the information for configuring the applet.

    getConfig  -- Retrieves the configuration information -- this is used mainly for debugging
                  and may not be defined in most applets.

    setState   -- Sets the current state (1) from the appletName_state HTML element if this
                  contains an <xml>...</xml> string.
               -- If the value contains <xml>restart_applet</xml> then set the current state to
                  ww_applet_list[appletName].initialState
               -- If the value is a blank string set the current state to
                  ww_applet_list[appletName].initialState

    getState   -- Retrieves the current state and stores in the appletName_state HTML element.

=cut

=head3 Requirements for applets

The following methods are desirable in an applet that preserves state in a WW question.  None of
them are required.

    setState(str)   (default: setXML)
                    -- Set the current state of the applet from an xml string.
                    -- Should be able to accept an empty string or a string of the form
                       <XML>...</XML> without creating errors.
                    -- Can be designed to receive other forms of input if it is coordinated with
                       the WW question.

    getState()      (default: getXML)
                    -- Return the current state of the applet in an xml string.
                    -- An empty string or a string of the form <XML>...</XML> are the standard
                       responses.
                    -- Can be designed to return other strings if it is coordinated with the WW
                       question.

    setConfig(str)  (default: setConfig)
                    -- If the applet allows configuration this configures the applet from an xml
                       string.
                    -- Should be able to accept an empty string or a string of the form
                       <xml>...</xml> without creating errors.
                    -- Can be designed to receive other forms of input if it is coordinated with
                       the WW question.

    getConfig       (default: getConfig)
                    -- This returns a string defining the configuration of the applet in an xml
                       string.
                    -- An empty string or a string of the form <XML>...</XML> are the standard
                       responses.
                    -- Can be designed to return other strings if it is coordinated with the WW
                       question.
                    -- This method is used for debugging to ensure that the configuration was
                       set as expected.

    getAnswer       (default: getAnswer)
                    -- Returns a string (usually NOT xml) which is the response that the student
                    is effectvely submitting to answer the WW question.

=cut

=head3 Initialization sequence

When the WW question is loaded a JavaScript load event handler calls each of the applets used in
the question asking them to initialize themselves.

The applets initialization method is as follows:

    -- Wait until the applet is loaded and the applet has loaded all of its auxiliary files.
    -- Set the debugMode in the applet.
    -- Call the setConfig method in the JavaScript applet
       (configuration parameters are "permanent" for the life of the applet).
    -- Call the setInitialization method in the JavaScript applet.  This often calls the
       setState method in the applet

=cut

=head3 Submit sequence

When the WW question submit button is pressed the form containing the WW question calles the
JavaScript "submitAction()" which then asks each of the applets on the page to perform its
submit action which consists of

    -- If the applet is to be reinitialized (appletName_state contains
       <xml>restart_applet</xml>) then the HTML elements appletName_state and
       previous_appletName_state are set to <xml>restart_applet</xml> to be interpreted by the
       next setState command.
    -- Otherwise getState() from the applet and save it to the HTML input element
       appletName_state.
    -- Perform the JavaScript commands in submitActionScript (default: '').
       A typical submitActionScript looks like:
           getQE(this.answerBox).value = getApplet(appletName).getAnswer()

=cut

sub new {
	my $class = shift;
	my $self = {
		appletName                => '',
		archive                   => '',
		code                      => '',
		codebase                  => '',
		params                    => undef,
		width                     => 550,
		height                    => 400,
		bgcolor                   => "#869ca7",
		type                      => '',
		visible                   => 0,
		configuration             => '', # configuration defining the applet
		initialState              => '', # initial state.
		getStateAlias             => 'getXML',
		setStateAlias             => 'setXML',
		configAlias               => '', # deprecated
		getConfigAlias            => 'getConfig',
		setConfigAlias            => 'setConfig',
		initializeActionAlias     => 'setXML',
		maxInitializationAttempts => 5, # number of attempts to initialize applet
		submitActionAlias         => 'getXML',
		submitActionScript        => '', # script executed on submitting the WW question
		answerBoxAlias            => 'answerBox',
		onInit                    => '',
		answerBox                 => '', # deprecated
		returnFieldName           => '', # deprecated
		headerText                => DEFAULT_HEADER_TEXT(),
		objectText                => '',
		debugMode                 => 0,
		selfLoading               => 0,
		@_,
	};
	bless $self, $class;
	$self->initialState('<xml></xml>');
	# Backward compatibility and deprecation warnings.
	if ($self->{returnFieldName} || $self->{answerBox}) {
		warn "use answerBoxAlias instead of returnFieldName or answerBox";
		$self->{answerBox} = '';
		$self->{returnFieldName} = '';
	}
	if ($self->{configAlias}) {
		warn "use setConfigAlias instead of configAlias";
		$self->{configAlias} = '';
	}
	$self->configuration('<xml></xml>');
	return $self;
}

# Accessor methods

sub appletName {
	my $self = shift;
	$self->{appletName} = shift || $self->{appletName};
	$self->{appletName};
}

sub archive {
	my $self = shift;
	$self->{archive} = shift || $self->{archive};
	$self->{archive};
}

sub code {
	my $self = shift;
	$self->{code} = shift || $self->{code};
	$self->{code};
}

sub codebase {
	my $self = shift;
	$self->{codebase} = shift || $self->{codebase};
	$self->{codebase};
}

sub params {
	my $self = shift;
	if (ref($_[0]) =~ /HASH/) {
		$self->{params} = shift;
	} elsif (defined($_[0])) {
		warn "You must enter a reference to a hash for the parameter list";
	}
	$self->{params};
}

sub width {
	my $self = shift;
	$self->{width} = shift || $self->{width};
	$self->{width};
}

sub height {
	my $self = shift;
	$self->{height} = shift || $self->{height};
	$self->{height};
}

sub bgcolor {
	my $self = shift;
	$self->{bgcolor} = shift || $self->{bgcolor};
	$self->{bgcolor};
}

sub  header {
	my $self = shift;
	# $applet->header('reset'); erases default header text.
	if ($_[0] eq "reset") {
		$self->{headerText} = '';
	} else {
		# $applet->header(new_text); concatenates new_text to existing header.
		$self->{headerText} .= join("", @_);
	}
	$self->{headerText};
}

sub  object {
	my $self = shift;
	if ($_[0] eq "reset") {
		$self->{objectText} = '';
	} else {
		$self->{objectText} .= join("", @_);
	}
	$self->{objectText};
}

sub configuration {
	my $self = shift;
	$self->{configuration} =  shift || $self->{configuration};
	$self->{configuration} =~ s/\n//g;
	$self->{configuration};
}

sub initialState {
	my $self = shift;
	$self->{initialState} = shift || $self->{initialState};
	$self->{initialState};
}

sub getStateAlias {
	my $self = shift;
	$self->{getStateAlias} = shift || $self->{getStateAlias};
	$self->{getStateAlias};
}

sub setStateAlias {
	my $self = shift;
	$self->{setStateAlias} = shift || $self->{setStateAlias};
	$self->{setStateAlias};
}

sub getConfigAlias {
	my $self = shift;
	$self->{getConfigAlias} = shift || $self->{getConfigAlias};
	$self->{getConfigAlias};
}

sub setConfigAlias {
	my $self = shift;
	$self->{setConfigAlias} = shift || $self->{setConfigAlias};
	$self->{setConfigAlias};
}

sub initializeActionAlias {
	my $self = shift;
	$self->{initializeActionAlias} = shift || $self->{initializeActionAlias};
	$self->{initializeActionAlias};
}

sub maxInitializationAttempts {
	my $self = shift;
	$self->{maxInitializationAttempts} = shift || $self->{maxInitializationAttempts};
	$self->{maxInitializationAttempts};
}

sub submitActionAlias {
	my $self = shift;
	$self->{submitActionAlias} = shift || $self->{submitActionAlias};
	$self->{submitActionAlias};
}

sub submitActionScript {
	my $self = shift;
	$self->{submitActionScript} = shift || $self->{submitActionScript};
	$self->{submitActionScript};
}

sub answerBoxAlias {
	my $self = shift;
	$self->{answerBoxAlias} = shift || $self->{answerBoxAlias};
	$self->{answerBoxAlias};
}

sub onInit {
	my $self = shift;
	$self->{onInit} = shift || $self->{onInit};
	$self->{onInit};
}

sub debugMode {
	my $self = shift;
	$self->{debugMode} = $_[0] if defined($_[0]);
	$self->{debugMode};
}

#######################
# Soon to be deprecated?
#######################

sub returnFieldName {
	my $self = shift;
	warn "use answerBoxName instead of returnFieldName";
}

sub answerBox {
	my $self = shift;
	warn "use answerBoxAlias instead of AnswerBox";
}

sub configAlias {
	my $self = shift;
	warn "use setConfigAlias instead of configAlias";
}

# FIXME
# Need to be able to adjust header material.

sub insertHeader {
	my $self = shift;

	my $type                  = $self->{type};
	my $codebase              = $self->codebase;
	my $appletName            = $self->appletName;
	my $initializeActionAlias = $self->initializeActionAlias;
	# Replace newlines and returns with spaces. These can cause trouble in the JavaScript.
	my $submitActionScript    = $self->submitActionScript =~ s/\n|\r/ /gr;
	my $setStateAlias         = $self->setStateAlias;
	my $getStateAlias         = $self->getStateAlias;

	my $setConfigAlias        = $self->setConfigAlias;
	my $getConfigAlias        = $self->getConfigAlias;
	my $maxInitializationAttempts = $self->maxInitializationAttempts;
	my $debugMode             = ($self->debugMode) ? "1": "0";
	my $answerBoxAlias        = $self->{answerBoxAlias};
	my $stateInput            = $self->{stateInput};
	# Function to call or code to execute to initialize the applet.
	my $onInit                = encode_base64($self->{onInit} =~ s/\n|\r/ /gr) =~ s/\n//gr;
	my $selfLoading           = $self->{selfLoading};

	my $base64_submitActionScript = encode_base64($submitActionScript) =~ s/\n//gr;
	# These are base64 encoded xml.
	my $base64_configuration = encode_base64($self->configuration) =~ s/\n//gr;
	my $base64_initialState = encode_base64($self->initialState) =~ s/\n//gr;

	my $headerText = $self->header();
	$headerText =~ s/(\$\w+)/$1/gee;
	return $headerText;
}

########################################################
# HEADER material for the jsApplet
########################################################

use constant DEFAULT_HEADER_TEXT => <<'END_HEADER_SCRIPT';
<script>
// JS OBJECT CODE

ww_applet_list["$appletName"] = new ww_applet("$appletName");

ww_applet_list["$appletName"].type                      = "$type";
ww_applet_list["$appletName"].code                      = "$code";
ww_applet_list["$appletName"].codebase                  = "$codebase";
ww_applet_list["$appletName"].base64_state              = "$base64_initialState";
ww_applet_list["$appletName"].initialState              = Base64.decode("$base64_initialState");
ww_applet_list["$appletName"].configuration             = Base64.decode("$base64_configuration");;
ww_applet_list["$appletName"].getStateAlias             = "$getStateAlias";
ww_applet_list["$appletName"].setStateAlias             = "$setStateAlias";
ww_applet_list["$appletName"].setConfigAlias            = "$setConfigAlias";
ww_applet_list["$appletName"].getConfigAlias            = "$getConfigAlias";
ww_applet_list["$appletName"].initializeActionAlias     = "$initializeActionAlias";
ww_applet_list["$appletName"].submitActionAlias         = "$submitActionAlias";
ww_applet_list["$appletName"].submitActionScript        = Base64.decode("$base64_submitActionScript");
ww_applet_list["$appletName"].answerBoxAlias            = "$answerBoxAlias";
ww_applet_list["$appletName"].stateInput                = "$stateInput";
ww_applet_list["$appletName"].maxInitializationAttempts = $maxInitializationAttempts;
ww_applet_list["$appletName"].debugMode                 = $debugMode;
ww_applet_list["$appletName"].reportsLoaded             = $selfLoading;
ww_applet_list["$appletName"].isReady                   = $selfLoading;
ww_applet_list["$appletName"].onInit                    = Base64.decode("$onInit");
</script>
END_HEADER_SCRIPT

sub insertObject {
	my $self = shift;

	my $code           = $self->{code};
	my $codebase       = $self->{codebase};
	my $appletName     = $self->{appletName};
	my $archive        = $self->{archive};
	my $width          = $self->{width};
	my $height         = $self->{height};
	my $applet_bgcolor = $self->{bgcolor};
	my $selfLoading    = $self->{selfLoading};

	my $javaParameters = '';
	my $flashParameters = '';
	my $webgeogebraParameters = '';

	if (PGUtil::not_null($self->{parameter_string})) {
		$javaParameters = $self->{parameter_string};
		$flashParameters = $self->{parameter_string};
		$webgeogebraParameters = $self->{parameter_string};
	} else {
		my %param_hash = %{$self->params()};

		foreach my $key (keys %param_hash) {
			$javaParameters .= qq!<param name="$key" value="$param_hash{$key}">\n!;
			$flashParameters .= uri_escape($key) . '=' . uri_escape($param_hash{$key}) . '&';
			$webgeogebraParameters .= qq!data-param-$key = "$param_hash{$key}"\n!;
		}
		$flashParameters =~ s/\&$//; # trim last &
		$webgeogebraParameters = qq!<article class="geogebraweb"
			data-param-id     = "$appletName"
			data-param-width  = "$width"
			data-param-height = "$height"
			!. $webgeogebraParameters . qq!\n></article>!;
	}

	my $objectText = $self->{objectText};
	$objectText =~ s/(\$\w+)/$1/gee;
	# Don't submit things if not visible
	$objectText .= qq{<script>ww_applet_list["$appletName"].visible = 1;</script>};
	return $objectText;
}

################################################################################################
# FLASH APPLET PACKAGE
################################################################################################

package FlashApplet;
@ISA = qw(Applet);

=head2 Insertion HTML code for FlashApplet

=pod

    use constant FLASH_OBJECT_TEXT =><<'END_OBJECT_TEXT';
    <object classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000"
            id="$appletName"  width="500" height="375"
            codebase="http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab">
    <param name="movie" value="$codebase/$appletName.swf" />
    <param name="quality" value="high" />
    <param name="bgcolor" value="$applet_bgcolor" />
    <param name="allowScriptAccess" value="sameDomain" />
    <param name="FlashVars" value="$flashParameters"/>
    <embed src="$codebase/$appletName.swf" quality="high" bgcolor="$applet_bgcolor"
           width="$width" height="$height" name="$appletName"  align="middle" id="$appletName"
           play="true" loop="false" quality="high" allowScriptAccess="sameDomain"
           type="application/x-shockwave-flash"
           pluginspage="http://www.macromedia.com/go/getflashplayer"
           FlashVars="$flashParameters">
    </embed>
    </object>
    END_OBJECT_TEXT

=cut

use constant FLASH_OBJECT_TEXT =><<'END_OBJECT_TEXT';
<object classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000"
        id="$appletName"  width="500" height="375"
        codebase="http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab">
<param name="movie" value="$codebase/$appletName.swf" />
<param name="quality" value="high" />
<param name="bgcolor" value="$applet_bgcolor" />
<param name="allowScriptAccess" value="sameDomain" />
<param name="FlashVars" value="$flashParameters"/>
<embed src="$codebase/$appletName.swf" quality="high" bgcolor="$applet_bgcolor"
       width="$width" height="$height" name="$appletName"  align="middle" id="$appletName"
       play="true" loop="false" quality="high" allowScriptAccess="sameDomain"
       type="application/x-shockwave-flash"
       pluginspage="http://www.macromedia.com/go/getflashplayer"
       FlashVars="$flashParameters">
</embed>
</object>
END_OBJECT_TEXT

sub new {
	my $class = shift;
	$class->SUPER::new(
		objectText => FLASH_OBJECT_TEXT(),
		type       => 'flash',
		@_
	);
}

################################################################################################
# JAVA APPLET PACKAGE
################################################################################################

package JavaApplet;
@ISA = qw(Applet);

=head2 Insertion HTML code for JavaApplet

=pod

    use constant JAVA_OBJECT_TEXT => <<'END_OBJECT_TEXT';

    <applet
        code     = "$code"
        codebase = "$codebase"
        archive  = "$archive"
        name     = "$appletName"
        id       = "$appletName"
        width    = "$width"
        height   = "$height"
        bgcolor  = "$applet_bgcolor"
        mayscript = "true";
    >
    $javaParameters

    Sorry, the Applet could not be started. Please make sure that
    Java 1.4.2 (or later) is installed and activated.
    (<a href="http://java.sun.com/getjava">click here to install Java now</a>)
    </applet>
    END_OBJECT_TEXT

=cut

use constant JAVA_OBJECT_TEXT => <<'END_OBJECT_TEXT';
<applet
    id       = "$appletName"
    name     = "$appletName"
    code      = "$code"
    type     = "application/x-java-applet"
    codebase = "$codebase"
    archive  = "$archive"
    height   = "$height"
    width    = "$width"
    bgcolor  = "$applet_bgcolor"
    mayscript = "true"
>
<PARAM NAME="MAYSCRIPT" VALUE="true">
$javaParameters

Sorry, the Applet could not be started. Please make sure that
Java 1.4.2 (or later) is installed and activated.
(<a href="http://java.sun.com/getjava">click here to install Java now</a>)
</applet>
END_OBJECT_TEXT

sub new {
	my $class = shift;
	$class->SUPER::new(
		objectText => JAVA_OBJECT_TEXT(),
		type       => 'java',
		@_
	);
}

###############################################################################################################
# CANVAS APPLET PACKAGE
###############################################################################################################

package CanvasApplet;
@ISA = qw(Applet);

=head2 Insertion HTML code for CanvasApplet

=pod

    use constant CANVAS_OBJECT_TEXT => <<'END_OBJECT_TEXT';
    <canvas name="cv" id="cv"
            data-src="/webwork2_files/js/legacy/sketchgraphhtml5b/SketchGraph.pjs"
            width="$width" height="$height">
    </canvas>
    END_OBJECT_TEXT

=cut

# FIXME need to get rid of hardcoded url
use constant CANVAS_OBJECT_TEXT => <<'END_OBJECT_TEXT';
<canvas name="cv" id="cv"
        data-src="/webwork2_files/js/legacy/sketchgraphhtml5b/SketchGraph.pjs"
        width="$width" height="$height">
</canvas>
END_OBJECT_TEXT

sub new {
	my $class = shift;
	$class->SUPER::new(
		objectText => CANVAS_OBJECT_TEXT(),
		type       => 'html5canvas',
		@_
	);
}

###############################################################################################################
# GeogebraWeb APPLET PACKAGE
###############################################################################################################

package GeogebraWebApplet;
@ISA = qw(Applet);

=head2 Insertion HTML code for GeogebraWebApplet

=pod

    use constant GEOGEBRAWEB_OBJECT_TEXT => <<'END_OBJECT_TEXT';
    <div class="enclose_geogebra_object">
    <div class="geogebra_object">
    $webgeogebraParameters
    </div>
    </div>
    END_OBJECT_TEXT

=cut

# Some changes in the way geogebra JavaScript works make it important That the object and the
# script that calls it are contained in some <div> (otherwise geogebra adds height and width
# values to the second enclosing <div> (i.e. the div enclosing the enclosing div) and if the div
# contains more than just the geogebra applet this size will be incorrect. ) (This behavior is
# probably a bug in geogebra -- but I don't have a precise statement of the API.) The <div
# class="enclose_geogebra_object> and <div class="geogebra_object" do nothing for now but
# perhaps they might have a use later. style="height:306 ptx,width: 486 ptx" is inserted in the
# class="enclose_geogebra_object" div by the geogebra applet.

use constant GEOGEBRAWEB_OBJECT_TEXT => <<'END_OBJECT_TEXT';
<div class="enclose_geogebra_object">
<div class="geogebra_object">
$webgeogebraParameters
</div>
</div>
END_OBJECT_TEXT

sub new {
	my $class = shift;
	$class->SUPER::new(
		objectText => GEOGEBRAWEB_OBJECT_TEXT(),
		type       => 'geogebraweb',
		@_
	);
}

1;
