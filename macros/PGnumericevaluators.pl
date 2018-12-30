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

PGnumericevaluators.pl - Macros that generate numeric answer evaluators.

=head1 SYNOPSIS

	ANS(num_cmp($answer_or_answer_array_ref, %options_hash));
	
	ANS(std_num_cmp($correctAnswer, $relTol, $format, $zeroLevel, $zeroLevelTol));
	ANS(std_num_cmp_abs($correctAnswer, $absTol, $format));
	ANS(std_num_cmp_list($relTol, $format, @answerList));
	ANS(std_num_cmp_abs_list($absTol, $format, @answerList));
	
	ANS(arith_num_cmp($correctAnswer, $relTol, $format, $zeroLevel, $zeroLevelTol));
	ANS(arith_num_cmp_abs($correctAnswer, $absTol, $format));
	ANS(arith_num_cmp_list($relTol, $format, @answerList));
	ANS(arith_num_cmp_abs_list($absTol, $format, @answerList));
	
	ANS(strict_num_cmp($correctAnswer, $relTol, $format, $zeroLevel, $zeroLevelTol));
	ANS(strict_num_cmp_abs($correctAnswer, $absTol, $format));
	ANS(strict_num_cmp_list($relTol, $format, @answerList));
	ANS(strict_num_cmp_abs_list($absTol, $format, @answerList));
	
	ANS(frac_num_cmp($correctAnswer, $relTol, $format, $zeroLevel, $zeroLevelTol));
	ANS(frac_num_cmp_abs($correctAnswer, $absTol, $format));
	ANS(frac_num_cmp_list($relTol, $format, @answerList));
	ANS(frac_num_cmp_abs_list($absTol, $format, @answerList));

=head1 DESCRIPTION

Numeric answer evaluators take in a numerical answer, compare it to the correct
answer, and return a score. In addition, they can choose to accept or reject an
answer based on its format, closeness to the correct answer, and other criteria.

The general numeric answer evaluator is num_cmp(). It takes a hash of named
options as parameters. There are also sixteen specific "mode"_num_cmp() answer
evaluators for use in common situations which feature a simplified syntax.

=head2 MathObjects and answer evaluators

The MathObjects system provides $obj->cmp() methods that produce answer
evaluators for a wide variety of answer types. num_cmp() has been rewritten to
use the appropriate MathObject to produce the answer evaluator. It is
recommended that you use the MathObjects cmp() methods directly if possible.

=cut

BEGIN { be_strict() }

# Until we get the PG cacheing business sorted out, we need to use
# PG_restricted_eval to get the correct values for some(?) PG environment
# variables. We do this once here and place the values in lexicals for later
# access.
my $CA;
my $Context;
my $numAbsTolDefault;
my $numFormatDefault;
my $numRelPercentTolDefault;
my $numZeroLevelDefault;
my $numZeroLevelTolDefault;
my $useOldAnswerMacros;
my $user_context;
sub _PGnumericevaluators_init {
	$CA                      = PG_restricted_eval(q/$CA/);
	$numAbsTolDefault        = PG_restricted_eval(q/$envir{numAbsTolDefault}/);
	$numFormatDefault        = PG_restricted_eval(q/$envir{numFormatDefault}/);
	$numRelPercentTolDefault = PG_restricted_eval(q/$envir{numRelPercentTolDefault}/);
	$numZeroLevelDefault     = PG_restricted_eval(q/$envir{numZeroLevelDefault}/);
	$numZeroLevelTolDefault  = PG_restricted_eval(q/$envir{numZeroLevelTolDefault}/);
	$useOldAnswerMacros      = PG_restricted_eval(q/$envir{useOldAnswerMacros}/);
	unless ($useOldAnswerMacros) {
		$user_context = PG_restricted_eval(q/\%context/);
		$Context = sub { Parser::Context->current($user_context, @_) };
	}
}

=head1 num_cmp

	ANS(num_cmp($answer_or_answer_array_ref, %options));

num_cmp() returns one or more answer evaluators (subroutine references) that
compare the student's answer to a numeric value. Evaluation options are
specified as items in the %options hash. This can make for more readable code
than using the "mode"_num_cmp() style, but some people find one or the other
easier to remember.

=head2 Options

