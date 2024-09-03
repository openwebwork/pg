
=head1 NAME

contextReaction.pl - Implements a MathObject class for checmical reactions.

=head1 DESCRIPTION

This file implements a Context in which checmical reactions can be
specified and compared.  Reactions can be composed of sums of integer
multiples of elements, molecules, ions, compounds, and complexes
separated by a right arrow (indicated by C<< --> >>).  Helpful error
messages are given when a reaction is not of the correct form.  Sums
of compounds can be given in any order, but the elements within a
compound must be in the order given by the correct answer; e.g., if
the correct answer specifies C<CO_2>, then C<O_2C> would be marked
incorrect.

To use the context include

    loadMacros("contextReaction.pl");
    Context("Reaction");

at the top of your PG file, then create C<Formula> objects for your
reactions.  For example:

    $R = Formula("4P + 5O_2 --> 2P_2O_5");

Ions can be specified using C<^> to produce superscripts, as in C<Na^+2> or
C<Na^{+2}>.  Note that the charge may be listed with prefix notation (+2)
or postfix notation (2+).  A sign by itself is assumed to have number
1, so that C<Na^+> is equivalent to C<Na^1+>.

States can be appended to compounds, as in C<AgCl(s)>.  So you can
make reactions like the following:

        Ag^+(aq) + Cl^-(aq) --> AgCl(s)

Note that a state can be given by itself, e.g., C<(l)>, so you can ask
for a student to supply just a state.

Complexes can be formed using square brakets, as in

        [CoCl_4(NH_3)_2]^−

These can be used in reactions as with any other compound.

Reactions know how to create their own TeX versions (via C<< $R->TeX >>), and
know how to check student answers (via C<< $R->cmp >>), just like any other
MathObject.

The Reaction Context also allows you to create parts of reactions.
E.g., you could create

    $products = Formula("4CO_2 + 6H_2O");

which you could use in a problem as follows:

    loadMacros("contextReaction.pl");
    Context("Reaction");

    $reactants = Formula("2C_2H_6 + 7O_2");
    $products  = Formula("4CO_2 + 6H_2O");

    BEGIN_PGML
    [`[$reactants] \longrightarrow`] [_____________________]{$products}.
    END_PGML

Note that sums are simplified during comparisons, so that
C<Formula("O + O")> and C<Formula("2O")> are equivalent, but
C<Formula("2O")> and C<Formula("O_2")> are not equivalent.

All the elements of the periodic table are available within the
Reaction Context, as are the states C<(aq)>, C<(s)>, C<(l)>, C<(g)>,
and C<(ppt)>.  By default, students are required to include states if
the corect answer includes them, but the flag C<studentsMustUseStates>
controls this behavior.  Setting this flag to C<0> will make the use
of states optional in student answers.  That is, if the correct answer
includes states, the student answer need not include them; but if the
student I<does> include them, they must be correct.  For example, if
you set

    Context()->flags-set(studentsMustUseStates => 0);

then with the correct answer of C<Formula("Cl(g)")>, a student answer
of either C<Cl> or C<Cl(g)> will be marked correct, but an answer of
C<Cl(aq)> will be marked false.  Note that if the correct answer does
not include a state and a student answer does, then it will be marked
incorrect regardless of the setting of C<studentsMustUsetates>.

If you need additional terms, like C<Heat> for example, you can add
them as variables:

    Context()->variables->add(Heat => $context::Reaction::CONSTANT);

Then you can make formulas that include C<Heat> as a term.  These
"constants" are not allowed to have coefficients or sub- or
superscripts, and can not be combined with compounds except by
addition.  If you want a term that can be combined in those ways, use
C<$context::Reaction::ELEMENT> instead, as in

    Context()->variables->add(e => $context::Reaction::ELEMENT);

to allow C<e> for electrons, for example.

If you need to add more states, use C<$context::Reaction::STATE>, as in

    Context()->variables->add('(x)' => $context::Reaction::STATE);

to allow a state of C<(x)> for a compound.

=cut

######################################################################

sub _contextReaction_init { context::Reaction::Init() }

######################################################################
#
#  The main MathObject class for reactions
#
package context::Reaction;
our @ISA = ('Value::Formula');

