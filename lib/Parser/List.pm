#########################################################################
#
#  Implements base List class.
#
package Parser::List;
use strict; use vars qw(@ISA);
@ISA = qw(Parser::Item);

#
#  First, check to see if we might be forming an interval
#    (true if the close paren is not the right one for the
#     open paren, or if one of the coordinates is infinity).
#  If we aren't forming an interval,
#    See if we need to form a matrix (entry type is already a vector)
#    Otherwise if we have mixed entry types (type is unknown)
#      Form a list if we can
#      Otherwise report an appropriate error
#  Then create the appropriately typed list object
#
sub new {
  my $self = shift;
  my $equation = shift; my $coords = shift;
  my $constant = shift; my $paren = shift;
  my $entryType = shift || $Value::Type{unknown};
  my $open = shift || ''; my $close = shift || '';
  my $parens = $equation->{context}{parens}; my $list;
 
  if ($paren && $close && $paren->{formInterval}) {
    $paren = $parens->{interval}
      if ($paren->{close} ne $close || (scalar(@{$coords}) == 2 &&
           ($coords->[0]->{isInfinite} || $coords->[1]->{isInfinite})) ||
           (scalar(@{$coords}) == 1 && $coords->[0]->{isInfinite}));
  }
  my $type = Value::Type($paren->{type},scalar(@{$coords}),$entryType,
                                list => 1, formMatrix => $paren->{formMatrix});
  if ($type->{name} ne 'Interval') {
    if ($paren->{formMatrix} && $entryType->{formMatrix}) {$type->{name} = 'Matrix'}
    elsif ($entryType->{name} eq 'unknown') {
      if ($paren->{formList}) {$type->{name} = 'List'}
      elsif ($type->{name} eq 'Point') {
        $equation->Error("Entries in a Matrix must be of the same type and length")}
      else {$equation->Error("Entries in a $type->{name} must be of the same type")}
    }
  }
  $list = bless {
    coords => $coords, type => $type, open => $open, close => $close,
    paren => $paren, equation => $equation, isConstant => $constant
  }, $equation->{context}{lists}{$type->{name}}{class};
  $list->checkInterval;
  $list->_check;
#  warn ">> $list->{type}{name} of $list->{type}{entryType}{name} of length $list->{type}{length}\n";
  if ($list->{isConstant}) {
    my $saveCBI = $list->{canBeInterval};
    $list = Parser::Value->new($equation,[$list->eval]);
    $list->{type} = $type; $list->{open} = $open; $list->{close} = $close;
    $list->{value}->{open} = $open, $list->{value}->{close} = $close
      if ref($list->{value});
    $list->{canBeInterval} = $saveCBI if $saveCBI;
  }
  return $list;
}

sub checkInterval {
  my $self = shift;
  if ((($self->{open} eq '(' || $self->{open} eq '[') &&
       ($self->{close} eq ')' || $self->{close} eq ']') && $self->length == 2) ||
      ($self->{open}.$self->{close} eq '[]' && $self->length == 1))
          {$self->{canBeInterval} = 1}
}

sub _check {}

##################################################

#
#  Evaluate all the entries in the list
#    then process the results
#
sub eval {
  my $self = shift; my @p = ();
  foreach my $x (@{$self->{coords}}) {push(@p,$x->eval)}
  $self->_eval(@p);
}

#
#  Call the appropriate creation routine from Value.pm
#  (Can be over-written by sub-classes)
#
sub _eval {
  my $self = shift;
  my $type = 'Value::'.$self->type;
  my $value = $type->new(@_);
  $value->{open} = $self->{open}; $value->{close} = $self->{close};
  return $value;
}

