###

=head1 NAME

        PGasu.pl -- located in the pg/macros directory

=head1 SYNPOSIS


	Macros contributed by John Jones

=cut


# Answer evaluator which always marks things correct

=head3 auto_right()


=cut

sub auto_right {
	my $ae = std_str_cmp("");

	my $ans_eval = sub {
		my $tried = shift;
		my $ans_hash = &$ae($tried);
		$ans_hash->{score} = 1;
		return $ans_hash;
	};
	return $ans_eval;
}

# Evaluate in tth mode

=head3	tthev()



=cut

sub tthev {
	my $cmt = shift;

	$mdm = $main::displayMode;
	$main::displayMode = 'HTML_tth';
	$cmt = EV3($cmt);
	$cmt =~ s/\\par/<P>/g;
        $cmt =~ s/\\noindent//g;
	$main::displayMode =$mdm;
	$cmt
}

=head3	no_decs()



=cut


sub no_decs {
	my ($old_evaluator) = @_;

  my $msg= "Your answer contains a decimal.  You must provide an exact answer, e.g. sqrt(5)/3";
	$old_evaluator->install_pre_filter(must_have_filter(".", 'no', $msg));
	$old_evaluator->install_post_filter(\&raw_student_answer_filter);

	return $old_evaluator;
	}

=head3     must_include()

 

=cut

sub must_include {
	my ($old_evaluator) = shift;
	my $muststr = shift;

	$old_evaluator->install_pre_filter(must_have_filter($muststr));
	$old_evaluator->install_post_filter(\&raw_student_answer_filter);
	return $old_evaluator;
	}
=head3      no_trig_fun()



=cut

sub no_trig_fun {
	my ($ans) = shift;
	my $new_eval = fun_cmp($ans);
	my ($msg) = "Your answer to this problem may not contain a trig function.";
	$new_eval->install_pre_filter(must_have_filter("sin", 'no', $msg));
	$new_eval->install_pre_filter(must_have_filter("cos", 'no', $msg));
	$new_eval->install_pre_filter(must_have_filter("tan", 'no', $msg));
	$new_eval->install_pre_filter(must_have_filter("sec", 'no', $msg));
	$new_eval->install_pre_filter(must_have_filter("csc", 'no', $msg));
	$new_eval->install_pre_filter(must_have_filter("cot", 'no', $msg));

	return $new_eval;
}

=head3      no_trig()



=cut
=head3      no_trig()



=cut

sub no_trig {
	my ($ans) = shift;
	my $new_eval = num_cmp($ans);
	my ($msg) = "Your answer to this problem may not contain a trig function.";
	$new_eval->install_pre_filter(must_have_filter("sin", 'no', $msg));
	$new_eval->install_pre_filter(must_have_filter("cos", 'no', $msg));
	$new_eval->install_pre_filter(must_have_filter("tan", 'no', $msg));
	$new_eval->install_pre_filter(must_have_filter("sec", 'no', $msg));
	$new_eval->install_pre_filter(must_have_filter("csc", 'no', $msg));
	$new_eval->install_pre_filter(must_have_filter("cot", 'no', $msg));

	return $new_eval;
}

=head3      exact_no_trig()



=cut

sub exact_no_trig {
	my ($ans) = shift;
	my $old_eval = num_cmp($ans);
	my $new_eval = no_decs($old_eval);
	my ($msg) = "Your answer to this problem may not contain a trig function.";
	$new_eval->install_pre_filter(must_have_filter("sin", 'no', $msg));
	$new_eval->install_pre_filter(must_have_filter("cos", 'no', $msg));
	$new_eval->install_pre_filter(must_have_filter("tan", 'no', $msg));
	$new_eval->install_pre_filter(must_have_filter("sec", 'no', $msg));
	$new_eval->install_pre_filter(must_have_filter("csc", 'no', $msg));
	$new_eval->install_pre_filter(must_have_filter("cot", 'no', $msg));

	return $new_eval;
}


