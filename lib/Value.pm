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
    'Set'    => {open => '{', close => '}'},
  },
  flags => {
    #
    #  For vectors:
    #
    ijk => 0,  # print vectors as <...>
    #
    #  For strings:
    #
    allowEmptyStrings => 1,
    infiniteWord => 'infinity',
    #
    #  For intervals and unions:
    #
    ignoreEndpointTypes => 0,
    reduceSets => 1,
    reduceSetsForComparison => 1,
    reduceUnions => 1,
    reduceUnionsForComparison => 1,
    #
    #  For fuzzy reals:
    #
    useFuzzyReals => 1,
    tolerance    => 1E-4,
    tolType      => 'relative',
    zeroLevel    => 1E-14,
    zeroLevelTol => 1E-12,
    #
    #  For Formulas:
    #
    limits       => [-2,2],
    num_points   => 5,
    granularity  => 1000,
    resolution   => undef,
    max_adapt    => 1E8,
    checkUndefinedPoints => 0,
    max_undefined => undef,
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
   'Set'      =>  9,
   'Union'    => 10,
   'String'   => 11,
   'Formula'  => 12,
   'special'  => 20,
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
   '.'   => '_dot',       # see _dot below
   'x'   => 'cross',
   '<=>' => 'compare',
   'cmp' => 'compare_string',
};

$$context->{pattern}{infinite} = '[-+]?inf(?:inity)?';
$$context->{pattern}{infinity} = '\+?inf(?:inity)?';
$$context->{pattern}{-infinity} = '-inf(?:inity)?';

push(@{$$context->{data}{values}},'method','precedence');

#
#  Get the value of a flag from the object itself,
#  or from the context, or from the default context
#  or from the given default, whichever is found first.
#
sub getFlag {
  my $self = shift; my $name = shift;
  return $self->{$name} if ref($self) && defined($self->{$name});
  return $self->{context}{flags}{$name} if ref($self) && defined($self->{context}) && defined($self->{context}{flags}{$name});
  return $$Value::context->{flags}{$name} if defined($$Value::context->{flags}{$name});
  return shift;
}

sub copy {
  my $self = shift;
  my $copy = {%{$self}}; $copy->{data} = [@{$self->{data}}];
  foreach my $x (@{$copy->{data}}) {$x = $x->copy if Value::isValue($x)}
  return bless $copy, ref($self);
}

#############################################################

#
#  Check if a value is a number, complex, etc.
#
sub matchNumber   {my $n = shift; $n =~ m/^$$context->{pattern}{signedNumber}$/i}
sub matchInfinite {my $n = shift; $n =~ m/^$$context->{pattern}{infinite}$/i}
sub isReal    {class(shift) eq 'Real'}
sub isComplex {class(shift) eq 'Complex'}
sub isFormula {
  my $v = shift;
  return class($v) eq 'Formula' ||
         (ref($v) && ref($v) ne 'ARRAY' && $v->{isFormula});
}
sub isValue {
  my $v = shift;
  return (ref($v) || $v) =~ m/^Value::/ ||
         (ref($v) && ref($v) ne 'ARRAY' && ref($v) ne 'CODE' && $v->{isValue});
}

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

sub isZero {
  my $self = shift;
  return 0 if scalar(@{$self->{data}}) == 0;
  foreach my $x (@{$self->{data}}) {return 0 unless $x eq "0"}
  return 1;
}

sub isOne {0}

sub isSetOfReals {0}
sub canBeInUnion {
  my $self = shift;
  return $self->length == 2 && $self->typeRef->{entryType}{name} eq 'Number' &&
    $self->{open} =~ m/^[\(\[]$/ && $self->{close} =~ m/^[\)\]]$/;
}

#
#  Convert non-Value objects to Values, if possible
#
sub makeValue {
  my $x = shift; my %params = (showError => 0, makeFormula => 1, @_);
  return $x if ref($x) && ref($x) ne 'ARRAY';
  return Value::Real->make($x) if matchNumber($x);
  if (matchInfinite($x)) {
    my $I = Value::Infinity->new();
    $I = $I->neg if $x =~ m/^$$Value::context->{pattern}{-infinity}$/;
    return $I;
  }
  return Value::String->make($x)
    if !$Parser::installed || $$Value::context->{strings}{$x} ||
       ($x eq '' && $$Value::context->{flags}{allowEmptyStrings});
  return $x if !$params{makeFormula};
  Value::Error("String constant '%s' is not defined in this context",$x)
    if $params{showError};
  $x = Value::Formula->new($x);
  $x = $x->eval if $x->isConstant;
  return $x;
}

