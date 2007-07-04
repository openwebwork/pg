#########################################################################
#
#  Implement the list of Value::Diagnostics types
#
package Value::Context::Diagnostics;
use strict;
our @ISA = ("Value::Context::Data");

sub new {
  my $self = shift; my $parent = shift;
  $self->SUPER::new($parent,
    formulas => {
      show => 0,
      showTestPoints => 1,
      showParameters => 1,
      showAbsoluteErrors => 1,
      showRelativeErrors => 1,
      showGraphs => 1,
      graphRelativeErrors => 1,
      graphAbsoluteErrors => 1,
      clipRelativeError => 5,
      clipAbsoluteError => 5,
      plotTestPoints => 1,
      combineGraphs => 1,
      checkNumericStability => 1,
    },
    graphs => {
      divisions => 75,
      limits => undef,
      size => 250,
      grid => [10,10],
      axes => [0,0],
    },
    @_,
  );
}

sub init {
  my $self = shift;
  $self->{dataName} = 'diagnostics';
  $self->{name} = 'diagnostics';
  $self->{Name} = 'Diagnostics';
  $self->{namePattern} = qr/[-\w_.]+/;
}

sub update {} # no pattern or tokens needed
sub addToken {}
sub removeToken {}

sub merge {
  my $self = shift; my $type = shift;
  my $merge = {%{$self->{context}{$self->{dataName}}}};
  foreach my $object (@_) {
    my $data = $object->{$self->{dataName}}; next unless $data;
    $data = {$type=>{@{$data}}} if ref($data) eq 'ARRAY';
    $data = {$type=>{show=>$data}} unless ref($data) eq 'HASH';
    $merge->{$type}{show} = 1 if scalar(keys(%{$data}));
    foreach my $x (keys %{$data}) {
      if (ref($merge->{$x}) ne 'HASH') {$merge->{$x} = $data->{$x}}
        else {$merge->{$x} = {%{$merge->{$x}},%{$data->{$x}}}}
    }
  }
  return $merge;
}


#########################################################################

1;
