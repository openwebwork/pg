loadMacros('Parser.pl');

# This is extraAnswerEvaluators.pl

# Most of the work is done in special namespaces
# At the end, we provide one global function, the interval answer evaluator

# To do:
#    Convert these to AnswerEvaluator objects
#    Better error checking/messages
#    Simplify checks so we don't make so much use of num_cmp and cplx_cmp.
#      When they change, these functions may have to change.

=head1 NAME

        extraAnswerEvaluators.pl -- located in the courseScripts directory

=head1 SYNPOSIS

        Answer Evaluators for intervals, lists of numbers, lists of points,
        and equations.

	interval_cmp() -- checks answers which are unions of intervals.
	                  It can also be used for checking an ordered pair or
	                  list of ordered pairs.

	number_list_cmp() -- checks a comma separated list of numbers.  By use of
	                     optional arguments, you can request that order be
	                     important, that complex numbers be allowed, and
	                     specify extra arguments to be sent to num_cmp (or
											 cplx_cmp) for checking individual entries.

	equation_cmp() -- provides a limited facility for checking equations.
	                  It makes no pretense of checking to see if the real locus
	                  of the student's equation matches the real locus of the
                    instructor's equation.  The student's equation must be
                    of the same general type as the instructors to get credit.


=cut

=head1 DESCRIPTION

This file adds subroutines which create "answer evaluators" for checking student
answers of various "exotic" types.

=cut


