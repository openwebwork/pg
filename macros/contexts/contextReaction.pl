
=head1 NAME

contextReaction.pl - Implements a MathObject class for chemical reactions.

=head1 DESCRIPTION

This file implements a Context in which chemical reactions can be
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

Ions can be specified using C<^> to produce superscripts, as in
C<Ca^+2> or C<Ca^{+2}>. Note that the charge may be listed with prefix
notation (+2) or postfix notation (2+). By default, TeX will display
only the sign of the charge of singly charged ions, e.g., C<Na^+> and
C<Cl^->. However, the context flag C<< showUnity=>1 >> can be used to
direct TeX to use an alternative notation for singly charged ions, by
which the numerical magnitude (1) is displayed along with the sign of
the charge, e.g., C<Na^1+> and C<Cl^1->. The default value of
C<<showUnity>> is zero.

States can be appended to compounds, as in C<AgCl(s)>.  So you can
make reactions like the following:

        Ag^+(aq) + Cl^-(aq) --> AgCl(s)

Note that a state can be given by itself, e.g., C<(l)>, so you can ask
for a student to supply just a state.

Complexes can be formed using square brackets, as in

        [CoCl_4(NH_3)_2]^-

These can be used in reactions as with any other compound.

Reactions know how to create their own TeX versions (via C<< $R->TeX >>),
and know how to check student answers (via C<< $R->cmp >>), just like
any other MathObject.

The Reaction Context also allows you to create parts of reactions.
E.g., you could create

    $products = Formula("4CO_2 + 6H_2O");

which you could use in a problem as follows:

    loadMacros("contextReaction.pl");
    Context("Reaction");

    $reactants = Formula("2C_2H_6 + 7O_2");
    $products  = Formula("4CO_2 + 6H_2O");

    BEGIN_PGML
    [`[$reactants] \longrightarrow`] [_]{$products}{25}.
    END_PGML

Note that sums are simplified during comparisons, so that
C<Formula("O + O")> and C<Formula("2O")> are equivalent, but
C<Formula("2O")> and C<Formula("O_2")> are not equivalent.

All the elements of the periodic table are available within the
Reaction Context, as are the states C<(aq)>, C<(s)>, C<(l)>, C<(g)>,
and C<(ppt)>.  By default, students are required to include states if
the correct answer includes them, but the flag C<studentsMustUseStates>
controls this behavior.  Setting this flag to C<0> will make the use
of states optional in student answers.  That is, if the correct answer
includes states, the student answer need not include them; but if the
student I<does> include them, they must be correct.  For example, if
you set

    Context()->flags->set(studentsMustUseStates => 0);

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
superscripts, and cannot be combined with compounds except by
addition.  If you want a term that can be combined in those ways, use
C<$context::Reaction::ELEMENT> instead, as in

    Context()->variables->add(e => $context::Reaction::ELEMENT);

to allow C<e> for electrons, for example.

If you need to add more states, use C<$context::Reaction::STATE>, as in

    Context()->variables->add('(x)' => $context::Reaction::STATE);

to allow a state of C<(x)> for a compound.

By default, the Reaction context checks the student answer against the
correct answer in the form the correct answer is given (molecular or
condensed structural form).  If you want to allow either form, then
you can set the flag C<acceptMolecularForm> to C<1>, in which case,
the student's answwer is compared first to the original correct answer
and then to its molecular form.  For example, if the correct answer is
`(NH_4)_3PO_4`, then a student answer of `N_3H_12PO_4` would also be
considered correct when this flag is set to C<1>.

You can convert a compound (or every term of a complete reaction) to
molecular form using the C<molecularForm> method of any Reaction
object.  For example

    $R = Compute("CH_3CH_2CH_3")->molecularForm;

would make C<$R> be the quivalent of C<Compute("C_3H_8")>.

Note that student answers aren't reduced to molecular form when
C<acceptMolecularForm> is true.  If you want to allow students to
enter compounds in any form, you can set the C<compareMolecular> flag
to C<1>, in which case both the correct and student answers are
formatted in molecular form internally before they are compared.

The molecular form will have the elements in the order that they first
appeared in the compound, and the student must use the same order for
their answer to be considered correct.  If you want to allow the
student to enter the elements in any order, you can set the
C<keepElementOrder> flag to C<0> which will cause the molecular form
to be in alphabetical order.  That way, if the student has the correct
number of each element, in any order, the two answers will match.

