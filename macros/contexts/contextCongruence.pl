################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2023 The WeBWorK Project, https://github.com/openwebwork
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of either: (a) the GNU General Public License as published by the
# Free Software Foundation; either version 2, or (at your option) any later
# version, or (b) the "Artistic License" which comes with this package.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See either the GNU General Public License or the
# Artistic License for more details.
################################################################################

=encoding UTF-8
=head1 NAME


C<Context("Congruence")> - Provides contexts that allow the
entry of congruence solutions

=head1 DESCRIPTION

These contexts allow you to enter congruence solutions.
Either the general solution or all possible solutions can be accepted
based on settings.

There are three contexts included here: C<Context("Congruence")>, which
allows both types of solutions, C<Context("Congruence-General-Solution")>, which
requires the general solution, and C<Context("Congruence-All-Solutions")>, which
requires all solutions to be entered.

Congruences must be created with three paramters (a, b, m) from ax ≡ b (mod m).

=head1 USAGE


    loadMacros("contextCongruence.pl");

    Context("Congruence");

ax ≡ b (mod m)

Can initialize with Congruence(a, b, m);

    #ex: 15x ≡ 10 (mod 25)
    $C1 = Congruence(15, 10, 25);
    $general_answer = Compute("4+5k");
    $all_answers = Compute("4+25k,9+25k,14+25k,19+25k,24+25k");
    $all_answers_diff_order = Compute("9+25k,4+25k,14+25k,19+25k,24+25k");

    $C1->compare($general_answer); # is true
    $C1->compare($all_answers); # is true
    $C1->compare($all_answers_diff_order); # is true

Can an force general solution only with

    Context()->flags->set(requireGeneralSolution => 1);
    $C1->compare($general_answer); # is true
    $C1->compare($all_answers); # is false


Can an force all solutions only with

    Context()->flags->set(requireAllSolutions => 1);
    $C1->compare($general_answer); # is false
    $C1->compare($all_answers); # is true

Students can enter 'none' when there is no solution

ex: 15x ≡ 10 (mod 24)

    $C2 = Congruence(15, 10, 24);
    $none = Compute("None");
    $n = Compute("n");

    $C2->compare($none); # is true
    $C2->compare($n); # is true
    $C1->compare($none); # is false

=cut

loadMacros('MathObjects.pl', 'contextInteger.pl');

sub _contextCongruence_init { context::Congruence::Init() }

###########################################################################

package context::Congruence;
our @ISA = ('Value::Formula');

#
#  Initialize the contexts and make the creator function.
#
sub Init {
	my $context = $main::context{Congruence} = Parser::Context->getCopy("Numeric");
	$context->{name} = "Congruence";
	Parser::Number::NoDecimals($context);

	$context->variables->clear();
	$context->variables->add(k => 'Real');

	$context->strings->add(
		None => { caseSensitive => 0 },
		N    => { caseSensitive => 0, alias => "None" }
	);

	$context->flags->set(
		requireGeneralSolution => 0,    # require general solution as answer?
		requireAllSolutions    => 0,    # require all solution as answer?
		outputAllSolutions     =>
			0    # default display only general solution. switch to 1 to display all possible solutions
	);

	#
	#  Only allow general solution for answer and output
	#
	$context = $main::context{"Congruence-General-Solution"} = $context->copy;
	$context->{name} = "Congruence-General-Solution";
	$context->flags->set(
		requireGeneralSolution => 1,
		requireAllSolutions    => 0,
		outputAllSolutions     => 0
	);

	#
	#  Only allow all solutions for answer and output
	#
	$context = $main::context{"Congruence-All-Solutions"} = $context->copy;
	$context->{name} = "Congruence-All-Solutions";
	$context->flags->set(
		requireGeneralSolution => 0,
		requireAllSolutions    => 1,
		outputAllSolutions     => 1
	);

	main::PG_restricted_eval("sub Congruence {context::Congruence->new(\@_)}");
}

sub new {
	my $self    = shift;
	my $class   = ref($self) || $self;
	my $context = (Value::isContext($_[0]) ? shift : $self->context);

	# validation is handled in _getCongruenceData
	my ($g, $residue, $divisor) = context::Congruence::Function::Numeric3::_getCongruenceData(@_);
	my $formula = main::Formula->new($context, "k");
	$formula->{g}       = $g;
	$formula->{residue} = $residue;
	$formula->{divisor} = $divisor;
	return bless $formula, $class;
}

