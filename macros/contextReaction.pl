=head1 NAME

contextReaction.pl - Implements a MathObject class for checmical reactions.

=head1 DESCRIPTION

This file implements a Context in which checmical reactions can be
specified and compared.  Reactions can be composed of sums of integer
multiples of elements (possibly with subscripts), separated by a right
arrow (indicated by "-->").  Helpful error messages are given when a
reaction is not of the correct form.  Sums of compounds can be given
in any order, but the elements within a compound must be in the order
given by the correct answer; e.g., if the correct answer specifies
CO_2, then O_2C would be marked incorrect.

To use the context include

	loadMacros("contextReaction.pl");
	Context("Reaction");

at the top of your PG file, then create Formula() objects for your
reactions.  For example:

	$R = Formula("4P + 5O_2 --> 2P_2O_5");

Ions can be specified using ^ to produce superscripts, as in Na^+1 or
Na^{+1}.  Note that the charge must be listed with prefix notation
(+1), not postfix notation (1+), and that a number is required (so you
can't use just Na^+).

States can be appended to compounds, as in AgCl(s).  So you can
make reactions like the following:

        Ag^{+1}(aq) + Cl^{-1}(aq) --> AgCl(s)

Note that a state can be given by itself, e.g., (l), so you can ask
for a student to supply just a state.

Reactions know how to create their own TeX versions (via $R->TeX), and
know how to check student answers (via $R->cmp), just like any other
MathObject.

The Reaction Context also allows you to create parts of reactions.
E.g., you could create

	$products = Formula("4CO_2 + 6H_2O");

which you could use in a problem as follows:

	loadMacros("contextReaction.pl");
	Context("Reaction");
	
	$reactants = Formula("2C_2H_6 + 7O_2");
	$products  = Formula("4CO_2 + 6H_2O");
	
	Context()->texStrings;
	BEGIN_TEXT
	\($reactants \longrightarrow\) \{ans_rule(30)\}.
	END_TEXT
	Context()->normalStrings;
	
	ANS($products->cmp);

Note that sums and products are not simplified in any way, so that
Formula("O + O") and Formula("2O") and Formula("O_2") are all
different and unequal in this context.

All the elements of the periodic table are available within the
Reaction Context, as are the states (aq), (s), (l), (g), and (ppt).
If you need additional terms, like "Heat" for example, you can add
them as variables:

	Context()->variables->add(Heat => $context::Reaction::CONSTANT);

Then you can make formulas that include Heat as a term.  These
"constants" are not allowed to have coefficients or sub- or
superscripts, and can not be combined with compounds except by
addition.  If you want a term that can be combined in those ways, use
$context::Reaction::ELEMENT instead, as in

	Context()->variables->add(e => $context::Reaction::ELEMENT);

to allow "e" for electrons, for example.

If you need to add more states, use $context::Reaction::STATE, as in

	Context()->variables->add('(x)' => $context::Reaction::STATE);

to allow a state of (x) for a compound.

=cut

######################################################################

sub _contextReaction_init {context::Reaction::Init()}

######################################################################
#
#  The main MathObject class for reactions
#
package context::Reaction;
our @ISA = ('Value::Formula');

#
#  Some type declarations for the various classes
#
our $ELEMENT  = {isValue => 1, type => Value::Type("Element",1)};
our $MOLECULE = {isValue => 1, type => Value::Type("Molecule",1)};
our $ION      = {isValue => 1, type => Value::Type("Ion",1)};
our $COMPOUND = {isValue => 1, type => Value::Type("Compound",1)};
our $REACTION = {isValue => 1, type => Value::Type("Reaction",1)};
our $CONSTANT = {isValue => 1, type => Value::Type("Constant",1)};
our $STATE    = {isValue => 1, type => Value::Type("State",1)};

#
#  Set up the context and Reaction() constructor
#
sub Init {
  my $context = $main::context{Reaction} = Parser::Context->getCopy("Numeric");
  $context->{name} = "Reaction";
  $context->functions->clear();
  $context->strings->clear();
  $context->constants->clear();
  $context->lists->clear();
  $context->lists->add(
   'List' => {class =>'context::Reaction::List::List', open => '', close => '', separator => ' + '},
  );
  $context->parens->clear();
  $context->parens->add(
   '(' => {close => ')', type => 'List', formList => 1, removable => 1},
   '{' => {close => '}', type => 'List', removable => 1},
  );
  $context->operators->clear();
  $context->operators->set(
   '-->' => {precedence => 1, associativity => 'left', type => 'bin', string => ' --> ',
           class => 'context::Reaction::BOP::arrow', TeX => " \\longrightarrow "},

   '+' => {precedence => 2, associativity => 'left', type => 'both', string => ' + ',
           class => 'context::Reaction::BOP::add', isComma => 1},

   ' ' => {precedence => 3, associativity => 'left', type => 'bin', string => ' ',
           class => 'context::Reaction::BOP::multiply', hidden => 1},

   '_' => {precedence => 4, associativity => 'left', type => 'bin', string => '_',
           class => 'context::Reaction::BOP::underscore'},

   '^' => {precedence => 4, associativity => 'left', type => 'bin', string => '^',
           class => 'context::Reaction::BOP::superscript'},

   '-' => {precedence => 5, associativity => 'left', type => 'both', string => '-',
           class => 'Parser::BOP::undefined'},
   'u-'=> {precedence => 6, associativity => 'left', type => 'unary', string => '-',
           class => 'context::Reaction::UOP::minus', hidden => 1},
   'u+'=> {precedence => 6, associativity => 'left', type => 'unary', string => '+',
           class => 'context::Reaction::UOP::plus', hidden => 1},
  );
  $context->variables->{namePattern} = qr/\(?[a-zA-Z][a-zA-Z0-9]*\)?/;
  $context->variables->are(
    map {$_ => $ELEMENT} (
      "H",                                                                                   "He",
      "Li","Be",                                                    "B", "C", "N", "O", "F", "Ne",
      "Na","Mg",                                                    "Al","Si","P", "S", "Cl","Ar",
      "K", "Ca",  "Sc","Ti","V", "Cr","Mn","Fe","Co","Ni","Cu","Zn","Ga","Ge","As","Se","Br","Kr",
      "Rb","Sr",  "Y", "Zr","Nb","Mo","Tc","Ru","Rh","Pd","Ag","Cd","In","Sn","Sb","Te","I", "Xe",
      "Cs","Ba",  "Lu","Hf","Ta","W", "Re","Os","Ir","Pt","Au","Hg","Ti","Pb","Bi","Po","At","Rn",
      "Fr","Ra",  "Lr","Rf","Db","Sg","Bh","Hs","Mt","Ds","Rg","Cn","Nh","Fl","Mc","Lv","Ts","Og",

                  "La","Ce","Pr","Nd","Pm","Sm","Eu","Gd","Tb","Dy","Ho","Er","Tm","Yb",
                  "Ac","Th","Pa","U", "Np","Pu","Am","Cm","Bk","Cf","Es","Fm","Md","No",
    )
  );
  $context->variables->add(
    map {$_ => $STATE} (
      "(aq)", "(s)", "(l)", "(g)", "(ppt)",
    )
  );
  $context->reductions->clear();
  $context->flags->set(reduceConstants => 0);
  $context->{parser}{Number} = "context::Reaction::Number";
  $context->{parser}{Variable} = "context::Reaction::Variable";
  $context->{parser}{Formula} = "context::Reaction";
  $context->{value}{Reaction} = "context::Reaction";
  $context->{value}{Element} = "context::Reaction::Variable";
  $context->{value}{Constant} = "context::Reaction::Variable";
  $context->{value}{State} = "context::Reaction::Variable";
  Parser::Number::NoDecimals($context);

  main::PG_restricted_eval('sub Reaction {Value->Package("Formula")->new(@_)};');
}

#
#  Compare by checking of the trees are equivalent
#
sub compare {
  my ($l,$r) = @_; my $self = $l;
  my $context = $self->context;
  $r = $context->Package("Formula")->new($context,$r) unless Value::isFormula($r);
  return ($l->{tree}->equivalent($r->{tree}) ? 0 : 1);
}

#
#  Don't allow evaluation
#
sub eval {
  my $self = shift;
  $self->Error("Can't evaluate ".$self->TYPE);
}

#
#  Provide a useful name
#
sub TYPE {'a chemical reaction'}
sub cmp_class {'a Chemical Reaction'}

#
#  Set up the answer checker.  Avoid the list checker in
#    Value::Formula::cmp_equal (for when the answer is a
#    sum of compounds) and provide a postprocessor to
#    give warnings when a reaction is compared to a
#    student answer that isn't a reaction.
#
sub cmp_defaults {(showTypeWarnings => 1)}
sub cmp_equal {Value::cmp_equal(@_)};
sub cmp_postprocess {
  my $self = shift; my $ans = shift;
  return unless $self->{tree}->type eq 'Reaction';
  $self->cmp_Error($ans,"Your answer doesn't seem to be a reaction\n(it should contain a reaction arrow '-->')")
    if $ans->{showTypeWarnings} && $ans->{student_value}{tree}->type ne 'Reaction';
}

#
#  Since the context only allows things that are comparable, we
#  don't really have to check anything.  (But if somone added
#  strings or constants, we would.)
#
sub typeMatch {
  my $self = shift; my $other = shift;
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
  my $self = shift; my $other = shift;
  return 0 unless $other->class eq 'Number';
  return $self->eval == $other->eval;
}

sub isChemical {0}

sub class {'Number'}
sub TYPE {'a Number'}

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
  my $self = shift; my $other = shift;
  return 0 unless $other->class eq 'Variable';
  return $self->{name} eq $other->{name};
}

