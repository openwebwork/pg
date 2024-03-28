## contextBoolean.pl

sub _contextBoolean_init { context::Boolean::Init() }

package context::Boolean;

sub Init {
	my $context = $main::context{Boolean} = Parser::Context->getCopy('Numeric');
	$context->{name} = 'Boolean';

	$context->{parser}{Number}      = 'context::Boolean::Number';
	$context->{parser}{Formula}     = 'context::Boolean::Formula';
	$context->{value}{Formula}      = 'context::Boolean::Formula';
	$context->{value}{Boolean}      = 'context::Boolean::Boolean';
	$context->{value}{Real}         = 'context::Boolean::Boolean';
	$context->{precedence}{Boolean} = $context->{precedence}{Real};

	## Disable unnecessary context stuff
	$context->functions->disable('All');
	$context->strings->clear();
	$context->lists->clear();

	## Define our logic operators
	#   (for now...)
	#   all binary operators have the same precedence and process left-to-right
	#   any parens to the right must be preserved with consecutive binary ops
	$context->operators->are(
		'or' => {
			class         => 'context::Boolean::BOP::or',
			precedence    => 3,
			associativity => 'left',
			type          => 'bin',
			rightparens   => 'same',
			string        => ' or ',
			TeX           => '\vee ',
			perl          => '||',
			alternatives  => ["\x{2228}"],
		},
		'and' => {
			class         => 'context::Boolean::BOP::and',
			precedence    => 3,
			associativity => 'left',
			type          => 'bin',
			rightparens   => 'same',
			string        => ' and ',
			TeX           => '\wedge ',
			perl          => '&&',
			alternatives  => ["\x{2227}"],
		},
		'xor' => {
			class         => 'context::Boolean::BOP::xor',
			precedence    => 3,
			associativity => 'left',
			type          => 'bin',
			rightparens   => 'same',
			string        => ' xor ',
			perl          => '!=',
			TeX           => '\oplus ',
			alternatives  => [ "\x{22BB}", "\x{2295}" ],
		},
		'not' => {
			class         => 'context::Boolean::UOP::not',
			precedence    => 3,
			associativity => 'left',
			type          => 'unary',
			string        => 'not ',
			TeX           => '\mathord{\sim}',
			perl          => '!',
			alternatives  => ["\x{00AC}"],
		},
		' ' => {
			class         => 3,
			precedence    => 1,
			associativity => 'left',
			type          => 'bin',
			string        => 'and',
			hidden        => 1
		},
		'*'   => { alias => 'and' },
		'/\\' => { alias => 'and' },
		'+'   => { alias => 'or' },
		'\\/' => { alias => 'or' },
		'-'   => { alias => 'not' },
		'!'   => { alias => 'not' },
		'~'   => { alias => 'not', alternatives => ["\x{223C}"] },
		'><'  => { alias => 'xor' },
	);

	## redefine, but disable some usual context tokens for 'clearer' error messages
	$context->operators->redefine([ ',', 'fn' ], from => 'Numeric');
	$context->lists->redefine('List', from => 'Numeric');
	$context->operators->redefine([ '/', '^', '**' ], from => 'Numeric');
	$context->operators->undefine('/', '^', '**');
	delete $context->operators->get('/')->{space};

	## Set default variables 'p' and 'q'
	$Parser::Context::Variables::type{Boolean} = $Parser::Context::Variables::type{Real};
	$context->variables->are(
		p => 'Boolean',
		q => 'Boolean',
	);

	## Set up new reduction rules:
	$context->reductions->set('x||1' => 1, 'x||0' => 1, 'x&&1' => 1, 'x&&0' => 1, '!!x' => 1);

	## Define constants for 'True' and 'False'
	$context->constants->{namePattern} = qr/(?:\w|[\x{22A4}\x{22A5}])+/;
	$context->constants->are(
		T => {
			value        => context::Boolean::Boolean->new($context, 1),
			string       => 'T',
			TeX          => '\top',
			perl         => 'context::Boolean->T',
			isConstant   => 1,
			alternatives => ["\x{22A4}"]
		},
		F => {
			value        => context::Boolean::Boolean->new($context, 0),
			string       => 'F',
			TeX          => '\bot',
			perl         => 'context::Boolean->F',
			isConstant   => 1,
			alternatives => ["\x{22A5}"]
		},
		'True'  => { alias => 'T' },
		'False' => { alias => 'F' },
	);

	## add our methods to this context
	bless $context, 'context::Boolean::Context';

	## allow authors to create Boolean values
	main::PG_restricted_eval('sub Boolean { Value->Package("Boolean()")->new(@_) }');
}