=head3      must_have_filter()


     
          # First argument is the string to have, or not have
		  # Second argument is optional, and tells us whether yes or no
		  # Third argument is the error message to produce (if any).

=cut


# First argument is the string to have, or not have
# Second argument is optional, and tells us whether yes or no
# Third argument is the error message to produce (if any).
sub must_have_filter {
	my $str = shift;
	my $yesno = shift;
	my $errm = shift;

	$str =~ s/\./\\./g;
	if(!defined($yesno)) {
		$yesno=1;
	} else {
		$yesno = ($yesno eq 'no') ? 0 :1;
	}

	my $newfilt = sub {
		my $num = shift;
		my $process_ans_hash = ( ref( $num ) eq 'AnswerHash' ) ? 1 : 0 ;
		my ($rh_ans);
		if ($process_ans_hash) {
			$rh_ans = $num;
			$num = $rh_ans->{original_student_ans};
		}
		my $is_ok = 0;

		return $is_ok unless defined($num);

		if (($yesno and ($num =~ /$str/)) or (!($yesno) and !($num=~ /$str/))) {
			$is_ok = 1;
		}

		if ($process_ans_hash)   {
			if ($is_ok == 1 ) {
				$rh_ans->{original_student_ans}=$num;
				return $rh_ans;
			} else {
				if(defined($errm)) {
					$rh_ans->{ans_message} = $errm;
					$rh_ans->{student_ans} = $rh_ans->{original_student_ans};
#					$rh_ans->{student_ans} = "Your answer was \"$rh_ans->{original_student_ans}\". $errm";
					$rh_ans->throw_error('SYNTAX', $errm);
				} else {
					$rh_ans->throw_error('NUMBER', "");
				}
				return $rh_ans;
			}

		} else {
			return $is_ok;
		}
	};
	return $newfilt;
}

=head3      raw_student_answer_filter()



=cut


sub raw_student_answer_filter {
	my ($rh_ans) = shift;
#	warn "answer was ".$rh_ans->{student_ans};
	$rh_ans->{student_ans} = $rh_ans->{original_student_ans}
		unless ($rh_ans->{student_ans} =~ /[a-zA-Z]/);
#	warn "2nd time ... answer was ".$rh_ans->{student_ans};

	return $rh_ans;
}

=head3      no_decimal_list()



=cut


sub no_decimal_list {
	my ($ans) = shift;
	my (%jopts) = @_;
	my $old_evaluator = number_list_cmp($ans);

	my $answer_evaluator = sub {
		my $tried = shift;
		my $ans_hash;
			if  ( ref($old_evaluator) eq 'AnswerEvaluator' ) { # new style
				$ans_hash = $old_evaluator->evaluate($tried);
			} elsif (ref($old_evaluator) eq  'CODE' )     { #old style
				$ans_hash = &$old_evaluator($tried);
		}
		if(defined($jopts{'must'}) && ! ($tried =~ /$jopts{'must'}/)) {
			$ans_hash->{score}=0;
			$ans_hash->setKeys( 'ans_message' => 'Your answer needs to be exact.');
		}
		if($tried =~ /\./) {
			$ans_hash->{score}=0;
			$ans_hash->setKeys( 'ans_message' => 'You may not use decimals in your answer.');
		}
		return $ans_hash;
	};
	return $answer_evaluator;
}


=head3      no_decimals()



=cut


sub no_decimals {
	my ($ans) = shift;
	my (%jopts) = @_;
	my $old_evaluator = std_num_cmp($ans);

	my $answer_evaluator = sub {
		my $tried = shift;
		my $ans_hash;
			if  ( ref($old_evaluator) eq 'AnswerEvaluator' ) { # new style
				$ans_hash = $old_evaluator->evaluate($tried);
			} elsif (ref($old_evaluator) eq  'CODE' )     { #old style
				$ans_hash = &$old_evaluator($tried);
		}
		if(defined($jopts{'must'}) && ! ($tried =~ /$jopts{'must'}/)) {
			$ans_hash->{score}=0;
			$ans_hash->setKeys( 'ans_message' => 'Your answer needs to be exact.');
		}
		if($tried =~ /\./) {
			$ans_hash->{score}=0;
			$ans_hash->setKeys( 'ans_message' => 'You may not use decimals in your answer.');
		}
		return $ans_hash;
	};
	return $answer_evaluator;
}

