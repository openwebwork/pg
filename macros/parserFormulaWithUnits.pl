loadMacros('Parser.pl');

sub _parserFormulaWithUnits_init {}; # don't reload this file

######################################################################
#
#  This is a Parser class that implements a formula with units.
#  It is a temporary version until the Parser can handle it
#  directly.
#
#  Use FormulaWithUnits("num units") or FormulaWithUnits(formula,"units")
#  to generate a FormulaWithUnits object, and then call its cmp() method
#  to get an answer checker for your formula with units.
#
#  Usage examples:
#
#      ANS(FormulaWithUnits("3 ft")->cmp);
#      ANS(FormulaWithUnits("$a*$b ft")->cmp);
#      ANS(FormulaWithUnits($a*$b,"ft")->cmp);
#
######################################################################

sub FormulaWithUnits {FormulaWithUnits->new(@_)}

package FormulaWithUnits;
our @ISA = qw(Value::Formula);

sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $num = shift; my $units = shift;
  Value::Error("You must provide a formula") unless defined($num);
  ($num,$units) = splitUnits($num) unless $units;
  Value::Error("You must provide units for your formula") unless $units;
  Value::Error("Your units can only contain one division") if $units =~ m!/.*/!;
  $num = Value::Formula->new($num);
  my %Units = getUnits($units);
  Value::Error($Units{ERROR}) if ($Units{ERROR});
  $num->{units} = $units;
  $num->{units_ref} = \%Units;
  $num->{isValue} = 1;
  bless $num, $class;
}

#
#  Find the units for the formula and split that off
#  (Too bad the Units::known_units hash is private)
#
my $aUnit = '([a-zA-Z]+|light-year)(\s*(\^|\*\*)\s*[-+]?\d+)?';
my $unitPattern = $aUnit.'(\s*[/*]\s*'.$aUnit.')*';
sub splitUnits {
  my $string = shift;
  my ($num,$units) = $string =~ m!^(.*?(?:[)}\]0-9a-z]|\d\.))\s*($unitPattern)$!o;
  if ($units) {
    $units =~ s/ //g;
    $units =~ s/\*\*/^/g;
  }
  return ($num,$units);
}

#
#  Add the units to the string value
#
sub string {
  my $self = shift;
  $self->SUPER::string . " " . $self->{units};
}

#
#  Add the units to the TeX value
#
sub TeX {
  my $self = shift;
  $self->SUPER::TeX(@_) . '\ ' . TeXunits($self->{units});
}


sub cmp_class {'a Formula with Units'};

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
    $self->cmp_Error($ans,"Your answer doesn't look like a number with units");
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
  my $factor = $self->{units_ref}{factor}/$Units{factor};
  my $f = $ans->{correct_value}; my $parser = $f->{context}{parser};
  $f->{tree} = $parser->{BOP}->new($f,'*',$f->{tree},$parser->{Value}->new($f,$factor));
  $ans->{student_ans} = $num;
  $ans = $self->SUPER::cmp_parse($ans);
  $ans->{student_ans} .= " " . $units;
  $ans->{preview_text_string}  .= " ".$units;
  $ans->{preview_latex_string} .= '\ '.TeXunits($units);
  #
  return $ans unless $ans->{ans_message} eq '';
  #
  #  Check that we have an actual number, and check the units
  #
  if (!defined($ans->{student_value}) || $ans->{student_value}->type ne 'Number') {
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
#  Convert units to TeX format
#  (fix superscripts, put terms in \rm,
#   and make a \frac out of fractions)
#
sub TeXunits {
  my $units = shift;
  $units =~ s/\^\(?([-+]?\d+)\)?/^{$1}/g;
  $units =~ s/\*/\\,/g;
  return '{\rm '.$units.'}' unless $units =~ m!^(.*)/(.*)$!;
  my $displayMode = $main::displayMode;
  return '\frac{'.$1.'}{'.$2.'}' if ($displayMode eq 'HTML_tth');
  return '\frac{\rm\mathstrut '.$1.'}{\rm\mathstrut '.$2.'}';
}

#
#  Get the units hash and fix up the errors
#
sub getUnits {
  my $units = shift;
  my %Units = Units::evaluate_units($units);
  if ($Units{ERROR}) {
    $Units{ERROR} =~ s/ at ([^ ]+) line \d+(\n|.)*//;
    $Units{ERROR} =~ s/^UNIT ERROR:? *//;
  }
  return %Units;
}

1;