## top-level access to context-specific T and T
sub T {
	my $context = main::Context();
	Value::Error("Context must be a Boolean context") unless $context->can('T');
	return $context->T;
}

sub F {
	my $context = main::Context();
	Value::Error("Context must be a Boolean context") unless $context->can('F');
	return $context->F;
}

## Subclass the Parser::Context to override copy() and add T and F functions
package context::Boolean::Context;
our @ISA = ('Parser::Context');

sub copy {
	my $self = shift->SUPER::copy(@_);
	## update the T and F constants to refer to this context
	$self->constants->set(
		T => { value => context::Boolean::Boolean->new($self, 1) },
		F => { value => context::Boolean::Boolean->new($self, 0) }
	);
	return $self;
}

## Access to the constant T and F values
sub F { shift->constants->get('F')->{value} }
sub T { shift->constants->get('T')->{value} }

## Easy setting of precedence to different types
sub setPrecedence {
	my ($self, $order) = @_;
	if ($order eq 'equal') {
		$self->operators->set(
			or  => { precedence => 3 },
			xor => { precedence => 3 },
			and => { precedence => 3 },
			not => { precedence => 3 },
		);
	} elsif ($order eq 'oxan') {
		$self->operators->set(
			or  => { precedence => 1 },
			xor => { precedence => 2 },
			and => { precedence => 3 },
			not => { precedence => 6 },
		);
	} else {
		Value::Error("Unknown precedence class '%s'", $order);
	}
}

## Subclass Parser::Number to return the constant T or F
package context::Boolean::Number;
our @ISA = ('Parser::Number');

sub eval {
	my $self = shift;
	return $self->context->constants->get(('F', 'T')[ $self->{value} ])->{value};
}

sub perl {
	my $self = shift;
	return $self->context->constants->get(('F', 'T')[ $self->{value} ])->{perl};
}

## Subclass Value::Formula for boolean formulas
package context::Boolean::Formula;
our @ISA = ('Value::Formula');

