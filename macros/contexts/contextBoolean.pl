
=head1 NAME

contextBoolean.pl - Implements a MathObject class for Boolean expressions

=head1 DESCRIPTION

Load this file:

    loadMacros('contextBoolean.pl');

and then select the context:

    Context('Boolean');

=head2 CONSTANTS

This constant recognizes two constants by default, C<T> and C<F>. The following are all equivalent:

    $T = Compute('1');
    $T = Boolean('T');
    $T = Context()->T;
    $T = context::Boolean->T;

=head2 VARIABLES

By default, this context has two variables, C<p> and C<q>. More variables can be added through the usual
means of modifying context:

    Context->variables->add( r => 'Boolean' );

=head2 OPERATORS

Changing the LaTeX representations of the boolean operators is handled through the operators C<or>, C<and>,
C<xor>, and C<not>. Note the extra space following the LaTeX command.

    Context->operators->set( not => { TeX => '\neg ' } );


=head3 Aliases and Alternatives

Modifications to the operators should be applied to the string versions of each operator: 'or', 'xor', 'and',
and 'not'; rather than to any of the following aliases or alternatives.

=over

=item OR

The 'or' operator is indicated by C<or>, C<+>, C<\\/>, C<wedge>, or unicode C<x{2228}>.

=item AND

The 'and' operator is indicated by C<and>, C<*>, whitespace (as with implicit multiplication), C</\\>, C<vee>,
or unicode C<x{2227}>.

=item XOR

The 'xor' operator is indicated by C<xor>, C<\>\<>, C<oplus>, or unicodes C<x{22BB}>, C<x{2295}>.

=item NOT

The 'not' operator is indicated by C<not>, C<->, C<!>, C<~>, or unicodes C<x{00AC}>, C<x{223C}>.

A right-associative version of the 'not' operator is also available by using C<'> or C<`> following the expression
to be negated.

=back

=head2 OPERATOR PRECEDENCE

=over

=item S<C<< setPrecedence >>>

This context supports two paradigms for operation precedence: C<equal> (default) and C<oxan>.

The default setting, C<equal>, gives all boolean operations the same priority, meaning that parenthesis
are the only manner by which an expression will evaluate operations to the right before those to the left.

    $a = Compute("T or T and F"); # $a == F

The C<oxan> setting priortizes C<or> < C<xor> < C<and> < C<not>.

    Context()->setPrecedence('oxan');
    $b = Compute("T or T and F"); # $b == T

=back

=head2 REDUCTION

The context also handles C<reduceConstants> with the following reduction rules:

=over

=item C<'x||1'>

    $f = Formula('p or T')->reduce; # $f == T

=item C<'x||0'>

    $f = Formula('p or F')->reduce; # $f == Formula('p')

=item C<'x&&1'>

    $f = Formula('p and T')->reduce; # $f == Formula('p')

=item C<'x&&0'>

    $f = Formula('p and F')->reduce; # $f == F

=item C<'!!x'>

    $f = Formula('not not p')->reduce; # $f == Formula('p');

=back

=head2 COMPARISON

Boolean Formula objects are considered equal whenever the two expressions generate the same truth table.

    $f = Formula('not (p or q)');
    $g = Formula('(not p) and (not q)');
    # $f == $g is true

=cut

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

	# Disable unnecessary context stuff
	$context->functions->disable('All');
	$context->strings->clear();
	$context->lists->clear();

	# Define our logic operators
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
			#			alternatives  => ["\x{2228}"],
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
			#			alternatives  => ["\x{2227}"],
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
			#			alternatives  => [ "\x{22BB}", "\x{2295}" ],
		},
		'not' => {
			class         => 'context::Boolean::UOP::not',
			precedence    => 3,
			associativity => 'left',
			type          => 'unary',
			string        => 'not ',
			TeX           => '\mathord{\sim}',
			perl          => '!',
			#			alternatives  => ["\x{00AC}"],
		},
		'`' => {
			class         => 'context::Boolean::UOP::not',
			precedence    => 3,
			associativity => 'right',
			type          => 'unary',
			string        => '`',
			TeX           => '^\prime',
			perl          => '!',
		},
		' ' => {
			class         => 1,
			precedence    => 3,
			associativity => 'left',
			type          => 'bin',
			string        => 'and',
			hidden        => 1
		},
		'*'     => { alias => 'and' },
		'/\\'   => { alias => 'and' },
		'wedge' => { alias => 'and', alternatives => ["\x{2227}"] },
		'+'     => { alias => 'or' },
		'\\/'   => { alias => 'or' },
		'vee'   => { alias => 'or',  alternatives => ["\x{2228}"] },
		'-'     => { alias => 'not', alternatives => ["\x{00AC}"] },
		'!'     => { alias => 'not' },
		'~'     => { alias => 'not', alternatives => ["\x{223C}"] },
		'\''    => { alias => '`' },
		'><'    => { alias => 'xor' },
		'oplus' => { alias => 'xor', alternatives => [ "\x{22BB}", "\x{2295}" ] },
	);

	# redefine, but disable, some usual context tokens for 'clearer' error messages
	$context->operators->redefine([ ',', 'fn' ], from => 'Numeric');
	$context->lists->redefine('List', from => 'Numeric');
	$context->operators->redefine([ '/', '^', '**' ], from => 'Numeric');
	$context->operators->undefine('/', '^', '**');
	delete $context->operators->get('/')->{space};

	# Set default variables 'p' and 'q'
	$Parser::Context::Variables::type{Boolean} = $Parser::Context::Variables::type{Real};
	$context->variables->are(
		p => 'Boolean',
		q => 'Boolean',
	);

	# Set up new reduction rules:
	$context->reductions->set('x||1' => 1, 'x||0' => 1, 'x&&1' => 1, 'x&&0' => 1, '!!x' => 1);

	# Define constants for 'True' and 'False'
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

	# add our methods to this context
	bless $context, 'context::Boolean::Context';

	# allow authors to create Boolean values
	main::PG_restricted_eval('sub Boolean { Value->Package("Boolean()")->new(@_) }');
}

