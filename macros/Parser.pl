###########################################################################
##
##  Set up the functions needed by the Parser.
##

if (!$Parser::installed) {
  die "\n************************************************************\n" .
        "* This problem requires the Parser.pm package, which doesn't\n".
        "* seem to be installed.  Please contact your WeBWorK system\n".
        "* administrator and ask him or her to install it first.\n".
        "************************************************************\n\n"
}
if (!$Value::installed) {
  die "\n************************************************************\n" .
        "* This problem requires the Value.pm package, which doesn't\n".
        "* seem to be installed.  Please contact your WeBWorK system\n".
        "* administrator and ask him or her to install it first.\n".
        "************************************************************\n\n"
}

loadMacros("Value.pl");
loadMacros("PGcommonFunctions.pl");

#
#  The main way to get a formula
#
sub Formula {Value::Formula->new(@_)}

#
#  Parse a formula and evaluate it
#
sub Compute {
  my $string = shift;
  my $formula = Formula($string)->eval(@_);
  $formula->{correct_ans} = $string;
  return $formula;
}  

#
#  Deal with contexts
#
sub Context {Parser::Context->current(\%context,@_)}
%context = ();  # locally defined contexts, including 'current' context
Context();  # Initialize context (for persistent mod_perl)

###########################################################################
#
# stubs for trigonometric functions
#

package Ignore;  ## let PGauxiliaryFunctions.pl do these

#sub sin {Parser::Function->call('sin',@_)}    # Let overload handle it
#sub cos {Parser::Function->call('cos',@_)}    # Let overload handle it
sub tan {Parser::Function->call('tan',@_)}
sub sec {Parser::Function->call('sec',@_)}
sub csc {Parser::Function->call('csc',@_)}
sub cot {Parser::Function->call('cot',@_)}

sub asin {Parser::Function->call('asin',@_)}
sub acos {Parser::Function->call('acos',@_)}
sub atan {Parser::Function->call('atan',@_)}
sub asec {Parser::Function->call('asec',@_)}
sub acsc {Parser::Function->call('acsc',@_)}
sub acot {Parser::Function->call('acot',@_)}

sub arcsin {Parser::Function->call('asin',@_)}
sub arccos {Parser::Function->call('acos',@_)}
sub arctan {Parser::Function->call('atan',@_)}
sub arcsec {Parser::Function->call('asec',@_)}
sub arccsc {Parser::Function->call('acsc',@_)}
sub arccot {Parser::Function->call('acot',@_)}

###########################################################################
#
# stubs for hyperbolic functions
#

sub sinh {Parser::Function->call('sinh',@_)}
sub cosh {Parser::Function->call('cosh',@_)}
sub tanh {Parser::Function->call('tanh',@_)}
sub sech {Parser::Function->call('sech',@_)}
sub csch {Parser::Function->call('csch',@_)}
sub coth {Parser::Function->call('coth',@_)}

sub asinh {Parser::Function->call('asinh',@_)}
sub acosh {Parser::Function->call('acosh',@_)}
sub atanh {Parser::Function->call('atanh',@_)}
sub asech {Parser::Function->call('asech',@_)}
sub acsch {Parser::Function->call('acsch',@_)}
sub acoth {Parser::Function->call('acoth',@_)}

sub arcsinh {Parser::Function->call('asinh',@_)}
sub arccosh {Parser::Function->call('acosh',@_)}
sub arctanh {Parser::Function->call('atanh',@_)}
sub arcsech {Parser::Function->call('asech',@_)}
sub arccsch {Parser::Function->call('acsch',@_)}
sub arccoth {Parser::Function->call('acoth',@_)}

###########################################################################
#
# stubs for numeric functions
#

#sub log   {Parser::Function->call('log',@_)}    # Let overload handle it
sub log10 {Parser::Function->call('log10',@_)}
#sub exp   {Parser::Function->call('exp',@_)}    # Let overload handle it
#sub sqrt  {Parser::Function->call('sqrt',@_)}    # Let overload handle it
#sub abs   {Parser::Function->call('abs',@_)}    # Let overload handle it
sub int   {Parser::Function->call('int',@_)}
sub sgn   {Parser::Function->call('sgn',@_)}

sub ln     {Parser::Function->call('log',@_)}
sub logten {Parser::Function->call('log10',@_)}

package main;  ##  back to main

sub log10 {Parser::Function->call('log10',@_)}
sub Factorial {Parser::UOP::factorial->call(@_)}

###########################################################################
#
# stubs for special functions
#

#sub atan2 {Parser::Function->call('atan2',@_)}    # Let overload handle it

###########################################################################
#
# stubs for numeric functions
#

sub arg  {Parser::Function->call('arg',@_)}
sub mod  {Parser::Function->call('mod',@_)}
sub Re   {Parser::Function->call('Re',@_)}
sub Im   {Parser::Function->call('Im',@_)}
sub conj {Parser::Function->call('conj',@_)}

###########################################################################
#
# stubs for vector functions
#

sub norm {Parser::Function->call('norm',@_)}
sub unit {Parser::Function->call('unit',@_)}

#
#  These need to be in dangerousMacros.pl for some reason
#
#sub i () {Compute('i')}
#sub j () {Compute('j')}
#sub k () {Compute('k')}

###########################################################################

$_parser_loaded = 1;  #  use this to tell if Parser.pl is loaded

sub _Parser_init {}; # don't let loadMacros load it again

###########################################################################

1;
