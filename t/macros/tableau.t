use Test2::V0;

use Class::Accessor;
use Parser;
use PGcore;
use Value;

use lib 't/lib';
use Test::PG;


=head1 Tableau

Deep recursion error possibly due to "context" being a reference
to the original context variable.
I can't find a way to stop the recursion.
As a result Test::More::is_deeply( $A, $B )
becomes Test2::Tools::Compare::is( $A->string, $B->string )
I wrote a validator for the cases where you are trying to compare
a Value::Matrix with an array ref of values which doesn't have
a "string" method.  If someone can clean it up, future coders
will thank you.

Tests many of the functions provided by F<tableau.pl>

Removed the redefined WARN and DEBUG MESSAGES

Error Messages:

A context appears to have been destroyed without first calling release().
Based on $@ it does not look like an exception was thrown (this is not always
a reliable test)

=cut


loadMacros('tableau.pl', 'Value.pl');    #gives us Real() etc.

my %context = ();


sub Context { Parser::Context->current(\%context, @_) }
unless (%context && $context{current}) {
	# ^variable our %context
	%context = ();    # Locally defined contexts, including 'current' context
					  # ^uses Context
	Context();        # Initialize context (for persistent mod_perl)
}

Context("Matrix");

Context()->flags->set(
	zeroLevel    => 1E-5,
	zeroLevelTol => 1E-5
);


my $A = Real(.0000005);
my $B = Real(0);

subtest 'test zeroLevel tolerance' => sub {
	is($A->value, within($B->value, $B->getFlag('zeroLevel')), 'test zeroLevel tolerance');
	ok($A == $B, 'test zeroLevel tolerance with ok');

	my $real_object = object {
		prop isa => 'Value::Real';

		field data    => array { item 0 => match qr/\d/; };
		field context => D();

		call string => match qr/\d/;
		call TeX    => match qr/\d/;
	};

	is $A, $real_object, 'Zero is a Real';
	is $B, $real_object, 'Near-Zero is a Real';
};

my $money_total = 6000;
my $time_total  = 600;

# Bill
my $bill_money_commitment = 5000;    #dollars
my $bill_time_commitment  = 400;     # hours
my $bill_profit           = 4700;

# Steve
my $steve_money_commitment = 3000;
my $steve_time_commitment  = 500;
my $steve_profit           = 4500;

#### problem starts here:

# need error checking to make sure that tableau->new checks
# that inputs are matrices
my $ra_matrix = [
	[ -$bill_money_commitment,  -$bill_time_commitment,  -1, 0,  1, 0, 0, -$bill_profit ],
	[ -$steve_money_commitment, -$steve_time_commitment, 0,  -1, 0, 1, 0, -$steve_profit ],
	[ -$money_total,            -$time_total,            -1, -1, 0, 0, 1, 0 ]
];
my $a = Value::Matrix->new([
	[ -$bill_money_commitment,  -$bill_time_commitment,  -1, 0 ],
	[ -$steve_money_commitment, -$steve_time_commitment, 0,  -1 ]
]);
my $b = Value::Vector->new([ -$bill_profit, -$steve_profit ]);    # need vertical vector
my $c = Value::Vector->new([ $money_total, $time_total, 1, 1 ]);

my $tableau1 = Tableau->new(A => $a, b => $b, c => $c);

###############################################################

subtest 'Check mutators' => sub {
	is $tableau1, D(), 'tableau has been defined and loaded';
	is $tableau1, object { prop isa => 'Tableau' }, 'has type Tableau';
};

subtest 'test "close_enough_to_zero" subroutine' => sub {
	is $tableau1->close_enough_to_zero(0),     1, 'checking_close_enough to zero';
	is $tableau1->close_enough_to_zero(1e-9),  0, 'checking_close_enough to zero';
	is $tableau1->close_enough_to_zero(1e-5),  0, 'checking_close_enough to zero';
	is $tableau1->close_enough_to_zero(1e-10), 1, 'checking_NOT_close_enough to zero for 1e-10 ';
	note('sanity check 1e-10 vs 10**(-10):  ', 1e-10, ' ', 10**(-10));
	note(1.e-10);
	note(0.9999e-10);
	note(-0.9999e-10);
	is $tableau1->close_enough_to_zero(0.9999e-10), 1, 'checking_close_enough to zero for 0.9999e-10';

	is $tableau1->close_enough_to_zero(-0.9999e-10), 1, 'checking_close_enough to zero for -0.9999e-10';
};

subtest 'Basic test warmup' => sub {
	note("display stringified  \$tableau1: ", $tableau1, "\n");
	is ref($tableau1), "Tableau", "checking data type is Tableau";
	is $tableau1,
		'[[-5000,-400,-1,0,1,0,0,-4700],[-3000,-500,0,-1,0,1,0,-4500]]',
		'checking_stringification of tableau';

	is $tableau1->{m}, 2, 'number of constraints is 2';
};

subtest 'check data structure of tableau object' => sub {
	is($tableau1->{m}, 2, 'number of constraints is 2');
	is($tableau1->{n}, 4, 'number of variables is 4');
	is [ $tableau1->{m}, $tableau1->{n} ], [ $tableau1->{A}->dimensions ],
		'{m},{n} match dimensions of A';

	is $tableau1,
		object {
			field A => object {
				prop isa => 'Value::Matrix';
				call string => "$a";
				field context => D();
				field data => D();
			};
			field b => D();
			field c => D();
			etc();
		}, 'tableau attributes';

	# call the string method to avoid the circular refs
	is $tableau1->{A}->string, $a->string, 'Constraint matrix';
	is $tableau1->{b}->string, Matrix([$b])->transpose->string, 'Constraint constants is m by 1 matrix';
	is $tableau1->{c}->string, $c->string, 'Objective function constants';

	is $tableau1->{A}->string, $tableau1->A->string, '{A} original constraint matrix accessor';
	is $tableau1->{b}->string, $tableau1->b->string, '{b} original constraint constants accessor';
	is $tableau1->{c}->string, $tableau1->c->string, '{c} original objective function constants accessor';
};

my $test_constraint_matrix = Matrix($ra_matrix->[0], $ra_matrix->[1]);

subtest 'Current constraint matrix' => sub {
	is $tableau1->{current_constraint_matrix}->string,
		$test_constraint_matrix->string,
		'initialization of current_constraint_matrix';
	is
		$tableau1->{current_constraint_matrix}->string,
		$tableau1->current_constraint_matrix->string,
		'current_constraint_matrix accessor';
	is $tableau1->{current_b}->string, $tableau1->{b}->string,       'initialization of current_b';
	is $tableau1->{current_b}->string, $tableau1->current_b->string, 'current_b accessor';

	is [ $tableau1->current_b->dimensions ], [ 2, 1 ],               'dimensions of current_b';
};

subtest 'Objective row properties' => sub {
	my $obj_row_test = [ ((-$c)->value, 0, 0, 1, 0) ];

	for (my $i = 0; $i < 4; $i++) {
		is $tableau1->objective_row->[$i]->string, $obj_row_test->[$i]->string,
			'initialization of $tableau->{obj_row} (first half)';
	}
	is @{$tableau1->objective_row}[4..7],
		@{$obj_row_test}[4..7],
		'initialization of $tableau->{obj_row} (second half)';

	is $tableau1->{obj_row}, object { prop isa => 'Value::Matrix' }, '->{obj_row} has type Value::Matrix';
	is $tableau1->obj_row,   object { prop isa => 'Value::Matrix' }, '->obj_row has type Value::Matrix';
	is $tableau1->obj_row->string,   $tableau1->{obj_row}->string,   'verify mutator for {obj_row}';
	is ref $tableau1->objective_row, 'ARRAY',                        '->objective_row has type ARRAY';

    # the first 4 elements are Value::Real's and the remainder are perl scalars (numbers)
    # these are all mapped to array refs of scalars
    # should these use the validator( $compare_data ) pattern below?
    is  [ map { ref $_ ? $_->{data} : [$_] } $tableau1->objective_row->@* ],
        [ map { ref $_ ? $_->{data} : $_ } $tableau1->{obj_row}->value ],
        'access to {obj_row}';
    is  [ map { ref $_ ? $_->{data} : [$_] } $tableau1->objective_row->@* ],
        [ map { ref $_ ? $_->{data} : $_ } $tableau1->obj_row->value ],
        'objective_row is obj_row->value = ARRAY';
};

subtest 'Current tableau' => sub {
	is $tableau1->current_tableau,
		object { prop isa => 'Value::Matrix' },
		'-> current_tableau is Value::Matrix';
	is $tableau1->current_tableau,
		Matrix($ra_matrix)->string,
		'entire tableau including obj coeff row';

	is $tableau1->S, object { prop isa => 'Value::Matrix' }, 'slack variables are a Value::Matrix';
	is $tableau1->S, $tableau1->I($tableau1->m)->string,     'slack variables are identity matrix';
};

subtest 'Verify stringify subroutine' => sub {
	my $aref = [ [qw/1 2/], 7, [3, 0.4], [ (5, -.6, [8, 9])], 0, -1, [qw/-2 -3/]];
	my $expected_string = '[[1,2],7,[3,0.4],[5,-0.6,[8,9]],0,-1,[-2,-3]]';
	is stringify($aref), $expected_string, 'Local stringify recursively descends the refs';
};

# try out validator for mixed data types
my $compare_data = sub {
	my %params = @_;

	# postfix dereferencing stable in perl 5.24
	my ($g, $e) = map { ref $_ =~ /Value/ ? $_->copy : $_ } @{$params{got}};

	my ($got, $exp);
	$got = ref $g eq 'Value::Matrix' ? $g->string : stringify($g);
	$exp = ref $e eq 'Value::Matrix' ? $e->string : stringify($e);

	return is $got, $exp, 'Compare datastructures of MathObjects';
};

subtest 'Verify objective_row methods and properties' => sub {
	is [ $tableau1->obj_row, $tableau1->{obj_row} ],
		validator( $compare_data ),
		'verify mutator for {obj_row}';

	is [ $tableau1->objective_row, [$tableau1->obj_row->value] ],
		validator( $compare_data ),
		'objective_row is obj_row->value = ARRAY';
};

subtest 'test basis' => sub {
	is ref $tableau1->basis_columns, 'ARRAY',  '{basis_column} has type ARRAY';
	is [$tableau1->basis_columns,  [ 5, 6 ]], validator( $compare_data ), 'initialization of basis';
	is(
		ref($tableau1->current_basis_matrix),
		ref(Value::Matrix->I($tableau1->m)),
		'current_basis_matrix type is MathObjectMatrix'
	);
	is $tableau1->current_basis_matrix->string,
		Value::Matrix->I($tableau1->m)->string,
		'initialization of basis';
};


subtest 'change basis and test again' => sub {
	$tableau1->basis(2, 3);

	is ref $tableau1->basis_columns, 'ARRAY',  '{basis_column} has type ARRAY';
	is [$tableau1->basis_columns, [ 2, 3 ]], validator( $compare_data ), ' basis columns set to {2,3}';
	is(
		ref($tableau1->current_basis_matrix),
		ref($test_constraint_matrix->column_slice(2, 3)),
		'current_basis_matrix type is MathObjectMatrix'
	);
	is(
		$tableau1->current_basis_matrix->string,
		$test_constraint_matrix->column_slice(2, 3)->string,
		'basis_matrix for columns {2,3} is correct'
	);
	is $tableau1->basis(Set(2, 3))->string,  List([ 2, 3 ])->string, '->basis(Set(2,3))';
	is $tableau1->basis(List(2, 3))->string, List([ 2, 3 ])->string, '->basis(List(2,3))';
	is $tableau1->basis([ 2, 3 ])->string,   List([ 2, 3 ])->string, '->basis([2,3])';
};

subtest 'find basis column index corresponding to row index' => sub {
	# and value of the basis coefficient

	$tableau1->basis(5, 6);
	note("\nbasis is",                     $tableau1->basis(5, 6));
	note(print $tableau1->current_tableau, "\n");
	is [ $tableau1->find_leaving_column(1) ], [ 5, 1 ],
		'find_leaving_column returns [col_index, pivot_value] ';
	is [ $tableau1->find_leaving_column(2) ], [ 6, 1 ],
		'find_leaving_column returns [col_index, pivot_value] ';

	is $tableau1->find_next_basis_from_pivot(1, 2)->string, Set(2, 6)->string,
		'find next basis from pivot (1,2)';
	is $tableau1->find_next_basis_from_pivot(1, 3)->string, Set(3, 6)->string,
		'find next basis from pivot (1,3)';
	is $tableau1->find_next_basis_from_pivot(2, 1)->string, Set(1, 5)->string,
		'find next basis from pivot (2,1)';
	is $tableau1->find_next_basis_from_pivot(1, 1)->string, Set(1, 6)->string,
		'find next basis from pivot (1,1)';

	like(
		dies { $tableau1->find_next_basis_from_pivot(2, 5)  },
		qr/pivot point should not be in a basis column/,
		"can't pivot in basis column (2,5)"
	);    # probably shouldn't be doing this.
	like(
		dies { $tableau1->find_next_basis_from_pivot(1, 6) },
		qr/pivot point should not be in a basis column/,
		"can't pivot in basis column (2,6)"
	);    # probably shouldn't be doing this.

	is $tableau1->find_next_basis_from_pivot(2, 1)->string, Set(1, 5)->string,
		'find next basis from pivot (2,1)';
	like(
		dies { $tableau1->find_next_basis_from_pivot(2, 6) },
		qr/pivot point should not be in a basis column/,
		"can't pivot in basis column (2,6)"
	);    # probably shouldn't be doing this.
};

subtest 'find another basis (2,3)' => sub {
	$tableau1->basis(2, 3);
	note("\nbasis is",                     $tableau1->basis());
	note(print $tableau1->current_tableau, "\n");

	is [ $tableau1->find_leaving_column(1) ], [ 2, 500 ],
		'find_leaving_column returns [col_index, pivot_value] ';
	is [ $tableau1->find_leaving_column(2) ], [ 3, 500 ],
		'find_leaving_column returns [col_index, pivot_value] ';

	like(
		dies { $tableau1->find_next_basis_from_pivot(1, 2) },
		qr/pivot point should not be in a basis column/,
		"can't pivot in basis column (1,2)"
	);    # probably shouldn't be doing this either.
	like(
		dies { $tableau1->find_next_basis_from_pivot(1, 3) },
		qr/pivot point should not be in a basis column/,
		"can't pivot in basis column (1,3)"
	);    # probably shouldn't be doing this.

	is $tableau1->find_next_basis_from_pivot(2, 1)->string, Set(1, 2)->string,
		'find next basis from pivot (2,1)';
	is $tableau1->find_next_basis_from_pivot(1, 1)->string, Set(1, 3)->string,
		'find next basis from pivot (1,1)';
};

subtest 'find next short cut pivots' => sub {
	$tableau1->basis(5, 6);
	note("\nbasis is ",              $tableau1->basis());
	note($tableau1->current_tableau, "\n");

	# ($row_index, $value, $feasible_point) = $self->find_short_cut_row()

	is [ $tableau1->find_short_cut_row() ],     [ 1, -4700, 0 ], 'row 1';
	is [ $tableau1->find_short_cut_column(1) ], [ 1, -5000, 0 ], 'column 1 ';
	is [ $tableau1->next_short_cut_pivot() ],   [ 1, 1, 0, 0 ],  'pivot (1,1)';
	is [ $tableau1->next_short_cut_basis() ],   [ 1, 6, undef ], 'new basis {1,6} continue';

	$tableau1->current_tableau(1, 6);
	note($tableau1->current_tableau);

	is [ $tableau1->find_short_cut_row ],
		[ 2, Value::Real->new(-8.4E+06)->string, 0 ], 'find short cut row';
	is [ $tableau1->find_short_cut_column(2) ],
		[ 2, Value::Real->new(-1.3E+06)->string, 0 ], 'find short cut col 2 ';
	is [ $tableau1->next_short_cut_pivot() ], [ 2, 2, 0, 0 ],  'pivot (2,2)';
	is [ $tableau1->next_short_cut_basis() ], [ 1, 2, undef ], 'new basis {1,2} continue';

	$tableau1->current_tableau(1, 2);
	note($tableau1->current_tableau);

	is [ $tableau1->next_short_cut_pivot() ], [ undef, undef, 1, 0 ], 'feasible point found';
	is(
		[ $tableau1->next_short_cut_basis() ],
		[ 1, 2, 'feasible_point' ],
		'all constraints positive at basis {1,2} --start phase2'
	);
	is [ $tableau1->find_pivot_column('max') ], [ 3, Value::Real->new(-100000)->string, 0 ],      'col 3';
	is [ $tableau1->find_pivot_row(3) ],        [ 1, Value::Real->new(550000 / 500)->string, 0 ], 'row 1';
	is [ $tableau1->find_next_pivot('max') ],   [ 1, 3, 0, 0 ],  'pivot (1,3)';
	is [ $tableau1->find_next_basis('max') ],   [ 2, 3, undef ], 'new basis {2,3} continue';

	$tableau1->current_tableau(2, 3);
	note($tableau1->current_tableau);
	is [ $tableau1->find_pivot_column('max') ], [ 4, Value::Real->new(-300)->string, 0 ], 'col 4';
	is [ $tableau1->find_pivot_row(4) ], [ 1, 4500, 0 ], 'row 2';

	is [ $tableau1->find_next_pivot('max') ], [ 1, 4, 0, 0 ], 'pivot 1,4';
	is [ $tableau1->find_next_basis('max') ], [ 3, 4, undef ], 'new basis {3,4} continue';

	$tableau1->current_tableau(3, 4);
	note($tableau1->current_tableau);
	is [ $tableau1->find_pivot_column('max') ], [ 5, Value::Real->new(-1)->string, 0 ], 'col 5';
	is [ $tableau1->find_pivot_row(5) ], [ undef, undef, 1 ], 'row 2';

	is [ $tableau1->find_next_pivot('max') ], [ undef, 5, 0, 1 ],    'unbounded -- no pivot';
	is [ $tableau1->find_next_basis('max') ], [ 3, 4, 'unbounded' ], 'basis 3,4 unbounded';
};
# note that the column is returned from find_next_pivot so one can find a certificate
# of unboundedness (can return a line going off to infinity)

# # this is ok -- we're looking at the dual of the bill and steve problem
# # and the original test was to minimize it not to maximize it
# # recheck the original problem with websim!!!!
#
# # regularize the output for row and column definitions if one of the flags is set.
# # can we always set those to undefined?
# # can we change the flag notification to
# # "unbounded, feasible_point, infeasible_tableau, optimal"?
# # it might be easier to remember.
#

subtest 'reset tableau to feasible point and try to minimize it for phase2' => sub {
	$tableau1->current_tableau(1, 2);
	note($tableau1->current_tableau);
	is [ $tableau1->next_short_cut_pivot() ], [ undef, undef, 1, 0 ], 'feasible point found';
	is(
		[ $tableau1->next_short_cut_basis() ],
		[ 1, 2, 'feasible_point' ],
		'all constraints positive at basis {1,2} --start phase2'
	);

	is [ $tableau1->find_pivot_column('min') ], [ undef, undef, 1 ], 'all neg coeff';
	is [ $tableau1->find_pivot_row(1) ],
		[ 1, Value::Real->new(550000 / 1300000)->string, 0 ],
		'row 1';
	is [ $tableau1->find_next_pivot('min') ], [ undef, undef, 1, 0 ], 'optimum';
	is [ $tableau1->find_next_basis('min') ], [ 1, 2, 'optimum' ],    'optimum';

	is(
		$tableau1->statevars,    # round off errors
		[ 550000 / 1300000, 8400000 / 1300000, 0, 0, 0, 0, 8.339999999999999E9 / 1300000 ],
		'state variables'
	);

	is $tableau1->align,    'cccc|cc|c|c',               'check align';
	is $tableau1->toplevel, [qw(x1 x2 x3 x4 x5 x6 z b)], 'check toplevel';

	# diag($tableau1->align);
	# diag(join(q{ } , @{$tableau1->toplevel}));
};


done_testing();

sub stringify {
	my $arrayref = shift;
	warn "Not an array ref [$arrayref]" unless ref $arrayref eq 'ARRAY';
	return sprintf("[%s]",
		join(',', map { my $s = $_; ref $s eq 'ARRAY' ? stringify($s) : $s } @{$arrayref})
	);
}
