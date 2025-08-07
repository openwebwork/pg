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
my $known_units       = '';

sub name      {'object'}
sub cmp_class {'an Object with Units'}

sub makeValue {
	my $self    = shift;
	my $value   = shift;
	my %options = (context => $self->context, @_);
	bless Value::makeValue($value, %options), $options{class};
}

sub initializeUnits {
	$fundamental_units = shift;
	$known_units       = shift;
}

sub new {
	my $self    = shift;
	my $class   = ref($self) || $self;
	my $context = (Value::isContext($_[0]) ? shift : $self->context);
	my $num     = shift;
	# we need to check if units is the options hash
	my $units = shift;
	my $options;

	if (ref($units) eq 'HASH') {
		$options = $units;
		$units   = '';
	} else {
		$options = shift;
	}

	# register a new unit/s if needed
	if (defined($options->{newUnit})) {
		my @newUnits;
		if (ref($options->{newUnit}) eq 'ARRAY') {
			@newUnits = @{ $options->{newUnit} };
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

	Value::Error("You must provide a " . $self->name)              unless defined($num);
	($num, $units) = splitUnits($num, $options->{mathquill})       unless $units;
	Value::Error("You must provide units for your " . $self->name) unless $units;
	Value::Error("Your units can only contain one division") if $units =~ m!/.*/!;
	$num = $self->makeValue($num, context => $context, class => $class);
	my %Units = getUnits($units);
	Value::Error($Units{ERROR}) if ($Units{ERROR});
	$num->{units}     = $units;
	$num->{units_ref} = \%Units;
	$num->{isValue}   = 1;
	$num->{correct_ans}              .= ' ' . $units           if defined $num->{correct_ans};
	$num->{correct_ans_latex_string} .= ' ' . TeXunits($units) if defined $num->{correct_ans_latex_string};
	return $num;
}

##################################################

#
#  Find the units for the formula and split that off
#
sub splitUnits {
	my $string         = shift;
	my $parseMathQuill = shift;
	my $aUnit          = '(?:' . getUnitNames() . ')(?:\s*(?:\^|\*\*)\s*[-+]?\d+)?';
	my $unitPattern =
		$parseMathQuill
		? '\(?\s*' . $aUnit . '(?:\s*[* ]\s*' . $aUnit . ')*\s*\)?'
		: $aUnit . '(?:\s*[/* ]\s*' . $aUnit . ')*';
	$unitPattern = $unitPattern . '(?:\/' . $unitPattern . ')*' if $parseMathQuill;
	my $unitSpace = "($aUnit) +($aUnit)";
	my ($num, $units) = $string =~ m!^(.*?(?:[)}\]0-9a-z]|\d\.))?\s*($unitPattern)\s*$!;
	if ($units) {
		while ($units =~ s/$unitSpace/$1*$2/) { }
		$units =~ s/ //g;
		$units =~ s/\*\*/^/g;
		$units =~ s/^\(?([^\(\)]*)\)?\/\(?([^\(\)]*)\)?$/$1\/$2/g if $parseMathQuill;
	}

	return ($num, $units);
}

#
#  Sort names so that longest ones are first, and then alphabetically
#  (so we match longest names before shorter ones).
#
sub getUnitNames {
	local ($a, $b);
	my $units = \%Units::known_units;
	if ($known_units) {
		$units = $known_units;
	}
	join(
		'|',
		sort {
			return length($b) <=> length($a) if length($a) != length($b);
			return $a cmp $b;
		} keys(%$units)
	);
}

#
#  Get the units hash and fix up the errors
#
sub getUnits {
	my $units   = shift;
	my $options = {};
	if ($fundamental_units) {
		$options->{fundamental_units} = $fundamental_units;
	}
	if ($known_units) {
		$options->{known_units} = $known_units;
	}
	my %Units = Units::evaluate_units($units, $options);
	if ($Units{ERROR}) {
		$Units{ERROR} =~ s/ at ([^ ]+) line \d+(\n|.)*//;
		$Units{ERROR} =~ s/^UNIT ERROR:? *//;
	}
	return %Units;
}