#
#  Some type declarations for the various classes
#
our $ELEMENT  = { isValue => 1, type => Value::Type('Element',  1) };
our $MOLECULE = { isValue => 1, type => Value::Type('Molecule', 1) };
our $ION      = { isValue => 1, type => Value::Type('Ion',      1) };
our $COMPOUND = { isValue => 1, type => Value::Type('Compound', 1) };
our $COMPLEX  = { isValue => 1, type => Value::Type('Complex',  1) };
our $REACTION = { isValue => 1, type => Value::Type('Reaction', 1) };
our $CONSTANT = { isValue => 1, type => Value::Type('Constant', 1) };
our $STATE    = { isValue => 1, type => Value::Type('State',    1) };

#
#  Set up the context and Reaction() constructor
#
sub Init {
	my $context = $main::context{Reaction} = Parser::Context->getCopy('Numeric');
	$context->{name} = 'Reaction';
	$context->functions->clear();
	$context->strings->clear();
	$context->constants->clear();
	$context->lists->clear();
	$context->lists->add(
		'List'    => { class => 'context::Reaction::List::List',    open => '',  close => '',  separator => ' + ' },
		'Complex' => { class => 'context::Reaction::List::Complex', open => '[', close => ']', separator => '' },
	);
	$context->parens->clear();
	$context->parens->add(
		'(' => { close => ')', type => 'List', formList  => 1, removable => 1 },
		'{' => { close => '}', type => 'List', removable => 1 },
		'[' => { close => ']', type => 'Complex' },
	);
	$context->operators->clear();
	$context->operators->set(
		'-->' => {
			precedence    => 1,
			associativity => 'left',
			type          => 'bin',
			string        => ' --> ',
			class         => 'context::Reaction::BOP::arrow',
			TeX           => ' \\longrightarrow '
		},

		'+' => {
			precedence    => 2,
			pprecedence   => 6,
			associativity => 'left',
			type          => 'both',
			string        => ' + ',
			class         => 'context::Reaction::BOP::add',
			isComma       => 1
		},

		' ' => {
			precedence    => 3,
			associativity => 'left',
			type          => 'bin',
			string        => ' ',
			class         => 'context::Reaction::BOP::multiply',
			hidden        => 1
		},

		'_' => {
			precedence    => 4,
			associativity => 'left',
			type          => 'bin',
			string        => '_',
			class         => 'context::Reaction::BOP::underscore'
		},

		'^' => {
			precedence    => 4,
			associativity => 'left',
			type          => 'bin',
			string        => '^',
			class         => 'context::Reaction::BOP::superscript'
		},

		'-' => {
			precedence    => 5,
			pprecedence   => 6,
			associativity => 'left',
			type          => 'both',
			string        => '-',
			class         => 'Parser::BOP::undefined'
		},
		'u-' => {
			precedence    => 6,
			associativity => 'left',
			type          => 'unary',
			string        => '-',
			class         => 'context::Reaction::UOP::minus',
			hidden        => 1
		},
		'p-' => {
			precedence    => 6,
			associativity => 'right',
			type          => 'unary',
			string        => '-',
			class         => 'context::Reaction::UOP::minus',
			hidden        => 1
		},
		'u+' => {
			precedence    => 6,
			associativity => 'left',
			type          => 'unary',
			string        => '+',
			class         => 'context::Reaction::UOP::plus',
			hidden        => 1
		},
		'p+' => {
			precedence    => 6,
			associativity => 'right',
			type          => 'unary',
			string        => '+',
			class         => 'context::Reaction::UOP::plus',
			hidden        => 1
		}
	);
	$context->variables->{namePattern} = qr/\(?[a-zA-Z][a-zA-Z0-9]*\)?/;
	$context->variables->are(
		map { $_ => $ELEMENT } (
#<<<
			'H',                                                                                                    'He',
			'Li', 'Be',                                                               'B',  'C' , 'N' , 'O',  'F' , 'Ne',
			'Na', 'Mg',                                                               'Al', 'Si', 'P' , 'S',  'Cl', 'Ar',
			'K',  'Ca',   'Sc', 'Ti', 'V',  'Cr', 'Mn', 'Fe', 'Co', 'Ni', 'Cu', 'Zn', 'Ga', 'Ge', 'As', 'Se', 'Br', 'Kr',
			'Rb', 'Sr',   'Y' , 'Zr', 'Nb', 'Mo', 'Tc', 'Ru', 'Rh', 'Pd', 'Ag', 'Cd', 'In', 'Sn', 'Sb', 'Te', 'I' , 'Xe',
			'Cs', 'Ba',   'Lu', 'Hf', 'Ta', 'W' , 'Re', 'Os', 'Ir', 'Pt', 'Au', 'Hg', 'Ti', 'Pb', 'Bi', 'Po', 'At', 'Rn',
			'Fr', 'Ra',   'Lr', 'Rf', 'Db', 'Sg', 'Bh', 'Hs', 'Mt', 'Ds', 'Rg', 'Cn', 'Nh', 'Fl', 'Mc', 'Lv', 'Ts', 'Og',

			              'La', 'Ce', 'Pr', 'Nd', 'Pm', 'Sm', 'Eu', 'Gd', 'Tb', 'Dy', 'Ho', 'Er', 'Tm', 'Yb',
			              'Ac', 'Th', 'Pa', 'U',  'Np', 'Pu', 'Am', 'Cm', 'Bk', 'Cf', 'Es', 'Fm', 'Md', 'No',
#>>>
		)
	);
	$context->variables->add(map { $_ => $STATE } ('(aq)', '(s)', '(l)', '(g)', '(ppt)'));
	$context->reductions->clear();
	$context->flags->set(studentsMustUseStates => 1);
	$context->flags->set(reduceConstants       => 0);
	$context->{parser}{Number}   = 'context::Reaction::Number';
	$context->{parser}{Variable} = 'context::Reaction::Variable';
	$context->{parser}{Formula}  = 'context::Reaction';
	$context->{value}{Reaction}  = 'context::Reaction';
	$context->{value}{Element}   = 'context::Reaction::Variable';
	$context->{value}{Constant}  = 'context::Reaction::Variable';
	$context->{value}{State}     = 'context::Reaction::Variable';
	Parser::Number::NoDecimals($context);

	main::PG_restricted_eval('sub Reaction {Value->Package("Formula")->new(@_)};');
}

