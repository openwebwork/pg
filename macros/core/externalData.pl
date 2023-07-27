################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2023 The WeBWorK Project, https://github.com/openwebwork
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

C<externalData.pl> - Macro that provides some parsing and way to send data from
a problem to the database. This is useful for using data common to multiple problems.

=cut

sub _externalData_init { }

=head2 store_number_list

This is a answer checker that checks only that there are a list of real number values
and the purpose is to store in the database.

=head3 Example

Make a List object, but the contents doesn't matter.

    $ans = List(0);

Then in the visible problem block add the following

    BEGIN_PGML
    Enter a list of values as a vector.

    [_____]{$ans->cmp(list_checker => store_number_list('my_list')}
    END_PGML

Note that you will need to add a key as an argument to the C<store_number_list>
(this should be unique for the problem set)

=cut

sub store_number_list {
	my ($key) = @_;
	warn 'You must pass in the key to save the data.' unless $key;
	return sub {
		my ($correct, $student, $ansHash, $value) = @_;

		# check that all numbers are real.
		for (@$student) {
			return 0, 'One of the numbers is not a real number' unless Value::classMatch($_, 'Real');
		}

		# Get the answer name for this input and store the name and key.
		RECORD_EXTRA_ANSWERS("_ext_data:$ansHash->{ans_label}:$key");

		return scalar(@$student);
	}
}

=head2 store_string

This is a answer checker that checks for a string to be saved in the database.

=head3 Example

If you are storing a string, the student will probably enter in an arbitrary string,
either use the contextArbitraryString macro or add possible strings to the current context.

    loadMacros('contextArbitraryString.pl');
    Context('ArbitraryString');

Make a String object, but the contents doesn't matter.

    $ans = String('');

Then in the visible problem block add the following

    BEGIN_PGML
    Enter a string
    [_____]{$ans->cmp(checker => store_string('my_string')}
    END_PGML

Note that you will need to add a key as an argument to C<store_string> and it
should be unique for the set.

=cut

sub store_string {
	my ($key) = @_;
	warn 'You must pass in the key to save the data.' unless $key;

	return sub {
		my ($correct, $student, $ansHash, $value) = @_;

		return 0, 'The input string must have at length greater than 0' unless length($student) > 0;

		# Get the answer name for this input and store the name and key.
		RECORD_EXTRA_ANSWERS("_ext_data:$ansHash->{ans_label}:$key");

		return 1;
	}
}

=head2 store_number

This is a answer checker that checks for a number to be saved in the database.

=head3 Example

To store a number, create a C<Real> MathObject with any value

    $num = Real(0);

Then in the visible problem block add the following

    BEGIN_PGML
    Enter a number
    [_____]{$num->cmp(checker => store_real('my_string')}
    END_PGML

Note that you will need to add a key as an argument to C<store_number> and it
should be unique for the set.

=cut

sub store_number {
	my ($key) = @_;
	warn 'You must pass in the key to save the data.' unless $key;

	return sub {
		my ($correct, $student, $ansHash, $value) = @_;

		return 0, 'The input is not a real number' unless Value::classMatch($student, 'Real');

		# Get the answer name for this input and store the name and key.
		RECORD_EXTRA_ANSWERS("_ext_data:$ansHash->{ans_label}:$key");
		return 1;
	}
}