sub eval {context::Reaction::eval(@_)}

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
  return ($self->type eq 'Constant' || $self->type eq 'State' ? 'a state' : 'an element');
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

sub eval {context::Reaction::eval(@_)}

#
#  Two nodes are equivalent if their operands are equivalent
#  and they have the same operator
#
sub equivalent {
  my $self = shift; my $other = shift;
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
  $self->Error("The left-hand side of '-->' must be a (sum of) reactants, not %s",
               $self->{lop}->TYPE) unless $self->{lop}->isChemical;
  $self->Error("The right-hand side of '-->' must be a (sum of) products, not %s",
               $self->{rop}->TYPE) unless $self->{rop}->isChemical;
  $self->{type} = $REACTION->{type};
}

sub TYPE {'a reaction'}

######################################################################
#
#  Implements addition, which forms a list of operands, so acts like
#  the Parser::BOP::comma operator
#
package context::Reaction::BOP::add;
our @ISA = ('Parser::BOP::comma','context::Reaction::BOP');

#
#  Check that the operands are OK
#
sub _check {
  my $self = shift;
  $self->Error("Can't add %s and %s",$self->{lop}->TYPE,$self->{rop}->TYPE)
     unless $self->{lop}->isChemical && $self->{rop}->isChemical;
  $self->SUPER::_check(@_);
}

