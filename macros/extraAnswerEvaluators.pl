################################################################################
# WeBWorK Online Homework Delivery System
# Copyright © 2000-2007 The WeBWorK Project, http://openwebwork.sf.net/
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

extraAnswerEvaluators.pl - Answer evaluators for intervals, lists of numbers,
and lists of points.

=head1 SYNPOSIS

	interval_cmp() -- checks answers which are unions of intervals. It can also
					  be used for checking an ordered pair or list of ordered
					  pairs.

	number_list_cmp() -- checks a comma separated list of numbers.  By use of
	                     optional arguments, you can request that order be
	                     important, that complex numbers be allowed, and specify
	                     extra arguments to be sent to num_cmp (or cplx_cmp) for
	                     checking individual entries.

	equation_cmp() -- provides a limited facility for checking equations. It
	                  makes no pretense of checking to see if the real locus of
	                  the student's equation matches the real locus of the
	                  instructor's equation.  The student's equation must be of
	                  the same general type as the instructors to get credit.

=head1 DESCRIPTION

This file adds subroutines which create "answer evaluators" for checking student
answers of various "exotic" types.

=cut

# ^uses loadMacros
loadMacros('MathObjects.pl');

{
	# ^package Equation_eval
	package Equation_eval;
	
	# ^function split_eqn
	sub split_eqn {
		my $instring = shift;
		
		split /=/, $instring;
	}
	
    #FIXME  -- this could be improved so that
    #          1. it uses an answer evaluator object instead of a sub routine
    #          2. it provides error messages when previous answers are equivalent
	# ^function equation_cmp
	# ^uses AnswerHash::new
	# ^uses split_eqn
	# ^uses main::check_syntax
	# ^uses main::fun_cmp
	sub equation_cmp {
		my $right_ans = shift;
		my %opts = @_;
		my $vars = ['x','y'];


		$vars = $opts{'vars'} if defined($opts{'vars'});

		my $ans_eval = sub {
			my $student = shift;
			my %response_options = @_;
			my $ans_hash = new AnswerHash(
				'score'=>0,
				'correct_ans'=>$right_ans,
				'student_ans'=>$student,
				'original_student_ans' => $student,
				'type' => 'equation_cmp',
				'ans_message'=>'',
				'preview_text_string'=>'',
				'preview_latex_string'=>'',
			);

			if(! ($student =~ /\S/)) { return $ans_hash; }

			my @right= split_eqn($right_ans);
			if(scalar(@right) != 2) {
				$ans_hash->{'ans_message'} = "Tell your professor that there is an error in this problem.";
				return $ans_hash;
			}
			my @studsplit = split_eqn($student);
			if(scalar(@studsplit) != 2) {
				$ans_hash->{'ans_message'} = "You did not enter an equation (with an equals sign and two sides).";
				return $ans_hash;
			}

			# Next we should do syntax checks on everyone

			my $ah = new AnswerHash;
			$ah->input($right[0]);
			$ah=main::check_syntax($ah);
			if($ah->{error_flag}) {
				$ans_hash->{'ans_message'} = "Tell your professor that there is an error in this problem.";
				return $ans_hash;
			}

			$ah->input($right[1]);
			$ah=main::check_syntax($ah);
			if($ah->{error_flag}) {
				$ans_hash->{'ans_message'} = "Tell your professor that there is an error in this problem.";
				return $ans_hash;
			}

			# Correct answer checks out, now check student's syntax

			my @prevs = ("","");
			my @prevtxt = ("","");
			$ah->input($studsplit[0]);
			$ah=main::check_syntax($ah);
			if($ah->{error_flag}) {
				$ans_hash->{'ans_message'} = "Syntax error on the left side of your equation.";
				return $ans_hash;
			}
			$prevs[0] = $ah->{'preview_latex_string'};
			$prevstxt[0] = $ah->{'preview_text_string'};


			$ah->input($studsplit[1]);
			$ah=main::check_syntax($ah);
			if($ah->{error_flag}) {
				$ans_hash->{'ans_message'} = "Syntax error on the right side of your equation.";
				return $ans_hash;
			}
			$prevs[1] = $ah->{'preview_latex_string'};
			$prevstxt[1] = $ah->{'preview_text_string'};

			$ans_hash->{'preview_latex_string'} = "$prevs[0] = $prevs[1]";
			$ans_hash->{'preview_text_string'} = "$prevstxt[0] = $prevstxt[1]";


			# Check for answer equivalent to 0=0
			# Could be false positive below because of parameter
			my $ae = main::fun_cmp("0", %opts);
			my $res = $ae->evaluate("$studsplit[0]-($studsplit[1])");
			if($res->{'score'}==1) {
				# Student is 0=0, is correct answer also like this?
				$res = $ae->evaluate("$right[0]-($right[1])");
				if($res->{'score'}==1) {
					$ans_hash-> setKeys('score' => $res->{'score'});
				}
				return $ans_hash;
			}

			# Maybe answer really is 0=0, and student got it wrong, so check that
			$res = $ae->evaluate("$right[0]-($right[1])");
			if($res->{'score'}==1) {
				return $ans_hash;
			}

			# Finally, use fun_cmp to check the answers

			$ae = main::fun_cmp("o*($right[0]-($right[1]))", vars=>$vars, params=>['o'], %opts);
			$res= $ae->evaluate("$studsplit[0]-($studsplit[1])",%response_options);
			$ans_hash-> setKeys('score' => $res->{'score'});

			return $ans_hash;
		};

		return $ans_eval;
	}
}
# ^package main

