=head1 NAME

contextFraction.pl - Implements a MathObject class for Fractions.

=head1 DESCRIPTION

This context implements a Fraction object that works like a Real, but
keeps the numerator and denominator separate.  It provides methods for
reducing the fractions, and for allowing fractions with a whole-number
preceeding it, as in 4 1/2 for "four and one half".  The answer
checker can require that students reduce their results, and there are
contexts that don't allow entery of decimal values (only fractions),
and that don't allow any operators or functions (other than division
and negation).

To use these contexts, first load the contextFraction.pl file:

	loadMacros("contextFraction.pl");

and then select the appropriate context -- one of the following:

	Context("Fraction");
	Context("Fraction-NoDecimals");
	Context("LimitedFraction");
        Context("LimitedProperFraction");

The first is the most general, and allows fractions to be intermixed
with real numbers, so 1/2 + .5 would be allowed.  Also, 1/2.5 is
allowed, though it produces a real number, not a fraction, since this
fraction class only implements fractions of integers.  All operators
and functions are defined, so there are no restrictions on what is
allowed by the student.

The second does not allow decimal numbers to be entered, but they can
still be produced as the result of function calls, or by named
constants such as "pi".  For example, 1/sqrt(2) is allowed (and
produces a real number result).  All functions and operations are
defined, and the only real difference between this and the previous
context is that decimal numbers can't be typed in explicitly.

The third context limits the operations that can be performed: in
addition to not being able to type decimal numbers, no operations
other than division and negation are allowed, and no function calls at
all.  Thus 1/sqrt(2) would be illegal, as would 1/2 + 2.  The student
must enter a whole number or a fraction in this context.  It is also
permissible to enter a whole number WITH a fraction, as in 2 1/2 for
"two and one half", or 5/2.

The fourth is the same as LimiteFraction, but students must enter proper
fractions, and results are shown as proper fractions.

You can use the Compute() function to generate fraction objects, or
the Fraction() constructor to make one explicitly.  For example:

	Context("Fraction");
	$a = Compute("1/2");
	$b = Compute("4 - 1/6");
	$c = Compute("(4/9)^(1/2)");
	
	Context("LimitedFraction");
	$d = Compute("4 2/3");
	$e = Compute("-1 1/2");
	
	$f = Fraction(-2,5);

Note that $c will be 2/3, $d will be 14/3, $e will be -3/2, and $f
will be -2/5.

Once you have created a fraction object, you can use it as you would
any real number.  For example:

	Context("Fraction");
	$a = Compute("1/2");
	$b = Compute("1/3");
	$c = $a - $b;
	$d = asin($a);
	$e = $b**2;

Here $c will be the equivalent of Compute("1/6"), $d will be
equivalent to Compute("pi/6"), and $e will be the same as Compute("1/9");

You can an answer checker for a fraction in the same way as you do for
ALL MathObjects -- via its cmp() method:

	ANS(Compute("1/2")->cmp);

or

	$b = Compute("1/2");
	ANS($b->cmp);

There are several options to the cmp() method that control how the
answer checker will work.  The first is controls whether unreduced
fractions are accepted as correct.  Unreduced fractions are allowed in
the Fraction and Fraction-NoDecimals contexts, but not in the
LimitedFraction context.  You can control this using the
studentsMustReduceFractions option:

	Context("Fraction");
	ANS(Compute("1/2")->cmp(studentsMustReduceFractions=>1));

or

	Context("LimitedFraction");
	ANS(Compute("1/2")->cmp(studentsMustReduceFractions=>0));

The second controls whether warnings are issued when students don't
reduce their answers, or to mark the answer incorrect silently.  This
is specified by the showFractionReductionWarnings option.  The default
is to report the warnings, but this option has an effect only when
studentsMustReduceFractions is 1, and so only in the LimitedFraction
context.  For example,

	Context("LimitedFraction");
	ANS(Compute("1/2")->cmp(showFractionReductionWarnings=>0));

turns off these warnings.

