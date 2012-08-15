package Value;
my $pkg = 'Value';
use vars qw($context $defaultContext %Type);
use Scalar::Util;
use strict; no strict "refs";

=head1 DESCRIPTION

Value (also called MathObjects) are intelligent versions of standard mathematical
objects.  They 'know' how to produce string or TeX or perl representations
of themselves.  They also 'know' how to compare themselves to student responses --
in other words they contain their own answer evaluators (response evaluators).
The standard operators like +, -, *, <, ==, >, etc, all work with them (when they
make sense), so that you can use these MathObjects in a natural way.  The comparisons
like equality are "fuzzy", meaning that two items are equal when they are "close enough"
(by tolerances that are set in the current Context).

=cut


=head3 Value context

 #############################################################
 #
 #  Initialize the context-- flags set
 #
	The following are list objects, meaning that they involve delimiters (parentheses)
	of some type.  They get overridden in lib/Parser/Context.pm

	lists => {
		'Point'  => {open => '(', close => ')'},
		'Vector' => {open => '<', close => '>'},
		'Matrix' => {open => '[', close => ']'},
		'List'   => {open => '(', close => ')'},
		'Set'    => {open => '{', close => '}'},
  	},

	The following context flags are set:

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


=cut

BEGIN {

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

}

=head3 Implemented MathObject types and their precedence

 #
 #  Precedence of the various types
 #    (They will be promoted upward automatically when needed)
 #

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

=cut

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
   '%'   => 'modulo',
   '<=>' => 'compare',
   'cmp' => 'compare_string',
};

$$context->{pattern}{infinite} = '[-+]?inf(?:inity)?';
$$context->{pattern}{infinity} = '\+?inf(?:inity)?';
$$context->{pattern}{-infinity} = '-inf(?:inity)?';

push(@{$$context->{data}{values}},'method','precedence');

#
#  Copy an item and its data
#
sub copy {
  my $self = shift;
  my $copy = {%{$self}}; $copy->{data} = [@{$self->{data}}];
  foreach my $x (@{$copy->{data}}) {$x = $x->copy if Value::isValue($x)}
  return bless $copy, ref($self);
}

=head3 getFlag

#
#  Get the value of a flag from the object itself, or from the
#  equation that created the object (if any), or from the AnswerHash
#  for the object (if it is being used as the source for an answer
#  checker), or from the object's context, or from the current
#  context, or use the given default, whichever is found first.
#

	Usage:   $mathObj->getFlag("showTypeWarnings");
	         $mathObj->getFlag("showTypeWarnings",1); # default is second parameter

=cut

sub getFlag {
  my $self = shift; my $name = shift;
  if (Value::isHash($self)) {
    return $self->{$name} if defined($self->{$name});
    if (defined $self->{equation}) {
      return $self->{equation}{$name} if defined($self->{equation}{$name});
      return $self->{equation}{equation}{$name}
	if defined($self->{equation}{equation}) && defined($self->{equation}{equation}{$name});
    }
  }
  my $context = $self->context;
  return $context->{answerHash}{$name}
    if defined($context->{answerHash}) && defined($context->{answerHash}{$name});  # use WW answerHash flags first
  return $context->{flags}{$name} if defined($context->{flags}{$name});
  return shift;
}

#
#  Get or set the context of an object
#
sub context {
  my $self = shift; my $context = shift;
  if (Value::isHash($self)) {
    if ($context && $self->{context} != $context) {
      $self->{context} = $context;
      if (defined $self->{data}) {
        foreach my $x (@{$self->{data}}) {$x->context($context) if Value::isBlessed($x)}
      }
    }
    return $self->{context} if $self->{context};
  }
  return $$Value::context;
}

#
#  Set context but return object
#
sub inContext {my $self = shift; $self->context(@_); $self}


#############################################################

#
#
#  The address of a Value object (actually ANY perl value).
#  Use this to compare two objects to see of they are
#  the same object (avoids automatic stringification).
#
sub address {oct(sprintf("0x%p",shift))}

sub isBlessed {Scalar::Util::blessed(shift) ne ""}
sub blessedClass {Scalar::Util::blessed(shift)}
sub blessedType {Scalar::Util::reftype(shift)}

