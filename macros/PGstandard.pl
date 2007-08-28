
=head1 NAME

PGstandard.pl - Load standard PG macro packages.

=head1 SYNOPSIS

 loadMacros('PGstandard.pl');

=head1 DESCRIPTION

PGstandard.pl loads the following macro files:

=over

=item * PG.pl

=item * PGbasicmacros.pl

=item * PGanswermacros.pl

=item * PGauxiliaryFunctions.pl

=back

=cut

loadMacros(
	"PG.pl",
	"PGbasicmacros.pl",
	"PGanswermacros.pl",
	"PGauxiliaryFunctions.pl",
);

1;
