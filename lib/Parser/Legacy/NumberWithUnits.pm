######################################################################
#
#  This is a Parser class that implements a number or formula
#  with units.  It is a temporary version until the Parser can
#  handle it directly.
#

package Parser::Legacy::ObjectWithUnits;

# Refrences to problem specific copies of %Units::fundamental_units
# and %Units::known_units.  These should be passed to any Units function call.
# They are set by the initializeUnits sub
my $fundamental_units = '';
my $known_units = '';

sub name {'object'};
sub cmp_class {'an Object with Units'};
sub makeValue {
  my $self = shift; my $value = shift;
  my %options = (context=>$self->context,@_);
  Value::makeValue($value,%options);
}

sub initializeUnits {
  $fundamental_units = shift;
  $known_units = shift;
}

sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $context = (Value::isContext($_[0]) ? shift : $self->context);
  my $num = shift;
  # we need to check if units is the options hash
  my $units = shift;
  my $options;

  if (ref($units) eq 'HASH') {
    $options = $units;
    $units = '';
  } else {
    $options = shift;
  }

  # register a new unit/s if needed
  if (defined($options->{newUnit})) {
    my @newUnits;
    if (ref($options->{newUnit}) eq 'ARRAY') {
      @newUnits = @{$options->{newUnit}};
    } else {
      @newUnits = ($options->{newUnit});
    }

    foreach my $newUnit (@newUnits) {
      if (ref($newUnit) eq 'HASH') {
	add_unit($newUnit->{name}, $newUnit->{conversion});
      } else {
	add_unit($newUnit);
      }
    }
  }

  
  
  Value::Error("You must provide a ".$self->name) unless defined($num);
  ($num,$units) = splitUnits($num) unless $units;
  Value::Error("You must provide units for your ".$self->name) unless $units;
  Value::Error("Your units can only contain one division") if $units =~ m!/.*/!;
  $num = $self->makeValue($num,context=>$context);
  my %Units = getUnits($units);
  Value::Error($Units{ERROR}) if ($Units{ERROR});
  $num->{units} = $units;
  $num->{units_ref} = \%Units;
  $num->{isValue} = 1;
  bless $num, $class;
}

##################################################

#
#  Find the units for the formula and split that off
#
sub splitUnits {
  my $aUnit = '(?:'.getUnitNames().')(?:\s*(?:\^|\*\*)\s*[-+]?\d+)?';
  my $unitPattern = $aUnit.'(?:\s*[/* ]\s*'.$aUnit.')*';
  my $unitSpace = "($aUnit) +($aUnit)";
  my $string = shift;
  my ($num,$units) = $string =~ m!^(.*?(?:[)}\]0-9a-z]|\d\.))\s*($unitPattern)\s*$!;
  if ($units) {
    while ($units =~ s/$unitSpace/$1*$2/) {};
    $units =~ s/ //g;
    $units =~ s/\*\*/^/g;
  }

  return ($num,$units);
}

#
#  Sort names so that longest ones are first, and then alphabetically
#  (so we match longest names before shorter ones).
#
sub getUnitNames {
  local ($a,$b);
  my $units = \%Units::known_units;
  if ($known_units) {
    $units = $known_units;
  }
  join('|',sort {
    return length($b) <=> length($a) if length($a) != length($b);
    return $a cmp $b;
  } keys(%$units));
}

#
#  Get the units hash and fix up the errors
#
sub getUnits {
  my $units = shift;
  my $options = {};
  if ($fundamental_units) {
    $options->{fundamental_units} = $fundamental_units;
  }
  if ($known_units) {
    $options->{known_units} = $known_units;
  }
  my %Units = Units::evaluate_units($units,$options);
  if ($Units{ERROR}) {
    $Units{ERROR} =~ s/ at ([^ ]+) line \d+(\n|.)*//;
    $Units{ERROR} =~ s/^UNIT ERROR:? *//;
  }
  return %Units;
}

#
#  Convert units to TeX format
#  (fix superscripts, put terms in \rm,
#   and make a \frac out of fractions)
#
sub TeXunits {
  my $units = shift;
  $units =~ s/\^\(?([-+]?\d+)\)?/^{$1}/g;
  $units =~ s/\*/\\,/g;
  return '{\rm '.$units.'}' unless $units =~ m!^(.*)/(.*)$!;
  my $displayMode = WeBWorK::PG::Translator::PG_restricted_eval(q!$main::displayMode!);
  return '{\textstyle\frac{'.$1.'}{'.$2.'}}' if ($displayMode eq 'HTML_tth');
  return '{\textstyle\frac{\rm\mathstrut '.$1.'}{\rm\mathstrut '.$2.'}}';
}

##################################################