{
 package Intervals;

 # We accept any of the following as infinity (case insensitive)
 @infinitywords = ("i", "inf", "infty", "infinity");
 $infinityre = join '|', @infinitywords;
 $infinityre = "^([-+m]?)($infinityre)\$";

 sub new {
	 my $class = shift;
	 my $base_string = shift;
	 my $self = {};
	 $self->{'original'} = $base_string;
	 return bless $self, $class;
 }

 # Not object oriented.  It just returns the structure
 sub new_interval {					# must call with 4 arguments
	 my($l,$r,$lec, $rec) = @_;
	 return [[$l,$r],[$lec,$rec]];
 }

 # error routine copied from AlgParser
 sub error {
	 my($self, @args) = @_;
	 # we cheat to use error from algparser
	 my($ap) = new AlgParser();
	 $ap->inittokenizer($self->{'original'});
	 $ap->error(@args);
	 $self->{htmlerror} =  $ap->{htmlerror};
	 $self->{error_msg} = $ap->{error_msg};
 }

 # Determine if num_cmp detected a parsing/syntax type error

 sub has_errors {
	 my($ah) = shift;

	 if($ah->{'student_ans'} =~ /error/) {
		 return 1;
	 }
	 my($am) = $ah->{'ans_message'};
	 if($am =~ /error/) {
		 return 2;
	 }
	 if($am =~ /must enter/) {
		 return 3;
	 }
	 if($am =~ /does not evaluate/) {
		 return 4;
	 }
	 return 0;
 }


 ## Parse a string into a bunch of intervals
 ## We do it by hand to avoid problems of nested parentheses
 ## This also builds a normalized version of the string, one with values,
 ## and a latex version.
 ##
 ## Return value simply says whether or not this was successful
 sub parse_intervals {
	 my($self) = shift;
	 my(%opts) = @_;
	 my($str) = $self->{'original'};
	 my(@ans_list) = ();
	 delete($opts{'sloppy'});
	 delete($opts{'ordered'});
	 my($unions) = 1;
	 if (defined($opts{'unions'}) and ($opts{'unions'} eq 'no')) {
		 $unions = 0;
	 }
	 # Sometimes we use this for lists of points
	 delete($opts{'unions'});
	 my($b1str,$b2str) = (', ', ', ');
	 if($unions) {
		 ($b1str,$b2str) = (' U ', ' \cup ');
	 }

	 my($tmp_ae) = main::num_cmp(1, %opts);
	 $self->{'normalized'} = '';
	 $self->{'value'} = '';
	 $self->{'latex'} = '';
	 $self->{'htmlerror'} = '';
	 $self->{'error_msg'} = '';
	 my($pmi) = 0;
	 my(@cur) = ("","");
	 my($lb,$rb) = (0,0);
	 my($level,$spot,$hold,$char,$lr) = (0,0,0,"a",0);

	 while ($spot < length($str)) {
		 $char = substr($str,$spot,1);
		 if ($char=~ /[\[(,)\]]/) { # Its a special character
			 if ($char eq ",") {
				 if ($level == 1) {			# Level 1 comma
					 if ($lr == 1) {
						 $self->error("Not a valid interval; too many commas.",[$spot]);
						 return 0;
					 } else {
						 $lr=1;
						 $cur[0] = substr($str,$hold, $spot-$hold);
						 if($pmi = pminf($cur[0])) {
							 if($pmi<0) {
								 $self->{'value'} .= '-';
								 $self->{'normalized'} .= '-';
								 $self->{'latex'} .= '-';
							 }
							 $self->{'value'} .= 'Infinity, ';
							 $self->{'normalized'} .= 'Infinity, ';
							 $self->{'latex'} .= '\infty, ';
						 } else {
							 my($tmp_ah) = $tmp_ae->evaluate($cur[0]);
							 if(has_errors($tmp_ah)) {
								 $self->error("I could not parse your input correctly",[$hold, $spot]);
								 return 0;
							 }
							 $self->{'normalized'} .= $tmp_ah->{'preview_text_string'}.", ";
							 $self->{'value'} .= $tmp_ah->{'student_ans'}.", ";
							 $self->{'latex'} .= $tmp_ah->{'preview_latex_string'}.", ";
						 }
						 $hold = $spot+1;
					 }
				 }
			 }												# end of comma
			 elsif ($char eq "[" or $char eq "(") { #opening
				 if ($level==0) {
					 $lr = 0;
					 if(scalar(@ans_list)) { # this is not the first interval
						 $self->{'normalized'} .= $b1str;
						 $self->{'value'} .= $b1str;
						 $self->{'latex'} .= $b2str;
					 }
					 $self->{'normalized'} .= "$char";
					 $self->{'value'} .= "$char";
					 $self->{'latex'} .= "$char";
					 $hold=$spot+1;
					 if ($char eq "[") {
						 $lb = 1;
					 } else {
						 $lb = 0;
					 }
				 }
				 $level++;
			 }												# end of open paren
			 else {										# must be closed paren
				 if ($level == 0) {
					 $self->error("Not a valid interval; extra $char when I expected a new interval to open.",[$spot]);
					 return 0;
				 } elsif ($level == 1) {
					 if ($lr != 1) {
						 $self->error("Not a valid interval; closing an interval without a right component.", [$spot]);
						 return 0;
					 } else {
						 $cur[1] = substr($str, $hold, $spot-$hold);
						 if($pmi = pminf($cur[1])) {
							 if($pmi<0) {
								 $self->{'value'} .= '-';
								 $self->{'normalized'} .= '-';
								 $self->{'latex'} .= '-';
							 }
							 $self->{'value'} .= "Infinity$char";
							 $self->{'normalized'} .= "Infinity$char";
							 $self->{'latex'} .= '\infty'."$char";
							 } else {
							 my($tmp_ah) = $tmp_ae->evaluate($cur[1]);
							 if(has_errors($tmp_ah)) {
								 $self->error("I could not parse your input correctly",[$hold, $spot]);
								 return 0;
							 }
							 $self->{'normalized'} .= $tmp_ah->{'preview_text_string'}."$char";
							 $self->{'value'} .= $tmp_ah->{'student_ans'}."$char";
							 $self->{'latex'} .= $tmp_ah->{'preview_latex_string'}."$char";
						 }
						 if ($char eq "]") {
							 $rb = 1;
						 } else {
							 $rb = 0;
						 }
						 push @ans_list, new_interval($cur[0], $cur[1], $lb, $rb);
					 }
				 }
				 $level--;
			 }
		 }
		 $spot++;
	 }

	 if($level>0) {
		 $self->error("Your expression ended in the middle of an interval.",
									[$hold, $spot]);
		 return 0;
	 }
	 $self->{'parsed'} = \@ans_list;
	 return 1;
 }

 # Is the argument an exceptable +/- infinity
 # Its sort of multiplies the input by 0 using 0 * oo = 1, 0 * (-oo) = -1.
 sub pminf {
	 my($val) = shift;
	 $val = "\L$val";							# lowercase
	 $val =~ s/ //g;							# remove space
	 if ($val =~ /$infinityre/) {
		 if (($1 eq '-') or ($1 eq 'm')) {
			 return -1;
		 } else {
			 return 1;
		 }
	 }
	 return 0;
 }

 # inputs are now of type Intervals, and then options

 sub cmp_intervals {
	 my($in1) = shift;
	 my($in2) = shift;
	 my(%opts) = @_;
	 my($strict_ordering) = 0;
	 if (defined($opts{'ordering'}) && $opts{'ordering'} eq 'strict') {
		 $strict_ordering = 1;
	 }
	 delete($opts{'ordering'});

	 my($issloppy) = 0;
	 if (defined($opts{'sloppy'}) && $opts{'sloppy'} eq 'yes') {
		 $issloppy = 1;
	 }
	 delete($opts{'sloppy'});

	 delete($opts{'unions'});


	 my(@i1) = @{$in1->{'parsed'}};
	 my(@i2) = @{$in2->{'parsed'}};

	 my($j,$pm10,$pm11,$pm20,$pm21);
	 # Same number of intervals?
	 if (scalar(@i1) != scalar(@i2)) {
		 return 0;
	 }
	 for ($j=0; $j<scalar(@i1);$j++) {
		 my($lbound) = 0;
		 my($ubound) = scalar(@i1)-1;
		 my($lookformatch) = 1;
		 if ($strict_ordering) {
			 $lbound = $j;
			 $ubound = $j;
		 }
		 for ($k=$lbound; $lookformatch && $k<=$ubound; $k++) {
			 # Do they all have correct inclusions ()[]?
			 if (! $issloppy and ($i1[$j]->[1][0] != $i2[$k]->[1][0] or
					 $i1[$j]->[1][1] != $i2[$k]->[1][1])) {
				 next;
			 }
			 $pm10 = pminf($i1[$j]->[0][0]);
			 $pm11 = pminf($i1[$j]->[0][1]);
			 $pm20 = pminf($i2[$k]->[0][0]);
			 $pm21 = pminf($i2[$k]->[0][1]);
			 if ($pm10 != $pm20) {
				 next;
			 }
			 if ($pm11 != $pm21) {
				 next;
			 }
			 # Now we deal with only numbers, no infinities
			 if ($pm10 == 0) {
#				 $opts{'correctAnswer'} = $i1[$j]->[0][0];
				 my $ae = main::num_cmp($i1[$j]->[0][0], %opts);
				 my $result = $ae->evaluate($i2[$k]->[0][0]);
				 if ($result->{score} == 0) {
					 next;
				 }
			 }
			 if ($pm11 == 0) {
#				 $opts{'correctAnswer'} = $i1[$j]->[0][1];
				 my $ae = main::num_cmp($i1[$j]->[0][1], %opts);
				 my $result = $ae->evaluate($i2[$k]->[0][1]);
				 if ($result->{score} == 0) {
					 next;
				 }
			 }
			 $lookformatch=0;
		 }
		 if ($lookformatch) {				# still looking ...
			 return 0;
		 }
	 }
	 return 1;
 }

 sub show_int {
	 my($intt) = shift;
	 my($intstring) = "";
	 return "|$intt->[0]->[0]%%$intt->[0]->[1]|";
 }



} # End of package Intervals