sub compare {
	my ($l, $r) = @_;
	my $self    = $l;
	my $context = $self->context;

	my $generalSolution        = $l->generalSolution;
	my $allSolutions           = $l->allSolutions;
	my $requireGeneralSolution = $self->getFlag("requireGeneralSolution");
	my $requireAllSolutions    = $self->getFlag("requireAllSolutions");

	# allow unorder formula lists
	if ($r->classMatch("Formula") && scalar($r->value)) {
		my @orderedValues = main::PGsort(
			sub {
				$_[0]->eval(k => 0) < $_[1]->eval(k => 0);
			},
			$r->value
		);
		$r = Value::Formula->new($self->context, join(",", @orderedValues));
	}

	if ($requireGeneralSolution) {
		return $generalSolution->compare($r);
	} elsif ($requireAllSolutions) {
		return $allSolutions->compare($r);
	} else {
		# check both all solutons and general solution
		return 0 if $allSolutions->compare($r) == 0;
		return $generalSolution->compare($r);
	}
}

sub generalSolution {
	my $self = shift;

	# check no solution
	return $self->Package("String")->new($self->context, "None") if ($self->{g} == 0);

	return Value::Formula->new($self->context, $self->{residue} . "+" . $self->{divisor} . "k");
}

sub allSolutions {
	my $self = shift;

	# check no solution
	return $self->Package("String")->new($self->context, "None") if ($self->{g} == 0);

	@solutions = ();
	my $divisor = $self->{divisor} * $self->{g};
	for my $index (0 .. $self->{g} - 1) {
		my $residue = $self->{residue} + ($index * $self->{g});
		push(@solutions, $residue . "+" . $divisor . "k");
	}
	return Value::Formula->new($self->context, join(",", @solutions));
}

#
#  Produce a string version
#
sub string {
	my $self               = shift;
	my $outputAllSolutions = $self->getFlag("outputAllSolutions");

	if ($outputAllSolutions) {
		return $self->allSolutions->string;
	} else {
		return $self->generalSolution->string;
	}
}

#
#  Produce a TeX version
#
sub TeX {
	my $self               = shift;
	my $outputAllSolutions = $self->getFlag("outputAllSolutions");

	if ($outputAllSolutions) {
		return $self->allSolutions->TeX;
	} else {
		return $self->generalSolution->TeX;
	}
}

sub typeMatch {
	my $self  = shift;
	my $other = shift;
	return $other->classMatch("Formula", "String");
}

package context::Congruence::Function::Numeric3;    # checks for 3 numeric inputs
our @ISA = qw(Parser::Function);

#
#  Check for two real-valued arguments
#
sub _check {
	my $self = shift;
	return if ($self->checkArgCount(3));
	if (
		(
			$self->{params}->[0]->isNumber
			&& $self->{params}->[1]->isNumber
			&& $self->{params}->[2]->isNumber
			&& !$self->{params}->[0]->isComplex
			&& !$self->{params}->[1]->isComplex
			&& !$self->{params}->[2]->isComplex
		)
		|| $self->context->flag("allowBadFunctionInputs")
		)
	{
		$self->{type} = $Value::Type{number};
	} else {
		$self->Error("Function '%s' has the wrong type of inputs", $self->{name});
	}
}

#
#  Check that the inputs are OK
#
sub _call {
	my $self = shift;
	my $name = shift;
	Value::Error("Function '%s' has too many inputs", $name) if scalar(@_) > 3;
	Value::Error("Function '%s' has too few inputs",  $name) if scalar(@_) < 3;
	Value::Error("Function '%s' has the wrong type of inputs", $name)
		unless Value::matchNumber($_[0]) && Value::matchNumber($_[1]);
	return $self->$name(@_);
}

#
#  Call the appropriate routine
#
sub _eval {
	my $self = shift;
	my $name = $self->{name};
	$self->$name(@_);
}

#
#  Congruence Class
#  ax ≡ b (mod m)
#
# returns gcd, residue, divisor
sub _getCongruenceData {
	my $a = shift;
	my $b = shift;
	my $m = shift;
	my $g = context::Integer::Function::Numeric2::gcd($a, $m);

	# check for no solutions
	if ($b % $g != 0) {
		return (0, 0, 0);
	}

	# (a/g)x ≡ (b/g) (mod (m/g)) reduce multiple solutions
	my $a2 = $a / $g;
	my $b2 = $b / $g;
	my $m2 = $m / $g;

	# x ≡ $modularInverse * b2 (mod m2)
	my $modularInverse = context::Integer::Function::Numeric2::mulularInverse($a2, $m2);
	$x = ($modularInverse * $b2) % $m2;

	return ($g, $x, $m2);
}

1;
