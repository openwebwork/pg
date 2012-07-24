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

PGstringevaluators.pl - Macros that generate string answer evaluators.

=head1 SYNOPSIS

	ANS(str_cmp("increasing"));
	
	ANS(unordered_str_cmp("A C E"));

=head1 DESCRIPTION

String answer evaluators compare a student string to the correct string.

=head2 MathObjects and answer evaluators

The MathObjects system provides a String->cmp() method that produce answer
evaluators for string comparisons. It is recommended that you use the String
object's cmp() method directly if possible.

=cut

BEGIN { be_strict() }
sub _PGstringevaluators_init {}

=head1 String Filters

Different filters can be applied to allow various degrees of variation. Both the
student and correct answers are subject to the same filters, to ensure that
there are no unexpected matches or rejections.

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
	    'ignore_case'		=>	\&ignore_case,
	    'ignore_order'		=>	\&ignore_order,
	    'nullify'			=>	\&nullify,
	);

	#test for unknown filters
	foreach my $filter ( @filters_to_use ) {
		#check that filter is known
		die "Unknown string filter $filter (try checking the parameters to str_cmp() )"
								unless exists $known_filters{$filter};
		$rh_ans = $known_filters{$filter}($rh_ans);  # apply filter.
	}

	return $rh_ans->{student_ans};
}

=over

=item remove_whitespace

Removes all whitespace from the string. It applies the following substitution to
the string:

	$filteredAnswer =~ s/\s+//g;

=cut

sub remove_whitespace {
	my $rh_ans = shift;
	die "expected an answer hash" unless ref($rh_ans)=~/HASH/i;
	$rh_ans->{_filter_name} = 'remove_whitespace'; 
	$rh_ans->{student_ans} =~ s/\s+//g;		# remove all whitespace
	$rh_ans->{correct_ans} =~ s/\s+//g;		# remove all whitespace
	return $rh_ans;
}

=item compress_whitespace

Removes leading and trailing whitespace, and replaces all other blocks of
whitespace by a single space. Applies the following substitutions:

	$filteredAnswer =~ s/^\s*//;
	$filteredAnswer =~ s/\s*$//;
	$filteredAnswer =~ s/\s+/ /g;

=cut

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

=item trim_whitespace

Removes leading and trailing whitespace. Applies the following substitutions:

	$filteredAnswer =~ s/^\s*//;
	$filteredAnswer =~ s/\s*$//;

=cut

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

=item nullify

Returns the null string.

=cut

sub nullify {
	my $rh_ans = shift;
	die "expected an answer hash" unless ref($rh_ans)=~/HASH/i;
	$rh_ans->{_filter_name} = 'nullify';
	$rh_ans->{student_ans} = "";		# return null string for student answer
	$rh_ans->{correct_ans} = "";		# return null string for correct answer
	return $rh_ans;
}

=item ignore_case

Ignores the case of the string. More accurately, it converts the string to
uppercase (by convention). Applies the following function:

	$filteredAnswer = uc($filteredAnswer);

=cut

sub ignore_case {
	my $rh_ans = shift;
	die "expected an answer hash" unless ref($rh_ans)=~/HASH/i;
	$rh_ans->{_filter_name} = 'ignore_case';
	$rh_ans->{student_ans} =~ tr/a-z/A-Z/;
	$rh_ans->{correct_ans} =~ tr/a-z/A-Z/;
	return $rh_ans;
}

=item ignore_order

Ignores the order of the letters in the string. This is used for problems of the
form "Choose all that apply." Specifically, it removes all whitespace and
lexically sorts the letters in ascending alphabetical order. Applies the
following functions:

	$filteredAnswer = join("", lex_sort(split(/\s*/, $filteredAnswer)));

=cut

sub ignore_order {
	my $rh_ans = shift;
	die "expected an answer hash" unless ref($rh_ans)=~/HASH/i;
	$rh_ans->{_filter_name} = 'ignore_order';
	$rh_ans->{student_ans} = join( "", lex_sort( split( /\s*/, $rh_ans->{student_ans} ) ) );
	$rh_ans->{correct_ans} = join( "", lex_sort( split( /\s*/, $rh_ans->{correct_ans} ) ) );
	
	return $rh_ans;
}

=back

=head1 str_cmp

	ANS(str_cmp($answer_or_answer_array_ref, @filters));
	ANS(str_cmp($answer_or_answer_array_ref, %options));

Compares a string or a list of strings, using a named hash of options to set
parameters. This can make for more readable code than using the "mode"_str_cmp()
style, but some people find one or the other easier to remember.

$answer_or_answer_array_ref can be a scalar representing the correct answer or a
reference to an array of string scalars. If multiple answers are given, str_cmp
returns one answer evaluator for each answer.