The final option, requireFraction, specifies whether a fraction MUST
be entered (e.g. one would have to enter 2/1 for a whole number).  The
default is 0.

In addition to these options for cmp(), there are Context flags that
control how fractions are handled.  These include the following.

=over

=item S<C<< reduceFractions >>>

This determines whether fractions are reduced automatically when they
are created.  The default is to reduce fractions (except when
studentsMustReduceFractions is set), so Compute("4/6") would produce
the fraction 2/3.  To leave fractions unreduced, set
reduceFractions=>0.  The LimitedFraction context has
studentsMustReduceFractions set, so reduceFractions is unset
automatically for students, but not for correct answers, so
Fraction(2,4) would still produce 1/2, even though 2/4 would not be
allowed in a student answer.

=item S<C<< strictFractions >>>

This determines whether division is allowed only between integers or
not.  If you want to prevent division from accepting non-integers,
then set strictFractions=>1 (and also strictMinus=>1 and
strictMultiplication=>1).  These are all three 0 by default in the
Fraction and Fraction-NoDecimals contexts, but 1 in LimitedFraction.

=item S<C<< allowMixedNumbers >>>

This determines whether a space between a whole number and a fraction
is interpretted as implicit multiplication (as it usually would be in
WeBWorK), or as addition, allowing "4 1/2" to mean "4 and 1/2".  By
default, it acts as multiplication in the Fraction and
Fraction-NoDecimals contexts, and as addition in LimitedFraction.  If
you set allowMixedNumbers=>1 you should also set reduceConstants=>0.
This parameter used to be named allowProperFractions, which is
deprecated, but you can still use it for backward-compatibility.

=item S<C<< showMixedNumbers >>>

This controls whether fractions are displayed as proper fractions or
not.  When set, 5/2 will be displayed as 2 1/2 in the answer preview
area, otherwise it will be displayed as 5/2.  This flag is 0 by
default in the Fraction and Fraction-NoDecimals contexts, and 1 in
LimitedFraction.  This parameter used to be named showProperFractions,
which is deprecated, but you can still use it for
backward-compatibility.

=item S<C<< requireProperFractions >>>

This determines whether fractions MUST be entered as proper fractions.
It is 0 by default, meaning improper fractions are allowed.  When set,
you will not be able to enter 5/2 as a fraction, but must use "2 1/2".
This flag is allowed only when strictFractions is in effect.  Set it
to 1 only when you also set allowMixedNumbers, or you will not be able
to specify fractions bigger than one.  It is off by default in all
four contexts.  You should not set both requireProperFractions and
requirePureFractions to 1.

=item S<C<< requirePureFractions >>>

This determines whether fractions MUST be entered as pure fractions
rather than mixed numbers.  If allowMixedNumbers is also set, then
mixed numbers will be properly interpretted, but will produce a
warning message and be marked incorrect; that is, 2 3/4 would be
recognized as 2+3/4 rather than 2*3/4, but would generate a message
indicating that mixed numbers are not allowed.  This flag is off by
default in all four contexts.  You should not set both
requirePureFractions and requireProperFractions to 1.

=back

Fraction objects have two methods that can be useful when
reduceFractions is set to 0.  The reduce() method will reduce a
fraction to lowest terms, and the isReduced() method returns true when
the fraction is reduced and false otherwise.

If you wish to convert a fraction to its numeric (real number) form,
use the Real() constructor to coerce it to a real.  E.g.,

	$a = Compute("1/2");
	$r = Real($a);

would set $r to the value 0.5.  Similarly, use Fraction() to convert a
real number to (an approximating) fraction.  E.g.,

	$r = Real(.5);
	$a = Fraction($r);

would set $a to be 1/2.  The fraction produced is good to about 6
decimal places, so it can't be used for numbers that are too small.

A side-effect of using the Fraction context is that fractions can be
used to take powers of negative numbers when the reduced form of the
fraction has an odd denominator.  Thus (-8)^(1/3) will produce -2 as a
result, while in the standard Numeric context it would produce an
error.

=cut

sub _contextFraction_init {context::Fraction::Init()};

###########################################################################

