#########################################################################
#
#  Implements the list of known functions
#
package Parser::Context::Functions;
use strict;
use vars qw (@ISA);
@ISA = qw(Parser::Context::Data);

sub init {
  my $self = shift;
  $self->{dataName} = 'functions';
  $self->{name} = 'function';
  $self->{Name} = 'Function';
  $self->{namePattern} = '[a-zA-Z][a-zA-Z0-9]*';
}

#
#  Remove a function from the list by assigning it
#    the undefined function.  This means it will still
#    be recognized by the parser, but will generate an
#    error message whenever it is used.
#
sub undefine {
  my $self = shift;
  my @data = ();
  foreach my $x (@_) {push(@data,$x => {class => 'Parser::Function::undefined'})}
  $self->set(@data);
}

#########################################################################

1;
