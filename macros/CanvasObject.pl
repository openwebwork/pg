#! /usr/bin/perl -w

$appletName="drawCanvas";
$canvasName = "cv";

HEADER_TEXT(<<END_HEADER_TEXT);
<script language="javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js"></script>
<script language="javascript" src="${webworkHtmlURL}js/sketchgraphhtml5b/SketchGraph.pjs"></script>
<script language="javascript" src="${webworkHtmlURL}js/sketchgraphhtml5b/processing-dgfix.js"></script>


<script>
// define your canvasObject here
var $appletName = new Object
$appletName.name = "$appletName";
$appletName.id   = "$appletName";
$appletName.setPoints = function(state){setPoints1()}
$appletName.getPoints = function(state){return( getPoints1() )}


//set your limits here
var xmin = -5, xmax = 5, ymin = -5, ymax = 5;
var points;
var showGrid = true;
var yValues = new Array();
var derivatives = new Array();
var canvasWidth = 400, canvasHeight = 400;
var padding =3;



//-------------------  Listeners ---------------------------
    //had to add the listeners with javascript
    //because it's not currently possible to reference processing methods from the html
    
    //reset the graph to 0
    function my_reset() {
      for (var i = 0; i < points; i++) {
    
        yValues[i] = 0.5;
        derivatives[i] = 0;
      }
      setPoints();
    }
    
    //toggle grid
    function toggleGrid() {
      showGrid = !showGrid;
    }
    
    //smooth the current graph 
    function smooth() {
      var newPoints = new Array(points);
      for (var i = 0; i < points; i++) {
        var sum = 0.3 * yValues[i];
        sum += 0.2 * (i > 0? yValues[i-1] : yValues[i]);
        sum += 0.2 * (i < points-1? yValues[i+1] : yValues[i]);
        sum += 0.1 * (i > 1? yValues[i-2] : yValues[i]);
        sum += 0.1 * (i < points - 2? yValues[i+2] : yValues[i]);
        sum += 0.05 * (i > 2? yValues[i-3] : yValues[i]);
        sum += 0.05 * (i < points - 3? yValues[i+3] : yValues[i]);
        newPoints[i] = sum;
      }
      yValues = newPoints;
    }

//     //grab points from graph and print
//     function getPoints() {
//       var temp = "";
//       for(var i = 0; i < points; i++){
//         temp += xmin + i*(xmax-xmin)/(points-1) + " ";
//         temp += ymin + yValues[i]*(ymax - ymin) + " ";
//         var dx = 1.0/points * (xmax - xmin);
//         if (i == 0)
//           temp += (yValues[1] - yValues[0])*(ymax-ymin)/dx + "\\n";
//         else if (i == points-1)
//           temp += (yValues[points-1] - yValues[points-2])*(ymax-ymin)/dx + "\\n";
//         else {
//           var i = i;
//           var left = Math.abs(yValues[i] - yValues[i-1]);
//           var right = Math.abs(yValues[i+1] - yValues[i]);
//           if (left < 1e-20 || right < 1e-20)
//             temp += 0 + "\\n";
//           else
//             temp += ((1/right)*(yValues[i+1]-yValues[i]) - (1/left)*(yValues[i]-yValues[i-1]))/(2*dx*((1/right)+(1/left))) + "\\n";
//         }
//       }
//       \$('#pointDisplay').val(temp);
//     }
//     
//     //load points from y-values
//     function setPoints() {
//       var tempString = \$('#points1').val();
//       var tempPoints = tempString.split(',');
//       var vals = new Array(tempPoints.length);
//       for(var i = 0; i < tempPoints.length; i++){
//         vals[i] = parseInt(tempPoints[i]);
//       }
//       points = vals.length;
//       yValues = new Array(points);
//       derivatives = [points];
//       for (var i = 0; i < points; i++)
//         yValues[i] = 0.5;
//       for (var i = 0; i < vals.length; i++) {
//         if (vals[i] > ymax)
//           yValues[i] = 1;
//         else if (vals[i] < ymin)
//           yValues[i] = 0;
//         else
//           yValues[i] = (vals[i]-ymin)/(ymax-ymin);
//       }
//     }
    //grab points from graph and print
 
    function getPoints1() {
      var temp = "";
      var temp2 = "";
      for(var i = 0; i < points; i++){
        temp += xmin + i*(xmax-xmin)/(points-1) + " ";
        temp += ymin + yValues[i]*(ymax - ymin) + " ";
        if (i!=0) { temp2 +=","};
        temp2 += ymin + yValues[i]*(ymax - ymin);
        var dx = 1.0/points * (xmax - xmin);
        if (i == 0)
          temp += (yValues[1] - yValues[0])*(ymax-ymin)/dx + "\\n";
        else if (i == points-1)
          temp += (yValues[points-1] - yValues[points-2])*(ymax-ymin)/dx + "\\n";
        else {
          var i = i;
          var left = Math.abs(yValues[i] - yValues[i-1]);
          var right = Math.abs(yValues[i+1] - yValues[i]);
          if (left < 1e-20 || right < 1e-20)
            temp += 0 + "\\n";
          else
            temp += ((1/right)*(yValues[i+1]-yValues[i]) - (1/left)*(yValues[i]-yValues[i-1]))/(2*dx*((1/right)+(1/left))) + "\\n";
        }
      }
      //alert("printing temp to ${appletName}_state" + temp );
      temp = "<xml>" + temp + "</xml>";
      \$('#${appletName}_state').val(temp);
      \$('#answerBox').val(temp2);
      return(temp);
    }
    
    //load points from y-values
    function setPoints1() {
      var tempString = \$('#answerBox').val();
      //alert("getting temp string from  $answerBox" + tempString );
      var tempPoints = tempString.split(',');
      var vals = new Array(tempPoints.length);
      for(var i = 0; i < tempPoints.length; i++){
        vals[i] = parseFloat(tempPoints[i]);
      }
      if (vals.length>2) points = vals.length;
      yValues = new Array(points);
      derivatives = [points];
      for (var i = 0; i < points; i++)
        yValues[i] = 0.5;
      for (var i = 0; i < vals.length; i++) {
        if (vals[i] > ymax)
          yValues[i] = 1;
        else if (vals[i] < ymin)
          yValues[i] = 0;
        else
          yValues[i] = (vals[i]-ymin)/(ymax-ymin);
      }
    }
