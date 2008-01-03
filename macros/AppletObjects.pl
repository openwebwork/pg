################################################################################
# WeBWorK Online Homework Delivery System
# Copyright © 2000-2007 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader: pg/macros/AppletObjects.pl,v 1.2 2007/12/03 22:32:01 gage Exp $
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

AppletOjects.pl - Macro-based front end for the Applet.pm module.


=head1 DESCRIPTION

This subroutines in this 
file provide mechanisms to insert Flash applets (and later Java applets)
into a WeBWorK problem.


=head1 SEE ALSO

L<Applets.pm>.

=cut

sub _PGapplets_init {}; # don't reload this file

=head3
	FlashApplet

	Useage:    $applet = FlashApplet();

=cut

sub FlashApplet {
	return new FlashApplet(@_);

}

package FlashApplet;

=head2 Methods

=cut

## this method is defined in this file 
## because the main subroutines HEADER_TEXT and MODES are 
## not available to the module FlashApplet when that file
## is compiled (at the time the apache child process is first initialized)

=head3  insert

	Useage:   TEXT( $applet->insert() );
	          \{ $applet->insert \}     (used within BEGIN_TEXT/END_TEXT blocks)

=cut 

=pod 

Inserts applet at this point in the HTML code.  (In TeX mode a message "Applet" is written.)  This method
also adds the applets header material into the header portion of the HTML page. It effectively inserts
the outputs of both C<$applet-E<gt>insertHeader> and C<$applet-E<gt>insertObject> (defined in L<Applet.pm> ) in the appropriate places.

=cut

sub insert {  ## inserts both header text and object text
	my $self = shift;
	main::HEADER_TEXT($self->insertHeader());
    return main::MODES(TeX=>' {\bf flash applet } ', HTML=>$self->insertObject);
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
	# Add java script functions to header section of HTML to 
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
		  //alert("update form with " + sMessage);
		  //window.document.problemMainForm.playbackStatus.value = sMessage;
		  //document.problemMainForm.playbackStatus.value = sMessage;
			  document.getElementById("playbackStatus").value = sMessage;
		}
		
		function newColor() {
		  //var app = getFlashMovie("ExternalInterface").getElementById("movie1");
		  // alert(app);
		  // The difficult issue in adapting Barbara's original file was locating
		  // the object.  It took several tries to find a method that worked
		  // and it is quite likely that it will not work in all browsers.
		
		  //alert("update color");
		  //alert(getFlashMovie("ExternalInterface"));
		  getFlashMovie("ExternalInterface").updateColor(Math.round(Math.random() * 0xFFFFFF));
		}
		
		function submitAction() { newColor()
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
	
	
	TEXT( MODES(TeX=>'object code', HTML=><<END_SCRIPT ) );
	<script>
			//alert("foobar");
		initialize();
		// this should really be done in the <body> tag -- can we make that happen?
	</script>
	END_SCRIPT
	
	 
	BEGIN_TEXT
	\{ $applet->insert \}
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