#
#  Handle postfix - and + in superscripts
#
sub Op {
	my $self = shift;
	my $name = shift;
	my $ref  = $self->{ref} = shift;
	if ($self->state eq 'operand') {
		my $context = $self->{context};
		my $op;
		($name, $op) = $context->operators->resolve($name);
		($name, $op) = $context->operators->resolve($op->{space}) if $self->{space} && defined($op->{space});
		if ($op->{type} eq 'both'
			&& $context->{operators}{"p$name"}
			&& $self->top->{value}->class eq 'Number'
			&& $self->prev->{type} eq 'operator'
			&& $self->prev->{name} eq '^')
		{
			($name, $op) = $context->operators->resolve("p$name");
			$self->pushOperand($self->Item('UOP')->new($self, $name, $self->pop->{value}, $ref));
			return;
		}
	} elsif ($self->state eq 'operator' && $self->top->{name} =~ m/^u/) {
		$self->SimpleCharge;
	}
	$self->SUPER::Op($name, $ref);
}

#
#  Handle superscripts of just + or -
#
sub Close {
	my $self = shift;
	my $type = shift;
	my $ref  = $self->{ref} = shift;
	$self->SimpleCharge if $self->state eq 'operator' && $self->top->{name} =~ m/^u/;
	$self->SUPER::Close($type, $ref);
}

sub pushOperand {
	my $self  = shift;
	my $value = shift;
	if ($self->state eq 'operator' && $value->type ne 'Number' && $self->top->{name} =~ m/^u/) {
		$self->SimpleCharge;
		$self->ImplicitMult;
	}
	$self->push({ type => 'operand', ref => $self->{ref}, value => $value });
}

sub SimpleCharge {
	my $self = shift;
	my $top  = $self->pop;
	my $one  = $self->Item('Number')->new($self, 1, $self->{ref});
	$self->pushOperand($self->Item('UOP')->new($self, $top->{name}, $one, $self->{ref}));
}

