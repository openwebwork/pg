##########################################################
#
#  Implements a context in which the "step" and "fact"
#  functions are defined.  These were defined in the old
#  AlgParser, but are not in the Parser's standard
#  Numeric context.
#
#  Warning:  since step and fact already are defined in
#  PGauxiliarymacros.pl we can't redefine them here, so you
#  can't use step(formula) or fact(formula) to automatically
#  generate Formula objects, as you can with all the other
#  functions.  Since this context is for compatibility with
#  old problems that didn't know about Formula objects
#  anyway, that should not be a problem.
#

package Parser::Legacy::Numeric;
our @ISA = qw(Parser::Function::numeric);
sub step {shift; do_step(shift)}; sub do_step {Value::pgCall('step',@_)}
sub fact {shift; do_fact(shift)}; sub do_fact {Value::pgCall('fact',@_)}

my $context = $Parser::Context::Default::context{Numeric}->copy;
$Parser::Context::Default::context{LegacyNumeric} = $context;
$context->functions->add(
  step => {class => 'Parser::Legacy::Numeric', perl => 'Parser::Legacy::Numeric::do_step'},
  fact => {class => 'Parser::Legacy::Numeric', perl => 'Parser::Legacy::Numeric::do_fact'},
);
$context->{name} = "LegacyNumeric";

1;