sub isa {UNIVERSAL::isa(@_)}
sub can {UNIVERSAL::can(@_)}

sub isHash {
  my $self = shift;
  return ref($self) eq 'HASH' || blessedType($self) eq 'HASH';
}

sub subclassed {
  my $self = shift; my $obj = shift; my $method = shift;
  my $code = UNIVERSAL::can($obj,$method);
  return $code && $code ne $self->can($method);
}

#
#  Check if a value is a number, complex, etc.
#
sub matchNumber   {my $n = shift; $n =~ m/^$$Value::context->{pattern}{signedNumber}$/i}
sub matchInfinite {my $n = shift; $n =~ m/^$$Value::context->{pattern}{infinite}$/i}
sub isReal    {classMatch(shift,'Real')}
sub isComplex {classMatch(shift,'Complex')}
sub isContext {class(shift) eq 'Context'}
sub isFormula {classMatch(shift,'Formula')}
sub isParser  {my $v = shift; isBlessed($v) && $v->isa('Parser::Item')}
sub isValue {
  my $v = shift;
  return (ref($v) || $v) =~ m/^Value::/ || (isHash($v) && $v->{isValue}) || isa($v,'Value');
}

sub isNumber {
  my $n = shift;
  return $n->{tree}->isNumber if isFormula($n);
  return classMatch($n,'Real','Complex') || matchNumber($n);
}

sub isRealNumber {
  my $n = shift;
  return $n->{tree}->isRealNumber if isFormula($n);
  return isReal($n) || matchNumber($n);
}

sub isZero {
  my $self = shift;
  return 0 if scalar(@{$self->{data}}) == 0;
  foreach my $x (@{$self->{data}}) {return 0 if $x ne "0"}
  return 1;
}

sub isOne {0}

sub isSetOfReals {0}
sub canBeInUnion {
  my $self = shift;
  my $def = $self->context->lists->get($self->class);
  my $open = $self->{open}; $open = $def->{open}||$def->{nestedOpen} unless defined $open;
  my $close = $self->{close}; $close = $def->{close}||$def->{nestedClose} unless defined $close;
  return $self->length == 2 && $self->typeRef->{entryType}{name} eq 'Number' &&
    $open =~ m/^[\(\[]$/ && $close =~ m/^[\)\]]$/;
}

######################################################################

#
#  Value->Package(name[,noerror]])
#
#  Returns the package name for the specificied Value object class
#  (as specified by the context's {value} hash, or "Value::name").
#
sub Package {(shift)->context->Package(@_)}

#  Check if the object class matches one of a list of classes
#
sub classMatch {
  my $self = shift;
  return $self->classMatch(@_) if Value->subclassed($self,"classMatch");
  my $class = class($self); my $ref = ref($self);
  my $isHash = ($ref && $ref ne 'ARRAY' && $ref ne 'CODE');
  my $context = ($isHash ? $self->{context} || Value->context : Value->context);
  foreach my $name (@_) {
    my $isName = "is".$name;
    return 1 if $class eq $name || $ref eq "Value::$name" ||
                ($isHash && $self->{$isName}) ||
		$ref eq $context->Package($name,1) ||
		(isa($self,"Value::$name") &&
		   !($isHash && defined($self->{$isName}) && $self->{$isName} == 0));
  }
  return 0;
}

=head3 makeValue

	Usage:  Value::makeValue(45);

	Will create a Real mathObject.
 #
 #  Convert non-Value objects to Values, if possible
 #

=cut

