#########################################################################
#
#  Implements the list of Operators
#
package Parser::Context::Operators;
use strict;
use vars qw (@ISA);
@ISA = qw(Parser::Context::Data);

sub init {
  my $self = shift;
  $self->{dataName} = 'operators';
  $self->{name} = 'operator';
  $self->{Name} = 'operator';
  $self->{namePattern} = '.+';
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
      push(@data,$x => {class => 'Parser::UOP::undefined'});
    } else {
      push(@data,$x => {class => 'Parser::BOP::undefined'});
    }
  }
  $self->set(@data);
}

#########################################################################

1;
