# This file	is PGanswermacros.pl
# This includes the subroutines for the ANS macros, that
# is, macros allowing a more flexible answer checking
####################################################################
# Copyright @ 1995-2000 University of Rochester
# All Rights Reserved
####################################################################
#$Id$

=head1 NAME

	PGanswermacros.pl -- located in the courseScripts directory

=head1 SYNPOSIS

	Number Answer Evaluators:
		num_cmp()	--	uses an input hash to determine parameters

		std_num_cmp(), std_num_cmp_list(), std_num_cmp_abs, std_num_cmp_abs_list()
		frac_num_cmp(), frac_num_cmp_list(), frac_num_cmp_abs, frac_num_cmp_abs_list()
		arith_num_cmp(), arith_num_cmp_list(), arith_num_cmp_abs, arith_num_cmp_abs_list()
		strict_num_cmp(), strict_num_cmp_list(), strict_num_cmp_abs, strict_num_cmp_abs_list()
		numerical_compare_with_units()	--	requires units as part of the answer
		std_num_str_cmp()	--	also accepts a set of strings as possible answers

	Function Answer Evaluators:
		fun_cmp()	--	uses an input hash to determine parameters

		function_cmp(), function_cmp_abs()
		function_cmp_up_to_constant(), function_cmp_up_to_constant_abs()
		multivar_function_cmp()

	String Answer Evaluators:
		str_cmp()	--	uses an input hash to determine parameters

		std_str_cmp(), std_str_cmp_list(), std_cs_str_cmp(), std_cs_str_cmp_list()
		strict_str_cmp(), strict_str_cmp_list()
		ordered_str_cmp(), ordered_str_cmp_list(), ordered_cs_str_cmp(), ordered_cs_str_cmp_list()
		unordered_str_cmp(), unordered_str_cmp_list(), unordered_cs_str_cmp(), unordered_cs_str_cmp_list()

	Miscellaneous Answer Evaluators:
		checkbox_cmp()
		radio_cmp()

=cut

=head1 DESCRIPTION

This file adds subroutines which create "answer evaluators" for checking
answers. Each answer evaluator accepts a single input from a student answer,
checks it and creates an output hash %ans_hash with seven or eight entries
(the preview_latex_string is optional). The output hash is now being created
with the AnswerHash package "class", which is located at the end of this file.
This class is currently just a wrapper for the hash, but this might change in
the future as new capabilities are added.

					score			=>	$correctQ,
					correct_ans		=>	$originalCorrEqn,
					student_ans		=>	$modified_student_ans
					original_student_ans	=>	$original_student_answer,
					ans_message		=>	$PGanswerMessage,
					type			=>	'typeString',
					preview_text_string	=>	$preview_text_string,
					preview_latex_string	=>	$preview_latex_string


	$ans_hash{score}			--	a number between 0 and 1 indicating
										whether the answer is correct. Fractions
										allow the implementation of partial
										credit for incorrect answers.
	$ans_hash{correct_ans}			--	The correct answer, as supplied by the
										instructor and then formatted. This can
										be viewed by the student after the answer date.
	$ans_hash{student_ans}			--	This is the student answer, after reformatting;
										for example the answer might be forced
										to capital letters for comparison with
										the instructors answer. For a numerical
										answer, it gives the evaluated answer.
										This is displayed in the section reporting
										the results of checking the student answers.
	$ans_hash{original_student_ans}		--	This is the original student answer. This is displayed
										on the preview page and may be used for sticky answers.
	$ans_hash{ans_message}			--	Any error message, or hint provided by the answer evaluator.
										This is also displayed in the section reporting
										the results of checking the student answers.
	$ans_hash{type}				--	A string indicating the type of answer evaluator. This
										helps in preprocessing the student answer for errors.
										Some examples:
											'number_with_units'
											'function'
											'frac_number'
											'arith_number'
	$ans_hash{preview_text_string}		--	This typically shows how the student answer was parsed. It is
										displayed on the preview page. For a student answer of 2sin(3x)
										this would be 2*sin(3*x). For string answers it is typically the
										same as $ans_hash{student_ans}.
	$ans_hash{preview_latex_string}		--	THIS IS OPTIONAL. This is latex version of the student answer
										which is used to show a typeset view on the answer on the preview
										page. For a student answer of 2/3, this would be \frac{2}{3}.

Technical note: the routines in this file are not actually answer evaluators. Instead, they create
answer evaluators. An answer evaluator is an anonymous subroutine, referenced by a named scalar. The
routines in this file build the subroutine and return a reference to it. Later, when the student
actually enters an answer, the problem processor feeds that answer to the referenced subroutine, which
evaluates it and returns a score (usually 0 or 1). For most users, this distinction is unimportant, but
if you plan on writing your own answer evaluators, you should understand this point.

=cut

BEGIN {
	be_strict(); # an alias	for	use	strict.	 This means	that all global	variable must contain main:: as	a prefix.
}


my ($BR 					        ,		# convenient localizations.
	$PAR					        ,
	$numRelPercentTolDefault		,
	$numZeroLevelDefault			,
	$numZeroLevelTolDefault			,
	$numAbsTolDefault			    ,
	$numFormatDefault			    ,
	$functRelPercentTolDefault	   	,
	$functZeroLevelDefault			,
	$functZeroLevelTolDefault		,
	$functAbsTolDefault			    ,
	$functNumOfPoints			    ,
	$functVarDefault			    ,
	$functLLimitDefault			    ,
	$functULimitDefault			    ,
	$functMaxConstantOfIntegration	,
	$CA                             ,
	$rh_envir                       ,
	$useBaseTenLog                  ,
	$inputs_ref                     ,
	$QUESTIONNAIRE_ANSWERS          ,
	$user_context,
	$Context,
);




sub _PGanswermacros_init {

		 $BR 	                            =   main::PG_restricted_eval(q!$main::BR!);		
		 $PAR	                            =   main::PG_restricted_eval(q!$main::PAR!);

		# import defaults
		# these	are	now imported from the %envir variable
		 $numRelPercentTolDefault			=	main::PG_restricted_eval(q!$main::numRelPercentTolDefault!);
		 $numZeroLevelDefault				=	main::PG_restricted_eval(q!$main::numZeroLevelDefault!);
		 $numZeroLevelTolDefault			=	main::PG_restricted_eval(q!$main::numZeroLevelTolDefault!);
		 $numAbsTolDefault				    =	main::PG_restricted_eval(q!$main::numAbsTolDefault!);
		 $numFormatDefault				    =	main::PG_restricted_eval(q!$main::numFormatDefault!);
		 $functRelPercentTolDefault			=	main::PG_restricted_eval(q!$main::functRelPercentTolDefault!);
		 $functZeroLevelDefault				=	main::PG_restricted_eval(q!$main::functZeroLevelDefault!);
		 $functZeroLevelTolDefault			=	main::PG_restricted_eval(q!$main::functZeroLevelTolDefault!);
		 $functAbsTolDefault				=	main::PG_restricted_eval(q!$main::functAbsTolDefault!);
		 $functNumOfPoints				    =	main::PG_restricted_eval(q!$main::functNumOfPoints!);
		 $functVarDefault				    =	main::PG_restricted_eval(q!$main::functVarDefault!);
		 $functLLimitDefault				=	main::PG_restricted_eval(q!$main::functLLimitDefault!);
		 $functULimitDefault				=	main::PG_restricted_eval(q!$main::functULimitDefault!);
		 $functMaxConstantOfIntegration		=	main::PG_restricted_eval(q!$main::functMaxConstantOfIntegration!);
		 $rh_envir                          =   main::PG_restricted_eval(q!\%main::envir!);
		 $useBaseTenLog                     =   main::PG_restricted_eval(q!$main::useBaseTenLog!);
		 $inputs_ref                        =   main::PG_restricted_eval(q!$main::inputs_ref!);
		 $QUESTIONNAIRE_ANSWERS				=   '';

		 if (!main::PG_restricted_eval(q!$main::useOldAnswerMacros!)) {
		   $user_context = main::PG_restricted_eval(q!\%context!);
		   $Context = sub {Parser::Context->current($user_context,@_)};
		 }
}



##########################################################################

#Note   use $rh_envir to read environment variables

##########################################################################
## Number answer evaluators

=head2 Number Answer Evaluators

Number answer evaluators take in a numerical answer, compare it to the correct answer,
and return a score. In addition, they can choose to accept or reject an answer based on
its format, closeness to the correct answer, and other criteria. There are two types
of numerical answer evaluators: num_cmp(), which takes a hash of named options as parameters,
and the "mode"_num_cmp() variety, which use different functions to access different sets of
options. In addition, there is the special case of std_num_str_cmp(), which can evaluate
both numbers and strings.

Numerical Comparison Options

	correctAnswer		--	This is the correct answer that the student answer will
						be compared to. However, this does not mean that the
						student answer must match this exactly. How close the
						student answer must be is determined by the other
						options, especially tolerance and format.

	tolerance		--	These options determine how close the student answer
						must be to the correct answer to qualify. There are two
						types of tolerance: relative and absolute. Relative
						tolerances are given in percentages. A relative
						tolerance of 1 indicates that the student answer must
						be within 1% of the correct answer to qualify as correct.
						In other words, a student answer is correct when
							abs(studentAnswer - correctAnswer) <= abs(.01*relpercentTol*correctAnswer)
						Using absolute tolerance, the student answer must be a
						fixed distance from the correct answer to qualify.
						For example, an absolute tolerance of 5 means that any
						number which is +-5 of the correct answer qualifies as correct.
							Final (rarely used) tolerance options are zeroLevel
						and zeroLevelTol, used in conjunction with relative
						tolerance. if correctAnswer has absolute value less than
						or equal to zeroLevel, then the student answer must be,
						in absolute terms, within zeroLevelTol of correctAnswer, i.e.,
							abs(studentAnswer - correctAnswer) <= zeroLevelTol.
						In other words, if the correct answer is very near zero,
						an absolute tolerance will be used. One must do this to
						handle floating point answers very near zero, because of
						the inaccuracy of floating point arithmetic. However, the
						default values are almost always adequate.

	mode			--	This determines the allowable methods for entering an
						answer. Answers which do not meet this requirement will
						be graded as incorrect, regardless of their numerical
						value. The recognized modes are:
							'std' (default)	--	allows any expression which evaluates
												to a number, including those using
												elementary functions like sin() and
												exp(), as well as the operations of
												arithmetic (+, -, *, /, ^)
							'strict'	--	only decimal numbers are allowed
							'frac'		--	whole numbers and fractions are allowed
							'arith'		--	arithmetic expressions are allowed, but
												no functions
						Note that all modes allow the use of "pi" and "e" as
						constants, and also the use of "E" to represent scientific
						notation.

	format			--	The format to use when displaying the correct and
						submitted answers. This has no effect on how answers are
						evaluated; it is only for cosmetic purposes. The
						formatting syntax is the same as Perl uses for the sprintf()
						function. Format strings are of the form '%m.nx' or '%m.nx#',
						where m and n are described below, and x is a formatter.
							Esentially, m is the minimum length of the field
						(make this negative to left-justify). Note that the decimal
						point counts as a character when determining the field width.
						If m begins with a zero, the number will be padded with zeros
						instead of spaces to fit the field.
							The precision specifier (n) works differently, depending
						on which formatter you are using. For d, i, o, u, x and X
						formatters (non-floating point formatters), n is the minimum
						number of digits to display. For e and f, it is the number of
						digits that appear after the decimal point (extra digits will
						be rounded; insufficient digits will be padded with spaces--see
						'#' below). For g, it is the number of significant digits to
						display.
							The full list of formatters can be found in the manpage
						for printf(3), or by typing "perldoc -f sprintf" at a
						terminal prompt. The following is a brief summary of the
						most frequent formatters:
							d	--	decimal number
							ld	--	long decimal number
							u	--	unsigned decimal number
							lu	--	long unsigned decimal number
							x	--	hexadecimal number
							o	--	octal number
							e	--	floating point number in scientific notation
							f	--	floating point number
							g	--	either e or f, whichever takes less space
						Technically, g will use e if the exponent is less than -4 or
						greater than or equal to the precision. Trailing zeros are
						removed in this mode.
							If the format string ends in '#', trailing zeros will be
						removed in the decimal part. Note that this is not a standard
						syntax; it is handled internally by WeBWorK and not by Perl
						(although this should not be a concern to end users).
						The default format is '%0.5f#', which displays as a floating
						point number with 5 digits of precision and no trailing zeros.
						Other useful format strings might be '%0.2f' for displaying
						dollar amounts, or '%010d' to display an integer with leading
						zeros. Setting format to an empty string ( '' ) means no
						formatting will be used; this will show 'arbitrary' precision
						floating points.

Default Values (As of 7/24/2000) (Option -- Variable Name -- Value)

	Format					--	$numFormatDefault		--	"%0.5f#"
	Relative Tolerance		--	$numRelPercentTolDefault	--	.1
	Absolute Tolerance		--	$numAbsTolDefault		--	.001
	Zero Level				--	$numZeroLevelDefault		--	1E-14
	Zero Level Tolerance	--	$numZeroLevelTolDefault		--	1E-12

=cut


=head3 num_cmp()

Compares a number or a list of numbers, using a named hash of options to set
parameters. This can make for more readable code than using the "mode"_num_cmp()
style, but some people find one or the other easier to remember.

ANS( num_cmp( answer or answer_array_ref, options_hash ) );

	1. the correct answer, or a reference to an array of correct answers
	2. a hash with the following keys (all optional):
		mode			--	'std' (default) (allows any expression evaluating to
								a number)
							'strict' (only numbers are allowed)
							'frac' (fractions are allowed)
							'arith' (arithmetic expressions allowed)
		format			--	'%0.5f#' (default); defines formatting for the
								correct answer
		tol				--	an absolute tolerance, or
		relTol			--	a relative tolerance
		units			--	the units to use for the answer(s)
		strings			--	a reference to an array of strings which are valid
								answers (works like std_num_str_cmp() )
		zeroLevel		--	if the correct answer is this close to zero,
								 then zeroLevelTol applies
		zeroLevelTol	--	absolute tolerance to allow when answer is close
								 to zero

		debug			--	if set to 1, provides verbose listing of
								hash entries throughout fliters.

	Returns an answer evaluator, or (if given a reference to an array of
	answers), a list of answer evaluators. Note that a reference to an array of
	answers results is just a shortcut for writing a separate <code>num_cmp()</code> for each
	answer.

EXAMPLES:

	num_cmp( 5 )					--	correct answer is 5, using defaults
									for all options
	num_cmp( [5,6,7] )				--	correct answers are 5, 6, and 7,
									using defaults for all options
	num_cmp( 5, mode => 'strict' )	--	correct answer is 5, mode is strict
	num_cmp( [5,6], relTol => 5 )	--	correct answers are 5 and 6,
										both with 5% relative tolerance
	num_cmp( 6, strings => ["Inf", "Minf", "NaN"] )
									--	correct answer is 6, "Inf", "Minf",
									 and "NaN" recognized as valid, but
									 incorrect answers.
	num_cmp( "-INF", strings => ["INF", "-INF"] )
									--	correct answer is "-INF", "INF" and
									 numerical expressions recognized as valid,
									 but incorrect answers.


=cut

sub num_cmp	{
	my $correctAnswer = shift @_;
	$CA = $correctAnswer;
	my @opt	= @_;
	my %out_options;

#########################################################################
# Retain this first check for backword compatibility.  Allows input of the form
# num_cmp($ans, 1, '%0.5f') but warns against it
#########################################################################
	my %known_options =	(
					'mode'			=>	'std',
					'format'		=>	$numFormatDefault,
					'tol'			=>	$numAbsTolDefault,
					'relTol'		=>	$numRelPercentTolDefault,
					'units'			=>	undef,
					'strings'		=>	undef,
					'zeroLevel'		=>	$numZeroLevelDefault,
					'zeroLevelTol'	=>	$numZeroLevelTolDefault,
					'tolType'       =>  'relative',
					'tolerance'     =>  1,
					'reltol'		=>	undef,			#alternate spelling
					'unit'			=>	undef,			#alternate spelling
					'debug'			=>	0
        );

	my @output_list;
	my( $relPercentTol, $format, $zeroLevel, $zeroLevelTol) = @opt;

	unless( ref($correctAnswer) eq 'ARRAY' || scalar( @opt ) == 0 ||
			  ( defined($opt[0]) and exists $known_options{$opt[0]} ) ) {
		# unless the first parameter is	a list of arrays
		# or the second	parameter is a known option or
		# no options were used,
		# use the old num_cmp which does not use options, but has inputs
		# $relPercentTol,$format,$zeroLevel,$zeroLevelTol
		warn "This method of using num_cmp() is deprecated. Please rewrite this" .
					" problem using the options style of parameter passing (or" .
					" check that your first option is spelled correctly).";

		%out_options = (	'relTol'		=> $relPercentTol,
					'format'		=> $format,
					'zeroLevel'		=> $zeroLevel,
					'zeroLevelTol'	=> $zeroLevelTol,
					'mode'			=> 'std'
		);
	}

#########################################################################
# Now handle the options assuming they are entered in the form
# num_cmp($ans, relTol=>1, format=>'%0.5f')
#########################################################################
	%out_options = @opt;
	assign_option_aliases( \%out_options,
				'reltol'    =>      'relTol',
				'unit'	    =>	    'units',
				'abstol'	=>		'tol',
				);

	set_default_options( \%out_options,
			     'tolType'		=>  (defined($out_options{'tol'}) ) ? 'absolute' : 'relative',  # the existence of "tol" means that we use absolute tolerance mode
			     'tolerance'    =>  (defined($out_options{'tolType'}) && $out_options{'tolType'} eq 'absolute' ) ? $numAbsTolDefault : $numRelPercentTolDefault,  # relative tolerance is the default
			     'mode'		    =>	'std',
			     'format'		=>	$numFormatDefault,
			     'tol'		    =>	undef,
			     'relTol'		=>	undef,
			     'units'		=>	undef,
			     'strings'		=>	undef,
			     'zeroLevel'	=>	$numZeroLevelDefault,
			     'zeroLevelTol'	=>	$numZeroLevelTolDefault,
			     'debug'		=>	0,
	);

	# can't use both units and strings
	if( defined( $out_options{'units'} ) && defined( $out_options{'strings'} ) ) {
		warn "Can't use both 'units' and 'strings' in the same problem " .
		"(check your parameters to num_cmp() )";
	}

	# absolute tolType and relTol are incompatible. So are relative tolType and tol
	if( defined( $out_options{'relTol'} ) &&  $out_options{'tolType'} eq 'absolute' )  {
		warn "The 'tolType' 'absolute' is not compatible with 'relTol' " .
		"(check your parameters to num_cmp() )";
	}
	if( defined( $out_options{'tol'} ) &&  $out_options{'tolType'} eq 'relative' )  {
		warn "The 'tolType' 'relative' is not compatible with 'tol' " .
		"(check your parameters to num_cmp() )";
	}


	# Handle legacy options
   	if ($out_options{tolType} eq 'absolute')   {
		$out_options{'tolerance'}=$out_options{'tol'} if defined($out_options{'tol'});
		delete($out_options{'relTol'}) if exists( $out_options{'relTol'} );
	} else {
		$out_options{'tolerance'}=$out_options{'relTol'} if defined($out_options{'relTol'});
		# delete($out_options{'tol'}) if exists( $out_options{'tol'} );
	}
	# end legacy options

	# thread over lists
	my @ans_list = ();

	if ( ref($correctAnswer) eq 'ARRAY' ) {
		@ans_list =	@{$correctAnswer};
	}
	else { push( @ans_list, $correctAnswer );
	}

	# produce answer evaluators
	foreach	my $ans	(@ans_list) {
		if( defined( $out_options{'units'} ) ) {
			$ans = "$ans $out_options{'units'}";

			push( @output_list, NUM_CMP(	'correctAnswer'	    	=>	$ans,
							'tolerance'		=>	$out_options{'tolerance'},
							'tolType'		=>	$out_options{'tolType'},
							'format'		=>	$out_options{'format'},
							'mode'			=>	$out_options{'mode'},
							'zeroLevel'		=>	$out_options{'zeroLevel'},
							'zeroLevelTol'	=>	$out_options{'zeroLevelTol'},
							'debug'			=>	$out_options{'debug'},
							'units'			=>	$out_options{'units'},
			      )
			);
		} elsif( defined( $out_options{'strings'} ) ) {


			push( @output_list, NUM_CMP( 	'correctAnswer'	=> 	$ans,
							'tolerance'	=>	$out_options{tolerance},
							'tolType'	=>	$out_options{tolType},
							'format'	=>	$out_options{'format'},
							'mode'		=>	$out_options{'mode'},
							'zeroLevel'	=>	$out_options{'zeroLevel'},
							'zeroLevelTol'	=>	$out_options{'zeroLevelTol'},
							'debug'		=>	$out_options{'debug'},
							'strings'	=> 	$out_options{'strings'},
				 )
				 );
		} else {
			push(@output_list,
				NUM_CMP(	'correctAnswer'	    	=>	$ans,
					'tolerance'		=>	$out_options{tolerance},
					'tolType'		=>	$out_options{tolType},
					'format'		=>	$out_options{'format'},
					'mode'			=>	$out_options{'mode'},
					'zeroLevel'		=>	$out_options{'zeroLevel'},
					'zeroLevelTol'	    	=>	$out_options{'zeroLevelTol'},
					'debug'			=>	$out_options{'debug'},
				),
			);
	    }
	}

	return (wantarray) ? @output_list : $output_list[0];
}

