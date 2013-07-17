
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

		# Clean the student login string to make it appropriate for a file name.
		$studentLogin =~ s/Q/QQ/g;
		$studentLogin =~ s/\./-Q-/g;
		$studentLogin =~ s/\,/-Q-/g;
		$studentLogin =~ s/\@/-Q-/g;

		# Define the file name, clean it up and convert to a url.
		my $filePath = "$studentLogin-$problemSeed-set" . $setName . "prob$prob.html";
		$filePath = $self->{PG}->convertPath($filePath);
		$filePath = $self->{PG}->surePathToTmpFile("data")."/".$filePath;
		my $url = $self->{PG}->{PG_alias}->make_alias($filePath);

		# Remove the .html off the end and replace it with a .csv
		$filePath =~ s/\.html$/.csv/;
		$url      =~ s/\.html$/.csv/;

		($filePath,$url);
}

# ##########################################
# Write the given data to a csv file.
# Return the URL if the file is written, 
# an empty string otherwise
#
sub write_array_to_CSV {
		my $self        = shift;
		my $fileName    = shift;
		my $headerTitle = shift;
		my $filePath = shift;
		my @data = @_;

		# Open the file and write the header to the first row.
		local(*OUTPUT);  # create local file handle so it won't overwrite other open files.
 		open(OUTPUT, ">$fileName")||warn ("$0","Can't open $fileName<BR>","");
 		chmod( 0777, $filePath);
 		print OUTPUT ($headerTitle."\n") || warn("$0","Can't print data file to $fileName<BR>","");

		# Go through each data point and write it out.
		my $lupe;
		for($lupe=0;$lupe<=$#data;++$lupe)
		{
				print OUTPUT ($data[$lupe],"\n");
		}

		# Close it up and move on.
 		close(OUTPUT)||warn("$0","Can't close $filePath<BR>","");

}


1;
