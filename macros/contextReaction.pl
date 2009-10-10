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
Reaction Context.  If you need additional terms, like "Heat" for
example, you can add them as variables:

	Context()->variables->add(Heat => $context::Reaction::CONSTANT);

Then you can make formulas that include Heat as a term.  These
"constants" are not allowed to have coefficients or subscripts, and
can not be combined with compounds except by addition.  If you want a
term that can be combined in those ways, use
$context::Reaction::ELEMENT instead.

=cut

sub _contextReaction_init {context::Reaction::Init()}

######################################################################

package context::Reaction;
our @ISA = ('Value::Formula');

our $ELEMENT  = {isValue => 1, type => Value::Type("Element",1)};
our $MOLECULE = {isValue => 1, type => Value::Type("Molecule",1)};
our $COMPOUND = {isValue => 1, type => Value::Type("Compound",1)};
our $REACTION = {isValue => 1, type => Value::Type("Reaction",1)};
our $CONSTANT = {isValue => 1, type => Value::Type("Constant",1)};

sub Init {
  my $context = $main::context{Reaction} = Parser::Context->getCopy("Numeric");
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

   '+' => {precedence => 2, associativity => 'left', type => 'bin', string => ' + ',
           class => 'context::Reaction::BOP::add', isComma => 1},

   ' ' => {precedence => 3, associativity => 'left', type => 'bin', string => ' ',
           class => 'context::Reaction::BOP::multiply', hidden => 1},

   '_' => {precedence => 4, associativity => 'left', type => 'bin', string => '_',
           class => 'context::Reaction::BOP::underscore'},

   '-' => {precedence => 5, associativity => 'left', type => 'both', string => ' - ',
           class => 'Parser::BOP::undefined'},
   'u-'=> {precedence => 6, associativity => 'left', type => 'unary', string => '-',
           class => 'Parser::UOP::undefined', hidden => 1},
  );
  $context->variables->are(
    map {$_ => $ELEMENT} (
      "H",                                                                                   "He",
      "Li","Be",                                                    "B", "C", "N", "O", "F", "Ne",
      "Na","Mg",                                                    "Al","Si","P", "S", "Cl","Ar",
      "K", "Ca",  "Sc","Ti","V", "Cr","Mn","Fe","Co","Ni","Cu","Zn","Ga","Ge","As","Se","Br","Kr",
      "Rb","Sr",  "Y", "Zr","Nb","Mo","Tc","Ru","Rh","Pd","Ag","Cd","In","Sn","Sb","Te","I", "Xe",
      "Cs","Ba",  "Lu","Hf","Ta","W", "Re","Os","Ir","Pt","Au","Hg","Ti","Pb"."Bi","Po","At","Rn",
      "Fr","Ra",  "Lr","Rf","Db","Sg","Bh","Hs","Mt","Ds","Rg","Cn","Uut","Uuq","Uup","Uuh","Uus","Uuo",

                  "La","Ce","Pr","Nd","Pm","Sm","Eu","Gd","Tb","Dy","Ho","Er","Tm","Yb",
                  "Ac","Th","Pa","U", "Np","Pu","Am","Cm","Bk","Cf","Es","Fm","Md","No",
    )
  );
  $context->{parser}{Number} = "context::Reaction::Number";
  $context->{parser}{Variable} = "context::Reaction::Variable";
  $context->{parser}{List} = "context::Reaction::List";
  $context->{parser}{Formula} = "context::Reaction";
  $context->{value}{Reaction} = "context::Reaction";
  $context->{value}{Element} = "context::Reaction::Variable";
  $context->{value}{Constant} = "context::Reaction::Variable";
  Parser::Number::NoDecimals($context);

  main::PG_restricted_eval('sub Reaction {Value->Package("Formula")->new(@_)};');
}

sub compare {
  my ($l,$r) = @_; my $self = $l;
  my $context = $self->context;
  $r = $context->Package("Formula")->new($context,$r) unless Value::isFormula($r);
  return ($l->{tree}->equivalent($r->{tree}) ? 0 : 1);
}

sub eval {
  my $self = shift;
  $self->Error("Can't evaluate ".$self->TYPE);
}

sub TYPE {'a chemical reaction'}
sub cmp_class {'a Chemical Reaction'}

sub cmp_defaults {(showTypeWarnings => 1)}

sub cmp_equal {Value::cmp_equal(@_)};

sub cmp_postprocess {
  my $self = shift; my $ans = shift;
  return unless $self->{tree}->type eq 'Reaction';
  $self->cmp_Error($ans,"Your answer doesn't seem to be a reaction (it should contain a reaction arrow '-->')")
    unless $ans->{student_value}{tree}->type eq 'Reaction';
}

