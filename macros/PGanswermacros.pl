################################################################################
# WeBWorK Online Homework Delivery System
# Copyright © 2000-2007 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader: pg/macros/PGanswermacros.pl,v 1.72 2010/02/01 01:33:05 apizer Exp $
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

# FIXME TODO:
# Document and maybe split out: filters, graders, utilities

=head1 NAME

PGanswermacros.pl - Macros for building answer evaluators.

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

=head1 DESCRIPTION

The macros in this file are factories which construct and return answer
evaluators for checking student answers. The macros take various arguments,
including the correct answer, and return an "answer evaluator", which is a
subroutine reference suitable for passing to the ANS* family of macro.

When called with the student's answer, the answer evaluator will compare this
answer to the correct answer that it keeps internally and returns an AnswerHash
representing the results of the comparison. Part of the answer hash is a score,
which is a number between 0 and 1 representing the correctness of the student's
answer. The fields of an AnswerHash are as follows:

	score                => $correctQ,
	correct_ans          => $originalCorrEqn,
	student_ans          => $modified_student_ans,
	original_student_ans => $original_student_answer,
	ans_message		     => $PGanswerMessage,
	type                 => 'typeString',
	preview_text_string  => $preview_text_string,
	preview_latex_string => $preview_latex_string, # optional

=over

=item C<$ans_hash{score}>

a number between 0 and 1 indicating whether the answer is correct. Fractions
allow the implementation of partial credit for incorrect answers.

=item C<$ans_hash{correct_ans}>

The correct answer, as supplied by the instructor and then formatted. This can
be viewed by the student after the answer date.

=item C<$ans_hash{student_ans}>

This is the student answer, after reformatting; for example the answer might be
forced to capital letters for comparison with the instructors answer. For a
numerical answer, it gives the evaluated answer. This is displayed in the
section reporting the results of checking the student answers.

=item C<$ans_hash{original_student_ans}>

This is the original student answer. This is displayed on the preview page and
may be used for sticky answers.

=item C<$ans_hash{ans_message}>

Any error message, or hint provided by the answer evaluator. This is also
displayed in the section reporting the results of checking the student answers.

=item C<$ans_hash{type}>

A string indicating the type of answer evaluator. This helps in preprocessing
the student answer for errors. Some examples: C<'number_with_units'>,
C<'function'>, C<'frac_number'>, C<'arith_number'>.

=item C<$ans_hash{preview_text_string}>

This typically shows how the student answer was parsed. It is displayed on the
preview page. For a student answer of 2sin(3x) this would be 2*sin(3*x). For
string answers it is typically the same as $ans_hash{student_ans}.

=item C<$ans_hash{preview_latex_string}>

(Optional.) This is latex version of the student answer which is used to
show a typeset view on the answer on the preview page. For a student answer of
2/3, this would be \frac{2}{3}.

=back

=cut

# ^uses be_strict
BEGIN { be_strict() }

# Until we get the PG cacheing business sorted out, we need to use
# PG_restricted_eval to get the correct values for some(?) PG environment
# variables. We do this once here and place the values in lexicals for later
# access.

# ^variable my $BR
my $BR;
# ^variable my $functLLimitDefault
my $functLLimitDefault;
# ^variable my $functULimitDefault
my $functULimitDefault;
# ^variable my $functVarDefault
my $functVarDefault;
# ^variable my $useBaseTenLog
my $useBaseTenLog;
# ^variable my $reducedScoringPeriod
my $reducedScoringPeriod;
# ^variable my $reducedScoringValue
my $reducedScoringValue;
# ^variable my $enable_reduced_scoring
my $enable_reduced_scoring;
# ^variable my $dueDate
my $dueDate;

# ^function _PGanswermacros_init
# ^uses loadMacros
# ^uses PG_restricted_eval
# ^uses $BR
# ^uses $envir{functLLimitDefault}
# ^uses $envir{functULimitDefault}
# ^uses $envir{functVarDefault}
# ^uses $envir{useBaseTenLog}
# ^uses $envir{reducedScoringPeriod}
# ^uses $envir{reducedScoringValue}
# ^uses $envir{enable_reduced_scoring}
# ^uses $envir{dueDate}