$answer_or_answer_array_ref can either be a scalar containing a numeric value or
a reference to an array of numeric scalars. If multiple answers are provided,
num_cmp() will return a list of answer evaluators, one for each answer
specified. %options is a hash containing options that affect the way the
comparison is performed. All hash items are optional. Allowed options are:

=over

=item mode

This determines the allowable methods for entering an answer. Answers which do
not meet this requirement will be graded as incorrect, regardless of their
numerical value. The recognized modes are:

=over

=item std (default)

The default mode allows any expression which evaluates to a number, including
those using elementary functions like sin() and exp(), as well as the operations
of arithmetic (+, -, *, /, and ^).

=item strict

Only decimal numbers are allowed.

=item frac

Only whole numbers and fractions are allowed.

=item arith

Arithmetic expressions are allowed, but no functions.

=back

Note that all modes allow the use of "pi" and "e" as constants, and also the use
of "E" to represent scientific notation.

=item format

The format to use when displaying the correct and submitted answers. This has no
effect on how answers are evaluated; it is only for cosmetic purposes. The
formatting syntax is the same as Perl uses for the sprintf() function. Format
strings are of the form '%m.nx' or '%m.nx#', where m and n are described below,
and x is a formatter.

Esentially, m is the minimum length of the field (make this negative to
left-justify). Note that the decimal point counts as a character when
determining the field width. If m begins with a zero, the number will be padded
with zeros instead of spaces to fit the field.

The precision specifier (n) works differently depending on which formatter you
are using. For d, i, o, u, x and X formatters (non-floating point formatters), n
is the minimum number of digits to display. For e and f, it is the number of
digits that appear after the decimal point (extra digits will be rounded;
insufficient digits will be padded with spaces--see '#' below). For g, it is the
number of significant digits to display.

The full list of formatters can be found in the manpage for printf(3), or by
typing "perldoc -f sprintf" at a terminal prompt. The following is a brief
summary of the most frequent formatters:

	%d     decimal number
	%ld    long decimal number
	%u     unsigned decimal number
	%lu    long unsigned decimal number
	%x     hexadecimal number
	%o     octal number
	%e     floating point number in scientific notation
	%f     floating point number
	%g     either %e or %f, whichever takes less space

Technically, %g will use %e if the exponent is less than -4 or greater than or
equal to the precision. Trailing zeros are removed in this mode.

If the format string ends in '#', trailing zeros will be removed in the decimal
part. Note that this is not a standard syntax; it is handled internally by
WeBWorK and not by Perl (although this should not be a concern to end users).
The default format is '%0.5f#', which displays as a floating point number with 5
digits of precision and no trailing zeros. Other useful format strings might be
'%0.2f' for displaying dollar amounts, or '%010d' to display an integer with
leading zeros. Setting format to an empty string ( '' ) means no formatting will
be used; this will show 'arbitrary' precision floating points.

=item tol

An absolute tolerance value. The student answer must be a fixed distance from
the correct answer to qualify. For example, an absolute tolerance of 5 means
that any number which is +-5 of the correct answer qualifies as correct. abstol
is accepted as a synonym for tol.

=item relTol

A relative tolerance. Relative tolerances are given in percentages. A relative
tolerance of 1 indicates that the student answer must be within 1% of the
correct answer to qualify as correct. In other words, a student answer is
correct when

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

=item units

A string representing the units of the correct answer. If specified, the student
answer must include these units. The strings and units options are mutually
exclusive.

=item strings

A reference to an array of strings which are valid (but incorrect) answers. This
prevents non-numeric entries like "NaN" or "None" from causing a syntax error.
The strings and units options are mutually exclusive.

=item debug

If set to 1, extra debugging information will be output.

=back

