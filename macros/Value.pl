

=head1 DESCRIPTION

 #
 #  Declares constructors for MathObjects
 #

=cut

=head3 Constructors for the various Mathobject types

=pod

MathObjects are objects which behave much like you would expect
their true mathematical counterparts to behave.

MathObject types (classes) -- defined in Value.pl

    Standard
        Real
              Behave like real numbers
        Infinity
              Extended real numbers (infinities)  -- Also complex
              numbers???
            infinity
            - infinity
            infinite (either plus or minus infinity)
        Complex
              Behave like complex numbers.  The interpretations of plus
              and times are those standardly used for mathematical
              complex numbers
    List objects -- which means that they involve delimiters
      (parentheses) of some type.
        Point
        Vector
        Matrix
        List
    Subsets of Reals
        Intervals
        Sets (finite collections of points
        Union (of intervals and sets)
    String   -- special purpose
          Allows comparison with a string
    Formula -- roughly a function with values as defined above.
        Complex object whose output is one of the MathObject values
          listed above.
        A formula object contains a parse tree inside it which allows
          you to calculate output values from given input values.
        This MathObject is more complicated than the ones above.

Constructing MathObjects
	$a = Real(3.5);
	$a = Real("345/45");
	$c = Complex(5,4);
	$c = Complex("5+4i");

See Value.pm for MathObject methods

See Parser.pm for information on turning strings into MathObjects.

=cut


sub String   {Value->Package("String()")->new(@_)}
sub Real     {Value->Package("Real()")->new(@_)}
sub Complex  {Value->Package("Complex()")->new(@_)}
sub Point    {Value->Package("Point()")->new(@_)}
sub Vector   {Value->Package("Vector()")->new(@_)}
sub Matrix   {Value->Package("Matrix()")->new(@_)}
sub List     {Value->Package("List()")->new(@_)}
sub Interval {Value->Package("Interval()")->new(@_)}
sub Set      {Value->Package("Set()")->new(@_)}
sub Union    {Value->Package("Union()")->new(@_)}

sub ColumnVector {Value->Package("Vector()")->new(@_)->with(ColumnVector=>1,open=>undef,close=>undef)}

# sub Formula  {Value->Package("Formula()")->new(@_)}  # in Parser.pl

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
 #  as well as 3*pi instead of 3*pi()

 #sub i ()  {Value->Package("Complex")->i};   #  defined in PG.pl
 #sub pi () {Value->Package("Complex")->pi};  #  defined in PG.pl
 #sub Infinity () {Value->Package("Infinity")->new()} # defined in PG.pl

=cut

sub _Value_init {};  # don't let loadMacros load it again

###########################################################################

1;
