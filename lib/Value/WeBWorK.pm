#############################################################
#
#  Definitions specific to WeBWorK.
#

sub Value::Formula::PGseedRandom {
  my $self = shift;
  return if $self->{PGrandom};
  $self->{PGrandom} = new PGrandom($self->{context}->flag('random_seed'));
}
sub Value::Formula::PGgetRandom {shift->{PGrandom}->random(@_)}

my @wwEvalFields = qw(
  functAbsTolDefault
  functNumOfPoints
  functRelPercentTolDefault
  functZeroLevelDefault
  functZeroLevelTolDefault
  numAbsTolDefault
  numFormatDefault
  numRelPercentTolDefault
  numZeroLevelDefault
  numZeroLevelTolDefault
);

sub Value::Context::initCopy {
  my $self = shift;
  my $context = $self->copy(@_);
  $context->{WW} = {}; push @{$context->{data}{values}}, 'WW';
  return $context if $Value::_no_WeBWorK_; # hack for command-line debugging
  return $context unless $Parser::installed;  # only do WW initialization after parser is fully loaded
  foreach my $x (@wwEvalFields) {$context->{WW}{$x} = eval('$main::envir{'.$x.'}');}
  my $ww = $context->{WW};
  $context->flags->set(
     tolerance    => $ww->{numRelPercentTolDefault} / 100,
     zeroLevel    => $ww->{numZeroLevelDefault},
     zeroLevelTol => $ww->{numZeroLevelTolDefault},
     num_points   => $ww->{functNumOfPoints} + 2,
  );
  $context->{format}{number} = $ww->{numFormatDefault} if $ww->{$numFormatDefault} ne '';
  $context;
}

#############################################################

use Value::AnswerChecker;

#############################################################

1;
