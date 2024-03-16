## contextBoolean.pl

sub _contextBoolean_init { context::Boolean::Init() }

package context::Boolean;

sub Init {
	my $context = $main::context{Boolean} = Parser::Context->getCopy('Numeric');
	$context->{name} = 'Boolean';

	$context->{parser}{Formula}     = 'context::Boolean::Formula';
	$context->{value}{Formula}      = 'context::Boolean::Formula';
	$context->{value}{Boolean}      = 'context::Boolean::Boolean';
	$context->{value}{Real}         = 'context::Boolean::Boolean';
	$context->{precedence}{Boolean} = $context->{precedence}{Real};

	## Disable unnecessary context stuff
	$context->functions->disable('All');
	$context->strings->clear();
	$context->lists->clear();

	our $T = context::Boolean::Boolean->new(1);
	our $F = context::Boolean::Boolean->new(0);

	## Define constants for 'True' and 'False'
	$context->constants->are(
		'T'     => { value => 1,   TeX           => '\top ', caseSensitive => 0, },    #alternatives => ["\x{22A4}"] },
		'F'     => { value => 0,   TeX           => '\bot ', caseSensitive => 0, },    #alternatives => ["\x{22A5}"] },
		'True'  => { alias => 'T', caseSensitive => 0 },
		'False' => { alias => 'F', caseSensitive => 0 },
	);

	## Define our logic operators
	#   all binary operators have the same precedence and process left-to-right
	#   any parens to the right must be preserved with consecutive binary ops
	$context->operators->are(
		'or' => {
			class         => 'context::Boolean::BOP::or',
			precedence    => 1,
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
			precedence    => 1,
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
			precedence    => 1,
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
		' '  => { class => 1, string => 'and', hidden => 1 },
		'*'  => { alias => 'and' },
		'+'  => { alias => 'or' },
		'-'  => { alias => 'not' },
		'!'  => { alias => 'not' },
		'~'  => { alias => 'not', alternatives => ["\x{223C}"] },
		'><' => { alias => 'xor' },
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

	## allow authors to create Boolean values
	main::PG_restricted_eval('sub Boolean { Value->Package("Boolean()")->new(@_) }');

	## Set up new reduction rules:
	$context->reductions->set('x||1' => 1, 'x||0' => 1, 'x&&1' => 1, 'x&&0' => 1, '!!x' => 1);
}

## Subclass Value::Formula for boolean formulas
package context::Boolean::Formula;
our @ISA = ('Value::Formula');

## use every combination of T/F across all variables
sub createRandomPoints {
	my $self      = shift;
	my @variables = $self->{context}->variables->names;
	my @points;
	my @values;

	my $f = $self->{f};
	$f = $self->{f} = $self->perlFunction(undef, \@variables) unless $f;

	foreach my $combination (0 .. 2**@variables - 1) {
		# coordinates must be unblessed
		my @point = map { $combination & 2**$_ ? 1 : 0 } (0 .. $#variables);
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
	my $result = $self->SUPER::perl(@_);
	return "($result ? 1 : 0)";
}

package context::Boolean::BOP::or;
our @ISA = qw(context::Boolean::BOP);

sub _eval { ($_[1] || $_[2] ? 1 : 0) }

sub _reduce {
	my $self   = shift;
	my $reduce = $self->{equation}{context}{reduction};
	my $l      = $self->{lop};
	my $r      = $self->{rop};

	return $self unless ($l->{isConstant} || $r->{isConstant});

	if ($l->{isConstant}) {
		return $l->eval ? ($reduce->{'x||1'} ? $l : $self) : ($reduce->{'x||0'} ? $r : $self);
	} else {
		return $r->eval ? ($reduce->{'x||1'} ? $r : $self) : ($reduce->{'x||0'} ? $l : $self);
	}
}

package context::Boolean::BOP::and;
our @ISA = qw(context::Boolean::BOP);

sub _eval { ($_[1] && $_[2] ? 1 : 0) }

sub _reduce {
	my $self   = shift;
	my $reduce = $self->{equation}{context}{reduction};
	my $l      = $self->{lop};
	my $r      = $self->{rop};

	return $self unless ($l->{isConstant} || $r->{isConstant});

	if ($l->{isConstant}) {
		return $l->eval ? ($reduce->{'x&&1'} ? $r : $self) : ($reduce->{'x&&0'} ? $l : $self);
	} else {
		return $r->eval ? ($reduce->{'x&&1'} ? $l : $self) : ($reduce->{'x&&0'} ? $r : $self);
	}
}

package context::Boolean::BOP::xor;
our @ISA = qw(context::Boolean::BOP);

sub _eval { ($_[1] != $_[2] ? 1 : 0) }

package context::Boolean::UOP::not;
our @ISA = qw(Parser::UOP);

sub _check {
	my $self = shift;
	return if $self->checkNumber;
	$self->Error("Operands of '%s' must be 'Boolean'", $self->{uop});
}

sub _reduce {
	my $self   = shift;
	my $reduce = $self->{equation}{context}{reduction};
	my $op     = $self->{op};

	if ($op->isNeg && $reduce->{'!!x'}) {
		delete $op->{op}{noParens};
		return $op->{op};
	}
	return $self;
}

sub isNeg {
	my $self = shift;
	return ($self->class eq 'UOP' && $self->{uop} eq 'not');
}

sub _eval { (!($_[1]) ? 1 : 0) }

sub perl {
	my $self   = shift;
	my $result = $self->SUPER::perl(@_);
	return "($result ? 1 : 0)";
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

sub string {
	my $self = shift;
	return ('F', 'T')[ $self->value ];
}

sub TeX {
	my $self = shift;
	return ('\bot', '\top')[ $self->value ];
}

# why doesn't this class inherit cmp_defaults from Value::Real (in AnswerChecker.pm)?
sub cmp_defaults { shift->SUPER::cmp_defaults(@_) }

1;