{
	package Interval_evaluator;

	sub nicify_string {
		my $str = shift;

		$str = uc($str);
		$str =~ s/\s//g; # remove white space
		$str;
		}

	#####  The answer evaluator

	sub interval_cmp {

		my $right_ans = shift;
		my %opts = @_;

		$opts{'mode'} = 'std' unless defined($opts{'mode'});
		$opts{'tolType'} = 'relative' unless defined($opts{'tolType'});

		my $ans_eval = sub {
			my $student = shift;

			my $ans_hash = new AnswerHash(
				'score'=>0,
				'correct_ans'=>$right_ans,
				'student_ans'=>$student,
				'original_student_ans' => $student,
				# 'type' => undef,
				'ans_message'=>'',
				'preview_text_string'=>'',
				'preview_latex_string'=>'',
			);
			# Handle string matches separately
			my($studentisstring, $correctisstring, $tststr) = (0,0,"");
			my($nicestud, $nicecorrect) = (nicify_string($student),
																		 nicify_string($right_ans));
			if(defined($opts{'strings'})) {
				for $tststr (@{$opts{'strings'}}) {
					$tststr = nicify_string($tststr);
					if(($tststr eq $nicestud)) {$studentisstring=1;}
					if(($tststr eq $nicecorrect)) {$correctisstring=1;}
				}
				if($studentisstring) {
					$ans_hash->{'preview_text_string'} = $student;
					$ans_hash->{'preview_latex_string'} = $student;
				}
			}
			my($student_int, $correct_int);
			if(!$studentisstring) {
				$student_int = new Intervals($student);
				if(! $student_int->parse_intervals(%opts)) {
					# Error in student input
					$ans_hash->{'student_ans'} = "error:	$student_int->{htmlerror}";
					$ans_hash->{'ans_message'} = "$student_int->{error_msg}";
					return $ans_hash;
				}

				$ans_hash->{'student_ans'} = $student_int->{'value'};
				$ans_hash->{'preview_text_string'} = $student_int->{'normalized'};
				$ans_hash->{'preview_latex_string'} = $student_int->{'latex'};
			}

			if(!$correctisstring) {
				$correct_int = new Intervals($right_ans);
				if(! $correct_int->parse_intervals(%opts)) {
					# Cannot parse instuctor's answer!
					$ans_hash->{'ans_message'} = "Tell your professor that there is an error in this problem.";
					return $ans_hash;
				}
			}
			if($correctisstring || $studentisstring) {
				if($nicestud eq $nicecorrect) {
					$ans_hash -> setKeys('score' => 1);
				}
			} else {
				if (Intervals::cmp_intervals($correct_int, $student_int, %opts)) {
					$ans_hash -> setKeys('score' => 1);
				}
			}

			return $ans_hash;
		};

		return $ans_eval;
	}

}