#
#  Convert units to TeX format
#  (fix superscripts, put terms in \rm,
#   escape percent,
#   and make a \frac out of fractions)
#
sub TeXunits {
	my $units = shift;
	$units                                      =~ s/\^\(?([-+]?\d+)\)?/^{$1}/g;
	$units                                      =~ s/\*/\\,/g;
	$units                                      =~ s/%/\\%/g;
	return '{\rm ' . $units . '}' unless $units =~ m!^(.*)/(.*)$!;
	my $displayMode = WeBWorK::PG::Translator::PG_restricted_eval(q!$main::displayMode!);
	return '{\textstyle\frac{' . $1 . '}{' . $2 . '}}' if ($displayMode eq 'HTML_tth');
	return '{\textstyle\frac{\rm\mathstrut ' . $1 . '}{\rm\mathstrut ' . $2 . '}}';
}

##################################################

sub uPowers {
	my $self  = shift;
	my $ref   = $self->{units_ref};
	my @units = grep { $ref->{$_} != 0 && $_ ne 'factor' } sort(keys %$ref);
	return join(' ', map { $_ . '=' . $ref->{$_} } @units);
}

sub add {
	my ($self, $l, $r, $other) = Value::checkOpOrderWithPromote(@_);
	my ($lunits, $runits) = ($l->uPowers, $r->uPowers);
	$self->Error("Can't add numbers with different units") unless $lunits eq $runits;
	my $factor = $r->{units_ref}{factor} / $l->{units_ref}{factor};
	return $self->new($l->value + $r->value * $factor, $l->{units});
}

sub sub {
	my ($self, $l, $r, $other) = Value::checkOpOrderWithPromote(@_);
	my ($lunits, $runits) = ($l->uPowers, $r->uPowers);
	$self->Error("Can't subtract numbers with different units") unless $lunits eq $runits;
	my $factor = $r->{units_ref}{factor} / $l->{units_ref}{factor};
	return $self->new($l->value - $r->value * $factor, $l->{units});
}

