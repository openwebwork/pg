################################################################################
# WeBWorK Online Homework Delivery System
# Copyright © 2000-2007 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader$
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
 $appletName = "PointGraph";
$applet =  FlashApplet(
   codebase              => findAppletCodebase("$appletName.swf"),
   appletName            => $appletName,
   appletId              => $appletName,
   setStateAlias         => 'setXML',
   getStateAlias         => 'getXML',
   setConfigAlias        => 'config',
   answerBoxAlias        => 'answerBox',
   submitActionScript    => qq{ getQE('answerBox').value = getApplet("$appletName").getAnswer() },
);

###################################
# Configure applet
###################################

#data to set up the equation
$applet->configuration(qq{<XML expr='(x - $a)^3 + $b/$a * x' />});
# initial points
$applet->intialState(qq{<XML> </XML>});
###################################
#insert applet into body
###################################

TEXT( MODES(TeX=>'object code', HTML=>$applet->insertAll(
  includeAnswerBox => 1
  debug=>0,
  reinitialize_button=>1,
 )));


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
use PGcore;
@ISA = qw(PGcore);

=head2 Default javaScript functions placed in header

=pod

These functions are automatically defined for use for 
any javaScript placed in the text of a PG question.

    getApplet(appletName)     -- finds the applet path in the DOM

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


        appletId     for simplicity and reliability appletId and appletName are always the same
        appletName
        archive      the name of the .jar file containing the applet code
        code         the name of the applet code in the .jar archive
        codebase     a prefix url used to find the archive and the applet itself
        
        params       an anonymous array containing name/value pairs 
                     to configure the applet [name =>'value, ...]
                     
        width        rectangle alloted in the html page for displaying the applet
        height

		bgcolor      background color of the applet rectangle
		
        header       stores the text to be added to the header section of the html page
        object       stores the text which places the applet on the html page


        configuration  configuration contains those customizable attributes of the applet which don't 
                     change as it is used.  When stored in hidden answer fields 
                     it is usually stored in base64 encoded format.
        initialState  the state consists of those customizable attributes of the applet which change
                     as the applet is used by the student.  It is stored by the calling .pg question so that 
                     when revisiting the question the applet will be restored to the same state it was 
                     left in when the question was last viewed.
                     
        getStateAlias  (default: getState) alias for command called to read the current state of the applet.
                       The state is passed in plain text xml format with outer tags: <xml>....</xml>
        setStateAlias  (default: setState) alias for the command called to reset the  state of the applet.
                       The state is passed in plain text in xml format with outer tags: <xml>....</xml>

        configAlias   (deprecated) -- a synonym for configAlias
        
        getConfigAlias (default: getConfig) -- retrieves the configuration from the applet.  This is used
                     mainly for debugging.  In principal the configuration remains the same for a given instance
                     of the applet -- i.e. for the homework question for a single student.  The state however
                     will change depending on the interactions between the student and the applet.
        setConfigAlias (default: setConfig ) names the applet command called with the contents of $self->config
                     to configure the applet.  The parameters are passed to the applet in plain text using <xml>
                     The outer tags must be   <xml> .....   </xml>


        initializeActionAlias  -- (default: initializeAction) the name of the javaScript subroutine called 
                                  to initialize the applet (some overlap with config/ and setState
        maxInitializationAttempts -- (default: 5) number attempts to test applet to see if it is installed.
                                     If isActive() exists then the WW question waits until the return value is 1 before
                                     calling the applet's confguration commands.
                                     Because some applets have isActive return 0 even when they are ready, 
                                     if isActive() exists but does not return 1 then the applet's configuration commands
                                     are called after maxInitializationAttempts number of times.  If none of the configuration commands
                                     of the applet can be detected then the WW question gives up after maxInitializationAttempts.
                                     
        submitActionAlias      -- (default: getXML) applet subroutine called when the submit button of the
                                  .pg question is pressed.
        submitActionScript     -- (default: qq{ getQE('answerBox').value = getApplet("$appletName").getAnswer() },
        
        answerBoxAlias         -- name of answer box to return answer to: default defaultAnswerBox 
        returnFieldName        -- (deprecated) synonmym for answerBoxAlias
       
       
        debugMode              (default: 0) for debugMode==1 the answerBox and the box preserving the applet state 
                               between questions are made visible along with some buttons for manually getting the state of
                               the applet and setting the state of the applet.
                               
                               for debugMode==2, in addition to the answerBox and stateBox there are several alerts 
                               which mark progress through the procedures of calling the applet.  Useful for troubleshooting
                               where in the chain of command a communication failure occurs

       
   Methods:
       
        insertHeader          -- inserts text in header section of HTML page 
        insertObject          -- inserts <object></object> or <applet></applet>  tag in body of the HTML page
        insertAll             -- (defined in AppletObjects.pl) installs applet by inserting both header text and the object text
            Usage:    $applet->insertAll(
                              includeAnswerBox     => 0,
                              debugMode            => 0,
                              reinitialize_button  =>0,
                      );


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
to a base64 constant and then converted back to text form when it is read by a javaScript subroutine.

The perlApplet has  methods that help place the jsApplet code on the HTML page and create the link to the applet itself. 
In particular instance variables such as "setStateAlias", "getStateAlias" connect the WW default of "setState" to subroutine
name chosen by the applet designer.  The aim is to make it easier to connect to applets previously designed to work 
with javaScript in an HTML page or other  systems.


The jsApplet acts as an intermediary for commands directed at the applet.  
It is not necessary for the minimal operations of 
configuring the applet and maintaining
state from one viewing of the WW question to address the applet directly.  
The methods such as "setState", "getState", "setConfig" which are part of the jsApplet 
take care of the book keeping details.
It is also possible to make direct calls to the applet from handcrafted javaScript subroutines, 
but it may be convenient to store these as additional methods in the
jsApplet. 

=cut

=head4 Detecting that the applet is ready

Timing issues are among the pitfalls awaiting when using flash or java applets in WW questions.  It is important that the WW question
does not issue any commands to the applet until the applet is fully loaded, including the uploading of any additional configuration
information from XML files.  This can be tricky since the timing issues usually don't arise when initiating the applet from an HTML page.

The WW API performs the following actions to determine if the applet is loaded:

	check the ww_applet_list[appletName].isReady flag (1== applet is ready)
	                    -- this caches the readiness information so that it doesn't 
	                       have to be repeated within a given viewing of a WW question
	                       If this is 1 then the applet is ready.
	determine whether the applet's isActive subroutine is defined AND returns 1 when called. 
	                    -- if the return value is 1 the applet is ready, if it is zero or no response then the applet is NOT ready
	                    -- If the applet has an isActive() subroutine -- there is no alias for this --
	                       then it must return 1 as soon as the applet is ready.  Otherwise
	                       the applet will timeout.
	determine whether the applet's setConfig subroutine is defined. 
	                    -- applet.{setConfigAlias}.  
	determine whether the applet's setState subroutine is defined.	
	determine whether the  jsApplets ww_applet_list[appletName].reportsLoaded flag is set to 1
	                    -- this can be set by the applet if it calls the javaScript function 
	                       "applet_loaded(appletName, loaded_status).  The loaded_status is 1 or 0
	                       
	Logic for determining applet status: if any one of the above checks succeeds (or returns 1) then the applet is 
	                      consdered to be ready  UNLESS the isActive() exists and the call returns a 0 or no response. In this case 
	                      the applet is assumed to be loading additional data and is not yet ready. 
	                      
	                      For this reason if the isActive subroutine
	                      is defined in the applet it must return a 1 once the applet is prepared to accept additional commands.
	                      (Since there are some extent flashApplets with non-functioning isActive() subroutines a temporary workaround
	                       assuems that after C<maxInitializationAttempts> -- 5 by default -- the applet is in fact ready but the 
	                       isActive() subroutine is non functioning.  This can give rise to false "readiness" signals if the applet
	                       takes a long time to load auxiliary files.)

The applet itself can take measures to insure that the setConfig subroutine is prepared to respond immediately once the applet is loaded.
It can include timers that delay execution of the configuring actions until all of the auxiliary files needed by the applet are loaded.


=cut




=head4 Instance variables in the javaScript applet   ww_applet_list[appletName]

       Most of the instance variables in the perl version of the applet are transferred to the javaScript applet
       
=cut


=head4 Methods defined for the javaScript applet   ww_applet_list[appletName]

This is not a comprehensive list

	setConfig         -- transmits the information for configuring the applet
	
	getConfig         -- retrieves the configuration information -- this is used mainly for debugging and may not be defined in most applets
	
	
	setState          -- sets the current state (1) from the appletName_state HTML element if this contains an <xml>...</xml> string
	                  -- if the value contains <xml>restart_applet</xml> then set the current state to ww_applet_list[appletName].initialState
	                  -- if the value is a blank string set the current state to ww_applet_list[appletName].initialState
	
	
	getState          -- retrieves the current state and stores in the appletName_state HTML element.
	
	
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
	                      response that the student is effectvely submitting to answer
	                      the WW question.


=cut

=head4 Initialization sequence

When the WW question is loaded the C<initializeWWquestion> javaScript subroutine calls each of the applets used in the question asking them
to initialize themselves.

The applets initialization method is as follows:
                   
                       -- wait until the applet is loaded and the applet has loaded all of its auxiliary files.
                       -- set the debugMode in the applet
                       -- call the setConfig  method in the javaScript applet  -- (configuration parameters are "permanent" for the life of the applet
                       -- call the setInitialization method in the javaScript applet -- this often calls the setState method in the applet                      

=cut


=head Submit sequence

When the WW question submit button is pressed the form containing the WW question calles the javaScript "submitAction()" which then asks
each of the applets on the page to perform its submit action which consists of 

	-- if the applet is to be reinitialized (appletName_state contains <xml>restart_applet</xml>) then 
	   the HTML elements appletName_state and previous_appletName_state are set to <xml>restart_applet</xml>
	   to be interpreted by the next setState command
	-- Otherwise getState() from the applet and save it to the  HTML input element appletName_state
	-- Perform the javaScript commands in .submitActionScript (default: '' )
	   a typical submitActionScript looks like getQE(this.answerBox).value = getApplet(appletName).getAnswer()  )

=cut


sub new {
	 my $class = shift; 
	 my $self = { 
		appletName  => '',
		appletId    => '',   #always use identical applet Id's and applet Names
        archive     => '',
		code        => '',
		codebase    => '',
		params    =>undef,
		width     => 550,
		height    => 400,
		bgcolor   => "#869ca7",
		type      => '',
		visible   => 0,
		configuration      => '',         # configuration defining the applet
		initialState       => '',         # initial state.  
		getStateAlias      =>  'getXML',
		setStateAlias      =>  'setXML',
		configAlias        =>  '',        # deprecated
		getConfigAlias     =>  'getConfig',
		setConfigAlias     =>  'setConfig',
		initializeActionAlias => 'setXML',
		maxInitializationAttempts => 5,   # number of attempts to initialize applet
		submitActionAlias  =>  'getXML',
		submitActionScript  => '',        # script executed on submitting the WW question
		answerBoxAlias     =>  'answerBox',
		answerBox          =>  '',        # deprecated
		returnFieldName    => '',         # deprecated
		headerText         =>  DEFAULT_HEADER_TEXT(),
		objectText         => '',
		debugMode          => 0,
		selfLoading        => 0,
		@_,
	};
	bless $self, $class;
	$self->initialState('<xml></xml>');
	if ($self->{returnFieldName} or $self->{answerBox} ) { # backward compatibility
		warn "use answerBoxAlias instead of returnFieldName or answerBox";
		$self->{answerBox}='';
		$self->{returnFieldName}='';
	}
	if ($self->{configAlias}) { # backward compatibility
		warn "use setConfigAlias instead of configAlias";
		$self->{configAlias}='';
	}
	$self->configuration('<xml></xml>');
	return $self;
}
sub appletId {  
	appletName(@_);
}
sub appletName {
	my $self = shift;
	$self->{appletName} = shift ||$self->{appletName}; # replace the current appletName if non-empty
    $self->{appletName};
}
sub archive {
	my $self = shift;
	$self->{archive} = shift ||$self->{archive}; # replace the current archive if non-empty
    $self->{archive};
}
sub code {
	my $self = shift;
	$self->{code} = shift ||$self->{code}; # replace the current code if non-empty
    $self->{code};
}
sub codebase {
	my $self = shift;
	$self->{codebase} = shift ||$self->{codebase}; # replace the current codebase if non-empty
    $self->{codebase};
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

sub width {
	my $self = shift;
	$self->{width} = shift ||$self->{width}; # replace the current width if non-empty
    $self->{width};
}
sub height {
	my $self = shift;
	$self->{height} = shift ||$self->{height}; # replace the current height if non-empty
    $self->{height};
}
sub bgcolor {
	my $self = shift;
	$self->{bgcolor} = shift ||$self->{bgcolor}; # replace the current background color if non-empty
    $self->{bgcolor};
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
sub configuration {
	my $self = shift;
	my $str = shift;
	$self->{configuration} =  $str   || $self->{configuration}; # replace the current string if non-empty
	$self->{configuration} =~ s/\n//g;
    $self->{configuration};
}

sub initialState {
	my $self = shift;
	my $str = shift;
	$self->{initialState} = $str   ||$self->{initialState}; # replace the current string if non-empty
    $self->{initialState};
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

sub getConfigAlias {
	my $self = shift;
	$self->{getConfigAlias} = shift ||$self->{getConfigAlias}; # replace the current contents if non-empty
    $self->{getConfigAlias};
}
sub setConfigAlias {
	my $self = shift;
	$self->{setConfigAlias} = shift ||$self->{setConfigAlias}; # replace the current contents if non-empty
    $self->{setConfigAlias};
}

sub initializeActionAlias {
	my $self = shift;
	$self->{initializeActionAlias} = shift ||$self->{initializeActionAlias}; # replace the current contents if non-empty
    $self->{initializeActionAlias};
}
sub maxInitializationAttempts {
	my $self = shift;
	$self->{maxInitializationAttempts} = shift || $self->{maxInitializationAttempts};
	$self->{maxInitializationAttempts};
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

sub answerBoxAlias {
	my $self = shift;
	$self->{answerBox} = shift ||$self->{answerBox}; # replace the current contents if non-empty
    $self->{answerBox};
}

sub debugMode {
	my $self = shift;
	my $new_flag = shift;
	$self->{debugMode} = $new_flag if defined($new_flag);
	$self->{debugMode};
}


#######################
# soon to be deprecated?
#######################

sub config {
	my $self = shift;
	my $str = shift;
	warn "use $self->configuration instead of $self->config.  Internally this string is ascii, not base64 encoded", join(' ', caller());
# 	$self->{base64_config} =  encode_base64($str)   || $self->{base64_config}; # replace the current string if non-empty
# 	$self->{base64_config} =~ s/\n//g;
#     decode_base64($self->{base64_config});
}
sub state {    #deprecated
	my $self = shift;
	my $str = shift;
	warn "use $self->initialState instead of $self->state.  Internally this string is ascii, not base64 encoded", join(' ', caller());
# 	$self->{base64_state} =  encode_base64($str)   ||$self->{base64_state}; # replace the current string if non-empty
# 	$self->{base64_state} =~ s/\n//g;
#     decode_base64($self->{base64_state});
}
sub base64_state{
	my $self = shift;
	warn "use $self->InitialState instead of $self->state.  Internally this string is ascii, not base64 encoded", join(' ', caller());


}

sub base64_config {
	my $self = shift;
	warn "use $self->configuration instead of $self->config.  Internally this string is ascii, not base64 encoded";
}

sub returnFieldName {
	my $self = shift;
    warn "use  answerBoxName  instead of returnFieldName";
}
sub answerBox {
	my $self = shift;
    warn "use  answerBoxAlias  instead of AnswerBox";
}
sub configAlias {
	my $self = shift;
    warn "use setConfigAlias instead of configAlias";
}
#########################
#FIXME
# need to be able to adjust header material

sub insertHeader {
    my $self = shift;

    my $codebase              =  $self->codebase;
    my $appletId              =  $self->appletId;
    my $appletName            =  $self->appletName;
    my $initializeActionAlias =  $self->initializeActionAlias;
    my $submitActionScript    =  $self->submitActionScript;
    my $setStateAlias         =  $self->setStateAlias;
    my $getStateAlias         =  $self->getStateAlias;

    my $setConfigAlias        =  $self->setConfigAlias;
    my $getConfigAlias        =  $self->getConfigAlias;
    my $maxInitializationAttempts = $self->maxInitializationAttempts;
    my $debugMode             =  ($self->debugMode) ? "1": "0";
    my $answerBoxAlias        =  $self->{answerBoxAlias};
    my $onInit                =  $self->{onInit};   # function to indicate that applet is loaded (for geogebra:   ggbOnInit
    my $headerText            =  $self->header();
    my $selfLoading           =  $self->{selfLoading};
    
    #$submitActionScript =~ s/"/\\"/g;    # escape quotes for ActionScript
                                         # other variables should not have quotes.
                                         
    $submitActionScript =~ s/\n/ /g;     # replace returns with spaces -- returns in the wrong spot can cause trouble with javaScript
    $submitActionScript =~ s/\r/ /g;     # replace returns with spaces -- returns can cause trouble
    my  $base64_submitActionScript =     encode_base64($submitActionScript);
    my $base64_configuration  =  encode_base64($self->configuration);
    my $base64_initialState   =  encode_base64($self->initialState);
 
    $base64_submitActionScript =~s/\n//g;
    $base64_initialState  =~s/\n//g;  # base64 encoded xml
    $base64_configuration =~s/\n//g;  # base64 encoded xml
    
    $headerText =~ s/(\$\w+)/$1/gee;   # interpolate variables p17 of Cookbook
  
    return $headerText;


}


########################################################
# HEADER material for one flash or java applet
########################################################

use constant DEFAULT_HEADER_TEXT =><<'END_HEADER_SCRIPT';
  	<script src="/webwork2_files/js/legacy/Base64.js" language="javascript">
    </script> 	
  	<script src="/webwork2_files/js/legacy/ww_applet_support.js" language="javascript">
  	    //upload functions stored in /opt/webwork/webwork2/htdocs/js ...
  	    
     </script>
	<script language="JavaScript">
	
     function getApplet(appletName) {
	 	  var isIE = navigator.appName.indexOf("Microsoft") != -1;  // ie8 uses this for java and firefox uses it for flash.
	 	  var obj = (isIE) ? window[appletName] : window.document[appletName];
	 	  //return window.document[appletName];
	 	  if (!obj) { obj = document.getElementById(appletName) }
	 	  if (obj ) {   //RECENT FIX to ==
	 		  return( obj );
	 	  } else {
	 		  alert ("can't find applet " + appletName);		  
	 	  }
	  }	
		
   	//////////////////////////////////////////////////////////
	//TEST code
	//
    // 
    //////////////////////////////////////////////////////////
   
    ww_applet_list["$appletName"]                  = new ww_applet("$appletName");
    
    
	ww_applet_list["$appletName"].code             = "$code";
	ww_applet_list["$appletName"].codebase         = "$codebase";
    ww_applet_list["$appletName"].appletID         = "$appletID";
	ww_applet_list["$appletName"].base64_state     = "$base64_initialState";
	ww_applet_list["$appletName"].initialState     =  Base64.decode("$base64_initialState");
	ww_applet_list["$appletName"].configuration    =  Base64.decode("$base64_configuration");;
	ww_applet_list["$appletName"].getStateAlias    = "$getStateAlias";
	ww_applet_list["$appletName"].setStateAlias    = "$setStateAlias";
	ww_applet_list["$appletName"].setConfigAlias   = "$setConfigAlias";
	ww_applet_list["$appletName"].getConfigAlias   = "$getConfigAlias";
	ww_applet_list["$appletName"].initializeActionAlias = "$initializeActionAlias";
	ww_applet_list["$appletName"].submitActionAlias = "$submitActionAlias";
	ww_applet_list["$appletName"].submitActionScript = Base64.decode("$base64_submitActionScript");
	ww_applet_list["$appletName"].answerBoxAlias     = "$answerBoxAlias";
	ww_applet_list["$appletName"].maxInitializationAttempts = $maxInitializationAttempts;
	ww_applet_list["$appletName"].debugMode          = "$debugMode";
	ww_applet_list["$appletName"].onInit             = "$onInit";	


    </script>
	
END_HEADER_SCRIPT



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
    my $selfLoading = $self->{selfLoading};
    my $javaParameters = '';
    my $flashParameters = '';
    my $webgeogebraParameters = '';
    if (PGUtil::not_null($self->{parameter_string}) ) {
    	$javaParameters = $self->{parameter_string};
    	$flashParameters = $self->{parameter_string};
    	$webgeogebraParameters = $self->{parameter_string};
    } else {
		my %param_hash = %{$self->params()};

		foreach my $key (keys %param_hash) {
			$javaParameters .= qq!<param name ="$key"  value = "$param_hash{$key}">\n!;
			$flashParameters .= uri_escape($key).'='.uri_escape($param_hash{$key}).'&';
			$webgeogebraParameters .= qq!data-param-$key = "$param_hash{$key}"\n!;
		}
		$flashParameters =~ s/\&$//;    # trim last &
		$webgeogebraParameters = qq!<article class="geogebraweb"
		 data-param-id     = "$appletName"
		 data-param-width  = "$width"
		 data-param-height = "$height"
		 !. $webgeogebraParameters . 
		 qq!\n
		> </article> !;
	}
  
   
    $objectText = $self->{objectText};
    $objectText =~ s/(\$\w+)/$1/gee;  # interpolate values into object text 
    $objectText .=qq{<script language="javascript">ww_applet_list["$appletName"].visible = 1;</script>}; # don't submit things if not visible
    return $objectText;
}


###############################################################################################################
#
# FLASH APPLET  PACKAGE
#
###############################################################################################################

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
	$class -> SUPER::new(	objectText   => DEFAULT_OBJECT_TEXT(),
	                        type         => 'flash',
		        			@_
	);

}

###############################################################################################################
#
# JAVA APPLET  PACKAGE
#
###############################################################################################################

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


=pod

use constant DEFAULT_OBJECT_TEXT =><<'END_OBJECT_TEXT';

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

#  classid  = "java:MyApplet.class"


use constant DEFAULT_OBJECT_TEXT =><<'END_OBJECT_TEXT';

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
	$class -> SUPER::new(	objectText   => DEFAULT_OBJECT_TEXT(),
	                        type         => 'java',
		        			@_
	);

}

###############################################################################################################
#
# CANVAS APPLET  PACKAGE
#
###############################################################################################################

package CanvasApplet;
@ISA = qw(Applet);


=head2 Insertion HTML code for CanvasApplet

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

use constant CANVAS_OBJECT_TEXT =><<'END_OBJECT_TEXT';
  <form></form>
	<script> var width = 200; var height = 200;</script>
	<canvas name="cv" id="cv" data-src="http://localhost/webwork2_files/js/legacy/sketchgraphhtml5b/SketchGraph.pjs" width="400" height="400"></canvas>  
END_OBJECT_TEXT



=cut


use constant CANVAS_OBJECT_HEADER_TEXT =><<'END_HEADER_SCRIPT';
  	<script src="/webwork2_files/js/legacy/Base64.js" language="javascript">
    </script> 	
  	<script src="/webwork2_files/js/legacy/ww_applet_support.js" language="javascript">
  	    //upload functions stored in /opt/webwork/webwork2/htdocs/js ...
  	    
     </script>
	<script language="JavaScript">
	

		
   	//////////////////////////////////////////////////////////
	//CANVAS OBJECT HEADER CODE
    // 
    //////////////////////////////////////////////////////////
   
    ww_applet_list["$appletName"] = new ww_applet("$appletName");
    
    
	ww_applet_list["$appletName"].code             = "$code";
	ww_applet_list["$appletName"].codebase         = "$codebase";
    ww_applet_list["$appletName"].appletID         = "$appletID";
	ww_applet_list["$appletName"].base64_state     = "$base64_initializationState";
	ww_applet_list["$appletName"].initialState     = Base64.decode("$base64_initialState");
	ww_applet_list["$appletName"].configuration    = Base64.decode("$base64_configuration");;
	ww_applet_list["$appletName"].getStateAlias    = "$getStateAlias";
	ww_applet_list["$appletName"].setStateAlias    = "$setStateAlias";
	ww_applet_list["$appletName"].setConfigAlias   = "$setConfigAlias";
	ww_applet_list["$appletName"].getConfigAlias   = "$getConfigAlias";
	ww_applet_list["$appletName"].initializeActionAlias = "$initializeActionAlias";
	ww_applet_list["$appletName"].submitActionAlias = "$submitActionAlias";
	ww_applet_list["$appletName"].submitActionScript = Base64.decode("$base64_submitActionScript");
	ww_applet_list["$appletName"].answerBoxAlias = "$answerBoxAlias";
	ww_applet_list["$appletName"].maxInitializationAttempts = $maxInitializationAttempts;
	ww_applet_list["$appletName"].debugMode = "$debugMode";	
    ww_applet_list["$appletName"].reportsLoaded = "$selfLoading";
    ww_applet_list["$appletName"].onInit             = "$onInit";	
    ww_applet_list["$appletName"].object = $appletName;
    
    function getApplet(appletName) {
	 	  var obj = ww_applet_list[appletName].object;   // define fake applet for this object
	 	  if (obj && (obj.name == appletName)) {   //RECENT FIX to ==
	 	      //alert("getting fake applet " + obj.name);
	 		  return( obj );
	 	  } else {
	 		  //alert ("can't find fake applet " + appletName + " in object "+obj.name);		  
	 	  }
	  }	
    </script>
	
END_HEADER_SCRIPT


#FIXME   need to get rid of hardcoded url


use constant CANVAS_OBJECT_TEXT =><<'END_OBJECT_TEXT';
    <script language="javascript">ww_applet_list["$appletName"].visible = 1; // don't submit things if not visible
    </script>
	<canvas name="cv" id="cv" data-src="/webwork2_files/js/legacy/sketchgraphhtml5b/SketchGraph.pjs" width="$width" height="$height"></canvas>  
END_OBJECT_TEXT

sub new {
    my $class = shift;
	$class -> SUPER::new(	objectText   => CANVAS_OBJECT_TEXT(),
			                headerText   => CANVAS_OBJECT_HEADER_TEXT(),
			                type         => 'html5canvas',
		        			@_
	);

}

###############################################################################################################
#
# GeogebraWeb APPLET  PACKAGE
#
###############################################################################################################

package GeogebraWebApplet;
@ISA = qw(Applet);


=head2 Insertion HTML code for GeogebraWebApplet

=pod


use constant CANVAS_OBJECT_TEXT =><<'END_OBJECT_TEXT';
  <form></form>
	<script> var width = 200; var height = 200;</script>
	<canvas name="cv" id="cv" data-src="http://localhost/webwork2_files/js/legacy/sketchgraphhtml5b/SketchGraph.pjs" width="400" height="400"></canvas>  
END_OBJECT_TEXT



=cut


use constant GEOGEBRAWEB_OBJECT_HEADER_TEXT =><<'END_HEADER_SCRIPT';
  	<script src="/webwork2_files/js/legacy/Base64.js" language="javascript">
    </script> 	
  	<script src="/webwork2_files/js/legacy/ww_applet_support.js" language="javascript">
  	    //upload functions stored in /opt/webwork/webwork2/htdocs/js ...
  	    
     </script>
	<script language="JavaScript">
	

		
   	//////////////////////////////////////////////////////////
	//GEOGEBRAWEB OBJECT HEADER CODE
    // 
    //////////////////////////////////////////////////////////
   
    ww_applet_list["$appletName"] = new ww_applet("$appletName");
    
    
	ww_applet_list["$appletName"].code             = "$code";
	ww_applet_list["$appletName"].codebase         = "$codebase";
    ww_applet_list["$appletName"].appletID         = "$appletID";
	ww_applet_list["$appletName"].base64_state     = "$base64_initializationState";
	ww_applet_list["$appletName"].initialState     = Base64.decode("$base64_initialState");
	ww_applet_list["$appletName"].configuration    = Base64.decode("$base64_configuration");;
	ww_applet_list["$appletName"].getStateAlias    = "$getStateAlias";
	ww_applet_list["$appletName"].setStateAlias    = "$setStateAlias";
	ww_applet_list["$appletName"].setConfigAlias   = "$setConfigAlias";
	ww_applet_list["$appletName"].getConfigAlias   = "$getConfigAlias";
	ww_applet_list["$appletName"].initializeActionAlias = "$initializeActionAlias";
	ww_applet_list["$appletName"].submitActionAlias = "$submitActionAlias";
	ww_applet_list["$appletName"].submitActionScript = Base64.decode("$base64_submitActionScript");
	ww_applet_list["$appletName"].answerBoxAlias = "$answerBoxAlias";
	ww_applet_list["$appletName"].maxInitializationAttempts = $maxInitializationAttempts;
	ww_applet_list["$appletName"].debugMode           = "$debugMode";	
    ww_applet_list["$appletName"].reportsLoaded       = "$selfLoading";
    ww_applet_list["$appletName"].isReady             = "$selfLoading";
    ww_applet_list["$appletName"].onInit              = "$onInit";	
    
    function getApplet(appletName) {
	 	  var obj = document.$appletName;
	 	  ww_applet_list[appletName].object = obj ;   // define fake applet for this object
	 	  return(obj);
	  }	
    </script>
	
END_HEADER_SCRIPT


use constant GEOGEBRAWEB_OBJECT_TEXT =><<'END_OBJECT_TEXT';
    <script language="javascript">ww_applet_list["$appletName"].visible = 1; // don't submit things if not visible
    </script>
<script type="text/javascript" language="javascript" src="https://www.geogebra.org/web/4.4/web/web.nocache.js"></script>

$webgeogebraParameters

END_OBJECT_TEXT

sub new {
    my $class = shift;
	$class -> SUPER::new(	objectText   => GEOGEBRAWEB_OBJECT_TEXT(),
			                headerText   => GEOGEBRAWEB_OBJECT_HEADER_TEXT(),
			                type         => 'geogebraweb',
		        			@_
	);

}

1;