#
#  Two are equivalent if they are equivalent in either order.
#  (never really gets used, since these result in the creation
#  of a list rather than an "add" node in the final tree.
#
sub equivalent {
  my $self = shift; my $other = shift;
  return 0 unless substr($other->class,0,3) eq 'BOP';
  return $self->SUPER::equivalent($other) ||
         ($self->{lop}->equivalent($other->{rop}) && $self->{rop}->equivalent($other->{rop}));
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
  $self->Error("Can't combine %s and %s",$self->{lop}->TYPE,$self->{rop}->TYPE)
    unless ($self->{lop}->class eq 'Number' || $self->{lop}->isChemical) &&
            $self->{rop}->isChemical;
  $self->Error("Compound already has a state")
    if $self->{lop}{hasState} && $self->{rop}->type eq 'State';
  $self->Error("Can't combine %s with %s",$self->{lop}{name},$self->{rop}->TYPE)
    if $self->{lop}->type eq 'Constant';
  $self->Error("Can't combine %s with %s",$self->{lop}->TYPE,$self->{rop}{name})
    if $self->{rop}->type eq 'Constant';
  $self->{type} = $COMPOUND->{type};
  $self->{hasState} = 1 if $self->{rop}->type eq 'State';
}

#
#  No space in output for implied multiplication
#
sub string {
  my $self = shift;
  return $self->{lop}->string.$self->{rop}->string;
}
sub TeX {
  my $self = shift;
  return $self->{lop}->TeX.$self->{rop}->TeX;
}

