#########################################################################
#
#  Implement the list of allowed parentheses.
#
package Parser::Context::Parens;
use strict;
use vars qw (@ISA);
@ISA = qw(Value::Context::Data);

sub init {
  my $self = shift;
  $self->{dataName} = 'parens';
  $self->{name} = 'parenthesis';
  $self->{Name} = 'Parenthesis';
  $self->{namePattern} = '[^\s]+';
}

#
#  Make open and close patterns from the list
#
sub update {
  my $self = shift;
  my $parens = $self->{context}{$self->{dataName}};
  my @open = (); my $openS = ''; my $openN = 0;
  my @close = (); my $closeS = ''; my $closeN = 0;
  foreach my $x (keys %{$parens}) {
    unless ($parens->{$x}{hidden}) {
      if (length($x) > 1) {push(@open,$x)} else {$openS .= $x}
      if (length($parens->{$x}{close}) > 1) {push(@close,$parens->{x}{close})}
        else {$closeS .= $parens->{$x}{close}}
    }
  }
  $self->{open} = $self->getPattern($openS,@open);
  $self->{close} = $self->getPattern($closeS,@close);
  $self->{context}->update;
}

#########################################################################

1;