package context::Fraction;

#
#  Initialize the contexts and make the creator function.
#
sub Init {
  my $context = $main::context{Fraction} = Parser::Context->getCopy("Numeric");
  $context->{name} = "Fraction";
  $context->{pattern}{signedNumber} = '(?:'.$context->{pattern}{signedNumber}.'|-?\d+/-?\d+)';
  $context->operators->set(
     "/"  => {class => "context::Fraction::BOP::divide"},
     "//" => {class => "context::Fraction::BOP::divide"},
     "/ " => {class => "context::Fraction::BOP::divide"},
     " /" => {class => "context::Fraction::BOP::divide"},
     "u-" => {class => "context::Fraction::UOP::minus"},
     " "  => {precedence => 2.8, string => ' *'},
     " *" => {class => "context::Fraction::BOP::multiply", precedence => 2.8},
     #  precedence is lower to get proper parens in string() and TeX() calls
     "  " => {precedence => 2.7, associativity => 'left', type => 'bin', string => ' ',
              class => 'context::Fraction::BOP::multiply', TeX => [' ',' '], hidden => 1},
  );
  $context->flags->set(
    reduceFractions => 1,
    strictFractions => 0, strictMinus => 0, strictMultiplication => 0,
    allowMixedNumbers => 0,  # also set reduceConstants => 0 if you change this
    requireProperFractions => 0,
    requirePureFractions => 0,
    showMixedNumbers => 0,
  );
  $context->reduction->set('a/b' => 1,'a b/c' => 1, '0 a/b' => 1);
  $context->{value}{Fraction} = "context::Fraction::Fraction";
  $context->{value}{Real} = "context::Fraction::Real";
  $context->{parser}{Value} = "context::Fraction::Value";
  $context->{parser}{Number} = "Parser::Legacy::LimitedNumeric::Number";
  $context->{precedence}{Fraction} = $context->{precedence}{Infinity} + .5;  # Fractions are above Infinity

  $context = $main::context{'Fraction-NoDecimals'} = $context->copy;
  $context->{name} = "Fraction-NoDecimals";
  Parser::Number::NoDecimals($context);
  $context->{error}{msg}{"You are not allowed to type decimal numbers in this problem"} =
    "You are only allowed to enter fractions, not decimal numbers";

  $context = $main::context{LimitedFraction} = $context->copy;
  $context->{name} = "LimitedFraction";
  $context->operators->undefine(
     '+', '-', '*', '* ', '^', '**',
     'U', '.', '><', 'u+', '!', '_', ',',
  );
  $context->parens->undefine('|','{','[');
  $context->functions->disable('All');
  $context->flags->set(
    strictFractions => 1, strictMinus => 1, strictMultiplication => 1,
    allowMixedNumbers => 1, reduceConstants => 0,
    showMixedNumbers => 1,
  );
  $context->{cmpDefaults}{Fraction} = {studentsMustReduceFractions => 1};

  $context = $main::context{LimitedProperFraction} = $context->copy;
  $context->flags->set(requireProperFractions => 1);

  main::PG_restricted_eval('sub Fraction {Value->Package("Fraction()")->new(@_)};');
}

#
#  Convert a real to a reduced fraction approximation
#
sub toFraction {
  my $context = shift; my $x = shift;
  my $Real = $context->Package("Real");
  my $d = 1000000;
  my ($a,$b) = reduce(int($x*$d),$d);
  return [$Real->make($a),$Real->make($b)];
}

#
#  Greatest Common Divisor
#
sub gcd {
  my $a = abs(shift); my $b = abs(shift);
  ($a,$b) = ($b,$a) if $a < $b;
  return $a if $b == 0;
  my $r = $a % $b;
  while ($r != 0) {
    ($a,$b) = ($b,$r);
    $r = $a % $b;
  }
  return $b;
}

#
#  Least Common Multiple
#
sub lcm {
  my ($a,$b) = @_;
  return ($a/gcd($a,$b))*$b;
}


