
=head1 DESCRIPTION

##############################################
#
#  Implements functions that are common to
#  the new Parser.pm and the old PGauxiliaryFunctions.pl
#

=cut

sub _PGcommonFunctions_init {}

#
#  Make these interact nicely with Parser.pm
#
package CommonFunction;

=head3 NOTE

#
#  Either call Parser (if it has been loaded) or
#  the functions below.  (If it's ever the case
#  that both the Parser and PGauxiliaryFunctions.pl are
#  both preloaded, then there will be no need for
#  this, as you can always use the Parser versions.
#  We only need this because Parser might not be loaded.)
#

=cut

sub Call {
  my $self = shift;
  my $fn = shift;
  if ($main::_parser_loaded) {
    return Parser::Function->call($fn,@_)
      if Parser::Context->current->{functions}{$fn};
  }
  return &{$CommonFunction::function{$fn}}(@_) if $CommonFunction::function{$fn};
  return $self->$fn(@_);
}

sub log {CORE::log($_[1])}
sub ln  {CORE::log($_[1])}
sub logten {CORE::log($_[1])/CORE::log(10)}

sub tan {CORE::sin($_[1])/CORE::cos($_[1])}
sub cot {CORE::cos($_[1])/CORE::sin($_[1])}
sub sec {1/CORE::cos($_[1])}
sub csc {1/CORE::sin($_[1])}

sub asin {CORE::atan2($_[1],CORE::sqrt(1-$_[1]*$_[1]))}
sub acos {CORE::atan2(CORE::sqrt(1-$_[1]*$_[1]),$_[1])}
sub atan {CORE::atan2($_[1],1)}
sub acot {CORE::atan2(1,$_[1])}
sub asec {acos($_[0],1.0/$_[1])}
sub acsc {asin($_[0],1.0/$_[1])}

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

sub C {
  shift; my ($n,$r) = @_; my $C = 1;
  return(0) if ($r>$n);
  $r = $n-$r if ($r > $n-$r); # find the smaller of the two
  for (1..$r) {$C = ($C*($n-$_+1))/$_}
  return $C;
}

sub P {
  shift; my ($n,$r) = @_; my $P = 1;
  return(0) if ($r>$n);
  for (1..$r) {$P *= ($n-$_+1)}
  return $P;
}


#
#  Back to main package
#
package main;

#
#  Make main versions call the checker to see
#  which package-specific version to call
#


Parser::defineLog();

sub ln     {CommonFunction->Call('ln',@_)}
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

sub C {CommonFunction->Call('C', @_)}
sub P {CommonFunction->Call('P', @_)}
sub Comb {CommonFunction->Call('C', @_)}
sub Perm {CommonFunction->Call('P', @_)}

1;
