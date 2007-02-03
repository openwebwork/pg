

=head1 NAME

	AnswerIO.pm

=head1 SYNPOSIS

This is not really an object, but it gives us a place to IO used by answer
macros.



=head1 DESCRIPTION


=head2 Examples:



=cut


BEGIN {
	be_strict(); # an alias for use strict.  This means that all global variable must contain main:: as a prefix.
}

package AnswerIO;



# Code for saving Answers to a file
# function, not a method
# Code in .pm files can access the disk.


sub saveAnswerToFile {
	  my $logFileID = shift;
      my $string = shift;
      # We want to allow acces only to predetermined files
      # We accomplish this by translating legal IDs into a file name

      my $rh_allowableFiles = {
         preflight => 'preflight.log',
         questionnaire => 'questionnaire.txt',

      	};
      my $error=undef;
      my $logFileName = $rh_allowableFiles->{$logFileID};
      if ( defined($logFileName) ) {
      	my $accessLog = Global::getCourseLogsDirectory().$logFileName;
      	#$error = "access Log is $accessLog";
      	#$error .="string is $string";
      	open(LOG, ">>$accessLog") or $error.= "Can't open course access log $accessLog";
      	print LOG $string;  #no format is forced on data.
      	close(LOG);
      } else {
      	$error = "Error: The file ID $logFileID is not recognized.";
      }
	return $error ;
}


1;