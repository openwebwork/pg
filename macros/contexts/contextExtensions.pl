
=head1 NAME

contextExtensoins.pl - Implements a framework for creating contexts that
                       extend other contexts.

=head1 DESCRIPTION

MathObject contexts specify their features by creating objects that
implement the needed functionality, and assigning those object classes
to the various operators, functions, etc. that are part of the
context.  For example, addition in the C<Numeric> context is attached
to the C<+> sign by setting its C<class> property to
C<Parser::BOP::add> in the context's C<operators> list.

To change the action of C<+> (for example, to allow it to work with a
new type of object that you are defining), you would change the
C<class> property to point to a new class (usually a subclass of
C<Parser::BOP::add>) that implements the new functionality needed for
the new category of object.  So if you are defining a new object to
handle quaternions, then you might use something like

    $context->operators->set( '+' => 'context::Quaternions::BOP::add' );

to direct the C<+> to use your new C<context::Quaternions::BOP::add>
object instead of the usual one.  (Of course, there is much more than
needs to be done as well, but this illustrates how such changes are
made.)

When you change the class associated with an operator or some other
Context feature, the previous class is replaced by the new class, and
that means you have to either maintain the old functionality by using
a subclass of the original class, or by re-implementing it in your new
class.  This usually means you need to know the original class when
you define your new objects, and that makes your new context dependent
on a specific original context.  If you want to be able to add your
new MathObject to an arbitrary context, that was not generally easy to
do.

The purpose of this file is to make it possible to overcome these
difficulties, and make it easier to extend a context by adding new
functionality without losing its old features, and without having to
know which context you are extending.  For example, the Fraction
object can be added to an existing context this way, as can the
handling of units.

=cut

sub _contextExtensions_init { }

#################################################################################################
#################################################################################################

#
#  This package provides create() and extend() functions that can be
#  used to get a copy of an existing context and extend it by
#  overridding the existing classes with your own, while maintining
#  information about those original classes so that you can fall back
#  on them for any sitautions that don't involve your new
#  functionality.  These functions are designed so that multiple
#  extensions can be added without interfering with one another.
#
package context::Extensions;

#
#  ID to use for contexts that need a dynamic extension
#
my $id = 0;

#
#  Copy the given context (given by name or as a Context object)
#  and name the new one.  For example,
#
#    $context = context::Extensions::create("Quaternions", "Complex");
#
#  would create a context named "Quaternions-Complex" as a copy of the
#  Complex context.  The implementation for classes added to this
#  context should be in the context::Quaternions namespace.
#
sub create {
	my ($new, $from) = @_;
	my $name    = "$new-$from";
	my $context = Value::isContext($from) ? $from->copy : Parser::Context->getCopy($from);
	$context->{baseName}  = $new;
	$context->{name}      = $name;
	$main::context{$name} = $context;
	return $context;
}

