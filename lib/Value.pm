package Value;
my $pkg = 'Value';
use vars qw($context $defaultContext %Type);
use strict;

#############################################################
#
#  Initialize the context
#

use Value::Context;

$defaultContext = Value::Context->new(
  lists => {
    'Point'  => {open => '(', close => ')'},
    'Vector' => {open => '<', close => '>'},
    'Matrix' => {open => '[', close => ']'},
    'List'   => {open => '(', close => ')'},
  },
  flags => {
    #
    #  For vectors:
    #
    ijk => 0,  # print vectors as <...>
    #
    #  word to use for infinity
    #
    infiniteWord => 'infinity',
    #
    #  For fuzzy reals:
    #
    useFuzzyReals => 1,
    tolerance    => 1E-4,
    tolType      => 'relative',
    zeroLevel    => 1E-14,
    zeroLevelTol => 1E-12,
    #
    #  For functions
    #
    limits => [-2,2],
    num_points => 5,
  },
);

$context = \$defaultContext;


#
#  Precedence of the various types
#    (They will be promoted upward automatically when needed)
#
$$context->{precedence} = {
   'Number'   =>  0,
   'Real'     =>  1,
   'Infinity' =>  2,
   'Complex'  =>  3,
   'Point'    =>  4,
   'Vector'   =>  5,
   'Matrix'   =>  6,
   'List'     =>  7,
   'Interval' =>  8,
   'Union'    =>  9,
   'String'   => 10,
   'Formula'  => 11,
};

#
#  Binding of perl operator to class method
#
$$context->{method} = {
   '+'   => 'add',
   '-'   => 'sub',
   '*'   => 'mult',
   '/'   => 'div',
   '**'  => 'power',
   '.'   => '_dot',  # see _dot below
   'x'   => 'cross',
   '<=>' => 'compare',
   'cmp' => 'cmp',
};

$$context->{pattern}{infinite} = '[-+]?inf(?:inity)?';
$$context->{pattern}{infinity} = '\+?inf(?:inity)?';
$$context->{pattern}{-infinity} = '-inf(?:inity)?';

push(@{$$context->{data}{values}},'method','precedence');

#############################################################

#
#  Check if a value is a number, complex, etc.
#
sub matchNumber   {my $n = shift; $n =~ m/^$$context->{pattern}{signedNumber}$/i}
sub matchInfinite {my $n = shift; $n =~ m/^$$context->{pattern}{infinite}$/i}
sub isReal    {class(shift) eq 'Real'}
sub isComplex {class(shift) eq 'Complex'}
sub isFormula {class(shift) eq 'Formula'}
sub isValue   {my $v = shift; return (ref($v) || $v) =~ m/^Value::/}

sub isNumber {
  my $n = shift;
  return $n->{tree}->isNumber if isFormula($n);
  return isReal($n) || isComplex($n) || matchNumber($n);
}

sub isRealNumber {
  my $n = shift;
  return $n->{tree}->isRealNumber if isFormula($n);
  return isReal($n) || matchNumber($n);
}

#
#  Convert non-Value objects to Values, if possible
#
sub makeValue {
  my $x = shift;
  return $x if ref($x);
  return Value::Real->make($x) if matchNumber($x);
  if (matchInfinite($x)) {
    my $I = Value::Infinity->new();
    $I = $I->neg if $x =~ m/^$$Value::context->{pattern}{-infinity}$/;
    return $I;
  }
  if ($Parser::installed) {return $x unless $$Value::context->{strings}{$x}}
  return Value::String->make($x);
}

#
#  Get a printable version of the class of an object
#
sub showClass {
  my $value = makeValue(shift);
  return "'".$value."'" unless Value::isValue($value);
  my $class = class($value);
  return showType($value) if ($class eq 'List');
  $class .= ' Number' if $class =~ m/^(Real|Complex)$/;
  $class .= ' of Intervals' if $class eq 'Union';
  $class = 'Word' if $class eq 'String';
  return 'a Formula that returns '.showType($value->{tree}) if ($class eq 'Formula');
  return 'an '.$class if $class =~ m/^[aeio]/i;
  return 'a '.$class;
}