sub typeMatch {
  my $self = shift; my $other = shift;
  return 1;
}

######################################################################

package context::Reaction::Number;
our @ISA = ('Parser::Number');

sub equivalent {
  my $self = shift; my $other = shift;
  return 0 unless $other->class eq 'Number';
  return $self->eval == $other->eval;
}

sub isChemical {0}

sub class {'Number'}
sub TYPE {'a Number'}

######################################################################

package context::Reaction::Variable;
our @ISA = ('Parser::Variable');

sub equivalent {
  my $self = shift; my $other = shift;
  return 0 unless $other->class eq 'Variable';
  return $self->{name} eq $other->{name};
}

sub eval {context::Reaction::eval(@_)}

sub isChemical {1}

sub TeX {
  my $self = shift;
  return "{\\rm $self->{name}}";
}

sub class {'Variable'}

sub TYPE {
  my $self = shift;
  return ($self->type eq 'Constant'? "'$self->{name}'" : 'an element');
}

######################################################################

package context::Reaction::BOP;
our @ISA = ('Parser::BOP');

sub isChemical {1}

sub eval {context::Reaction::eval(@_)}

sub equivalent {
  my $self = shift; my $other = shift;
  return 0 unless substr($other->class,0,3) eq 'BOP';
  return $self->{lop}->equivalent($other->{lop}) && $self->{rop}->equivalent($other->{rop});
}

sub class {
  my $self = shift;
  my $class = ref($self);
  $class =~ s/.*::BOP::/BOP::/;
  return $class;
}

######################################################################

package context::Reaction::BOP::arrow;
our @ISA = ('context::Reaction::BOP');

sub isChemical {0}

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

package context::Reaction::BOP::add;
our @ISA = ('Parser::BOP::comma','context::Reaction::BOP');

sub _check {
  my $self = shift;
  $self->Error("Can't add %s and %s",$self->{lop}->TYPE,$self->{rop}->TYPE)
     unless $self->{lop}->isChemical && $self->{rop}->isChemical;
  $self->SUPER::_check(@_);
}

sub equivalent {
  my $self = shift; my $other = shift;
  return 0 unless substr($other->class,0,3) eq 'BOP';
  return $self->SUPER::equivalent($other) ||
         ($self->{lop}->equivalent($other->{rop}) && $self->{rop}->equivalent($other->{rop}));
}

sub TYPE {'a sum of Compounds'}

######################################################################

package context::Reaction::BOP::multiply;
our @ISA = ('context::Reaction::BOP');

sub _check {
  my $self = shift;
  $self->Error("Can't combine %s and %s",$self->{lop}->TYPE,$self->{rop}->TYPE)
    unless ($self->{lop}->class eq 'Number' || $self->{lop}->isChemical) &&
            $self->{rop}->isChemical;
  $self->Error("Can't combine %s with %s",$self->{lop}{name},$self->{rop}->TYPE)
    if $self->{lop}->type eq 'Constant';
  $self->Error("Can't combine %s with %s",$self->{lop}->TYPE,$self->{rop}{name})
    if $self->{rop}->type eq 'Constant';
  $self->{type} = $COMPOUND->{type};
}

#
#  No space for implied multiplication
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

package context::Reaction::BOP::underscore;
our @ISA = ('context::Reaction::BOP');

sub _check {
  my $self = shift;
  $self->Error("The left-hand side of '_' must be an element, not %s",$self->{lop}->TYPE)
    unless $self->{lop}->type eq 'Element';
  $self->Error("The right-hand side of '_' must be a number, not %s",$self->{rop}->TYPE)
    unless $self->{rop}->class eq 'Number';
  $self->{type} = $MOLECULE->{type};
}

sub TeX {
  my $self = shift;
  return $self->{lop}->TeX."_{".$self->{rop}->TeX."}";
}

sub TYPE {'a molecule'}

######################################################################

package context::Reaction::List;
our @ISA = ('Parser::List::List');

sub cmp_compare {
  my $self = shift; my $other = shift; my $ans = shift;
  return $self->{tree}->equivalent($other->{tree});
}

######################################################################

package context::Reaction::List::List;
our @ISA = ('Parser::List::List');

sub equivalent {
  my $self = shift; my $other = shift;
  return 0 unless $self->length == $other->length;
  my @left = main::lex_sort(map {$_->string} @{$self->{coords}});
  my @right = main::lex_sort(map {$_->string} @{$other->{coords}});
  return join(',',@left) eq join(',',@right);
}

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