sub _PGanswermacros_init {
	loadMacros('PGnumericevaluators.pl');   # even if these files are already loaded they need to be initialized.
	loadMacros('PGfunctionevaluators.pl');
	loadMacros('PGstringevaluators.pl');
	loadMacros('PGmiscevaluators.pl');
	
	$BR                 = PG_restricted_eval(q/$BR/);
	$functLLimitDefault = PG_restricted_eval(q/$envir{functLLimitDefault}/);
	$functULimitDefault = PG_restricted_eval(q/$envir{functULimitDefault}/);
	$functVarDefault    = PG_restricted_eval(q/$envir{functVarDefault}/);
	$useBaseTenLog      = PG_restricted_eval(q/$envir{useBaseTenLog}/);
	$reducedScoringPeriod= PG_restricted_eval(q/$envir{reducedScoringPeriod}/);
	$reducedScoringValue= PG_restricted_eval(q/$envir{reducedScoringValue}/);
	$enable_reduced_scoring= PG_restricted_eval(q/$envir{enable_reduced_scoring}/);
	$dueDate	    = PG_restricted_eval(q/$envir{dueDate}/);
}

=head1 MACROS

=head2 Answer evaluator macros

The answer macros have been split up into several separate files, one for each type:

L<PGnumericevaluators.pl> - contains answer evaluators for evaluating numeric
values, including num_cmp() and related.

L<PGfunctionevaluators.pl> - contains answer evaluators for evaluating
functions, including fun_cmp() and related.

L<PGstringevaluators.pl> - contains answer evaluators for evaluating strings,
including str_cmp() and related.

L<PGtextevaluators.pl> - contains answer evaluators that handle free response
questions and questionnaires.

L<PGmiscevaluators.pl> - contains answer evaluators that don't seem to fit into
other categories.

=cut

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

# ^function get_var_array
# ^uses $functVarDefault
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

# ^function get_limits_array
# ^uses $functLLimitDefault
# ^uses $functULimitDefault
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
# ^function function_invalid_params
sub function_invalid_params {
	my $correctEqn = shift @_;
	my $error_response = sub {
		my $PGanswerMessage	= "Tell your professor that there is an error with the parameters " .
						"to the function answer evaluator";
		return ( 0, $correctEqn, "", $PGanswerMessage );
	};
	return $error_response;
}

# ^function clean_up_error_msg
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
# ^function prfmt
# ^uses is_a_number
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

# ^function compare_numbers
# ^uses PG_answer_eval
# ^uses clean_up_error_msg
# ^uses prfmt
# ^uses is_a_number
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

# ^function std_num_filter
# ^uses math_constants
# ^uses PG_answer_eval
# ^uses clean_up_error_msg
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

=head4 std_num_array_filter

	std_num_array_filter($rh_ans, %options)
	returns $rh_ans

Assumes the {student_ans} field is a numerical  array, and applies BOTH check_syntax and std_num_filter
to each element of the array.  Does it's best to generate sensible error messages for syntax errors.
A typical error message displayed in {studnet_ans} might be ( 56, error message, -4).

=cut

# ^function std_num_array_filter
# ^uses set_default_options
# ^uses AnswerHash::new
# ^uses check_syntax
# ^uses std_num_filter
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

# ^function function_from_string2
# ^uses assign_option_aliases
# ^uses set_default_options
# ^uses math_constants
# ^uses PG_restricted_eval
# ^uses PG_answer_eval
# ^uses clean_up_error_msg
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

# ^function is_zero_array
# ^uses is_a_number
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

# ^function best_approx_parameters
# ^uses set_default_options
# ^uses pretty_print
# ^uses Matrix::new
# ^uses is_a_number
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
    my $matrix = Matrix->new($rows,$dim_of_param_space);
    my $rhs_vec =  Matrix->new($rows, 1);
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

# ^function calculate_difference_vector
# ^uses assign_option_aliases
# ^uses set_default_options
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
#  DPVC -- adjust so that a check for tolerance will
#          do a zeroLevelTol check
## $diff *= $options{tolerance}/$options{zeroLevelTol} unless abs($instructorVal) > $options{zeroLevel};
# /DPVC
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

# ^function fix_answers_for_display
# ^uses evaluatesToNumber
# ^uses AnswerHash::new
# ^uses check_syntax
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