#
#  Reduced fraction
#
sub reduce {
  my $a = shift; my $b = shift;
  ($a,$b) = (-$a,-$b) if $b < 0;
  my $gcd = gcd($a,$b);
  return ($a/$gcd,$b/$gcd);
}

###########################################################################

package context::Fraction::BOP::divide;
our @ISA = ('Parser::BOP::divide');

#
#  Create a Fraction or Real from the given data
#
sub _eval {
  my $self = shift; my $context = $self->{equation}{context};
  return $_[0]/$_[1] if Value::isValue($_[0]) || Value::isValue($_[1]);
  my $n = $context->Package("Fraction")->make($context,@_);
  $n->{isHorizontal} = 1 if $self->{def}{noFrac};
  return $n;
}

#
#  When strictFraction is in effect, only allow division
#  with integers and negative integers
#
sub _check {
  my $self = shift;
  $self->SUPER::_check;
  return unless $self->context->flag("strictFractions");
  $self->Error("The numerator of a fraction must be an integer")
    unless $self->{lop}->class =~ /INTEGER|MINUS/;
  $self->Error("The denominator of a fraction must be a (non-negative) integer")
    unless $self->{rop}->class eq 'INTEGER';
  $self->Error("The numerator must be less than the denominator in a proper fraction")
    if $self->context->flag("requireProperFractions") && CORE::abs($self->{lop}->eval) >= CORE::abs($self->{rop}->eval);
}

#
#  Reduce the fraction, if it is one, otherwise do the usual reduce
#
sub reduce {
  my $self = shift;
  return $self->SUPER::reduce unless $self->class eq 'FRACTION';
  my $reduce = $self->{equation}{context}{reduction};
  return $self->{lop} if $self->{rop}{isOne} && $reduce->{'x/1'};
  $self->Error("Division by zero"), return $self if $self->{rop}{isZero};
  return $self->{lop} if $self->{lop}{isZero} && $reduce->{'0/x'};
  if ($reduce->{'a/b'}) {
    my ($a,$b) = context::Fraction::reduce($self->{lop}->eval,$self->{rop}->eval);
    if ($self->{lop}->class eq 'INTEGER') {$self->{lop}{value} = $a} else {$self->{lop}{op}{value} = -$a}
    $self->{rop}{value} = $b;
  }
  return $self;
}

#
#  Display minus signs outside the fraction
#
sub TeX {
  my $self = shift; my $bop = $self->{def};
  return $self->SUPER::TeX(@_) if $self->class ne 'FRACTION' || $bop->{noFrac};
  my ($precedence,$showparens,$position,$outerRight) = @_;
  $showparens = '' unless defined($showparens);
  my $addparens =
      defined($precedence) &&
      ($showparens eq 'all' || ($precedence > $bop->{precedence} && $showparens ne 'nofractions') ||
      ($precedence == $bop->{precedence} && ($bop->{associativity} eq 'right' || $showparens eq 'same')));

  my $TeX = $self->eval->TeX;
  $TeX = '\left('.$TeX.'\right)' if ($addparens);
  return $TeX;
}

#
#  Indicate if the value is a fraction or not
#
sub class {
  my $self = shift;
  return "FRACTION" if $self->{lop}->class =~ /INTEGER|MINUS/ &&
                       $self->{rop}->class eq 'INTEGER';
  return $self->SUPER::class;
}

###########################################################################

package context::Fraction::BOP::multiply;
our @ISA = ('Parser::BOP::multiply');

#
#  For proper fractions, add the integer to the fraction
#
sub _eval {
  my ($self,$a,$b)= @_;
  return ($a >= 0 ? $a + $b : $a - $b);
}

