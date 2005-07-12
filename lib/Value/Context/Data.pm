#########################################################################
#
#  Implements base class for data list in Context objects.
#
package Value::Context::Data;
use strict;

sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $parent = shift;
  my $data = bless {
    context => $parent,     # parent context
    dataName => {},         # name of data storage in context hash
    pattern => '^$',        # pattern for names of data items (default never matches)
    namePattern => '',      # pattern for allowed names for new items
    name => '', Name => '', # lower- and upper-case names for the class of items
  }, $class;
  $data->init();
  $parent->{$data->{dataName}} = {};
  $data->add(@_);
  return $data;
}

#
#  Implemented in sub-classes
#
sub init {}
sub create {shift; shift}

#
#  Sort names so that they can be joined for regexp matching
#
sub byName {
  my $result = length($b) <=> length($a);
  return $result unless $result == 0;
  return $a cmp $b;
}

#
#  Update the pattern for the names
#
sub update {
  my $self = shift;
  my $data = $self->{context}->{$self->{dataName}};
  my $single = ''; my @multi = ();
  foreach my $x (sort byName (keys %{$data})) {
    unless ($data->{$x}{hidden}) {
      if (length($x) == 1) {$single .= $x} else {push(@multi,$x)}
    }
  }
  $self->{pattern} = $self->getPattern($single,@multi);
  $self->{context}->update;
}

#
#  Build a regexp pattern from the characters and list of names
#  (protect special characters)
#
sub getPattern {
  shift; my $s = shift;
  foreach my $x (@_) {$x = protectRegexp($x)}
  my @pattern = ();
  push(@pattern,join('|',@_)) if scalar(@_) > 0;
  push(@pattern,protectRegexp($s)) if length($s) == 1;
  push(@pattern,"[".protectChars($s)."]") if length($s) > 1;
  my $pattern = join('|',@pattern);
  $pattern = '^$' if $pattern eq '';
  return $pattern;
}

sub protectRegexp {
  my $string = shift;
  $string =~ s/[\[\](){}|+.*?\\]/\\$&/g;
  return $string;
}

sub protectChars {
  my $string = shift;
  $string =~ s/\]/\\\]/g;
  $string =~ s/^(.*)-(.*)$/-$1$2/g;
  return $string;
}


#
#  Add one or more new items to the list
#
sub add {
  my $self = shift; my %D = (@_); return if scalar(@_) == 0;
  my $data = $self->{context}{$self->{dataName}};
  foreach my $x (keys %D) {
    Value::Error("Illegal %s name '%s'",$self->{name},$x) unless $x =~ m/^$self->{namePattern}$/;
    warn "$self->{Name} '$x' already exists" if defined($data->{$x});
    $data->{$x} = $self->create($D{$x});
  }
  $self->update;
}

#
#  Remove one or more items
#
sub remove {
  my $self = shift;
  my $data = $self->{context}{$self->{dataName}};
  foreach my $x (@_) {
    warn "$self->{Name} '$x' doesn't exist" unless defined($data->{$x});
    delete $data->{$x};
  }
  $self->update;
}

#
#  Replace an item with a new definition
#
sub replace {
  my $self = shift; my %list = (@_);
  $self->remove(keys %list);
  $self->add(@_);
}

#
#  Clear all items
#
sub clear {
  my $self = shift;
  $self->{context}{$self->{dataName}} = {};
  $self->update;
}

#
#  Make the data be only these items
#
sub are {
  my $self = shift;
  $self->clear;
  $self->add(@_);
}

#
#  Make one or more items become undefined, but still recognized.
#  (Implemented in the sub-classes.)
#
sub undefine {my $self = shift; $self->remove(@_)}


#
#  Get hash for an item
#
sub get {
  my $self = shift; my $x = shift;
  return $self->{context}{$self->{dataName}}{$x};
}

#
#  Set flags for one or more items
#
sub set {
  my $self = shift; my %D = (@_);
  my $data = $self->{context}{$self->{dataName}};
  foreach my $x (keys(%D)) {
    my $xref = $data->{$x};
    if (defined($xref) && ref($xref) eq 'HASH') {
      foreach my $id (keys %{$D{$x}}) {$xref->{$id} = $D{$x}{$id}}
    } else {
      $data->{$x} = $self->create($D{$x});
    }
  };
}

#
#  Get the names of all items
#
sub names {
  my $self = shift;
  return sort(keys %{$self->{context}{$self->{dataName}}});
}

#
#  Get the complete data hash
#
sub all {
  my $self = shift;
  $self->{context}{$self->{dataName}};
}

#########################################################################
#
#  Load the subclasses.
#

use Value::Context::Flags;
use Value::Context::Lists;

#########################################################################

1;
