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


package PGstatistics;
use strict;
#use Exporter;
#use UUID::Tiny  ':std';
use PGcore;
use PGresource;

our @ISA =  qw ( PGcore  );  # look up features in PGcore -- in this case we want the environment.


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


}

# ##########################################
# Write the given data to a csv file.
# Return the URL if the file is written, 
# an empty string otherwise
#
sub write_array_to_CSV {
		my $filePath = shift;
		my @data = @_;

}