#
#  If the implied multiplication represents a proper fraction with a
#  preceeding integer, then switch to the proper fraction operator
#  (for proper handling of string() and TeX() calls), otherwise,
#  convert the object to a standard multiplication.
#
sub _check {
  my $self = shift;
  $self->SUPER::_check;
  my $isFraction = 0;
  my $allowMixedNumbers = $self->context->flag("allowProperFractions");
  $allowMixedNumbers = $self->context->flag("allowMixedNumbers")
    unless defined($allowMixedNumbers) && $allowMixedNumbers ne "";
  if ($allowMixedNumbers) {
    $isFraction = ($self->{lop}->class =~ /INTEGER|MINUS/ && !$self->{lop}{hadParens} &&
                   $self->{rop}->class eq 'FRACTION' && !$self->{rop}{hadParens} &&
                   $self->{rop}->eval >= 0);
  }
  if ($isFraction) {
    $self->Error("Mixed numbers are not allowed; you must use a pure fraction")
      if ($self->context->flag("requirePureFractions"));
    $self->{isFraction} = 1; $self->{bop} = "  ";
    $self->{def} = $self->context->{operators}{$self->{bop}};
    if ($self->{lop}->class eq 'MINUS') {
      #
      #  Hack to replace BOP with unary negation of BOP.
      #  (When check() is changed to accept a return value,
      #   this will not be necessary.)
      #
      my $copy = bless {%$self}, ref($self); $copy->{lop} = $copy->{lop}{op};
      my $neg = $self->Item("UOP")->new($self->{equation},"u-",$copy);
      map {delete $self->{$_}} (keys %$self);
      map {$self->{$_} = $neg->{$_}} (keys %$neg);
      bless $self, ref($neg);
    }
  } else {
    $self->Error("Can't use implied multiplication in this context",$self->{bop})
      if $self->context->flag("strictMultiplication");
    bless $self, $ISA[0];
  }
}

#
#  Indicate if the value is a fraction or not
#
sub class {
  my $self = shift;
  return "FRACTION" if $self->{isFraction};
  return $self->SUPER::class;
}

#
#  Reduce the fraction
#
sub reduce {
  my $self = shift;
  my $reduce = $self->{equation}{context}{reduction};
  my ($a,($b,$c)) = (CORE::abs($self->{lop}->eval),$self->{rop}->eval->value);
  if ($reduce->{'a b/c'}) {
    ($b,$c) = context::Fraction::reduce($b,$c) if $reduce->{'a/b'};
    $a += int($b/$c); $b = $b % $c;
    $self->{lop}{value} = $a;
    $self->{rop}{lop}{value} = $b;
    $self->{rop}{rop}{value} = $c;
    return $self->{lop} if $b == 0 || $c == 1;
  }
  return $self->{rop} if $a == 0 && $reduce->{'0 a/b'};
  return $self;
}

###########################################################################

package context::Fraction::UOP::minus;
our @ISA = ('Parser::UOP::minus');

#
#  For strict fractions, only allow minus on certain operands
#
sub _check {
  my $self = shift;
  $self->SUPER::_check;
  $self->{hadParens} = 1 if $self->{op}{hadParens};
  return unless $self->context->flag("strictMinus");
  my $uop = $self->{def}{string} || $self->{uop};
  $self->Error("You can only use '%s' with (non-negative) numbers",$uop)
    unless $self->{op}->class =~ /Number|INTEGER|FRACTION/;
}

#
#  class is MINUS if it is a negative number
#
sub class {
  my $self = shift;
  return "MINUS" if $self->{op}->class =~ /Number|INTEGER/;
  $self->SUPER::class;
}

#
#  make isNeg properly handle the modified class
#
sub isNeg {
  my $self = shift;
  return ($self->class =~ /UOP|MINUS/ && $self->{uop} eq 'u-' && !$self->{op}->{isInfinite});

}

###########################################################################

package context::Fraction::Value;
our @ISA = ('Parser::Value');

#
#  Indicate if the Value object is a fraction or not
#
sub class {
  my $self = shift;
  return "FRACTION" if $self->{value}->classMatch('Fraction');
  return $self->SUPER::class;
}

#
#  Handle reductions of negative fractions
#
sub reduce {
  my $self = shift;
  my $reduce = $self->context->{reduction};
  if ($self->{value}->class eq 'Fraction') {
    $self->{value} = $self->{value}->reduce;
    if ($reduce->{'-n'} && $self->{value}{data}[0] < 0) {
      $self->{value}{data}[0] = -$self->{value}{data}[0];
      return Parser::UOP::Neg($self);
    }
    return $self;
  }
  return $self->SUPER::reduce;
}