num_cmp() differentiates %options from @filters by checking for the names of
supported options in the list. Currently "filter", "filters", and "debug" are
checked for. If these strings are found in the argument list, it is assumed that
%options is present rather than @filters.

%options can contain the following items:

=over

=item filters

A reference to an array of filter names, to be applied to both the correct
answer and the student's answer before doing string comparison. Supported
filters are listed above. filter is avaliable as a synonym for filters.

=item debug

If set to 1, extra debugging information will be output.

=back

If %options is not detected, the rest of the argument list is assumed to be a
list of filter names. Hence, the following two forms are equivalent:

	ANS(str_cmp($ans, 'remove_whitespace', 'ignore_order'));
	ANS(str_cmp($ans, filters=>['remove_whitespace', 'ignore_order']));

=head2 Examples

	# same as std_str_cmp() -- matches "Hello", "  hello", etc.
	str_cmp("Hello")

	# same as std_str_cmp_list()
	str_cmp(["Hello", "Goodbye"]);

	# matches "hello", " hello  ", etc.
	str_cmp(' hello ', 'trim_whitespace');

	# matches "ACB" and "A B C", but not "abc"
	str_cmp('ABC', filters=>'ignore_order');

	# matches "def" and "d e f" but not "fed"
	str_cmp('D E F', 'remove_whitespace', 'ignore_case');

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

=head1 "mode"_str_cmp functions

The functions of the the form "mode"_str_cmp() use different functions to
specify which filters to apply. They take no options except the correct string.
There are also versions which accept a list of strings.

=over

=item standard

	std_str_cmp($correctString)
	std_str_cmp_list(@correctStringList)

Filters: compress_whitespace, ignore_case

=item standard, case sensitive

	std_cs_str_cmp($correctString)
	std_cs_str_cmp_list(@correctStringList)

Filters: compress_whitespace

=item strict

	strict_str_cmp($correctString)
	strict_str_cmp_list(@correctStringList)

Filters: trim_whitespace

=item unordered

	unordered_str_cmp( $correctString )
	unordered_str_cmp_list( @correctStringList )

Filters: ignore_order, ignore_case

=item unordered, case sensitive

	unordered_cs_str_cmp( $correctString )
	unordered_cs_str_cmp_list( @correctStringList )

Filters: ignore_order

=item ordered

	ordered_str_cmp( $correctString )
	ordered_str_cmp_list( @correctStringList )

Filters: remove_whitespace, ignore_case

=item ordered, case sensitive

	ordered_cs_str_cmp( $correctString )
	ordered_cs_str_cmp_list( @correctStringList )

Filters: remove_whitespace

=back

=head2 Examples

	# Accepts "W. Mozart", "W. MOZarT", and so forth. Case insensitive. All
	# internal spaces treated as single spaces.
	ANS(std_str_cmp("W. Mozart"));

	# Rejects "mozart". Same as std_str_cmp() but case sensitive.
	ANS(std_cs_str_cmp("Mozart"));

	# Accepts only the exact string.
	ANS(strict_str_cmp("W. Mozart"));

	# Accepts "a c B", "CBA" and so forth. Unordered, case insensitive, spaces
	# ignored.
	ANS(unordered_str_cmp("ABC"));

	# Rejects "abc". Same as unordered_str_cmp() but case sensitive.
	ANS(unordered_cs_str_cmp("ABC"));

	# Accepts "a b C", "A B C" and so forth. Ordered, case insensitive, spaces
	# ignored.
	ANS(ordered_str_cmp("ABC"));

	# Rejects "abc", accepts "A BC" and so forth. Same as ordered_str_cmp() but
	# case sensitive.
	ANS(ordered_cs_str_cmp("ABC"));

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
	# Remove blank prefilter if the correct answer is blank
	$answer_evaluator->install_pre_filter('erase') if $answer_evaluator->ans_hash->{correct_ans} eq '';

	my %known_filters = (	
	    'remove_whitespace'		=>	\&remove_whitespace,
	    'compress_whitespace'	=>	\&compress_whitespace,
	    'trim_whitespace'		=>	\&trim_whitespace,
	    'ignore_case'		=>	\&ignore_case,
	    'ignore_order'		=>	\&ignore_order,
	    'nullify'			=>	\&nullify,
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
		my $rh_hash = shift; my $c = chr(128); ## something that won't be typed
		$rh_hash->{_filter_name} = "clean up preview strings";
		$rh_hash->{'preview_text_string'} = $rh_hash->{student_ans};
#		$rh_hash->{'preview_latex_string'} = "\\text{ ".$rh_hash->{student_ans}." }";
		$rh_hash->{'preview_latex_string'} = "\\verb".$c.$rh_hash->{student_ans}.$c;
		$rh_hash;		
	});
	return $answer_evaluator;
}

=head1 SEE ALSO

L<PGanswermacros.pl>, L<MathObjects>.

=cut

1;
