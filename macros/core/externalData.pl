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

sub _init_externalData { }

=head2 store_number_list

This is a answer checker that checks only that there are a list of real number values
and the purpose is to store in the database.

=head3 Example

Make a List object, but the contents doesn't matter.

  $ans = List(0);

Then in the visible problem block add the following

  BEGIN_PGML
  Enter a list of values as a vector.

  [_____]{$ans->cmp(list_checker => store_number_list(), key => 'my_list')}
  END_PGML

Note that you will need to add a key (this should be unique for the problem set)

=cut

sub store_number_list {
	return sub {
		my ($correct, $student, $ansHash, $value) = @_;
		my @errors;    # stores error messages

		# Make sure that the key is set
		my $key = $ansHash->{key};
		warn 'You must pass in the key to save the data.' unless $key;

		# Get the answer name for this input and store the name and key.
		RECORD_EXTRA_ANSWERS("_ext_data:$ansHash->{ans_label}:numeric_list:$key");

		# check that all numbers are real.
		my $all_real = 1;
		$all_real = $all_real && Value::isRealNumber($_) for (@$student);
		push(@errors, 'One of the numbers is not a real number') unless $all_real;

		return ($all_real ? scalar(@$student) : 0, @errors);
	}
}

=head2 store_scalar

This is a answer checker that preps a string or a real to be saved in the database.

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
  [_____]{$ans->cmp(checker => store_scalar('string'), key => 'my_string')}
  END_PGML

Note that you will need to add a key (this should be unique for the problem set)

Similarly, for a real, create a C<Real> MathObject with any value

  $num = Real(0);

Then in the visible problem block add the following

  BEGIN_PGML
  Enter a string
  [_____]{$ans->cmp(checker => store_scalar('real'), key => 'my_string')}
  END_PGML

=cut

sub store_scalar {
	my $type = shift;
	warn "The type $type is not a valid datatype" unless grep { $_ eq $type } qw(string real);
	return sub {
		my ($correct, $student, $ansHash, $value) = @_;
		my @errors;    # stores error messages

		# Make sure that the key is set
		my $key = $ansHash->{key};
		warn 'You must pass in the key to save the data.' unless $key;

		# Get the answer name for this input and store the name and key.
		RECORD_EXTRA_ANSWERS("_ext_data:$ansHash->{ans_label}:$type:$key");

		return 1;
	}
}
