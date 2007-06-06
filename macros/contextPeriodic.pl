
=head1 contextPeriodic.pl

The features in this file will probably be added to the Real and
Complex contexts in the future and this file will not be needed.

=cut

=head3 RealPeriodic

	usage    Context("Numeric");
			 $a = Real("pi/2")->with(period=>pi);
			 $a->cmp   # will match pi/2,  3pi/2 etc.


=cut



package RealPeriodic;
@ISA = ("Value::Real");

sub new {
  my $self = shift; my $class = ref($self) || $self;
  bless Value::Real->new(@_), $class;
}

sub compare {
  my ($l,$r,$flag) = @_; my $self = shift;
  my $m = $l->{period};
  return $self->SUPER::compare(@_) unless defined $m;
  if ($l->promotePrecedence($r)) {return $r->compare($l,!$flag)}
  $r = Value::Real::promote($r); if ($flag) {my $tmp = $l; $l = $r; $r = $tmp}
  if ($self->{logPeriodic}) {
    return 1 if $l eq "0" || $r eq "0"; # non-fuzzy checks
    $l = log($l); $r = log($r);
  }
  return modulo($l-$r+$m/2,$m) <=> $m/2;
}

sub modulo {
  my $a = shift;  my $b = shift;
  $a = Value::Real->new($a); $b = Value::Real->new($b); # just in case
  return Value::Real->new(0) if $b eq "0"; # non-fuzzy check
  my $m = ($a/$b)->value;
  my $n = int($m); $n-- if $n > $m; # act as floor() rather than int()
  return $a - $n*$b;
}

sub isReal {1}

=head3 ComplexPeriodic

	usage    Context("Complex");
			 $z0 = Real("i^i")->with(period=>2pi, logPeriodic=>1);
			 $z0->cmp   # will match exp( i (ln(1) + Arg(pi/2)+2k pi ) )

=cut


package ComplexPeriodic;
@ISA = ("Value::Complex");

sub new {
  my $self = shift; my $class = ref($self) || $self;
  bless Value::Complex->new(@_), $class;
}

sub compare {
  my ($l,$r,$flag) = @_; my $self = shift;
  my $m = $l->{period};
  return $self->SUPER::compare(@_) unless defined $m;
  if ($l->promotePrecedence($r)) {return $r->compare($l,!$flag)}
  $r = Value::Complex::promote($r); if ($flag) {my $tmp = $l; $l = $r; $r = $tmp}
  if ($self->{logPeriodic}) {
    return 1 if $l eq "0" || $r eq "0"; # non-fuzzy checks
    $l = log($l); $r = log($r);
  }
  return modulo($l-$r+$m/2,$m) <=> $m/2;
}

sub modulo {
  my $a = shift;  my $b = shift;
  $a = Value::Complex->new($a); $b = Value::Complex->new($b); # just in case
  return Value::Complex->new(0) if $b eq "0"; # non-fuzzy check
  my $m = ($a/$b)->Re->value;
  my $n = int($m); $n-- if $n > $m; # act as floor() rather than int()
  return $a - $n*$b;
}

sub isComplex {1}

package main;

$context{Complex} = Parser::Context->getCopy(\%context,"Complex");
$context{Complex}{precedence}{ComplexPeriodic} = $context{Complex}{precedence}{Complex} + .5;
$context{Complex}{precedence}{RealPeriodic} = $context{Real}{precedence}{Complex} + .5;

$context{Numeric} = Parser::Context->getCopy(\%context,"Numeric");
$context{Numeric}{precedence}{RealPeriodic} = $context{Numeric}{precedence}{Complex} + .5;

sub Complex {ComplexPeriodic->new(@_)}
sub Real {RealPeriodic->new(@_)}
