#
#  Make a class for infinity?
#  Allow printing of ijk format for vectors
#  
#  Share more items between Value and Parser::Context?
#  
package Value;
my $pkg = 'Value';
use vars qw(%precedence %parens %Type);
use strict;

#
#  Pattern for a generic real number
# 
my $numPattern = '-?(\d+(\.\d*)?|\.\d+)(E[-+]?\d+)?';

#
#  Precedence of the various types
#    (They will be promoted upward automatically when needed)
#
%precedence = (
   'Number'   => 0,
   'Complex'  => 1,
   'Point'    => 2,
   'Vector'   => 3,
   'Matrix'   => 4,
   'List'     => 5,
   'Interval' => 6,
   'Union'    => 7,
   'Formula'  => 8,
);

#
#  Binding of perl operator to class method
#
my %method = (
   '+'   => 'add',
   '-'   => 'sub',
   '*'   => 'mult',
   '/'   => 'div',
   '**'  => 'power',
   '.'   => '_dot',  # see _dot below
   'x'   => 'cross',
   '<=>' => 'compare',
);

#
#  The type of paren used in printing a value
#
%parens = (
   'Point'  => {open => '(', close => ')'},
   'Vector' => {open => '<', close => '>'},
   'Matrix' => {open => '[', close => ']'},
   'List'   => {open => '(', close => ')'},
);

#
#  Check if a value is a number, complex, etc.
#
sub matchNumber {my $n = shift; $n =~ m/^$numPattern$/oi}
sub isComplex {my $n = shift; class($n) eq 'Complex'}
sub isFormula {my $value = shift; class($value) eq 'Formula'}
sub isValue {my $value = shift; ref($value) =~ m/^Value::/}

sub isNumber {
  my $n = shift;
  return 1 if matchNumber($n) || isComplex($n);
  return (isFormula($n)  && $n->{tree}->isNumber);
}

sub isRealNumber {
  my $n = shift;
  return 1 if matchNumber($n);
  return (isFormula($n) && $n->{tree}->isRealNumber);
}

#
#  Get a printable version of the class of an object
#
sub showClass {
  my $value = shift;
  return "'".$value."'" unless ref($value);
  my $class = class($value);
  return showType($value->{tree}) if $class eq 'Formula';
  return 'an '.$class if substr($class,0,1) =~ m/[aeio]/i;
  return 'a '.$class;
}

#
#  Get a printable version of the type of an object
#
sub showType {
  my $value = shift;
  my $type = $value->type;
  return 'a Complex Number' if $value->isComplex;
  return 'an '.$type if substr($type,0,1) =~ m/[aeio]/i;
  return 'a '.$type;
}

#
#  return a string describing a value's type
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
  my $open = $Value::parens{$class}{'open'};
  my $close = $Value::parens{$class}{'close'};
  my $formula = Value::Formula->blank;
  my @coords = Value::toFormula($formula,@{$values});
  $formula->{tree} = Parser::List->new($formula,[@coords],0,
     $formula->{context}{parens}{$open},$coords[0]->typeRef,$open,$close);
  return $formula->eval if scalar(%{$formula->{variables}}) == 0;
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
  my $sprec = $precedence{class($self)};
  my $oprec = $precedence{class($other)};
  return defined($oprec) && $sprec < $oprec;
}

#
#  Default stub to call when no function is defined for an operation
#
sub nomethod {
  my ($l,$r,$flag,$op) = @_;
  my $call = $method{$op}; 
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
#  parsed again, we put parentheses around the values to guearantee that
#  the values will be treated as one mathematical unit.  For example, if
#  $f = Formula("1+x") and $g = Formula("y") then Formula("$f/$g") will be
#  (1+x)/y not 1+(x/y), as it would be without the implicit parentheses.
# 
sub _dot {
  my ($l,$r,$flag) = @_;
  return Value::_dot($r,$l,!$flag) if ($l->promotePrecedence($r));
  return $l->dot($r,$flag) if (Value::isValue($r));
  $l = '(' . $l->string . ')';
  return ($flag)? ($r.$l): ($l.$r);
}
#
#  Some classes override this
#
sub dot   {
  my ($l,$r,$flag) = @_;
  $l = '(' . $l->stringify . ')'; $r = '(' . $r->stringify . ')' if ref($r);
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
#  Generate the various output formats
#
sub stringify {shift->value}
sub string {my $self = shift; shift; $self->stringify(@_)}
sub TeX {(shift)->string(@_)}
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

#
#  Report an error
#
sub Error {
  my $message = shift;
  my $context = $Parser::Context::contextTable->{current};
  $context->setError($message,'') if (defined($context));
  die $message . Value::getCaller();
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

###########################################################################
#
#  Load the sub-classes.
#

use Value::Complex;
use Value::Point;
use Value::Vector;
use Value::Matrix;
use Value::List;
use Value::Interval;
use Value::Union;
# use Value::Formula;

###########################################################################

1;

