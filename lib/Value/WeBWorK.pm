#############################################################
#
#  Definitions specific to WeBWorK.
#

##################################################
#
#  Convert a student answer to a formula, with error trapping.
#  If the result is undef, there was an error (message is in Context()->{error} object)
#

package Parser;

sub Formula {
  my $f = shift;
  my $v = eval {Value::Formula->new($f)};
  reportEvalError($@) unless defined($v) || $$Value::context->{error}{flag};
  return $v;
}

#
#  Evaluate a formula, with error trapping.
#  If the result is undef, there was an error (message is in Context()->{error} object)
#  If the result was a real, make it a fuzzy one.
#
sub Evaluate {
  my $f = shift;
  return unless defined($f);
  my $v = eval {$f->eval(@_)};
  if (defined($v)) {$v = Value::makeValue($v)}
    else {reportEvalError($@) unless $f->{context}{error}{flag}}
  return $v;
}

#
#  Remove backtrace and line number, since these
#  will be reported in the student 
#
sub Parser::reportEvalError {
  my $error = shift; my $fullerror = $error;
  $error =~ s/ at \S+\.\S+ line \d+(\n|.)*//;
  $error =~ s/ at line \d+ of (\n|.)*//;
  $$Value::context->setError($error);
  if ($$Value::context->{debug}) {
    $fullerror =~ s/\n/<BR>/g;
    warn $fullerror;
  }
}

package main;

#####################################################
#
# Use PG random number generator rather than perl
#
sub Value::Formula::PGseedRandom {
  my $self = shift;
  return if $self->{PGrandom};
  $self->{PGrandom} = new PGrandom($self->{context}->flag('random_seed'));
}
sub Value::Formula::PGgetRandom {shift->{PGrandom}->random(@_)}

#####################################################
#
#  Initialize contexts with WW default data
#

my @wwEvalFields = qw(
  functAbsTolDefault
  functNumOfPoints
  functRelPercentTolDefault
  functZeroLevelDefault
  functZeroLevelTolDefault
  functMaxConstantOfIntegration
  numAbsTolDefault
  numFormatDefault
  numRelPercentTolDefault
  numZeroLevelDefault
  numZeroLevelTolDefault
  useBaseTenLog
);

sub Parser::Context::initCopy {
  my $self = shift;
  my $context = $self->copy(@_);
  return $context if $context->{WW} && scalar(keys %{$context->{WW}}) > 0;
  $context->{WW} = {}; push @{$context->{data}{values}}, 'WW';
  return $context if $Value::_no_WeBWorK_; # hack for command-line debugging
  return $context unless $Parser::installed;  # only do WW initialization after parser is fully loaded
  foreach my $x (@wwEvalFields) {$context->{WW}{$x} = eval('$main::envir{'.$x.'}');}
  my $ww = $context->{WW};
  $context->flags->set(
     tolerance      => $ww->{numRelPercentTolDefault} / 100,
     zeroLevel      => $ww->{numZeroLevelDefault},
     zeroLevelTol   => $ww->{numZeroLevelTolDefault},
     num_points     => $ww->{functNumOfPoints} + 2,
     max_adapt      => $ww->{functMaxConstantOfIntegration},
     useBaseTenLog => $ww->{useBaseTenLog},
  );
  $context->{format}{number} = $ww->{numFormatDefault} if $ww->{numFormatDefault} ne '';
  $context;
}

#############################################################

use Value::AnswerChecker;

#############################################################

1;