#
#  Get a printable version of the class of an object
#
sub showClass {
  my $value = makeValue(shift,makeFormula=>0);
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
  return 'an Infinity' if $type eq 'String' && $value->{isInfinite};
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
  elsif (Value::class($value) eq 'Infinity') {return 'Infinity'}
  elsif (Value::isReal($value)) {return 'Number'}
  elsif (Value::isValue($value)) {return 'value'}
  elsif (ref($value)) {return 'unknown'}
  elsif (defined($strings->{$value})) {return 'String'}
  elsif (Value::isNumber($value)) {return 'Number'}
  elsif ($value eq '' && $equation->{context}{flags}{allowEmptyStrings}) {return 'String'}
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
  elsif ($type eq 'Infinity') {$type = $Value::Type{infinity}}
  elsif ($type eq 'value' || $type eq 'Formula') {$type = $value->typeRef}
  elsif ($type eq 'unknown') {
    $equation->Error(["Can't convert %s to a constant",Value::showClass($value)]);
  } else {
    $type = 'Value::'.$type, $value = $type->new(@{$value});
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
      push(@f,$formula->{context}{parser}{Value}->new($formula,$x));
    }
  }
  return (@f);
}

#
#  Convert a list of values (and open and close parens)
#    to a formula whose type is the list type associated with
#    the parens.
#
sub formula {
  my $self = shift; my $values = shift;
  my $class = $self->class;
  my $list = $$context->lists->get($class);
  my $open = $list->{'open'};
  my $close = $list->{'close'};
  my $paren = $open; $paren = 'list' if $class eq 'List';
  my $formula = Value::Formula->blank;
  my @coords = Value::toFormula($formula,@{$values});
  $formula->{tree} = $formula->{context}{parser}{List}->new($formula,[@coords],0,
     $formula->{context}{parens}{$paren},$coords[0]->typeRef,$open,$close);
  $formula->{autoFormula} = 1;  # mark that this was generated automatically
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
#  Easy method for setting parameters of an object
#
sub with {
  my $self = shift; my %hash = @_;
  foreach my $id (keys(%hash)) {$self->{$id} = $hash{$id}}
  return $self;
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
  number   => Value::Type('Number',1),
  complex  => Value::Type('Number',2),
  string   => Value::Type('String',1),
  infinity => Value::Type('Infinity',1),
  unknown  => Value::Type('unknown',0,undef,list => 1)
);

#
#  Return various information about the object
#
sub value {return @{(shift)->{data}}}                  # the value of the object (as an array)
sub data {return (shift)->{data}}                      # the reference to the value
sub length {return scalar(@{(shift)->{data}})}         # the number of coordinates
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
  $class =~ s/.*:://;
  return $class;
}