#legacy code for compatability purposes
sub num_rel_cmp	{		# compare numbers
    std_num_cmp( @_ );
}


=head3 "mode"_num_cmp() functions

There are 16 functions total, 4 for each mode (std, frac, strict, arith). Each mode has
one "normal" function, one which accepts a list of answers, one which uses absolute
rather than relative tolerance, and one which uses absolute tolerance and accepts a list.
The "std" family is documented below; all others work precisely the same.

 std_num_cmp($correctAnswer) OR
 std_num_cmp($correctAnswer, $relPercentTol) OR
 std_num_cmp($correctAnswer, $relPercentTol, $format) OR
 std_num_cmp($correctAnswer, $relPercentTol, $format, $zeroLevel) OR
 std_num_cmp($correctAnswer, $relPercentTol, $format, $zeroLevel, $zeroLevelTol)

	$correctAnswer	--	the correct answer
	$relPercentTol	--	the tolerance, as a percentage (optional)
	$format		--	the format of the displayed answer (optional)
	$zeroLevel	--	if the correct answer is this close to zero, then zeroLevelTol applies (optional)
	$zeroLevelTol	--	absolute tolerance to allow when correct answer is close to zero (optional)

	std_num_cmp() uses standard mode (arithmetic operations and elementary
	functions allowed) and relative tolerance. Options are specified by
	one or more parameters. Note that if you wish to set an option which
	is later in the parameter list, you must set all previous options.

 std_num_cmp_abs($correctAnswer) OR
 std_num_cmp_abs($correctAnswer, $absTol) OR
 std_num_cmp_abs($correctAnswer, $absTol, $format)

	$correctAnswer		--	the correct answer
	$absTol			--	an absolute tolerance (optional)
	$format			--	the format of the displayed answer (optional)

	std_num_cmp_abs() uses standard mode and absolute tolerance. Options
	are set as with std_num_cmp(). Note that $zeroLevel and $zeroLevelTol
	do not apply with absolute tolerance.

 std_num_cmp_list($relPercentTol, $format, @answerList)

	$relPercentTol		--	the tolerance, as a percentage
	$format			--	the format of the displayed answer(s)
	@answerList		--	a list of one or more correct answers

	std_num_cmp_list() uses standard mode and relative tolerance. There
	is no way to set $zeroLevel or $zeroLevelTol. Note that no
	parameters are optional. All answers in the list will be
	evaluated with the same set of parameters.

 std_num_cmp_abs_list($absTol, $format, @answerList)

	$absTol		--	an absolute tolerance
	$format		--	the format of the displayed answer(s)
	@answerList	--	a list of one or more correct answers

	std_num_cmp_abs_list() uses standard mode and absolute tolerance.
	Note that no parameters are optional. All answers in the list will be
	evaluated with the same set of parameters.

 arith_num_cmp(), arith_num_cmp_list(), arith_num_cmp_abs(), arith_num_cmp_abs_list()
 strict_num_cmp(), strict_num_cmp_list(), strict_num_cmp_abs(), strict_num_cmp_abs_list()
 frac_num_cmp(), frac_num_cmp_list(), frac_num_cmp_abs(), frac_num_cmp_abs_list()

Examples:

	ANS( strict_num_cmp( 3.14159 ) )	--	The student answer must be a number
		in decimal or scientific notation which is within .1 percent of 3.14159.
		This assumes $numRelPercentTolDefault has been set to .1.
	ANS( strict_num_cmp( $answer, .01 ) )	--	The student answer must be a
		number within .01 percent of $answer (e.g. 3.14159 if $answer is 3.14159
		or $answer is "pi" or $answer is 4*atan(1)).
	ANS( frac_num_cmp( $answer) ) or ANS( frac_num_cmp( $answer,.01 ))	--
		The student answer can be a number or fraction, e.g. 2/3.
	ANS( arith_num_cmp( $answer) ) or ANS( arith_num_cmp( $answer,.01 ))	--
		The student answer can be an arithmetic expression, e.g. (2+3)/7-2^.5 .
	ANS( std_num_cmp( $answer) ) or ANS( std_num_cmp( $answer,.01 ))	--
		The student answer can contain elementary functions, e.g. sin(.3+pi/2)

=cut

sub std_num_cmp	{						# compare numbers allowing use of elementary functions
    my ( $correctAnswer, $relPercentTol, $format, $zeroLevel, $zeroLevelTol ) = @_;

	my %options = ( 'relTol'        =>	$relPercentTol,
		    		'format'		=>	$format,
		    		'zeroLevel'		=>	$zeroLevel,
		    		'zeroLevelTol'	=>	$zeroLevelTol
    );

    set_default_options( \%options,
			 'tolType'	    =>  'relative',
			 'tolerance'    =>  $numRelPercentTolDefault,
			 'mode'		    =>	'std',
			 'format'	    =>	$numFormatDefault,
			 'relTol'	    =>	$numRelPercentTolDefault,
			 'zeroLevel'    =>  $numZeroLevelDefault,
			 'zeroLevelTol' =>  $numZeroLevelTolDefault,
			 'debug'        =>  0,
    );

    num_cmp([$correctAnswer], %options);
}

##	Similar	to std_num_cmp but accepts a list of numbers in	the	form
##	std_num_cmp_list(relpercentTol,format,ans1,ans2,ans3,...)
##	format is of the form "%10.3g" or "", i.e., a format suitable for sprintf(). Use "" for default
##	You	must enter a format	and	tolerance

sub std_num_cmp_list {
	my ( $relPercentTol, $format, @answerList) = @_;

	my %options = ( 'relTol'	=>      $relPercentTol,
			'format'        =>      $format,
	);

	set_default_options( \%options,
			     'tolType'      =>      'relative',
			     'tolerance'    =>      $numRelPercentTolDefault,
			     'mode'         =>      'std',
			     'format'       =>      $numFormatDefault,
			     'relTol'       =>      $numRelPercentTolDefault,
			     'zeroLevel'    =>      $numZeroLevelDefault,
			     'zeroLevelTol' =>      $numZeroLevelTolDefault,
			     'debug'        =>      0,
	);

	num_cmp(\@answerList, %options);

}

sub std_num_cmp_abs	{			# compare numbers allowing use of elementary functions with absolute tolerance
	my ( $correctAnswer, $absTol, $format) = @_;
	my %options = ( 'tolerance'  => $absTol,
		      	'format'     => $format
	);

	set_default_options (\%options,
			     'tolType'      =>      'absolute',
			     'tolerance'    =>      $absTol,
			     'mode'         =>      'std',
			     'format'       =>      $numFormatDefault,
			     'zeroLevel'    =>      0,
			     'zeroLevelTol' =>      0,
			     'debug'        =>      0,
	);

	num_cmp([$correctAnswer], %options);
}

##	See std_num_cmp_list for usage

sub std_num_cmp_abs_list {
	my ( $absTol, $format, @answerList ) = @_;

        my %options = ( 'tolerance'         =>      $absTol,
                        'format'            =>      $format,
	);

        set_default_options( \%options,
                             'tolType'      =>      'absolute',
                             'tolerance'    =>      $absTol,
                             'mode'         =>      'std',
                             'format'       =>      $numFormatDefault,
                             'zeroLevel'    =>      0,
                             'zeroLevelTol' =>      0,
                             'debug'        =>      0,
        );

        num_cmp(\@answerList, %options);
}

sub frac_num_cmp {						# only allow fractions and numbers as submitted answer

	my ( $correctAnswer, $relPercentTol, $format, $zeroLevel, $zeroLevelTol ) = @_;

	my %options = (	'relTol'	 =>		$relPercentTol,
					'format'		 =>		$format,
					'zeroLevel'	 =>		$zeroLevel,
					'zeroLevelTol'	 =>		$zeroLevelTol
	);

	set_default_options( \%options,
				 'tolType'		 =>		'relative',
				 'tolerance'	 =>		$relPercentTol,
				 'mode'			 =>		'frac',
				 'format'		 =>		$numFormatDefault,
				 'zeroLevel'	 =>		$numZeroLevelDefault,
				 'zeroLevelTol'	 =>		$numZeroLevelTolDefault,
				 'relTol'		 =>		$numRelPercentTolDefault,
				 'debug'		 =>		0,
	 );

	num_cmp([$correctAnswer], %options);
}

##	See std_num_cmp_list for usage
sub frac_num_cmp_list {
	my ( $relPercentTol, $format, @answerList ) = @_;

	my %options = (			 'relTol'	 =>		$relPercentTol,
							 'format'		 =>		$format
	);

	set_default_options( \%options,
			 'tolType'		 =>		'relative',
			 'tolerance'	 =>		$relPercentTol,
			 'mode'			 =>		'frac',
			 'format'		 =>		$numFormatDefault,
			 'zeroLevel'	 =>		$numZeroLevelDefault,
			 'zeroLevelTol'	 =>		$numZeroLevelTolDefault,
			 'relTol'		 =>		$numRelPercentTolDefault,
			 'debug'		 =>		0,
	);

	num_cmp(\@answerList, %options);
}

sub frac_num_cmp_abs {			# only allow fraction expressions as submitted answer with absolute tolerance
    my ( $correctAnswer, $absTol, $format ) = @_;

    my %options = (           	'tolerance'    =>     $absTol,
		        	'format'       =>     $format
    );

	set_default_options (\%options,
			'tolType'	   =>	  'absolute',
			'tolerance'	   =>	  $absTol,
			'mode'		   =>	  'frac',
			'format'	   =>	  $numFormatDefault,
			'zeroLevel'	   =>	  0,
			'zeroLevelTol' =>	  0,
			'debug'		   =>	  0,
	);

    num_cmp([$correctAnswer], %options);
}

##	See std_num_cmp_list for usage

sub frac_num_cmp_abs_list {
    my ( $absTol, $format, @answerList ) = @_;

    my %options = (           	'tolerance'    =>     $absTol,
			      	'format'       =>     $format
    );

    set_default_options (\%options,
			 'tolType'      =>     'absolute',
			 'tolerance'    =>     $absTol,
			 'mode'         =>     'frac',
			 'format'       =>     $numFormatDefault,
			 'zeroLevel'    =>     0,
			 'zeroLevelTol' =>     0,
			 'debug'        =>     0,
    );

    num_cmp(\@answerList, %options);
}


sub arith_num_cmp {						# only allow arithmetic expressions as submitted answer

    my ( $correctAnswer, $relPercentTol, $format, $zeroLevel, $zeroLevelTol ) = @_;

    my %options = (     'relTol'      =>     $relPercentTol,
			'format'         =>     $format,
			'zeroLevel'      =>     $zeroLevel,
			'zeroLevelTol'   =>     $zeroLevelTol
    );

    set_default_options( \%options,
                        'tolType'       =>     'relative',
                        'tolerance'     =>     $relPercentTol,
                        'mode'          =>     'arith',
                        'format'        =>     $numFormatDefault,
                        'zeroLevel'     =>     $numZeroLevelDefault,
                        'zeroLevelTol'  =>     $numZeroLevelTolDefault,
                        'relTol'        =>     $numRelPercentTolDefault,
                        'debug'         =>     0,
    );

    num_cmp([$correctAnswer], %options);
}

##	See std_num_cmp_list for usage
sub arith_num_cmp_list {
    my ( $relPercentTol, $format, @answerList ) = @_;

    my %options = (     'relTol'     =>     $relPercentTol,
                        'format'        =>     $format,
    );

    set_default_options( \%options,
                         'tolType'       =>     'relative',
                         'tolerance'     =>     $relPercentTol,
                         'mode'          =>     'arith',
                         'format'        =>     $numFormatDefault,
                         'zeroLevel'     =>     $numZeroLevelDefault,
                         'zeroLevelTol'  =>     $numZeroLevelTolDefault,
                         'relTol'        =>     $numRelPercentTolDefault,
                         'debug'         =>     0,
    );

    num_cmp(\@answerList, %options);
}

sub arith_num_cmp_abs {			# only allow arithmetic expressions as submitted answer with absolute tolerance
    my ( $correctAnswer, $absTol, $format ) = @_;

    my %options = (      'tolerance'    =>     $absTol,
                         'format'       =>     $format
    );

    set_default_options (\%options,
                         'tolType'      =>     'absolute',
                         'tolerance'    =>     $absTol,
                         'mode'         =>     'arith',
                         'format'       =>     $numFormatDefault,
                         'zeroLevel'    =>     0,
                         'zeroLevelTol' =>     0,
                         'debug'        =>     0,
    );

    num_cmp([$correctAnswer], %options);
}

##	See std_num_cmp_list for usage
sub arith_num_cmp_abs_list {
    my ( $absTol, $format, @answerList ) = @_;

    my %options = (      'tolerance'    =>     $absTol,
                         'format'       =>     $format
    );

    set_default_options (\%options,
                         'tolType'      =>     'absolute',
                         'tolerance'    =>     $absTol,
                         'mode'         =>     'arith',
                         'format'       =>     $numFormatDefault,
                         'zeroLevel'    =>     0,
                         'zeroLevelTol' =>     0,
                         'debug'        =>     0,
    );

    num_cmp(\@answerList, %options);
}

sub strict_num_cmp {					# only allow numbers as submitted answer
    my ( $correctAnswer, $relPercentTol, $format, $zeroLevel, $zeroLevelTol ) = @_;

    my %options = (      'relTol'     =>     $relPercentTol,
                         'format'        =>     $format,
                         'zeroLevel'     =>     $zeroLevel,
                         'zeroLevelTol'  =>     $zeroLevelTol
    );

    set_default_options( \%options,
                         'tolType'       =>     'relative',
                         'tolerance'     =>     $relPercentTol,
                         'mode'          =>     'strict',
                         'format'        =>     $numFormatDefault,
                         'zeroLevel'     =>     $numZeroLevelDefault,
                         'zeroLevelTol'  =>     $numZeroLevelTolDefault,
                         'relTol'        =>     $numRelPercentTolDefault,
                         'debug'         =>     0,
    );
    num_cmp([$correctAnswer], %options);

}

##	See std_num_cmp_list for usage
sub strict_num_cmp_list	{				# compare numbers
    my ( $relPercentTol, $format, @answerList ) = @_;

    my %options = (  	 'relTol'     =>     $relPercentTol,
			 'format'        =>     $format,
    );

    set_default_options( \%options,
                         'tolType'       =>     'relative',
                         'tolerance'     =>     $relPercentTol,
                         'mode'          =>     'strict',
                         'format'        =>     $numFormatDefault,
                         'zeroLevel'     =>     $numZeroLevelDefault,
                         'zeroLevelTol'  =>     $numZeroLevelTolDefault,
                         'relTol'        =>     $numRelPercentTolDefault,
                         'debug'         =>     0,
    );

    num_cmp(\@answerList, %options);
}


sub strict_num_cmp_abs {				# only allow numbers as submitted answer with absolute tolerance
    my ( $correctAnswer, $absTol, $format ) = @_;

    my %options = (       'tolerance'    =>     $absTol,
	                  'format'       =>     $format
    );

    set_default_options (\%options,
                         'tolType'      =>     'absolute',
                         'tolerance'    =>     $absTol,
                         'mode'         =>     'strict',
                         'format'       =>     $numFormatDefault,
                         'zeroLevel'    =>     0,
                         'zeroLevelTol' =>     0,
                         'debug'        =>     0,
    );
    num_cmp([$correctAnswer], %options);

}

##	See std_num_cmp_list for usage
sub strict_num_cmp_abs_list	{			# compare numbers
    my ( $absTol, $format, @answerList ) = @_;

    my %options = (      'tolerance'    =>     $absTol,
                         'format'       =>     $format
    );

    set_default_options (\%options,
                         'tolType'      =>     'absolute',
                         'tolerance'    =>     $absTol,
                         'mode'         =>     'strict',
                         'format'       =>     $numFormatDefault,
                         'zeroLevel'    =>     0,
                         'zeroLevelTol' =>     0,
                         'debug'        =>     0,
    );

    num_cmp(\@answerList, %options);
}

## sub numerical_compare_with_units
## Compares a number with units
## Deprecated; use num_cmp()
##
## IN:	a string which includes the numerical answer and the units
##		a hash with the following keys (all optional):
##			mode		--	'std', 'frac', 'arith', or 'strict'
##			format		--	the format to use when displaying the answer
##			tol		--	an absolute tolerance, or
##			relTol		--	a relative tolerance
##			zeroLevel	--	if the correct answer is this close to zero, then zeroLevelTol applies
##			zeroLevelTol	--	absolute tolerance to allow when correct answer is close to zero

# This mode is depricated.  send input through num_cmp -- it can handle units.

sub numerical_compare_with_units {
	my $correct_answer = shift;	 # the answer is a string which	includes both the numerical answer and the units.
	my %options	= @_;		 # all of the other inputs are (key value) pairs

	# Prepare the correct answer
	$correct_answer	= str_filters( $correct_answer, 'trim_whitespace' );

	# it surprises me that the match below works since the first .*	is greedy.
	my ($correct_num_answer, $correct_units) = $correct_answer =~ /^(.*)\s+([^\s]*)$/;
	$options{units} = $correct_units;

	num_cmp($correct_num_answer, %options);
}


=head3 std_num_str_cmp()

NOTE:	This function is maintained for compatibility. num_cmp() with the
		'strings' parameter is slightly preferred.

std_num_str_cmp() is used when the correct answer could be either a number or a
string. For example, if you wanted the student to evaluate a function at number
of points, but write "Inf" or "Minf" if the function is unbounded. This routine
will provide error messages that do not give a hint as to whether the correct
answer is a string or a number. For numerical comparisons, std_num_cmp() is
used internally; for string comparisons, std_str_cmp() is used.  String answers
must consist entirely of letters except that an initial minus sign is allowed.
E.g. "inf" and "-inf" are valid strings where as "too-big" is not.

 std_num_str_cmp( $correctAnswer ) OR
 std_num_str_cmp( $correctAnswer, $ra_legalStrings ) OR
 std_num_str_cmp( $correctAnswer, $ra_legalStrings, $relPercentTol ) OR
 std_num_str_cmp( $correctAnswer, $ra_legalStrings, $relPercentTol, $format ) OR
 std_num_str_cmp( $correctAnswer, $ra_legalStrings, $relPercentTol, $format, $zeroLevel ) OR
 std_num_str_cmp( $correctAnswer, $ra_legalStrings, $relPercentTol, $format,
					$zeroLevel, $zeroLevelTol )

	$correctAnswer		--	the correct answer
	$ra_legalStrings	--	a reference to an array of legal strings, e.g. ["str1", "str2"]
	$relPercentTol		--	the error tolerance as a percentage
	$format			--	the display format
	$zeroLevel		--	if the correct answer is this close to zero, then zeroLevelTol applies
	$zeroLevelTol		--	absolute tolerance to allow when correct answer is close to zero

Examples:
	ANS( std_num_str_cmp( $ans, ["Inf", "Minf", "NaN"] ) );
	ANS( std_num_str_cmp( $ans, ["INF", "-INF"] ) );

=cut

sub std_num_str_cmp {
	my ( $correctAnswer, $ra_legalStrings, $relpercentTol, $format, $zeroLevel, $zeroLevelTol ) = @_;
	# warn ('This method is depreciated.  Use num_cmp instead.');
	return num_cmp ($correctAnswer, strings=>$ra_legalStrings, relTol=>$relpercentTol, format=>$format,
		zeroLevel=>$zeroLevel, zeroLevelTol=>$zeroLevelTol);
}