#
#  Compare by checking of the trees are equivalent
#
sub compare {
	my ($l, $r) = @_;
	my $self    = $l;
	my $context = $self->context;
	$r = $context->Package('Formula')->new($context, $r) unless Value::isFormula($r);
	return ($l->{tree}->equivalent($r->{tree}) ? 0 : 1);
}

#
#  Don't allow evaluation
#
sub eval {
	my $self = shift;
	$self->Error("Can't evaluate " . $self->TYPE);
}

#
#  Provide a useful name
#
sub TYPE      {'a chemical reaction'}
sub cmp_class {'a Chemical Reaction'}

#
#  Set up the answer checker.  Avoid the list checker in
#    Value::Formula::cmp_equal (for when the answer is a
#    sum of compounds) and provide a postprocessor to
#    give warnings when a reaction is compared to a
#    student answer that isn't a reaction.
#
sub cmp_defaults { (showTypeWarnings => 1) }
sub cmp_equal    { Value::cmp_equal(@_) }

sub cmp_postprocess {
	my $self = shift;
	my $ans  = shift;
	return unless $self->{tree}->type eq 'Reaction';
	$self->cmp_Error($ans, "Your answer doesn't seem to be a reaction\n(it should contain a reaction arrow '-->')")
		if $ans->{showTypeWarnings} && $ans->{student_value}{tree}->type ne 'Reaction';
}

#
#  Since the context only allows things that are comparable, we
#  don't really have to check anything.  (But if somone added
#  strings or constants, we would.)
#
sub typeMatch {
	my $self  = shift;
	my $other = shift;
	return 1;
}

######################################################################
#
#  The replacement for the Parser:Number class
#
package context::Reaction::Number;
our @ISA = ('Parser::Number');

#
#  Equivalent is equal
#
sub equivalent {
	my $self  = shift;
	my $other = shift;
	return 0 unless $other->class eq 'Number';
	return $self->eval == $other->eval;
}

sub isChemical {0}

sub class {'Number'}
sub TYPE  {'a Number'}

######################################################################
#
#  The replacement for Parser::Variable.  We hold the elements here.
#
package context::Reaction::Variable;
our @ISA = ('Parser::Variable');

#
#  Two elements are equivalent if their names are equal
#
sub equivalent {
	my $self  = shift;
	my $other = shift;
	return $other->equivalent($self) if $other->class eq 'BOP';
	return 0 unless $other->class eq 'Variable';
	return $self->{name} eq $other->{name};
}

sub eval { context::Reaction::eval(@_) }

sub isChemical {1}

#
#  Print element names in Roman
#
sub TeX {
	my $self = shift;
	return "{\\rm $self->{name}}";
}

sub class {'Variable'}

#
#  For a printable name, use a constant's name,
#  and 'an element' for an element.
#
sub TYPE {
	my $self = shift;
	return ($self->type eq 'Constant' ? 'a constant' : $self->type eq 'State' ? 'a state' : 'an element');
}

######################################################################
#
#  General binary operator (add, multiply, arrow, and underscore
#  are subclasses of this).
#
package context::Reaction::BOP;
our @ISA = ('Parser::BOP');

#
#  Binary operators produce chemcicals (unless overridden, as in arrow)
#
sub isChemical {1}

sub eval { context::Reaction::eval(@_) }

#
#  Two nodes are equivalent if their operands are equivalent
#  and they have the same operator
#
sub equivalent {
	my $self  = shift;
	my $other = shift;
	#        return $other->equivalent($self)
	#		if $other->class eq 'BOP' && $other->{rop}->type eq 'State' && $self->{rop}->type ne 'State';
	return 0 unless $other->class eq 'BOP';
	return 0 unless $self->{bop} eq $other->{bop};
	return $self->{lop}->equivalent($other->{lop}) && $self->{rop}->equivalent($other->{rop});
}

######################################################################
#
#  Implements the --> operator
#
package context::Reaction::BOP::arrow;
our @ISA = ('context::Reaction::BOP');

#
#  It is a reaction, not a chemical
#
sub isChemical {0}