{
	package Equation_eval;

	sub split_eqn {
		my $instring = shift;

		 split /=/, $instring;
	}


	sub equation_cmp {
		my $right_ans = shift;
		my %opts = @_;
		my $vars = ['x','y'];


		$vars = $opts{'vars'} if defined($opts{'vars'});

		my $ans_eval = sub {
			my $student = shift;

			my $ans_hash = new AnswerHash(
																		'score'=>0,
																		'correct_ans'=>$right_ans,
																		'student_ans'=>$student,
																		'original_student_ans' => $student,
																		# 'type' => undef,
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
			$res= $ae->evaluate("$studsplit[0]-($studsplit[1])");
			$ans_hash-> setKeys('score' => $res->{'score'});

			return $ans_hash;
		};

		return $ans_eval;
	}
}

=head3 interval_cmp ()

Compares an interval or union of intervals.  Typical invocations are

  interval_cmp("(2, 3] U(7, 11)")

The U is used for union symbol.  In fact, any garbage (or nothing at all)
can go between intervals.  It makes sure open/closed parts of intervals
are correct, unless you don't like that.  To have it ignore the difference
between open and closed endpoints, use

  interval_cmp("(2, 3] U(7, 11)", sloppy=>'yes')

interval_cmp uses num_cmp on the endpoints.  You can pass optional
arguments for num_cmp, so to change the tolerance, you can use

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

=cut

sub interval_cmp {
	Interval_evaluator::interval_cmp(@_);
}

=head3 number_list_cmp ()

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

=cut

sub number_list_cmp {
	my $list = shift;

	my %num_params = @_;

        my $mode          = $num_params{mode} || 'std';
        my %options       = (debug => $num_params{debug});

        #
        #  Get an apppropriate context based on the mode
        #
	my $oldContext = Context();
        my $context;
	#my $Context = sub {Parser::Context->current($user_context,@_)};
        for ($mode) {
          /^strict$/i    and do {
            $context = Context("LimitedNumeric")->copy;
	    $context->operators->set(',' => {class=> 'Parser::BOP::comma'});
            last;
          };
          /^arith$/i     and do {
            $context = Context("LegacyNumeric")->copy;
            $context->functions->disable('All');
            last;
          };
          /^frac$/i      and do {
            $context = Context("LimitedNumeric-Fraction")->copy;
	    $context->operators->set(',' => {class=> 'Parser::BOP::comma'});
            last;
          };
	if(defined($num_params{'complex'}) &&
			($num_params{'complex'} =~ /(yes|ok)/i)) {
		$context = Context("Complex")->copy;
		last;
	}

          # default
          $context = Context("LegacyNumeric")->copy;
        }
        $context->{format}{number} = $num_params{'format'} || $main::numFormatDefault;
        $context->strings->clear;
	if (defined($num_params{strings}) && $num_params{strings}) {
          foreach my $string (@{$num_params{strings}}) {
            my %tex = ($string =~ m/(-?)inf(inity)?/i)? (TeX => "$1\\infty"): ();
            $context->strings->add(uc($string) => {%tex});
          }
        }

	$num_params{tolType} = $num_params{tolType} || 'relative';
	$num_params{tolerance} = $num_params{tolerance} || $num_params{tol} || $num_params{reltol} || $num_params{relTol} || $num_params{abstol} || 1;
	$num_params{zeroLevel} = $num_params{zeroLevel} || $num_params{zeroLevelTol} || $main::numZeroLevelTolDefault;
	if ($num_params{tolType} eq 'absolute' or defined($num_params{tol})
		or defined($num_params{abstol})) {
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
	$options{ordered} = 1 if(defined($num_params{ordered}));

	Context($context);
	$ans_eval = List($list)->cmp(%options);
	Context($oldContext);
	return($ans_eval);
}


=head3 equation_cmp ()

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

sub equation_cmp {
	Equation_eval::equation_cmp(@_);
}