sub mult {
	my ($self, $l, $r, $other) = Value::checkOpOrderWithPromote(@_);
	my ($ltop, $lbot)          = split(/\//, $l->{units});
	my ($rtop, $rbot)          = split(/\//, $r->{units});
	my $bot   = $lbot ? ($rbot ? "$lbot*$rbot" : $lbot) : $rbot;
	my $units = "$ltop*$rtop" . ($bot ? '/' . $bot : '');
	return $self->new($l->value * $r->value, $units);
}

sub div {
	my ($self, $l, $r, $other) = Value::checkOpOrderWithPromote(@_);
	my ($ltop, $lbot)          = split(/\//, $l->{units});
	my ($rtop, $rbot)          = split(/\//, $r->{units});
	my $units = ($ltop . ($rbot ? "*$rbot" : '')) . '/' . (($lbot ? "$lbot*" : '') . $rtop);
	return $self->new($l->value / $r->value, $units);
}

sub power {
	my ($self, $l, $r, $other) = Value::checkOpOrder(@_);
	($l, $r) = (Value::makeValue($l), Value::makeValue($r));
	$self->Error("Can't raise %s to %s", $l->showClass, $r->showClass)
		unless $r->type eq 'Number' && !$r->classMatch('NumberWithUnit');
	my $n = $r->value;
	$self->Error("The power for %s must be a non-zero integer value", $l->showClass)
		if $n == 0 || CORE::int($n) != $n;
	return $l->copy if $n == 1;
	my @terms = split(/([*\/])/, $self->{units});
	for (my $i = 0; $i < @terms; $i += 2) {
		my ($b, $p) = split(/\^/, $terms[$i]);
		$p = 1 unless defined $p;
		$p *= $n;
		$terms[$i] = "$b^$p";
	}
	return $self->new($self->value**$n, join('', @terms));
}

##################################################

sub cmp {
	my $self = shift;
	my $meth = @{ ref($self) . '::ISA' }[-1] . '::cmp';
	$meth = 'Value::cmp' unless defined &$meth;
	my $ans = &$meth($self, @_);
	$ans->install_pre_filter(sub { $self->unitsPreFilter(@_) });
	return $ans;
}

sub unitsPreFilter {
	my $self = shift;
	my $ans  = shift;
	my ($num, $units) = splitUnits($ans->{student_ans},
		$ans->{correct_value}{context}
			&& $ans->{correct_value}->context->flag('useMathQuill')
			&& (!defined $ans->{mathQuillOpts} || $ans->{mathQuillOpts} !~ /^\s*disabled\s*$/i));
	if (defined($units) && $units ne '' && $num eq '') {
		$self->cmp_Error($ans, "Units must follow a number");
		$ans->{unit_error}  = $ans->{ans_message};
		$ans->{student_ans} = '';
		return $ans;
	}
	unless (defined($num) && defined($units) && $units ne '') {
		$self->cmp_Error($ans, "Your answer doesn't look like " . lc($self->cmp_class));
		$ans->{unit_error} = $ans->{ans_message};
		return $ans;
	}
	if ($units =~ m!/.*/!) {
		$self->cmp_Error($ans, "Your units can only contain one division");
		$ans->{unit_error} = $ans->{ans_message};
		return $ans;
	}
	my $ref = { getUnits($units) };
	if ($ref->{ERROR}) {
		$self->cmp_Error($ans, $ref->{ERROR});
		$ans->{unit_error} = $ans->{ans_message};
		return $ans;
	}
	$ans->{units}       = $units;
	$ans->{student_ans} = $num;
	return $ans;
}

sub cmp_preprocess {
	my $self = shift;
	my $ans  = shift;

	if ($ans->{unit_error}) {
		$ans->{ans_message} = $ans->{error_message} = $ans->{unit_error};
		if ($ans->{student_ans} eq '') {
			$ans->{student_ans}          = $ans->{original_student_ans};
			$ans->{preview_latex_string} = TeXunits($ans->{student_ans});
		}
		return;
	}
	my $units = $ans->{units};
	return $ans unless $units;
	$ans->{student_ans}          .= " " . $units;
	$ans->{preview_text_string}  .= " " . $units;
	$ans->{preview_latex_string} .= '\ ' . TeXunits($units);

	if (!defined($ans->{student_value}) || $self->checkStudentValue($ans->{student_value})) {
		$ans->{student_value} = undef;
		$ans->score(0);
		$self->cmp_Error($ans, "Units must follow a number");
		$ans->{unit_error} = $ans->{ans_message};
		return;
	}

	$ans->{student_formula} = Parser::Legacy::FormulaWithUnits->new($ans->{student_formula}->{tree}, $units);
	$ans->{student_value}   = Parser::Legacy::NumberWithUnits->new($ans->{student_value}->value, $units);
}

sub cmp_equal {
	my $self = shift;
	my $ans  = shift;
	if (!$ans->{unit_error}) {
		my $meth = @{ ref($self) . '::ISA' }[-1] . '::cmp_equal';
		$meth = 'Value::cmp_equal' unless defined &$meth;
		&$meth($self, $ans, @_);
	}
}

sub cmp_postprocess {
	my $self = shift;
	my $ans  = shift;
	if ($ans->{units} && $ans->{score} == 0 && !$ans->{ans_message}) {
		$self->cmp_Error($ans, "The units for your answer are not correct")
			unless $ans->{correct_value}->uPowers eq $ans->{student_value}->uPowers;
	}
	return $ans;
}

##################################################

sub add_fundamental_unit {
	my $unit = shift;
	$fundamental_units->{$unit} = 0;
}

sub add_unit {
	my $unit = shift;
	my $hash = shift;

	unless (ref($hash) eq 'HASH') {
		$hash = {
			'factor' => 1,
			"$unit"  => 1
		};
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

sub name      {'number'}
sub cmp_class {'a Number with Units'}

sub value { uc(shift->{data}[0]) }

sub makeValue {
	my $self    = shift;
	my $value   = shift;
	my %options = (context => $self->context, @_);
	my $num     = Value::makeValue($value, %options);
	return bless $num, 'Parser::Legacy::FormulaWithUnits' if $num->classMatch('Formula');
	Value::Error("A number with units must be a constant, not %s", lc(Value::showClass($num)))
		unless Value::isReal($num);
	bless $num, $options{class};
}

sub checkStudentValue {
	my $self    = shift;
	my $student = shift;
	return $student->class ne 'Real';
}

sub promote {
	my $self    = shift;
	my $class   = ref($self) || $self;
	my $context = (Value::isContext($_[0]) ? shift : $self->context);
	my $x       = (scalar(@_)              ? shift : $self);
	return $x->inContext($context) if (ref($x) eq $class || Value::isReal($x)) && scalar(@_) == 0;
	return $self->new($context, $x, @_);
}

sub showClass {'a Number-with-Units'}

sub compare {
	my ($self, $other, $flag) = @_;

	$other = $self->promote($other) unless Value::classMatch($other, 'NumberWithUnits');
	return $other->compare($self, !$flag) if Value::isFormula($other);

	my $factor   = $other->{units_ref}{factor} / $self->{units_ref}{factor};
	my $adjusted = Value::Real->new($other->value * $factor);
	my $ret      = Value::Real->new($self->value)->compare($adjusted, $flag);
	$ret = ($self->{units} cmp $other->{units}) * ($flag ? -1 : 1)
		if $ret == 0 && $self->uPowers ne $other->uPowers;
	return $ret;
}

sub string {
	my $self = shift;
	Value::Real::string($self, @_) . ' ' . $self->{units};
}

sub TeX {
	my $self = shift;
	my $n    = Value::Real::string($self, @_);
	$n =~ s/E\+?(-?)0*([^)]*)/\\times 10^{$1$2}/i;    # convert E notation to x10^(...)
	return $n . '\ ' . Parser::Legacy::ObjectWithUnits::TeXunits($self->{units});
}

######################################################################

#
#  Customize for FormulaWithUnits
#

package Parser::Legacy::FormulaWithUnits;
our @ISA = qw(Parser::Legacy::ObjectWithUnits Value::Formula);

sub name      {'formula'}
sub cmp_class {'a Formula with Units'}

sub value {
	my $self = shift;
	return $self->Package("Formula")->new($self->context, $self->{tree});
}

sub makeValue {
	my $self    = shift;
	my $value   = shift;
	my %options = (context => $self->context, @_);
	bless $self->Package("Formula")->new($options{context}, $value), $options{class};
}

sub checkStudentValue {
	my $self    = shift;
	my $student = shift;
	return $student->type ne 'Number';
}

sub promote {
	my $self    = shift;
	my $class   = ref($self) || $self;
	my $context = (Value::isContext($_[0]) ? shift : $self->context);
	my $x       = (scalar(@_)              ? shift : $self);
	return $x->inContext($context) if ref($x) eq $class && scalar(@_) == 0;
	return $self->new($context, $x->value, $x->{units}) if Value::classMatch($x, 'NumberWithUnits');
	return $self->new($context, $x, @_);
}

sub showClass {'a Formula returning a Number-with-Units'}

sub compare {
	my ($self, $other, $flag) = @_;
	$other = $self->promote($other);

	my $adjusted = $other->value * uc($other->{units_ref}{factor} / $self->{units_ref}{factor});
	my $ret      = $self->value->compare($adjusted, $flag);
	$ret = ($self->{units} cmp $other->{units}) * ($flag ? -1 : 1)
		if $ret == 0 && $self->uPowers ne $other->uPowers;
	return $ret;
}

sub string {
	my $self = shift;
	Parser::string($self, @_) . ' ' . $self->{units};
}

sub TeX {
	my $self = shift;
	Parser::TeX($self, @_) . '\ ' . Parser::Legacy::ObjectWithUnits::TeXunits($self->{units});
}

######################################################################

1;
