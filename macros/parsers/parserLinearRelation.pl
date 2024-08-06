################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2024 The WeBWorK Project, https://github.com/openwebwork
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

=encoding utf8

=head1 NAME

contextLinearRelation.pl - Implement linear relations.

=head1 DESCRIPTION

This macro library provides a context C<LinearRelation> with a C<LinearRelation>
Math Object using =, <, >, <=, >=, or !=. Note that this file evolved from
C<parserLinearInequality.pl>, but it has several important differences.

Activate the context with:

    Context("LinearRelation");

Use C<LinearRelation(formula)>, C<Formula(formula)>, or C<Compute(formula)> to 
to create a LinearRelation object using a string formula. Alternatively, use
C<LinearRelation(vector,point,sign> where C<vector> is the normal vector and
C<point> is a point on the plane. Either can be an array reference or a Math
Object Vector or Point. And C<sign> is one of the (in)equality symbols. Or use
C<LinearRelation(vector,real,sign)> where C<real> is the dot product of any
point in the plane with the normal vector.

Usage examples:

    $LR = LinearRelation("x + y + 2z <= 5");
    $LR = Formula("x + y + 2z <= 5");
    $LR = Compute("x + y + 2z <= 5");
    $LR = LinearRelation([1,1,2], [1,2,1], "<=");
    $LR = LinearRelation([1,1,2], 5, "<=");
    $LR = LinearRelation(Vector(1,1,2), Point(1,2,1), "<=");
    $LR = LinearRelation(Vector(1,1,2), 5, "<=");

If C<$pg{specialPGEnvironmentVars}{parseAlternatives}> is true in your configuration,
then you may also work with sloppy inequality signs (=<, =>, <>) and with the
characters ≤, ≥, and ≠.

By default, the context has three variables x, y, and z. You should explicitly set
the variables if your situation should use something different. For example with

    Context()->variables->are(m => 'Real', n =>'Real');

Note that things like C<LinearRelation("1 = 1")> and C<<LinearRelation("1 < 5")>>
are allowed. These two examples are equivalent, but not equiivalent to
C<<LinearRelation("1 < 1")>> and C<<LinearRelation("1 > 5")>> which are equivalent
to each other.

There is one special context flag.

=over 

=item S<C<< standardForm >>>

This determines whether something like C<<LinearRelation("x+2 < y+z")>> will be
displayed as C<<x+2 < y+z>> or converted to standard form: C<<x-y-z < -2>>.
It is 0 by default.

=back 

There is one special method for LinearRelation objects.

=over

=item S<C<< $LR->check_at(point) >>>

This returns true or false depending on if the point satisfies the relation.
C<point> must be a Math Object Point, Vector, or ColumnVector; or simply be an
array reference. The number of entries in C<point> must match the number of
variables in the context.

=back

=cut

loadMacros('MathObjects.pl');

sub _parserLinearRelation_init { LinearRelation::Init() };    # don't reload this file

##################################################
#
#  Initialize the contexts and make the creator function.
#

package LinearRelation;
our @ISA = qw(Value::Formula);

sub Init {
	my $context = $main::context{LinearRelation} = Parser::Context->getCopy("Vector");
	$context->{name}                       = "LinearRelation";
	$context->{precedence}{LinearRelation} = $context->{precedence}{special};
	$context->{value}{LinearRelation}      = "LinearRelation";
	$context->{value}{Formula}             = "LinearRelation::formula";
	$context->parens->remove("<");
	$context->flags->set(standardForm => 0);
	$context->operators->add(
		'=' => {
			precedence    => .5,
			associativity => 'left',
			type          => 'bin',
			string        => ' = ',
			kind          => 'eq',
			eval          => sub { $_[0] == $_[1] },
			class         => 'LinearRelation::inequality',
			formulaClass  => "LinearRelation"
		},
		'<' => {
			precedence    => .5,
			associativity => 'left',
			type          => 'bin',
			string        => ' < ',
			kind          => 'lt',
			eval          => sub { $_[0] < $_[1] },
			class         => 'LinearRelation::inequality',
			formulaClass  => "LinearRelation"
		},
		'>' => {
			precedence    => .5,
			associativity => 'left',
			type          => 'bin',
			string        => ' > ',
			kind          => 'gt',
			reverse       => 'lt',
			eval          => sub { $_[0] > $_[1] },
			class         => 'LinearRelation::inequality',
			formulaClass  => "LinearRelation"
		},
		'<=' => {
			precedence    => .5,
			associativity => 'left',
			type          => 'bin',
			string        => ' <= ',
			TeX           => '\le ',
			kind          => "le",
			eval          => sub { $_[0] <= $_[1] },
			class         => 'LinearRelation::inequality',
			formulaClass  => "LinearRelation",
			alternatives  => [ '=<', "\x{2264}" ]
		},
		'>=' => {
			precedence    => .5,
			associativity => 'left',
			type          => 'bin',
			string        => ' >= ',
			TeX           => '\ge ',
			kind          => 'ge',
			reverse       => 'le',
			eval          => sub { $_[0] >= $_[1] },
			class         => 'LinearRelation::inequality',
			formulaClass  => "LinearRelation",
			alternatives  => [ '=>', "\x{2265}" ]
		},
		'!=' => {
			precedence    => .5,
			associativity => 'left',
			type          => 'bin',
			string        => ' != ',
			TeX           => '\ne ',
			kind          => 'ne',
			eval          => sub { $_[0] != $_[1] },
			class         => 'LinearRelation::inequality',
			formulaClass  => "LinearRelation",
			alternatives  => [ '<>', "\x{2260}" ]
		},
	);
	main::PG_restricted_eval('sub LinearRelation {Value->Package("LinearRelation()")->new(@_)}');
}

#    $R = LinearRelation("x + y + 2z <= 5");
#    $R = Formula("x + y + 2z <= 5");
#    $R = Compute("x + y + 2z <= 5");
#    $R = LinearRelation([1,2,1], [1,1,2], "<=");
#    $R = LinearRelation([1,2,1], 5, "<=");

sub new {
	my $self    = shift;
	my $class   = ref($self) || $self;
	my $context = (Value::isContext($_[0]) ? shift : $self->context);
	my ($N, $p, $bop) = @_;
	my $formula = "Value::Formula";
	return shift if scalar(@_) == 1 && ref($_[0]) eq 'LinearRelation';

	my ($plane, $d);

	if (defined $p) {
		# Make sure $N is a Vector
		$N = $context->Package("Vector")->new($context, $N);
		# Make sure $p is a Point or Real
		$p = $context->Package("Point")->new($context, $p) if (ref($p) eq 'ARRAY' || ref($p) eq 'Value::Vector');
		$p = $context->Package("Real")->new($context, $p)  if ref($p) ne 'Value::Point';
		# Constant on the right side
		$d = (ref($p) eq 'Value::Real') ? $p : $p . $N;
		my @terms;
		my $i = 0;
		for my $x ($context->variables->names) { push @terms, $N->{data}[ $i++ ]->string . $x }
		$bop      = '=' unless defined($bop);
		$leftside = $formula->new(join(' + ', @terms))->reduce(@_);
		$plane    = $formula->new($leftside . $bop . $d->string);
	} else {
		# Determine the normal vector and d value from the equation
		$plane = $N;
		$plane = $formula->new($context, $plane) unless Value::isValue($plane);
		$vars  = [ $context->variables->names ];
		Value::Error("Your formula doesn't look like a linear relation")
			unless $plane->type eq 'Relation';
		# Find the coefficients of the formula
		my $f = ($formula->new($context, $plane->{tree}{lop}) - $formula->new($context, $plane->{tree}{rop}))->reduce;
		my $F = $f->perlFunction(undef, [ @{$vars} ]);
		my @v = split('', '0' x scalar(@{$vars}));
		$d = -&$F(@v);
		my @coeff = (@v);
		for my $i (0 .. scalar(@v) - 1) { $v[$i] = 1; $coeff[$i] = &$F(@v) + $d; $v[$i] = 0 }
		$N = Value::Vector->new([@coeff]);
		$plane =
			$self->new($N, $d, $plane->{tree}{bop}, '-x=-y' => 0, '-x=n' => 0)
			->with(original_formula => $plane, original_formula_latex => $plane->TeX);
		# Check that the student's formula really is what we thought
		Value::Error("Your formula isn't a linear one")
			unless ($formula->new($plane->{tree}{lop}) - $formula->new($plane->{tree}{rop})) == $f;
	}
	$plane->{d} = $d;
	$plane->{N} = $N;
	return bless $plane, $class;
}

#
#  If the vectors are zero, check if true or false
#  If the vectors are non-zero, check if the equations are multiples of each other.
#
sub compare {
	my ($self, $l, $r) = Value::checkOpOrder(@_);
	$l = LinearRelation->new($l) unless ref($l) eq ref($self);
	$r = LinearRelation->new($r) unless ref($r) eq ref($self);
	my ($lN, $ld, $ltype, $lrev) = ($l->{N}, $l->{d}, $l->{tree}{def}{kind}, $l->{tree}{def}{reverse});
	my ($rN, $rd, $rtype, $rrev) = ($r->{N}, $r->{d}, $r->{tree}{def}{kind}, $r->{tree}{def}{reverse});

	#
	#  Outright true or false relations have no type yet, so give them one
	#
	my $zero = 0 * $lN;
	if (!$ltype) {
		$ltype = $l->check_at($zero) ? 'eq' : 'ne';
	}
	if (!$rtype) {
		$rtype = $r->check_at($zero) ? 'eq' : 'ne';
	}

	#
	#  Reverse inequalities to favor lt, le over gt, ge
	#
	($lN, $ld, $ltype) = (-$lN, -$ld, $lrev) if $lrev;
	($rN, $rd, $rtype) = (-$rN, -$rd, $rrev) if $rrev;

	#
	#  First, check if the type of inequality is the same.
	#  Then check if the dividing (hyper)plane is the right one.
	#
	return 1 unless $ltype eq $rtype;

	#
	#  Are both 0?
	#
	if ($lN == $zero && $rN == $zero) {
		my $ltruth = $l->check_at($zero);
		my $rtruth = $r->check_at($zero);
		return ($ltruth && $rtruth || !$ltruth && !$rtruth) ? 0 : 1;
	}

	# 'samedirection' is the second optional input to isParallel
	return $lN <=> $rN
		unless $lN->isParallel($rN, ($ltype ne 'eq' && $ltype ne 'ne'))
		;    # inequalities require same direction which is the second optional input to isParallel
	return $ld <=> $rd if $rd == 0 || $ld == 0;
	return $rd * $lN <=> $ld * $rN;
}

sub cmp_class {'a Linear Relation'}
sub showClass { shift->cmp_class }

sub cmp_defaults { (
	Value::Real::cmp_defaults(shift),
	ignoreInfinity => 0,    # report infinity as an error
) }

#
#  Only compare two relations
#
sub typeMatch {
	my ($self, $other, $ans) = @_;
	return ref($other) && $other->type eq 'Relation' unless ref($self);
	return ref($other) && $self->type eq $other->type;
}

sub string {
	my $self = shift;
	if (!$self->getFlag(standardForm) && defined $self->{original_formula}) {
		return $self->{original_formula};
	} else {
		return $self->SUPER::string;
	}
}

sub TeX {
	my $self = shift;
	if (!$self->getFlag(standardForm) && defined $self->{original_formula_latex}) {
		return $self->{original_formula_latex};
	} else {
		return $self->SUPER::TeX;
	}
}

sub check_at {
	my ($self, $point) = @_;
	if (ref($point) ne 'ARRAY') {
		$self->Error("check_at argument must be an array reference or MathObject Point or Vector.")
			unless ($point->type eq 'Point' || $point->type eq 'Vector');
	}
	my $context = $self->context;
	$point = $context->Package("Vector")->make($context, @{$point}) if (ref($point) eq 'ARRAY');
	my @variables = main::lex_sort(keys(%{ $context->{variables} }));
	my $n         = @variables;
	$self->Error("The context for this linear relation has $n variables: "
			. join(', ', @variables)
			. ", so a point to check at must also have $n entries")
		unless ($n == $point->value);
	return $self->eval(map { $variables[$_] => ($point->value)[$_] } (0 .. $#variables));
}

sub isConstant {
	my $self = shift;
	return 0 if $self->type eq "Relation";
	return $self->SUPER::isConstant;
}

#
#  We subclass BOP::equality so that we can assign a type using _check and
#  override the _eval method for relation operators
#

package LinearRelation::inequality;
our @ISA = qw(Parser::BOP::equality);

sub _check {
	my $self = shift;
	$self->SUPER::_check;
	$self->{type}       = Value::Type('Relation', 1);
	$self->{isConstant} = 0;
}

sub _eval {
	my $self    = shift;
	my $context = $self->context;
	return $context->Package("Real")->new($context, &{ $self->{def}{eval} }(@_) ? 1 : 0);
}

#
#  We use a special formula object to check if the formula is a
#  LinearRelation or not, and return the proper class.  This allows
#  lists of linear relations, for example.
#

package LinearRelation::formula;
our @ISA = ('Value::Formula');

sub new {
	my $self = shift;
	my $f    = Value::Formula->new(@_);
	return $f unless $f->{tree}{def}{formulaClass};
	return $f->{tree}{def}{formulaClass}->new($f);
}
1;