sub NUM_CMP {                              # low level numeric compare (now uses Parser)
	return ORIGINAL_NUM_CMP(@_)
	  if main::PG_restricted_eval(q!$main::useOldAnswerMacros!);

	my %num_params = @_;

	#
	#  check for required parameters
	#
	my @keys = qw(correctAnswer tolerance tolType format mode zeroLevel zeroLevelTol debug);
	foreach my $key (@keys) {
	    warn "$key must be defined in options when calling NUM_CMP"
	      unless defined($num_params{$key});
	}

	my $correctAnswer = $num_params{correctAnswer};
	my $mode          = $num_params{mode};
	my %options       = (debug => $num_params{debug});

	#
	#  Hack to fix up exponential notation in correct answer
	#  (e.g., perl will pass .0000001 as 1e-07).
	#
	$correctAnswer = uc($correctAnswer)
	  if $correctAnswer =~ m/e/ && Value::isNumber($correctAnswer);

	#
	#  Get an apppropriate context based on the mode
	#
	my $context;
	for ($mode) {
	  /^strict$/i    and do {
	    $context = $Parser::Context::Default::context{LimitedNumeric}->copy;
	    last;
	  };
	  /^arith$/i     and do {
	    $context = $Parser::Context::Default::context{LegacyNumeric}->copy;
	    $context->functions->disable('All');
	    last;
	  };
	  /^frac$/i	 and do {
	    $context = $Parser::Context::Default::context{'LimitedNumeric-Fraction'}->copy;
	    last;
	  };

	  # default
	  $context = $Parser::Context::Default::context{LegacyNumeric}->copy;
	}
	$context->{format}{number} = $num_params{'format'};
	$context->strings->clear;
	#  FIXME:  should clear variables as well? Copy them from the current context?
	
	#
	#  Add the strings to the context
	#
	if ($num_params{strings}) {
	  foreach my $string (@{$num_params{strings}}) {
	    my %tex = ($string =~ m/^(-?)inf(inity)?$/i)? (TeX => "$1\\infty"): ();
	    %tex = (TeX => "-\\infty") if uc($string) eq "MINF";
	    $context->strings->add(uc($string) => {%tex});
	  }
	}

	#
	#  Set the tolerances
	#
	if ($num_params{tolType} eq 'absolute') {
	  $context->flags->set(
	    tolerance => $num_params{tolerance},
	    tolType => 'absolute',
	  );
	} else {
	  $context->flags->set(
	    tolerance => .01*$num_params{tolerance},
	    tolType => 'relative',
	  );
	}
	$context->flags->set(
	  zeroLevel => $num_params{zeroLevel},
	  zeroLevelTol => $num_params{zeroLevelTol},
	);

	#
	#  Get the proper Parser object for the professor's answer
	#  using the initialized context
	#
	my $oldContext = &$Context(); &$Context($context); my $r;
	if ($num_params{units}) {
	  $r = new Parser::Legacy::NumberWithUnits($correctAnswer);
          $options{rh_correct_units} = $num_params{units};
	} else {
	  $r = Value::Formula->new($correctAnswer);
	  die "The professor's answer can't be a formula" unless $r->isConstant;
	  $r = $r->eval; $r = new Value::Real($r) unless Value::class($r) eq 'String';
	  $r->{correct_ans} = $correctAnswer;
	  if ($mode eq 'phase_pi') {
	    my $pi = 4*atan2(1,1);
	    while ($r >  $pi/2) {$r -= $pi}
	    while ($r < -$pi/2) {$r += $pi}
	  }
	}
	#
	#  Get the answer checker from the parser object
	#
	my $cmp = $r->cmp(%options);
	$cmp->install_pre_filter(sub {
	  my $rh_ans = shift;
	  $rh_ans->{original_student_ans} = $rh_ans->{student_ans};
	  $rh_ans->{original_correct_ans} = $rh_ans->{correct_ans};
	  return $rh_ans;
	});
	$cmp->install_post_filter(sub {
	  my $rh_ans = shift;
	  $rh_ans->{student_ans} = $rh_ans->{student_value}->string
	    if ref($rh_ans->{student_value});
	  return $rh_ans;
	});
	&$Context($oldContext);

	return $cmp;
}

#
#  The original version, for backward compatibility
#  (can be removed when the Parser-based version is more fully tested.)
#
sub ORIGINAL_NUM_CMP {		# low level	numeric	compare
	my %num_params = @_;

	my @keys = qw ( correctAnswer tolerance tolType format mode zeroLevel zeroLevelTol debug );
	foreach my $key (@keys) {
	    warn "$key must be defined in options when calling NUM_CMP" unless defined ($num_params{$key});
	}

	my $correctAnswer	=	$num_params{'correctAnswer'};
	my $format		    =	$num_params{'format'};
	my $mode		    =	$num_params{'mode'};

	if( $num_params{tolType} eq 'relative' ) {
		$num_params{'tolerance'} = .01*$num_params{'tolerance'};
	}

	my $formattedCorrectAnswer;
	my $correct_units;
	my $correct_num_answer;
	my %correct_units;
	my $corrAnswerIsString = 0;


	if (defined($num_params{units}) && $num_params{units}) {
		$correctAnswer	= str_filters( $correctAnswer, 'trim_whitespace' );
						# units are in form stuff space units where units contains no spaces.

		($correct_num_answer, $correct_units) = $correctAnswer =~ /^(.*)\s+([^\s]*)$/;
		%correct_units = Units::evaluate_units($correct_units);
		if ( defined( $correct_units{'ERROR'} ) ) {
			 warn ("ERROR: The answer \"$correctAnswer\" in the problem definition cannot be parsed:\n" .
			 	"$correct_units{'ERROR'}\n");
		}
		# $formattedCorrectAnswer = spf($correct_num_answer,$num_params{'format'}) . " $correct_units";
		$formattedCorrectAnswer = prfmt($correct_num_answer,$num_params{'format'}) . " $correct_units";

	} elsif (defined($num_params{strings}) && $num_params{strings}) {
		my $legalString	= '';
		my @legalStrings = @{$num_params{strings}};
		$correct_num_answer = $correctAnswer;
		$formattedCorrectAnswer = $correctAnswer;
		foreach	$legalString (@legalStrings) {
			if ( uc($correctAnswer) eq uc($legalString) ) {
				$corrAnswerIsString	= 1;

				last;
			}
		}		  ## at	this point $corrAnswerIsString = 0 iff correct answer is numeric
	} else {
		$correct_num_answer = $correctAnswer;
		$formattedCorrectAnswer = prfmt( $correctAnswer, $num_params{'format'} );
	}

	$correct_num_answer = math_constants($correct_num_answer);

	my $PGanswerMessage = '';

	my ($inVal,$correctVal,$PG_eval_errors,$PG_full_error_report);

	if (defined($correct_num_answer) && $correct_num_answer =~ /\S/ && $corrAnswerIsString == 0 )	{
			($correctVal, $PG_eval_errors,$PG_full_error_report) = PG_answer_eval($correct_num_answer);
	} else { # case of a string answer
		$PG_eval_errors	= '	';
		$correctVal = $correctAnswer;
	}

	if ( ($PG_eval_errors && $corrAnswerIsString == 0) or ((not is_a_number($correctVal)) && $corrAnswerIsString == 0)) {
				##error message from eval or above
		warn "Error in 'correct' answer: $PG_eval_errors<br>
		      The answer $correctAnswer evaluates to $correctVal,
		      which cannot be interpreted as a number.  ";

	}
	#########################################################################

	#construct the answer evaluator
    	my $answer_evaluator = new AnswerEvaluator;
    	$answer_evaluator->{debug} = $num_params{debug};
    	$answer_evaluator->ans_hash(
    						correct_ans 			=> 	$correctVal,
    					 	type					=>	"${mode}_number",
    					 	tolerance				=>	$num_params{tolerance},
					 		tolType					=>	$num_params{tolType},
					 		units					=> 	$correct_units,
     					 	original_correct_ans	=>	$formattedCorrectAnswer,
     					 	rh_correct_units		=>      \%correct_units,
     					 	answerIsString			=>	$corrAnswerIsString,
     	);
    	my ($in, $formattedSubmittedAnswer);
	$answer_evaluator->install_pre_filter(sub {my $rh_ans = shift;
		$rh_ans->{original_student_ans} = $rh_ans->{student_ans}; $rh_ans;}
	);

	

	if (defined($num_params{units}) && $num_params{units}) {
			$answer_evaluator->install_pre_filter(\&check_units);
	}
	if (defined($num_params{strings}) && $num_params{strings}) {
			$answer_evaluator->install_pre_filter(\&check_strings, %num_params);
	}
	
	## FIXME? - this pre filter was moved before check_units to allow
	## 	    for latex preview of answers with no units.
	##          seems to work but may have unintended side effects elsewhere.
	
	##      Actually it caused trouble with the check strings package so it has been moved back
	#       We'll try some other method  -- perhaps add code to fix_answer for display
	$answer_evaluator->install_pre_filter(\&check_syntax);

	$answer_evaluator->install_pre_filter(\&math_constants);

	if ($mode eq 'std')	{
				# do nothing
	} elsif ($mode eq 'strict') {
		$answer_evaluator->install_pre_filter(\&is_a_number);
	} elsif ($mode eq 'arith') {
			$answer_evaluator->install_pre_filter(\&is_an_arithmetic_expression);
		} elsif ($mode eq 'frac') {
			$answer_evaluator->install_pre_filter(\&is_a_fraction);

		} elsif ($mode eq 'phase_pi') {
			$answer_evaluator->install_pre_filter(\&phase_pi);

		} else {
			$PGanswerMessage = 'Tell your professor	that there is an error in his or her answer mechanism. No mode was specified.';
			$formattedSubmittedAnswer =	$in;
		}

	if ($corrAnswerIsString == 0 ){		# avoiding running compare_numbers when correct answer is a string.
		$answer_evaluator->install_evaluator(\&compare_numbers, %num_params);
	 }


###############################################################################
# We'll leave these next lines out for now, so that the evaluated versions of the student's and professor's
# can be displayed in the answer message.  This may still cause a few anomolies when strings are used
#
###############################################################################

	$answer_evaluator->install_post_filter(\&fix_answers_for_display);

     	$answer_evaluator->install_post_filter(sub {my $rh_ans = shift;
					return $rh_ans unless $rh_ans->catch_error('EVAL');
					$rh_ans->{student_ans} = $rh_ans->{original_student_ans}. ' '. $rh_ans->{error_message};
					$rh_ans->clear_error('EVAL'); } );
     	$answer_evaluator->install_post_filter(sub {my $rh_ans = shift; $rh_ans->clear_error('SYNTAX'); } );
     	$answer_evaluator->install_post_filter(sub {my $rh_ans = shift; $rh_ans->clear_error('UNITS'); } );
     	$answer_evaluator->install_post_filter(sub {my $rh_ans = shift; $rh_ans->clear_error('NUMBER'); } );
	    $answer_evaluator->install_post_filter(sub {my $rh_ans = shift; $rh_ans->clear_error('STRING'); } );
     	$answer_evaluator;
}



##########################################################################
##########################################################################
## Function answer evaluators

=head2 Function Answer Evaluators

Function answer evaluators take in a function, compare it numerically to a
correct function, and return a score. They can require an exactly equivalent
function, or one that is equal up to a constant. They can accept or reject an
answer based on specified tolerances for numerical deviation.

Function Comparison Options

	correctEqn	--	The correct equation, specified as a string. It may include
					all basic arithmetic operations, as well as elementary
					functions. Variable usage is described below.

	Variables	--	The independent variable(s). When comparing the correct
					equation to the student equation, each variable will be
					replaced by a certain number of numerical values. If
					the student equation agrees numerically with the correct
					equation, they are considered equal. Note that all
					comparison is numeric; it is possible (although highly
					unlikely and never a practical concern) for two unequal
					functions to yield the same numerical results.

	Limits		--	The limits of evaluation for the independent variables.
					Each variable is evaluated only in the half-open interval
					[lower_limit, upper_limit). This is useful if the function
					has a singularity or is not defined in a certain range.
					For example, the function "sqrt(-1-x)" could be evaluated
					in [-2,-1).

	Tolerance	--	Tolerance in function comparisons works exactly as in
					numerical comparisons; see the numerical comparison
					documentation for a complete description. Note that the
					tolerance does applies to the function as a whole, not
					each point individually.

	Number of	--	Specifies how many points to evaluate each variable at. This
	Points			is typically 3, but can be set higher if it is felt that
					there is a strong possibility of "false positives."

	Maximum		--	Sets the maximum size of the constant of integration. For
	Constant of		technical reasons concerning floating point arithmetic, if
	Integration		the additive constant, i.e., the constant of integration, is
					greater (in absolute value) than maxConstantOfIntegration
					AND is greater than maxConstantOfIntegration times the
					correct value, WeBWorK will give an error message saying
					that it can not handle such a large constant of integration.
					This is to prevent e.g. cos(x) + 1E20 or even 1E20 as being
					accepted as a correct antiderivatives of sin(x) since
					floating point arithmetic cannot tell the difference
					between cos(x) + 1E20, 1E20, and -cos(x) + 1E20.

Technical note: if you examine the code for the function routines, you will see
that most subroutines are simply doing some basic error-checking and then
passing the parameters on to the low-level FUNCTION_CMP(). Because this routine
is set up to handle multivariable functions, with single-variable functions as
a special case, it is possible to pass multivariable parameters to single-
variable functions. This usage is strongly discouraged as unnecessarily
confusing. Avoid it.

Default Values (As of 7/24/2000) (Option -- Variable Name -- Value)

	Variable			--	$functVarDefault			--	'x'
	Relative Tolerance		--	$functRelPercentTolDefault		--	.1
	Absolute Tolerance		--	$functAbsTolDefault			--	.001
	Lower Limit			--	$functLLimitDefault			--	.0000001
	Upper Limit			--	$functULimitDefault			--	1
	Number of Points		--	$functNumOfPoints			--	3
	Zero Level			--	$functZeroLevelDefault			--	1E-14
	Zero Level Tolerance		--	$functZeroLevelTolDefault		--	1E-12
	Maximum Constant		--	$functMaxConstantOfIntegration		--	1E8
		of Integration

=cut



=head3 fun_cmp()

Compares a function or a list of functions, using a named hash of options to set
parameters. This can make for more readable code than using the function_cmp()
style, but some people find one or the other easier to remember.