=head2 Examples

	# correct answer is 5, using defaults for all options
	num_cmp(5);

	# correct answers are 5, 6, and 7, using defaults for all options
	num_cmp([5,6,7]);

	# correct answer is 5, mode is strict
	num_cmp(5, mode=>'strict');

	# correct answers are 5 and 6, both with 5% relative tolerance
	num_cmp([5,6], relTol=>5);

	# correct answer is 6, "Inf", "Minf", and "NaN" recognized as valid, but
	# incorrect answers.
	num_cmp(6, strings=>["Inf", "Minf", "NaN"]);

	# correct answer is "-INF", "INF" and numerical expressions recognized as
	# valid, but incorrect answers.
	num_cmp("-INF", strings => ["INF", "-INF"]);

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

			push( @output_list, NUM_CMP(	
			                'correctAnswer'	=>	$ans,
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


			push( @output_list, NUM_CMP( 	
			                'correctAnswer'	=> 	$ans,
							'tolerance'		=>	$out_options{tolerance},
							'tolType'		=>	$out_options{tolType},
							'format'		=>	$out_options{'format'},
							'mode'			=>	$out_options{'mode'},
							'zeroLevel'		=>	$out_options{'zeroLevel'},
							'zeroLevelTol'	=>	$out_options{'zeroLevelTol'},
							'debug'			=>	$out_options{'debug'},
							'strings'		=> 	$out_options{'strings'},
				 )
				 );
		} else {
			push(@output_list,
				NUM_CMP(	
				    'correctAnswer'	=>	$ans,
					'tolerance'		=>	$out_options{tolerance},
					'tolType'		=>	$out_options{tolType},
					'format'		=>	$out_options{'format'},
					'mode'			=>	$out_options{'mode'},
					'zeroLevel'		=>	$out_options{'zeroLevel'},
					'zeroLevelTol'	=>	$out_options{'zeroLevelTol'},
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

=head1 "mode"_num_cmp() functions

There are 16 functions that provide simplified interfaces to num_cmp(). They are
organized into four groups, based on the number of answers accpeted (single or
list) and whether relative or absolute tolerances are used. Each group contains
four functions, one for each evaluation mode. See the mode option to num_cmp()
above for details about each mode.

	 GROUP:|    "normal"    |       "list"        |       "abs"        |        "abs_list"       |
	       | single answer  |   list of answers   |   single answer    |     list of answers     |
	MODE:  | relative tol.  | relative tolerance  | absolute tolerance |    absolute tolerance   |
	-------+----------------+---------------------+--------------------+-------------------------+
	   std |    std_num_cmp |    std_num_cmp_list |    std_num_cmp_abs |    std_num_cmp_abs_list |
	  frac |   frac_num_cmp |   frac_num_cmp_list |   frac_num_cmp_abs |   frac_num_cmp_abs_list |
	strict | strict_num_cmp | strict_num_cmp_list | strict_num_cmp_abs | strict_num_cmp_abs_list |
	 arith |  arith_num_cmp |  arith_num_cmp_list |  arith_num_cmp_abs |  arith_num_cmp_abs_list |

The functions in each group take the same arguments.

=head2 The normal group

	ANS(std_num_cmp($correctAnswer, $relTol, $format, $zeroLevel, $zeroLevelTol));
	ANS(arith_num_cmp($correctAnswer, $relTol, $format, $zeroLevel, $zeroLevelTol));
	ANS(strict_num_cmp($correctAnswer, $relTol, $format, $zeroLevel, $zeroLevelTol));
	ANS(frac_num_cmp($correctAnswer, $relTol, $format, $zeroLevel, $zeroLevelTol));

This group of functions produces answer evaluators for a single correct answer
using relative tolerances. The first argument, $correctAnswer, is required. The
rest are optional. The arguments are equivalent to the identically-named options
to num_cmp(), above.

=head2 The list group

	ANS(std_num_cmp_list($relTol, $format, @answerList));
	ANS(arith_num_cmp_list($relTol, $format, @answerList));
	ANS(strict_num_cmp_list($relTol, $format, @answerList));
	ANS(frac_num_cmp_list($relTol, $format, @answerList));

This group of functions produces answer evaluators for a list of correct answers
using relative tolerances. $relTol and $format are equivelent to the
identically-named options to num_cmp() above. @answerList must contain one or
more correct answers. A list of answer evaluators is returned, one for each
answer provided in @answerList. All answer returned evaluators will use the
relative tolerance and format specified.

=head2 The abs group

	ANS(std_num_cmp_abs($correctAnswer, $absTol, $format));
	ANS(arith_num_cmp_abs($correctAnswer, $absTol, $format));
	ANS(strict_num_cmp_abs($correctAnswer, $absTol, $format));
	ANS(frac_num_cmp_abs($correctAnswer, $absTol, $format));

This group of functions produces answer evaluators for a single correct answer
using absolute tolerances. The first argument, $correctAnswer, is required. The
rest are optional. The arguments are equivalent to the identically-named options
to num_cmp(), above.

=head2 The abs_list group

	ANS(std_num_cmp_abs_list($absTol, $format, @answerList));
	ANS(arith_num_cmp_abs_list($absTol, $format, @answerList));
	ANS(strict_num_cmp_abs_list($absTol, $format, @answerList));
	ANS(frac_num_cmp_abs_list($absTol, $format, @answerList));

This group of functions produces answer evaluators for a list of correct answers
using absolute tolerances. $absTol and $format are equivelent to the
identically-named options to num_cmp() above. @answerList must contain one or
more correct answers. A list of answer evaluators is returned, one for each
answer provided in @answerList. All answer returned evaluators will use the
absolute tolerance and format specified.

=head2 Examples

	# The student answer must be a number in decimal or scientific notation
	# which is within .1 percent of 3.14159. This assumes
	# $numRelPercentTolDefault has been set to .1.
	ANS(strict_num_cmp(3.14159));

	# The student answer must be a number within .01 percent of $answer (e.g. #
	3.14159 if $answer is 3.14159 or $answer is "pi" or $answer is 4*atan(1)).
	ANS(strict_num_cmp($answer, .01));

	# The student answer can be a number or fraction, e.g. 2/3.
	ANS(frac_num_cmp($answer)); # or
	ANS(frac_num_cmp($answer, .01));

	# The student answer can be an arithmetic expression, e.g. (2+3)/7-2^.5 .
	ANS(arith_num_cmp($answer)); # or
	ANS(arith_num_cmp($answer, .01));

	# The student answer can contain elementary functions, e.g. sin(.3+pi/2)
	ANS(std_num_cmp($answer)); # or
	ANS(std_num_cmp( $answer, .01));

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
			        'format'    =>      $format,
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

=head1 Miscellaneous functions

=head2 [DEPRECATED] numerical_compare_with_units

	ANS(numerical_compare_with_units($correct_ans_with_units, %options))	

This function is deprecated. Use num_cmp with the units option instead:

	ANS(num_cmp($correct_ans, units=>$units));

=cut

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

=head2 [DEPRECATED] std_num_str_cmp()

	ANS(std_num_str_cmp($correctAnswer, $ra_legalStrings, $relTol, $format, $zeroLevel, $zeroLevelTol))

This function is deprecated. Use num_cmp() with the strings option instead:

	ANS(num_cmp($correctAnswer, strings=>$ra_legalStrings, ...));

=cut

sub std_num_str_cmp {
	my ( $correctAnswer, $ra_legalStrings, $relpercentTol, $format, $zeroLevel, $zeroLevelTol ) = @_;
	# warn ('This method is depreciated.  Use num_cmp instead.');
	return num_cmp ($correctAnswer, strings=>$ra_legalStrings, relTol=>$relpercentTol, format=>$format,
		zeroLevel=>$zeroLevel, zeroLevelTol=>$zeroLevelTol);
}

sub NUM_CMP {                              # low level numeric compare (now uses Parser)
	return ORIGINAL_NUM_CMP(@_)
	  if $main::useOldAnswerMacros;
	my %num_params = @_;

	#
	#  check for required parameters
	#
	my @keys = qw(correctAnswer tolerance tolType format mode zeroLevel zeroLevelTol debug);
	foreach my $key (@keys) {
	    warn( "$key must be defined in options when calling NUM_CMP" )
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
	  /^strict$/i and do {
	    $context = Parser::Context->getCopy($user_context,"LimitedNumeric");
	    last;
	  };
	  /^arith$/i  and do {
	    $context = Parser::Context->getCopy($user_context,"LegacyNumeric");
	    $context->functions->disable('All');
	    last;
	  };
	  /^frac$/i   and do {
	    $context = Parser::Context->getCopy($user_context,"LimitedNumeric-Fraction");
	    last;
	  };

	  # default
	  $context = Parser::Context->getCopy($user_context,"LegacyNumeric");
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
	    $context->strings->add(uc($string) => {%tex})
	      unless $context->strings->get(uc($string));
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
	# WARN_MESSAGE("Using old ORIGINAL_NUM_CMP function.");
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

=head1 SEE ALSO

L<PGanswermacros.pl>, L<MathObjects>.

=cut

1;