sub makeValue {
  my $x = shift; return $x unless defined $x;
  my %params = (showError => 0, makeFormula => 1, context => Value->context, @_);
  my $context = $params{context};
  if (Value::isValue($x)) {
    return $x unless {@_}->{context};
    return $x->copy->inContext($context);
  }
  return $context->Package("Real")->make($context,$x) if matchNumber($x);
  if (matchInfinite($x)) {
    my $I = $context->Package("Infinity")->new($context);
    $I = $I->neg if $x =~ m/^$context->{pattern}{-infinity}$/;
    return $I;
  }
  return $context->Package("Complex")->make($context,$x->Re,$x->Im) if ref($x) eq "Complex1";
  return $context->Package("String")->make($context,$x)
    if !$Parser::installed || $context->{strings}{$x} ||
       ($x eq '' && $context->{flags}{allowEmptyStrings});
  return $x if !$params{makeFormula};
  Value::Error("String constant '%s' is not defined in this context",$x)
    if $params{showError};
  $x = $context->Package("Formula")->new($context,$x);
  $x = $x->eval if $x->isConstant;
  return $x;
}

=head3 showClass

	Usage:   TEXT( $mathObj -> showClass() );

		Will print the class of the MathObject

 #
 #  Get a printable version of the class of an object
 #  (used primarily in error messages)
 #

=cut

sub showClass {
  my $value = shift;
  if (ref($value) || $value !~ m/::/) {
    $value = Value::makeValue($value,makeFormula=>0);
    return "'".$value."'" unless Value::isValue($value);
  }
  return $value->showClass(@_) if Value->subclassed($value,"showClass");
  my $class = class($value);
  return showType($value) if Value::classMatch($value,'List');
  $class .= ' Number' if Value::classMatch($value,'Real','Complex');
  $class .= ' of Intervals' if Value::classMatch($value,'Union');
  $class = ($value eq '' ? 'Empty Value' : 'Word') if Value::classMatch($value,'String');
  return 'a Formula that returns '.showType($value->{tree}) if Value::isFormula($value);
  return 'an '.$class if $class =~ m/^[aeio]/i;
  return 'a '.$class;
}

=head3 showType

	Usage:   TEXT( $mathObj -> showType() );

		Will print the class of the MathObject

 #
 #  Get a printable version of the type of an object
 #  (the class and type are not the same.  For example
 #  a Formula-class object can be of type Number)
 #

=cut

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
  return 'an Empty Value' if $type eq 'String' && $value eq '';
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
  return $value->getType($equation,@_) if Value->subclassed($value,"getType");
  my $strings = $equation->{context}{strings};
  if (ref($value) eq 'ARRAY') {
    return 'Interval' if ($value->[0] =~ m/^[(\[]$/ && $value->[-1] =~ m/^[)\]]$/);
    my ($type,$ltype);
    foreach my $x (@{$value}) {
      $type = getType($equation,$x);
      if ($type eq 'value') {
        $type = $x->type if $x->classMatch('Formula');
        $type = 'Number' if $x->classMatch('Complex') || $type eq 'Complex';
      }
      $ltype = $type if $ltype eq '';
      return 'List' if $type ne $ltype;
    }
    return 'Point'  if $ltype eq 'Number';
    return 'Matrix' if $ltype =~ m/Point|Matrix/;
    return 'List';
  }
  return 'Formula'  if Value::isFormula($value);
  return 'Infinity' if Value::classMatch($value,'Infinity');
  return 'Number'   if Value::isReal($value);
  return 'value'    if Value::isValue($value);
  return 'unknown'  if ref($value);
  return 'String'   if defined($strings->{$value});
  return 'Number'   if Value::isNumber($value);
  return 'String'   if $value eq '' && $equation->{context}{flags}{allowEmptyStrings};
  return 'unknown';
}