#
#  Extend a given Context object to include new features by specifying
#  classes to use for operators, functions, value object, and parser
#  objects, while retaining the old classes for fallback use.
#
#  The changes are specified in the options following the Context, and these
#  can include:
#
#    opClasses => { op => 'class', ... }
#
#      specifies the operators to override, and the class suffix to
#      use for their implementations.  For example, using
#
#         opClasses => { '+' => 'BOP::add' }
#
#      would attach the class context::Quaternions::BOP::add to the
#      plus sign in our Qaternion setting.  If the space operator (' ')
#      in your list, and if the original context has it point to an
#      operator that is NOT in your list, then that references operator
#      is redirected automatically to 'BOP::Space' in your base context
#      package.  In our case, we would want to include a definition for
#      context::Quaternions::BOP::Space in order to cover that possibility.
#
#    ops => { op => {def}, ... }
#
#      specifies new operators to add to the context (where "def" is
#      an operator definition like those for any context).
#
#    functions => 'class1|class2|...'
#
#      specifies the function categories that you are overriding (e.g.,
#
#         functions => 'numeric|trig|hyperbolic'
#
#      would override the functions that have classes that end in
#      ::Functions:numeric, ::Function::trig, or ::Function::hyperbolic
#      and direct them to your own versions of these.  In our quaternion
#      setting that would be to context::Quaternions::Function::numeric
#      for the first of these, and similarly for the others.
#
#    value => ['Class1', 'Class2', ...]
#
#      specifies the Value object classes to override.  For instance,
#
#         value => ['Real', 'Formula']
#
#      would set $context->{value}{Real} and $context->{value}{Formula}
#      to point to your own versions of these (e.g., in our example,
#      these would be context::Quaternions::Value::Real and
#      context::Quaternions::Value::Formula.  Note that if you list
#      the parenthesized version (used by the coreesponding constructor
#      functions), then the parentheses are replaced by "_Parens" in the
#      class name.  For example,
#
#         value => ['Real()']
#
#      would set
#
#         $context->{value}{Real()} = 'context::Quaternions::Value::Real_Parens';
#
#    parser => ['Class1', 'Class2', ... ]
#
#      specifies the Parser classes to override.  This works similarly
#      to the "value" option above, so that
#
#         parser => ['Number']
#
#      would set $context->{parser}{Number} to your version of this class,
#      which would be context::Quaternions::Parser::Number in our example.
#
#    flags => { flag => value, ...}
#
#      specifies the new flags to add to the context (or existing ones to
#      override.
#
#    reductions => { name => 1 or 0, ... }
#
#      specifies new reduction rules to add to the context, and
#      whether they are in effect by default (1) or not (0).  Of
#      course, you need to implement these reduction rules in your
#      Parser objects.
#
#    context => "Context"
#
#      specifies that your context is a subclass of Parser::Context
#      that adds methods to the context.  If specified, the modified
#      context will be blessed using this value as the suffix for the
#      context's class.  In our quaternion example, the value "Context"
#      would mean the resulting modified context would be blessed
#      as context::Quaternions::Context.
#
#  The extend() function returns the modified context.
#
#  The various operators, functions, and value and Parser objects that
#  you define should use the context::Extensions::Super package below
#  in order to access the original classes for those objects.  Idealy,
#  your new objects will mutate (i.e., re-bless) themselves to their
#  original classes if they don't involve your new MathObjects.
#
#  For example, the new context::Quaternions::BOP::add class should
#  have the context::Extensions::Super object as one of its
#  superclasses, and then its _check() method could check if either
#  operand is a quaternion, and if not, it can call
#  $self->mutate->_check to turn itself into the original object's
#  class and perform its _check() actions.  That way, the new BOP::add
#  class only needs to worry about implementing the situation for
#  quaternions, and lets the original class deal with everything else.
#
sub extend {
	my ($context, %options) = @_;

	#
	#  The main context package
	#
	my $class = "context::$context->{baseName}";

	#
	#  Extension data are stored in a context property
	#
	$context->{$class} = {};
	push(@{ $context->{data}{values} }, $class);
	my $data = $context->{$class};

	#
	#  Replace existing classes, but save the originals in the
	#  class data for the context
	#
	my $operators = $context->operators;
	my $opClass   = $options{opClasses} || {};
	for my $op (keys %$opClass) {
		my $def = makeOpSubclass($context, $data, $operators, $op, $opClass->{$op});
		makeOpSubclass($context, $data, $operators, $def->{string}, 'BOP::Space', 1)
			if $op eq ' ' && !$opClass->{ $def->{string} };
	}
	#
	#  Make any new operators that are needed
	#
	$operators->set(%{ $options{ops} }) if $options{ops};

	#
	#  We tie into the existing function definitions in order to handle
	#  arguments for this extension, but inherit the rest from the
	#  original function classes.
	#
	if ($options{functions}) {
		my $functions = $context->functions;
		my $pattern   = qr/::Function::(?:$options{functions})$/;
		for my $fn ($functions->names) {
			my $def = $functions->get($fn);
			if ($def->{class} && $def->{class} =~ $pattern) {
				$data->{ substr($&, 2) } = $def->{class};
				$functions->set($fn => { class => "$class$&" });
			}
		}
	}

	#
	#  Replace any Parser/Value classes that are needed, saving the
	#  originals in the class data for the context
	#
	makeSubclass($context, $data, "Value",  $_) for (@{ $options{value}  || [] });
	makeSubclass($context, $data, "Parser", $_) for (@{ $options{parser} || [] });

	#
	#  Add any new flags requested
	#
	$context->flags->set(%{ $options{flags} }) if $options{flags};

	#
	#  Add any new reduction options
	#
	$context->reduction->set(%{ $options{reductions} }) if $options{reductions};

	#
	#  If there is a special context class, use it
	#
	if ($options{context}) {
		if (ref($context) ne 'Parser::Context') {
			$id++;
			@{"${class}::${id}::$options{context}::ISA"} = ("${class}::$options{context}", ref($context));
			$class .= "::${id}";
		}
		bless $context, "${class}::$options{context}";
	}

	#
	#  Return the context
	#
	return $context;
}