#
#  Check that the operands are correct.
#
sub _check {
	my $self = shift;
	$self->Error("The left-hand side of '-->' must be a (sum of) reactants, not %s", $self->{lop}->TYPE)
		unless $self->{lop}->isChemical;
	$self->Error("The right-hand side of '-->' must be a (sum of) products, not %s", $self->{rop}->TYPE)
		unless $self->{rop}->isChemical;
	$self->{type} = $REACTION->{type};
}

sub TYPE {'a reaction'}

######################################################################
#
#  Implements addition, which forms a list of operands, so acts like
#  the Parser::BOP::comma operator
#
package context::Reaction::BOP::add;
our @ISA = ('Parser::BOP::comma', 'context::Reaction::BOP');

#
#  Check that the operands are OK
#
sub _check {
	my $self = shift;
	$self->Error("Can't add %s and %s", $self->{lop}->TYPE, $self->{rop}->TYPE)
		unless $self->{lop}->isChemical && $self->{rop}->isChemical;
	$self->SUPER::_check(@_);
}

#
#  Two are equivalent if they are equivalent in either order.
#  (never really gets used, since these result in the creation
#  of a list rather than an "add" node in the final tree.
#
sub equivalent {
	my $self  = shift;
	my $other = shift;
	return 0 unless $other->class eq 'BOP';
	return $self->SUPER::equivalent($other)
		|| ($self->{lop}->equivalent($other->{rop}) && $self->{rop}->equivalent($other->{rop}));
}

sub TYPE {'a sum of Compounds'}

######################################################################
#
#  Implements concatenation, which produces compounds or integer
#  multiples of elements or molecules.
#
package context::Reaction::BOP::multiply;
our @ISA = ('context::Reaction::BOP');

#
#  Check that the operands are OK
#
sub _check {
	my $self = shift;
	my ($lop, $rop) = ($self->{lop}, $self->{rop});
	$self->Error("Can't combine %s and %s", $lop->TYPE, $rop->TYPE)
		unless ($lop->class eq 'Number' || $lop->isChemical) && $rop->isChemical;
	$self->Error("Compound already has a state") if $lop->{hasState} && $rop->type eq 'State';
	$self->Error("Can't combine %s with %s", $lop->TYPE,   $rop->TYPE)   if $lop->{hasState} && $rop->isChemical;
	$self->Error("Can't combine %s with %s", $lop->TYPE,   $rop->TYPE)   if $rop->{hasState} && $lop->isChemical;
	$self->Error("Can't combine %s with %s", $lop->{name}, $rop->TYPE)   if $lop->type eq 'Constant';
	$self->Error("Can't combine %s with %s", $lop->TYPE,   $rop->{name}) if $rop->type eq 'Constant';
	$self->{type} = $COMPOUND->{type};

	if ($self->{lop}{hasNumber}) {
		my $n = $self->{lop}{lop};
		$self->{lop}{lop}      = $self->{lop}{rop};
		$self->{lop}{rop}      = $self->{rop};
		$self->{lop}{hasState} = 1 if $self->{rop}->type eq 'State';
		delete $self->{lop}{hasNumber};
		$self->{rop} = $self->{lop};
		$self->{lop} = $n;
	}
	$self->{hasState}  = 1 if $self->{rop}->type eq 'State';
	$self->{hasNumber} = 1 if $self->{lop}->class eq 'Number';
}

#
#  Remove ground state, if needed
#
sub equivalent {
	my $self  = shift;
	my $other = shift;
	if ($other->class eq 'List') {
		my $parens = $self->context->parens->get('(');
		my $list   = $self->Item('List')->new($self->{equation}, [$self], 1, $parens);
		return $list->equivalent($other);
	}
	my $states = $self->context->flags->get('studentsMustUseStates');
	my $equiv  = $self->SUPER::equivalent($other);
	return ($equiv || !$self->{hasState} || $states ? $equiv : $self->{lop}->equivalent($other));
}

#
#  No space in output for implied multiplication
#
sub string {
	my $self = shift;
	return $self->{lop}->string . $self->{rop}->string;
}

sub TeX {
	my $self = shift;
	return $self->{lop}->TeX . $self->{rop}->TeX;
}

#
#  Handle states separately
#
sub TYPE {
	my $self = shift;
	return $self->{rop}->TYPE eq 'a state' ? $self->{lop}->TYPE . ' with state' : 'a compound';
}