The Reaction context can perform an automatic reduction that combines
adjacent elements that are the same.  This is controlled by the
C<combineAdjacentElements> flag, which is C<1> by default.  For
example,

    $R1 = Compute("COOH");
    $R2 = Compute("CO_2H");

would equal each other when the flag is set, even when
C<compareMolecular> is not set.

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
	$context->lists->are(
		'List'    => { class => 'context::Reaction::List::List',    open => '',  close => '',  separator => ' + ' },
		'Complex' => { class => 'context::Reaction::List::Complex', open => '[', close => ']', separator => '' },
	);
	$context->parens->are(
		'(' => { close => ')', type => 'List', formList  => 1, removable => 1 },
		'{' => { close => '}', type => 'List', removable => 1 },
		'[' => { close => ']', type => 'Complex' },
	);
	$context->operators->are(
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
	$context->flags->set(
		showUnity               => 0,
		studentsMustUseStates   => 1,
		reduceConstants         => 1,
		combineAdjacentElements => 1,
		acceptMolecularForm     => 0,
		compareMolecular        => 0,
		keepElementOrder        => 1,
	);
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
	my $self    = shift;
	my $name    = shift;
	my $ref     = $self->{ref} = shift;
	my $context = $self->{context};
	my $op;
	($name, $op) = $context->operators->resolve($name);
	($name, $op) = $context->operators->resolve($op->{space}) if $self->{space} && defined($op->{space});
	if ($self->state eq 'operand') {
		if ($op->{type} eq 'both'
			&& $context->{operators}{"p$name"}
			&& $self->top->{value}->class eq 'Number'
			&& $self->prev->{type} eq 'operator'
			&& $self->prev->{name} eq '^')
		{
			($name, $op) = $context->operators->resolve("p$name");
			$self->pushCharge($name, $self->pop->{value});
			return;
		}
	}
	$self->SUPER::Op($name, $ref);
}