# top-level access to context-specific T and F
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

# Subclass the Parser::Context to override copy() and add T and F functions
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

# Access to the constant T and F values
sub F { shift->constants->get('F')->{value} }
sub T { shift->constants->get('T')->{value} }

# Easy setting of precedence to different types
sub setPrecedence {
	my ($self, $order) = @_;
	if ($order eq 'equal') {
		$self->operators->set(
			or  => { precedence => 3 },
			xor => { precedence => 3 },
			and => { precedence => 3 },
			' ' => { precedence => 3 },
			not => { precedence => 3 },
			'`' => { precedence => 3 },
		);
	} elsif ($order eq 'oxan') {
		$self->operators->set(
			or  => { precedence => 1 },
			xor => { precedence => 2 },
			and => { precedence => 3 },
			' ' => { precedence => 3 },
			not => { precedence => 6 },
			'`' => { precedence => 6 },
		);
	} else {
		Value::Error("Unknown precedence class '%s'", $order);
	}
}

# Subclass Parser::Number to return the constant T or F
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

# Subclass Value::Formula for boolean formulas
package context::Boolean::Formula;
our @ISA = ('Value::Formula');

sub cmp_defaults { return (shift->SUPER::cmp_defaults(@_), mathQuillOpts => '{spaceBehavesLikeTab: false}') }

# use every combination of T/F across all variables
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

sub createPointValues {
	my $self    = shift;
	my $context = $self->context;
	my $points  = shift || $self->{test_points} || $self->createRandomPoints;
	my @vars    = $context->variables->variables;
	my @params  = $context->variables->parameters;

	my $f = $self->{f};
	$f = $self->{f} = $self->perlFunction(undef, [ @vars, @params ]) unless $f;

	my (@values, $v);
	foreach my $p (@$points) {
		$v = eval { &$f(@$p) };
		Value::Error("Can't evaluate formula on test point (%s)", join(',', @{$p})) unless (defined $v);
		push @values, $v;
	}

	$self->{test_points} = $points;
	$self->{test_values} = \@values;

	return \@values;
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

# remove once UOP::string passses 'same' as second argument
sub string {
	my ($self, $precedence, $showparens, $position, $outerRight) = @_;
	$showparens = "same" if !($position // '') && !($showparens // '');
	return $self->SUPER::string($precedence, $showparens, $position, $outerRight);
}

# remove once UOP::TeX passses 'same' as second argument
sub TeX {
	my ($self, $precedence, $showparens, $position, $outerRight) = @_;
	$showparens = "same" if !($position // '') && !($showparens // '');
	return $self->SUPER::TeX($precedence, $showparens, $position, $outerRight);
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
	my $self    = shift;
	my $context = $self->context;
	my $reduce  = $context->{reduction};
	my $op      = $self->{op};

	if ($op->isNeg && $reduce->{'!!x'}) {
		delete $op->{op}{noParens};
		return $op->{op};
	}

	if ($op->{isConstant} && $context->flag('reduceConstants')) {
		return $self->Item('Value')->new($self->{equation}, [ 1 - $op->eval ]);
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

# use the context settings
sub string {
	my $self  = shift;
	my $const = $self->context->constants;
	my $T     = $const->get('T')->{string} // 'T';
	my $F     = $const->get('F')->{string} // 'F';
	return ($F, $T)[ $self->value ];
}

# use the context settings
sub TeX {
	my $self  = shift;
	my $const = $self->context->constants;
	my $T     = $const->get('T')->{TeX} // '\top';
	my $F     = $const->get('F')->{TeX} // '\bot';
	return ($F, $T)[ $self->value ];
}

sub perl {
	my $self = shift;
	return $self->value ? 'context::Boolean->T' : 'context::Boolean->F';
}

sub cmp_defaults { shift->SUPER::cmp_defaults(@_) }

1;