###########################################################################

package context::Fraction::Real;
our @ISA = ('Value::Real');

#
#  Allow Real to convert Fractions to Reals
#
sub new {
  my $self = shift; my $context = (Value::isContext($_[0]) ? shift : $self->context);
  my $x = shift;
  $x = $context->Package("Formula")->new($context,$x)->eval if ref($x) eq "" && $x =~ m!/!;
  $x = $x->eval if scalar(@_) == 0 && Value::classMatch($x,'Fraction');
  $self->SUPER::new($context,$x,@_);
}

#
#  Since the signed number pattern now include fractions, we need to make sure
#  we handle them when a real is made and it looks like a fraction
#
sub make {
  my $self = shift; my $context = (Value::isContext($_[0]) ? shift : $self->context);
  my $x = shift;
  $x = $context->Package("Formula")->new($context,$x)->eval if ref($x) eq "" && $x =~ m!/!;
  $x = $x->eval if scalar(@_) == 0 && Value::classMatch($x,'Fraction');
  $self->SUPER::make($context,$x,@_);
}

###########################################################################
###########################################################################
#
#  Implements the MathObject for fractions
#

package context::Fraction::Fraction;
our @ISA = ('Value');

sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $context = (Value::isContext($_[0]) ? shift : $self->context);
  my $x = shift; $x = [$x,@_] if scalar(@_) > 0;
  return $x->inContext($context) if Value::classMatch($x,'Fraction');
  $x = [$x] unless ref($x) eq 'ARRAY'; $x->[1] = 1 if scalar(@{$x}) == 1;
  Value::Error("Can't convert ARRAY of length %d to %s",scalar(@{$x}),Value::showClass($self))
    unless (scalar(@{$x}) == 2);
  $x->[0] = Value::makeValue($x->[0],context=>$context);
  $x->[1] = Value::makeValue($x->[1],context=>$context);
  return $x->[0] if Value::classMatch($x->[0],'Fraction') && scalar(@_) == 0;
  $x = context::Fraction::toFraction($context,$x->[0]->value) if Value::isReal($x->[0]) && scalar(@_) == 0;
  return $self->formula($x) if Value::isFormula($x->[0]) || Value::isFormula($x->[1]);
  Value::Error("Fraction numerators must be integers") unless isInteger($x->[0]);
  Value::Error("Fraction denominators must be integers") unless isInteger($x->[1]);
  my ($a,$b) = ($x->[0]->value,$x->[1]->value); ($a,$b) = (-$a,-$b) if $b < 0;
  Value::Error("Denominator can't be zero") if $b == 0;
  ($a,$b) = context::Fraction::reduce($a,$b) if $context->flag("reduceFractions");
  bless {data => [$a,$b], context => $context}, $class;
}

#
#  Produce a real if one of the terms is not an integer
#  otherwise produce a fraction.
#
sub make {
  my $self = shift; my $class = ref($self) || $self;
  my $context = (Value::isContext($_[0]) ? shift : $self->context);
  push(@_,0) if scalar(@_) == 0; push(@_,1) if scalar(@_) == 1;
  my ($a,$b) = @_; ($a,$b) = (-$a,-$b) if $b < 0;
  return $context->Package("Real")->make($context,$a/$b) unless isInteger($a) && isInteger($b);
  ($a,$b) = context::Fraction::reduce($a,$b) if $context->flag("reduceFractions");
  bless {data => [$a,$b], context => $context}, $class;
}

#
#  Promote to a fraction, allowing reals to be $x/1 even when
#  not an integer (later $self->make() will produce a Real in
#  that case)
#
sub promote {
  my $self = shift; my $class = ref($self) || $self;
  my $context = (Value::isContext($_[0]) ? shift : $self->context);
  my $x = (scalar(@_) ? shift : $self);
  if (scalar(@_) == 0) {
    return $x->inContext($context) if ref($x) eq $class;
    return (bless {data => [$x->value,1], context => $context}, $class) if Value::isReal($x);
    return (bless {data => [$x,1], context => $context}, $class) if Value::matchNumber($x);
  }
  return $x if Value::isValue($x) && $x->classMatch("Infinity");
  return $self->new($context,$x,@_);
}