#
#  Get a string describing a value's type,
#    and convert the value to a Value object (if needed)
#
sub getValueType {
  my $equation = shift; my $value = shift;
  return $value->getValueType($equation,@_) if Value->subclassed($value,"getValueType");
  my $type = Value::getType($equation,$value);
  if ($type eq 'String') {$type = $Value::Type{string}}
  elsif ($type eq 'Number') {$type = $Value::Type{number}}
  elsif ($type eq 'Infinity') {$type = $Value::Type{infinity}}
  elsif ($type eq 'value' || $type eq 'Formula') {$type = $value->typeRef}
  elsif ($type eq 'unknown') {
    $equation->Error(["Can't convert %s to a constant",Value::showClass($value)]);
  } else {
    $type = $equation->{context}->Package($type);
    $value = $type->new($equation->{context},@{$value});
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
      push(@f,$formula->Item("Value")->new($formula,$x));
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
  my $context = $self->context;
  my $list = $context->lists->get($self->class);
  my $open = $list->{'open'};
  my $close = $list->{'close'};
  my $paren = $open; $paren = 'list' if $self->classMatch('List');
  my $formula = $self->Package("Formula")->blank($context);
  my @coords = Value::toFormula($formula,@{$values});
  $formula->{tree} = $formula->Item("List")->new($formula,[@coords],0,
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
  my $context = (Value::isContext($_[0]) ? shift : $self->context);
  bless {$self->hash, data => [@_], context => $context}, $class;
}

#
#  Easy method for setting parameters of an object
#  (returns a copy with the new values set, but the copy
#  is not a deep copy.)
#
sub with {
  my $self = shift;
  bless {%{$self},@_}, ref($self);
}

#
#  Return a copy with the specified fields removed
#
sub without {
  my $self = shift;
  $self = bless {%{$self}}, ref($self);
  foreach my $id (@_) {delete $self->{$id} if defined $self->{$id}}
  return $self;
}

######################################################################

#
#  Return the hash data as an array of key=>value pairs
#
sub hash {
  my $self = shift;
  return %$self if isHash($self);
  return ();
}

#
#  Copy attributes that are not already in the current object
#  from the given objects.  (Used by binary operators to make sure
#  the result inherits the values from the two terms.)
#
sub inherit {
  my $self = shift;
  my %copy = (map {%$_} @_,$self);  # copy values from given objects
  foreach my $id ($self->noinherit) {delete $copy{$id}}
  $self = bless {%copy}, ref($self);
  return $self;
}

#
#  The list of fields NOT to inherit.
#  Use the default list plus any specified explicitly in the object itself.
#  Subclasses can override and return additional fields, if necessary.
#
sub noinherit {
  my $self = shift;
  ("correct_ans","original_formula","equation",@{$self->{noinherit}||[]});
}

######################################################################

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
  interval => Value::Type('Interval',2),
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
  my $self = shift;
  return $self->class(@_) if Value->subclassed($self,"class");
  my $class = ref($self) || $self; $class =~ s/.*:://;
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
    return if Value::isNumber($M);
    $i = shift @indices; $i = $i->value if Value::isValue($i);
    Value::Error("Can't extract element number '%s' (index must be an integer)",$i)
      unless $i =~ m/^-?\d+$/;
    return if $i == 0; $i-- if $i > 0;
    $M = $M->data->[$i];
  }
  return $M;
}

######################################################################

use overload
       '+'   => '_add',
       '-'   => '_sub',
       '*'   => '_mult',
       '/'   => '_div',
       '**'  => '_power',
       '.'   => '_dot',
       'x'   => '_cross',
       '%'   => '_modulo',
       '<=>' => '_compare',
       'cmp' => '_compare_string',
       '~'   => '_twiddle',
       'neg' => '_neg',
       'abs' => '_abs',
       'sqrt'=> '_sqrt',
       'exp' => '_exp',
       'log' => '_log',
       'sin' => '_sin',
       'cos' => '_cos',
     'atan2' => '_atan2',
  'nomethod' => 'nomethod',
        '""' => 'stringify';

#
#  Promote an operand to the same precedence as the current object
#
sub promotePrecedence {
  my $self = shift; my $other = shift; my $context = $self->context;
  return 0 unless Value::isValue($other);
  my $sprec = $self->precedence; my $oprec = $other->precedence;
  return (defined($sprec) && defined($oprec) && $sprec < $oprec);
}

sub precedence {my $self = shift; return $self->context->{precedence}{$self->class}}

sub promote {
  my $self = shift; my $class = ref($self) || $self;
  my $context = (Value::isContext($_[0]) ? shift : $self->context);
  my $x = (scalar(@_) ? shift : $self);
  return $x->inContext($context) if ref($x) eq $class && scalar(@_) == 0;
  return $self->new($context,$x,@_);
}

#
#  Return the operators in the correct order
#
sub checkOpOrder {
  my ($l,$r,$flag) = @_;
  if ($flag) {return ($l,$r,$l,$r)} else {return ($l,$l,$r,$r)}
}