#
#  Reduce all the entries in the list
#  Mark the result as a zero or constant vector as appropriate
#  Do any sub-class defined reductions.
#
sub reduce {
  my $self = shift;
  my @coords = (); my $zero = 1; my $constant = 1;
  foreach my $x (@{$self->{coords}}) {
    $x = $x->reduce; return if $self->{equation}{error};
    $zero = 0 unless $x->{isZero};
    $constant = 0 unless $x->{isConstant};
  }
  $self->{isZero} = 1 if $zero and scalar(@coords) > 0;
  $self->{isConstant} = 1 if $constant;
  ## check matrix for being identity
  return Parser::Value->new($self->{equation},[$self->eval]) if $constant;
  $self->_reduce;
}
#
#  Stub for sub-classes.
#
sub _reduce {shift}

#
#  Substitute in each coordinate
#  Mark the result as a zero or constant vector as appropriate
#
sub substitute {
  my $self = shift;
  my @coords = (); my $zero = 1; my $constant = 1;
  foreach my $x (@{$self->{coords}}) {
    $x = $x->substitute; return if $self->{equation}{error};
    $zero = 0 unless $x->{isZero};
    $constant = 0 unless $x->{isConstant};
  }
  $self->{isZero} = 1 if $zero and scalar(@coords) > 0;
  $self->{isConstant} = 1 if $constant;
  ## check matrix for being identity
  return Parser::Value->new($self->{equation},[$self->eval]) if $constant;
  return $self;
}

#
#  Copy all the list entries as well as the list object.
#
sub copy {
  my $self = shift; my $equation = shift;
  my $new = $self->SUPER::copy($equation);
  $new->{coords} = [];
  foreach my $x (@{$self->{coords}}) {push(@{$new->{coords}},$x->copy($equation))}
  return $new;
}

##################################################

#
#  Return the coordinate array reference
#
sub coords {(shift)->{coords}}

#
#  Get the variables from all the coordinates
#
sub getVariables {
  my $self = shift; my $vars = {};
  foreach my $x (@{$self->{coords}}) {$vars = {%{$vars},%{$x->getVariables}}}
  return $vars;
}

#
#  Convert the list to a matrix with given open and close parens
#  (Used my Matrix to convert the rows from points and vectors to
#   matrices so they print properly.  Probably a mistake.)
#
sub makeMatrix {
  my $self = shift;
  my ($name,$open,$close) = @_;
  bless $self, $self->{equation}{context}{lists}{$name}{class};
  $self->{type}{name} = $name;
  $self->{open} = $open; $self->{close} = $close;
}

##################################################
#
#  Generate the various output formats.
#

#
#  Produce a string version.
#
sub string {
  my $self = shift; my $precedence = shift; my @coords = ();
  foreach my $x (@{$self->{coords}}) {push(@coords,$x->string)}
  return $self->{open}.join(',',@coords).$self->{close};
}

#
#  Produce TeX version.
#
#  Use stretchable open and close delimiters (quoting braces)
#  
sub TeX {
  my $self = shift; my $precedence = shift; my @coords = ();
  my ($open,$close) = ($self->{open},$self->{close});
  $open = '\{' if $open eq '{'; $close = '\}' if $close eq '}';
  $open  = '\left' .$open  if $open  ne '';
  $close = '\right'.$close if $close ne '';
  foreach my $x (@{$self->{coords}}) {push(@coords,$x->TeX)}
  return $open.join(',',@coords).$close;
}

#
#  Produce perl version
#
sub perl {
  my $self = shift; my $parens = shift; my $matrix = shift;
  my $perl; my @p = ();
  foreach my $x (@{$self->{coords}}) {push(@p,$x->perl)}
  $perl = $self->type.'('.join(',',@p).')';
  $perl = '('.$perl.')' if $parens;
  return $perl;
}

sub makeUnion {
  my $self = shift;
  $self = bless $self->copy, 'Parser::List::Interval';
  $self->typeRef->{name} = $self->{equation}{context}{parens}{interval}{type};
  return $self;
}

#########################################################################
#
#  Load the subclasses.
#

use Parser::List::Point;
use Parser::List::Vector;
use Parser::List::Matrix;
use Parser::List::List;
use Parser::List::Interval;
use Parser::List::AbsoluteValue;

#########################################################################

1;