</script>

END_HEADER_TEXT

sub insertCanvas {
    my $myWidth = shift() || 200;
    my $myHeight = shift() ||200;
	$canvasObject = MODES(TeX=>"canvasObject",HTML=><<END_CANVAS);
	<script> var canvasWidth = $myWidth; var canvasHeight = $myHeight;</script>
	<canvas id="cv" data-src="${webworkHtmlURL}js/sketchgraphhtml5b/SketchGraph.pjs" width="$myWidth" height="$myHeight"></canvas>  
END_CANVAS
# keep END_CANVAS flush left!!	
	return $canvasObject;
}

sub insertYvaluesInputBox {
	$yValuesInput = MODES(TeX=>"yVAluesInput",HTML=><<EOF);
	<p>
	Y-values: 
	<input type="text" id="points1" size=50></input>
	<button type="button" id="setPts" onClick="setPoints();">Set</button>
	</p>
EOF
	return $yValuesInput;

}

sub insertGridButtons {
	$gridButtons = MODES(TeX=>"gridButtons",HTML=><<EOF);
	<button type="button" id="hideGrid" onClick="toggleGrid();">Toggle Grid</button>
	<button type="button" id="reset1" onClick="my_reset();">Reset to Zero</button>
	<button type="button" id="smooth1" onClick="smooth();">Smooth</button>
	<br><br>

EOF
	return $gridButtons;
}
# sub stateAndDebugBoxes {  ## inserts both header text and object text
# 	#my $self = shift;
# 	my %options = @_;
# 	
# 	
# 	##########################
# 	# determine debug mode
# 	# debugMode can be turned on by setting it to 1 in either the applet definition or at insertAll time
# 	##########################
# 
# 	my $debugMode = (defined($options{debug}) and $options{debug}>0) ? $options{debug} : 0;
# 	my $includeAnswerBox = (defined($options{includeAnswerBox}) and $options{includeAnswerBox}==1) ? 1 : 0;
# 	$debugMode = $debugMode || 0; #   $self->debugMode;
#     #$self->debugMode( $debugMode);
# 
# 	
# 	my $reset_button = $options{reinitialize_button} || 0;
# 	warn qq! please change  "reset_button=>1" to "reinitialize_button=>1" in the applet->installAll() command \n! if defined($options{reset_button});
# 
# 	##########################
# 	# Get data to be interpolated into the HTML code defined in this subroutine
# 	#
#     # This consists of the name of the applet and the names of the routines 
#     # to get and set State of the applet (which is done every time the question page is refreshed
#     # and to get and set Config  which is the initial configuration the applet is placed in 
#     # when the question is first viewed.  It is also the state which is returned to when the 
#     # reset button is pressed.
# 	##########################
# 
# 	# prepare html code for storing state 
# 	my $appletName      = 'cv';        # $self->appletName;
# 	my $appletStateName = "${appletName}_state";   # the name of the hidden "answer" blank storing state FIXME -- use persistent data instead
# 	my $getState        = 'getPoints()'; # $self->getStateAlias;    # names of routines for this applet
# 	my $setState        = 'setPoints()'; # $self->setStateAlias;
# 	my $getConfig       = '';          # $self->getConfigAlias;
# 	my $setConfig       = '';          # $self->setConfigAlias;
# 
# 	my $base64_initialState     = '';  # encode_base64($self->initialState);
# 	main::RECORD_FORM_LABEL($appletStateName);            #this insures that the state will be saved from one invocation to the next
# 	                                                      # FIXME -- with PGcore the persistant data mechanism can be used instead
#     my $answer_value = '<xml></xml>';
# 
# 	##########################
# 	# implement the sticky answer mechanism for maintaining the applet state when the question page is refreshed
# 	# This is important for guest users for whom no permanent record of answers is recorded.
# 	##########################
# 	
#     if ( defined( ${$inputs_ref}{$appletStateName} ) and ${$main::inputs_ref}{$appletStateName} =~ /\S/ ) {   
# 		$answer_value = ${$main::inputs_ref}{$appletStateName};
# 	} elsif ( defined( $main::rh_sticky_answers->{$appletStateName} )  ) {
# 	    warn "type of sticky answers is ", ref( $main::rh_sticky_answers->{$appletStateName} );
# 		$answer_value = shift( @{ $main::rh_sticky_answers->{$appletStateName} });
# 	}
# 	$answer_value =~ tr/\\$@`//d;   #`## make sure student answers can not be interpolated by e.g. EV3
# 	$answer_value =~ s/\s+/ /g;     ## remove excessive whitespace from student answer
# 	
# 	##########################
# 	# insert a hidden answer blank to hold the applet's state 
# 	# (debug =>1 makes it visible for debugging and provides debugging buttons)
# 	##########################
# 
# 
# 	##########################
# 	# Regularize the applet's state -- which could be in either XML format or in XML format encoded by base64
# 	# In rare cases it might be simple string -- protect against that by putting xml tags around the state
# 	# The result:
# 	# $base_64_encoded_answer_value -- a base64 encoded xml string
# 	# $decoded_answer_value         -- and xml string
# 	##########################
#     	
# 	my $base_64_encoded_answer_value;
# 	my $decoded_answer_value; 
#  	$answer_value = '<xml></xml>'; #(defined( $answer_value) and $answer_value =~/\S/)? $answer_value : '<xml></xml>';
# 	if ( $answer_value =~/<XML|<?xml/i) {
# 		$base_64_encoded_answer_value = $answer_value;  #encode_base64($answer_value);  #FIXME
# 		$decoded_answer_value = $answer_value;
# 	} else {
#         $decoded_answer_value = $answer_value;  #    decode_base64($answer_value);
#  		if ( $decoded_answer_value =~/<XML|<?xml/i) {  # great, we've decoded the answer to obtain an xml string
#  			$base_64_encoded_answer_value = $answer_value;
#  		} else {    #WTF??  apparently we don't have XML tags
#  			$answer_value = "<xml>$answer_value</xml>";
#  			$base_64_encoded_answer_value = $answer_value; #  encode_base64($answer_value);
#  			$decoded_answer_value = $answer_value;
#  		}
# 	}	
#   	$base_64_encoded_answer_value =~ s/\r|\n//g;    # get rid of line returns
# 
# 	##########################
#     # Construct answer blank for storing state -- in both regular (answer blank hidden) 
#     # and debug (answer blank displayed) modes.
# 	##########################
# 	
# 	##########################
#     # debug version of the applet state answerBox and controls (all displayed)
#     # stored in 
#     # $debug_input_element
# 	##########################
# 
#     my $debug_input_element  = qq!\n<textarea  rows="4" cols="80" 
# 	   name = "$appletStateName" id = "$appletStateName">$decoded_answer_value</textarea><br/>!;
# 	if ($getState=~/\S/) {   # if getStateAlias is not an empty string
# 		$debug_input_element .= qq!
# 	        <input type="button"  value="$getState" 
# 	               onClick="debugText=''; 
# 	                        ww_applet_list['$appletName'].getState(); 
# 	                        if (debugText) {alert(debugText)};"
# 	        >!;
# 	}
# 	if ($setState=~/\S/) {   # if setStateAlias is not an empty string
# 		$debug_input_element .= qq!
# 	        <input type="button"  value="$setState" 
# 	               onClick="debugText='';
# 	                        ww_applet_list['$appletName'].setState();
# 	                        if (debugText) {alert(debugText)};"
# 	        >!;
# 	}
# 	if ($getConfig=~/\S/) {   # if getConfigAlias is not an empty string
# 		$debug_input_element .= qq!
# 	        <input type="button"  value="$getConfig" 
# 	               onClick="debugText=''; 
# 	                        ww_applet_list['$appletName'].getConfig();
# 	                        if (debugText) {alert(debugText)};"
# 	        >!;
# 	}
# 	if ($setConfig=~/\S/) {   # if setConfigAlias is not an empty string
# 		$debug_input_element .= qq!
# 		    <input type="button"  value="$setConfig" 
# 	               onClick="debugText='';
# 	                        ww_applet_list['$appletName'].setConfig();
# 	                        if (debugText) {alert(debugText)};"
#             >!;
#     }
#     
# 	##########################
#     # Construct answerblank for storing state
#     # using either the debug version (defined above) or the non-debug version
#     # where the state variable is hidden and the definition is very simple
#     # stored in 
#     # $state_input_element
# 	##########################
# 	        
# 	my $state_input_element = ($debugMode) ? $debug_input_element :
# 	      qq!\n<input type="hidden" name = "$appletStateName" id = "$appletStateName"  value ="$base_64_encoded_answer_value">!;
# 	      
# 	##########################
#     # Construct the reset button string (this is blank if the button is not to be displayed
#     # $reset_button_str
# 	##########################
# 
#     my $reset_button_str = ($reset_button) ?
#             qq!<input type='submit' name='previewAnswers' id ='previewAnswers' value='return this question to its initial state' 
#                  onClick="setAppletStateToRestart('$appletName')"><br/>!
#             : ''  ;
# 
# 	##########################
# 	# Combine the state_input_button and the reset button into one string
# 	# $state_storage_html_code
# 	##########################
# 
# 
#     $state_storage_html_code = qq!<input type="hidden"  name="previous_$appletStateName" id = "previous_$appletStateName"  value = "$base_64_encoded_answer_value">!              
#                               . $state_input_element. $reset_button_str
#                              ;
# 	##########################
# 	# Construct the answerBox (if it is requested).  This is a default input box for interacting 
# 	# with the applet.  It is separate from maintaining state but it often contains similar data.
# 	# Additional answer boxes or buttons can be defined but they must be explicitly connected to 
# 	# the applet with additional javaScript commands.
# 	# Result: $answerBox_code
# 	##########################
# 
#     my $answerBox_code ='';
#     if ($includeAnswerBox) {
# 		if ($debugMode) {
# 		
# 			$answerBox_code = $main::BR . main::NAMED_ANS_RULE('answerBox', 50 );
# 			$answerBox_code .= qq!
# 							 <br/><input type="button" value="get Answer from applet" onClick="eval(ww_applet_list['$appletName'].submitActionScript )"/>
# 							 <br/>
# 							!;
# 		} else {
# 			$answerBox_code = main::NAMED_HIDDEN_ANS_RULE('answerBox', 50 );
# 		}
# 	}
# 	
# 	##########################
#     # insert header material
# 	##########################
# 	#main::HEADER_TEXT($self->insertHeader());
# 	# update the debug mode for this applet.
#     main::HEADER_TEXT(qq!<script> ww_applet_list["$appletName"].debugMode = $debugMode;\n</script>!);
#     
# 	##########################
#     # Return HTML or TeX strings to be included in the body of the page
# 	##########################
#         
#     return main::MODES(TeX=>' {\bf  applet } ', 
#     #HTML=>$self->insertObject.$main::BR.$state_storage_html_code.$answerBox_code);
#      HTML=>$main::BR.$state_storage_html_code.$answerBox_code
#      );
#  }

sub insertPointsArea {
	$pointsArea = MODES(TeX=>"pointsArea",HTML=><<EOF);
	<button type="button" id="getPts" onClick="getPoints();">Get Points</button><br/>
	<textarea id="pointDisplay" rows=10 cols=60></textarea>	
EOF
	return $pointsArea;
}
