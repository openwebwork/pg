##############################################
#
#  Implements functions that are common to
#  the new Parser.pm and the old PGauxiliaryFunctions.pl
#

sub _PGcommonFunctions_init {}

#
#  Make these interact nicely with Parser.pm
#
package CommonFunction;

#
#  Either call Parser (if it has been loaded) or
#  the functions below.  (If it's ever the case
#  that both the Parser and PGauxiliaryFunctions.pl are
#  both preloaded, then there will be no need for
#  this, as you can always use the Parser versions.
#  We only need this because Parser might not be loaded.)
#

sub Call {
  my $self = shift;
  my $fn = shift;
  if ($main::_parser_loaded) {return Parser::Function->call($fn,@_)}
  return $self->$fn(@_);
}

sub log {CORE::log($_[1])}
sub ln {CORE::log($_[1])}
sub logten {CORE::log($_[1])/CORE::log(10)}

sub tan {CORE::sin($_[1])/CORE::cos($_[1])}
sub cot {CORE::cos($_[1])/CORE::sin($_[1])}
sub sec {1/CORE::cos($_[1])}
sub csc {1/CORE::sin($_[1])}

sub asin {CORE::atan2($_[1],CORE::sqrt(1-$_[1]*$_[1]))}
sub acos {CORE::atan2(CORE::sqrt(1-$_[1]*$_[1]),$_[1])}
sub atan {CORE::atan2($_[1],1)}
sub acot {CORE::atan2(1,$_[1])}
sub asec {acos(1.0/$_[1])}
sub acsc {asin(1.0/$_[1])}

sub sinh {(CORE::exp($_[1])-CORE::exp(-$_[1]))/2}
sub cosh {(CORE::CORE::exp($_[1])+CORE::CORE::exp(-$_[1]))/2}
sub tanh {(CORE::exp($_[1])-CORE::exp(-$_[1]))/(CORE::exp($_[1])+CORE::exp(-$_[1]))}
sub sech {2/(CORE::exp($_[1])+CORE::exp(-$_[1]))}
sub csch {2.0/(CORE::exp($_[1])-CORE::exp(-$_[1]))}
sub coth {(CORE::exp($_[1])+CORE::exp(-$_[1]))/(CORE::exp($_[1])-CORE::exp(-$_[1]))}

sub asinh {CORE::log($_[1]+CORE::sqrt($_[1]*$_[1]+1.0))}
sub acosh {CORE::log($_[1]+CORE::sqrt($_[1]*$_[1]-1.0))}
sub atanh {CORE::log((1.0+$_[1])/(1.0-$_[1]))/2.0}
sub asech {CORE::log((1.0+CORE::sqrt(1-$_[1]*$_[1]))/$_[1])}
sub acsch {CORE::log((1.0+CORE::sqrt(1+$_[1]*$_[1]))/$_[1])}
sub acoth {CORE::log(($_[1]+1.0)/($_[1]-1.0))/2.0}

sub sgn {$_[1] <=> 0}

#
#  Back to main package
#
package main;

#
#  Make main versions call the checker to see
#  which package-specific version to call
#

sub ln {CommonFunction->Call('log',@_)}
sub logten {CommonFunction->Call('logten',@_)}

sub tan {CommonFunction->Call('tan',@_)}
sub cot {CommonFunction->Call('cot',@_)}
sub sec {CommonFunction->Call('sec',@_)}
sub csc {CommonFunction->Call('csc',@_)}

sub arcsin {CommonFunction->Call('asin',@_)}; sub asin {CommonFunction->Call('asin',@_)}
sub arccos {CommonFunction->Call('acos',@_)}; sub acos {CommonFunction->Call('acos',@_)}
sub arctan {CommonFunction->Call('atan',@_)}; sub atan {CommonFunction->Call('atan',@_)}
sub arccot {CommonFunction->Call('acot',@_)}; sub acot {CommonFunction->Call('acot',@_)}
sub arcsec {CommonFunction->Call('asec',@_)}; sub asec {CommonFunction->Call('asec',@_)}
sub arccsc {CommonFunction->Call('acsc',@_)}; sub acsc {CommonFunction->Call('acsc',@_)}

sub sinh {CommonFunction->Call('sinh',@_)}
sub cosh {CommonFunction->Call('cosh',@_)}
sub tanh {CommonFunction->Call('tanh',@_)}
sub sech {CommonFunction->Call('sech',@_)}
sub csch {CommonFunction->Call('csch',@_)}
sub coth {CommonFunction->Call('coth',@_)}

sub arcsinh {CommonFunction->Call('asinh',@_)}; sub asinh {CommonFunction->Call('asinh',@_)}
sub arccosh {CommonFunction->Call('acosh',@_)}; sub acosh {CommonFunction->Call('acosh',@_)}
sub arctanh {CommonFunction->Call('atanh',@_)}; sub atanh {CommonFunction->Call('atanh',@_)}
sub arcsech {CommonFunction->Call('asech',@_)}; sub asech {CommonFunction->Call('asech',@_)}
sub arccsch {CommonFunction->Call('acsch',@_)}; sub acsch {CommonFunction->Call('acsch',@_)}
sub arccoth {CommonFunction->Call('acoth',@_)}; sub acoth {CommonFunction->Call('acoth',@_)}

sub sgn {CommonFunction->Call('sgn',@_)}

1;