sub TYPE {'a compound'}

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
  $self->Error("The left-hand side of '_' must be an element or compound, not %s",$self->{lop}->TYPE)
    unless $self->{lop}->type eq 'Element' || $self->{lop}->type eq 'Compound';
  $self->Error("The right-hand side of '_' must be a number, not %s",$self->{rop}->TYPE)
    unless $self->{rop}->class eq 'Number';
  $self->{type} = $MOLECULE->{type};
}

#
#  Create proper TeX output
#
sub TeX {
  my $self = shift;
  my $left = $self->{lop}->TeX;
  $left = "($left)" if $self->{lop}->type eq 'Compound';
  return $left."_{".$self->{rop}->TeX."}";
}

#
#  Create proper text output
#
sub string {
  my $self = shift;
  my $left = $self->{lop}->string;
  $left = "($left)" if $self->{lop}->type eq 'Compound';
  return $left."_".$self->{rop}->string;
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
  $self->Error("The left-hand side of '^' must be an element or molecule, not %s",$self->{lop}->TYPE)
    unless $self->{lop}->type eq 'Element' || $self->{lop}->type eq 'Molecule';
  $self->Error("The right-hand side of '^' must be a signed number, not %s",$self->{rop}->TYPE)
    unless $self->{rop}->class eq 'UOP';
  $self->{type} = $ION->{type};
}

#
#  Create proper TeX output
#
sub TeX {
  my $self = shift;
  my $left = $self->{lop}->TeX;
  return $left."^{".$self->{rop}->TeX."}";
}

#
#  Create proper text output
#
sub string {
  my $self = shift;
  my $left = $self->{lop}->string;
  return $left."^".$self->{rop}->string;
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
  return if ($self->checkNumber);
  $self->{type} = $Value::Type{number};
}

#
#  Unary operators produce numbers
#
sub isChemical {0}

sub eval {context::Reaction::eval(@_)}

#
#  Two nodes are equivalent if their operands are equivalent
#  and they have the same operator
#
sub equivalent {
  my $self = shift; my $other = shift;
  return 0 unless $other->class eq 'UOP';
  return 0 unless $self->{uop} eq $other->{uop};
  return $self->{op}->equivalent($other->{op});
}

sub TYPE {'a signed number'};

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
#  (we check by stringifying them and sorting, then compare results)
#
sub equivalent {
  my $self = shift; my $other = shift;
  return 0 unless $self->length == $other->length;
  my @left = main::lex_sort(map {$_->string} @{$self->{coords}});
  my @right = main::lex_sort(map {$_->string} @{$other->{coords}});
  return join(',',@left) eq join(',',@right);
}

#
#  Use "+" between entries in the list (with no parens)
#
sub TeX {
  my $self = shift; my $precedence = shift; my @coords = ();
  foreach my $x (@{$self->{coords}}) {push(@coords,$x->TeX)}
  return join(' + ',@coords);
}

sub eval {context::Reaction::eval(@_)}

sub isChemical {1}

sub TYPE {'a sum of compounds'}

######################################################################

1;