# ^function mode2context
# ^uses Parser::Context::getCopy
# ^uses %context
# ^uses $numZeroLevelTolDefault
# ^uses $numAbsTolDefault
# ^uses $numRelPercentTolDefault
# ^uses $numFormatDefault
sub mode2context {
	my $mode = shift;
	my %options = @_;
	my $context;
	for ($mode) {
		/^strict$/i  and do {
			$context = Parser::Context->getCopy(\%main::context,"LimitedNumeric");
			$context->operators->redefine(',');
			last;
		};
		/^arith$/i   and do {
			$context = Parser::Context->getCopy(\%main::context,"LegacyNumeric");
			$context->functions->disable('All');
			last;
		};
		/^frac$/i    and do {
			$context = Parser::Context->getCopy(\%main::context,"LimitedNumeric-Fraction");
			$context->operators->redefine(',');
			last;
		};
		
		# default
		$context = Parser::Context->getCopy(\%main::context,"LegacyNumeric");
	}
	# If we are using complex numbers, then we ignore the other mode parts
	if(defined($options{'complex'}) &&
	   ($options{'complex'} =~ /(yes|ok)/i)) {
		#$context->constants->redefine('i', from=>'Complex');
		#$context->functions->redefine(['arg','mod','Re','Im','conj', 'sqrt', 'log'], from=>'Complex');
		#$context->operators->redefine(['^', '**'], from=>'Complex');
		$context = Parser::Context->getCopy(\%main::context,"Complex");
	}
	$options{tolType} = $options{tolType} || 'relative';
	$options{tolType} = 'absolute' if defined($options{tol});
	$options{zeroLevel} = $options{zeroLevel} || $options{zeroLevelTol} ||
		$main::numZeroLevelTolDefault;
	if ($options{tolType} eq 'absolute' or defined($options{abstol})) {
		$options{tolerance} = $options{tolerance} || $options{tol} ||
			$options{reltol} || $options{relTol} || $options{abstol} ||
			$main::numAbsTolDefault;
		$context->flags->set(
			tolerance => $options{tolerance},
			tolType => 'absolute',
			);
	} else {
		$options{tolerance} = $options{tolerance} || $options{tol} ||
			$options{reltol} || $options{relTol} || $options{abstol} ||
			$main::numRelPercentTolDefault;
		$context->flags->set(
			tolerance => .01*$options{tolerance},
			tolType => 'relative',
			);
	}
	$context->flags->set(
		zeroLevel => $options{zeroLevel},
		zeroLevelTol => $options{zeroLevelTol} || $main::numZeroLevelTolDefault,
		);
	$context->{format}{number} = $options{'format'} || $main::numFormatDefault;
	return($context);
}

=head1 MACROS

=head2 interval_cmp

Compares an interval or union of intervals.  Typical invocations are

	interval_cmp("(2, 3] U(7, 11)")

The U is used for union symbol.  In fact, any garbage (or nothing at all) can go
between intervals.  It makes sure open/closed parts of intervals are correct,
unless you don't like that.  To have it ignore the difference between open and
closed endpoints, use

	interval_cmp("(2, 3] U(7, 11)", sloppy=>'yes')

interval_cmp uses num_cmp on the endpoints.  You can pass optional arguments for
num_cmp, so to change the tolerance, you can use

	interval_cmp("(2, 3] U(3+4, 11)", relTol=>3)

The intervals can be listed in any order, unless you want to force a
particular order, which is signaled as

	interval_cmp("(2, 3] U(3+4, 11)", ordered=>'strict')

You can specify infinity as an endpoint.  It will do a case-insensitive
string match looking for I, Infinity, Infty, or Inf.  You can prepend a +
or -, as in

	interval_cmp("(-inf, 3] U [e^10, infinity)")

or

	interval_cmp("(-INF, 3] U [e^10, +I)")

If the question might have an empty set as the answer, you can use
the strings option to allow for it.  So

	interval_cmp("$ans", strings=>['empty'])

will not generate an error message if the student enters the string
empty.  Better still, it will mark a student answer of "empty" as correct
iff this matches $ans.

You can use interval_cmp for ordered pairs, or lists of ordered pairs.
Internally, this is just a distinction of whether to put nice union symbols
between intervals, or commas.  To get commas, use

	interval_cmp("(1,2), (2,3), (4,-1)", unions=>'no')

Note that interval_cmp makes no attempt at simplifying overlapping intervals.
This becomes an important feature when you are really checking lists of
ordered pairs.

Now we use the Parser package for checking intervals (or lists of
points if unions=>'no').  So, one can specify the Parser options
showCoordinateHints, showHints, partialCredit, and/or showLengthHints
as optional arguments:

	interval_cmp("(1,2), (2,3), (4,-1)", unions=>'no', partialCredit=>1)

Also, set differences and 'R' for all real numbers now work too since they work
for Parser Intervals and Unions.

=cut

# ^function interval_cmp
# ^uses Context
# ^uses mode2context
# ^uses List
# ^uses Union
sub interval_cmp {
	my $correct_ans = shift;

	my %opts = @_;
	
	my $mode          = $opts{mode} || 'std';
	my %options       = (debug => $opts{debug});
	my $ans_type = ''; # set to List, Union, or String below
	
	#
	#  Get an apppropriate context based on the mode
	#
	my $oldContext = Context();
	my $context = mode2context($mode, %opts);

	if(defined($opts{unions}) and $opts{unions} eq 'no' ) {
		# This is really a list of points, not intervals at all
		$ans_type = 'List';
		$context->parens->redefine('(');
		$context->parens->redefine('[');
		$context->parens->redefine('{');
		$context->operators->redefine('u',using=>',');
		$context->operators->set(u=>{string=>", ", TeX=>',\,'});
	} else {
		$context->parens->redefine('(', from=>'Interval');
		$context->parens->redefine('[', from=>'Interval');
		$context->parens->redefine('{', from=>'Interval');
		
		$context->constants->redefine('R',from=>'Interval');
		$context->operators->redefine('U',from=>"Interval");
		$context->operators->redefine('u',from=>"Interval",using=>"U");
		$ans_type = 'Union';
	}
	# Take optional arguments intended for List, or Union
	for my $o (qw( showCoordinateHints showHints partialCredit showLengthHints )) {
		$options{$o} = $opts{$o} || 0;
	}
	$options{showUnionReduceWarnings} = $opts{showUnionReduceWarnings};
	$options{studentsMustReduceUnions} = $opts{studentsMustReduceUnions};
	if(defined($opts{ordered}) and $opts{ordered}) {
		$options{ordered} = 1;
		# Force this option if the the union must be ordered
		$options{studentsMustReduceUnions} = 1;
	}
	if (defined($opts{'sloppy'}) && $opts{'sloppy'} eq 'yes') {
		 $options{requireParenMatch} = 0;
	}
	# historically we allow more infinities
	$context->strings->add(
		'i' => {alias=>'infinity'},
		'infty' => {alias=>'infinity'},
		'minfinity' => {infinite=>1, negative=>1},
		'minfty' => {alias=>'minfinity'},
		'minf' => {alias=>'minfinity'},
		'mi' => {alias=>'minfinity'},
	);
	# Add any strings
	if ($opts{strings}) {
		foreach my $string (@{$opts{strings}}) {
			$string = uc($string);
			$context->strings->add($string) unless
				defined($context->strings->get($string));
			$ans_type = 'String' if $string eq uc($correct_ans);
		}
	}
	# Add any variables
	$opts{vars} = $opts{var} if ($opts{var});
	if ($opts{vars}) {
		$context->variables->are(); # clear old vars
		$opts{vars} = [$opts{vars}] unless ref($opts{vars}) eq 'ARRAY';
		foreach my $v (@{$opts{vars}}) {
			$context->variables->add($v=>'Real')
				unless $context->variables->get($v);
		}
	}
	
	my $ans_eval;
	Context($context);
	if($ans_type eq 'List') {
		$ans_eval = List($correct_ans)->cmp(%options);
	} elsif($ans_type eq 'Union') {
		$ans_eval = Union($correct_ans)->cmp(%options);
	} elsif($ans_type eq 'String') {
		$ans_eval = List($correct_ans)->cmp(%options);
	} else {
		warn "Bug -- should not be here in interval_cmp";
	}
		
	Context($oldContext);
	return($ans_eval);
}

=head2 number_list_cmp

Checks an answer which is a comma-separated list of numbers.  The actual
numbers are fed to num_cmp, so all of the flexibilty of num_cmp carries
over (values can be expressions to be evaluated).  For example,

	number_list_cmp("1, -2")

will accept "1, -2", "-2, 1", or "-1-1,sqrt(1)".

	number_list_cmp("1^2 + 1, 2^2 + 1, 3^2 + 1", ordered=>'strict')

will accept "2, 5, 10", but not "5, 2, 10".

If you want to allow complex number entries, complex=>'ok' will cause it
to use cplx_cmp instead:

	number_list_cmp("2, -2, 2i, -2i", complex=>'ok')

In cases where you set complex=>'ok', be sure the problem file loads
PGcomplexmacros.pl.

Optional arguements for num_cmp (resp. cplx_cmp) can be used as well,
such as

	number_list_cmp("cos(3), sqrt(111)", relTol => 3)

The strings=>['hello'] argument is treated specially.  It can be used to
replace the entire answer.  So

	number_list_cmp("cos(3), sqrt(111)", strings=>['none'])

will mark "none" wrong, but not generate an error.  On the other hand,

	number_list_cmp("none", strings=>['none'])

will mark "none" as correct.

One can also specify optionnal arguments for Parser's List checker: showHints,
partialCredit, and showLengthHints, as in:

	number_list_cmp("cos(3), sqrt(111)", partialCredit=>1)

=cut

# ^function number_list_cmp
# ^uses Context
# ^uses mode2context
# ^uses List
sub number_list_cmp {
	my $list = shift;

	my %num_params = @_;

	my $mode		  = $num_params{mode} || 'std';
	my %options		  = (debug => $num_params{debug});

	#
	#  Get an apppropriate context based on the mode
	#
	my $oldContext = Context();
	my $context = mode2context($mode, %num_params);

	#$context->strings->clear;
	if ($num_params{strings}) {
		foreach my $string (@{$num_params{strings}}) {
			my %tex = ($string =~ m/(-?)inf(inity)?/i)? (TeX => "$1\\infty"): ();
			$string = uc($string);
			$context->strings->add($string => {%tex}) unless
				defined($context->strings->get($string));
		}
	}

	$options{ordered} = 1 if defined($num_params{ordered});
	# These didn't exist before in number_list_cmp so they behaved like
	# in List()->cmp.  Now they can be optionally set
	for my $o (qw( showHints partialCredit showLengthHints )) {
		$options{$o} = $num_params{$o} || 0;
	}

	Context($context);
	my $ans_eval = List($list)->cmp(%options);
	Context($oldContext);
	return($ans_eval);
}


=heads equation_cmp

Compares an equation.  This really piggy-backs off of fun_cmp.  It looks
at LHS-RHS of the equations to see if they agree up to constant multiple.
It also guards against an answer of 0=0 (which technically gives a constant
multiple of any equation).  It is best suited to situations such as checking
the equation of a line which might be vertical and you don't want to give
that away, or checking equations of ellipses where the students answer should
be quadratic.

Typical invocation would be:

	equation_com("x^2+(y-1)^2 = 11", vars=>['x','y'])

=cut

# ^function equation_cmp
# ^uses Equation_eval::equation_cmp
sub equation_cmp {
	Equation_eval::equation_cmp(@_);
}
