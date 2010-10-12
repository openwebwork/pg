

BEGIN {
	be_strict();
}


sub CAPA_ans {
	my $ans = shift;
	my %options = @_;
	my $answer_evaluator = 0;

    #TEXT("answerCounter =". ++$problemCounter,"$BR"); # checking whether values are reinitialized

    # explicitlty delete options which are meaningless to WeBWorK
    if (defined($options{'sig'})) { delete($options{'sig'}); }
    if (defined($options{'wgt'})) { delete($options{'wgt'}); }
    if (defined($options{'tries'})) { delete($options{'tries'}); }

#	$options{'allow_unknown_options'} = 1; 	## if uncommented, this is a fast and possibly dangerous
											## way to prevent warning message about unknown options


	if (defined($options{'reltol'}) or defined($options{'tol'}) or defined($options{'unit'})  ) {

 		if (defined( $options{'unit'} ) ) {
			#$ans = "$ans  $options{'unit'}";
			$answer_evaluator = num_cmp($ans, 'format'	=>	$options{format},
			                                   reltol	=>	( defined($options{reltol}) ) ? $options{reltol} :undef,
			                                   tol		=>	( defined($options{tol})    ) ? $options{tol} : undef ,
			                                   unit		=>	$options{unit},
			);
		} else { # numerical compare:
			if (defined($options{'reltol'})  ) {  #relative tolerance is given with a percent sign
			        my $reltol =  $options{ 'reltol' };
			        my $format = $options{'format'} if defined($options{'format'});
					$answer_evaluator = num_cmp($ans,reltol=>$reltol,'format' => $format);
			} elsif (defined($options{'tol'})  ) {
				    my $format = $options{'format'} if defined($options{'format'});
					$answer_evaluator = num_cmp($ans,tol => $options{'tol'}, 'format' => $format);
		    } else {
		    	   my $tol = $ans*$main::numRelPercentTolDefault;
		    	   my $format = $options{'format'} if defined($options{'format'});
		    	   $answer_evaluator = num_cmp($ans,reltol=> $tol,'format'=> $format);
		    }
		}
	} else {
	   # string comparisons
	   if ( defined($options{'str'})  and   $options{'str'} =~/CS/i )  {
	   		  	$answer_evaluator =str_cmp($ans,filters=>['compress_whitespace']);
	   } elsif  ( defined($options{'str'}) and $options{'str'} =~/MC/i )  {
	            $answer_evaluator = str_cmp($ans,filters=>[qw( compress_whitespace ignore_case ignore_order )]);
	   } else {
	            $answer_evaluator = str_cmp($ans,filters=>[qw( compress_whitespace ignore_case )]);
	   }
	}

   $answer_evaluator;
}

sub CAPA_import {
	my $filePath = shift;
	my %save_envir = %main::envir;
	my $r_string =  read_whole_problem_file($filePath);

	$main::envir{'probFileName'} = $filePath;
	$main::envir{'fileName'} = $filePath;
	includePGtext($r_string); # the 0 prevents  a new Safe compartment from being used
	%main::envir = %save_envir;
}



sub CAPA_map {
	my $seed = shift;
    my $array_var_ref = shift;
    my $PGrand = new PGrandom($seed);
    local $main::array_values_ref = shift;   # this must be local since it must be passed to PG_restricted_eval
    my $size = @$main::array_values_ref;  # get number of values
	my @array = 0..($size-1);
	my @slice = ();
	while ( @slice < $size) {
		push(@slice, splice(@array , $PGrand->random(0,$#array) , 1) );
	}
    my $string = "";
    my $var;
    my $i = 0;
     foreach $var (@$array_var_ref) {
		$string .= "\$$var = \$\$main::array_values_ref[ $slice[$i++]]; ";
 	 }

     # it is important that PG-restriced eval can accesss the $array_values_ref
     my($val, $PG_eval_errors,$PG_full_error_report) =PG_restricted_eval($string);
     my $out = '';
     $string =~ s/\$/\\\$/g;  # protect variables for error message
     $out = "Error in MAP subroutine: $PG_eval_errors <BR>\n" . $string ." <BR>\n" if $PG_eval_errors;
     $out;
}

sub compare_units {


}

sub CAPA_hint {
    my $hint = shift;
	TEXT(hint(qq{ HINT:   $hint $main::BR}));
}

sub CAPA_explanation {
	TEXT(solution( qq{ $main::BR$main::BR EXPLANATION:   @_ $main::BR$main::BR} )) if solution(@_);
}

sub pow {
    my($base,$exponent)=@_;
    $base**$exponent;
}
sub CAPA_tex {
    my $tex = shift;
   # $tex =~ s|/*|\$|g;
    #$tex =~ s/\\/\\\\/g;   #protect backslashes???
    my $nontex = shift;
    &M3($tex, $nontex,$nontex);
}
sub CAPA_web {
	my $text = shift;
	my $tex  = shift;
	my $html = shift;
	&M3($tex,"\\begin{rawhtml}$html\\end{rawhtml}",$html);
}
sub CAPA_html {
	my $html = shift;
	&M3("","\\begin{rawhtml}$html\\end{rawhtml}",$html);
}
sub var_in_tex {
    my($tex)=$_[0];
    &M3( "$tex","$tex","");
}



sub isNumberQ {  # determine whether the input is a number
	my $in = shift;
	$in =~ /^[\d\.\+\-Ee]+$/;
}

sub choose {
   # my($in)=join(" ",@_);
    my($var)=$_[0];
    $_[$var];
}

sub problem {
	$main::probNum;
}

sub pin {
    $main::psvn;
}
sub section {
    $main::sectionNumber;
}
sub name {
    $main::studentName;
}
sub set {
    $main::setNumber;
}
sub question {
    $main::probNum;
}

sub due_date {
 	$main::formattedDueDate;
 }

sub answer_date {
   $main::formattedAnswerDate;
}
sub open_date {
   $main::formattedOpenDate;
}
sub to_string {
    $_[0];
}


sub CAPA_EV {

   my $out = &EV3(@_);
   $out  =~ s/\n\n/\n/g;  # hack to prevent introduction of paragraphs in TeX??
   # HACK TO DO THE RIGHT THING WITH DOLLAR SIGNS
   $out = ev_substring($out,"/*/*","/*/*",\&display_math_ev3);
   $out = ev_substring($out,"/*","/*",\&math_ev3);
   # TEXT($main::BR, $main::BR, $out,$main::BR,$main::BR);
   $out;
}

# these are very commonly needed files
CAPA_import("${main::CAPA_Tools}StdMacros");
CAPA_import("${main::CAPA_Tools}StdUnits");
CAPA_import("${main::CAPA_Tools}StdConst");
#####################

$main::prob_val="";			# gets rid of spurious errors.
$main::prob_try="";

1;
