

=head1 Value.pl DESCRIPTION

#
#  Declares functions needed for Value.pm
#

=cut

=head3 Constructors for the various types

#
# String, Real, Complex, Point, Vector, Matrix, List, Interval, Set, Union, ColumnVector
#

=cut


sub String   {Value->Package("String")->new(@_)}
sub Real     {Value->Package("Real")->new(@_)}
sub Complex  {Value->Package("Complex")->new(@_)}
sub Point    {Value->Package("Point")->new(@_)}
sub Vector   {Value->Package("Vector")->new(@_)}
sub Matrix   {Value->Package("Matrix")->new(@_)}
sub List     {Value->Package("List")->new(@_)}
sub Interval {Value->Package("Interval")->new(@_)}
sub Set      {Value->Package("Set")->new(@_)}
sub Union    {Value->Package("Union")->new(@_)}

sub ColumnVector {Value->Package("Vector")->new(@_)->with(ColumnVector=>1,open=>undef,close=>undef)}

# sub Formula  {Value->Package("Formula")->new(@_)}  # in Parser.pl

=head3 Closed($point)

#
#  Make a point or list a closed interval.
#  (Obsolete: use $x->with(open=>'[',close=>']') instead.)
#

=cut

sub Closed {
  my $x = shift;
  if (Value::isValue($x)) {$x->{open} = '['; $x->{close} = ']'}
  return $x;
}

=head3 NOTE:

###########################################################################
#
#  Make it possible to use  1+3*i  in perl rather than  1+3*$i or 1+3*i()
#

#sub i ()  {Value->Package("Complex")->i};   #  defined in Parser.pl
#sub pi () {Value->Package("Complex")->pi};  #  defined in dangerousMacros.pl


=cut

sub _Value_init {};  # don't let loadMacros load it again

###########################################################################

1;
