################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2020 The WeBWorK Project, http://openwebwork.sf.net/
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

=head1 NAME

parserLogb.pl - defines a C<logb(b, x)> function for the logarithm with base b
evaluated at x.

=head1 DESCRIPTION

This file defines the code necessary to add to any context a C<logb(b, x)>
function that evaluates the logarithm with base b at x.  For example,
C<Compute("logb(3, 5)")> would return the equivalent of
C<Compute("log(5)/log(3)"> although it will be displayed as a logarithm with
base b.

To accomplish this, put the line

    loadMacros("parserLogb.pl");

at the beginning of your problem file, then set the Context to the one you wish
to use in the problem.  Then use the command:

    Parser::Logb->Enable;

(You can also pass the Enable command a pointer to a context if you wish to
alter a context other than the current one.)

Once that is done, you (and students) can enter logarithms with base b by using
the C<logb()> function.  You can use C<logb()> both within C<Formula()> and
C<Compute()> calls, and in Perl expressions, such as

	$ans = Compute("logb(3, 5)";
    $n   = logb(3, 5);

to obtain the logarithm with base b.  Note that by default C<logb()> will
produce an error message for logarithms evaluated at zero or negative numbers or
if the base is zero or negative.

However, if you enable C<logb()> in a context that allows complex numbers, you
may want to allow logarithms of negative numbers or with negative bases.  To do
this, use

    Parser::Logb->EnableComplex;

(again, you can pass a context to be altered, if you wish).  This will force
logarithms of negative values or with negative bases to be promoted to complex
numbers.  So

    Parser::Logb->EnableComplex;
    $z = logb(3, -9);
    $y = logb(-3, 9);

would produce the equivalent of C<$z = Compute("log(-9)/log(3)");> and
C<$y = Compute("log(9)/log(-3)");> except that they will be displayed as
logarithms with base 3 or -3 respectively.

Note that if MathQuill is enabled, then students will be able to enter the
logarithm with base C<b> evaluated at C<x> by typing C<log_b(x)>. To facilitate
students entering such answers, a subscript button is present in the MathQuill
toolbar for answers with the C<logb> function enabled.

=cut

BEGIN { strict->import }

loadMacros('MathObjects.pl');

sub _parserLogb_init { }

sub logb { Parser::Function->call('logb', @_); }

package Parser::Logb;

sub Enable {
	my ($self, $context, $complex) = @_;
	$context = main::Context() unless Value::isContext($context);
	$context->functions->add(logb => { class => 'Parser::Logb::Function::numeric2' });
	$context->functions->set(logb => { negativeIsComplex => 1 }) if $complex;
	$context->flag('mathQuillOpts')->{logsChangeBase} = 0;
	return;
}

sub EnableComplex {
	my ($self, $context) = @_;
	$self->Enable($context, 1);
	return;
}

package Parser::Logb::Function::numeric2;
our @ISA = qw(Parser::Function);

# Check for numeric arguments
sub _check {
	my $self    = shift;
	my $context = $self->context;
	return if ($self->checkArgCount(2));
	$self->{type} = $Value::Type{number};
	return if $context->flag('allowBadFunctionInputs');
	my ($b, $x) = @{ $self->{params} };
	$self->Error('Function "%s" must have numeric inputs', $self->{name})
		unless $b->isNumber && $x->isNumber;
	$self->{type} = $Value::Type{complex} if $x->isComplex || $b->isComplex;
	return;
}

# Check that the inputs are OK and call the named routine
sub _call {
	my ($self, $name, @inputs) = @_;
	$self->Error('Function "%s" has too many inputs', $name) if scalar(@inputs) > 2;
	$self->Error('Function "%s" has too few inputs',  $name) if scalar(@inputs) < 2;
	return $self->$name($self->checkArguments($name, @inputs));
}

# Call the appropriate routine
sub _eval {
	my ($self, @inputs) = @_;
	my $name = $self->{name};
	return $self->$name($self->checkArguments($name, @inputs));
}

# Check that the parameters are OK
sub checkArguments {
	my ($self, $name, @inputs) = @_;
	my $context = $self->context;
	my ($b, $x) = (map { Value::makeValue($_, $context) } @inputs);
	$self->Error('Function "%s" must have numeric inputs', $name)
		unless $b->isNumber && $x->isNumber;
	return ($b, $x);
}

# Compute log base b using log(x)/log(b)
# If b < 0 or x < 0, either promote to a complex or throw an error.
sub logb {
	my ($self, $b, $x) = @_;
	$self->Error('Invalid base %s logarithm of %s', $b)
		if $x->value == 0 || $b->value == 0;
	if (($x->isReal && $x->value < 0) || ($b->isReal && $b->value < 0)) {
		my $context = $x->context;
		$self->Error('Invalid base %s logarithm of %s', $b, $x)
			unless $context->functions->get('logb')->{negativeIsComplex};
		$x = $self->Package('Complex')->promote($context, $x);
		$b = $self->Package('Complex')->promote($context, $b);
	}
	return log($x) / log($b);
}

# Implement differentiation: (logb(b, u))' -> u'/(u * ln(b)) - b'/(b * ln(u)) * logb(b, u)
sub D {
	my ($self, $x) = @_;
	my $equation = $self->{equation};
	my $BOP      = $self->Item('BOP');
	my $NUM      = $self->Item('Number');
	my ($b, $u) = @{ $self->{params} };
	my $D = $BOP->new(
		$equation,
		'/',
		$u->D($x),
		$BOP->new(
			$equation, '*', $u->copy($equation),
			$self->Item('Function')->new($equation, 'ln', [ $b->copy($equation) ], $b->{isConstant})
		)
	);
	$D = $BOP->new(
		$equation,
		'-', $D,
		$BOP->new(
			$equation,
			'*',
			$BOP->new(
				$equation,
				'/',
				$b->D($x),
				$BOP->new(
					$equation, '*', $b->copy($equation),
					$self->Item('Function')->new($equation, 'ln', [ $b->copy($equation) ], $b->{isConstant})
				)
			),
			$self->copy($equation)
		)
	) if $b->getVariables->{$x};
	return $D->reduce;
}

# Output TeX using \log_{b}(x)
sub TeX {
	my ($self, $precedence, $showparens, $position, $outerRight, $power) = @_;
	$showparens = '' unless defined $showparens;
	my $fn            = $self->{equation}{context}{operators}{'fn'};
	my $fn_precedence = $fn->{parenPrecedence} || $fn->{precedence};
	my ($b, $x) = @{ $self->{params} };
	my $TeX = '\log_{' . $b->TeX . '}\left(' . $x->TeX . '\right)';
	$TeX = '\left(' . $TeX . '\right)'
		if $showparens eq 'all'
		|| $showparens eq 'extra'
		|| (defined($precedence) && $precedence > $fn_precedence)
		|| (defined($precedence) && $precedence == $fn_precedence && $showparens eq 'same');
	return $TeX;
}

1;