#
#  Create a new formula from the number
#
sub formula {
  my $self = shift; my $value = shift;
  my $formula = $self->Package("Formula")->blank($self->context);
  my ($l,$r) = Value::toFormula($formula,@{$value});
  $formula->{tree} = $formula->Item("BOP")->new($formula,'/',$l,$r);
  return $formula;
}

#
#  Return the real number type
#
sub typeRef {return $Value::Type{number}}
sub length {2}

sub isZero {(shift)->{data}[0] == 0}
sub isOne {(shift)->eval == 1}

#
#  Return the real value
#
sub eval {
  my $self = shift;
  my ($a,$b) = $self->value;
  return $a/$b;
}

#
#  Parts are not Value objects, so don't transfer
#
sub transferFlags {}

#
#  Check if a value is an integer
#
sub isInteger {
  my $n = shift;
  $n = $n->value if Value::isReal($n);
  return $n =~ m/^-?\d+$/;
};

#
#  Get a flag that has been renamed
#
sub getFlagWithAlias {
  my $self = shift; my $flag = shift; my $alias = shift;
  return $self->getFlag($alias,$self->getFlag($flag));
}


##################################################
#
#  Binary operations
#

sub add {
  my ($self,$l,$r,$other) = Value::checkOpOrderWithPromote(@_);
  my (($a,$b),($c,$d)) = ($l->value,$r->value);
  my $M = context::Fraction::lcm($b,$d);
  return $self->inherit($other)->make($a*($M/$b)+$c*($M/$d),$M);
}

sub sub {
  my ($self,$l,$r,$other) = Value::checkOpOrderWithPromote(@_);
  my (($a,$b),($c,$d)) = ($l->value,$r->value);
  my $M = context::Fraction::lcm($b,$d);
  return $self->inherit($other)->make($a*($M/$b)-$c*($M/$d),$M);
}

sub mult {
  my ($self,$l,$r,$other) = Value::checkOpOrderWithPromote(@_);
  my (($a,$b),($c,$d)) = ($l->value,$r->value);
  return $self->inherit($other)->make($a*$c,$b*$d);
}

sub div {
  my ($self,$l,$r,$other) = Value::checkOpOrderWithPromote(@_);
  my (($a,$b),($c,$d)) = ($l->value,$r->value);
  Value::Error("Division by zero") if $c == 0;
  return $self->inherit($other)->make($a*$d,$b*$c);
}

sub power {
  my ($self,$l,$r,$other) = Value::checkOpOrderWithPromote(@_);
  my (($a,$b),($c,$d)) = ($l->value,$r->reduce->value);
  ($a,$b,$c) = ($b,$a,-$c) if $c < 0;
  my ($x,$y) = ($c == 1 ? ($a,$b) : ($a**$c,$b**$c));
  if ($d != 1) {
    if ($x < 0 && $d % 2 == 1) {$x = -(-$x)**(1/$d)} else {$x = $x**(1/$d)};
    if ($y < 0 && $d % 2 == 1) {$y = -(-$y)**(1/$d)} else {$y = $y**(1/$d)};
  }
  return $self->inherit($other)->make($x,$y) unless $x eq 'nan' || $y eq 'nan';
  Value::Error("Can't raise a negative number to a non-integer power") if $a*$b < 0;
  Value::Error("Result of exponention is not a number");
}

sub compare {
  my ($self,$l,$r) = Value::checkOpOrderWithPromote(@_);
  return $l->eval <=> $r->eval;
}

##################################################
#
#   Numeric functions
#