#
#  Record original operator class and set the new one,
#  extending to a new class if needed.
#
sub makeOpSubclass {
	my ($context, $data, $operators, $op, $class, $extend) = @_;
	my $def = $operators->get($op);
	Value->Error("Context '%s' does not have a definition for '%s'", $from, $op) unless $def || $extend;
	$data->{$op} = $def->{class};
	$operators->set($op => { class => "context::$context->{baseName}::${class}" });
	return $def;
}

#
#  Record original class for a given Value or Parser class
#
sub makeSubclass {
	my ($context, $data, $Type, $Name) = @_;
	my $type = lc($Type);
	if ($Name =~ m/\(\)$/) {
		my $name = substr($Name, 0, -2);
		$data->{"${Type}::${name}_Parens"} = $context->{$type}{$Name} || $context->{$type}{$name} || "${Type}::${name}";
		$context->{$type}{$Name} = "context::$context->{baseName}::${Type}::${name}_Parens";
		return;
	}
	$data->{"${Type}::${Name}"} = $context->{$type}{$Name} || "${Type}::${Name}";
	$context->{$type}{$Name} = "context::$context->{baseName}::${Type}::${Name}";
	if ($Type eq 'Value' && $context->{$type}{"${Name}()"}) {
		$data->{"${Type}::${Name}_Parens"} = $context->{$type}{"${Name}()"};
		$context->{$type}{"${Name}()"} = "context::$context->{baseName}::${Type}::${Name}_Parens";
	}
}

#################################################################################################
#################################################################################################

#
#  A common class for getting the super-class of an extension class.
#
#  This class handles all the details of dealing with the original
#  object classes that you have overridden in the context.  You should
#  create a subclass of this class and define its extensionContext()
#  method to return your base context name, and then include that
#  subclass in your @ISA arrays for your new classes that override the
#  original context's classes.
#
#  For our quaternions example, you would use
#
#    package context::Quaternions::Super
#    our @ISA = ('context::Extensions::Super');
#
#    sub extensionContext { 'context::Quaternions' }
#
#  and then use 'context::Quaternsions::Super' in the @ISA of your new
#  classes for operators, functions, or Value or Parser objects.
#  E.g.,
#
#    package context::Quaternions::BOP::add;
#    our @ISA = ('context::Quaternions::Super', 'Parser::BOP');
#
#    sub _check {
#      my $self = shift;
#      return $self->mutate->_check
#        unless $self->{lop}->class eq 'Quaternion' || $self->{rop}->class eq 'Quaternion';
#      #  Do your checking for proper arguments to go along with a quaternion here
#    }
#
#    sub _eval {
#      #  Do what is needed to perform addition between quaternions or between
#      #  a quaternion or another legal value here.  You don't have to worry
#      #  about any other types here, as the mutate() call above will change
#      #  the class to the original class (and its _eval() method) if one
#      #  of the operands isn't a quaternion.
#    }
#
#  If you need to call a method from the original class, use
#
#    &{$self->super("method")}($self, args...);
#
#  where "method" is the name of the method to call, and "args" are any arguments
#  that you need to pass.  For example,
#
#    my $string = &{$self->super("string")}($self);
#
#  would get the string output from the original class.
#
#  If you are defining a new() or make() method (where the $self could be
#  the class name rather than a class instance), you will need to pass the
#  context to mutate(), super(), or superClass().  See the example for
#  new() below.
#
#  The superClass() method gets you the name of the original class, in
#  case you need to access any class variables from that.
#
package context::Extensions::Super;

#
#  Get a method from the original class from the extended context
#
sub super {
	my ($self, $method, $context) = @_;
	return $self->superClass($context)->can($method);
}

#
#  Get the super class name from the extension hash in the context
#
sub superClass {
	my $self  = shift;
	my $class = ref($self) || $self;
	my $name  = $self->extensionContext;
	my $data  = (shift || $self->context)->{$name};
	my $op    = $self->{bop} || $self->{uop};
	return $op ? $data->{$op} : $data->{ substr($class, length($name) + 2) };
}

#
#  Re-bless the current object to become the other object,
#  if there is one, or the object's super class if not.
#
sub mutate {
	my ($self, $context, $other) = @_;
	if ($other) {
		delete $self->{$_} for (keys %$self);
		$self->{$_} = $other->{$_} for (keys %$other);
		bless $self, ref($other);
	} elsif (ref($self) eq '') {
		$self = $self->superClass($context);
	} else {
		bless $self, $self->superClass($context);
	}
	return $self;
}