#
#  Get a printable version of the type of an object
#
sub showType {
  my $value = shift;
  my $type = $value->type;
  if ($type eq 'List') {
    my $ltype = $value->typeRef->{entryType}{name};
    if ($ltype && $ltype ne 'unknown') {
      $ltype =~ s/y$/ie/;
      $type .= ' of '.$ltype.'s';
    }
  }
  return 'a Word' if $type eq 'String';
  return 'a Complex Number' if $value->isComplex;
  return 'an '.$type if $type =~ m/^[aeio]/i;
  return 'a '.$type;
}

#
#  Return a string describing a value's type
#
sub getType {
  my $equation = shift; my $value = shift;
  my $strings = $equation->{context}{strings};
  if (ref($value) eq 'ARRAY') {
    return 'Interval' if ($value->[0] =~ m/^[(\[]$/ && $value->[-1] =~ m/^[)\]]$/);
    my ($type,$ltype);
    foreach my $x (@{$value}) {
      $type = getType($equation,$x);
      if ($type eq 'value') {
        $type = $x->type if $x->class eq 'Formula';
        $type = 'Number' if $x->class eq 'Complex' || $type eq 'Complex';
      }
      $ltype = $type if $ltype eq '';
      return 'List' if $type ne $ltype;
    }
    return 'Point' if $ltype eq 'Number';
    return 'Matrix' if $ltype =~ m/Point|Matrix/;
    return 'List';
  }
  elsif (Value::isFormula($value)) {return 'Formula'}
  elsif (Value::class($value) eq 'Infinity') {return 'String'}
  elsif (Value::isReal($value)) {return 'Number'}
  elsif (Value::isValue($value)) {return 'value'}
  elsif (ref($value)) {return 'unknown'}
  elsif (defined($strings->{$value})) {return 'String'}
  elsif (Value::isNumber($value)) {return 'Number'}
  return 'unknown';
}

#
#  Get a string describing a value's type,
#    and convert the value to a Value object (if needed)
#
sub getValueType {
  my $equation = shift; my $value = shift;
  my $type = Value::getType($equation,$value);
  if ($type eq 'String') {$type = $Value::Type{string}}
  elsif ($type eq 'Number') {$type = $Value::Type{number}}
  elsif ($type eq 'value') {$type = $value->typeRef}
  elsif ($type =~ m/unknown|Formula/) {
    $equation->Error("Can't convert ".Value::showClass($value)." to a constant");
  } else {
    $type = 'Value::'.$type, $value = $type->new(@{$value}) unless $type eq 'value';
    $type = $value->typeRef;
  }
  return ($value,$type);
}

#
#  Convert a list of values to a list of formulas (called by Parser::Value)
#  
sub toFormula {
  my $formula = shift;
  my $processed = 0;
  my @f = (); my $vars = {};
  foreach my $x (@_) {
    if (isFormula($x)) {
      $formula->{context} = $x->{context}, $processed = 1 unless $processed;
      $formula->{variables} = {%{$formula->{variables}},%{$x->{variables}}};
      push(@f,$x->{tree}->copy($formula));
    } else {
      push(@f,Parser::Value->new($formula,$x));
    }
  }
  return (@f);
}

#
#  Convert a list of values (and open and close parens)
#    to a formula whose type is the list type associated with
#    the parens.  If the formula is constant, evaluate it.
#
sub formula {
  my $self = shift; my $values = shift;
  my $class = $self->class;
  my $list = $$context->lists->get($class);
  my $open = $list->{'open'};
  my $close = $list->{'close'};
  my $formula = Value::Formula->blank;
  my @coords = Value::toFormula($formula,@{$values});
  $formula->{tree} = Parser::List->new($formula,[@coords],0,
     $formula->{context}{parens}{$open},$coords[0]->typeRef,$open,$close);
#   return $formula->eval if scalar(%{$formula->{variables}}) == 0;
  return $formula;
}

