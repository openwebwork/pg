package Value;
my $pkg = 'Value';
use vars qw($context $defaultContext %Type);
use strict;

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
	of some type.

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
#  Copy a context and its data
#
sub copy {
  my $self = shift;
  my $copy = {%{$self}}; $copy->{data} = [@{$self->{data}}];
  foreach my $x (@{$copy->{data}}) {$x = $x->copy if Value::isValue($x)}
  return bless $copy, ref($self);
}

=head3 getFlag

#
#  Get the value of a flag from the object itself,
#  or from the context, or from the default context
#  or from the given default, whichever is found first.
#

	Usage:   $mathObj->getFlag("showTypeWarnings");
	         $mathObj->getFlag("showTypeWarnings",1); # default is second parameter

=cut

sub getFlag {
  my $self = shift; my $name = shift;
  return $self->{$name} if ref($self) && ref($self) ne 'ARRAY' && defined($self->{$name});
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
  if (ref($self) && ref($self) ne 'ARRAY') {
    if ($context && $self->{context} != $context) {
      $self->{context} = $context;
      if (defined $self->{data}) {
        foreach my $x (@{$self->{data}}) {$x->context($context) if ref($x)}
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
#  Check if the object class matches one of a list of classes
#
sub classMatch {
  my $self = shift; my $class = class($self);
  my $ref = ref($self); my $isHash = ($ref && $ref ne 'ARRAY' && $ref ne 'CODE');
  my $context = ($isHash ? $self->{context} : Value->context);
  foreach my $name (@_) {
    return 1 if $class eq $name || $ref eq $context->Package($name,0) ||
                $ref eq "Value::$name" || ($isHash && $self->{"is".$name});
  }
  return 0;
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
sub isValue {
  my $v = shift;
  return (ref($v) || $v) =~ m/^Value::/ ||
         (ref($v) && ref($v) ne 'ARRAY' && ref($v) ne 'CODE' && $v->{isValue});
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
  return $self->length == 2 && $self->typeRef->{entryType}{name} eq 'Number' &&
    $self->{open} =~ m/^[\(\[]$/ && $self->{close} =~ m/^[\)\]]$/;
}

######################################################################

#
#  Value->Package(name[,noerror]])
#
#  Returns the package name for the specificied Value object class
#  (as specified by the context's {value} hash, or "Value::name").
#
sub Package {(shift)->context->Package(@_)}

=head3 makeValue

	Usage:  Value::makeValue(45);

	Will create a Real mathObject.
 #
 #  Convert non-Value objects to Values, if possible
 #

=cut

sub makeValue {
  my $x = shift;
  my %params = (showError => 0, makeFormula => 1, context => Value->context, @_);
  my $context = $params{context};
  return $x if ref($x) && ref($x) ne 'ARRAY';
  return $context->Package("Real")->make($context,$x) if matchNumber($x);
  if (matchInfinite($x)) {
    my $I = $context->Package("Infinity")->new($context);
    $I = $I->neg if $x =~ m/^$context->{pattern}{-infinity}$/;
    return $I;
  }
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
  my $class = class($value);
  return showType($value) if Value::classMatch($value,'List');
  $class .= ' Number' if Value::classMatch($value,'Real','Complex');
  $class .= ' of Intervals' if Value::classMatch($value,'Union');
  $class = 'Word' if Value::classMatch($value,'String');
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
        $type = $x->type if $x->classMatch('Formula');
        $type = 'Number' if $x->classMatch('Complex') || $type eq 'Complex';
      }
      $ltype = $type if $ltype eq '';
      return 'List' if $type ne $ltype;
    }
    return 'Point' if $ltype eq 'Number';
    return 'Matrix' if $ltype =~ m/Point|Matrix/;
    return 'List';
  }
  elsif (Value::isFormula($value)) {return 'Formula'}
  elsif (Value::classMatch($value,'Infinity')) {return 'Infinity'}
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
  bless {data => [@_], context => $context}, $class;
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
  my $sprec = $context->{precedence}{class($self)};
  my $oprec = $context->{precedence}{class($other)};
  return (defined($sprec) && defined($oprec) && $sprec < $oprec);
}

sub promote {
  my $self = shift;
  return $_[0] if scalar(@_) == 1 && ref($_[1]) eq ref($self);
  return $self->new(@_);
}

#
#  Return the operators in the correct order
#
sub checkOpOrder {
  my ($l,$r,$flag) = @_;
  if ($flag) {return ($l,$r,$l)} else {return ($l,$l,$r)}
}

#
#  Return the operators in the correct order, and promote the
#  other value, if needed.
#
sub checkOpOrderWithPromote {
  my ($l,$r,$flag) = @_; $r = $l->promote($r);
  if ($flag) {return ($l,$r,$l)} else {return ($l,$l,$r)}
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

sub _compare        {binOp(@_,'compare')}
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
  my ($l,$r) = Value::checkOpOrder(@_);
  return $l->value <=> $r->value;
}

#
#  Compare the values as strings
#
sub compare_string {
  my ($l,$r,$flag) = @_;
  $l = $l->stringify; $r = $r->stringify if Value::isValue($r);
  if ($flag) {my $tmp = $l; $l = $r; $r = $tmp}
  return $l cmp $r;
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
  return $self->TeX() if Value->context->flag('StringifyAsTeX');
  my $def = $self->context->lists->get($self->class);
  return $self->string unless $def;
  my $open = $self->{open};   $open  = $def->{open}  unless defined($open);
  my $close = $self->{close}; $close = $def->{close} unless defined($close);
  $open.join($def->{separator},@{$self->data}).$close;
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
    if (Value::isValue($x))
      {push(@coords,$x->string($equation))} else {push(@coords,$x)}
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

	Usage: $mathObj->Error("We're sorry...");

 #
 #  Report an error
 #

=cut

sub Error {
  my $message = shift; my $context = Value->context;
  $message = [$message,@_] if scalar(@_) > 0;
  $context->setError($message,'');
  $message = $context->{error}{message};
  die $message . traceback() if $context->flags('showTraceback');
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
