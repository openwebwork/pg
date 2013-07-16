
################################################################################
# WeBWorK Online Homework Delivery System
# Copyright © 2013 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader: $
# Author: Kelly Black - kjblack@gmail.com
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



package Statistics;

#use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw( );
@EXPORT    = qw( );
$VERSION = '0.01';


# ##########################################
# Initialize the class
# Expected argument: a ref to a valid PGcore object 
#
sub new {
	my $class = shift;	
	my $self = {
			PG		=>	shift
	};	

	bless $self, $class;

}

# ##########################################
# Create an alias to a csv file.
# Return the url that can be used in a browser 
# to access the file.
#
sub make_csv_alias {

		my $self         = shift;
		my $studentLogin = shift;
		my $problemSeed  = shift;
		my $setname      = shift;
		my $prob         = shift;

		$studentLogin =~ s/Q/QQ/g;
		$studentLogin =~ s/\./-Q-/g;
		$studentLogin =~ s/\,/-Q-/g;
		$studentLogin =~ s/\@/-Q-/g;
		my $filePath = "$studentLogin-$problemSeed-set" . $setName . "prob$prob.html";
		$filePath = $self->{PG}->convertPath($filePath);
		$filePath = $self->{PG}->surePathToTmpFile("data")."/".$filePath;
		my $url = $self->{PG}->{PG_alias}->make_alias($filePath);

		($filePath,$url);
}

# ##########################################
# Write the given data to a csv file.
# Return the URL if the file is written, 
# an empty string otherwise
#
sub write_array_to_CSV {
		my $self         = shift;
		my $headerTitle = shift;
		my $filePath = shift;
		my @data = @_;

#	if( not -e $filePath # does it exist?
#	  or ((stat "$templateDirectory"."$main::envir{probFileName}")[9] > (stat $filePath)[9]) # source has changed
#	  or $refreshCachedImages
#	) {
 		#createFile($filePath, $main::tmp_file_permission, $main::numericalGroupID);
#		local(*OUTPUT);  # create local file handle so it won't overwrite other open files.
# 		open(OUTPUT, ">$filePath")||warn ("$0","Can't open $filePath<BR>","");
# 		chmod( 0777, $filePath);
# 		print OUTPUT $graph->draw|| warn("$0","Can't print graph to $filePath<BR>","");
# 		close(OUTPUT)||warn("$0","Can't close $filePath<BR>","");
#	}


}


1;