#
#  A shortcut for new() that creates an instance of the object,
#    but doesn't do the error checking.  We assume the data are already
#    known to be good.
#
sub make {
  my $self = shift; my $class = ref($self) || $self;
  bless {data => [@_]}, $class;
}

#
#  Return a type structure for the item
#    (includes name, length of vectors, and so on)
#
sub Type {
  my $name = shift; my $length = shift; my $entryType = shift;
  $length = 1 unless defined $length;
  return {name => $name, length => $length, entryType => $entryType,
          list => (defined $entryType), @_};
}

#
#  Some predefined types
#
%Type = (
  number  => Value::Type('Number',1),
  complex => Value::Type('Number',2),
  string  => Value::Type('String',1),
  unknown => Value::Type('unknown',0,undef,list => 1)
);

#
#  Return various information about the object
#
sub value {return @{(shift)->{data}}}                  # the value of the object (as an array)
sub data {return (shift)->{data}}                      # the reference to the value
sub length {return (shift)->typeRef->{length}}         # the number of coordinates
sub type {return (shift)->typeRef->{name}}             # the object type
sub entryType {return (shift)->typeRef->{entryType}}   # the coordinate type
#
#  The the full type-hash for the item
#
sub typeRef {
  my $self = shift;
  return Value::Type($self->class, $self->length, $Value::Type{number});
}
#
#  The Value.pm object class
#
sub class {
  my $self = shift; my $class = ref($self) || $self;
  $class =~ s/Value:://;
  return $class;
}

#
#  Get an element from a point, vector, matrix, or list
#
sub extract {
  my $M = shift; my $i;
  while (scalar(@_) > 0) {
    return unless Value::isValue($M);
    $i = shift; $i-- if $i > 0;
    Value::Error("Can't extract element number '$i' (index must be an integer)")
      unless $i =~ m/^-?\d+$/;
    $M = $M->data->[$i];
  }
  return $M;
}


#
#  Promote an operand to the same precedence as the current object
#
sub promotePrecedence {
  my $self = shift; my $other = shift;
  my $sprec = $$context->{precedence}{class($self)};
  my $oprec = $$context->{precedence}{class($other)};
  return defined($oprec) && $sprec < $oprec;
}

sub promote {shift}

#
#  Default stub to call when no function is defined for an operation
#
sub nomethod {
  my ($l,$r,$flag,$op) = @_;
  my $call = $$context->{method}{$op}; 
  if (defined($call) && $l->promotePrecedence($r)) {return $r->$call($l,!$flag)}
  my $error = "Can't use '$op' with ".$l->class."-valued operands";
  $error .= " (use '**' for exponentiation)" if $op eq '^';
  Value::Error($error);
}

#
#  Stubs for the sub-classes
#
sub add   {nomethod(@_,'+')}
sub sub   {nomethod(@_,'-')}
sub mult  {nomethod(@_,'*')}
sub div   {nomethod(@_,'/')}
sub power {nomethod(@_,'**')}
sub cross {nomethod(@_,'x')}

#
#  If the right operand is higher precedence, we switch the order.
#  
#  If the right operand is also a Value object, we do the object's
#  dot method to combine the two objects of the same class.
#
#  Otherwise, since . is used for string concatenation, we want to retain
#  that.  Since the resulting string is often used in Formula and will be
#  parsed again, we put parentheses around the values to guarantee that
#  the values will be treated as one mathematical unit.  For example, if
#  $f = Formula("1+x") and $g = Formula("y") then Formula("$f/$g") will be
#  (1+x)/y not 1+(x/y), as it would be without the implicit parentheses.
# 
sub _dot {
  my ($l,$r,$flag) = @_;
  return Value::_dot($r,$l,!$flag) if ($l->promotePrecedence($r));
  return $l->dot($r,$flag) if (Value::isValue($r));
  $l = $l->stringify; $l = '('.$l.')' unless $$Value::context->flag('StringifyAsTeX');
  return ($flag)? ($r.$l): ($l.$r);
}
#
#  Some classes override this
#
sub dot {
  my ($l,$r,$flag) = @_;
  my $tex = $$Value::context->flag('StringifyAsTeX');
  $l = $l->stringify; $l = '('.$l.')' if $tex;
  if (ref($r)) {$r = $r->stringify; $r = '('.$l.')' if $tex}
  return ($flag)? ($r.$l): ($l.$r);
}