ANS( fun_cmp( answer or answer_array_ref, options_hash ) );

	1. a string containing the correct function, or a reference to an
		array of correct functions
	2. a hash containing the following items (all optional):
		var						--	either the number of variables or a reference to an
											array of variable names (see below)
		limits						--	reference to an array of arrays of limits (see below), or:
		mode						--	'std' (default) (function must match exactly), or:
										'antider' (function must match up to a constant)
		relTol						--	(default) a relative tolerance (as a percentage), or:
		tol						--	an absolute tolerance for error
		numPoints					--	the number of points to evaluate the function at
		maxConstantOfIntegration			--	maximum size of the constant of integration
		zeroLevel					--	if the correct answer is this close to zero, then
											zeroLevelTol applies
		zeroLevelTol					--	absolute tolerance to allow when answer is close to zero
	  test_points    -- a list of points to use in checking the function, or a list of lists when there is more than one variable.
		params						   	an array of "free" parameters which can be used to adapt
								   	the correct answer to the submitted answer. (e.g. ['c'] for
								   	a constant of integration in the answer x^3/3 + c.
		debug						-- 	when set to 1 this provides extra information while checking the
		 						        the answer.

	Returns an answer evaluator, or (if given a reference to an array
	of answers), a list of answer evaluators

ANSWER:

	The answer must be in the form of a string. The answer can contain
	functions, pi, e, and arithmetic operations. However, the correct answer
	string follows a slightly stricter syntax than student answers; specifically,
	there is no implicit multiplication. So the correct answer must be "3*x" rather
	than "3 x". Students can still enter "3 x".

VARIABLES:

	The var parameter can contain either a number or a reference to an array of
	variable names. If it contains a number, the variables are named automatically
	as follows:	1 variable	--	x
			2 variables	--	x, y
			3 variables	--	x, y, z
			4 or more	--	x_1, x_2, x_3, etc.
	If the var parameter contains a reference to an array of variable names, then
	the number of variables is determined by the number of items in the array. A
	reference to an array is created with brackets, e.g. "var => ['r', 's', 't']".
	If only one variable is being used, you can write either "var => ['t']" for
	consistency or "var => 't'" as a shortcut. The default is one variable, x.

LIMITS:

	Limits are specified with the limits parameter. You may NOT use llimit/ulimit.
	If you specify limits for one variable, you must specify them for all variables.
	The limit parameter must be a reference to an array of arrays of the form
	[lower_limit. upper_limit], each array corresponding to the lower and upper
	endpoints of the (half-open) domain of one variable. For example,
	"vars => 2, limits => [[0,2], [-3,8]]" would cause x to be evaluated in [0,2) and
	y to be evaluated in [-3,8). If only one variable is being used, you can write
	either "limits => [[0,3]]" for consistency or "limits => [0,3]" as a shortcut.

TEST POINTS:

  In some cases, the problem writer may want to specify the points
  used to check a particular function.  For example, if you want to
  use only integer values, they can be specified.  With one variable,
  you can specify "test_points => [1,4,5,6]" or "test_points => [[1,4,5,6]]".
  With more variables, specify the list for the first variable, then the
  second, and so on: "vars=>['x','y'], test_points => [[1,4,5],[7,14,29]]".

  If the problem writer wants random values which need to meet some special
  restrictions (such as being integers), they can be generated in the problem:
  "test_points=>[random(1,50), random(1,50), random(1,50), random(1,50)]".

  Note that test_points should not be used for function checks which involve
  parameters  (either explicitly given by "params", or as antiderivatives).

EXAMPLES:

	fun_cmp( "3*x" )	--	standard compare, variable is x
	fun_cmp( ["3*x", "4*x+3", "3*x**2"] )	--	standard compare, defaults used for all three functions
	fun_cmp( "3*t", var => 't' )	--	standard compare, variable is t
	fun_cmp( "5*x*y*z", var => 3 )	--	x, y and z are the variables
	fun_cmp( "5*x", mode => 'antider' )	--	student answer must match up to constant (i.e., 5x+C)
	fun_cmp( ["3*x*y", "4*x*y"], limits => [[0,2], [5,7]] )	--	x evaluated in [0,2)
																y evaluated in [5,7)

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

=head3 Single-variable Function Comparisons

There are four single-variable function answer evaluators: "normal," absolute
tolerance, antiderivative, and antiderivative with absolute tolerance. All
parameters (other than the correct equation) are optional.

 function_cmp( $correctEqn ) OR
 function_cmp( $correctEqn, $var ) OR
 function_cmp( $correctEqn, $var, $llimit, $ulimit ) OR
 function_cmp( $correctEqn, $var, $llimit, $ulimit, $relPercentTol ) OR
 function_cmp( $correctEqn, $var, $llimit, $ulimit,
				$relPercentTol, $numPoints ) OR
 function_cmp( $correctEqn, $var, $llimit, $ulimit,
				$relPercentTol, $numPoints, $zeroLevel ) OR
 function_cmp( $correctEqn, $var, $llimit, $ulimit, $relPercentTol, $numPoints,
				$zeroLevel,$zeroLevelTol )

	$correctEqn		--	the correct equation, as a string
	$var			--	the string representing the variable (optional)
	$llimit			--	the lower limit of the interval to evaluate the
							variable in (optional)
	$ulimit			--	the upper limit of the interval to evaluate the
							variable in (optional)
	$relPercentTol	--	the error tolerance as a percentage (optional)
	$numPoints		--	the number of points at which to evaluate the
							variable (optional)
	$zeroLevel		--	if the correct answer is this close to zero, then
							zeroLevelTol applies (optional)
	$zeroLevelTol	--	absolute tolerance to allow when answer is close to zero

	function_cmp() uses standard comparison and relative tolerance. It takes a
	string representing a single-variable function and compares the student
	answer to that function numerically.

 function_cmp_up_to_constant( $correctEqn ) OR
 function_cmp_up_to_constant( $correctEqn, $var ) OR
 function_cmp_up_to_constant( $correctEqn, $var, $llimit, $ulimit ) OR
 function_cmp_up_to_constant( $correctEqn, $var, $llimit, $ulimit,
								$relpercentTol ) OR
 function_cmp_up_to_constant( $correctEqn, $var, $llimit, $ulimit,
								$relpercentTol, $numOfPoints ) OR
 function_cmp_up_to_constant( $correctEqn, $var, $llimit, $ulimit,
								$relpercentTol, $numOfPoints,
								$maxConstantOfIntegration ) OR
 function_cmp_up_to_constant( $correctEqn, $var, $llimit, $ulimit,
								$relpercentTol, $numOfPoints,
								$maxConstantOfIntegration, $zeroLevel)  OR
 function_cmp_up_to_constant( $correctEqn, $var, $llimit, $ulimit,
								$relpercentTol, $numOfPoints,
								$maxConstantOfIntegration,
								$zeroLevel, $zeroLevelTol )

	$maxConstantOfIntegration	--	the maximum size of the constant of
									integration

	function_cmp_up_to_constant() uses antiderivative compare and relative
	tolerance. All options work exactly like function_cmp(), except of course
	$maxConstantOfIntegration. It will accept as correct any function which
	differs from $correctEqn by at most a constant; that is, if
		$studentEqn = $correctEqn + C
	the answer is correct.

 function_cmp_abs( $correctFunction ) OR
 function_cmp_abs( $correctFunction, $var ) OR
 function_cmp_abs( $correctFunction, $var, $llimit, $ulimit ) OR
 function_cmp_abs( $correctFunction, $var, $llimit, $ulimit, $absTol ) OR
 function_cmp_abs( $correctFunction, $var, $llimit, $ulimit, $absTol,
					$numOfPoints )

	$absTol	--	the tolerance as an absolute value

	function_cmp_abs() uses standard compare and absolute tolerance. All
	other options work exactly as for function_cmp().

 function_cmp_up_to_constant_abs( $correctFunction ) OR
 function_cmp_up_to_constant_abs( $correctFunction, $var ) OR
 function_cmp_up_to_constant_abs( $correctFunction, $var, $llimit, $ulimit ) OR
 function_cmp_up_to_constant_abs( $correctFunction, $var, $llimit, $ulimit,
									$absTol ) OR
 function_cmp_up_to_constant_abs( $correctFunction, $var, $llimit, $ulimit,
									$absTol, $numOfPoints ) OR
 function_cmp_up_to_constant_abs( $correctFunction, $var, $llimit, $ulimit,
									$absTol, $numOfPoints,
									$maxConstantOfIntegration )

	function_cmp_up_to_constant_abs() uses antiderivative compare
	and absolute tolerance. All other options work exactly as with
	function_cmp_up_to_constant().

Examples:

	ANS( function_cmp( "cos(x)" ) )	--	Accepts cos(x), sin(x+pi/2),
		sin(x)^2 + cos(x) + cos(x)^2 -1, etc. This assumes
		$functVarDefault has been set to "x".
	ANS( function_cmp( $answer, "t" ) )	--	Assuming $answer is "cos(t)",
		accepts cos(t), etc.
	ANS( function_cmp_up_to_constant( "cos(x)" ) )	--	Accepts any
		antiderivative of sin(x), e.g. cos(x) + 5.
	ANS( function_cmp_up_to_constant( "cos(z)", "z" ) )	--	Accepts any
		antiderivative of sin(z), e.g. sin(z+pi/2) + 5.

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

## The following answer evaluator for comparing multivarable functions was
## contributed by Professor William K. Ziemer
## (Note: most of the multivariable functionality provided by Professor Ziemer
## has now been integrated into fun_cmp and FUNCTION_CMP)
############################
# W.K. Ziemer, Sep. 1999
# Math Dept. CSULB
# email: wziemer@csulb.edu
############################

=head3 multivar_function_cmp

NOTE:	this function is maintained for compatibility. fun_cmp() is
		slightly preferred.

usage:

	multivar_function_cmp( $answer, $var_reference, options)
		$answer				--	string, represents function of several variables
		$var_reference		--	number (of variables), or list reference (e.g. ["var1","var2"] )
	options:
		$limit_reference	--	reference to list of lists (e.g. [[1,2],[3,4]])
		$relPercentTol		--	relative percent tolerance in answer
		$numPoints			--	number of points to sample in for each variable
		$zeroLevel			--	if the correct answer is this close to zero, then zeroLevelTol applies
		$zeroLevelTol		--	absolute tolerance to allow when answer is close to zero

=cut

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
	  if main::PG_restricted_eval(q!$main::useOldAnswerMacros!);

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
	
	if($tolType eq 'relative') {
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
	my $context = $Parser::Context::Default::context{"LegacyNumeric"}->copy;
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
	foreach $x (@{$func_params{'var'}}) {
	  if (length($x) > 1) {
	    $context->{_variables}->{pattern} = $context->{_variables}->{namePattern} =
	      $x . '|' . $context->{_variables}->{pattern};
	    $context->update;
	  }
	  $variables{$x} = 'Real';
	}
	foreach $x (@{$func_params{'params'}}) {$variables{$x} = 'Parameter'}
	$context->variables->are(%variables);

	#
	#  Create the Formula object and get its answer checker
	#
	my $oldContext = &$Context(); &$Context($context);
	my $f = new Value::Formula($correctEqn);
	$f->{limits}      = $func_params{'limits'};
	$f->{test_points} = $func_params{'test_points'};
	my $cmp = $f->cmp(%options);
	&$Context($oldContext);

	#
	#  Get previous answer from hidden field of form
	#
	$cmp->install_pre_filter(
	  sub {
	    my $rh_ans = shift;
	    $rh_ans->{_filter_name} = "fetch_previous_answer";
	    my $prev_ans_label = "previous_".$rh_ans->{ans_label};
	    $rh_ans->{prev_ans} = 
	      (defined $inputs_ref->{$prev_ans_label} and
	       $inputs_ref->{$prev_ans_label} =~/\S/) ? $inputs_ref->{$prev_ans_label} : undef; 
	    $rh_ans;
	  }
	);

	#
	#  Parse the previous answer, if any
	#
	$cmp->install_evaluator(
	  sub {
	    my $rh_ans = shift;
	    $rh_ans->{_filter_name} = "parse_previous_answer";
	    return $rh_ans unless defined $rh_ans->{prev_ans};
	    my $oldContext = &$Context();
	    &$Context($rh_ans->{correct_value}{context});
	    $rh_ans->{prev_formula} = Parser::Formula($rh_ans->{prev_ans});
	    &$Context($oldContext);
	    $rh_ans;
	  }
	);

	#
	#  Check if previous answer equals this current one
	#
	$cmp->install_evaluator(
	  sub {
	    my $rh_ans = shift;
	    $rh_ans->{_filter_name} = "compare_to_previous_answer";
	    return $rh_ans unless defined($rh_ans->{prev_formula}) && defined($rh_ans->{student_formula});
	    $rh_ans->{prev_equals_current} =
	      Value::cmp_compare($rh_ans->{student_formula},$rh_ans->{prev_formula},{});
	    $rh_ans;
	  }
	);

	#
	#  Produce a message if the previous answer equals this one
	#  (and is not correct, and is not specified the same way)
	#
	$cmp->install_post_filter(
	  sub {
	    my $rh_ans = shift;
	    $rh_ans->{_filter_name} = "produce_equivalence_message";
	    return $rh_ans unless $rh_ans->{prev_equals_current} && $rh_ans->{score} == 0;
	    # the match is exact don't give an error since the previous entry
	    # might have been from the preview button
		return $rh_ans if $rh_ans->{prev_ans} eq $rh_ans->{original_student_ans};
	    $rh_ans->{ans_message} = "This answer is equivalent to the one you just submitted or previewed.";
	    $rh_ans;
	  }
	);

	return $cmp;
}
	
#
#  The original version, for backward compatibility
#  (can be removed when the Parser-based version is more fully tested.)
#
sub ORIGINAL_FUNCTION_CMP {
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
			my $prev_ans_label = "previous_".$rh_ans->{ans_label};
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
	
	$answer_evaluator->install_post_filter(
		sub {
			my $rh_ans = shift;
			if ( defined($rh_ans->{'ans_equals_prev_ans'}) and $rh_ans->{'ans_equals_prev_ans'} and $rh_ans->{score}==0) {
##				$rh_ans->{ans_message} = "This answer is the same as the one you just submitted or previewed.";
				$rh_ans->{ans_message} = "This answer is equivalent to the one you just submitted or previewed."; ## DPVC
			}
			$rh_ans;
		}
	);
	
	$answer_evaluator;
}


## LOW-LEVEL ROUTINE -- NOT NORMALLY FOR END USERS -- USE WITH CAUTION
##
## IN:	a hash containing the following items (error-checking to be added later?):
##			correctAnswer	--	the correct answer
##			tolerance		--	the allowable margin of error
##			tolType			--	'relative' or 'absolute'
##			format			--	the display format of the answer
##			mode			--	one of 'std', 'strict',	'arith', or	'frac';
##									determines allowable formats for the input
##			zeroLevel		--	if the correct answer is this close to zero, then zeroLevelTol applies
##			zeroLevelTol	--	absolute tolerance to allow when answer is close to zero


##########################################################################
##########################################################################
## String answer evaluators

=head2 String Answer Evaluators

String answer evaluators compare a student string to the correct string.
Different filters can be applied to allow various degrees of variation.
Both the student and correct answers are subject to the same filters, to
ensure that there are no unexpected matches or rejections.

String Filters

	remove_whitespace	--	Removes all whitespace from the string.
						It applies the following substitution
						to the string:
							$filteredAnswer =~ s/\s+//g;

	compress_whitespace	--	Removes leading and trailing whitespace, and
						replaces all other blocks of whitespace by a
						single space. Applies the following substitutions:
							$filteredAnswer =~ s/^\s*//;
							$filteredAnswer =~ s/\s*$//;
							$filteredAnswer =~ s/\s+/ /g;

	trim_whitespace		--	Removes leading and trailing whitespace.
						Applies the following substitutions:
							$filteredAnswer =~ s/^\s*//;
							$filteredAnswer =~ s/\s*$//;

	ignore_case			--	Ignores the case of the string. More accurately,
						it converts the string to uppercase (by convention).
						Applies the following function:
							$filteredAnswer = uc $filteredAnswer;

	ignore_order		--	Ignores the order of the letters in the string.
						This is used for problems of the form "Choose all
						that apply." Specifically, it removes all
						whitespace and lexically sorts the letters in
						ascending alphabetical order. Applies the following
						functions:
							$filteredAnswer = join( "", lex_sort(
								split( /\s*/, $filteredAnswer ) ) );

=cut

################################
## STRING ANSWER FILTERS

## IN:	--the string to be filtered
##		--a list of the filters to use
##
## OUT:	--the modified string
##
## Use this subroutine instead of the
## individual filters below it

sub str_filters {
	my $stringToFilter = shift @_;
	# filters now take an answer hash, so encapsulate the string 
	# in the answer hash.
	my $rh_ans = new AnswerHash;
	$rh_ans->{student_ans} = $stringToFilter;
	$rh_ans->{correct_ans}='';
	my @filters_to_use = @_;
	my %known_filters = (	
	            'remove_whitespace'		=>	\&remove_whitespace,
				'compress_whitespace'	=>	\&compress_whitespace,
				'trim_whitespace'		=>	\&trim_whitespace,
				'ignore_case'			=>	\&ignore_case,
				'ignore_order'			=>	\&ignore_order,
	);

	#test for unknown filters
	foreach my $filter ( @filters_to_use ) {
		#check that filter is known
		die "Unknown string filter $filter (try checking the parameters to str_cmp() )"
								unless exists $known_filters{$filter};
		$rh_ans = $known_filters{$filter}($rh_ans);  # apply filter.
	}
# 	foreach $filter (@filters_to_use) {
# 		die "Unknown string filter $filter (try checking the parameters to str_cmp() )"
# 								unless exists $known_filters{$filter};
# 	}
# 
# 	if( grep( /remove_whitespace/i, @filters_to_use ) ) {
# 		$rh_ans = remove_whitespace( $rh_ans );
# 	}
# 	if( grep( /compress_whitespace/i, @filters_to_use ) ) {
# 		$rh_ans = compress_whitespace( $rh_ans );
# 	}
# 	if( grep( /trim_whitespace/i, @filters_to_use ) ) {
# 		$rh_ans = trim_whitespace( $rh_ans );
# 	}
# 	if( grep( /ignore_case/i, @filters_to_use ) ) {
# 		$rh_ans = ignore_case( $rh_ans );
# 	}
# 	if( grep( /ignore_order/i, @filters_to_use ) ) {
# 		$rh_ans = ignore_order( $rh_ans );
# 	}

	return $rh_ans->{student_ans};
}
sub remove_whitespace {
	my $rh_ans = shift;
	die "expected an answer hash" unless ref($rh_ans)=~/HASH/i;
	$rh_ans->{_filter_name} = 'remove_whitespace'; 
	$rh_ans->{student_ans} =~ s/\s+//g;		# remove all whitespace
	$rh_ans->{correct_ans} =~ s/\s+//g;		# remove all whitespace
	return $rh_ans;
}

sub compress_whitespace	{
	my $rh_ans = shift;
	die "expected an answer hash" unless ref($rh_ans)=~/HASH/i;
	$rh_ans->{_filter_name} = 'compress_whitespace';
	$rh_ans->{student_ans} =~ s/^\s*//;		# remove initial whitespace
	$rh_ans->{student_ans} =~ s/\s*$//;		# remove trailing whitespace
	$rh_ans->{student_ans} =~ s/\s+/ /g;		# replace spaces by	single space
	$rh_ans->{correct_ans} =~ s/^\s*//;		# remove initial whitespace
	$rh_ans->{correct_ans} =~ s/\s*$//;		# remove trailing whitespace
	$rh_ans->{correct_ans} =~ s/\s+/ /g;		# replace spaces by	single space

	return $rh_ans;
}

sub trim_whitespace {
	my $rh_ans = shift;
	die "expected an answer hash" unless ref($rh_ans)=~/HASH/i;
	$rh_ans->{_filter_name} = 'trim_whitespace';
	$rh_ans->{student_ans} =~ s/^\s*//;		# remove initial whitespace
	$rh_ans->{student_ans} =~ s/\s*$//;		# remove trailing whitespace
	$rh_ans->{correct_ans} =~ s/^\s*//;		# remove initial whitespace
	$rh_ans->{correct_ans} =~ s/\s*$//;		# remove trailing whitespace

	return $rh_ans;
}

sub ignore_case {
	my $rh_ans = shift;
	die "expected an answer hash" unless ref($rh_ans)=~/HASH/i;
	$rh_ans->{_filter_name} = 'ignore_case';
	$rh_ans->{student_ans} =~ tr/a-z/A-Z/;
	$rh_ans->{correct_ans} =~ tr/a-z/A-Z/;
	return $rh_ans;
}

sub ignore_order {
	my $rh_ans = shift;
	die "expected an answer hash" unless ref($rh_ans)=~/HASH/i;
	$rh_ans->{_filter_name} = 'ignore_order';
	$rh_ans->{student_ans} = join( "", lex_sort( split( /\s*/, $rh_ans->{student_ans} ) ) );
	$rh_ans->{correct_ans} = join( "", lex_sort( split( /\s*/, $rh_ans->{correct_ans} ) ) );
	
	return $rh_ans;
}
# sub remove_whitespace {
# 	my $filteredAnswer = shift;
# 	
# 	$filteredAnswer =~ s/\s+//g;		# remove all whitespace
# 
# 	return $filteredAnswer;
# }
# 
# sub compress_whitespace	{
# 	my $filteredAnswer = shift;
# 
# 	$filteredAnswer =~ s/^\s*//;		# remove initial whitespace
# 	$filteredAnswer =~ s/\s*$//;		# remove trailing whitespace
# 	$filteredAnswer =~ s/\s+/ /g;		# replace spaces by	single space
# 
# 	return $filteredAnswer;
# }
# 
# sub trim_whitespace {
# 	my $filteredAnswer = shift;
# 
# 	$filteredAnswer =~ s/^\s*//;		# remove initial whitespace
# 	$filteredAnswer =~ s/\s*$//;		# remove trailing whitespace
# 
# 	return $filteredAnswer;
# }
# 
# sub ignore_case {
# 	my $filteredAnswer = shift;
# 	#warn "filtered answer is ", $filteredAnswer;
# 	#$filteredAnswer = uc $filteredAnswer;  # this didn't work on webwork xmlrpc, but does elsewhere ????
# 	$filteredAnswer =~ tr/a-z/A-Z/;
# 
# 	return $filteredAnswer;
# }
# 
# sub ignore_order {
# 	my $filteredAnswer = shift;
# 
# 	$filteredAnswer = join( "", lex_sort( split( /\s*/, $filteredAnswer ) ) );
# 
# 	return $filteredAnswer;
# }
################################
## END STRING ANSWER FILTERS


=head3 str_cmp()

Compares a string or a list of strings, using a named hash of options to set
parameters. This can make for more readable code than using the "mode"_str_cmp()
style, but some people find one or the other easier to remember.

ANS( str_cmp( answer or answer_array_ref, options_hash ) );

	1. the correct answer or a reference to an array of answers
	2. either a list of filters, or:
	   a hash consisting of
		filters - a reference to an array of filters

	Returns an answer evaluator, or (if given a reference to an array of answers),
	a list of answer evaluators

FILTERS:

	remove_whitespace	--	removes all whitespace
	compress_whitespace	--	removes whitespace from the beginning and end of the string,
							and treats one or more whitespace characters in a row as a
							single space (true by default)
	trim_whitespace		--	removes whitespace from the beginning and end of the string
	ignore_case		--	ignores the case of the letters (true by default)
	ignore_order		--	ignores the order in which letters are entered

EXAMPLES:

	str_cmp( "Hello" )	--	matches "Hello", "  hello" (same as std_str_cmp() )
	str_cmp( ["Hello", "Goodbye"] )	--	same as std_str_cmp_list()
	str_cmp( " hello ", trim_whitespace )	--	matches "hello", " hello  "
	str_cmp( "ABC", filters => 'ignore_order' )	--	matches "ACB", "A B C", but not "abc"
	str_cmp( "D E F", remove_whitespace, ignore_case )	--	matches "def" and "d e f" but not "fed"


=cut

sub str_cmp {
	my $correctAnswer =	shift @_;
	$correctAnswer = '' unless defined($correctAnswer);
	my @options	= @_;
	my %options = ();
	# backward compatibility
	if (grep /filters|debug|filter/, @options) { # see whether we have hash keys in the input.
		%options = @options;
	} elsif (@options) {     # all options are names of filters.
		$options{filters} = [@options];
	}
	my $ra_filters;
 	assign_option_aliases( \%options,
 				'filter'               =>  'filters',
     );
    set_default_options(	\%options,
    			'filters'               =>  [qw(trim_whitespace compress_whitespace ignore_case)],
	       		'debug'					=>	0,
	       		'type'                  =>  'str_cmp',
    );
	$options{filters} = (ref($options{filters}))?$options{filters}:[$options{filters}]; 
	# make sure this is a reference to an array.
	# error-checking for filters occurs in the filters() subroutine
# 	if( not defined( $options[0] ) ) {		# used with no filters as alias for std_str_cmp()
# 		@options = ( 'compress_whitespace', 'ignore_case' );
# 	}
# 
# 	if( $options[0] eq 'filters' ) {		# using filters => [f1, f2, ...] notation
# 		$ra_filters = $options[1];
# 	}
# 	else {						# using a list of filters
# 		$ra_filters = \@options;
# 	}

	# thread over lists
	my @ans_list = ();

	if ( ref($correctAnswer) eq 'ARRAY' ) {
		@ans_list =	@{$correctAnswer};
	}
	else {
		push( @ans_list, $correctAnswer );
	}

	# final_answer;
	my @output_list	= ();

	foreach	my $ans	(@ans_list)	{
		push(@output_list, STR_CMP(	
		            	'correct_ans'	=>	$ans,
						'filters'		=>	$options{filters},
						'type'			=>	$options{type},
						'debug'         =>  $options{debug},
		     )
		);
	}

	return (wantarray) ? @output_list : $output_list[0] ;
}

=head3 "mode"_str_cmp functions

The functions of the the form "mode"_str_cmp() use different functions to
specify which filters to apply. They take no options except the correct
string. There are also versions which accept a list of strings.

 std_str_cmp( $correctString )
 std_str_cmp_list( @correctStringList )
	Filters: compress_whitespace, ignore_case

 std_cs_str_cmp( $correctString )
 std_cs_str_cmp_list( @correctStringList )
	Filters: compress_whitespace

 strict_str_cmp( $correctString )
 strict_str_cmp_list( @correctStringList )
	Filters: trim_whitespace

 unordered_str_cmp( $correctString )
 unordered_str_cmp_list( @correctStringList )
	Filters: ignore_order, ignore_case

 unordered_cs_str_cmp( $correctString )
 unordered_cs_str_cmp_list( @correctStringList )
	Filters: ignore_order

 ordered_str_cmp( $correctString )
 ordered_str_cmp_list( @correctStringList )
	Filters: remove_whitespace, ignore_case

 ordered_cs_str_cmp( $correctString )
 ordered_cs_str_cmp_list( @correctStringList )
	Filters: remove_whitespace

Examples

	ANS( std_str_cmp( "W. Mozart" ) )	--	Accepts "W. Mozart", "W. MOZarT",
		and so forth. Case insensitive. All internal spaces treated
		as single spaces.
	ANS( std_cs_str_cmp( "Mozart" ) )	--	Rejects "mozart". Same as
		std_str_cmp() but case sensitive.
	ANS( strict_str_cmp( "W. Mozart" ) )	--	Accepts only the exact string.
	ANS( unordered_str_cmp( "ABC" ) )	--	Accepts "a c B", "CBA" and so forth.
		Unordered, case insensitive, spaces ignored.
	ANS( unordered_cs_str_cmp( "ABC" ) )	--	Rejects "abc". Same as
		unordered_str_cmp() but case sensitive.
	ANS( ordered_str_cmp( "ABC" ) )	--	Accepts "a b C", "A B C" and so forth.
		Ordered, case insensitive, spaces ignored.
	ANS( ordered_cs_str_cmp( "ABC" ) )	--	Rejects "abc", accepts "A BC" and
		so forth. Same as ordered_str_cmp() but case sensitive.

=cut

sub std_str_cmp	{					# compare strings
	my $correctAnswer = shift @_;
	my @filters = ( 'compress_whitespace', 'ignore_case' );
	my $type = 'std_str_cmp';
	STR_CMP('correct_ans'	=>	$correctAnswer,
			'filters'	=>	\@filters,
			'type'		=>	$type
	);
}

sub std_str_cmp_list {				# alias for std_str_cmp
	my @answerList = @_;
	my @output;
	while (@answerList)	{
		push( @output, std_str_cmp(shift @answerList) );
	}
	@output;
}

sub std_cs_str_cmp {				# compare strings case sensitive
	my $correctAnswer = shift @_;
	my @filters = ( 'compress_whitespace' );
	my $type = 'std_cs_str_cmp';
	STR_CMP(	'correct_ans'	=>	$correctAnswer,
			'filters'	=>	\@filters,
			'type'		=>	$type
	);
}

sub std_cs_str_cmp_list	{			# alias	for	std_cs_str_cmp
	my @answerList = @_;
	my @output;
	while (@answerList)	{
		push( @output, std_cs_str_cmp(shift @answerList) );
	}
	@output;
}

sub strict_str_cmp {				# strict string compare
	my $correctAnswer = shift @_;
	my @filters = ( 'trim_whitespace' );
	my $type = 'strict_str_cmp';
	STR_CMP(	'correct_ans'	=>	$correctAnswer,
			'filters'	=>	\@filters,
			'type'		=>	$type
	);
}

sub strict_str_cmp_list	{			# alias	for	strict_str_cmp
	my @answerList = @_;
	my @output;
	while (@answerList)	{
		push( @output, strict_str_cmp(shift @answerList) );
	}
	@output;
}

sub unordered_str_cmp {				# unordered, case insensitive, spaces ignored
	my $correctAnswer = shift @_;
	my @filters = ( 'ignore_order', 'ignore_case' );
	my $type = 'unordered_str_cmp';
	STR_CMP(	'correct_ans'		=>	$correctAnswer,
			'filters'		=>	\@filters,
			'type'			=>	$type
	);
}

sub unordered_str_cmp_list {		# alias for unordered_str_cmp
	my @answerList = @_;
	my @output;
	while (@answerList)	{
		push( @output, unordered_str_cmp(shift @answerList) );
	}
	@output;
}

sub unordered_cs_str_cmp {			# unordered, case sensitive, spaces ignored
	my $correctAnswer = shift @_;
	my @filters = ( 'ignore_order' );
	my $type = 'unordered_cs_str_cmp';
	STR_CMP(	'correct_ans'		=>	$correctAnswer,
			'filters'		=>	\@filters,
			'type'			=>	$type
	);
}

sub unordered_cs_str_cmp_list {		# alias for unordered_cs_str_cmp
	my @answerList = @_;
	my @output;
	while (@answerList)	{
		push( @output, unordered_cs_str_cmp(shift @answerList) );
	}
	@output;
}

sub ordered_str_cmp {				# ordered, case insensitive, spaces ignored
	my $correctAnswer = shift @_;
	my @filters = ( 'remove_whitespace', 'ignore_case' );
	my $type = 'ordered_str_cmp';
	STR_CMP(	'correct_ans'	=>	$correctAnswer,
			'filters'	=>	\@filters,
			'type'		=>	$type
	);
}

sub ordered_str_cmp_list {			# alias for ordered_str_cmp
	my @answerList = @_;
	my @output;
	while (@answerList)	{
		push( @output, ordered_str_cmp(shift @answerList) );
	}
	@output;
}

sub ordered_cs_str_cmp {			# ordered,	case sensitive,	spaces ignored
	my $correctAnswer = shift @_;
	my @filters = ( 'remove_whitespace' );
	my $type = 'ordered_cs_str_cmp';
	STR_CMP(	'correct_ans'	=>	$correctAnswer,
			'filters'	=>	\@filters,
			'type'		=>	$type
	);
}

sub ordered_cs_str_cmp_list {		# alias	for	ordered_cs_str_cmp
	my @answerList = @_;
	my @output;
	while (@answerList)	{
		push( @output, ordered_cs_str_cmp(shift @answerList) );
	}
	@output;
}


## LOW-LEVEL ROUTINE -- NOT NORMALLY FOR END USERS -- USE WITH CAUTION
##
## IN:	a hashtable with the following entries (error-checking to be added later?):
##			correctAnswer	--	the correct answer, before filtering
##			filters			--	reference to an array containing the filters to be applied
##			type			--	a string containing the type of answer evaluator in use
## OUT:	a reference to an answer evaluator subroutine
sub STR_CMP {
	my %str_params = @_;
	#my $correctAnswer =  str_filters( $str_params{'correct_ans'}, @{$str_params{'filters'}} );
	my $answer_evaluator = new AnswerEvaluator;
	$answer_evaluator->{debug} = $str_params{debug};
	$answer_evaluator->ans_hash( 	
		correct_ans       => "$str_params{correct_ans}",
		type              => $str_params{type}||'str_cmp',
		score             => 0,

    );
	my %known_filters = (	
	            'remove_whitespace'		=>	\&remove_whitespace,
				'compress_whitespace'	=>	\&compress_whitespace,
				'trim_whitespace'		=>	\&trim_whitespace,
				'ignore_case'			=>	\&ignore_case,
				'ignore_order'			=>	\&ignore_order,
	);

	foreach my $filter ( @{$str_params{filters}} ) {
		#check that filter is known
		die "Unknown string filter |$filter|. Known filters are ".
		     join(" ", keys %known_filters) .
		     "(try checking the parameters to str_cmp() )"
								unless exists $known_filters{$filter};
		# install related pre_filter
		$answer_evaluator->install_pre_filter( $known_filters{$filter} );
	}
	$answer_evaluator->install_evaluator(sub {
			my $rh_ans = shift;
			$rh_ans->{_filter_name} = "Evaluator: Compare string answers with eq";
			$rh_ans->{score} = ($rh_ans->{student_ans} eq $rh_ans->{correct_ans})?1:0  ;
			$rh_ans;
	});
	$answer_evaluator->install_post_filter(sub {
		my $rh_hash = shift;
		$rh_hash->{_filter_name} = "clean up preview strings";
		$rh_hash->{'preview_text_string'} = $rh_hash->{student_ans};
		$rh_hash->{'preview_latex_string'} = "\\text{ ".$rh_hash->{student_ans}." }";
		$rh_hash;		
	});
	return $answer_evaluator;
}

# sub STR_CMP_old {
# 	my %str_params = @_;
# 	$str_params{'correct_ans'} = str_filters( $str_params{'correct_ans'}, @{$str_params{'filters'}} );
# 	my $answer_evaluator = sub {
# 		my $in = shift @_;
# 		$in = '' unless defined $in;
# 		my $original_student_ans = $in;
# 		$in = str_filters( $in, @{$str_params{'filters'}} );
# 		my $correctQ = ( $in eq $str_params{'correct_ans'} ) ? 1: 0;
# 		my $ans_hash = new AnswerHash(		'score'				=>	$correctQ,
# 							'correct_ans'			=>	$str_params{'correctAnswer'},
# 							'student_ans'			=>	$in,
# 							'ans_message'			=>	'',
# 							'type'				=>	$str_params{'type'},
# 							'preview_text_string'		=>	$in,
# 							'preview_latex_string'		=>	$in,
# 							'original_student_ans'		=>	$original_student_ans
# 		);
# 		return $ans_hash;
# 	};
# 	return $answer_evaluator;
# }

##########################################################################
##########################################################################
## Miscellaneous answer evaluators

=head2 Miscellaneous Answer Evaluators (Checkboxes and Radio Buttons)

These evaluators do not fit any of the other categories.

checkbox_cmp( $correctAnswer )

	$correctAnswer	--	a string containing the names of the correct boxes,
						e.g. "ACD". Note that this means that individual
						checkbox names can only be one character. Internally,
						this is largely the same as unordered_cs_str_cmp().

radio_cmp( $correctAnswer )

	$correctAnswer	--	a string containing the name of the correct radio
						button, e.g. "Choice1". This is case sensitive and
						whitespace sensitive, so the correct answer must match
						the name of the radio button exactly.

=cut

# added 6/14/2000 by David Etlinger
# because of the conversion of the answer
# string to an array, I thought it better not
# to force STR_CMP() to work with this

#added 2/26/2003 by Mike Gage
# handled the case where multiple answers are passed as an array reference
# rather than as a \0 delimited string.
sub checkbox_cmp {
	my	$correctAnswer = shift @_;
	my %options = @_;
	assign_option_aliases( \%options,
     );
    set_default_options(	\%options,
    			'debug'					=>	0,
	       		'type'                  =>  'checkbox_cmp',
    );
	my $answer_evaluator = new AnswerEvaluator(
		correct_ans      => $correctAnswer,
		type             => $options{type},
	);
	# pass along debug requests
	$answer_evaluator->{debug} = $options{debug};
	
	# join student answer array into a single string if necessary
	$answer_evaluator->install_pre_filter(sub {
		my $rh_ans = shift;
		$rh_ans->{_filter_name} = 'convert student_ans to string';
		$rh_ans->{student_ans} = join("", @{$rh_ans->{student_ans}}) 
		         if ref($rh_ans->{student_ans}) =~/ARRAY/i;
		$rh_ans;
	});
	# ignore order of check boxes
	$answer_evaluator->install_pre_filter(\&ignore_order);
	# compare as strings
	$answer_evaluator->install_evaluator(sub {
		my $rh_ans     = shift;
		$rh_ans->{_filter_name} = 'compare strings generated by checked boxes';
		$rh_ans->{score} = ($rh_ans->{student_ans} eq $rh_ans->{correct_ans}) ? 1 : 0;
		$rh_ans;
	});
	# fix up preview displays
	$answer_evaluator->install_post_filter( sub {
		my $rh_ans      = shift;
		$rh_ans->{_filter_name} = 'adjust preview strings';
		$rh_ans->{type} = $options{type};
		$rh_ans->{preview_text_string}	=	'\\text{'.$rh_ans->{student_ans}.'}',
		$rh_ans->{preview_latex_string}	=	'\\text{'.$rh_ans->{student_ans}.'}',
		$rh_ans;
	
	
	});
	
# 	my	$answer_evaluator =	sub	{
# 		my $in = shift @_;
# 		$in = '' unless defined $in;			#in case no boxes checked
# 												# multiple answers could come in two forms
# 												# either a \0 delimited string or
# 												# an array reference.  We handle both.
#         if (ref($in) eq 'ARRAY')   {
#         	$in = join("",@{$in});              # convert array to single no-delimiter string
#         } else {
# 			my @temp = split( "\0", $in );		#convert "\0"-delimited string to array...
# 			$in = join( "", @temp );			#and then to a single no-delimiter string
# 		}
# 		my $original_student_ans = $in;			#well, almost original
# 		$in	= str_filters( $in, 'ignore_order' );
# 
# 		my $correctQ = ($in	eq $correctAnswer) ? 1: 0;
# 
# 		my $ans_hash = new AnswerHash(
# 			'score'			        =>	$correctQ,
# 			'correct_ans'		    =>	"$correctAnswer",
# 			'student_ans'		    =>	$in,
# 			'ans_message'		    =>	"",
# 			'type'			        =>	"checkbox_cmp",
# 			'preview_text_string'	=>	$in,
# 			'preview_latex_string'	=>	$in,
# 			'original_student_ans'	=>	$original_student_ans
# 		);
# 		return $ans_hash;
# 
# 	};
	return $answer_evaluator;
}
# sub checkbox_cmp {
# 	my	$correctAnswer = shift @_;
# 	$correctAnswer = str_filters( $correctAnswer, 'ignore_order' );
# 
# 	my	$answer_evaluator =	sub	{
# 		my $in = shift @_;
# 		$in = '' unless defined $in;			#in case no boxes checked
# 												# multiple answers could come in two forms
# 												# either a \0 delimited string or
# 												# an array reference.  We handle both.
#         if (ref($in) eq 'ARRAY')   {
#         	$in = join("",@{$in});              # convert array to single no-delimiter string
#         } else {
# 			my @temp = split( "\0", $in );		#convert "\0"-delimited string to array...
# 			$in = join( "", @temp );			#and then to a single no-delimiter string
# 		}
# 		my $original_student_ans = $in;			#well, almost original
# 		$in	= str_filters( $in, 'ignore_order' );
# 
# 		my $correctQ = ($in	eq $correctAnswer) ? 1: 0;
# 
# 		my $ans_hash = new AnswerHash(
# 			'score'			        =>	$correctQ,
# 			'correct_ans'		    =>	"$correctAnswer",
# 			'student_ans'		    =>	$in,
# 			'ans_message'		    =>	"",
# 			'type'			        =>	"checkbox_cmp",
# 			'preview_text_string'	=>	$in,
# 			'preview_latex_string'	=>	$in,
# 			'original_student_ans'	=>	$original_student_ans
# 		);
# 		return $ans_hash;
# 
# 	};
# 	return $answer_evaluator;
# }

#added 6/28/2000 by David Etlinger
#exactly the same as strict_str_cmp,
#but more intuitive to the user

# check that answer is really a string and not an array
# also use ordinary string compare
sub radio_cmp {
	#strict_str_cmp( @_ );
	my $response = shift;  # there should be only one item.
	warn "Multiple choices -- this should not happen with radio buttons. Have
	you used checkboxes perhaps?" if ref($response); #triggered if an ARRAY is passed
	str_cmp($response);
}

##########################################################################
##########################################################################
## Text and e-mail routines

sub store_ans_at {
	my $answerStringRef	= shift;
	my %options	= @_;
	my $ans_eval= '';
	if ( ref($answerStringRef) eq 'SCALAR' ) {
		$ans_eval= sub {
			my $text = shift;
			$text =	'' unless defined($text);
			$$answerStringRef =	$$answerStringRef  . $text;
			my $ans_hash = new AnswerHash(
							 'score'			=>	1,
							 'correct_ans'			=>	'',
							 'student_ans'			=>	$text,
							 'ans_message'			=>	'',
							 'type'				=>	'store_ans_at',
							 'original_student_ans'		=>	$text,
							 'preview_text_string'		=>	''
			);

		return $ans_hash;
		};
	}
	else {
		die	"Syntax	error: \n The argument to store_ans_at() must be a pointer to a	scalar.\n(e.g.	store_ans_at(~~\$MSG) )\n\n";
	}

	return $ans_eval;
}

#### subroutines used in producing a questionnaire
#### these are at least	good models	for	other answers of this type

# my $QUESTIONNAIRE_ANSWERS='';	#  stores the answers until	it is time to send them
		   #  this must	be initialized before the answer evaluators	are	run
		   #  but that happens long	after all of the text in the problem is
		   #  evaluated.
# this is a	utility	script for cleaning	up the answer output for display in
#the answers.

sub DUMMY_ANSWER {
	my $num	= shift;
	qq{<INPUT TYPE="HIDDEN"	NAME="answer$num" VALUE="">}
}

sub escapeHTML {
	my $string = shift;
	$string	=~ s/\n/$BR/ge;
	$string;
}

# these	next three subroutines show how to modify	the	"store_ans_at()" answer
# evaluator	to add extra information before	storing	the	info
# They provide a good model	for	how	to tweak answer	evaluators in special cases.

sub anstext {
	my $num	= shift;
	my $ans_eval_template =	store_ans_at(\$QUESTIONNAIRE_ANSWERS);
	my $psvnNumber  = PG_restricted_eval(q!$main::psvnNumber!);
	my $probNum     = PG_restricted_eval(q!$main::probNum!);
	my $courseName  = PG_restricted_eval(q!$main::courseName!);
	my $setNumber     = PG_restricted_eval(q!$main::setNumber!);
	
	my $ans_eval    = sub {
				 my	$text =	shift;
				 $text = ''	unless defined($text);
				 my	$new_text =	"\n$setNumber$courseName$psvnNumber-Problem-$probNum-Question-$num:\n $text "; #	modify entered text
				 my	$out = &$ans_eval_template($new_text);			 # standard	evaluator
				 #warn "$QUESTIONNAIRE_ANSWERS";
				 $out->{student_ans} = escapeHTML($text);  #	restore	original entered text
				 $out->{correct_ans} = "Question  $num answered";
				 $out->{original_student_ans} = escapeHTML($text);
				 $out;
   	};
   $ans_eval;
}


sub ansradio {
	my $num	= shift;
	my $psvnNumber  = PG_restricted_eval(q!$main::psvnNumber!);
	my $probNum  = PG_restricted_eval(q!$main::probNum!);

	my $ans_eval_template =	store_ans_at(\$QUESTIONNAIRE_ANSWERS);
	my $ans_eval = sub {
				 my	$text =	shift;
				 $text = ''	unless defined($text);
				 my	$new_text =	"\n$psvnNumber-Problem-$probNum-RADIO-$num:\n $text	";		   # modify	entered	text
				 my	$out = $ans_eval_template->($new_text);			  #	standard evaluator
				 $out->{student_ans} =escapeHTML($text);  #	restore	original entered text
				 $out->{original_student_ans} = escapeHTML($text);
				 $out;
	 };

   $ans_eval;
}

sub anstext_non_anonymous {
	## this emails identifying information
	my $num	         = shift;
    my $psvnNumber   = PG_restricted_eval(q!$main::psvnNumber!);
	my $probNum      = PG_restricted_eval(q!$main::probNum!);
    my $studentLogin = PG_restricted_eval(q!$main::studentLogin!);
	my $studentID    = PG_restricted_eval(q!$main::studentID!);
    my $studentName  = PG_restricted_eval(q!$main::studentName!);


	my $ans_eval_template =	store_ans_at(\$QUESTIONNAIRE_ANSWERS);
	my $ans_eval = sub {
				 my	$text =	shift;
				 $text = ''	unless defined($text);
				 my	$new_text =	"\n$psvnNumber-Problem-$probNum-Question-$num:\n$studentLogin $main::studentID $studentName\n$text "; #	modify entered text
				 my	$out = &$ans_eval_template($new_text);			 # standard	evaluator
				 #warn "$QUESTIONNAIRE_ANSWERS";
				 $out->{student_ans} = escapeHTML($text);  #	restore	original entered text
				 $out->{correct_ans} = "Question  $num answered";
				 $out->{original_student_ans} = escapeHTML($text);
				 $out;
   	};
   $ans_eval;
}


#  This	is another example of how to modify	an	answer evaluator to	obtain
#  the desired behavior	in a special case.	Here the object	is to have
#  have	the	last answer	trigger	the	send_mail_to subroutine	which mails
#  all of the answers to the designated	address.
#  (This address must be listed	in PG_environment{'ALLOW_MAIL_TO'} or an error occurs.)

# Fix me?? why is the body hard wired to the string QUESTIONNAIRE_ANSWERS?

sub mail_answers_to {  #accepts	the	last answer	and	mails off the result
	my $user_address = shift;
	my $ans_eval = sub {

		# then mail out	all of the answers, including this last one.

		send_mail_to(	$user_address,
					'subject'		    =>	"$main::courseName WeBWorK questionnaire",
					'body'			    =>	$QUESTIONNAIRE_ANSWERS,
					'ALLOW_MAIL_TO'		=>	$rh_envir->{ALLOW_MAIL_TO}
		);

		my $ans_hash = new AnswerHash(	'score'		=>	1,
						'correct_ans'	=>	'',
						'student_ans'	=>	'Answer	recorded',
						'ans_message'	=>	'',
						'type'		=>	'send_mail_to',
		);

		return $ans_hash;
	};

	return $ans_eval; 
}

sub save_answer_to_file {  #accepts	the	last answer	and	mails off the result
	my $fileID = shift;
	my $ans_eval = new AnswerEvaluator;
	$ans_eval->install_evaluator(
			sub {
				 my $rh_ans = shift;

       		 	 unless ( defined( $rh_ans->{student_ans} ) ) {
        			$rh_ans->throw_error("save_answers_to_file","{student_ans} field not defined");
        			return $rh_ans;
       			}

				my $error;
				my $string = '';
				$string = qq![[<$main::studentLogin> $main::studentName /!. time() . qq!/]]\n!.
					$rh_ans->{student_ans}. qq!\n\n============================\n\n!;

				if ($error = AnswerIO::saveAnswerToFile('preflight',$string) ) {
					$rh_ans->throw_error("save_answers_to_file","Error:  $error");
				} else {
					$rh_ans->{'student_ans'} = 'Answer saved';
					$rh_ans->{'score'} = 1;
				}
				$rh_ans;
			}
	);

	return $ans_eval;
}

sub mail_answers_to2 {	#accepts the last answer and mails off the result
	my $user_address         = shift;
	my $subject              = shift;
	my $ra_allow_mail_to     = shift;	 
	$subject = "$main::courseName WeBWorK questionnaire" unless defined $subject;
	send_mail_to($user_address,
			'subject'			=> $subject,
			'body'				=> $QUESTIONNAIRE_ANSWERS,
			'ALLOW_MAIL_TO'		=> $rh_envir->{ALLOW_MAIL_TO},
	);
}

##########################################################################
##########################################################################


###########################################################################
###	THE	FOLLOWING ARE LOCAL	SUBROUTINES	THAT ARE MEANT TO BE CALLED	ONLY FROM THIS SCRIPT.

## Internal routine that converts variables into the standard array format
##
## IN:	one of the following:
##			an undefined value (i.e., no variable was specified)
##			a reference to an array of variable names -- [var1, var2]
##			a number (the number of variables desired) -- 3
##			one or more variable names -- (var1, var2)
## OUT:	an array of variable names

sub get_var_array {
	my $in = shift @_;
	my @out;

	if( not defined($in) ) {			#if nothing defined, build default array and return
		@out = ( $functVarDefault );
		return @out;
	}
	elsif( ref( $in ) eq 'ARRAY' ) {	#if given an array ref, dereference and return
		return @{$in};
	}
	elsif( $in =~ /^\d+/ ) {			#if given a number, set up the array and return
		if( $in == 1 ) {
			$out[0] = 'x';
		}
		elsif( $in == 2 ) {
			$out[0] = 'x';
			$out[1] = 'y';
		}
		elsif( $in == 3 ) {
			$out[0] = 'x';
			$out[1] = 'y';
			$out[2] = 'z';
		}
		else {	#default to the x_1, x_2, ... convention
			my ($i, $tag);
			for($i = 0; $i < $in; $i++) {$out[$i] = "${functVarDefault}_".($i+1)}
		}
		return @out;
	}
	else {						#if given one or more names, return as an array
		unshift( @_, $in );
		return @_;
	}
}

## Internal routine that converts limits into the standard array of arrays format
##	Some of the cases are probably unneccessary, but better safe than sorry
##
## IN:	one of the following:
##			an undefined value (i.e., no limits were specified)
##			a reference to an array of arrays of limits -- [[llim,ulim], [llim,ulim]]
##			a reference to an array of limits -- [llim, ulim]
##			an array of array references -- ([llim,ulim], [llim,ulim])
##			an array of limits -- (llim,ulim)
## OUT:	an array of array references -- ([llim,ulim], [llim,ulim]) or ([llim,ulim])

sub get_limits_array {
	my $in = shift @_;
	my @out;

	if( not defined($in) ) {				#if nothing defined, build default array and return
		@out = ( [$functLLimitDefault, $functULimitDefault] );
		return @out;
	}
	elsif( ref($in) eq 'ARRAY' ) {				#$in is either ref to array, or ref to array of refs
		my @deref = @{$in};

		if( ref( $in->[0] ) eq 'ARRAY' ) {		#$in is a ref to an array of array refs
			return @deref;
		}
		else {						#$in was just a ref to an array of numbers
			@out = ( $in );
			return @out;
		}
	}
	else {							#$in was an array of references or numbers
		unshift( @_, $in );

		if( ref($_[0]) eq 'ARRAY' ) {			#$in was an array of references, so just return it
			return @_;
		}
		else {						#$in was an array of numbers
			@out = ( \@_ );
			return @out;
		}
	}
}

#sub check_option_list {
#	my $size = scalar(@_);
#	if( ( $size % 2 ) != 0 ) {
#		warn "ERROR	in answer evaluator	generator:\n" .
#			"Usage: <CODE>str_cmp([\$ans1,	\$ans2],%options)</CODE>
#			or <CODE>	num_cmp([\$num1, \$num2], %options)</CODE><BR>
#			A list of inputs must be inclosed in square brackets <CODE>[\$ans1, \$ans2]</CODE>";
#	}
#}

# simple subroutine to display an error message when
# function compares are called with invalid parameters
sub function_invalid_params {
	my $correctEqn = shift @_;
	my $error_response = sub {
		my $PGanswerMessage	= "Tell your professor that there is an error with the parameters " .
						"to the function answer evaluator";
		return ( 0, $correctEqn, "", $PGanswerMessage );
	};
	return $error_response;
}

sub clean_up_error_msg {
	my $msg = $_[0];
	$msg =~ s/^\[[^\]]*\][^:]*://;
	$msg =~ s/Unquoted string//g;
	$msg =~ s/may\s+clash.*/does not make sense here/;
	$msg =~ s/\sat.*line [\d]*//g;
	$msg = 'Error: '. $msg;

	return $msg;
}

#formats the student and correct answer as specified
#format must be of a form suitable for sprintf (e.g. '%0.5g'),
#with the exception that a '#' at the end of the string
#will cause trailing zeros in the decimal part to be removed
sub prfmt {
	my($number,$format)	= @_;  # attention,	the	order of format	and	number are reversed
	my $out;
	if ($format) {
		warn "Incorrect	format used: $format. <BR> Format should look something like %4.5g<BR>"
								unless $format =~ /^\s*%\d*\.?\d*\w#?\s*$/;

		if( $format =~ s/#\s*$// ) {	# remove trailing zeros in the decimal
			$out = sprintf( $format, $number );
			$out =~ s/(\.\d*?)0+$/$1/;
			$out =~ s/\.$//;			# in case all decimal digits were zero, remove the decimal
			$out =~ s/e/E/g;				# only use capital E's for exponents. Little e is for 2.71828...
		} elsif (is_a_number($number) ){
			$out = sprintf( $format, $number );
			$out =~ s/e/E/g;				# only use capital E's for exponents. Little e is for 2.71828...
		} else { # number is probably a string representing an arithmetic expression
			$out = $number;
		}

	} else {
		if (is_a_number($number)) {# only use capital E's for exponents. Little e is for 2.71828...
			$out = $number;
			$out =~ s/e/E/g;
		} else { # number is probably a string representing an arithmetic expression
			$out = $number;
		}
	}
	return $out;
}
#########################################################################
# Filters for answer evaluators
#########################################################################

=head2 Filters

=pod

A filter is a short subroutine with the following structure.  It accepts an
AnswerHash, followed by a hash of options.  It returns an AnswerHash

	$ans_hash = filter($ans_hash, %options);

See the AnswerHash.pm file for a list of entries which can be expected to be found
in an AnswerHash, such as 'student_ans', 'score' and so forth.  Other entries
may be present for specialized answer evaluators.

The hope is that a well designed set of filters can easily be combined to form
a new answer_evaluator and that this method will produce answer evaluators which are
are more robust than the method of copying existing answer evaluators and modifying them.

Here is an outline of how a filter is constructed:

	sub filter{
		my $rh_ans = shift;
		my %options = @_;
		assign_option_aliases(\%options,
				'alias1'	=> 'option5'
				'alias2'	=> 'option7'
		);
		set_default_options(\%options,
				'_filter_name'	=>	'filter',
				'option5'		=>  .0001,
				'option7'		=>	'ascii',
				'allow_unknown_options	=>	0,
		}
		.... body code of filter .......
			if ($error) {
				$rh_ans->throw_error("FILTER_ERROR", "Something went wrong");
				# see AnswerHash.pm for details on using the throw_error method.

		$rh_ans;  #reference to an AnswerHash object is returned.
	}

=cut

=head4 compare_numbers


=cut


sub compare_numbers {
	my ($rh_ans, %options) = @_;
	my ($inVal,$PG_eval_errors,$PG_full_error_report) = PG_answer_eval($rh_ans->{student_ans});
	if ($PG_eval_errors) {
		$rh_ans->throw_error('EVAL','There is a syntax error in your answer');
		$rh_ans->{ans_message} = clean_up_error_msg($PG_eval_errors);
		# return $rh_ans;
	} else {
		$rh_ans->{student_ans} = prfmt($inVal,$options{format});
	}

	my $permitted_error;

	if ($rh_ans->{tolType} eq 'absolute')	{
		$permitted_error = $rh_ans->{tolerance};
	}
	elsif ( abs($rh_ans->{correct_ans}) <= $options{zeroLevel}) {
			$permitted_error = $options{zeroLevelTol};  ## want $tol to be non zero
	}
	else {
		$permitted_error = abs($rh_ans->{tolerance}*$rh_ans->{correct_ans});
	}

	my $is_a_number	= is_a_number($inVal);
	$rh_ans->{score} = 1 if ( ($is_a_number) and
		  (abs(	$inVal - $rh_ans->{correct_ans} ) <= $permitted_error) );
	if (not $is_a_number) {
		$rh_ans->{error_message} = "$rh_ans->{error_message}". 'Your answer does not evaluate to a number ';
	}

	$rh_ans;
}

=head4 std_num_filter

	std_num_filter($rh_ans, %options)
	returns $rh_ans

Replaces some constants using math_constants, then evaluates a perl expression.


=cut

sub std_num_filter {
	my $rh_ans = shift;
	my %options = @_;
	my $in = $rh_ans->input();
	$in = math_constants($in);
	$rh_ans->{type} = 'std_number';
	my ($inVal,$PG_eval_errors,$PG_full_error_report);
	if ($in	=~ /\S/) {
		($inVal,$PG_eval_errors,$PG_full_error_report) = PG_answer_eval($in);
	} else {
		$PG_eval_errors = '';
	}

	if ($PG_eval_errors) {			  ##error message from eval	or above
		$rh_ans->{ans_message} = 'There is a syntax error	in your	answer';
		$rh_ans->{student_ans} = 
		clean_up_error_msg($PG_eval_errors);
	} else {
		$rh_ans->{student_ans} = $inVal;
	}
	$rh_ans;
}

=head std_num_array_filter

	std_num_array_filter($rh_ans, %options)
	returns $rh_ans

Assumes the {student_ans} field is a numerical  array, and applies BOTH check_syntax and std_num_filter
to each element of the array.  Does it's best to generate sensible error messages for syntax errors.
A typical error message displayed in {studnet_ans} might be ( 56, error message, -4).

=cut

sub std_num_array_filter {
	my $rh_ans= shift;
	my %options = @_;
	set_default_options(  \%options,
				'_filter_name'	=>	'std_num_array_filter',
    );
	my @in = @{$rh_ans->{student_ans}};
	my $temp_hash = new AnswerHash;
	my @out=();
	my $PGanswerMessage = '';
	foreach my $item (@in)   {  # evaluate each number in the vector
		$temp_hash->input($item);
		$temp_hash = check_syntax($temp_hash);
		if (defined($temp_hash->{error_flag}) and $temp_hash->{error_flag} eq 'SYNTAX') {
			$PGanswerMessage .= $temp_hash->{ans_message};
			$temp_hash->{ans_message} = undef;
		} else {
			#continue processing
			$temp_hash = std_num_filter($temp_hash);
			if (defined($temp_hash->{ans_message}) and $temp_hash->{ans_message} ) {
				$PGanswerMessage .= $temp_hash->{ans_message};
				$temp_hash->{ans_message} = undef;
			}
		}
		push(@out, $temp_hash->input());

	}
	if ($PGanswerMessage) {
		$rh_ans->input( "( " . join(", ", @out ) . " )" );
	    	$rh_ans->throw_error('SYNTAX', 'There is a syntax error in your answer.');
	} else {
		$rh_ans->input( [@out] );
	}
	$rh_ans;
}

=head4 function_from_string2



=cut

sub function_from_string2 {
    my $rh_ans = shift;
    my %options = @_;
	assign_option_aliases(\%options,
				'vars'			=> 'ra_vars',
				'var'           => 'ra_vars',
				'store_in'      => 'stdout',
	);
	set_default_options(  \%options,
				'stdin'         =>  'student_ans',
	            'stdout'		=>  'rf_student_ans',
    			'ra_vars'		=>	[qw( x y )],
    			'debug'			=>	0,
    			'_filter_name'	=>	'function_from_string2',
    );
    # initialize
    $rh_ans->{_filter_name} = $options{_filter_name};
    
    my $eqn         = $rh_ans->{ $options{stdin} };
    my @VARS        = @{ $options{ 'ra_vars'}    };
    #warn "VARS = ", join("<>", @VARS) if defined($options{debug}) and $options{debug} ==1;
    my $originalEqn = $eqn;
    $eqn            = &math_constants($eqn);
    for( my $i = 0; $i < @VARS; $i++ ) {
        #  This next line is a hack required for 5.6.0 -- it doesn't appear to be needed in 5.6.1
        my ($temp,$er1,$er2) = PG_restricted_eval('"'. $VARS[$i] . '"');
		#$eqn	=~ s/\b$VARS[$i]\b/\$VARS[$i]/g;
        $eqn	=~ s/\b$temp\b/\$VARS[$i]/g;

	}
	#warn "equation evaluated = $eqn",$rh_ans->pretty_print(), "<br>\noptions<br>\n",
	#     pretty_print(\%options)
	#     if defined($options{debug}) and $options{debug} ==1;
    my ($function_sub,$PG_eval_errors, $PG_full_errors) = PG_answer_eval( q!
	    sub {
	    	my @VARS = @_;
	    	my $input_str = '';
	    	for( my $i=0; $i<@VARS; $i++ ) {
	    		$input_str .= "\$VARS[$i] = $VARS[$i]; ";
	    	}
	    	my $PGanswerMessage;
	    	$input_str .= '! . $eqn . q!';  # need the single quotes to keep the contents of $eqn from being
	    	                                # evaluated when it is assigned to $input_str;
	    	my ($out, $PG_eval_errors, $PG_full_errors) = PG_answer_eval($input_str); #Finally evaluated

	    	if ( defined($PG_eval_errors) and $PG_eval_errors =~ /\S/ ) {
	    	    $PGanswerMessage	= clean_up_error_msg($PG_eval_errors);
# This message seemed too verbose, but it does give extra information, we'll see if it is needed.
#                    "<br> There was an error in evaluating your function <br>
# 					!. $originalEqn . q! <br>
# 					at ( " . join(', ', @VARS) . " ) <br>
# 					 $PG_eval_errors
# 					";   # this message appears in the answer section which is not process by Latex2HTML so it must
# 					     # be in HTML.  That is why $BR is NOT used.

			}
			(wantarray) ? ($out, $PGanswerMessage): $out;   # PGanswerMessage may be undefined.
	    };
	!);

	if (defined($PG_eval_errors) and $PG_eval_errors =~/\S/	) {
				$PG_eval_errors	= clean_up_error_msg($PG_eval_errors);

 		my $PGanswerMessage = "There was an error in converting the expression
 		 	$BR $originalEqn $BR into a function.
 		 	$BR $PG_eval_errors.";
 		$rh_ans->{rf_student_ans} = $function_sub;
 		$rh_ans->{ans_message} = $PGanswerMessage;
 		$rh_ans->{error_message} = $PGanswerMessage;
 		$rh_ans->{error_flag} = 1;
 		 # we couldn't compile the equation, we'll return an error message.
 	} else {
#  		if (defined($options{stdout} )) {
#  			$rh_ans ->{$options{stdout}} = $function_sub;
#  		} else {
#  	    	$rh_ans->{rf_student_ans} = $function_sub;
#  	    }
 	    $rh_ans ->{$options{stdout}} = $function_sub;
 	}

    $rh_ans;
}

=head4 is_zero_array


=cut


sub is_zero_array {
    my $rh_ans = shift;
    my %options = @_;
    set_default_options(  \%options,
				'_filter_name'	=>	'is_zero_array',
				'tolerance'	    =>	0.000001,
				'stdin'         => 'ra_differences',
				'stdout'        => 'score',
    );
    #intialize
    $rh_ans->{_filter_name} = $options{_filter_name};
    
    my $array = $rh_ans -> {$options{stdin}};  # default ra_differences
	my $num = @$array;
	my $i;
	my $max = 0; my $mm;
	for ($i=0; $i< $num; $i++) {
		$mm = $array->[$i] ;
		if  (not is_a_number($mm) ) {
			$max = $mm;  # break out if one of the elements is not a number
			last;
		}
		$max = abs($mm) if abs($mm) > $max;
	}
	if (not is_a_number($max)) {
		$rh_ans->{score} = 0;
	    my $error = "WeBWorK was unable evaluate your function. Please check that your
 		            expression doesn't take roots of negative numbers, or divide by zero.";
 		$rh_ans->throw_error('EVAL',$error);
	} else {
    	$rh_ans->{$options{stdout}} = ($max < $options{tolerance} ) ? 1: 0;       # set 'score' to 1 if the array is close to 0;
	}
	$rh_ans;
}

=head4 best_approx_parameters

	best_approx_parameters($rh_ans,%options);   #requires the following fields in $rh_ans
	                      {rf_student_ans}    	# reference to the test answer
	                      {rf_correct_ans}    	# reference to the comparison answer
	                      {evaluation_points},  # an array of row vectors indicating the points
	                             				# to evaluate when comparing the functions

	                       %options				# debug => 1   gives more error answers
	                       						# param_vars => ['']  additional parameters used to adapt to function
	                       )


The parameters for the comparison function which best approximates the test_function are stored
in the field {ra_parameters}.


The last $dim_of_parms_space variables are assumed to be parameters, and it is also
assumed that the function \&comparison_fun
depends linearly on these variables.  This function finds the  values for these parameters which minimizes the
Euclidean distance (L2 distance) between the test function and the comparison function and the test points specified
by the array reference  \@rows_of_test_points.  This is assumed to be an array of arrays, with the inner arrays
determining a test point.

The comparison function should have $dim_of_params_space more input variables than the test function.





=cut

#	Used internally:
#
# 	&$determine_param_coeff( $rf_comparison_function # a reference to the correct answer function
# 	                 $ra_variables                   # an array of the active input variables to the functions
# 	                 $dim_of_params_space            # indicates the number of parameters upon which the
# 	                                                 # the comparison function depends linearly.  These are assumed to
# 	                                                 # be the last group of inputs to the comparison function.
#
# 	                 %options                        # $options{debug} gives more error messages
#
# 	                                                 # A typical function might look like
# 	                                                 # f(x,y,z,a,b) = x^2+a*cos(xz) + b*sin(x) with a parameter
# 	                                                 # space of dimension 2 and a variable space of dimension 3.
# 	                )
# 				# returns a list of coefficients

sub best_approx_parameters {
    my $rh_ans = shift;
    my %options = @_;
    set_default_options(\%options,
    		'_filter_name'			=>	'best_approx_paramters',
    		'allow_unknown_options'	=>	1,
    );
    my $errors = undef;
    # This subroutine for the determining the coefficents of the parameters at a given point
    # is pretty specialized, so it is included here as a sub-subroutine.
    my $determine_param_coeffs	= sub {
		my ($rf_fun, $ra_variables, $dim_of_params_space, %options) =@_;
		my @zero_params=();
		for(my $i=1;$i<=$dim_of_params_space;$i++){push(@zero_params,0); }
		my @vars = @$ra_variables;
		my @coeff = ();
		my @inputs = (@vars,@zero_params);
		my ($f0, $f1, $err);
		($f0, $err) = &{$rf_fun}(@inputs);
		if (defined($err) ) {
			$errors .= "$err ";
		} else {
			for (my $i=@vars;$i<@inputs;$i++) {
				$inputs[$i]=1;  # set one parameter to 1;
				my($f1,$err) = &$rf_fun(@inputs);
				if (defined($err) ) {
					$errors .= " $err ";
				} else {
					push(@coeff, $f1-$f0);
				}
				$inputs[$i]=0;  # set it back
			}
		}
		(\@coeff, $errors);
	};
    my $rf_fun = $rh_ans->{rf_student_ans};
    my $rf_correct_fun = $rh_ans->{rf_correct_ans};
    my $ra_vars_matrix = $rh_ans->{evaluation_points};
    my $dim_of_param_space = @{$options{param_vars}};
    # Short cut.  Bail if there are no param_vars
    unless ($dim_of_param_space >0) {
		$rh_ans ->{ra_parameters} = [];
		return $rh_ans;
    }
    # inputs are row arrays in this case.
    my @zero_params=();

    for(my $i=1;$i<=$dim_of_param_space;$i++){push(@zero_params,0); }
    my @rows_of_vars = @$ra_vars_matrix;
    warn "input rows ", pretty_print(\@rows_of_vars) if defined($options{debug}) and $options{debug};
    my $rows = @rows_of_vars;
    my $matrix =new Matrix($rows,$dim_of_param_space);
    my $rhs_vec = new Matrix($rows, 1);
    my $row_num = 1;
    my ($ra_coeff,$val2, $val1, $err1,$err2,@inputs,@vars);
    my $number_of_data_points = $dim_of_param_space +2;
    while (@rows_of_vars and $row_num <= $number_of_data_points) {
 	   # get one set of data points from the test function;
	    @vars = @{ shift(@rows_of_vars) };
 	    ($val2, $err1) = &{$rf_fun}(@vars);
 	    $errors .= " $err1 "  if defined($err1);
 	    @inputs = (@vars,@zero_params);
 	    ($val1, $err2) = &{$rf_correct_fun}(@inputs);
 	    $errors .= " $err2 " if defined($err2);

 	    unless (defined($err1) or defined($err2) ) {
 	        $rhs_vec->assign($row_num,1, $val2-$val1 );

	 	# warn "rhs data  val1=$val1, val2=$val2, val2 - val1 = ", $val2 - $val1 if $options{debug};
	 	# warn "vars ", join(" | ", @vars) if $options{debug};

	 		($ra_coeff, $err1) = &{$determine_param_coeffs}($rf_correct_fun,\@vars,$dim_of_param_space,%options);
	 		if (defined($err1) ) {
	 			$errors .= " $err1 ";
	 		} else {
		 		my @coeff = @$ra_coeff;
		 		my $col_num=1;
		  		while(@coeff) {
		  			$matrix->assign($row_num,$col_num, shift(@coeff) );
		  			$col_num++;
		  		}
		  	}
  		}
  		$row_num++;
  		last if $errors;  # break if there are any errors.
		                  # This cuts down on the size of error messages.
		                  # However it impossible to check for equivalence at 95% of points
		   		  # which might be useful for functions that are not defined at some points.
 	}
 	  warn "<br> best_approx_parameters: matrix1 <br>  ", " $matrix " if $options{debug};
 	  warn "<br> best_approx_parameters: vector <br>  ", " $rhs_vec " if $options{debug};

 	 # we have   Matrix * parameter = data_vec + perpendicular vector
 	 # where the matrix has column vectors defining the span of the parameter space
 	 # multiply both sides by Matrix_transpose and solve for the parameters
 	 # This is exactly what the method proj_coeff method does.
 	 my @array;
 	 if (defined($errors) ) {
 	 	@array = ();   #     new Matrix($dim_of_param_space,1);
 	 } else {
 	 	@array = $matrix->proj_coeff($rhs_vec)->list();
 	 }
 	# check size (hack)
 	my $max = 0;
 	foreach my $val (@array ) {
 		$max = abs($val) if  $max < abs($val);
 		if (not is_a_number($val) ) {
 			$max = "NaN: $val";
 			last;
 		}
 	}
 	if ($max =~/NaN/) {
 		$errors .= "WeBWorK was unable evaluate your function. Please check that your
 		            expression doesn't take roots of negative numbers, or divide by zero.";
 	} elsif ($max > $options{maxConstantOfIntegration} ) {
 		$errors .= "At least one of the adapting parameters
 	           (perhaps the constant of integration) is too large: $max,
 	           ( the maximum allowed is $options{maxConstantOfIntegration} )";
 	}

    $rh_ans->{ra_parameters} = \@array;
    $rh_ans->throw_error('EVAL', $errors) if defined($errors);
    $rh_ans;
}

=head4 calculate_difference_vector

	calculate_difference_vector( $ans_hash, %options);

	   			      {rf_student_ans},     # a reference to the test function
	                             {rf_correct_ans},	    # a reference to the correct answer function
	                             {evaluation_points},   # an array of row vectors indicating the points
	                              			    # to evaluate when comparing the functions
	                             {ra_parameters}        # these are the (optional) additional inputs to
	                                                    # the comparison function which adapt it properly
	                                                    # to the problem at hand.

	                             %options               # mode => 'rel'  specifies that each element in the
	                                                    # difference matrix is divided by the correct answer.
	                                                    # unless the correct answer is nearly 0.
	                            )

=cut

sub calculate_difference_vector {
	my $rh_ans = shift;
	my %options = @_;
	assign_option_aliases( \%options,
    );
    set_default_options(	\%options,
        allow_unknown_options  =>  1,
    	stdin1		           => 'rf_student_ans',
    	stdin2                 => 'rf_correct_ans',
    	stdout                 => 'ra_differences',
		debug                  =>  0,
		tolType                => 'absolute',
		error_msg_flag         =>  1,
     );
	# initialize
	$rh_ans->{_filter_name} = 'calculate_difference_vector';
	my $rf_fun              = $rh_ans -> {$options{stdin1}};        # rf_student_ans by default
	my $rf_correct_fun      = $rh_ans -> {$options{stdin2}};        # rf_correct_ans by default
	my $ra_parameters       = $rh_ans -> {ra_parameters};
	my @evaluation_points   = @{$rh_ans->{evaluation_points} };
	my @parameters          = ();
	@parameters             = @$ra_parameters if defined($ra_parameters) and ref($ra_parameters) eq 'ARRAY';
	my $errors              = undef;
	my @zero_params         = ();
	for (my $i=1;$i<=@{$ra_parameters};$i++) { 
		push(@zero_params,0); 
	}
	my @differences         = ();
	my @student_values;
	my @adjusted_student_values;
	my @instructorVals;
	my ($diff,$instructorVal);
	# calculate the vector of differences between the test function and the comparison function.
	while (@evaluation_points) {
		my ($err1, $err2,$err3);
		my @vars = @{ shift(@evaluation_points) };
		my @inputs = (@vars, @parameters);
		my ($inVal,  $correctVal);
		($inVal, $err1) = &{$rf_fun}(@vars);
		$errors .= " $err1 "  if defined($err1);
		$errors .= " Error detected evaluating student input at (".join(' , ',@vars) ." ) " if  defined($options{debug}) and $options{debug}==1 and defined($err1);
		($correctVal, $err2) =&{$rf_correct_fun}(@inputs);
		$errors .= " There is an error in WeBWorK's answer to this problem, please alert your instructor.<br> $err2 " if defined($err2);
		$errors .= " Error detected evaluating correct adapted answer  at (".join(' , ',@inputs) ." ) " if defined($options{debug}) and $options{debug}=1 and defined($err2);
		($instructorVal,$err3)= &$rf_correct_fun(@vars, @zero_params);
		$errors .= " There is an error in WeBWorK's answer to this problem, please alert your instructor.<br> $err3 " if defined($err3);
		$errors .= " Error detected evaluating instructor answer  at (".join(' , ',@vars, @zero_params) ." ) " if defined($options{debug}) and $options{debug}=1 and defined($err3);
		unless (defined($err1) or defined($err2) or defined($err3) ) {
			$diff = ( $inVal - ($correctVal -$instructorVal ) ) - $instructorVal;  #prevents entering too high a number?
			#warn "taking the difference of ", $inVal, " and ", $correctVal, " is ", $diff;
			if ( $options{tolType} eq 'relative' ) {  #relative tolerance
				#warn "diff = $diff";
				#$diff = ( $inVal - ($correctVal-$instructorVal ) )/abs($instructorVal) -1    if abs($instructorVal) > $options{zeroLevel};
				$diff = ( $inVal - ($correctVal-$instructorVal ) )/$instructorVal -1    if abs($instructorVal) > $options{zeroLevel};
				#$diff = ( $inVal - ($correctVal-$instructorVal- $instructorVal ) )/abs($instructorVal)    if abs($instructorVal) > $options{zeroLevel};
				#warn "diff = $diff,   ", abs( &$rf_correct_fun(@inputs) ) , "-- $correctVal";
			}
		}
		last if $errors;  # break if there are any errors.
                  # This cuts down on the size of error messages.
                  # However it impossible to check for equivalence at 95% of points
                  # which might be useful for functions that are not defined at some points.
        push(@student_values,$inVal);
        push(@adjusted_student_values,(  $inVal - ($correctVal -$instructorVal) ) );
		push(@differences, $diff);
		push(@instructorVals,$instructorVal);
	}
	if (( not defined($errors) )  or $errors eq '' or $options{error_msg_flag} ) {
	    $rh_ans ->{$options{stdout}} = \@differences;
		$rh_ans ->{ra_student_values} = \@student_values;
		$rh_ans ->{ra_adjusted_student_values} = \@adjusted_student_values;
		$rh_ans->{ra_instructor_values}=\@instructorVals;
		$rh_ans->throw_error('EVAL', $errors) if defined($errors);
	} else { 
	     
	}      # no output if error_msg_flag is set to 0.
	
	$rh_ans;
}

=head4 fix_answer_for_display

=cut

sub fix_answers_for_display	{
	my ($rh_ans, %options) = @_;
	if ( $rh_ans->{answerIsString} ==1) {
		$rh_ans = evaluatesToNumber ($rh_ans, %options);
	}
	if (defined ($rh_ans->{student_units})) {
		$rh_ans->{student_ans} = $rh_ans->{student_ans}. ' '. $rh_ans->{student_units};
		
	}
	if ( $rh_ans->catch_error('UNITS')  ) {  # create preview latex string for expressions even if the units are incorrect
			my $rh_temp = new AnswerHash;
			$rh_temp->{student_ans} = $rh_ans->{student_ans};
			$rh_temp = check_syntax($rh_temp);
			$rh_ans->{preview_latex_string} = $rh_temp->{preview_latex_string};
	}
	$rh_ans->{correct_ans} = $rh_ans->{original_correct_ans};

	$rh_ans;
}

=head4 evaluatesToNumber

=cut

sub evaluatesToNumber {
	my ($rh_ans, %options) = @_;
	if (is_a_numeric_expression($rh_ans->{student_ans})) {
		my ($inVal,$PG_eval_errors,$PG_full_error_report) = PG_answer_eval($rh_ans->{student_ans});
		if ($PG_eval_errors) { # this if statement should never be run
			# change nothing
		} else {
			# change this
			$rh_ans->{student_ans} = prfmt($inVal,$options{format});
		}
	}
	$rh_ans;
}

=head4 is_numeric_expression

=cut

sub is_a_numeric_expression {
	my $testString = shift;
	my $is_a_numeric_expression = 0;
	my ($inVal,$PG_eval_errors,$PG_full_error_report) = PG_answer_eval($testString);
	if ($PG_eval_errors) {
		$is_a_numeric_expression = 0;
	} else {
		$is_a_numeric_expression = 1;
	}
	$is_a_numeric_expression;
}

=head4 is_a_number

=cut

sub is_a_number {
	my ($num,%options) =	@_;
	my $process_ans_hash = ( ref( $num ) eq 'AnswerHash' ) ? 1 : 0 ;
	my ($rh_ans);
	if ($process_ans_hash) {
		$rh_ans = $num;
		$num = $rh_ans->{student_ans};
	}

	my $is_a_number	= 0;
	return $is_a_number	unless defined($num);
	$num =~	s/^\s*//; ## remove	initial	spaces
	$num =~	s/\s*$//; ## remove	trailing spaces

	## the following is	copied from	the	online perl	manual
	if ($num =~	/^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/){
		$is_a_number = 1;
	}

	if ($process_ans_hash)   {
    		if ($is_a_number == 1 ) {
    			$rh_ans->{student_ans}=$num;
    			return $rh_ans;
    		} else {
    			$rh_ans->{student_ans} = "Incorrect number format:  You	must enter a number, e.g. -6, 5.3, or 6.12E-3";
    			$rh_ans->throw_error('NUMBER', 'You must enter a number, e.g. -6, 5.3, or 6.12E-3');
    			return $rh_ans;
    		}
	} else {
		return $is_a_number;
	}
}

=head4 is_a_fraction

=cut

sub is_a_fraction {
	my ($num,%options) =	@_;
	my $process_ans_hash = ( ref( $num ) eq 'AnswerHash' ) ? 1 : 0 ;
	my ($rh_ans);
	if ($process_ans_hash) {
		$rh_ans = $num;
		$num = $rh_ans->{student_ans};
	}

	my $is_a_fraction = 0;
	return $is_a_fraction unless defined($num);
	$num =~	s/^\s*//; ## remove	initial	spaces
	$num =~	s/\s*$//; ## remove	trailing spaces

	if ($num =~	/^\s*\-?\s*[\/\d\.Ee\s]*$/) {
		$is_a_fraction = 1;
	}

    if ($process_ans_hash)   {
    	if ($is_a_fraction == 1 ) {
    		$rh_ans->{student_ans}=$num;
    		return $rh_ans;
    	} else {
    		$rh_ans->{student_ans} = "Not a number of fraction: You must enter a number or fraction, e.g. -6 or 7/13";
    		$rh_ans->throw_error('NUMBER', 'You must enter a number, e.g. -6, 5.3, or 6.12E-3');
    		return $rh_ans;
    	}

    	} else {
		return $is_a_fraction;
	}
}

=head4 phase_pi
	I often discovered that the answers I was getting, when using the arctan function would be off by phases of
	pi, which for the tangent function, were equivalent values. This method allows for this.
=cut

sub phase_pi {
	my ($num,%options) =	@_;
	my $process_ans_hash = ( ref( $num ) eq 'AnswerHash' ) ? 1 : 0 ;
	my ($rh_ans);
	if ($process_ans_hash) {
		$rh_ans = $num;
		$num = $rh_ans->{correct_ans};
	}
	while( ($rh_ans->{correct_ans}) >  3.14159265358979/2 ){
		$rh_ans->{correct_ans} -= 3.14159265358979;
	}
	while( ($rh_ans->{correct_ans}) <= -3.14159265358979/2 ){
		$rh_ans->{correct_ans} += 3.14159265358979;
	}
	$rh_ans;
}

=head4 is_an_arithemetic_expression

=cut

sub is_an_arithmetic_expression {
	my ($num,%options) =	@_;
	my $process_ans_hash = ( ref( $num ) eq 'AnswerHash' ) ? 1 : 0 ;
	my ($rh_ans);
	if ($process_ans_hash) {
		$rh_ans = $num;
		$num = $rh_ans->{student_ans};
	}

	my $is_an_arithmetic_expression = 0;
	return $is_an_arithmetic_expression unless defined($num);
	$num =~	s/^\s*//; ## remove	initial	spaces
	$num =~	s/\s*$//; ## remove	trailing spaces

	if ($num =~	/^[+\-*\/\^\(\)\[\]\{\}\s\d\.Ee]*$/) {
		$is_an_arithmetic_expression =	1;
	}

    if ($process_ans_hash)   {
    	if ($is_an_arithmetic_expression == 1 ) {
    		$rh_ans->{student_ans}=$num;
    		return $rh_ans;
    	} else {

		$rh_ans->{student_ans} = "Not an arithmetic expression: You must enter an arithmetic expression, e.g. -6 or (2.3*4+5/3)^2";
    		$rh_ans->throw_error('NUMBER', 'You must enter an arithmetic expression, e.g. -6 or (2.3*4+5/3)^2');
    		return $rh_ans;
    	}

    	} else {
		return $is_an_arithmetic_expression;
	}
}

#

=head4 math_constants

replaces pi, e, and ^ with their Perl equivalents
if useBaseTenLog is non-zero, convert log to logten

=cut

sub math_constants {
	my($in,%options) = @_;
	my $rh_ans;
	my $process_ans_hash = ( ref( $in ) eq 'AnswerHash' ) ? 1 : 0 ;
	if ($process_ans_hash) {
		$rh_ans = $in;
		$in = $rh_ans->{student_ans};
	}
	# The code fragment above allows this filter to be used when the input is simply a string
	# as well as when the input is an AnswerHash, and options.
	$in	=~s/\bpi\b/(4*atan2(1,1))/ge;
	$in	=~s/\be\b/(exp(1))/ge;
	$in	=~s/\^/**/g;
	if($useBaseTenLog) {
		$in =~ s/\blog\b/logten/g;
	}

	if ($process_ans_hash)   {
    	$rh_ans->{student_ans}=$in;
    	return $rh_ans;
    } else {
		return $in;
	}
}



=head4 is_array

	is_array($rh_ans)
		returns: $rh_ans.   Throws error "NOTARRAY" if this is not an array

=cut

sub is_array	{
	my $rh_ans = shift;
    # return if the result is an array
	return($rh_ans) if  ref($rh_ans->{student_ans}) eq 'ARRAY' ;
	$rh_ans->throw_error("NOTARRAY","The answer is not an array");
	$rh_ans;
}

=head4 check_syntax

	check_syntax( $rh_ans, %options)
		returns an answer hash.

latex2html preview code are installed in the answer hash.
The input has been transformed, changing 7pi to 7*pi  or 7x to 7*x.
Syntax error messages may be generated and stored in student_ans
Additional syntax error messages are stored in {ans_message} and duplicated in {error_message}


=cut

sub check_syntax {
        my $rh_ans = shift;
        my %options = @_;
        assign_option_aliases(\%options,
		);
		set_default_options(  \%options,
					'stdin'         =>  'student_ans',
					'stdout'		=>  'student_ans',
					'ra_vars'		=>	[qw( x y )],
					'debug'			=>	0,
					'_filter_name'	=>	'check_syntax',
					error_msg_flag  =>  1,
		);
		#initialize
		$rh_ans->{_filter_name}     = $options{_filter_name};
        unless ( defined( $rh_ans->{$options{stdin}} ) ) {
        	warn "Check_syntax requires an equation in the field '$options{stdin}' or input";
        	$rh_ans->throw_error("1","'$options{stdin}' field not defined");
        	return $rh_ans;
        }
        my $in     = $rh_ans->{$options{stdin}};
		my $parser = new AlgParserWithImplicitExpand;
		my $ret	   = $parser -> parse($in);			#for use with loops

		if ( ref($ret) )  {		## parsed successfully
			# $parser -> tostring();   # FIXME?  was this needed for some reason?????
			$parser -> normalize();
			$rh_ans -> {$options{stdout}}     = $parser -> tostring();
			$rh_ans -> {preview_text_string}  = $in;
			$rh_ans -> {preview_latex_string} =	$parser -> tolatex();

		} elsif ($options{error_msg_flag} ) {					## error in	parsing

			$rh_ans->{$options{stdout}}			=	'syntax error:'. $parser->{htmlerror},
			$rh_ans->{'ans_message'}			=	$parser -> {error_msg},
			$rh_ans->{'preview_text_string'}	=	'',
			$rh_ans->{'preview_latex_string'}	=	'',
			$rh_ans->throw_error('SYNTAX',	'syntax error in answer:'. $parser->{htmlerror} . "$BR" .$parser -> {error_msg});
		}   # no output is produced if there is an error and the error_msg_flag is set to zero
       $rh_ans;

}

=head4 check_strings

	check_strings ($rh_ans, %options)
		returns $rh_ans

=cut

