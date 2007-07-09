#########################################################################
#
#  Implements the Matrix class.
#
package Parser::List::Matrix;
use strict;
our @ISA = qw(Parser::List);

#
#  The main checks are all done in the List object.
#  Here, we just convert the entry types from points or
#    vectors to matrices (hack) with appropriate parens.
#
sub _check {
  my $self = shift;
  my $matrix = $self->{equation}{context}{lists}{Matrix};
  $self->{open} = $matrix->{open}; $self->{close} = $matrix->{close};
  if ($self->{entryType}{name} ne 'Matrix') {
    foreach my $x (@{$self->{coords}})
      {$x->makeMatrix($self->{type}{name},$self->{open},$self->{close})}
  }
  return if $self->context->flag("allowBadOperands");
  foreach my $x (@{$self->{coords}}) {
    $self->{equation}->Error("Entries in a Matrix must be Numbers or Lists of Numbers")
      unless ($x->type =~ m/Number|Matrix/);
  }
}

#
#  Handle a 2-dimensional matrix as a special case, using
#  LaTeX's \array command.
#
sub TeX {
  my ($self,$precedence) = @_;
  return $self->SUPER::TeX(@_) unless $self->entryType->{entryType};
  my ($open,$close) = ($self->{open},$self->{close});
  $open = '\{' if $open eq '{'; $close = '\}' if $close eq '}';
  my $TeX = ''; my @entries = (); my $d;
  foreach my $row (@{$self->coords}) {
    foreach my $x (@{$row->coords}) {push(@entries,$x->TeX)}
    $TeX .= join(' &',@entries) . '\cr'."\n";
    $d = scalar(@entries); @entries = ();
  }
  $TeX = '\begin{array}{'.($self->{array_template} || ('c'x$d)).'}'."\n".$TeX.'\end{array}';
  return $TeX unless $open || $close;
  $open  = "." if $close && !$open;
  $close = "." if $open && !$close;
  return '\left'.$open.$TeX.'\right'.$close;
}

#
#  Recursively handle the rows, but only enclose in brackets
#  to form reference to array of (references to arrays of ...) entries
#
sub perl {
  my $self = shift; my $parens = shift; my $matrix = shift;
  my $perl; my @p = ();
  foreach my $x (@{$self->{coords}}) {push(@p,$x->perl(0,1))}
  if ($matrix) {
    $perl = '['.join(',',@p).']';
  } else {
    $perl = $self->Package($self->type).'->new('.join(',',@p).')';
    $perl = '('.$perl.')' if $parens;
  }
  return $perl;
}

#########################################################################

1;
