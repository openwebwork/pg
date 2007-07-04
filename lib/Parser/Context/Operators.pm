#########################################################################
#
#  Implements the list of Operators
#
package Parser::Context::Operators;
use strict;
our @ISA = qw(Value::Context::Data);

sub init {
  my $self = shift;
  $self->{dataName} = 'operators';
  $self->{name} = 'operator';
  $self->{Name} = 'operator';
  $self->{namePattern} = qr/.+/;
  $self->{tokenType} = 'op';
}

#
#  Remove an operator from the list by assigning it
#    the undefined operator.  This means it will still
#    be recognized by the parser, but will generate an
#    error message whenever it is used.
#
sub undefine {
  my $self = shift;
  my @data = ();
  foreach my $x (@_) {
    if ($self->{context}{operators}{$x}{type} eq 'unary') {
      push(@data,$x => {
	class => 'Parser::UOP::undefined',
	oldClass => $self->get($x)->{class},
      });
    } else {
      push(@data,$x => {
	class => 'Parser::BOP::undefined',
	oldClass => $self->get($x)->{class},
      });
    }
  }
  $self->set(@data);
}

sub redefine {
  my $self = shift; my $X = shift;
  return $self->SUPER::redefine($X,@_) if scalar(@_) > 0;
  $X = [$X] unless ref($X) eq 'ARRAY';
  my @data = ();
  foreach my $x (@{$X}) {
    my $oldClass = $self->get($x)->{oldClass};
    push(@data,$x => {class => $oldClass, oldClass => undef})
      if $oldClass;
  }
  $self->set(@data);
}

#########################################################################

1;