#
#  Compare the values of the objects
#    (list classes should replace this)
#
sub compare {
  my ($l,$r,$flag) = @_;
  if ($l->promotePrecedence($r)) {return $r->compare($l,!$flag)}
  return $l->value <=> $r->value;
}

#
#  Compare the values as strings
#
sub cmp {
  my ($l,$r,$flag) = @_;
  if ($l->promotePrecedence($r)) {return $r->compare($l,!$flag)}
  $l = $l->stringify; $r = $r->stringify if Value::isValue($r);
  if ($flag) {my $tmp = $l; $l = $r; $r = $tmp}
  return $l cmp $r;
}

#
#  Generate the various output formats
#  (can be replaced by sub-classes)
#
sub stringify {
  my $self = shift;
  return $self->TeX() if $$Value::context->flag('StringifyAsTeX');
  $self->string;
}
sub string {shift->value}
sub TeX {shift->string(@_)}
#
#  For perl, call the appropriate constructor around the objects data
#
sub perl {
  my $self = shift; my $parens = shift; my $matrix = shift;
  my $class = $self->class; my $mtype = $class eq 'Matrix';
  my $perl; my @p = ();
  foreach my $x (@{$self->data}) {
    if (Value::isValue($x)) {push(@p,$x->perl(0,$mtype))} else {push(@p,$x)}
  }
  @p = ("'".$self->{open}."'",@p,"'".$self->{close}."'") if $class eq 'Interval';
  if ($matrix) {
    $perl = '['.join(',',@p).']';
  } else {
    $perl = $class.'('.join(',',@p).')';
    $perl = '('.$perl.')' if $parens == 1;
  }
  return $perl;
}

#
#  Stubs for when called by Parser
#
sub eval {shift}
sub reduce {shift}

sub ijk {
  Value::Error("Can't use method 'ijk' with objects of type '".(shift)->class."'");
}

#
#  Report an error
#
sub Error {
  my $message = shift;
  $$context->setError($message,'');
#  die $message . traceback();
  die $message . getCaller();
}

#
#  Try to locate the line and file where the error occurred
#  
sub getCaller {
  my $frame = 2;
  while (my ($pkg,$file,$line,$subname) = caller($frame++)) {
    return " at line $line of $file\n" 
      unless $pkg =~ /^(Value|Parser)/ ||
             $subname =~ m/^(Value|Parser).*(new|call)$/;
  }
  return "";
}

#
#  For debugging
#
sub traceback {
  my $frame = 2;
  my $trace = '';
  while (my ($pkg,$file,$line,$subname) = caller($frame++)) 
    {$trace .= " in $subname at line $line of $file\n"}
  return $trace;
}

###########################################################################
#
#  Load the sub-classes.
#

use Value::Real;
use Value::Complex;
use Value::Infinity;
use Value::Point;
use Value::Vector;
use Value::Matrix;
use Value::List;
use Value::Interval;
use Value::Union;
use Value::String;
# use Value::Formula;

use Value::AnswerChecker;  #  for WeBWorK

###########################################################################

use vars qw($installed);
$Value::installed = 1;

###########################################################################
###########################################################################
#
#    To Do:
#
#  Make Complex class include more of Complex1.pm
#  Make better interval comparison
#  
###########################################################################

1;