=head3      log_switcheroo()



=cut


sub log_switcheroo {
	my $foo = shift;

	$foo =~ s/log(?!ten)/logten/gi;
	return $foo;
}

# only used below, so assumes it is being applied to num_cmp
sub log_switcheroo_filter {
	my ($rh_ans) = shift;
	$rh_ans->{student_ans} = log_switcheroo($rh_ans->{student_ans});

	return $rh_ans;
	}

=head3      log10_cmp()



=cut



sub log10_cmp {
 my(@stuff) = @_;
 $stuff[0] = log_switcheroo($stuff[0]);
 my ($ae) = num_cmp(@stuff);
 $ae->install_pre_filter(\&log_switcheroo_filter);
 return $ae;
}


=head3      with_comments()


	# Wrapper for an answer evaluator which can also supply comments

=cut

# Wrapper for an answer evaluator which can also supply comments


sub with_comments {
	my ($old_evaluator, $cmt) = @_;

# 	$mdm = $main::displayMode;
# 	$main::displayMode = 'HTML_tth';
# 	$cmt = EV2($cmt);
# 	$main::displayMode =$mdm;

	my $ans_evaluator =  sub  {
		my $tried = shift;
		my $ans_hash;

		if  ( ref($old_evaluator) eq 'AnswerEvaluator' ) { # new style
			$ans_hash = $old_evaluator->evaluate($tried);
		} elsif (ref($old_evaluator) eq  'CODE' )     { #old style
			$ans_hash = &$old_evaluator($tried);
		} else {
			warn "There is a problem using the answer evaluator";
		}

    if($ans_hash->{score}>0) {
      $ans_hash -> setKeys( 'ans_message' => $cmt);
    }
		return $ans_hash;
	};

  $ans_evaluator;
}


=head3      pc_evaluator()


		# Wrapper for multiple answer evaluators, it takes a list of the following as inputs
		# [answer_evaluator, partial credit factor, comment]
		# it applies evaluators from the list until it hits one with positive credit,
		# weights it by the partial credit factor, and throws in its comment


=cut


# Wrapper for multiple answer evaluators, it takes a list of the following as inputs
# [answer_evaluator, partial credit factor, comment]
# it applies evaluators from the list until it hits one with positive credit,
# weights it by the partial credit factor, and throws in its comment

sub pc_evaluator {
	my ($evaluator_list) = @_;

	my $ans_evaluator =  sub  {
		my $tried = shift;
		my $ans_hash;
		for($j=0;$j<scalar(@{$evaluator_list}); $j++) {
			my $old_evaluator = $evaluator_list->[$j][0];
			my $cmt = $evaluator_list->[$j][2];
			my $weight = $evaluator_list->[$j][1];

			if  ( ref($old_evaluator) eq 'AnswerEvaluator' ) { # new style
				$ans_hash = $old_evaluator->evaluate($tried);
			} elsif (ref($old_evaluator) eq  'CODE' )     { #old style
				$ans_hash = &$old_evaluator($tried);
			} else {
				warn "There is a problem using the answer evaluator";
			}

			if($ans_hash->{score}>0) {
				$ans_hash -> setKeys( 'ans_message' => $cmt);
				$ans_hash->{score} *= $weight;
				return $ans_hash;
			};
		};
		return $ans_hash;
	};

  $ans_evaluator;
}

=head3      nicestring



=cut


