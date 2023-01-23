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

nondecimal_base.pl - Handles conversions to and from non-decimal bases.

=head1 DESCRIPTION

The subroutine C<convertBase> converts nubmers to and from bases up to hexadecimal.

    $x = 47;
    $x2 = convertBase($x, to => 2);

    $y16 = convertBase('2EF9', from => 16);

This can be used in problems with base conversion.

    $x = random(200,500);
    $x_16 = Real(convertBase($x, to => 16));

    BEGIN_PGML
    Convert the number [$x] (in decimal) to base-16

    [$x] = [___]{$x_16} [`_{16}`]
    END_PGML

=cut

sub _nondecimal_base_init { }

=head2 convertBase

Convert positive integers to and from non-decimal bases.

    convertBase($x, %opts)

where C<$x> is an integer or string representation of a string.  If the base (in either the
C<to> or C<from> options is greater than 1, the standard digits 'ABCDEF' are used for the next
6 digits.)

If instead, you wish to use other characters, the option C<digits> is an arrayref of digits.
See an example below.

The subroutine checks to ensure that the input number contain only provided digits (in the given
base), that the C<to> and C<from> options are only between 2 and 16 and that the C<digits>
option is an array ref.

=head3 Options

=over

=item *

C<to> the base to convert the integer to.  C<to> should be an integer between 2 and 16. The
default is 10.

=item *

C<from> the base that the number C<$x> is in.  C<from> should be an integer between 2 and 16.
The default is 10.

=item *

C<digits> is an arrayref of digits to use.  The default is C<[0..9, 'A'..'F']>

=back

=head3 Examples

=over

=item *

C<convertBase(87, to=E<gt> 2)> returns C<1010111>

=item *

C<convertBase('9FE8', from =E<gt> 16)> returns C<40936>

=item *

The standard digits up to hexadecimal is 0..9,A,B,..,F.  You can use non-standard digits
with the C<digits> option.  The following uses 'T' and 'E' for the digit ten and eleven in
base 12.

    convertBase(56, to => 12, digits = [0..9,'T','E'])

=back

=cut

sub convertBase {
	my ($value, %opts) = @_;
	$from = $opts{from} // 10;
	$to   = $opts{to}   // 10;

	return Value::Error('The option digits must be an array ref of length at least the larger of to/from.')
		if defined($opts{digits})
		&& (ref($opts{digits}) ne 'ARRAY' || scalar(@{ $opts{digits} }) < $to || scalar(@{ $opts{digits} }) < $from);
	my @digits =
		defined($opts{digits}) && ref($opts{digits}) eq 'ARRAY' ? @{ $opts{digits} } : ('0' .. '9', 'A' .. 'F');

	return Value::Error('The base of conversion must be between 2 and 16')
		unless $from >= 2 && $from <= 16 && $to >= 2 && $to <= 16;

	# regular expression only of the digits up to from.
	my $digre = '^[' . join('', @digits[ 0 .. ($from - 1) ]) . ']+$';
	return Value::Error('The input number must consist only of the digits') unless $value =~ qr/$digre/;

	# The value in base 10
	my $val_10 = 0;
	# convert $value to base 10 if not in that base
	if ($from != 10) {
		my $from_b = 1;
		for my $ch (reverse($value =~ m/./g)) {
			# convert
			my $v = (grep { $digits[$_] eq $ch } (0 .. $#digits))[0];
			$val_10 += $v * $from_b;
			$from_b *= $from;
		}
	} else {
		$val_10 = $value;
	}
	return $val_10 if $to == 10;

	# Convert to the $to base
	my $val_b = '';
	do {
		my $dig = $val_10 % $to;
		$val_10 = int($val_10 / $to);
		$val_b  = "$digits[$dig]$val_b";
	} while ($val_10 > 0);
	return $val_b;
}
