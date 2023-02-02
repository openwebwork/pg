################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2022 The WeBWorK Project, https://github.com/openwebwork
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

externalData.pl - Macro that reads and writes data from a problem to the database.
This is useful for using data common to multiple problems.

=cut

sub store_number_list {
	my ($correct, $student, $ansHash, $value) = @_;
	my @errors = ();    # stores error messages

	# Make sure that the key is set
	my $key = $ansHash->{key};
	warn 'You must pass in the key to save the data.' unless $key;

	# Get the answer name for this input and store the name and key.
	my $ans_name = $ansHash->{ans_label};
	push @{ $main::PG->{flags}{KEPT_EXTRA_ANSWERS} }, "_ext_data:$ans_name:$key";

	# check that all numbers are real.
	my $all_real = 1;
	$all_real = $all_real && Value::isRealNumber($_) for (@$student);
	push(@errors, 'One of the numbers is not a real number') unless $all_real;

	return ($all_real ? scalar(@$student) : 0, @errors);
}