sub nicestring {
  my($thingy) = shift;
  my(@coefs) = @{$thingy};
  my $n = scalar(@coefs);
  $thingy = shift;
  my(@others);
  if(defined($thingy)) {
    @others = @{$thingy};
  } else {
    my($j);
    for $j (1..($n-2)) {
      $others[$j-1] = "x^".($n-$j);
    }
    if($n>=2) { $others[$n-2] = "x";}
    $others[$n-1] = "";
  }
  my($j, $k)=(0,0);
  while(($k<$n) && ($coefs[$k]==0)) {$k++;}
  if($k==$n) {return("0");}
  my $ans;
  if($coefs[$k]==1) {$ans = ($others[$k]) ? "$others[$k]" : "1";}
  elsif($coefs[$k]== -1) {$ans =  ($others[$k]) ? "- $others[$k]" : "-1"}
  else { $ans = "$coefs[$k] $others[$k]";}
  $k++;
  for $j ($k..($n-1)) {
    if($coefs[$j] != 0) {
      if($coefs[$j] == 1) {
        $ans .= ($others[$j]) ? "+ $others[$j]" : "+ 1";
      } elsif($coefs[$j] == -1) {
        $ans .= ($others[$j]) ? "- $others[$j]" : "-1";
      } else {
        $ans .= "+ $coefs[$j] $others[$j]";
      }
    }
  }
  return($ans);
}


=head3      displaymat



=cut


sub displaymat {
	my $tmpp = shift;
	my %opts = @_;
	my @myrows = @{$tmpp};
	my $numrows = scalar(@myrows);
	my @arow = $myrows->[0];
	my ($number)= scalar(@arow);   #number of columns in table
	my $out;
	my $j;
	my $align1=''; # alignment as a string
	my @align;     # alignment as a list
	if(defined($opts{'align'})) {
		$align1= $opts{'align'};
		@align = split //, $opts{'align'};
	} else {
		for($j=0; $j<$number; $j++) {
			$align[$j] = "c";
			$align1 .= "c";
		}
	}

	$out .= beginmatrix($align1);
	$out .= matleft($numrows);
	for $j (@myrows) {
		$out .= matrow($j, @align);
	}
	$out .= matright($numrows);
	$out .= endmatrix();
	$out;
}

=head3      beginmatrix



=cut


sub beginmatrix {
	my ($aligns)=shift;   #alignments of columns in table
#	my %options = @_;
	my $out =	"";
	if ($displayMode eq 'TeX') {
		$out .= "\n\\(\\displaystyle\\left(\\begin{array}{$aligns} \n";
		}
	elsif ($displayMode eq 'Latex2HTML') {
		$out .= "\n\\begin{rawhtml} <TABLE  BORDER=0>\n\\end{rawhtml}";
		}
	elsif ($displayMode eq 'HTML' || $displayMode eq 'HTML_tth' || $displayMode eq 'HTML_dpng') {
		$out .= "<TABLE BORDER=0>\n"
	}
	else {
		$out = "Error: beginmatrix: Unknown displayMode: $displayMode.\n";
		}
	$out;
}


=head3      matleft



=cut



sub matleft {
	my $numrows = shift;
	if ($displayMode eq 'TeX') {
		return "";
	}
	my $out='';
	my $j;

	if(($displayMode eq 'HTML_dpng') || ($displayMode eq 'Latex2HTML')) {
# 		if($numrows>12) {		$numrows = 12; }
		if($displayMode eq 'Latex2HTML') { $out .= '\begin{rawhtml}'; }
 		$out .= "<tr><td nowrap=\"nowrap\" align=\"left\">";
		if($displayMode eq 'Latex2HTML') { $out .= '\end{rawhtml}'; }
# 		$out .= "<img alt=\"(\" src = \"".
# 			$main::imagesURL."/left$numrows.png\" >";
# 		return $out;
		$out .= '\(\left.\begin{array}{c}';
		for($j=0;$j<$numrows;$j++)  { $out .= ' \\\\'; }
		$out .= '\end{array}\right(\)';

		if($displayMode eq 'Latex2HTML') { $out .= '\begin{rawhtml}'; }
 		$out .= "<td><table border=0  cellspacing=5>\n";
		if($displayMode eq 'Latex2HTML') { $out .= '\end{rawhtml}'; }
		return $out;
	}
	$out = "<tr><td nowrap=\"nowrap\" align=\"left\"><font face=\"symbol\">æ<br />";
	for($j=0;$j<$numrows;$j++)  {
		$out .= "ç<br />";
	}
	$out .= "è</font></td>\n";
	$out .= "<td><table border=0  cellspacing=5>\n";
	return $out;
}