sub check_strings {
	my ($rh_ans, %options) = @_;

	# if the student's answer is a number, simply return the answer hash (unchanged).

	#  we allow constructions like -INF to be treated as a string. Thus we ignore an initial
	# - in deciding whether the student's answer is a number or string

	my $temp_ans = $rh_ans->{student_ans};
	$temp_ans =~ s/^\s*\-//;   # remove an initial -

	if  ( $temp_ans =~ m/[\d+\-*\/^(){}\[\]]|^\s*e\s*$|^\s*pi\s*$/)   {
	#	if ( $rh_ans->{answerIsString} == 1) {
	#			#$rh_ans->throw_error('STRING','Incorrect Answer');	# student's answer is a number
	#	}
		return $rh_ans;
	}
	# the student's answer is recognized as a string
	my $ans = $rh_ans->{student_ans};

# OVERVIEW of reminder of function:
# if answer is correct, return correct.  (adjust score to 1)
# if answer is incorect:
#	1) determine if the answer is sensible.  if it is, return incorrect.
#	2) if the answer is not sensible (and incorrect), then return an error message indicating so.
# no matter what:  throw a 'STRING' error to skip numerical evaluations.  (error flag skips remainder of pre_filters and evaluators)
# last: 'STRING' post_filter will clear the error (avoiding pink screen.)

	my $sensibleAnswer = 0;
	$ans = str_filters( $ans, 'compress_whitespace' );	# remove trailing, leading, and double spaces.
	my ($ans_eval) = str_cmp($rh_ans->{correct_ans});
	my $temp_ans_hash = $ans_eval->evaluate($ans);
	$rh_ans->{test} = $temp_ans_hash;
	
	if ($temp_ans_hash->{score} ==1 ) {			# students answer matches the correct answer.
		$rh_ans->{score} = 1;
		$sensibleAnswer = 1;
	} else {						# students answer does not match the correct answer.
		my $legalString	= '';				# find out if string makes sense
		my @legalStrings = @{$options{strings}};
		foreach	$legalString (@legalStrings) {
			if ( uc($ans) eq uc($legalString) ) {
				$sensibleAnswer	= 1;
				last;
				}
			}
		$sensibleAnswer	= 1 unless $ans	=~ /\S/;  ## empty answers are sensible
		$rh_ans->throw_error('EVAL', "Your answer is not a recognized answer") unless ($sensibleAnswer);
		# $temp_ans_hash -> setKeys( 'ans_message' => 'Your answer is not a recognized answer' ) unless ($sensibleAnswer);
		# $temp_ans_hash -> setKeys( 'student_ans' => uc($ans) );
	}
	
	$rh_ans->{student_ans} = $ans;
	
	if ($sensibleAnswer) {
		$rh_ans->throw_error('STRING', "The student's answer $rh_ans->{student_ans} is interpreted as a string.");
	}
	
	$rh_ans->{'preview_text_string'}	=	$ans,
	$rh_ans->{'preview_latex_string'}	=	$ans,

	# warn ("\$rh_ans->{answerIsString} = $rh_ans->{answerIsString}");
	$rh_ans;
}

=head4 check_units

	check_strings ($rh_ans, %options)
		returns $rh_ans


=cut

sub check_units {
	my ($rh_ans, %options) = @_;
	my %correct_units = %{$rh_ans-> {rh_correct_units}};
	my $ans = $rh_ans->{student_ans};
	# $ans = '' unless defined ($ans);
	$ans = str_filters ($ans, 'trim_whitespace');
	my $original_student_ans = $ans;
	$rh_ans->{original_student_ans} = $original_student_ans;

	# it surprises me that the match below works since the first .*	is greedy.
	my ($num_answer, $units) = $ans	=~ /^(.*)\s+([^\s]*)$/;

	unless ( defined($num_answer) && $units	) {
		# there	is an error reading the input
		if ( $ans =~ /\S/ )	 {	# the answer is not blank
			$rh_ans -> setKeys( 'ans_message' => "The answer \"$ans\" could not be interpreted " .
				"as a number or an arithmetic expression followed by a unit specification. " .
				"Your answer must contain units." );
			$rh_ans->throw_error('UNITS', "The answer \"$ans\" could not be interpreted " .
				"as a number or an arithmetic expression followed by a unit specification. " .
				"Your answer must contain units." );
		}
		return $rh_ans;
	}

	# we have been able to parse the answer	into a numerical part and a unit part

	# $num_answer	= $1;		#$1 and $2 from the regular expression above
	# $units 		= $2;

	my %units = Units::evaluate_units($units);
	if ( defined( $units{'ERROR'} ) ) {
		 # handle error	condition
         	$units{'ERROR'}	= clean_up_error_msg($units{'ERROR'});
		$rh_ans -> setKeys( 'ans_message' => "$units{'ERROR'}" );
		$rh_ans -> throw_error('UNITS', "$units{'ERROR'}");
		return $rh_ans;
	}

	my $units_match	= 1;
	my $fund_unit;
	foreach	$fund_unit (keys %correct_units) {
		next if	$fund_unit eq 'factor';
		$units_match = 0 unless	$correct_units{$fund_unit} == $units{$fund_unit};
	}

	if ( $units_match )	{
		    # units	are	ok.	 Evaluate the numerical	part of	the	answer
		$rh_ans->{'tolerance'} = $rh_ans->{'tolerance'}* $correct_units{'factor'}/$units{'factor'}	if
	    		$rh_ans->{'tolType'} eq 'absolute'; # the tolerance is in the units specified by the instructor.
		$rh_ans->{correct_ans} =  prfmt($rh_ans->{correct_ans}*$correct_units{'factor'}/$units{'factor'});
		$rh_ans->{student_units} = $units;
		$rh_ans->{student_ans} = $num_answer;

	} else {
		    $rh_ans -> setKeys( ans_message => 'There is an error in the units for this answer.' );
		    $rh_ans -> throw_error ( 'UNITS', 'There is an error in the units for this answer.' );
	}

	return $rh_ans;
}



=head2 Filter utilities

These two subroutines can be used in filters to set default options.  They
help make filters perform in uniform, predictable ways, and also make it
easy to recognize from the code which options a given filter expects.


=head4 assign_option_aliases

Use this to assign aliases for the standard options.  It must come before set_default_options
within the subroutine.

		assign_option_aliases(\%options,
				'alias1'	=> 'option5'
				'alias2'	=> 'option7'
		);


If the subroutine is called with an option  " alias1 => 23 " it will behave as if it had been
called with the option " option5 => 23 "

=cut



sub assign_option_aliases {
	my $rh_options = shift;
	warn "The first entry to set_default_options must be a reference to the option hash" unless ref($rh_options) eq 'HASH';
	my @option_aliases = @_;
	while (@option_aliases) {
		my $alias = shift @option_aliases;
		my $option_key = shift @option_aliases;

		if (defined($rh_options->{$alias} )) {                       # if the alias appears in the option list
			if (not defined($rh_options->{$option_key}) ) {          # and the option itself is not defined,
				$rh_options->{$option_key} = $rh_options->{$alias};  # insert the value defined by the alias into the option value
				                                                     # the FIRST alias for a given option takes precedence
				                                                     # (after the option itself)
			} else {
				warn "option $option_key is already defined as", $rh_options->{$option_key}, "<br>\n",
				     "The attempt to override this option with the alias $alias with value ", $rh_options->{$alias},
				     " was ignored.";
			}
		}
		delete($rh_options->{$alias});                               # remove the alias from the initial list
	}

}

=head4 set_default_options

		set_default_options(\%options,
				'_filter_name'	=>	'filter',
				'option5'		=>  .0001,
				'option7'		=>	'ascii',
				'allow_unknown_options	=>	0,
		}

Note that the first entry is a reference to the options with which the filter was called.

The option5 is set to .0001 unless the option is explicitly set when the subroutine is called.

The B<'_filter_name'> option should always be set, although there is no error if it is missing.
It is used mainly for debugging answer evaluators and allows
you to keep track of which filter is currently processing the answer.

If B<'allow_unknown_options'> is set to 0 then if the filter is called with options which do NOT appear in the
set_default_options list an error will be signaled and a warning message will be printed out.  This provides
error checking against misspelling an option and is generally what is desired for most filters.

Occasionally one wants to write a filter which accepts a long list of options, not all of which are known in advance,
but only uses a subset of the options
provided.  In this case, setting 'allow_unkown_options' to 1 prevents the error from being signaled.

=cut

sub set_default_options {
	my $rh_options = shift;
	warn "The first entry to set_default_options must be a reference to the option hash" unless ref($rh_options) eq 'HASH';
	my %default_options = @_;
	unless ( defined($default_options{allow_unknown_options}) and $default_options{allow_unknown_options} == 1 ) {
		foreach  my $key1 (keys %$rh_options) {
			warn "This option |$key1| is not recognized in this subroutine<br> ", pretty_print($rh_options) unless exists($default_options{$key1});
		}
	}
	foreach my $key (keys %default_options) {
		if  ( not defined($rh_options->{$key} ) and defined( $default_options{$key} )  ) {
			$rh_options->{$key} = $default_options{$key};  #this allows     tol   => undef to allow the tol option, but doesn't define
			                                               # this key unless tol is explicitly defined.
		}
	}
}

=head2 Problem Grader Subroutines

=cut

## Problem Grader Subroutines

#####################################
# This is a	model for plug-in problem graders
#####################################
sub install_problem_grader {
	my $rf_problem_grader =	shift;
	my $rh_flags = PG_restricted_eval(q!\\%main::PG_FLAGS!);
	$rh_flags->{PROBLEM_GRADER_TO_USE} = $rf_problem_grader;
}

=head4 std_problem_grader

This is an all-or-nothing grader.  A student must get all parts of the problem write
before receiving credit.  You should make sure to use this grader on multiple choice
and true-false questions, otherwise students will be able to deduce how many
answers are correct by the grade reported by webwork.


	install_problem_grader(~~&std_problem_grader);

=cut

sub std_problem_grader {
	my $rh_evaluated_answers = shift;
	my $rh_problem_state = shift;
	my %form_options = @_;
	my %evaluated_answers =	%{$rh_evaluated_answers};
	#  The hash	$rh_evaluated_answers typically	contains:
	#	   'answer1' =>	34,	'answer2'=>	'Mozart', etc.

	# By default the  old problem state	is simply passed back out again.
	my %problem_state =	%$rh_problem_state;

	# %form_options	might include
	# The user login name
	# The permission level of the user
	# The studentLogin name	for	this psvn.
	# Whether the form is asking for a refresh or is submitting	a new answer.

	# initial setup	of the answer
	my %problem_result = ( score		=> 0,
   			       errors		=> '',
			       type		=> 'std_problem_grader',
			       msg	 	=> '',
	);
	# Checks

	my $ansCount = keys	%evaluated_answers;	 # get the number of answers

	unless ($ansCount >	0 )	{

		$problem_result{msg} = "This problem did not ask any questions.";
		return(\%problem_result,\%problem_state);
	}

	if ($ansCount >	1 )	{
		$problem_result{msg} = 'In order to	get	credit for this	problem	all	answers	must be	correct.' ;
	}

	unless ($form_options{answers_submitted} ==	1) {
		return(\%problem_result,\%problem_state);
	}

	my $allAnswersCorrectQ=1;
	foreach	my $ans_name (keys %evaluated_answers) {
	# I'm not sure if this check is	really useful.
		if ( ( ref($evaluated_answers{$ans_name} ) eq 'HASH' ) or ( ref($evaluated_answers{$ans_name}) eq 'AnswerHash' ) )	{
			$allAnswersCorrectQ	= 0	unless(	1 == $evaluated_answers{$ans_name}->{score}	);
		}
		else {
			die	"Error at file ",__FILE__,"line ", __LINE__,":	Answer |$ans_name| is not a	hash reference\n".
				 $evaluated_answers{$ans_name} .
				 "This probably	means that the answer evaluator	for	this answer\n" .
				 "is not working correctly.";
			$problem_result{error} = "Error: Answer	$ans_name is not a hash: $evaluated_answers{$ans_name}";
		}
	}
	# report the results
	$problem_result{score} = $allAnswersCorrectQ;

	# I	don't like to put in this bit of code.
	# It makes it hard to construct	error free problem graders
	# I	would prefer to	know that the problem score	was	numeric.
	unless (defined($problem_state{recorded_score}) and $problem_state{recorded_score} =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/ ) {
		$problem_state{recorded_score} = 0;	 # This	gets rid of non-numeric scores
	}
	#
	if ($allAnswersCorrectQ	== 1 or	$problem_state{recorded_score} == 1) {
		$problem_state{recorded_score} = 1;
	}
	else {
		$problem_state{recorded_score} = 0;
	}

	$problem_state{num_of_correct_ans}++ if	$allAnswersCorrectQ	== 1;
	$problem_state{num_of_incorrect_ans}++ if $allAnswersCorrectQ == 0;
	
	$problem_state{state_summary_msg} = '';  # an HTML formatted message printed at the bottom of the problem page
	
	(\%problem_result, \%problem_state);
}

=head4 std_problem_grader2

This is an all-or-nothing grader.  A student must get all parts of the problem write
before receiving credit.  You should make sure to use this grader on multiple choice
and true-false questions, otherwise students will be able to deduce how many
answers are correct by the grade reported by webwork.


	install_problem_grader(~~&std_problem_grader2);

The only difference between the two versions
is at the end of the subroutine, where std_problem_grader2
records the attempt only if there have been no syntax errors,
whereas std_problem_grader records it regardless.

=cut



sub std_problem_grader2 {
	my $rh_evaluated_answers = shift;
	my $rh_problem_state = shift;
	my %form_options = @_;
	my %evaluated_answers =	%{$rh_evaluated_answers};
	#  The hash	$rh_evaluated_answers typically	contains:
	#	   'answer1' =>	34,	'answer2'=>	'Mozart', etc.

	# By default the  old problem state	is simply passed back out again.
	my %problem_state =	%$rh_problem_state;

	# %form_options	might include
	# The user login name
	# The permission level of the user
	# The studentLogin name	for	this psvn.
	# Whether the form is asking for a refresh or is submitting	a new answer.

	# initial setup	of the answer
	my %problem_result = ( score				=> 0,
 			       errors				=> '',
			       type				=> 'std_problem_grader',
			       msg				=> '',
	);

	# syntax errors	are	not	counted.
	my $record_problem_attempt = 1;
	# Checks

	my $ansCount = keys	%evaluated_answers;	 # get the number of answers
	unless ($ansCount >	0 )	{
		$problem_result{msg} = "This problem did not ask any questions.";
		return(\%problem_result,\%problem_state);
	}

	if ($ansCount >	1 )	{
		$problem_result{msg} = 'In order to	get	credit for this	problem	all	answers	must be	correct.' ;
	}

	unless ($form_options{answers_submitted} ==	1) {
		return(\%problem_result,\%problem_state);
	}

	my	$allAnswersCorrectQ=1;
	foreach	my $ans_name (keys %evaluated_answers) {
	# I'm not sure if this check is	really useful.
		if ( ( ref($evaluated_answers{$ans_name} ) eq 'HASH' ) or ( ref($evaluated_answers{$ans_name}) eq 'AnswerHash' ) )	{
			$allAnswersCorrectQ	= 0	unless(	1 == $evaluated_answers{$ans_name}->{score}	);
		}
		else {
			die	"Error at file ",__FILE__,"line ", __LINE__,":	Answer |$ans_name| is not a	hash reference\n".
				 $evaluated_answers{$ans_name} .
				 "This probably	means that the answer evaluator	for	this answer\n" .
				 "is not working correctly.";
			$problem_result{error} = "Error: Answer	$ans_name is not a hash: $evaluated_answers{$ans_name}";
		}
	}
	# report the results
	$problem_result{score} = $allAnswersCorrectQ;

	# I	don't like to put in this bit of code.
	# It makes it hard to construct	error free problem graders
	# I	would prefer to	know that the problem score	was	numeric.
	unless ($problem_state{recorded_score} =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/ ) {
		$problem_state{recorded_score} = 0;	 # This	gets rid of	non-numeric	scores
	}
	#
	if ($allAnswersCorrectQ	== 1 or	$problem_state{recorded_score} == 1) {
		$problem_state{recorded_score} = 1;
	}
	else {
		$problem_state{recorded_score} = 0;
	}
	# record attempt only if there have	been no	syntax errors.

	if ($record_problem_attempt	== 1) {
		$problem_state{num_of_correct_ans}++ if	$allAnswersCorrectQ	== 1;
		$problem_state{num_of_incorrect_ans}++ if $allAnswersCorrectQ == 0;
		$problem_state{state_summary_msg} = '';  # an HTML formatted message printed at the bottom of the problem page
	
	}
	else {
		$problem_result{show_partial_correct_answers} =	0 ;	 # prevent partial correct answers from	being shown	for	syntax errors.
	}
	(\%problem_result, \%problem_state);
}

=head4 avg_problem_grader

This grader gives a grade depending on how many questions from the problem are correct.  (The highest
grade is the one that is kept.  One can never lower the recorded grade on a problem by repeating it.)
Many professors (and almost all students :-)  ) prefer this grader.


	install_problem_grader(~~&avg_problem_grader);

=cut


sub avg_problem_grader {
		my $rh_evaluated_answers = shift;
	my $rh_problem_state = shift;
	my %form_options = @_;
	my %evaluated_answers =	%{$rh_evaluated_answers};
	#  The hash	$rh_evaluated_answers typically	contains:
	#	   'answer1' =>	34,	'answer2'=>	'Mozart', etc.

	# By default the  old problem state	is simply passed back out again.
	my %problem_state =	%$rh_problem_state;


	# %form_options	might include
	# The user login name
	# The permission level of the user
	# The studentLogin name	for	this psvn.
	# Whether the form is asking for a refresh or is submitting	a new answer.

	# initial setup	of the answer
	my	$total=0;
	my %problem_result = ( score				=> 0,
			       errors				=> '',
			       type				=> 'avg_problem_grader',
			       msg				=> '',
	);
	my $count =	keys %evaluated_answers;
	$problem_result{msg} = 'You	can	earn partial credit	on this	problem.' if $count	>1;
	# Return unless	answers	have been submitted
	unless ($form_options{answers_submitted} ==	1) {
		return(\%problem_result,\%problem_state);
	}

	# Answers have been	submitted -- process them.
	foreach	my $ans_name (keys %evaluated_answers) {
		# I'm not sure if this check is	really useful.
		if ( ( ref($evaluated_answers{$ans_name} ) eq 'HASH' ) or ( ref($evaluated_answers{$ans_name}) eq 'AnswerHash' ) )	{
			$total += $evaluated_answers{$ans_name}->{score};
		}
		else {
			die	"Error:	Answer |$ans_name| is not a	hash reference\n".
				 $evaluated_answers{$ans_name} .
				 "This probably	means that the answer evaluator	for	this answer\n" .
				 "is not working correctly.";
			$problem_result{error} = "Error: Answer	$ans_name is not a hash: $evaluated_answers{$ans_name}";
		}
	}
	# Calculate	score rounded to three places to avoid roundoff	problems
	$problem_result{score} = $total/$count if $count;
	# increase recorded	score if the current score is greater.
	$problem_state{recorded_score} = $problem_result{score}	if $problem_result{score} >	$problem_state{recorded_score};


	$problem_state{num_of_correct_ans}++ if	$total == $count;
	$problem_state{num_of_incorrect_ans}++ if $total < $count ;
	
	$problem_state{state_summary_msg} = '';  # an HTML formatted message printed at the bottom of the problem page
	
	warn "Error	in grading this	problem	the	total $total is	larger than	$count"	if $total >	$count;
	(\%problem_result, \%problem_state);
}

=head2 Utility subroutines

=head4

	warn pretty_print( $rh_hash_input)

This can be very useful for printing out messages about objects while debugging

=cut

sub pretty_print {
    my $r_input = shift;
    my $out = '';
    if ( not ref($r_input) ) {
    	$out = $r_input;    # not a reference
    } elsif ("$r_input" =~/hash/i) {  # this will pick up objects whose '$self' is hash and so works better than ref($r_iput).
	    local($^W) = 0;
		$out .= "$r_input " ."<TABLE border = \"2\" cellpadding = \"3\" BGCOLOR = \"#FFFFFF\">";
		foreach my $key (lex_sort( keys %$r_input )) {
			$out .= "<tr><TD> $key</TD><TD>=&gt;</td><td>&nbsp;".pretty_print($r_input->{$key}) . "</td></tr>";
		}
		$out .="</table>";
	} elsif (ref($r_input) eq 'ARRAY' ) {
		my @array = @$r_input;
		$out .= "( " ;
		while (@array) {
			$out .= pretty_print(shift @array) . " , ";
		}
		$out .= " )";
	} elsif (ref($r_input) eq 'CODE') {
		$out = "$r_input";
	} else {
		$out = $r_input;
	}
		$out;
}

1;
