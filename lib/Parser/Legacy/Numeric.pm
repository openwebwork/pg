##########################################################
#
#  Implements a context in which the "step" function
#  is defined.  This was defined in the old AlgParser,
#  but not in the Parser's standard Numeric context.
#
#  Warning:  since step is already defined in PGauxiliarymacros.pl
#  we can't redefine it here, so you can't use step(formula) to
#  automatically generate Formula objects, as you can with
#  all the other functions.

package Parser::Legacy::Numeric;
our @ISA = qw(Parser::Function::numeric);
sub step {shift; main::step((shift)->value)}

my $context = $Parser::Context::Default::context{Numeric}->copy;
$Parser::Context::Default::context{LegacyNumeric} = $context;
$context->functions->add(step => {class => 'Parser::Legacy::Numeric'});