## use every combination of T/F across all variables
sub createRandomPoints {
	my $self      = shift;
	my $context   = $self->{context};
	my @variables = $context->variables->names;
	my @points;
	my @values;

	my $T = $context->T;
	my $F = $context->F;

	my $f = $self->{f};
	$f = $self->{f} = $self->perlFunction(undef, \@variables) unless $f;

	foreach my $combination (0 .. 2**@variables - 1) {
		my @point = map { $combination & 2**$_ ? $T : $F } (0 .. $#variables);
		my $value = &$f(@point);
		push @points, \@point;
		push @values, $value;
	}

	$self->{test_points} = \@points;
	$self->{test_values} = \@values;
	return \@points;
}

package context::Boolean::BOP;
our @ISA = qw(Parser::BOP);

sub _check {
	my $self = shift;
	return if $self->checkNumbers;
	$self->Error("Operands of '%s' must be 'Boolean'", $self->{bop});
}

sub perl {
	my $self   = shift;
	my $l      = $self->{lop};
	my $r      = $self->{rop};
	my $bop    = $self->{def}{perl} || $self->{def}{string};
	my $lPerl  = $self->{lop}->perl(1) . '->value';
	my $rPerl  = $self->{rop}->perl(2) . '->value';
	my $result = "$lPerl $bop $rPerl";
	return "($result ? context::Boolean->T : context::Boolean->F)";
}

package context::Boolean::BOP::or;
our @ISA = qw(context::Boolean::BOP);

sub _eval {
	my ($self, $l, $r) = @_;
	return ($l->value || $r->value ? $self->context->T : $self->context->F);
}

sub _reduce {
	my $self   = shift;
	my $reduce = $self->context->{reduction};
	my $l      = $self->{lop};
	my $r      = $self->{rop};

	return $self unless ($l->{isConstant} || $r->{isConstant});

	if ($l->{isConstant}) {
		return $l->eval->value ? ($reduce->{'x||1'} ? $l : $self) : ($reduce->{'x||0'} ? $r : $self);
	} else {
		return $r->eval->value ? ($reduce->{'x||1'} ? $r : $self) : ($reduce->{'x||0'} ? $l : $self);
	}
}

package context::Boolean::BOP::and;
our @ISA = qw(context::Boolean::BOP);

sub _eval {
	my ($self, $l, $r) = @_;
	return ($l->value && $r->value ? $self->context->T : $self->context->F);
}

sub _reduce {
	my $self   = shift;
	my $reduce = $self->context->{reduction};
	my $l      = $self->{lop};
	my $r      = $self->{rop};

	return $self unless ($l->{isConstant} || $r->{isConstant});

	if ($l->{isConstant}) {
		return $l->eval->value ? ($reduce->{'x&&1'} ? $r : $self) : ($reduce->{'x&&0'} ? $l : $self);
	} else {
		return $r->eval->value ? ($reduce->{'x&&1'} ? $l : $self) : ($reduce->{'x&&0'} ? $r : $self);
	}
}

package context::Boolean::BOP::xor;
our @ISA = qw(context::Boolean::BOP);

sub _eval {
	my ($self, $l, $r) = @_;
	return ($l->value != $r->value ? $self->context->T : $self->context->F);
}

package context::Boolean::UOP::not;
our @ISA = qw(Parser::UOP);

sub _check {
	my $self = shift;
	return if $self->checkNumber;
	$self->Error("Operands of '%s' must be 'Boolean'", $self->{uop});
}

sub _reduce {
	my $self   = shift;
	my $reduce = $self->context->{reduction};
	my $op     = $self->{op};

	if ($op->isNeg && $reduce->{'!!x'}) {
		delete $op->{op}{noParens};
		return $op->{op};
	}

	if ($op->{isConstant} && $context->flag('reduceConstants')) {
		return $self->Item('Value')->new($self->{equation}, [ 1 - $op->value ]);
	}
	return $self;
}

sub isNeg {1}

sub _eval {
	my ($self, $op) = @_;
	return (!($op->value) ? $self->context->T : $self->context->F);
}

sub perl {
	my $self   = shift;
	my $op     = $self->{def}{perl} || $self->{def}{string};
	my $perl   = $self->{op}->perl(1) . '->value';
	my $result = "$op $perl";
	return "($result ? context::Boolean->T : context::Boolean->F)";
}

package context::Boolean::Boolean;
our @ISA = qw(Value::Real);

sub new {
	my $self  = shift;
	my $value = $self->SUPER::new(@_);
	$value->checkBoolean unless $value->classMatch("Formula");
	return $value;
}

sub make {
	my $self   = shift;
	my $result = $self->SUPER::make(@_);
	$result->checkBoolean unless $result->classMatch("Formula");
	return $result;
}

sub checkBoolean {
	my $self = shift;
	$self->Error("Numeric values can only be 1 or 0 in this context")
		unless ($self->value == 1 || $self->value == 0);
}

sub compare {
	my ($self, $l, $r) = Value::checkOpOrderWithPromote(@_);
	return $l->value <=> $r->value;
}

## use the context settings
sub string {
	my $self  = shift;
	my $const = $self->context->constants;
	my $T     = $const->get('T')->{string} || 'T';
	my $F     = $const->get('F')->{string} || 'F';
	return ($F, $T)[ $self->value ];
}

## use the context settings
sub TeX {
	my $self  = shift;
	my $const = $self->context->constants;
	my $T     = $const->get('T')->{TeX} || '\top';
	my $F     = $const->get('F')->{TeX} || '\bot';
	return ($F, $T)[ $self->value ];
}

sub perl {
	my $self = shift;
	return $self->value ? 'context::Boolean->T' : 'context::Boolean->F';
}

sub cmp_defaults { shift->SUPER::cmp_defaults(@_) }

1;