#
#  Return the operators in the correct order, and promote the
#  other value, if needed.
#
sub checkOpOrderWithPromote {
  my ($l,$r,$flag) = @_; $r = $l->promote($r);
  if ($flag) {return ($l,$r,$l,$r)} else {return ($l,$l,$r,$r)}
}

#
#  Handle a binary operator, promoting the object types
#  as needed, and then calling the main method
#
sub binOp {
  my ($l,$r,$flag,$call) = @_;
  if ($l->promotePrecedence($r)) {return $r->$call($l,!$flag)}
                            else {return $l->$call($r,$flag)}
}

#
#  stubs for binary operations (with promotion)
#
sub _add            {binOp(@_,'add')}
sub _sub            {binOp(@_,'sub')}
sub _mult           {binOp(@_,'mult')}
sub _div            {binOp(@_,'div')}
sub _power          {binOp(@_,'power')}
sub _cross          {binOp(@_,'cross')}
sub _modulo         {binOp(@_,'modulo')}

sub _compare        {transferTolerances(@_); binOp(@_,'compare')}
sub _compare_string {binOp(@_,'compare_string')}

sub _atan2          {binOp(@_,'atan2')}

sub _twiddle        {(shift)->twiddle}
sub _neg            {(shift)->neg}
sub _abs            {(shift)->abs}
sub _sqrt           {(shift)->sqrt}
sub _exp            {(shift)->exp}
sub _log            {(shift)->log}
sub _sin            {(shift)->sin}
sub _cos            {(shift)->cos}

#
#  Default stub to call when no function is defined for an operation
#
sub nomethod {
  my ($l,$r,$flag,$op) = @_;
  my $call = $l->context->{method}{$op};
  if (defined($call) && $l->promotePrecedence($r)) {return $r->$call($l,!$flag)}
  my $error = "Can't use '%s' with %s-valued operands";
  $error .= " (use '**' for exponentiation)" if $op eq '^';
  Value::Error($error,$op,$l->class);
}

sub nodef {
  my $self = shift; my $func = shift;
  Value::Error("Can't use '%s' with %s-valued operands",$func,$self->class);
}

#
#  Stubs for the sub-classes
#
sub add    {nomethod(@_,'+')}
sub sub    {nomethod(@_,'-')}
sub mult   {nomethod(@_,'*')}
sub div    {nomethod(@_,'/')}
sub power  {nomethod(@_,'**')}
sub cross  {nomethod(@_,'x')}
sub modulo {nomethod(@_,'%')}

sub twiddle {nodef(shift,"~")}
sub neg     {nodef(shift,"-")}
sub abs     {nodef(shift,"abs")}
sub sqrt    {nodef(shift,"sqrt")}
sub exp     {nodef(shift,"exp")}
sub log     {nodef(shift,"log")}
sub sin     {nodef(shift,"sin")}
sub cos     {nodef(shift,"cos")}

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
  if (Value->context->flag('StringifyAsTeX')) {$l = $l->TeX} else {$l = $l->pdot}
  return ($flag)? ($r.$l): ($l.$r);
}
#
#  Some classes override this
#
sub dot {
  my ($l,$r,$flag) = @_;
  my $tex = Value->context->flag('StringifyAsTeX');
  if ($tex) {$l = $l->TeX} else {$l = $l->pdot}
  if (Value::isBlessed($r)) {if ($tex) {$r = $r->TeX} else {$r = $r->pdot}}
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
  my ($l,$r) = Value::checkOpOrder(@_);
  return $l->value <=> $r->value;
}

#
#  Compare the values as strings
#
sub compare_string {
  my ($l,$r,$flag) = @_;
  $l = $l->string; $r = $r->string if Value::isValue($r);
  if ($flag) {my $tmp = $l; $l = $r; $r = $tmp}
  return $l cmp $r;
}

#
#  Copy flags from the parent object to its children (recursively).
#
sub transferFlags {
  my $self = shift;
  foreach my $flag (@_) {
    next unless defined $self->{$flag};
    foreach my $x (@{$self->{data}}) {
      if ($x->{$flag} ne $self->{$flag}) {
	$x->{$flag} = $self->{$flag};
	$x->transferFlags($flag);
      }
    }
  }
}

sub transferTolerances {
  my ($self,$other) = @_;
  $self->transferFlags("tolerance","tolType","zeroLevel","zeroLevelTol");
  $other->transferFlags("tolerance","tolType","zeroLevel","zeroLevelTol") if Value::isValue($other);
}

=head3 output methods for MathObjects

 #
 #  Generate the various output formats
 #  (can be replaced by sub-classes)
 #

=cut

=head4 stringify

	Usage:   TEXT($mathObj); or TEXT( $mathObj->stringify() ) ;

		Produces text string or TeX output depending on context
			Context()->texStrings;
			Context()->normalStrings;

		called automatically when object is called in a string context.

=cut

sub stringify {
  my $self = shift;
  return $self->TeX if Value->context->flag('StringifyAsTeX');
  return $self->string;
}

=head4 ->string

	Usage: $mathObj->string()

	---produce a string representation of the object
           (as opposed to stringify, which can produce TeX or string versions)

=cut

sub string {
  my $self = shift; my $equation = shift;
  my $def = ($equation->{context} || $self->context)->lists->get($self->class);
  return $self->value unless $def;
  my $open = shift; my $close = shift;
  $open  = $self->{open}  unless defined($open);
  $open  = $def->{open}   unless defined($open);
  $close = $self->{close} unless defined($close);
  $close = $def->{close}  unless defined($close);
  my @coords = ();
  foreach my $x (@{$self->data}) {
    if (Value::isValue($x)) {
      $x->{format} = $self->{format} if defined $self->{format};
      push(@coords,$x->string($equation));
    } else {
      push(@coords,$x);
    }
  }
  return $open.join($def->{separator},@coords).$close;
}

=head4 ->TeX

	Usage: $mathObj->TeX()

	---produce TeX prepresentation of the object

=cut

sub TeX {
  my $self = shift; my $equation = shift;
  my $context = $equation->{context} || $self->context;
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
    if (Value::isValue($x)) {
      $x->{format} = $self->{format} if defined $self->{format};
      push(@coords,$x->TeX($equation));
    } elsif (defined($str->{$x}) && $str->{$x}{TeX}) {push(@coords,$str->{$x}{TeX})}
    else {push(@coords,$x)}
  }
  return $open.join(',',@coords).$close;
}

#
#  For perl, call the appropriate constructor around the object's data
#
sub perl {
  my $self = shift; my $parens = shift; my $matrix = shift;
  my $mtype = $self->classMatch('Matrix'); $mtype = -1 if $mtype & !$matrix;
  my $perl; my @p = ();
  foreach my $x (@{$self->data}) {
    if (Value::isValue($x)) {push(@p,$x->perl(0,$mtype))} else {push(@p,$x)}
  }
  @p = ("'".$self->{open}."'",@p,"'".$self->{close}."'") if $self->classMatch('Interval');
  if ($matrix) {
    $perl = join(',',@p);
    $perl = '['.$perl.']' if $mtype > 0;
  } else {
    $perl = ref($self).'->new('.join(',',@p).')';
    $perl = "($perl)->with(open=>'$self->{open}',close=>'$self->{close}')"
      if $self->classMatch('List') && $self->{open}.$self->{close} ne '()';
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


=head3 Error

	Usage: Value->Error("We're sorry...");
           or  $mathObject->Error("We're still sorry...");

 #
 #  Report an error and die.  This can be used within custom answer checkers
 #  to report errors during the check, or when sub-classing a MathObject to
 #  report error conditions.
 #

=cut

sub Error {
  my $self = (UNIVERSAL::can($_[0],"getFlag") ? shift : "Value");
  my $message = shift; my $context = $self->context;
  $message = [$message,@_] if scalar(@_) > 0;
  $context->setError($message,'');
  $message = $context->{error}{message};
  die $message . traceback() if $self->getFlag('showTraceback');
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

END {
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
}

###########################################################################

our $installed = 1;

###########################################################################

1;