# ^function evaluatesToNumber
# ^uses is_a_numeric_expression
# ^uses PG_answer_eval
# ^uses prfmt
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

# ^function is_a_numeric_expression
# ^uses PG_answer_eval
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

# ^function is_a_number
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

# ^function is_a_fraction
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

# ^function phase_pi
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

# ^function is_an_arithmetic_expression
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

# ^function math_constants
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

# ^function is_array
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

# ^function check_syntax
# ^uses assign_option_aliases
# ^uses set_default_options
# ^uses AlgParserWithImplicitExpand::new
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

# ^function check_strings
# ^uses str_filters
# ^uses str_cmp
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

# ^function check_units
# ^uses str_filters
# ^uses Units::evaluate_units
# ^uses clean_up_error_msg
# ^uses prfmt
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




=head4 std_problem_grader

This is an all-or-nothing grader.  A student must get all parts of the problem write
before receiving credit.  You should make sure to use this grader on multiple choice
and true-false questions, otherwise students will be able to deduce how many
answers are correct by the grade reported by webwork.


	install_problem_grader(~~&std_problem_grader);

=cut

# ^function std_problem_grader
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
	
	$problem_state{num_of_correct_ans}++ if	$allAnswersCorrectQ	== 1;
	$problem_state{num_of_incorrect_ans}++ if $allAnswersCorrectQ == 0;
	$problem_state{recorded_score} = 0 unless defined $problem_state{recorded_score};
	# Determine if we are in the reduced scoring period and act accordingly

	my $reducedScoringPeriodSec = $reducedScoringPeriod*60;   # $reducedScoringPeriod is in minutes
	if (!$enable_reduced_scoring or time() < ($dueDate - $reducedScoringPeriodSec)) {	# the reduced scoring period is disabled or it is before the reduced scoring period
		# increase recorded score if the current score is greater.
		$problem_state{recorded_score} = $problem_result{score}	if $problem_result{score} > $problem_state{recorded_score};
		# the sub_recored_score holds the recored_score before entering the reduced scoring period
		$problem_state{sub_recorded_score} = $problem_state{recorded_score};
	}
	elsif (time() < $dueDate) {	# we are in the reduced scoring period. 
 		# student gets credit for all work done before the reduced scoring period plus a portion of work done during period
		my $newScore = 0;
		$newScore =   $problem_state{sub_recorded_score} + $reducedScoringValue*($problem_result{score} - $problem_state{sub_recorded_score})  if ($problem_result{score} > $problem_state{sub_recorded_score});
		$problem_state{recorded_score} = $newScore if $newScore > $problem_state{recorded_score};
		my $reducedScoringPerCent = int(100*$reducedScoringValue+.5);
		$problem_result{msg} = $problem_result{msg}."<br />You are in the Reduced Credit Period: All additional work done counts $reducedScoringPerCent\% of the original."; 		
	}

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



