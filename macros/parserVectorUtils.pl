#####################################################################
#
#   Some utility routines that are useful in vector problems
#

sub _parserVectorUtils_init {}; # don't reload this file

##################################################

#
#  formats a vector name (should be used in math mode)
#
#  Vectors will be in bold italics in HTML modes, and
#  will be overlined in TeX modes.  (Bold italic could also work in
#  TeX modes, but the low resolution on screen made it less easy
#  to distinguish the difference between bold and regular letters.)
#
sub Overline {
  my $v = shift;
  my $HTML = '<B><I>'.$v.'</B></I>';
  MODES(
    TeX => "\\overline{$v}",
    HTML => $HTML,
    HTML_tth => '\begin{rawhtml}'.$HTML.'\end{rawhtml}',
    HTML_dpng => "\\overline{$v}",
  );
}

#
#  This gets a bold letter in TeX as well as HTML modes.
#  Although \boldsymbol{} works fine on screen in latex2html mode,
#  the PDF file produces non-bold letters.  I haven't been able to
#  track this down, so used \mathbf{} in TeX mode, which produces
#  roman bold, not math-italic bold.
#
sub BoldMath {
  my $v = shift;
  my $HTML = '<B><I>'.$v.'</B></I>';
  MODES(
    TeX => "\\boldsymbol{$v}", #  doesn't seem to work in TeX mode
#    TeX => "\\mathbf{$v}",      #  gives non-italic bold in TeX mode
    Latex2HTML => "\\boldsymbol{$v}",
    HTML => $HTML,
    HTML_tth => '\begin{rawhtml}'.$HTML.'\end{rawhtml}',
    HTML_dpng => "\\boldsymbol{$v}",
  );
}

#
#  Grad sumbol
#
$GRAD = '\nabla ';

#
#  Create a non-zero point with the given number of coordinates
#  with the given random range (which defaults to (-5,5,1)).
#
#  non_zero_point(n,a,b,c)
#
sub non_zero_point {
  my $n = shift; my $k = $n; my @v = ();
  my $a = shift || -5; my $b = shift || $a + 10; my $c = shift || 1;
  while ($k--) {push(@v,random($a,$b,$c))}
  if (norm(Point(@v)) == 0) {$v[random(0,$n-1,1)] = non_zero_random($a,$b,$c)}
  return Point(@v);
}
sub non_zero_point2D {non_zero_point(2,@_)}
sub non_zero_point3D {non_zero_point(3,@_)}

#
#  Same but for Vectors
#
sub non_zero_vector {Vector(non_zero_point(@_))}
sub non_zero_vector2D {non_zero_vector(2,@_)}
sub non_zero_vector3D {non_zero_vector(3,@_)}

#
#  Form the vector-parametric form for a line given its point and vector
#
#  Usage:  Line(P,V); or Line(P,V,'t');
#
#  where P is the point and V the direction vector for the line, and
#  t is the variable to use (default is 't').
#
#  Ex:  Line([1,-3],[2,1]) produces Vector("1+2t","-3+t").
#  Ex:  Line(Point(1,-3),Vector(2,1)) produces Vector("1+2t","-3+t").
#
sub Line {
  my @p = Point(shift)->value; my @v = Vector(shift)->value;
  my $t = shift; $t = 't' unless $t; $t = Formula($t);
  my @coords = ();
  die "Dimensions of point and vector don't match" unless $#p == $#v;
  foreach my $i (0..$#p) {push(@coords,($p[$i]+$v[$i]*$t)->reduce)}
  return Vector(@coords);
}

#
#  Creates a displayable string for a plane given its
#  normal vector and a point on the plane.  (Better to use
#  the ImplicitPlane class from parserImplicitPlane.pl).
#
#  Usage:  Plane(P,N);
#
sub Plane {
  my $P = Point(shift); my $N = Vector(shift); my @N = $N->value;
  my $xyz = shift; $xyz = ['x','y','z'] unless defined($xyz);
  die "Number of variables doesn't match dimension of normal vector"
    unless scalar(@N) == scalar(@{$xyz});
  my @terms = ();
  foreach my $i (0..$#N) {push(@terms,$N[$i]->TeX.$xyz->[$i])}
  Formula(join(' + ',@terms))->reduce->TeX . " = " . ($N.$P)->TeX;
}

1;
