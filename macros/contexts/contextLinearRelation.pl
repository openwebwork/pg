################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2022 The WeBWorK Project, https://github.com/openwebwork
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

contextLinearRelation.pl - Implement linear relations.

=head1 DESCRIPTION

This gives a context C<LinearRelation> that implements an implicit linear relations
MathObject using =, <, >, <=, >=, or !=. Activate the context with:

    Context("LinearRelation");

Use C<LinearRelation(formula)>, C<Formula(formula)>, or C<Compute(formula)> to 
to create a LinearRelation object using a string formula. Alternatively, use
C<LinearRelation(point,vector,sign> where C<point> and C<vector> are array references
and C<sign> is one of the (in)equality symbols.

Usage examples:

    $R = LinearRelation("x +y + 2z <= 5");
    $R = Formula("x +y + 2z <= 5");
    $R = Compute("x +y + 2z <= 5");
    $R = LinearRelation([1,2,1], [1,1,2], "<=");

Sloppy inequality signs (=<, =>, <>) may be used.

If C<$pg{specialPGEnvironmentVars}{parseAlternatives}> is true in your configuration,
then you may also work directly with the characters ≤, ≥, and ≠.  

By default, the context has three variables x, y, and z. You should explicitly set
the variables if your situation should use something different. For example with

    Context()->variables->are(m => 'Real', n =>'Real');

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
C<point> must be a MathObject Point, Vector, or ColumnVector; or simply be an
array reference. The number of entries in C<point> must match the number of
variables in the context.

=back

=cut

loadMacros('MathObjects.pl');

sub _contextLinearRelation_init { LinearRelation::Init() };    # don't reload this file

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
			class         => 'LinearRelation::inequality',
			formulaClass  => "LinearRelation"
		},

		'<' => {
			precedence    => .5,
			associativity => 'left',
			type          => 'bin',
			string        => ' < ',
			kind          => 'lt',
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
			class         => 'LinearRelation::inequality',
			formulaClass  => "LinearRelation",
			alternatives  => ["\x{2264}"]
		},
		'=<' => {
			precedence    => .5,
			associativity => 'left',
			type          => 'bin',
			string        => ' <= ',
			TeX           => '\le ',
			kind          => "le",
			class         => 'LinearRelation::inequality',
			formulaClass  => "LinearRelation"
		},

		'>=' => {
			precedence    => .5,
			associativity => 'left',
			type          => 'bin',
			string        => ' >= ',
			TeX           => '\ge ',
			kind          => 'ge',
			reverse       => 'le',
			class         => 'LinearRelation::inequality',
			formulaClass  => "LinearRelation",
			alternatives  => ["\x{2265}"]
		},
		'=>' => {
			precedence    => .5,
			associativity => 'left',
			type          => 'bin',
			string        => ' >= ',
			TeX           => '\ge ',
			kind          => 'ge',
			reverse       => 'le',
			class         => 'LinearRelation::inequality',
			formulaClass  => "LinearRelation"
		},

		'!=' => {
			precedence    => .5,
			associativity => 'left',
			type          => 'bin',
			string        => ' != ',
			TeX           => '\ne ',
			kind          => 'ne',
			reverse       => 'ne',
			class         => 'LinearRelation::inequality',
			formulaClass  => "LinearRelation",
			alternatives  => ["\x{2260}"]
		},
		'<>' => {
			precedence    => .5,
			associativity => 'left',
			type          => 'bin',
			string        => ' != ',
			TeX           => '\ne ',
			kind          => 'ne',
			reverse       => 'ne',
			class         => 'LinearRelation::inequality',
			formulaClass  => "LinearRelation"
		}
	);
	main::PG_restricted_eval('sub LinearRelation {Value->Package("LinearRelation()")->new(@_)}');
}

sub new {
	my $self    = shift;
	my $class   = ref($self) || $self;
	my $context = (Value::isContext($_[0]) ? shift : $self->context);
	my $formula = "Value::Formula";
	return shift if scalar(@_) == 1 && ref($_[0]) eq 'LinearRelation';
	$_[0] = $context->Package("Point")->new($context, $_[0])  if ref($_[0]) eq 'ARRAY';
	$_[1] = $context->Package("Vector")->new($context, $_[1]) if ref($_[1]) eq 'ARRAY';

	my ($p, $N, $plane, $vars, $d);
	if (scalar(@_) >= 2 && Value::classMatch($_[0], 'Point', 'Vector') && Value::classMatch($_[1], 'Vector')
		|| Value::isRealNumber($_[1]))
	{
		#
		# Make a plane from a point and a vector and optionally a
		# symbol <= or = or =>,
		# e.g. LinearRelation($point, $vector, '<=');
		# or from a list of coefficients and the constant
		# e.g. LinearRelation($dist, [3,5,6], '<=')
		# one can optionally add new Context
		# variables ($point, $vector, '<=',[qw(a1,a2,a3)])
		$p = shift;
		$N = shift;
		my $bop = shift || "=";
		if (Value::classMatch($N, 'Vector')) {
			$d = $p . $N;
		} else {
			$d = $context->Package("Real")->make($context, $N);
			$N = $context->Package("Vector")->new($context, $p);
		}
		$vars = shift || [ $context->variables->names ];
		$vars = [$vars] unless ref($vars) eq 'ARRAY';
		my @terms = ();
		my $i     = 0;
		foreach my $x (@{$vars}) { push @terms, $N->{data}[ $i++ ]->string . $x }
		$plane = $formula->new(join(' + ', @terms) . $bop . $d->string)->reduce(@_);
	} else {
		#
		#  Determine the normal vector and d value from the equation
		#
		$plane = shift;
		$plane = $formula->new($context, $plane) unless Value::isValue($plane);
		$vars  = shift || [ $context->variables->names ];
		$vars  = [$vars] unless ref($vars) eq 'ARRAY';
		Value::Error("Your formula doesn't look like a linear inequality")
			unless $plane->type eq 'Equality';
		#
		#  Find the coefficients of the formula
		#
		my $f = ($formula->new($context, $plane->{tree}{lop}) - $formula->new($context, $plane->{tree}{rop}))->reduce;
		my $F = $f->perlFunction(undef, [ @{$vars} ]);
		my @v = split('', '0' x scalar(@{$vars}));
		$d = -&$F(@v);
		my @coeff = (@v);
		foreach my $i (0 .. scalar(@v) - 1) { $v[$i] = 1; $coeff[$i] = &$F(@v) + $d; $v[$i] = 0 }
		$N = Value::Vector->new([@coeff]);
		$plane =
			$self->new($N, $d, $plane->{tree}{bop}, $vars, '-x=-y' => 0, '-x=n' => 0)
			->with(original_formula => $plane, original_formula_latex => $plane->TeX);
		#
		#  Check that the student's formula really is what we thought
		#
		Value::Error("Your formula isn't a linear one")
			unless ($formula->new($plane->{tree}{lop}) - $formula->new($plane->{tree}{rop})) == $f;
	}
	Value::Error("The equation of a linear inequality must be non-zero somewhere")
		if ($N->norm == 0);
	$plane->{d} = $d;
	$plane->{N} = $N;
	return bless $plane, $class;
}

#
#  We already know the vectors are non-zero, so check
#  if the equations are multiples of each other.
#
sub compare {
	my ($self, $l, $r) = Value::checkOpOrder(@_);
	$l = new LinearRelation($l) unless ref($l) eq ref($self);
	$r = new LinearRelation($r) unless ref($r) eq ref($self);
	my ($lN, $ld, $ltype, $lrev) = ($l->{N}, $l->{d}, $l->{tree}{def}{kind}, $l->{tree}{def}{reverse});
	my ($rN, $rd, $rtype, $rrev) = ($r->{N}, $r->{d}, $r->{tree}{def}{kind}, $r->{tree}{def}{reverse});

	#
	#  Reverse inequalities if they face the wrong way
	#
	($lN, $ld, $ltype) = (-$lN, -$ld, $lrev) if $lrev;
	($rN, $rd, $rtype) = (-$rN, -$rd, $rrev) if $rrev;

	#
	#  First, check if the type of inequality is the same.
	#  Then check if the dividing (hyper)plane is the right one.
	#
	return 1 unless $ltype eq $rtype;
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
#  Only compare two equalities
#
sub typeMatch {
	my $self  = shift;
	my $other = shift;
	my $ans   = shift;
	return ref($other) && $other->type eq 'Equality' unless ref($self);
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

#
#  We subclass BOP::equality so that we can give a warning about
#  things like 1 = 3, and compute the values of inequalities.
#

package LinearRelation::inequality;
our @ISA = qw(Parser::BOP::equality);

sub _check {
	my $self = shift;
	$self->SUPER::_check;
	$self->Error("An implicit equation can't be constant on both sides")
		if $self->{lop}{isConstant} && $self->{rop}{isConstant};
}

sub _eval {
	my $self = shift;
	my ($l, $r) = @_;
	{
		eq => ($l == $r),
		lt => ($l < $r),
		le => ($l <= $r),
		gt => ($l > $r),
		ge => ($l >= $r),
		ne => ($l != $r)
	}->{ $self->{def}{kind} };
}

#
#  We use a special formula object to check if the formula is a
#  LineRelation or not, and return the proper class.  This allows
#  lists of linear equalities, for example.
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
