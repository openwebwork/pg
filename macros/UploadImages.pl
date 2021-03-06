################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2020 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader: pg/macros/UploadImage.pl,v 1.0 2020/05/28 23:28:44 gage Exp $
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

=pod

=head1 NAME

UploadImages.pl

=head1 SYNOPSIS

Provides students a way to upload images to a WeBWorK question.

=head1 DESCRIPTION

Load the C<UploadImages.pl> macro file.

=over 12

=item loadMacros("PGstandard.pl","MathObjects.pl","PGML.pl","UploadImages.pl","PGcourse.pl");

=back

The C<UploadImages.pl> macro file has one Perl subroutine C<UploadImages()> that is run in
Perl mode (not inside a BEGIN_TEXT / END_TEXT or a
BEGIN_PGML / END_PGML block).

=over 12

=item C<UploadImages()>

=back

Insert an image upload prompt using

=over 12

BEGIN_TEXT
The text of the problem goes here.
END_TEXT

UploadImages(); # creates its own text and html

=back

The uploaded images are stored as dataURLs with the student answer data 
(on the WeBWorK server's database) and thus persist between login
sessions.  The uploaded images are not automatically graded.  Up to 21 images
are allowed to be uploaded.

=head1 MANUAL LOCAL INSTALLATION FOR ONE COURSE

Download the most recent C<UploadImages.pl> macro file from
C<https://github.com/openwebwork/pg/tree/master/macros>
to your hard drive.  Anyone with professor level permissions can move 
C<UploadImages.pl> to the C<course/templates/macros/> directory using the 
File Manager in the WeBWorK graphical user interface as follows: 

1. Click File Manager.  This will put you into the C<course/templates/> directory.
2. Double click the C<macros/> directory.
3. Choose the C<UploadImages.pl> file from your hard drive and press C<Upload>.

=head1 MANUAL SYSTEM WIDE INSTALLATION

Move the file C<UploadImages.pl> file to 
    
        /opt/webwork/pg/macros/UploadImages.pl

=head1 AUTHORS

Paul Pearson, Hope College, Department of Mathematics and Statistics

=cut




########################################################

sub _UploadImages_init {}; # don't reload this file

###################
# to do / questions
# 0. unique id issues
# 1. remove image
# 2. rotate image
# 3. sketchpad on top of images for grading?
# 4. update the copyright header?



###################
# create html hidden inputs and retrieve past answers

# we allow for 21 file uploads (perhaps we should limit this)
# note: the name of the hidden input is what gets used as the key in $inputs_ref
sub get_stored_data {
    my $hidden_input_id = shift;

    ##########################
	# implement the sticky answer mechanism for maintaining the applet state when the question page is refreshed
	# This is important for guest users for whom no permanent record of answers is recorded.
	##########################
	my $answer_value = '';
    if ( defined( ${$main::inputs_ref}{$hidden_input_id} ) and ${$main::inputs_ref}{$hidden_input_id} =~ /\S/ ) { 
		$answer_value = ${$main::inputs_ref}{$hidden_input_id};
	} 
	$answer_value =~ tr/\\$@`//d;   #`## make sure student answers can not be interpolated by e.g. EV3
	$answer_value =~ s/\s+/ /g;     ## remove excessive whitespace from student answer

    
    main::TEXT(main::MODES(TeX=>'', HTML=>qq!<input type='text' name="$hidden_input_id" id="$hidden_input_id" value="$answer_value" />!));
    main::RECORD_FORM_LABEL($hidden_input_id);    
}










###########################################
# https://developer.mozilla.org/en-US/docs/Web/API/FileReader/readAsDataURL 


HEADER_TEXT(<<END_HEADER_TEXT);	

<script>
//var all_files = [];
var num_files_attached = 0;

function previewFiles() {

  var preview = document.querySelector('#preview');
  var files   = document.querySelector('input[type=file]').files;

  function readAndPreview(file) {
    // console.log(file); // view file meta data

    // Make sure `file.name` matches our extensions criteria
    //if ( /\.(jpe?g|png|gif)$/i.test(file.name) ) { // original threw an error in webwork, probably because of the backslash
    if (file.type.match('image.*')) { // alternative: check file type using mime type

      var reader = new FileReader();

      reader.addEventListener("load", function () {
        //console.log("Event listener inside readAndPreview run");
        var image = new Image();
        //image.height = 100;
        image.title = file.name;
        image.src = this.result; // this.result is the base64 string
		//console.log("length of base64 string: " + this.result.length);
        preview.appendChild( image );

        // store each file in an html hidden file input
        var j = 0;
        while (j < 21) {
          if ( document.getElementById('hidden_file_input_id_' + j).value == '' ) {
            document.getElementById('hidden_file_input_id_' + j).value = this.result; // this.result is the base64 string of the image
            //all_files.push( this.result );

            num_files_attached++;
            document.getElementById('number_of_files_attached').value = num_files_attached;
            break;
          }
          j++;
        }

      }, false);

	  reader.readAsDataURL(file);
    }

  }

  if (files) {
    [].forEach.call(files, readAndPreview);
	  
    // https://stackoverflow.com/questions/16053357/what-does-foreach-call-do-in-javascript
    // this forEach loop just looks at the file meta data, not the file data
    //[].forEach.call(files, function(item, i, arr) { console.log("[].forEach... run"); console.log(item); console.log(i); console.log(arr); } );
    //[].forEach.call(files, function(item, i, arr) { all_files.push(item) } );
	  
  }

}


// This code runs after the webpage is loaded and ready
document.addEventListener("DOMContentLoaded", function() {
    //console.log("DOM content loaded"); //setState();

    var preview = document.querySelector('#preview');

    // read the file from the hidden input and draw it
    var j = 0;
    while (j < 21) {
      var hidden_file_input_id = 'hidden_file_input_id_' + j;  
      if ( document.getElementById(hidden_file_input_id).value != '' ) {
        //console.log( document.getElementById(hidden_file_input_id).value ); // this.result is the base64 string of the image
        var image = new Image();
        //image.height = 100;
        //image.title = file.name;
        image.src = document.getElementById(hidden_file_input_id).value; // this.result is the base64 string
        preview.appendChild( image );
  
      }
      j++;
    }

});
</script>
END_HEADER_TEXT



###########################################


sub UploadImages {

# For the sake of saving time, I'm not going to implement unique id's right now, but here's a start.
# We're going to assume that UploadImages() will only get used once in a .pg file.
#    %options = (
#        unique_id => 'FileUpload1',
#        @_
#    );
# my $uid = $main::PG->encode_base64( $envir{probFileName} . $options{unique_id} );


foreach my $i (0..20) {
    get_stored_data("hidden_file_input_id_" . $i);
}

get_stored_data('number_of_files_attached');


my $html = qq(
    $PAR$HR
    <h4 style="margin:0">Attach image files</h4>
    $PAR
    <input id="browse" name="browse" type="file" onchange="previewFiles()" multiple>
    <div id="preview"></div>
    );

    main::TEXT(main::MODES(TeX=>"", HTML=>$html, PTX=>$html));

} # end UploadImages()


1;