#
#  Replace the cmp_parse with one that removes the units
#  from the student answer and checks them.  The answer
#  value is adjusted by the factors, and then checked.
#  Finally, the units themselves are checked.
#
sub cmp_parse {
  my $self = shift; my $ans = shift;
  #
  #  Check that the units are defined and legal
  #

  my ($num,$units) = splitUnits($ans->{student_ans});
  unless (defined($num) && defined($units) && $units ne '') {
    $self->cmp_Error($ans,"Your answer doesn't look like ".lc($self->cmp_class));
    return $ans;
  }
  if ($units =~ m!/.*/!) {
    $self->cmp_Error($ans,"Your units can only contain one division");
    return $ans;
  }
  my %Units = getUnits($units);
  if ($Units{ERROR}) {$self->cmp_Error($ans,$Units{ERROR}); return $ans}
  #
  #  Check the numeric part of the answer
  #   and adjust the answer strings
  #
  $self->adjustCorrectValue($ans,$self->{units_ref}{factor}/$Units{factor});
  $ans->{student_ans} = $num;
  $ans = $self->cmp_reparse($ans);
  $ans->{student_ans} .= " " . $units;
  $ans->{preview_text_string}  .= " ".$units;
  $ans->{preview_latex_string} .= '\ '.TeXunits($units);
  #
  return $ans unless $ans->{ans_message} eq '';
  #
  #  Check that we have an actual number, and check the units
  #
  if (!defined($ans->{student_value}) || $self->checkStudentValue($ans->{student_value})) {
    $ans->{student_value} = undef; $ans->score(0);
    $self->cmp_Error($ans,"Your answer doesn't look like a number with units");
  } else {
    $ans->{student_value} = $self->new($num,$units);
    foreach my $funit (keys %{$self->{units_ref}}) {
      next if $funit eq 'factor';
      next if $self->{units_ref}{$funit} == $Units{$funit};
      $self->cmp_Error($ans,"The units for your answer are not correct")
        unless $ans->{isPreview};
      $ans->score(0); last;
    }
  }
  return $ans;
}

#
#  Fix the correct answer so that the value matches the student's units
#
sub adjustCorrectValue {
  my $self = shift; my $ans = shift;
  my $factor = shift;
  $ans->{correct_value}{data}[0] *= $factor;
}

sub cmp_reparse {Value::cmp_parse(@_)}

sub add_fundamental_unit {
  my $unit = shift;
  $fundamental_units->{$unit} = 0;
}

sub add_unit {
  my $unit = shift;
  my $hash = shift;
  
  unless (ref($hash) eq 'HASH') {
    $hash = {'factor'    => 1,
	     "$unit"     => 1 };
  }

  # make sure that if this unit is defined in terms of any other units
  # then those units are fundamental units.  
  foreach my $subUnit (keys %$hash) {
    if (!defined($fundamental_units->{$subUnit})) {
      add_fundamental_unit($subUnit);
    }
  }

  $known_units->{$unit} = $hash;
}

######################################################################

#
#  Customize for NumberWithUnits
#

package Parser::Legacy::NumberWithUnits;
our @ISA = qw(Parser::Legacy::ObjectWithUnits Value::Real);

sub name {'number'};
sub cmp_class {'a Number with Units'};

sub makeValue {
  my $self = shift; my $value = shift;
  my %options = (context => $self->context,@_);
  my $num = Value::makeValue($value,%options);
  Value::Error("A number with units must be a constant, not %s",lc(Value::showClass($num)))
    unless Value::isReal($num);
  return $num;
}

sub checkStudentValue {
  my $self = shift; my $student = shift;
  return $student->class ne 'Real';
}

sub promote {
  my $self = shift; my $class = ref($self) || $self;
  my $context = (Value::isContext($_[0]) ? shift : $self->context);
  my $x = (scalar(@_) ? shift : $self);
  return $x->inContext($context) if (ref($x) eq $class || Value::isReal($x)) && scalar(@_) == 0;
  return $self->new($context,$x,@_);
}

sub string {
  my $self = shift;
  Value::Real::string($self,@_) . ' ' . $self->{units};
}

sub TeX {
  my $self = shift;
  my $n = Value::Real::string($self,@_);
  $n =~ s/E\+?(-?)0*([^)]*)/\\times 10^{$1$2}/i; # convert E notation to x10^(...)
  return $n . '\ ' . Parser::Legacy::ObjectWithUnits::TeXunits($self->{units});
}


######################################################################

#
#  Customize for FormulaWithUnits
#

package Parser::Legacy::FormulaWithUnits;
our @ISA = qw(Parser::Legacy::ObjectWithUnits Value::Formula);

sub name {'formula'};
sub cmp_class {'a Formula with Units'};

sub makeValue {
  my $self = shift; my $value = shift;
  my %options = (context => $self->context,@_);
  $self->Package("Formula")->new($options{context},$value);
}

sub checkStudentValue {
  my $self = shift; my $student = shift;
  return $student->type ne 'Number';
}

sub adjustCorrectValue {
  my $self = shift; my $ans = shift;
  my $factor = shift;
  my $f = $ans->{correct_value};
  $f->{tree} = $f->Item("BOP")->new($f,'*',$f->{tree},$f->Item("Value")->new($f,$factor));
}

sub string {
  my $self = shift;
  Parser::string($self,@_) . ' ' . $self->{units};
}

sub TeX {
  my $self = shift;
  Parser::TeX($self,@_) . '\ ' . Parser::Legacy::ObjectWithUnits::TeXunits($self->{units});
}

######################################################################

1;