=head3      matright



=cut


sub matright {
	my $numrows = shift;
	my $out='';
	my $j;

	if ($displayMode eq 'TeX') {
		return "";
	}

	if(($displayMode eq 'HTML_dpng') || ($displayMode eq 'Latex2HTML')) {
		if($displayMode eq 'Latex2HTML') { $out .= '\begin{rawhtml}'; }
		$out .= "</table><td nowrap=\"nowrap\" align=\"right\">";
		if($displayMode eq 'Latex2HTML') { $out .= '\end{rawhtml}'; }

#		$out .= "<img alt=\"(\" src = \"".
#			"/webwork_system_html/images"."/right$numrows.png\" >";
		$out .= '\(\left)\begin{array}{c}';
		for($j=0;$j<$numrows;$j++)  { $out .= ' \\\\'; }
		$out .= '\end{array}\right.\)';
		return $out;
	}

	$out .= "</table>";
	$out .= "<td nowrap=\"nowrap\" align=\"left\"><font face=\"symbol\">ö<br />";
	for($j=0;$j<$numrows;$j++)  {
		$out .= "÷<br />";
	}
	$out .= "ø</font></td>\n";
	return $out;
}

=head3      endmatrix



=cut


sub endmatrix {
	my $out = "";
	if ($displayMode eq 'TeX') {
		$out .= "\n\\end{array}\\right)\\)\n";
		}
	elsif ($displayMode eq 'Latex2HTML') {
		$out .= "\n\\begin{rawhtml} </TABLE >\n\\end{rawhtml}";
		}
	elsif ($displayMode eq 'HTML' || $displayMode eq 'HTML_tth' || $displayMode eq 'HTML_dpng') {
		$out .= "</TABLE>\n";
		}
	else {
		$out = "Error: PGchoicemacros: endtable: Unknown displayMode: $displayMode.\n";
		}
	$out;
}


=head3      matrow



=cut



sub matrow {
	my $elements = shift;
	my @align = @_;
	my @elements = @{$elements};
	my $out = "";
	if ($displayMode eq 'TeX') {
		while (@elements) {
			$out .= shift(@elements) . " &";
			}
		 chop($out); # remove last &
		 $out .= "\\\\  \n";
		 # carriage returns must be added manually for tex
		}
	elsif ($displayMode eq 'Latex2HTML') {
		$out .= "\n\\begin{rawhtml}\n<TR>\n\\end{rawhtml}\n";
		while (@elements) {
			$out .= " \n\\begin{rawhtml}\n<TD> \n\\end{rawhtml}\n" . shift(@elements) . " \n\\begin{rawhtml}\n</TD> \n\\end{rawhtml}\n";
			}
		$out .= " \n\\begin{rawhtml}\n</TR> \n\\end{rawhtml}\n";
	}
	elsif ($main::displayMode eq 'HTML' || $main::displayMode eq 'HTML_tth' || $displayMode eq 'HTML_dpng') {
		$out .= "<TR><td nowrap=\"nowrap\">\n";
		while (@elements) {
			my $myalign;
			#do {$myalign = shift @align;} until($myalign ne "|");
			$myalign = shift @align;
			if($myalign eq "|") {
				$out .= '<td> | </td>';
			} else {
				if($myalign eq "c") { $myalign = "center";}
				if($myalign eq "l") { $myalign = "left";}
				if($myalign eq "r") { $myalign = "right";}
				$out .= "<TD nowrap=\"nowrap\" align=\"$myalign\">" . shift(@elements) . "</TD>";
			}
			}
		$out .= "<td>\n</TR>\n";
	}
	else {
		$out = "Error: matrow: Unknown displayMode: $main::displayMode.\n";
		}
	$out;
}


## Local Variables:
## mode: CPerl
## font-lock-mode: t
## End:
