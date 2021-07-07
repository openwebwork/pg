################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2018 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader$
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

PGfunctionevaluators.pl - Macros that generate function answer evaluators.

=head1 SYNOPSIS

	ANS(fun_cmp($answer_or_answer_array_ref, %options));

	ANS(function_cmp($correctEqn, $var, $llimit, $ulimit, $relTol, $numPoints, $zeroLevel,
	                 $zeroLevelTol));
	ANS(function_cmp_up_to_constant($correctEqn, $var, $llimit, $ulimit, $relpercentTol, 
	                                $numOfPoints, $maxConstantOfIntegration, $zeroLevel, 
	                                $zeroLevelTol));
	ANS(function_cmp_abs($correctFunction, $var, $llimit, $ulimit, $absTol, $numOfPoints));
	ANS(function_cmp_up_to_constant_abs($correctFunction, $var, $llimit, $ulimit,
	                                    $absTol, $numOfPoints, $maxConstantOfIntegration));

=head1 DESCRIPTION

Function answer evaluators take in a function, compare it numerically to a
correct function, and return a score. They can require an exactly equivalent
function, or one that is equal up to a constant. They can accept or reject an
answer based on specified tolerances for numerical deviation.

The general function answer evaluator is fun_cmp(). It takes a hash of named
options as parameters. There are also several specific function_cmp_*() answer
evaluators for use in common situations which feature a simplified syntax.

=head2 MathObjects and answer evaluators

The MathObjects system provides a Formula->cmp() method that produce answer
evaluators for function comparisons. fun_cmp() has been rewritten to use
Formula->cmp() to produce the answer evaluator. It is recommended that you use
the Formula object's cmp() method directly if possible.

=cut

BEGIN { be_strict() }

# Until we get the PG cacheing business sorted out, we need to use
# PG_restricted_eval to get the correct values for some(?) PG environment
# variables. We do this once here and place the values in lexicals for later
# access.
my $Context;
my $functAbsTolDefault;
my $functLLimitDefault;
my $functMaxConstantOfIntegration;
my $functNumOfPoints;
my $functRelPercentTolDefault;
my $functULimitDefault;
my $functVarDefault;
my $functZeroLevelDefault;
my $functZeroLevelTolDefault;
my $inputs_ref;
my $useOldAnswerMacros;
my $user_context;
sub _PGfunctionevaluators_init {
	$functAbsTolDefault            = PG_restricted_eval(q/$envir{functAbsTolDefault}/);
	$functLLimitDefault            = PG_restricted_eval(q/$envir{functLLimitDefault}/);
	$functMaxConstantOfIntegration = PG_restricted_eval(q/$envir{functMaxConstantOfIntegration}/);
	$functNumOfPoints              = PG_restricted_eval(q/$envir{functNumOfPoints}/);
	$functRelPercentTolDefault     = PG_restricted_eval(q/$envir{functRelPercentTolDefault}/);
	$functULimitDefault            = PG_restricted_eval(q/$envir{functULimitDefault}/);
	$functVarDefault               = PG_restricted_eval(q/$envir{functVarDefault}/);
	$functZeroLevelDefault         = PG_restricted_eval(q/$envir{functZeroLevelDefault}/);
	$functZeroLevelTolDefault      = PG_restricted_eval(q/$envir{functZeroLevelTolDefault}/);
	$inputs_ref                    = PG_restricted_eval(q/$envir{inputs_ref}/);
	$useOldAnswerMacros            = PG_restricted_eval(q/$envir{useOldAnswerMacros}/);
	unless ($useOldAnswerMacros) {
		$user_context = PG_restricted_eval(q/\%context/);
		$Context = sub { Parser::Context->current($user_context, @_) };
	}
}

=head1 fun_cmp

	ANS(fun_cmp($answer_or_answer_array_ref, %options));

Compares a function or a list of functions, using a named hash of options to set
parameters. This can make for more readable code than using the function_cmp()
style, but some people find one or the other easier to remember.

=head2 Options

$answer_or_answer_array_ref can either be a string scalar representing the
correct formula or a reference to an array of string scalars. If multiple
formulas are provided, fun_cmp() will return a list of answer evaluators, one
for each answer specified. The answer can contain functions, pi, e, and
arithmetic operations. However, the correct answer string follows a slightly
stricter syntax than student answers; specifically, there is no implicit
multiplication. So the correct answer must be "3*x" rather than "3 x". Students
can still enter "3 x".

%options is a hash containing options that affect the way the comparison is
performed. All hash items are optional. Allowed options are:

=over

=item mode

This determines the evaluation mode. The recognized modes are:

=over

=item std (default)

Function must match exactly.

=item antider

Function must match up to a constant.

=back

=item tol

An absolute tolerance value. When the student and correct functions are
evaluated,  the result for each evaluation point must be within a fixed distance
from the correct answer to qualify. For example, an absolute tolerance of 5
means that any result which is +-5 of the correct answer qualifies as correct.
abstol is accepted as a synonym for tol.

=item relTol

A relative tolerance. Relative tolerances are given in percentages. A relative
tolerance of 1 indicates that when the student's function are evaluated, the
result of evaluation at each point must be within within 1% of the correct
answer to qualify as correct. In other words, a student answer is correct when

	abs(studentAnswer - correctAnswer) <= abs(.01*relTol*correctAnswer)

tol and relTol are mutually exclusive. reltol is also accpeted as a synonym for
relTol.

=item zeroLevel, zeroLevelTol

zeroLevel and zeroLevelTol specify a alternative absolute tolerance to use when
the correct answer is very close to zero.

If the correct answer has an absolute value less than or equal to zeroLevel,
then the student answer must be, in absolute terms, within zeroLevelTol of
correctAnswer, i.e.,

	abs(studentAnswer - correctAnswer) <= zeroLevelTol

In other words, if the correct answer is very near zero, an absolute tolerance
will be used. One must do this to handle floating point answers very near zero,
because of the inaccuracy of floating point arithmetic. However, the default
values are almost always adequate.

=item var

The var parameter can contain a number, a string, or a reference to an array of
variable names. If it contains a number, the variables are named automatically
as follows:

	 var | variables used     
	-----+--------------------
	 1   | x                  
	 2   | x, y               
	 3   | x, y, z            
	 4+  | x_1, x_2, x_3, ... 

If the var parameter contains a reference to an array of variable names, then
the number of variables is determined by the number of items in the array. For example:

	var=>['r','s','t']

If the var parameter contains a string, the string is used as the name of a
single variable. Hence, the following are equivalent:

	var=>['t']
	var=>'t'

vars is recognied as a synonym for var. The default is a single variable, x.

=item limits

Limits are specified with the limits parameter. If you specify limits for one
variable, you must specify them for all variables. The limit parameter must be a
reference to an array of arrays of the form C<[$lower_limit. $upper_limit]>,
each array corresponding to the lower and upper endpoints of the (half-open)
domain of one variable. For example,

	vars=>2, limits=>[[0,2], [-3,8]]

would cause x to be evaluated in [0,2) and y to be evaluated in [-3,8). If only
one variable is being used, you can write either:

	limits => [[0,3]]
	limits => [0,3]

domain is recognized as a synonym for limits.

=item test_points

In some cases, the problem writer may want to specify the points used to check a
particular function.  For example, if you want to use only integer values, they
can be specified.  With one variable, either of these two forms work:

	test_points=>[1,4,5,6]
	test_points=>[[1,4,5,6]]

With more variables, specify the list for the first variable, then the second,
and so on:

	vars=>['x','y'], test_points=>[[1,4,5],[7,14,29]]".

If the problem writer wants random values which need to meet some special
restrictions (such as being integers), they can be generated in the problem:

	test_points=>[random(1,50), random(1,50), random(1,50), random(1,50)]

Note that test_points should not be used for function checks which involve
parameters (either explicitly given by "params", or as antiderivatives).


=item numPoints

The number of sample points to use when evaluating the function.

=item maxConstantOfIntegration

Maximum size for the constant of integration (in antider mode).

=item params

A reference to an array of "free" parameters which can be used to adapt the
correct answer to the submitted answer. (e.g. ['c'] for a constant of
integration in the answer x^3/3+c.

=item debug

If set to one, extra debugging information will be output.

=back

=head2 Examples

	# standard compare, variable is x
	fun_cmp("3*x");

	# standard compare, defaults used for all three functions
	fun_cmp(["3*x", "4*x+3", "3*x**2"]);

	# standard compare, variable is t
	fun_cmp("3*t", var=>'t');

	# x, y and z are the variables
	fun_cmp("5*x*y*z", var=>3);

	# student answer must match up to constant (i.e., 5x+C)
	fun_cmp("5*x", mode=>'antider');

	# x is evaluated in [0,2), y in [5,7)
	fun_cmp(["3*x*y", "4*x*y"], limits=>[[0,2], [5,7]]);

=cut

sub fun_cmp {
	my $correctAnswer =	shift @_;
	my %opt	          = @_;

    assign_option_aliases( \%opt,
				'vars'		=>	'var',    # set the standard option 'var' to the one specified as vars
    			'domain'	=>	'limits', # set the standard option 'limits' to the one specified as domain
    			'reltol'    =>  'relTol',
    			'param'		=>  'params',
    );

    set_default_options(	\%opt,
				'var'					=>	$functVarDefault,
	       		'params'				=>	[],
				'limits'				=>	[[$functLLimitDefault, $functULimitDefault]],
				'test_points'   => undef,
				'mode'					=>	'std',
				'tolType'				=>  	(defined($opt{tol}) ) ? 'absolute' : 'relative',
				'tol'					=>	.01, # default mode should be relative, to obtain this tol must not be defined
	       		'relTol'				=>	$functRelPercentTolDefault,
				'numPoints'				=>	$functNumOfPoints,
				'maxConstantOfIntegration'	=>	$functMaxConstantOfIntegration,
				'zeroLevel'				=>	$functZeroLevelDefault,
				'zeroLevelTol'			=>	$functZeroLevelTolDefault,
	       		'debug'					=>	0,
	       		'diagnostics'                           =>      undef,
     );

    # allow var => 'x' as an abbreviation for var => ['x']
	my %out_options = %opt;
	unless ( ref($out_options{var}) eq 'ARRAY' || $out_options{var} =~ m/^\d+$/) {
		$out_options{var} = [$out_options{var}];
	}
	# allow params => 'c' as an abbreviation for params => ['c']
	unless ( ref($out_options{params}) eq 'ARRAY' ) {
		$out_options{params} = [$out_options{params}];
	}
	my ($tolType, $tol);
   	if ($out_options{tolType} eq 'absolute') {
		$tolType = 'absolute';
		$tol = $out_options{'tol'};
		delete($out_options{'relTol'}) if exists( $out_options{'relTol'} );
	} else {
		$tolType = 'relative';
		$tol = $out_options{'relTol'};
		delete($out_options{'tol'}) if exists( $out_options{'tol'} );
	}

	my @output_list	= ();
	# thread over lists
	my @ans_list = ();

	if ( ref($correctAnswer) eq 'ARRAY' ) {
		@ans_list =	@{$correctAnswer};
	}
	else {
		push( @ans_list, $correctAnswer );
	}

	# produce answer evaluators
	foreach	my $ans	(@ans_list)	{
		push(@output_list,
			FUNCTION_CMP(
					'correctEqn'		=>	$ans,
					'var'				=>	$out_options{'var'},
					'limits'			=>	$out_options{'limits'},
					'tolerance'			=>	$tol,
					'tolType'			=>	$tolType,
					'numPoints'			=>	$out_options{'numPoints'},
					'test_points' =>  $out_options{'test_points'},
					'mode'				=>	$out_options{'mode'},
					'maxConstantOfIntegration'	=>	$out_options{'maxConstantOfIntegration'},
					'zeroLevel'			=>	$out_options{'zeroLevel'},
					'zeroLevelTol'		=>	$out_options{'zeroLevelTol'},
					'params'			=>	$out_options{'params'},
					'debug'				=>	$out_options{'debug'},
				        'diagnostics'  		       	=> 	$out_options{'diagnostics'} ,
			),
		);
	}

	return (wantarray) ? @output_list : $output_list[0];
}

=head1 Single-variable Function Comparisons

There are four single-variable function answer evaluators: "normal," absolute
tolerance, antiderivative, and antiderivative with absolute tolerance. All
parameters (other than the correct equation) are optional.

=head2 function_cmp

	ANS(function_cmp($correctEqn, $var, $llimit, $ulimit, $relTol, $numPoints,
	                 $zeroLevel, $zeroLevelTol));

function_cmp() uses standard comparison and relative tolerance. It takes a
string representing a single-variable function and compares the student answer
to that function numerically. $var, $relTol, $numPoints, $zeroLevel, and 
$zeroLevelTol are equivalent to the identically-named options to fun_cmp(),
above. $llimit and $ulimit are combined to form the value of limits above.

=cut

sub function_cmp {
	my ($correctEqn,$var,$llimit,$ulimit,$relPercentTol,$numPoints,$zeroLevel,$zeroLevelTol) = @_;

	if ( (scalar(@_) == 3) or (scalar(@_) > 8) or (scalar(@_) == 0) ) {
		function_invalid_params( $correctEqn );
	}
	else {
		FUNCTION_CMP(	'correctEqn'					=>	$correctEqn,
				'var'						=>	$var,
				'limits'					=>	[$llimit, $ulimit],
				'tolerance'					=>	$relPercentTol,
				'tolType'					=>	'relative',
				'numPoints'					=>	$numPoints,
				'mode'						=>	'std',
				'maxConstantOfIntegration'			=>	0,
				'zeroLevel'					=>	$zeroLevel,
				'zeroLevelTol'					=>	$zeroLevelTol
					);
	}
}

=head2 function_cmp_up_to_constant

	ANS(function_cmp_up_to_constant($correctEqn, $var, $llimit, $ulimit,
	                                $relpercentTol, $numOfPoints,
	                                $maxConstantOfIntegration, $zeroLevel,
	                                $zeroLevelTol));

function_cmp_up_to_constant() uses antiderivative compare and relative
tolerance. All but the first argument are optional. All options work exactly
like function_cmp(), except of course $maxConstantOfIntegration. It will accept
as correct any function which differs from $correctEqn by at most a constant;
that is, if

	$studentEqn = $correctEqn + C, where C <= $maxConstantOfIntegration

the answer is correct.

=cut

sub function_cmp_up_to_constant {	## for antiderivative problems
	my ($correctEqn,$var,$llimit,$ulimit,$relPercentTol,$numPoints,$maxConstantOfIntegration,$zeroLevel,$zeroLevelTol) = @_;

	if ( (scalar(@_) == 3) or (scalar(@_) > 9) or (scalar(@_) == 0) ) {
		function_invalid_params( $correctEqn );
	}
	else {
		FUNCTION_CMP(	'correctEqn'					=>	$correctEqn,
				'var'						=>	$var,
				'limits'					=>	[$llimit, $ulimit],
				'tolerance'					=>	$relPercentTol,
				'tolType'					=>	'relative',
				'numPoints'					=>	$numPoints,
				'mode'						=>	'antider',
				'maxConstantOfIntegration'			=>	$maxConstantOfIntegration,
				'zeroLevel'					=>	$zeroLevel,
				'zeroLevelTol'					=>	$zeroLevelTol
	        );
	}
}

=head2 function_cmp_abs

	ANS(function_cmp_abs($correctFunction, $var, $llimit, $ulimit, $absTol, $numOfPoints));

function_cmp_abs() uses standard compare and absolute tolerance. All but the
first argument are optional. $absTol defines the absolute tolerance value. See
the corresponding option to fun_cmp(), above. All other options work exactly as
for function_cmp().

=cut

sub function_cmp_abs {			## similar to function_cmp but uses	absolute tolerance
	my ($correctEqn,$var,$llimit,$ulimit,$absTol,$numPoints) = @_;

	if ( (scalar(@_) == 3) or (scalar(@_) > 6) or (scalar(@_) == 0) ) {
		function_invalid_params( $correctEqn );
	}
	else {
		FUNCTION_CMP(	'correctEqn'			=>	$correctEqn,
				'var'				=>	$var,
				'limits'			=>	[$llimit, $ulimit],
				'tolerance'			=>	$absTol,
				'tolType'			=>	'absolute',
				'numPoints'			=>	$numPoints,
				'mode'				=>	'std',
				'maxConstantOfIntegration'	=>	0,
				'zeroLevel'			=>	0,
				'zeroLevelTol'			=>	0
		);
	}
}

=head2 function_cmp_up_to_constant_abs

	ANS(function_cmp_up_to_constant_abs($correctFunction, $var, $llimit,
	                                    $ulimit, $absTol, $numOfPoints,
	                                    $maxConstantOfIntegration));

function_cmp_up_to_constant_abs() uses antiderivative compare and absolute
tolerance. All but the first argument are optional. $absTol defines the absolute
tolerance value. See the corresponding option to fun_cmp(), above. All other
options work exactly as with function_cmp_up_to_constant().

=cut

sub function_cmp_up_to_constant_abs	 {	## for antiderivative problems
										## similar to function_cmp_up_to_constant
										## but uses absolute tolerance
	my ($correctEqn,$var,$llimit,$ulimit,$absTol,$numPoints,$maxConstantOfIntegration) = @_;

	if ( (scalar(@_) == 3) or (scalar(@_) > 7) or (scalar(@_) == 0) ) {
		function_invalid_params( $correctEqn );
	}

	else {
		FUNCTION_CMP(	'correctEqn'					=>	$correctEqn,
				'var'						=>	$var,
				'limits'					=>	[$llimit, $ulimit],
				'tolerance'					=>	$absTol,
				'tolType'					=>	'absolute',
				'numPoints'					=>	$numPoints,
				'mode'						=>	'antider',
				'maxConstantOfIntegration'			=>	$maxConstantOfIntegration,
				'zeroLevel'					=>	0,
				'zeroLevelTol'					=>	0
		);
	}
}

=head2 adaptive_function_cmp

FIXME undocumented.

=cut

sub adaptive_function_cmp {
	my $correctEqn = shift;
	my %options = @_;
	set_default_options(	\%options,
			'vars'			=>	[qw( x y )],
	               	'params'		=>	[],
	               	'limits'		=>	[ [0,1], [0,1]],
	               	'reltol'		=>	$functRelPercentTolDefault,
	               	'numPoints'		=>	$functNumOfPoints,
	               	'zeroLevel'		=>	$functZeroLevelDefault,
	               	'zeroLevelTol'	=>	$functZeroLevelTolDefault,
	               	'debug'			=>	0,
	       		'diagnostics'           =>      undef,
	);

    my $var_ref = $options{'vars'};
    my $ra_params = $options{ 'params'};
    my $limit_ref = $options{'limits'};
    my $relPercentTol= $options{'reltol'};
    my $numPoints = $options{'numPoints'};
    my $zeroLevel = $options{'zeroLevel'};
    my $zeroLevelTol = $options{'zeroLevelTol'};

	FUNCTION_CMP(	'correctEqn'					=>	$correctEqn,
			'var'						=>	$var_ref,
			'limits'					=>	$limit_ref,
			'tolerance'					=>	$relPercentTol,
			'tolType'					=>	'relative',
			'numPoints'					=>	$numPoints,
			'mode'						=>	'std',
			'maxConstantOfIntegration'			=>	10**100,
			'zeroLevel'					=>	$zeroLevel,
			'zeroLevelTol'					=>	$zeroLevelTol,
			'scale_norm'                			=>  	1,
			'params'                    			=>  	$ra_params,
			'debug'     					=> 	$options{debug} ,
			'diagnostics'  					=> 	$options{diagnostics} ,
	);
}

=head1 Multi-variable Function Comparisons

=head2 [DEPRECATED] multivar_function_cmp

	ANS(multivar_function_cmp($correctFunction, $var, $limits, $relTol, $numPoints, $zeroLevel, $zeroLevelTol));

This function is deprecated. Use fun_cmp instead:

	ANS(fun_cmp($correctFunction, var=>$var, limits=>$limits, ...));

=cut

## The following answer evaluator for comparing multivarable functions was
## contributed by Professor William K. Ziemer
## (Note: most of the multivariable functionality provided by Professor Ziemer
## has now been integrated into fun_cmp and FUNCTION_CMP)
############################
# W.K. Ziemer, Sep. 1999
# Math Dept. CSULB
# email: wziemer@csulb.edu
############################

sub multivar_function_cmp {
	my ($correctEqn,$var_ref,$limit_ref,$relPercentTol,$numPoints,$zeroLevel,$zeroLevelTol) = @_;

	if ( (scalar(@_) > 7) or (scalar(@_) < 2) ) {
		function_invalid_params( $correctEqn );
	}

	FUNCTION_CMP(	'correctEqn'			=>	$correctEqn,
			'var'				=>	$var_ref,
			'limits'			=>	$limit_ref,
			'tolerance'			=>	$relPercentTol,
			'tolType'			=>	'relative',
			'numPoints'			=>	$numPoints,
			'mode'				=>	'std',
			'maxConstantOfIntegration'	=>	0,
			'zeroLevel'			=>	$zeroLevel,
			'zeroLevelTol'			=>	$zeroLevelTol
	);
}

## LOW-LEVEL ROUTINE -- NOT NORMALLY FOR END USERS -- USE WITH CAUTION
## NOTE: PG_answer_eval	is used	instead	of PG_restricted_eval in order to insure that the answer
## evaluated within	the	context	of the package the problem was originally defined in.
## Includes multivariable modifications contributed by Professor William K. Ziemer
##
## IN:	a hash consisting of the following keys (error checking to be added later?)
##			correctEqn			--	the correct equation as a string
##			var				--	the variable name as a string,
##								or a reference to an array of variables
##			limits				--	reference to an array of arrays of type [lower,upper]
##			tolerance			--	the allowable margin of error
##			tolType				--	'relative' or 'absolute'
##			numPoints			--	the number of points to evaluate the function at
##			mode				--	'std' or 'antider'
##			maxConstantOfIntegration	--	maximum size of the constant of integration
##			zeroLevel			--	if the correct answer is this close to zero,
##												then zeroLevelTol applies
##			zeroLevelTol			--	absolute tolerance to allow when answer is close to zero
##			test_points			--	user supplied points to use for testing the
##                          function, either array of arrays, or optionally
##                          reference to single array (for one variable)


sub FUNCTION_CMP {
	return ORIGINAL_FUNCTION_CMP(@_)
	  if $main::useOldAnswerMacros;

	my %func_params = @_;

	my $correctEqn               = $func_params{'correctEqn'};
	my $var                      = $func_params{'var'};
	my $ra_limits                = $func_params{'limits'};
	my $tol                      = $func_params{'tolerance'};
	my $tolType                  = $func_params{'tolType'};
	my $numPoints                = $func_params{'numPoints'};
	my $mode                     = $func_params{'mode'};
	my $maxConstantOfIntegration = $func_params{'maxConstantOfIntegration'};
	my $zeroLevel                = $func_params{'zeroLevel'};
	my $zeroLevelTol             = $func_params{'zeroLevelTol'};
	my $testPoints               = $func_params{'test_points'};

	#
	#  Check that everything is defined:
	#
	$func_params{debug} = 0 unless defined $func_params{debug};
	$mode = 'std' unless defined $mode;
	my @VARS   = get_var_array($var);
	my @limits = get_limits_array($ra_limits);
	my @PARAMS = @{$func_params{'params'} || []};

	if ($tolType eq 'relative') {
	  $tol = $functRelPercentTolDefault unless defined $tol;
	  $tol *= .01;
	} else {
	  $tol = $functAbsTolDefault unless defined $tol;
	}

	#
	#  Ensure that the number of limits matches number of variables
	#
	foreach my $i (0..scalar(@VARS)-1) {
	  $limits[$i][0] = $functLLimitDefault unless defined $limits[$i][0];
	  $limits[$i][1] = $functULimitDefault unless defined $limits[$i][1];
	}

	#
	#  Check that the test points are array references with the right number of coordinates
	#
	if ($testPoints) {
	  my $n = scalar(@VARS); my $s = ($n != 1)? "s": "";
	  foreach my $p (@{$testPoints}) {
	    $p = [$p] unless ref($p) eq 'ARRAY';
	    warn "Test point (".join(',',@{$p}).") should have $n coordiante$s"
	      unless scalar(@{$p}) == $n;
	  }
	}

	#
	#  Reorder variables, limits, and test_points if the variables are not in alphabetical order
	#
	if (scalar(@VARS) > 1 && join('',@VARS) ne join('',lex_sort(@VARS))) {
	  my %order; foreach my $i (0..$#VARS) {$order{$VARS[$i]} = $i}
	  @VARS = lex_sort(@VARS);
	  @limits = map {$limits[$order{$_}]} @VARS;
	  if ($testPoints) {foreach my $p (@{$testPoints}) {$p = [map {$p->[$order{$_}]} @VARS]}}
	}

	$numPoints                = $functNumOfPoints              unless defined $numPoints;
	$maxConstantOfIntegration = $functMaxConstantOfIntegration unless defined $maxConstantOfIntegration;
	$zeroLevel                = $functZeroLevelDefault         unless defined $zeroLevel;
	$zeroLevelTol             = $functZeroLevelTolDefault      unless defined $zeroLevelTol;

	$func_params{'var'}                      = \@VARS;
        $func_params{'params'}                   = \@PARAMS;
	$func_params{'limits'}                   = \@limits;
	$func_params{'tolerance'}                = $tol;
	$func_params{'tolType'}                  = $tolType;
	$func_params{'numPoints'}                = $numPoints;
	$func_params{'mode'}                     = $mode;
	$func_params{'maxConstantOfIntegration'} = $maxConstantOfIntegration;
	$func_params{'zeroLevel'}                = $zeroLevel;
	$func_params{'zeroLevelTol'}             = $zeroLevelTol;

	########################################################
	#   End of cleanup of calling parameters
	########################################################

        my %options = (
	  debug => $func_params{'debug'},
          diagnostics => $func_params{'diagnostics'},
        );

	#
	#  Initialize the context for the formula
	#
	my $context = Parser::Context->getCopy($user_context,"LegacyNumeric");
	$context->flags->set(
	  tolerance    => $func_params{'tolerance'},
	  tolType      => $func_params{'tolType'},
	  zeroLevel    => $func_params{'zeroLevel'},
	  zeroLevelTol => $func_params{'zeroLevelTol'},
	  num_points   => $func_params{'numPoints'},
	);
	if ($func_params{'mode'} eq 'antider') {
	  $context->flags->set(max_adapt => $func_params{'maxConstantOfIntegration'});
	  $options{upToConstant} = 1;
	}

	#
	#  Add the variables and parameters to the context
	#
	my %variables; my $x;
	foreach $x (@{$func_params{'var'}})    {$variables{$x} = 'Real'}
	foreach $x (@{$func_params{'params'}}) {$variables{$x} = 'Parameter'}
	$context->variables->are(%variables);

	#
	#  Create the Formula object and get its answer checker
	#
	my $oldContext = &$Context(); &$Context($context);
	my $f = new Value::Formula($correctEqn);
	$f->{limits}      = $func_params{'limits'};
	$f->{test_points} = $func_params{'test_points'};
        $f->{correct_ans} = $correctEqn;
	my $cmp = $f->cmp(%options);
	&$Context($oldContext);

	return $cmp;
}

#
#  The original version, for backward compatibility
#  (can be removed when the Parser-based version is more fully tested.)
#
sub ORIGINAL_FUNCTION_CMP {
	my %func_params = @_;
	# WARN_MESSAGE("Using ORIGINAL_FUNCTION_CMP subroutine");
	my $correctEqn               = $func_params{'correctEqn'};
	my $var                      = $func_params{'var'};
	my $ra_limits                = $func_params{'limits'};
	my $tol                      = $func_params{'tolerance'};
	my $tolType                  = $func_params{'tolType'};
	my $numPoints                = $func_params{'numPoints'};
	my $mode                     = $func_params{'mode'};
	my $maxConstantOfIntegration = $func_params{'maxConstantOfIntegration'};
	my $zeroLevel                = $func_params{'zeroLevel'};
	my $zeroLevelTol             = $func_params{'zeroLevelTol'};
	my $ra_test_points           = $func_params{'test_points'};

    # Check that everything is defined:
    $func_params{debug} = 0 unless defined $func_params{debug};
    $mode = 'std' unless defined $mode;
    my @VARS = get_var_array($var);
	my @limits = get_limits_array($ra_limits);
	my @PARAMS = ();
	@PARAMS = @{$func_params{'params'}} if defined $func_params{'params'};

	my @evaluation_points;
	if(defined $ra_test_points) {
		# see if this is the standard format
		if(ref $ra_test_points->[0] eq 'ARRAY') {
			$numPoints = scalar @{$ra_test_points->[0]};
			# now a little sanity check
			my $j;
			for $j (@{$ra_test_points}) {
				warn "Test points do not give the same number of values for each variable"
					unless(scalar(@{$j}) == $numPoints);
			}
			warn "Test points do not match the number of variables"
				unless scalar @{$ra_test_points} == scalar @VARS;
		} else { # we are got the one-variable format
			$ra_test_points = [$ra_test_points];
			$numPoints = scalar $ra_test_points->[0];
		}
		# The input format for test points is the transpose of what is used
		# internally below, so take care of that now.
		my ($j1, $j2);
		for ($j1 = 0; $j1 < scalar @{$ra_test_points}; $j1++) {
			for ($j2 = 0; $j2 < scalar @{$ra_test_points->[$j1]}; $j2++) {
				$evaluation_points[$j2][$j1] = $ra_test_points->[$j1][$j2];
			}
		}
	} # end of handling of user supplied evaluation points

	if ($mode eq 'antider') {
		# doctor the equation to allow addition of a constant
		my $CONSTANT_PARAM = 'Q'; # unfortunately parameters must be single letters.
		                          # There is the possibility of conflict here.
		                          #  'Q' seemed less dangerous than  'C'.
		$correctEqn = "( $correctEqn ) + $CONSTANT_PARAM";
		push @PARAMS, $CONSTANT_PARAM;
	}
    my $dim_of_param_space = @PARAMS;      # dimension of equivalence space

	if($tolType eq 'relative') {
		$tol = $functRelPercentTolDefault unless defined $tol;
		$tol *= .01;
	} else {
		$tol = $functAbsTolDefault unless defined $tol;
	}

	#loop ensures that number of limits matches number of variables
	for(my $i = 0; $i < scalar @VARS; $i++) {
		$limits[$i][0] = $functLLimitDefault unless defined $limits[$i][0];
		$limits[$i][1] = $functULimitDefault unless defined $limits[$i][1];
	}
	$numPoints                = $functNumOfPoints              unless defined $numPoints;
	$maxConstantOfIntegration = $functMaxConstantOfIntegration unless defined $maxConstantOfIntegration;
	$zeroLevel                = $functZeroLevelDefault         unless defined $zeroLevel;
	$zeroLevelTol             = $functZeroLevelTolDefault      unless defined $zeroLevelTol;

	$func_params{'var'}	                     = $var;
	$func_params{'limits'}                   = \@limits;
	$func_params{'tolerance'}                = $tol;
	$func_params{'tolType'}                  = $tolType;
	$func_params{'numPoints'}                = $numPoints;
	$func_params{'mode'}                     = $mode;
	$func_params{'maxConstantOfIntegration'} = $maxConstantOfIntegration;
	$func_params{'zeroLevel'}                = $zeroLevel;
	$func_params{'zeroLevelTol'}             = $zeroLevelTol;

	########################################################
	#   End of cleanup of calling parameters
	########################################################

	my $i; # for use with loops
	my $PGanswerMessage	= "";
	my $originalCorrEqn	= $correctEqn;

	######################################################################
	# prepare the correct answer and check its syntax
	######################################################################

    my $rh_correct_ans = new AnswerHash;
	$rh_correct_ans->input($correctEqn);
	$rh_correct_ans = check_syntax($rh_correct_ans);
	warn  $rh_correct_ans->{error_message} if $rh_correct_ans->{error_flag};
	$rh_correct_ans->clear_error();
	$rh_correct_ans = function_from_string2($rh_correct_ans,
		ra_vars => [ @VARS, @PARAMS ],
		stdout  => 'rf_correct_ans',
		debug   => $func_params{debug}
	);
	my $correct_eqn_sub = $rh_correct_ans->{rf_correct_ans};
	warn $rh_correct_ans->{error_message} if $rh_correct_ans->{error_flag};
	
	######################################################################
	# define the points at which the functions are to be evaluated
	######################################################################
	
	if(not defined $ra_test_points) {
		#create the evaluation points
		my $random_for_answers = new PGrandom($main::PG_original_problemSeed);
		my $NUMBER_OF_STEPS_IN_RANDOM = 1000; # determines the granularity of the random_for_answers number generator
		for(my $count = 0; $count < @PARAMS+1+$numPoints; $count++) {
	    	my (@vars,$iteration_limit);
			for(my $i = 0; $i < @VARS; $i++) {
				my $iteration_limit = 10;
				while (0 < --$iteration_limit) {  # make sure that the endpoints of the interval are not included
		    		$vars[$i] = $random_for_answers->random($limits[$i][0], $limits[$i][1], abs($limits[$i][1] - $limits[$i][0])/$NUMBER_OF_STEPS_IN_RANDOM);
		    		last if $vars[$i]!=$limits[$i][0] and $vars[$i]!=$limits[$i][1];
				}
				warn "Unable to properly choose  evaluation points for this function in the interval ( $limits[$i][0] , $limits[$i][1] )"
					if $iteration_limit == 0;
			}
			
			push @evaluation_points, \@vars;
		}
	}
	my $evaluation_points = Matrix->new_from_array_ref(\@evaluation_points);
	
	#my $COEFFS = determine_param_coeffs($correct_eqn_sub,$evaluation_points[0],$numOfParameters);
	#warn "coeff", join(" | ", @{$COEFFS});
	
	#construct the answer evaluator
    my $answer_evaluator = new AnswerEvaluator;
    $answer_evaluator->{debug} = $func_params{debug};
    $answer_evaluator->ans_hash( 	
		correct_ans       => $originalCorrEqn,
		rf_correct_ans    => $rh_correct_ans->{rf_correct_ans},
		evaluation_points => \@evaluation_points,
		ra_param_vars     => \@PARAMS,
		ra_vars           => \@VARS,
		type              => 'function',
		score             => 0,
    );
    
    #########################################################
    # Prepare the previous answer for evaluation, discard errors
    #########################################################
    
	$answer_evaluator->install_pre_filter(
		sub {
			my $rh_ans = shift; 
						
			$rh_ans->{_filter_name} = "fetch_previous_answer";
			$rh_ans->{ans_label}='' unless defined $rh_ans->{ans_label};
			my $prev_ans_label = "previous_". $rh_ans->{ans_label};
			$rh_ans->{prev_ans} = (defined $inputs_ref->{$prev_ans_label} and $inputs_ref->{$prev_ans_label} =~/\S/)
				? $inputs_ref->{$prev_ans_label}
				: undef; 
			$rh_ans;
		}
	);
	
	$answer_evaluator->install_pre_filter(
		sub {
			my $rh_ans = shift;
			return $rh_ans unless defined $rh_ans->{prev_ans};
			check_syntax($rh_ans,
				stdin          => 'prev_ans',
				stdout         => 'prev_ans',
				error_msg_flag => 0
			);
			$rh_ans->{_filter_name} = "check_syntax_of_previous_answer";
			$rh_ans;
		}
	);
	
	$answer_evaluator->install_pre_filter(
		sub {
			my $rh_ans = shift;
			return $rh_ans unless defined $rh_ans->{prev_ans};
			function_from_string2($rh_ans, 
				stdin   => 'prev_ans', 
				stdout  => 'rf_prev_ans',
				ra_vars => \@VARS, 
				debug   => $func_params{debug}
			);
			$rh_ans->{_filter_name} = "compile_previous_answer";
			$rh_ans;
		}
	);
	
    #########################################################
    # Prepare the current answer for evaluation
    #########################################################
	
	$answer_evaluator->install_pre_filter(\&check_syntax);
	$answer_evaluator->install_pre_filter(\&function_from_string2,
		ra_vars => \@VARS,
		debug   => $func_params{debug}
    ); # @VARS has been guaranteed to be an array, $var might be a single string.
    
    #########################################################
    # Compare the previous and current answer.  Discard errors
    #########################################################
	
	$answer_evaluator->install_evaluator(
		sub {
			my $rh_ans = shift;
			return $rh_ans unless defined $rh_ans->{rf_prev_ans};
			calculate_difference_vector($rh_ans, 
				%func_params, 
				stdin1         => 'rf_student_ans', 
				stdin2         => 'rf_prev_ans',
				stdout         => 'ra_diff_with_prev_ans',
				error_msg_flag => 0,
			);
			$rh_ans->{_filter_name} = "calculate_difference_vector_of_previous_answer";
			$rh_ans;
		}
	);
	
	$answer_evaluator->install_evaluator(
		sub {
			my $rh_ans = shift;
			return $rh_ans unless defined $rh_ans->{ra_diff_with_prev_ans};
			##
			## DPVC -- only give the message if the answer is specified differently
			##
			return $rh_ans if $rh_ans->{prev_ans} eq $rh_ans->{student_ans};
			##
			## /DPVC
			##
			is_zero_array($rh_ans,
				stdin  => 'ra_diff_with_prev_ans', 
				stdout => 'ans_equals_prev_ans' 
			);
		}
	);
	
    #########################################################
    # Calculate values for approximation parameters and
    # compare the current answer with the correct answer.  Keep errors this time.
    #########################################################
   
    $answer_evaluator->install_pre_filter(\&best_approx_parameters, %func_params, param_vars => \@PARAMS);
    $answer_evaluator->install_evaluator(\&calculate_difference_vector, %func_params);
    $answer_evaluator->install_evaluator(\&is_zero_array, tolerance => $tol );

    $answer_evaluator->install_post_filter(
    	sub {
    		my $rh_ans = shift;
    		$rh_ans->clear_error('SYNTAX');
    		$rh_ans;
    	}
    );
    
	$answer_evaluator->install_post_filter(
		sub {
			my $rh_ans = shift;
			if ($rh_ans->catch_error('EVAL')) {
				$rh_ans->{ans_message} = $rh_ans->{error_message};
				$rh_ans->clear_error('EVAL');
			}
			$rh_ans;
		}
	);
	
	#
	#  Show a message when the answer is equivalent to the previous answer.
	#  
	#  We want to show the message when we're not in preview mode AND the
	#  answers are equivalent AND the answers are not identical. We DON'T CARE
	#  whether the answers are correct or not, because that leaks information in
	#  multipart questions when $showPartialCorrectAnswers is off.
	#
	$answer_evaluator->install_post_filter(
		sub {
			my $rh_ans = shift;	
			#WARN_MESSAGE(pretty_print($inputs_ref));
			my $isPreview = $inputs_ref->{previewAnswers}; # || ($inputs_ref->{action} =~ m/^Preview/);
			return $rh_ans if ($rh_ans->{bypass_equivalence_test});
			return $rh_ans unless !$isPreview # not preview mode
				and $rh_ans->{ans_equals_prev_ans} # equivalent
				and $rh_ans->{prev_ans} ne $rh_ans->{original_student_ans}; # not identical

			$rh_ans->{ans_message} = "This answer is equivalent to the one you just submitted.";
			return $rh_ans;
		}
	);
	
	$answer_evaluator;
}

=head1 SEE ALSO

L<PGanswermacros.pl>, L<MathObjects>.

=cut

1;