######################################################################
#
#  Implements the underscore for creating molecules
#
package context::Reaction::BOP::underscore;
our @ISA = ('context::Reaction::BOP');

#
#  Check that the operands are OK
#
sub _check {
	my $self = shift;
	my ($lop, $rop) = ($self->{lop}, $self->{rop});
	$self->Error("The left-hand side of '_' must be an element, compound, or complex, not %s", $lop->TYPE)
		unless $lop->type =~ m/Element|Compound|Complex/ && !$lop->{hasState};
	$self->Error("The right-hand side of '_' must be a number, not %s", $rop->TYPE)
		unless $rop->class eq 'Number';
	$self->{type} = $MOLECULE->{type};
}

#
#  Create proper TeX output
#
sub TeX {
	my $self = shift;
	my $left = $self->{lop}->TeX;
	$left = "($left)" if $self->{lop}->type eq 'Compound';
	return $left . '_{' . $self->{rop}->TeX . '}';
}

#
#  Create proper text output
#
sub string {
	my $self = shift;
	my $left = $self->{lop}->string;
	$left = "($left)" if $self->{lop}->type eq 'Compound';
	return $left . '_' . $self->{rop}->string;
}

sub TYPE {'a molecule'}

######################################################################
#
#  Implements the superscript for creating ions
#
package context::Reaction::BOP::superscript;
our @ISA = ('context::Reaction::BOP');

#
#  Check that the operands are OK
#
sub _check {
	my $self = shift;
	my ($lop, $rop) = ($self->{lop}, $self->{rop});
	$self->Error("The left-hand side of '^' must be an element, molecule, or complex, not %s", $lop->TYPE)
		unless $lop->type =~ m/Element|Molecule|Compound|Complex/ && !$lop->{hasState};
	$self->Error("The right-hand side of '^' must be %s, not %s", context::Reaction::UOP->TYPE, $rop->TYPE)
		unless $rop->class eq 'UOP';
	$self->{type} = $ION->{type};
}

#
#  Create proper TeX output
#
sub TeX {
	my $self = shift;
	my $left = $self->{lop}->TeX;
	$left = "\\left($left\\right)" if $self->{lop}->type eq 'Compound';
	return $left . '^{' . $self->{rop}->TeX . '}';
}

#
#  Create proper text output
#
sub string {
	my $self  = shift;
	my $left  = $self->{lop}->string;
	my $right = $self->{rop}->string;
	$left  = "($left)" if $self->{lop}->type eq 'Compound';
	$right = "($right)" unless $right eq '-' || $right eq '+';
	return "$left^$right";
}

sub TYPE {'an ion'}

######################################################################
#
#  General unary operator (minus and plus are subclasses of this).
#
package context::Reaction::UOP;
our @ISA = ('Parser::UOP');

sub _check {
	my $self = shift;
	$self->{type} = $Value::Type{number};
	return if ($self->checkNumber);
	my $name = $self->{uop};
	$name =~ s/^[up]//;
	$self->Error("Can't use unary '%s' with %s", $name, $self->{op}->TYPE);
}

#
#  Unary operators produce numbers
#
sub isChemical {0}

sub eval { context::Reaction::eval(@_) }

#
#  Two nodes are equivalent if their operands are equivalent
#  and they have the same operator
#
sub equivalent {
	my $self  = shift;
	my $other = shift;
	return 0 unless $other->class eq 'UOP';
	my ($sop, $oop) = ($self->{uop}, $other->{uop});
	$sop =~ s/^[up]//;
	$oop =~ s/^[up]//;
	return 0 unless $sop eq $oop;
	return $self->{op}->equivalent($other->{op});
}

#
#  Always put signs on the right
#
sub string {
	my $self = shift;
	my $n    = $self->{op}->string($uop->{precedence});
	return ($n eq '1' ? '' : $n) . $self->{def}{string};
}

#
#  Always put signs on the right
#
sub TeX {
	my $self = shift;
	my $uop  = $self->{def};
	my $op   = (defined($uop->{TeX}) ? $uop->{TeX} : $uop->{string});
	return $self->{op}->TeX($uop->{precedence}) . $op;
}

sub TYPE {'a charge'}