# ^function std_problem_grader2
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
	# FIXME:  syntax errors are never checked for so this grader does not perform as advertised

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
	$problem_state{recorded_score} = 0 unless defined $problem_state{recorded_score};

	# Determine if we are in the reduced scoring period and act accordingly

	my $reducedScoringPeriodSec = $reducedScoringPeriod*60;   # $reducedScoringPeriod is in minutes
	if (!$enable_reduced_scoring or time() < ($dueDate - $reducedScoringPeriodSec)) {	# the reduced scoring period is disabled or it is before the reduced scoring period
		# increase recorded score if the current score is greater.
		$problem_state{recorded_score} = $problem_result{score}	if $problem_result{score} > $problem_state{recorded_score};
		# the sub_recored_score holds the recored_score before entering the reduced scoring period
		$problem_state{sub_recorded_score} = $problem_state{recorded_score};
	}
	elsif (time() < $dueDate) {	# we are in the reduced scoring period.
 		# student gets credit for all work done before the reduced scoring period plus a portion of work done during period
		my $newScore = 0;
		$newScore =   $problem_state{sub_recorded_score} + $reducedScoringValue*($problem_result{score} - $problem_state{sub_recorded_score})  if ($problem_result{score} > $problem_state{sub_recorded_score});
		$problem_state{recorded_score} = $newScore if $newScore > $problem_state{recorded_score};
		my $reducedScoringPerCent = int(100*$reducedScoringValue+.5);
		$problem_result{msg} = $problem_result{msg}."<br />You are in the Reduced Credit Period: All additional work done counts $reducedScoringPerCent\% of the original."; 		
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

# ^function avg_problem_grader
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
	$problem_state{recorded_score} = 0 unless defined $problem_state{recorded_score};

	$problem_state{num_of_correct_ans}++ if	$total == $count;
	$problem_state{num_of_incorrect_ans}++ if $total < $count;

	# Determine if we are in the reduced scoring period and if the reduced scoring period is enabled and act accordingly
#warn("enable_reduced_scoring is $enable_reduced_scoring");
# warn("dueDate is $dueDate");
	my $reducedScoringPeriodSec = $reducedScoringPeriod*60;   # $reducedScoringPeriod is in minutes
	if (!$enable_reduced_scoring or time() < ($dueDate - $reducedScoringPeriodSec)) {	# the reduced scoring period is disabled or it is before the reduced scoring period
		# increase recorded score if the current score is greater.
		$problem_state{recorded_score} = $problem_result{score}	if $problem_result{score} > $problem_state{recorded_score};
		# the sub_recored_score holds the recored_score before entering the reduced scoring period
		$problem_state{sub_recorded_score} = $problem_state{recorded_score};
	}
elsif (time() < $dueDate) {	# we are in the reduced scoring period.
 		# student gets credit for all work done before the reduced scoring period plus a portion of work done during period
		my $newScore = 0;
		$newScore =   $problem_state{sub_recorded_score} + $reducedScoringValue*($problem_result{score} - $problem_state{sub_recorded_score})  if ($problem_result{score} > $problem_state{sub_recorded_score});
		$problem_state{recorded_score} = $newScore if $newScore > $problem_state{recorded_score};
		my $reducedScoringPerCent = int(100*$reducedScoringValue+.5);
		$problem_result{msg} = $problem_result{msg}."<br />You are in the Reduced Credit Period: All additional work done counts $reducedScoringPerCent\% of the original."; 		
	}
	
	$problem_state{state_summary_msg} = '';  # an HTML formatted message printed at the bottom of the problem page

	warn "Error	in grading this	problem	the	total $total is	larger than	$count"	if $total >	$count;
	(\%problem_result, \%problem_state);
}

=head2 Utility subroutines

=head4 pretty_print

	Usage: warn pretty_print( $rh_hash_input)
		   TEXT(pretty_print($ans_hash));
		   TEXT(~~%envir);

This can be very useful for printing out messages about objects while debugging

=cut

# ^function pretty_print
# ^uses lex_sort
# ^uses pretty_print
# sub pretty_print {
#     my $r_input = shift;
#     my $out = '';
#     if ( not ref($r_input) ) {
#     	$out = $r_input if defined $r_input;    # not a reference
#     	$out =~ s/</&lt;/g  ;  # protect for HTML output
#     } elsif ("$r_input" =~/hash/i) {  # this will pick up objects whose '$self' is hash and so works better than ref($r_iput).
# 	    local($^W) = 0;
# 	    
# 		$out .= "$r_input " ."<TABLE border = \"2\" cellpadding = \"3\" BGCOLOR = \"#FFFFFF\">";
# 		
# 		
# 		foreach my $key (lex_sort( keys %$r_input )) {
# 			$out .= "<tr><TD> $key</TD><TD>=&gt;</td><td>&nbsp;".pretty_print($r_input->{$key}) . "</td></tr>";
# 		}
# 		
# 		
# 		
# 		$out .="</table>";
# 	} elsif (ref($r_input) eq 'ARRAY' ) {
# 		my @array = @$r_input;
# 		$out .= "( " ;
# 		while (@array) {
# 			$out .= pretty_print(shift @array) . " , ";
# 		}
# 		$out .= " )";
# 	} elsif (ref($r_input) eq 'CODE') {
# 		$out = "$r_input";
# 	} else {
# 		$out = $r_input;
# 		$out =~ s/</&lt;/g ;  # protect for HTML output
# 	}
# 		$out;
# }

1;