#
#  Get an element from a point, vector, matrix, or list
#
sub extract {
  my $M = shift; my $i; my @indices = @_;
  return unless Value::isValue($M);
  @indices = $_[0]->value if scalar(@_) == 1 && Value::isValue($_[0]);
  while (scalar(@indices) > 0) {
    $i = shift @indices; $i-- if $i > 0; $i = $i->value if Value::isValue($i);
    Value::Error("Can't extract element number '%s' (index must be an integer)",$i)
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
  return 0 unless Value::isValue($other);
  my $sprec = $$context->{precedence}{class($self)};
  my $oprec = $$context->{precedence}{class($other)};
  return (defined($sprec) && defined($oprec) && $sprec < $oprec);
}

sub promote {shift}

#
#  Default stub to call when no function is defined for an operation
#
sub nomethod {
  my ($l,$r,$flag,$op) = @_;
  my $call = $$context->{method}{$op};
  if (defined($call) && $l->promotePrecedence($r)) {return $r->$call($l,!$flag)}
  my $error = "Can't use '%s' with %s-valued operands";
  $error .= " (use '**' for exponentiation)" if $op eq '^';
  Value::Error($error,$op,$l->class);
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
  return $r->_dot($l,!$flag) if ($l->promotePrecedence($r));
  return $l->dot($r,$flag) if (Value::isValue($r));
  if ($$Value::context->flag('StringifyAsTeX')) {$l = $l->TeX} else {$l = $l->pdot}
  return ($flag)? ($r.$l): ($l.$r);
}
#
#  Some classes override this
#
sub dot {
  my ($l,$r,$flag) = @_;
  my $tex = $$Value::context->flag('StringifyAsTeX');
  if ($tex) {$l = $l->TeX} else {$l = $l->pdot}
  if (ref($r)) {if ($tex) {$r = $r->TeX} else {$r = $r->pdot}}
  return ($flag)? ($r.$l): ($l.$r);
}

#
#  Some classes override this to add parens
#
sub pdot {shift->stringify}
  

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
sub compare_string {
  my ($l,$r,$flag) = @_;
  if ($l->promotePrecedence($r)) {return $r->compare_string($l,!$flag)}
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
  my $def = $$Value::context->lists->get($self->class);
  return $self->string unless $def;
  my $open = $self->{open};   $open  = $def->{open}  unless defined($open);
  my $close = $self->{close}; $close = $def->{close} unless defined($close);
  $open.join($def->{separator},@{$self->data}).$close;
}

sub string {
  my $self = shift; my $equation = shift;
  my $def = ($equation->{context} || $$Value::context)->lists->get($self->class);
  return $self->value unless $def;
  my $open = shift; my $close = shift;
  $open  = $self->{open}  unless defined($open);
  $open  = $def->{open}   unless defined($open);
  $close = $self->{close} unless defined($close);
  $close = $def->{close}  unless defined($close);
  my @coords = ();
  foreach my $x (@{$self->data}) {
    if (Value::isValue($x)) 
      {push(@coords,$x->string($equation))} else {push(@coords,$x)}
  }
  return $open.join($def->{separator},@coords).$close;
}

sub TeX {
  my $self = shift; my $equation = shift;
  my $context = $equation->{context} || $$Value::context;
  my $def = $context->lists->get($self->class);
  return $self->string(@_) unless $def;
  my $open = shift; my $close = shift;
  $open  = $self->{open}  unless defined($open);
  $open  = $def->{open}   unless defined($open);
  $close = $self->{close} unless defined($close);
  $close = $def->{close}  unless defined($close);
  $open =~ s/([{}])/\\$1/g; $close =~ s/([{}])/\\$1/g;
  $open = '\left'.$open if $open; $close = '\right'.$close if $close;
  my @coords = (); my $str = $context->{strings};
  foreach my $x (@{$self->data}) {
    if (Value::isValue($x)) {push(@coords,$x->TeX($equation))}
    elsif (defined($str->{$x}) && $str->{$x}{TeX}) {push(@coords,$str->{$x}{TeX})}
    else {push(@coords,$x)}
  }
  return $open.join(',',@coords).$close;
}

#
#  For perl, call the appropriate constructor around the object's data
#
sub perl {
  my $self = shift; my $parens = shift; my $matrix = shift;
  my $class = $self->class;
  my $mtype = $class eq 'Matrix'; $mtype = -1 if $mtype & !$matrix;
  my $perl; my @p = ();
  foreach my $x (@{$self->data}) {
    if (Value::isValue($x)) {push(@p,$x->perl(0,$mtype))} else {push(@p,$x)}
  }
  @p = ("'".$self->{open}."'",@p,"'".$self->{close}."'") if $class eq 'Interval';
  if ($matrix) {
    $perl = join(',',@p);
    $perl = '['.$perl.']' if $mtype > 0;
  } else {
    $perl = 'new '.ref($self).'('.join(',',@p).')';
    $perl = "($perl)->with(open=>'$self->{open}',close=>'$self->{close}')"
      if $class eq 'List' && $self->{open}.$self->{close} ne '()';
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
  Value::Error("Can't use method 'ijk' with objects of type '%s'",(shift)->class);
}

#
#  Report an error
#
sub Error {
  my $message = shift;
  $message = [$message,@_] if scalar(@_) > 0;
  $$context->setError($message,'');
  $message = $$context->{error}{message};
  die $message . traceback() if $$context->flags('showTraceback');
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
  my $frame = shift; $frame = 2 unless defined($frame);
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
use Value::Set;
use Value::Union;
use Value::String;
use Value::Formula;

use Value::WeBWorK;  # stuff specific to WeBWorK

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
#  Include context in objects within new() calls.
#  
###########################################################################

1;