sub abs  {my $self = shift; $self->make(CORE::abs($self->{data}[0]),CORE::abs($self->{data}[1]))}
sub neg  {my $self = shift; $self->make(-($self->{data}[0]),$self->{data}[1])}
sub exp  {my $self = shift; $self->make(CORE::exp($self->eval))}
sub log  {my $self = shift; $self->make(CORE::log($self->eval))}
sub sqrt {my $self = shift; $self->make(CORE::sqrt($self->{data}[0]),CORE::sqrt($self->{data}[1]))}

##################################################
#
#   Trig functions
#

sub sin {my $self = shift; $self->make(CORE::sin($self->eval))}
sub cos {my $self = shift; $self->make(CORE::cos($self->eval))}

sub atan2 {
  my ($self,$l,$r,$other) = Value::checkOpOrderWithPromote(@_);
  return $self->inherit($other)->make(CORE::atan2($l->eval,$r->eval));
}

##################################################
#
#  Utility
#

sub reduce {
  my $self = shift;
  my ($a,$b) = context::Fraction::reduce($self->value);
  return $self->make($a,$b);
}

sub isReduced {
  my $self = shift;
  my (($a,$b),($c,$d)) = ($self->value,$self->reduce->value);
  return $a == $c && $b == $d;
}

##################################################
#
#  Formatting
#

sub string {
  my $self = shift; my $equation = shift; my $prec = shift;
  my ($a,$b) = @{$self->{data}}; my $n = "";
  return $a if $b == 1;
  if ($self->getFlagWithAlias("showMixedNumbers","showProperFractions") && CORE::abs($a) > $b)
    {$n = int($a/$b); $a = CORE::abs($a) % $b; $n .= " " unless $a == 0}
  $n .= "$a/$b" unless $a == 0 && $n ne '';
  $n = "($n)" if defined $prec && $prec >= 1;
  return $n;
}

sub TeX {
  my $self = shift; my $equation = shift; my $prec = shift;
  my ($a,$b) = @{$self->{data}}; my $n = "";
  return $a if $b == 1;
  if ($self->getFlagWithAlias("showMixedNumbers","showProperFractions") && CORE::abs($a) > $b)
    {$n = int($a/$b); $a = CORE::abs($a) % $b; $n .= " " unless $a == 0}
  my $s = ""; ($a,$s) = (-$a,"-") if $a < 0;
  $n .= ($self->{isHorizontal} ? "$s$a/$b" : "${s}{\\textstyle\\frac{$a}{$b}}")
    unless $a == 0 && $n ne '';
  $n = "\\left($n\\right)" if defined $prec && $prec >= 1;
  return $n;
}

sub pdot {
  my $self = shift; my $n = $self->string;
  $n = '('.$n.')' if $n =~ m![^0-9]!;  #  add parens if not just a number
  return $n;
}

###########################################################################
#
#  Answer Checker
#

sub cmp_defaults {(
  shift->SUPER::cmp_defaults(@_),
  ignoreInfinity => 1,
  studentsMustReduceFractions => 0,
  showFractionReduceWarnings => 1,
  requireFraction => 0,
)}

sub cmp_contextFlags {
  my $self = shift; my $ans = shift;
  return (
    $self->SUPER::cmp_contextFlags($ans),
    reduceFractions => !$ans->{studentsMustReduceFractions},
  );
}

sub cmp_class {"a fraction of integers"}

sub typeMatch {
  my $self = shift; my $other = shift; my $ans = shift;
  return 1 unless ref($other);
  return 0 if Value::isFormula($other);
  return 1 if $other->type eq 'Infinity' && $ans->{ignoreInfinity};
  return 0 if $ans->{requireFraction} && !$other->classMatch("Fraction");
  $self->type eq $other->type;
}

sub cmp_postprocess {
  my $self = shift; my $ans = shift;
  my $student = $ans->{student_value};
  return if $ans->{isPreview} ||
            !$ans->{studentsMustReduceFractions} ||
	    !Value::classMatch($student,'Fraction') ||
	    $student->isReduced;
  $ans->score(0);
  $self->cmp_Error($ans,"Your fraction is not reduced") if $ans->{showFractionReduceWarnings};
}

###########################################################################

1;