#
#  Use the super-class new() method
#
sub new {
	my $self    = shift;
	my $context = Value::isContext($_[0]) ? $_[0] : $self->context;
	return &{ $self->super("new", $context) }($self, @_);
}

#
#  Get the object's class from its class name
#
sub class {
	my $self  = shift;
	my @class = split(/::/, ref($self) || $self);
	my $name  = $class[-2];
	return $name eq 'Value' || $name eq 'Parser' ? $class[-1] : $name;
}

#
#  This method must be supplied by subclassing
#  context::Extensions::Super package and overriding this method with
#  one that returns the extension context's name.
#
sub extensionContext {
	die "The context must subclass context::Extensions::Super and supply an extensionContext() method";
}

#################################################################################################
#################################################################################################

#
#  A common class for handling the private extension data in an object's typeRef.
#
#  This allows you to add and retrieve custom data to and from an
#  object's type in such a way that it doesn't interfere with the
#  original object's type, or that of any other extensions.
#
#  A MathObject's typeRef property is a HASH that includes information
#  about the object's type, its length (for things like lists and
#  vectors), and entry types (again for objects like lists and
#  vectors).  We can add data to this hash to store additional
#  information that we need in order to be more granualr about the
#  type or class of a Parser object.
#
#  To use this, create a subclass of context::Extensions::Data that
#  has an extensionID() method that returns a name to use as the hash
#  key to store your custom data (the default is to use the base
#  context name).  Your subclass should also include your Super class
#  as a parent class.  For example:
#
#    package context::Quaternions::Data;
#    our @ISA = ('context::Quaternions::Super', 'context::Extensions:Data');
#
#    sub extensionID { 'quatData' }
#
#  Then use this new subclass in the @ISA list for any class that needs access
#  to your custom data.
#
#  The extensionData() method returns the complete hash of your custom
#  data, from which you can extract the value of the property you
#  need, or can set any properties that you want.  E.g.,
#
#    $self->extensionData->{class};
#
#  could be used to obtain the custom "class" property of your data.
#
#  The setExtensionType() method is used to set an object's
#  $self->{type} property (which holds the object's typeRef) to a
#  named type residing in your base context.  For example:
#
#    package context::Quaternions;
#    our $QUATERNION = Value::Type("Number, undef, undef, quatData => {class => "QUATERNION"});
#
#    package context::Quaternions::Super
#    our @ISA = ('context::Extensions::Super');
#    sub extensionContext { 'context::Quaternions' }
#
#    package context::Quaternions::Data;
#    our @ISA = ('context::Quaternions::Super', 'context::Extensions:Data');
#    sub extensionID { 'quatData' }
#
#    package context::Quaternions::BOP::add;
#    our @ISA = ('context::Quaternions::Data', 'Parser::BOP');
#
#    sub _check {
#      my $self = shift;
#      unless $self->{lop}->class eq 'Quaternion' || $self->{rop}->class eq 'Quaternion';
#      #  other typechecking here
#      $self->setExtensionType("QUATERNION");  # Use the type in the $QUATERNION variable above
#    }
#
#  Finally, the extensionDataMatch() method checks if the value of a
#  given property is one of a set of values.  For example, if you have
#  a property called "class", then
#
#    $self->extensionDataMatch($self->{lop}, "class", "QUATERNION", "COMPLEX");
#
#  would return 1 if the quatData->{class} was either "QUATERNION" or
#  "COMPLEX" in the $self->{lop}{type} hash, and 0 otherwise.
#
package context::Extensions::Data;

#
#  Get the object's extensionData
#
sub extensionData { (shift)->typeRef->{ $self->extensionID } }

#
#  Set the object's extensionData (and the rest of its type)
#
sub setExtensionType {
	my ($self, $type) = @_;
	$self->{type} = ${ $self->extensionContext . "::${type}" };
}

#
#  Check if an object's extension property matches one of the given values
#
sub extensionDataMatch {
	my ($self, $x, $prop, @values) = @_;
	my $value = $x->typeRef->{ $self->extensionID }{$prop};
	if (defined $value) {
		for my $test (@values) {
			return 1 if $test eq $value;
		}
	}
	return 0;
}

#
#  The extnsion context can subclass that is produce a better name
#
sub extensionID { (shift)->extensionContext }

#################################################################################################
#################################################################################################

1;