#
#  Handle superscripts of just + or - or postscript + or -
#
sub Close {
	my $self = shift;
	my $type = shift;
	my $ref  = $self->{ref} = shift;
	$self->SimpleCharge if $self->state eq 'operator' && $self->top->{name} =~ m/^u/;
	my $name    = $self->top->{name};
	my $context = $self->{context};
	if ($self->state eq 'operator'
		&& $context->{operators}{"p$name"}
		&& $self->prev->{type} eq 'operand'
		&& $self->top(-2)->{type} eq 'open')
	{
		$self->pop;
		($name) = $context->operators->resolve("p$name");
		$self->pushCharge($name, $self->pop->{value});
	}
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

sub pushCharge {
	my $self  = shift;
	my $op    = shift;
	my $value = shift;
	$self->pushOperand($self->Item('UOP')->new($self, $op, $value, $self->{ref}));
}

sub SimpleCharge {
	my $self = shift;
	my $top  = $self->pop;
	my $one  = $self->Item('Number')->new($self, 1, $self->{ref});
	$self->pushCharge($top->{name}, $one);
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
#  Don't allow evaluation except for numbers
#
sub eval {
	my $self = shift;
	return $self->Package('Real')->new($self->{tree}{value}) if $self->{tree}->class eq 'Number';
	$self->Error("Can't evaluate " . $self->{tree}->TYPE);
}

#
#  Get the molecular form for everything in the reaction
#
sub molecularForm {
	my $self = shift;
	return $self->new($self->{tree}->molecularForm);
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
#  don't really have to check anything.  (But if someone added
#  strings or constants, we would.)
#
sub typeMatch {
	my $self  = shift;
	my $other = shift;
	return 1;
}

######################################################################
#
#  Common functions to multiple classes
#
package context::Reaction::common;

#
#  Shorthand for creating parser items
#
sub ITEM {
	my $self = shift;
	return $self->Item(shift)->new($self->{equation}, @_);
}

#
#  Convert an item to a compound
#
sub COMPOUND {
	my $self = shift;
	return $self->ITEM('BOP', ' ', $self->ITEM('Number', 1), $self->copy);
}

#
#  Make a charge item from a number
#
sub CHARGE {
	my ($self, $n) = @_;
	return $self->ITEM('UOP', $n < 0 ? 'u-' : 'u+', $self->ITEM('Number', CORE::abs($n)));
}

#
#  Add a term into an item's data
#
sub combineData {
	my ($self, $other) = @_;
	return unless $other->{order};
	my ($order, $elements) = ($self->{order}, $self->{elements});
	for my $element (@{ $other->{order} }) {
		if (!$elements->{$element}) {
			push(@$order, $element);
			$elements->{$element} = 0;
		}
		$elements->{$element} += $other->{elements}{$element};
	}
	$self->{charge} += $other->{charge};
	$self->{factor} *= $other->{factor};
}

#
#  Molecular form is same as original
#
sub molecularForm { shift->copy }

#
#  Default is not a checmicla or sum
#
sub isChemical {0}
sub isSum      {0}

######################################################################
#
#  The replacement for the Parser:Number class
#
package context::Reaction::Number;
our @ISA = ('Parser::Number', 'context::Reaction::common');

#
#  Equivalent is equal
#
sub equivalent {
	my $self  = shift;
	my $other = shift;
	return 0 unless $other->class eq 'Number';
	return $self->eval == $other->eval;
}

sub class {'Number'}
sub TYPE  {'a Number'}

######################################################################
#
#  The replacement for Parser::Variable.  We hold the elements here.
#
package context::Reaction::Variable;
our @ISA = ('Parser::Variable', 'context::Reaction::common');

#
#  Save the element data
#
sub new {
	my $self = shift->SUPER::new(@_);
	if ($self->type ne 'State') {
		$self->{order}    = [ $self->{name} ];
		$self->{elements} = { $self->{name} => 1 };
		$self->{charge}   = 0;
		$self->{factor}   = 1;
	}
	return $self;
}

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
our @ISA = ('Parser::BOP', 'context::Reaction::common');

#
#  Binary operators produce chemicals (unless overridden, as in arrow)
#
sub isChemical {1}

sub eval { context::Reaction::eval(@_) }

#
#  Form molecular form by combining molecular forms of the operands
#
sub molecularForm {
	my $self = shift;
	$self        = bless {%$self}, ref($self);
	$self->{lop} = $self->{lop}->molecularForm;
	$self->{rop} = $self->{rop}->molecularForm;
	return $self;
}

#
#  Two nodes are equivalent if their operands are equivalent
#  and they have the same operator
#
sub equivalent {
	my $self  = shift;
	my $other = shift;
	return 0 unless $other->class eq 'BOP' && $self->{bop} eq $other->{bop};
	return $self->{lop}->equivalent($other->{lop}) && $self->{rop}->equivalent($other->{rop});
}

#
#  Check for equivalence using string representations of compounds
#
sub equivalentTo {
	my ($self, $other, $states) = @_;
	$other = $other->string;
	return $self->string eq $other || (!$states && $self->{hasState} && $self->{lop}->string eq $other);
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
	my ($lop, $rop) = ($self->{lop}, $self->{rop});
	$self->Error("The left-hand side of '-->' must be a (sum of) reactants, not %s", $lop->TYPE)
		unless $lop->isChemical || $lop->isSum;
	$self->Error("The right-hand side of '-->' must be a (sum of) products, not %s", $rop->TYPE)
		unless $rop->isChemical || $rop->isSum;
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
	my ($lop, $rop) = ($self->{lop}, $self->{rop});
	$self->Error("Can't combine %s and %s", $lop->TYPE, $rop->TYPE)
		unless ($lop->isChemical || $lop->isSum) && ($rop->isChemical || $rop->isSum);
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

#
#  It is a sum
#
sub isSum {1}

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
	$self->Error("Can't use a numeric prefix with %s", $rop->TYPE)
		unless ($lop->class eq 'Number' || $lop->isChemical) && $rop->isChemical;
	$self->Error("Compound already has a state") if $lop->{hasState} && $rop->type eq 'State';
	$self->Error("Can't combine %s with %s", $lop->TYPE,   $rop->TYPE)   if $lop->{hasState} && $rop->isChemical;
	$self->Error("Can't combine %s with %s", $lop->TYPE,   $rop->TYPE)   if $rop->{hasState} && $lop->isChemical;
	$self->Error("Can't combine %s with %s", $lop->{name}, $rop->TYPE)   if $lop->type eq 'Constant';
	$self->Error("Can't combine %s with %s", $lop->TYPE,   $rop->{name}) if $rop->type eq 'Constant';
	$self->Error("Can't combine %s with %s", $lop->TYPE,   $rop->TYPE)
		if $lop->class ne 'Number' && $rop->{hasNumber};
	$self->{type} = $COMPOUND->{type};

	$self->getCompound;
	$self->{hasState}  = 1 if $rop->type eq 'State';
	$self->{hasNumber} = 1 if $lop->type eq 'Number' || $lop->{hasNumber};

	if ($lop->{hasNumber} && $rop->type ne 'State') {
		my $n = $lop->{lop};
		$lop->{lop} = $lop->{rop};
		$lop->{rop} = $rop;
		delete $lop->{hasNumber};
		$rop = $self->{rop} = $lop;
		$lop = $self->{lop} = $n;
	}

	$self->combineAdjacentNumbers  if $self->context->flag('reduceConstants');
	$self->combineAdjacentElements if $self->context->flag('combineAdjacentElements');
}

#
#  Get the order/element/charge data for a compound
#
sub getCompound {
	my $self = shift;
	my ($lop, $rop) = ($self->{lop}, $self->{rop});
	$self->{order}    = [];
	$self->{elements} = {};
	$self->{charge}   = 0;
	$self->{factor}   = $lop->type eq 'Number' ? $lop->eval : 1;
	$self->combineData($lop);
	$self->combineData($rop);
}

#
#  Combine adjacent numbers (e.g., 2(3CO))
#
sub combineAdjacentNumbers {
	my $self = shift;
	my ($lop, $rop) = ($self->{lop}, $self->{rop});
	if ($rop->{hasNumber} && $lop->class eq 'Number') {
		if ($rop->{hasState}) {
			$lop->{value} *= $rop->{lop}{lop}{value};
			$rop->{lop} = $rop->{lop}{rop};
		} else {
			$lop->{value} *= $rop->{lop}{value};
			$rop = $self->{rop} = $rop->{rop};
		}
	}
}

#
#  Combine adjacent elements if they are the same
#
sub combineAdjacentElements {
	my $self = shift;
	my ($lop, $rop) = ($self->{lop}, $self->{rop});
	return unless $lop->{order} && $rop->{order} && scalar(@{ $rop->{order} }) == 1;
	my $name = $rop->{order}[0];
	if ($lop->type eq 'Compound') {
		$self->combineCompound($lop, $rop);
	} else {
		$self->combineSimple($lop, $rop);
	}
}

#
#  Combine elements when the left operand is a compound
#
sub combineCompound {
	my ($self, $lop, $rop) = @_;
	my $last = $lop->{rop};
	my $name = $rop->{order}[0];
	return unless $last->{order} && scalar(@{ $last->{order} }) == 1 && $last->{order}[0] eq $name;
	$self->{lop} = $lop->{lop};
	my $n = $self->ITEM('Number', $last->{elements}{$name} + $rop->{elements}{$name});
	$self->{rop} = $self->ITEM('BOP', '_', $self->ITEM('Variable', $name), $n);
	my $charge = $last->{charge} + $rop->{charge};
	$self->{rop} = $self->ITEM('BOP', '^', $self->{rop}, $self->CHARGE($charge)) if $charge;
}

#
#  Combine elements when the left is not a compound
#
sub combineSimple {
	my ($self, $lop, $rop) = @_;
	my $name = $rop->{order}[0];
	return unless scalar(@{ $lop->{order} }) == 1 && $lop->{order}[0] eq $name;
	my $n       = $self->ITEM('Number',   $lop->{elements}{$name} + $rop->{elements}{$name});
	my $element = $self->ITEM('Variable', $name);
	my $charge  = $lop->{charge} + $rop->{charge};
	if ($charge) {
		$self->mutate('^', $self->ITEM('BOP', '_', $element, $n), $self->CHARGE($charge));
	} else {
		$self->mutate('_', $element, $n);
	}
}

#
#  Mutate the BOP into a different one
#
sub mutate {
	my $self  = shift;
	my $other = $self->ITEM('BOP', @_);
	delete $self->{$_} for (keys %$self);
	$self->{$_} = $other->{$_} for (keys %$other);
	bless $self, ref($other);
}

#
#  Create the molecular form for a compound
#
sub molecularForm {
	my $self     = shift;
	my $elements = $self->{elements};
	my $state    = $self->{hasState}   ? $self->{rop}                           : undef;
	my $number   = $self->{factor} > 1 ? $self->ITEM('Number', $self->{factor}) : undef;
	my @order    = @{ $self->{order} };
	@order = main::lex_sort(@order) if !$self->context->flag('keepElementOrder');
	my $compound;
	for (@order) {
		my $term = $self->ITEM('Variable', $_);
		$term     = $self->ITEM('BOP', '_', $term, $self->ITEM('Number', $elements->{$_})) if $elements->{$_} > 1;
		$compound = $compound ? $self->ITEM('BOP', ' ', $compound, $term) : $term;
	}
	$compound = $self->ITEM('BOP', '^', $compound, $self->CHARGE($self->{charge})) if $self->{charge};
	$compound = $self->ITEM('BOP', ' ', $number,   $compound)                      if $number;
	$compound = $self->ITEM('BOP', ' ', $compound, $state->copy)                   if $state;
	return $compound;
}

#
#  Check for equivalence of two compounds
#    removing states if needed and student answers can be without them
#
sub equivalent {
	my $self  = shift;
	my $other = shift;
	if ($other->class eq 'List') {
		my $parens = $self->context->parens->get('(');
		my $list   = $self->ITEM('List', $self->{equation}, [$self], 1, $parens);
		return $list->equivalent($other);
	}
	return 0 unless $other->isChemical;
	$other = $other->COMPOUND unless $other->type eq 'Compound';
	my $states    = $self->context->flag('studentsMustUseStates');
	my $molecular = $self->context->flag('compareMolecular');
	my $both      = $self->context->flag('acceptMolecularForm');
	return $self->molecularForm->equivalentTo($other->molecularForm, $states) if $molecular;
	return $self->equivalentTo($other, $states) || ($both && $self->molecularForm->equivalentTo($other, $states));
}

#
#  No space in output for implied multiplication
#    and add parentheses for compounds that need it
#
sub string {
	my $self = shift;
	my ($l, $r) = ($self->{lop}->string, $self->{rop}->string);
	$l = '' if $l eq '1';
	$r = "($r)"
		if $l && $self->{rop}->type eq 'Compound' && ($self->{rop}{hasNumber} || $self->{lop}->class ne 'Number');
	return $l . $r;
}

sub TeX {
	my $self = shift;
	my ($l, $r) = ($self->{lop}->TeX, $self->{rop}->TeX);
	$l = '' if $l eq '1';
	$r = "($r)"
		if $l && $self->{rop}->type eq 'Compound' && ($self->{rop}{hasNumber} || $self->{lop}->class ne 'Number');
	return $l . $r;
}

#
#  Handle states separately
#
sub TYPE {
	my $self = shift;
	return $self->{rop}->TYPE eq 'a state'
		? $self->{lop}->TYPE . ' with state'
		: 'a compound' . ($self->{hasNumber} ? ' with number' : '');
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
		unless $lop->type =~ m/Element|Compound|Complex/ && !$lop->{hasState} && !$lop->{hasNumber};
	$self->Error("The right-hand side of '_' must be a number, not %s", $rop->TYPE)
		unless $rop->class eq 'Number';
	$self->{type} = $MOLECULE->{type};
	$self->getMolecule;
}

#
#  Get the order/elements/charge data for a molecule
#
sub getMolecule {
	my $self = shift;
	my $lop  = $self->{lop};
	my $n    = $self->{rop}->eval;
	$self->{order}    = [ @{ $lop->{order} } ];
	$self->{elements} = { %{ $lop->{elements} } };
	$self->{elements}{$_} *= $n for (keys %{ $self->{elements} });
	$self->{charge} = $n * $lop->{charge};
	$self->{factor} = $lop->{factor};
}

#
#  Use compound check
#
sub equivalent {
	my ($self, $other) = @_;
	return $self->COMPOUND->equivalent($other);
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
	$self->Error("The left-hand side of '^' must be an element, molecule, or compound, not %s", $lop->TYPE)
		unless $lop->type =~ m/Element|Molecule|Compound|Complex/ && !$lop->{hasState} && !$lop->{hasNumber};
	$self->Error("The right-hand side of '^' must be %s, not %s", context::Reaction::UOP->TYPE, $rop->TYPE)
		unless $rop->TYPE eq 'a charge';
	$self->{type} = $ION->{type};
	$self->getIon;
}

#
#  Get the order/elements/charge data for an ion
#
sub getIon {
	my $self = shift;
	my $lop  = $self->{lop};
	$self->{order}    = [ @{ $lop->{order} } ];
	$self->{elements} = { %{ $lop->{elements} } };
	$self->{charge}   = $self->{rop}->eval;
	$self->{factor}   = $lop->{factor};
}

#
#  Use compound check
#
sub equivalent {
	my ($self, $other) = @_;
	return $self->COMPOUND->equivalent($other);
}

#
#  Create proper TeX output
#
sub TeX {
	my $self = shift;
	my $left = $self->{lop}->TeX;
	return $left . '^{' . $self->{rop}->TeX . '}';
}

#
#  Create proper text output
#
sub string {
	my $self  = shift;
	my $left  = $self->{lop}->string;
	my $right = $self->{rop}->string;
	$right = "($right)" unless $right eq '-' || $right eq '+';
	return "$left^$right";
}

sub TYPE {'an ion'}

######################################################################
#
#  General unary operator (minus and plus are subclasses of this).
#
package context::Reaction::UOP;
our @ISA = ('Parser::UOP', 'context::Reaction::common');

sub _check {
	my $self = shift;
	$self->{type} = $Value::Type{number};
	return if ($self->checkNumber);
	my $name = $self->{uop};
	$name =~ s/^[up]//;
	$self->Error("Can't use unary '%s' with %s", $name, $self->{op}->TYPE);
}

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
#  Don't allow reduction of UOP plus (or minus)
#
sub isNeg {1}

#
#  Always put signs on the right
#
sub string {
	my $self    = shift;
	my $uop     = $self->{def};
	my $op      = $uop->{string};
	my $isUnity = $self->context->flags->get('showUnity');
	my $mag     = $self->{op}->string($uop->{precedence});    #magnitude
	$mag = '' if ($mag eq '1' && !$isUnity);
	return $mag . $op;
}

#
#  Always put signs on the right
#
sub TeX {
	my $self    = shift;
	my $uop     = $self->{def};
	my $op      = (defined($uop->{TeX}) ? $uop->{TeX} : $uop->{string});
	my $mag     = $self->{op}->TeX($uop->{precedence});
	my $isUnity = $self->context->flags->get('showUnity');
	$mag = '' if ($mag eq '1' && !$isUnity);
	return $mag . $op;
}

sub TYPE {'a charge'}

######################################################################
#
#  Negative numbers (for ion exponents)
#
package context::Reaction::UOP::minus;
our @ISA = ('context::Reaction::UOP');

sub eval { -(shift->{op}{value}) }

######################################################################
#
#  Positive numbers (for ion exponents)
#
package context::Reaction::UOP::plus;
our @ISA = ('context::Reaction::UOP');

sub eval { shift->{op}{value} }

######################################################################
#
#  Implements sums of compounds as a list
#
package context::Reaction::List::List;
our @ISA = ('Parser::List::List', 'context::Reaction::common');

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
#  to include them (otherwise the hash names will include the states).
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

#
#  Get the molecular form of each item in the list
#
sub molecularForm {
	my $self   = shift;
	my $coords = [ map { $_->molecularForm } @{ $self->{coords} } ];
	my $paren  = $self->context->parens->get('(');
	return $self->new($self->{equation}, $coords, 0, $paren);
}

sub eval { context::Reaction::eval(@_) }

sub isSum {1}

sub TYPE {'a sum of compounds'}

######################################################################
#
#  Implements complexes as a list
#
package context::Reaction::List::Complex;
our @ISA = ('Parser::List::List', 'context::Reaction::common');

sub _check {
	my $self = shift;
	$self->Error("A complex can't contain %s", context::Reaction::List::List->TYPE)
		if $self->{type}{length} != 1;
	my $arg = $self->{coords}[0];
	$self->Error("The contents of a complex must be an element, molecule, ion, or compound, not %s", $arg->TYPE)
		unless $arg->type =~ /Element|Molecule|Ion|Compound/ && !$arg->{hasState};
	$self->{type} = $COMPLEX->{type};
	$self->getComplex;
}

sub getComplex {
	my $self = shift;
	$self->{order}    = [];
	$self->{elements} = {};
	$self->{charge}   = 0;
	$self->{factor}   = 1;
	$self->combineData($self->{coords}[0]);
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

#
#  Get the molecular form of each item in the list
#
sub molecularForm {
	my $self = shift;
	return $self->{coords}[0]->molecularForm;
}

sub eval { context::Reaction::eval(@_) }

sub isChemical {1}

sub TYPE {'a complex'}

######################################################################

1;