######################################################################
#
#  Negative numbers (for ion exponents)
#
package context::Reaction::UOP::minus;
our @ISA = ('context::Reaction::UOP');

######################################################################
#
#  Positive numbers (for ion exponents)
#
package context::Reaction::UOP::plus;
our @ISA = ('context::Reaction::UOP');

######################################################################
#
#  Implements sums of compounds as a list
#
package context::Reaction::List::List;
our @ISA = ('Parser::List::List');

#
#  Two sums are equivalent if their terms agree in any order.
#
sub equivalent {
	my ($self, $other) = @_;
	$other = $self->new($self->{equation}, [$other], 1, $self->context->parens->get('('), $other->type)
		unless $other->type eq $self->type;
	my $correct = $self->organizeList();
	my $student = $other->organizeList();
	my @ckeys   = keys(%$correct);
	my @skeys   = main::lex_sort(keys(%$student));
	return 0
		unless scalar(@ckeys) == scalar(@skeys)
		&& join(',', main::lex_sort(@ckeys)) eq join(',', main::lex_sort(@skeys));
	for my $name (@ckeys) {
		my ($c, $s) = ($correct->{$name}{count}, $student->{$name}{count});
		$s -= $c;
		return 0 if $s < 0;    # not equivalent if student doesn't have enough of this element
		my ($cstates, $sstates) = ($correct->{$name}{states}, $student->{$name}{states});
		for my $state (keys %{$cstates}) {
			my ($cs, $ss) = ($cstates->{$state}, $sstates->{$state} || 0);
			$cs -= $ss;
			return 0 if $cs < 0;    # not equivalent if student has too many of this state
			$s -= $cs;
		}
		return 0 if $s != 0;        # not equivalent if student has the wrong number of this element
	}
	return 1;
}

#
#  Get a hash of element (or compound, etc.) names used in the list
#  mapping to the count of each and a hash of the states used and
#  their counts.  States are only recorded if students don't need
#  to include them (othewise the hash names will include the states).
#
sub organizeList() {
	my $self     = shift;
	my $required = $self->context->flags->get('studentsMustUseStates');
	my $list     = {};
	for my $item (@{ $self->{coords} }) {
		my ($count, $state) = (1, '');
		($count, $item) = ($item->{lop}{value}, $item->{rop}) if $item->{hasNumber};
		($state, $item) = ($item->{rop}->string, $item->{lop}) if $item->{hasState};
		my $name = $item->string . ($required && $state ? $state : '');
		$list->{$name} = { count => 0, states => {} } unless defined $list->{$name};
		if (!$required && $state) {
			my $states = $list->{$name}{states};
			$states->{$state} = 0 unless defined $ststes->{$state};
			$states->{$state} += $count;
		} else {
			$list->{$name}{count} += $count;
		}
	}
	return $list;
}

#
#  Use "+" between entries in the list (with no parens)
#
sub TeX {
	my $self       = shift;
	my $precedence = shift;
	my @coords     = ();
	foreach my $x (@{ $self->{coords} }) { push(@coords, $x->TeX) }
	return join(' + ', @coords);
}

sub eval { context::Reaction::eval(@_) }

sub isChemical {1}

sub TYPE {'a sum of compounds'}

######################################################################
#
#  Implements complexes as a list
#
package context::Reaction::List::Complex;
our @ISA = ('Parser::List::List');

sub _check {
	my $self = shift;
	$self->Error("A complex can't contain %s", context::Reaction::List::List->TYPE)
		if $self->{type}{length} != 1;
	my $arg = $self->{coords}[0];
	$self->Error("The contents of a complex must be an element, molecule, ion, or compound, not %s", $arg->TYPE)
		unless $arg->type =~ /Element|Molecule|Ion|Compound/ && !$arg->{hasState};
	$self->{type} = $COMPLEX->{type};
}

#
#  Two complexes are equivalent if their contents are equivalent
#  (we check by stringifying them and sorting, then compare results)
#
sub equivalent {
	my $self  = shift;
	my $other = shift;
	return 0 unless $other->type eq $self->type;
	return $self->{coords}[0]->equivalent($other->{coords}[0]);
}

sub eval { context::Reaction::eval(@_) }

sub isChemical {1}

sub TYPE {'a complex'}

######################################################################

1;
