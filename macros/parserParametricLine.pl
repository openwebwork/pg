loadMacros('Parser.pl');

sub _parserParametricLine_init {}; # don't reload this file

######################################################################
#
#  This is a Parser class that implements parametric lines as
#  a subclass of the Formula class.  The standard ->cmp routine
#  will work for this, provided we define the compare() function
#  needed by the overloaded ==.  We assign the special precedence
#  so that overloaded operations will be promoted to the ones below.
#
#  Use ParametricLine(point,vector) or ParametricLine(formula)
#  to create a ParametricLine object.  You can pass an optional
#  additional parameter that indicated the variable to use for the
#  parameter for the line.
#
#  Usage examples:
#
#      $L = ParametricLine(Point(3,-1,2),Vector(1,1,3));
#      $L = ParametricLine([3,-1,2],[1,1,3]);
#      $L = ParametricLine("<t,1-t,2t-3>");
#
#      $p = Point(3,-1,2); $v = Vector(1,1,3);
#      $L = ParametricLine($p,$v);
#
#      $t = Formula('t'); $p = Point(3,-1,2); $v = Vector(1,1,3);
#      $L = ParametricLine($p+$t*$v);
#
#      Context()->constants->are(a=>1+pi^2); # won't guess this value
#      $L = ParametricLine("(a,2a,-1) + t <1,a,a^2>");
#
#  Then use
#
#     ANS($L->cmp);
#
#  to get the answer checker for $L.
#

#
#  Define a new context for lines
#
$context{ParametricLine} = Context("Vector")->copy();
$context{ParametricLine}->variables->are(t=>'Real');
$context{ParametricLine}->{precedence}{ParametricLine} = 
  $context{ParametricLine}->{precedence}{special};
$context{ParametricLine}->reduction->set('(-x)-y'=>0);
#
#  Make it active
#
Context("ParametricLine");

#
#  Syntactic sugar
#
sub ParametricLine {ParametricLine->new(@_)}

#
#  Define the subclass of Formula
#
package ParametricLine;
our @ISA = qw(Value::Formula);

sub new {
  my $self = shift; my $class = ref($self) || $self;
  my ($p,$v,$line,$t);
  return shift if scalar(@_) == 1 && ref($_[0]) eq $class;
  $_[0] = Value::Point->new($_[0]) if ref($_[0]) eq 'ARRAY';
  $_[1] = Value::Vector->new($_[1]) if ref($_[1]) eq 'ARRAY';
  if (scalar(@_) >= 2 && Value::class($_[0]) eq 'Point' &&
                         Value::class($_[1]) eq 'Vector') {
    $p = shift; $v = shift;
    $t = shift || Value::Formula->new('t');
    $line = $p + $t*$v;
  } else {
    $line = Value::Formula->new(shift);
    Value::Error("Your formula doesn't look like a parametric line")
      unless $line->type eq 'Vector';
    $t = shift || (keys %{$line->{variables}})[0];
    Value::Error("A line can't be just a constant vector") unless $t;
    $p = Value::Point->new($line->eval($t=>0));
    $v = Value::Vector->new($line->eval($t=>1) - $p);
    Value::Error("Your formula isn't linear in the variable %s",$t)
      unless $line == $p + Value::Formula->new($t) * $v;
  }
  Value::Error("The direction vector for a parametric line can't be the zero vector")
    if ($v->norm == 0);
  $line->{p} = $p; $line->{v} = $v;
  $line->{isValue} = $line->{isFormula} = 1;
  return bless $line, $class;
}

#
#  Two parametric lines are equal if they have 
#  parallel direction vectors and either the same
#  points or the vector between the points is
#  parallel to the (common) direction vector.
#
sub compare {
  my ($l,$r,$flag) = @_;
  if ($l->promotePrecedence($r)) {return $r->compare($l,!$flag)}
  $r = ParametricLine->new($r);
  if ($flag) {my $tmp = $l; $l = $r; $r = $tmp}
  my ($lp,$lv) = ($l->{p},$l->{v});
  my ($rp,$rv) = ($r->{p},$r->{v});
  return $lv <=> $rv unless ($lv->isParallel($rv));
  return 0 if $lp == $rp || $lv->isParallel($rp-$lp);
  return $lp <=> $rp;
}

sub cmp_class {'a Parametric Line'};

sub cmp_defaults {(
  shift->SUPER::cmp_defaults,
  showEqualErrors => 0,  # don't show problems evaluating student answer
  ignoreInfinity => 0,   # report infinity as an error
)}

#
#  Report some errors that were stopped by the showEqualErrors=>0 above.
#
sub cmp_postprocess {
  my $self = shift; my $ans = shift;
  my $error = $$Value::context->{error}{message};
  $self->cmp_error($ans) 
    if $error =~ m/^(Your formula (isn't linear|doesn't look)|A line can't|The direction vector)/;
}

1;
