
BEGIN{
	be_strict;
}

package main;


=head1 NAME

PGchoicemacros.pl --- located in the courseScripts directory


=head1 SYNPOSIS

=pod

There are two types of choice macros. The older versions are simply scripts.
The newer versions involve the "List.pm" class and its sub-classes
and the use of objects based on these classes. The list sub-classes are:
"Match.pm" which aids in setting up matching question
 and answer lists, "Select.pm" which aids in selecting
 and presenting a subset of questions with short answers
(e.g. true/false questions) from a larger question set, and
"Multiple.pm" which aids in setting up a
standard style, one question, many answers type multiple
choice question.


=head1 DESCRIPTION

Sample usage:


	$ml = new_match_list();
	# enter three questions and their answers
	$ml->qa( 	 "What color is a rose?",
			 "Red",
			 "What color is the sky?",
			 "Blue",
			 "What color is the sea?",
			 "Green"
	);
	# choose two of these questions, ordered at random,
	#	which will be printed in the problem.
	$ml->choose(2);
	BEGIN_TEXT
		Match the answers below with these questions:$BR
		\\{$ml->print_q\\} $BR
		Answers:
		\\{$ml->print_a\\}
	END_TEXT

	ANS( $ml->ra_correct_ans()    );

=cut


=head2 Matching List macros


=head3 new_match_list

Matching list object creation macro

Usage:


	$ml = new_match_list();

Which is short hand for the following direct call to Match

	$ml = new Match(random(1,2000,1), ~~&std_print_q, ~~&std_print_a);


Either call will create a matching list object in the variable $ml.
(I< Note: $ml cannot be a my variable if it is to be used within a BEGIN_TEXT/END_TEXT block.>)

The first argument is the seed for the match list (choosen at random between 1 and 2000 in
the example above.).  The next two arguments are references to the print subroutines
used to print the questions and the answers.
Other printing methods can be used instead of the standard ones.  An
example of how to do this is demonstrated with
"pop_up_list_print_q"  below.

=head4 std_print_q

Standard method for formatting a list of questions with answer blanks.

This  formatting routine is the default method for formatting the
way questions are printed
for each of the three sub-classes of "List.pm". It lists the questions vertically, numbering
them sequentially and providing an answer blank before each question.
C<std_print_q> checks which mode the user is trying to print the
questions from and returns the appropriately formatted string.

The length of the answer blank can be set with C<$ml->

To replace the standard question formatting method with your own, use:

	$ml->rf_print_q(~~&my_question_format_method)

Your method should be a subroutine of the form C<my_question_format_method($self, @questions)>
and should return a string to be printed.  The @questions array contains the
questions to be listed, while $self  can be used to obtain extra information from
the object for formatting purposes. The variable C<$main::displayMode> contains the
current display mode.  (See "MODES" for more details on display modes and
see "writing print methods for lists" for details on constructing formatting subroutines.)


=head4 std_print_a

Standard method for formatting a list of answers.

This simple formatting routine is the default method for formatting
the answers for matching lists.  It lists the answers vertically
lettered sequentially.

To replace the standard answer formatting method with your own subroutine use:

	$ml->rf_print_q(~~&my_answer_format_method)

The answer formatting method has the same interface as the question formatting
method.


=head2 Select List macros


=head3 new_select_list

Select list object creation macro

Usage:

	$sl = new_select_list;

Which is equivalent to this direct call to Select

	$sl = new Select(random(1,2000,1), ~~&std_print_q, ~~&std_print_a);


Either call will create a select list object in the variable $sl. ( Note that
$sl cannot be a my variable if it is to be used within a BEGIN_TEXT/END_TEXT
block.)  The printing methods are the same as those defined for C<new_match_list>
above.
See the documentation for "Select.pm" to see how to use this
object to create a true/false question.

std_print_a is only intended to be used for debugging with select lists, as there is rarely a reason to
print out the answers to a select list.


=head3 new_pop_up_select_list



Usage:

	$sl = new_pop_up_select_list;</I></PRE>

Which is equivalent to this direct call to Select

	$sl = new Select(random(1,2000,1), ~~&pop_up_list_print_q, ~~&std_print_a);


Either call will create a select list object in the variable $sl. ( Note that
$sl cannot be a my variable if it is to be used within a BEGIN_TEXT/END_TEXT
block.)  The printing methods are passed as references (~~ in PG equals \ in
perl) to subroutines so that no matter what printing subroutines are used,
those subroutines can be used by saying $sl->print_q and $sl->print_a.  This
also means that other subroutines can be used instead of the default ones.

See the documentation for <a href='Select'>Select.pm</a> to see how to use this
	object to create a true/false question.


=head4 std_print_q

Standard method for printing questions with answer boxes

See std_print_q under Matching Lists above.


=head4 pop_up_list_print_q

Alternate method for print questions with pop up lists.

Usage:

This printing routine is used to print the questions for a true/false or other
select list with a preceding pop up list of possible answers.  A list of values
and labels need to be given to the pop_up_list so that the intended answer is
returned when a student selects an answer form the list.  Notethe use of => to
associate the values on the left with the labels on the right, this means that,
for instance, the student will see the word True in the pop_up_list but the
answer that is returned to the grader is T, so that it corresponds with what
the professor typed in as the answer when using $sl->qa('blah blah', 'T');

=for html
	<PRE>
	<I>$sl->ra_pop_up_list([</I>value<I> => </I>label<I>,
							T => 'True',
							F => 'False']);</I></PRE>


=head4 std_print_a

This is only intended to be used for debugging as there is rarely a reason to
print out the answers to a select list.

See std_print_a under Matching Lists above.


=head2 Multiple Choice macros


=head3 new_multiple_choice

Multiple choice object creation macro

Usage:

=for html
	<PRE>
	<I>$mc = new_multiple_choice;</I></PRE>

Which is equivalent to this direct call to Multiple

=for html
	<PRE>
	<I>$mc = new Multiple(random(1,2000,1), ~~&std_print_q, ~~&std_print_a);</I></PRE>

Either call will create a multiple choice object in the variable $mc. Note that
$mc cannot be a my variable if it is to be used within a BEGIN_TEXT/END_TEXT
block.

=for html
	<P>See the documentation for <a href='Multiple'>Multiple.pm</a> to see how to use
	this object to create a multiple choice question.


=head4 std_print_q

Standard method for printing questions

See std_print_q under Matching Lists above.


=head4 radio_print_a

Method for printing answers with radio buttons

This simple printing routine is used to print the answers to multiple choice
questions in a bulleted style with radio buttons preceding each possible answer.
When a multiple choice object is created, a reference to radio_print_a is passed
to that object so that it can be used from within the object later.

radio_print_a checks which mode the user is trying to print the answers from and
returns the appropriately formatted string.


=head3 new_checkbox_multiple_choice

Checkbox multiple choice object creation macro

Usage:

=for html
	<PRE>
	<I>$cmc = new_checkbox_multiple_choice;</I></PRE>

Which is equivalent to this direct call to Multiple

=for html
	<PRE>
	<I>$cmc = new Multiple(random(1,2000,1), ~~&std_print_q, ~~&checkbox_print_a);</I></PRE>

Either call will create a checkbox multiple choice object in the variable $cmc. Note that
$cmc cannot be a my variable if it is to be used within a BEGIN_TEXT/END_TEXT
block.

=for html
	<P>See the documentation for <a href='Multiple'>Multiple.pm</a> to see how to use
	this object to create a multiple choice question.


=head4 std_print_q

Standard method for printing questions

See std_print_q under Matching Lists above.


=head4 checkbox_print_a

Method for printing answers with radio buttons

This simple printing routine is used to print the answers to multiple choice
questions in a bulleted style with checkboxes preceding each possible answer.
When a multiple choice object is created, a reference to checkbox_print_a is passed
to that object so that it can be used from within the object later.

checkbox_print_a checks which mode the user is trying to print the answers from and
returns the appropriately formatted string.



=cut
BEGIN {
	be_strict();
}
sub _PGchoicemacros_init{
}

=head4 new_match_list

	Usage: $ml = new_match_list();


Note that $ml cannot be a my variable if used within a BEGIN_TEXT/END_TEXT block

=cut

sub new_match_list {
	new Match(random(1,2000,1), \&std_print_q, \&std_print_a);
}

=head4 new_select_list
	sage: $sl = new_select_list();

Note that $sl cannot be a my variable if used within a BEGIN_TEXT/END_TEXT block

=cut

sub new_select_list {
	new Select(random(1,2000,1), \&std_print_q, \&std_print_a);
}

=head4 new_pop_up_select_list;

	Usage: $pusl = new_pop_up_select_list();

=cut

sub new_pop_up_select_list {
	new Select(random(1,2000,1), \&pop_up_list_print_q, \&std_print_a);
}

=head4 new_multiple_choice

	Usage: $mc = new_multiple_choice();

=cut


sub new_multiple_choice {
	new Multiple(random(1,2000,1), \&std_print_q, \&radio_print_a);
}

=head4 new_checkbox_multiple_choice

	Usage: $mcc = new_checkbox_multiple_choice();

=cut

sub new_checkbox_multiple_choice {
	new Multiple(random(1,2000,1), \&std_print_q, \&checkbox_print_a);
}

=head4 initializing a pop_up_list

	Usage:	$sl->rf_print_a(~~&pop_up_list_print_q);
			$sl->ra_pop_up_list([</I>value<I> => </I>label<I>, T => 'True', F => 'False']);

=cut

sub pop_up_list_print_q {
    my $self = shift;
    my (@questions) = @_;
    my $length = $self->{ans_rule_len};
    my @list = @{$self->{ra_pop_up_list} };
    my $out = "";

 	#if ($main::displayMode eq 'HTML' || $main::displayMode eq 'HTML_tth') {
 	if ($main::displayMode =~ /^HTML/) {
 		my $i=1; my $quest;
 		foreach $quest (@questions) {
 			 $out.=	"\n<p>" . pop_up_list(@list) . "&nbsp;<B>$i.</B> $quest";
 			 $i++;
 		}
 		$out .= "<br>\n";
	} elsif ($main::displayMode eq 'Latex2HTML') {
		my $i=1; my $quest;
		foreach $quest (@questions) {
			 $out.=	" \\begin{rawhtml}<p><B>\\end{rawhtml}" . pop_up_list(@list) . " $i. \\begin{rawhtml}</B>\\end{rawhtml}   $quest";
			 $i++;
		}
		$out .= " \\begin{rawhtml}<BR>\\end{rawhtml} ";
	}  elsif ($main::displayMode eq 'TeX') {
	    $out = "\n\\par\\begin{enumerate}\n";
	    my $i=1; my $quest;
	 	foreach $quest (@questions) {
	 		$out .= "\\item[" .  pop_up_list(@list) . "$i.] $quest\n";
	 		$i++;
	 	}
	 	$out .= "\\end{enumerate}\n";
	} else {
		$out = "Error: PGchoicemacros: pop_up_list_print_q: Unknown displayMode: $main::displayMode.\n";
	}
	$out;

}


# For graphs in a matching question.

#sub format_graphs {
#	my $self = shift;
#	my @in = @_;
#	my $out = "";
#	while (@in) {
#		$out .= shift(@in). "#" ;
#	}
#	$out;
#}


# To put pop-up-list at the end of a question.
# contributed by Mark Schmitt 3-6-03

sub quest_first_pop_up_list_print_q {
    my $self = shift;
    my (@questions) = @_;
    my $length = $self->{ans_rule_len};
    my @list = @{$self->{ra_pop_up_list} };
    my $out = "";

	if ($main::displayMode eq 'HTML' || $main::displayMode eq 'HTML_tth'
              || $main::displayMode eq 'HTML_dpng'|| $main::displayMode eq 'HTML_img') {
 		my $i=1; my $quest;
 		foreach $quest (@questions) {
 			 $out.=	"\n<p>" .  "&nbsp; $quest" . pop_up_list(@list);
 			 $i++;
 		}
 		$out .= "<br>\n";
	} elsif ($main::displayMode eq 'Latex2HTML') {
		my $i=1; my $quest;
		foreach $quest (@questions) {
			 $out.=	" \\begin{rawhtml}<p><B>\\end{rawhtml}" . pop_up_list(@list) . " $i. \\begin{rawhtml}</B>\\end{rawhtml}   $quest";
			 $i++;
		}
		$out .= " \\begin{rawhtml}<BR>\\end{rawhtml} ";
	}  elsif ($main::displayMode eq 'TeX') {
	    $out = "\n\\par\\begin{enumerate}\n";
	    my $i=1; my $quest;
	 	foreach $quest (@questions) {
	 		$out .= "\\item[" .  pop_up_list(@list) . "$i.] $quest\n";
	 		$i++;
	 	}
	 	$out .= "\\end{enumerate}\n";
	} else {
		$out = "Error: PGchoicemacros: pop_up_list_print_q: Unknown displayMode: $main::displayMode.\n";
	}
	$out;

}
# To put pop-up-list in the middle of a question.
# contributed by Mark Schmitt 3-6-03

sub ans_in_middle_pop_up_list_print_q {
    my $self = shift;
    my (@questions) = @_;
    my $length = $self->{ans_rule_len};
    my @list = @{$self->{ra_pop_up_list} };
    my $out = "";

	if ($main::displayMode eq 'HTML' || $main::displayMode eq 'HTML_tth'
              || $main::displayMode eq 'HTML_dpng'|| $main::displayMode eq 'HTML_img') {
 		my $i=1; my $quest;
 		foreach $quest (@questions) {
 			 $out.=	"" .  "&nbsp; $quest" . pop_up_list(@list);
 			 $i++;
 		}
 		$out .= "";
	} elsif ($main::displayMode eq 'Latex2HTML') {
		my $i=1; my $quest;
		foreach $quest (@questions) {
			 $out.=	" \\begin{rawhtml}<p><B>\\end{rawhtml}" . pop_up_list(@list) . " $i. \\begin{rawhtml}</B>\\end{rawhtml}   $quest";
			 $i++;
		}
		$out .= " \\begin{rawhtml}<BR>\\end{rawhtml} ";
	}  elsif ($main::displayMode eq 'TeX') {
	    $out = "\n\\par\\begin{enumerate}\n";
	    my $i=1; my $quest;
	 	foreach $quest (@questions) {
	 		$out .= "\\item[" .  pop_up_list(@list) . "$i.] $quest\n";
	 		$i++;
	 	}
	 	$out .= "\\end{enumerate}\n";
	} else {
		$out = "Error: PGchoicemacros: pop_up_list_print_q: Unknown displayMode: $main::displayMode.\n";
	}
	$out;

}


# Units for physics class
# contributed by Mark Schmitt 3-6-03

sub units_list_print_q {
    my $self = shift;
    my (@questions) = @_;
    my $length = $self->{ans_rule_len};
    my @list = @{$self->{ra_pop_up_list} };
    my $out = '';

	$out.= pop_up_list(@list);

    $out;
}

#Standard method of printing answers in a matching list
sub std_print_a {
	my $self = shift;
	my(@array) = @_;
	my $i = 0;
	my	$out= 	&main::M3(
					"\\begin{enumerate}\n",
					" \\begin{rawhtml} <OL TYPE=\"A\" VALUE=\"1\"> \\end{rawhtml} ",
					"<OL COMPACT TYPE=\"A\" START=\"1\">\n"
	) ;
	my $elem;
	foreach $elem (@array) {
		$out .= &main::M3(
					"\\item[$main::ALPHABET[$i].] $elem\n",
					" \\begin{rawhtml} <LI> \\end{rawhtml} $elem  ",
					"<LI> $elem\n"
		) ;
		$i++;
	}
	$out .= &main::M3(
				"\\end{enumerate}\n",
				" \\begin{rawhtml} </OL>\n \\end{rawhtml} ",
				"</OL>\n"
	) ;
	$out;

}




#Alternate method of printing answers as a list of radio buttons for multiple choice
sub radio_print_a {
    my $self = shift;
    my (@answers) = @_;
    my $out = "";
	my $i =0;
    my @in = ();
 	#if ($main::displayMode eq 'HTML' || $main::displayMode eq 'HTML_tth') {
 	if ($main::displayMode =~ /^HTML/) {
		foreach my $ans (@answers) {
			push (@in, ($main::ALPHABET[$i], "<B> $main::ALPHABET[$i]. </B> $ans"));
			$i++;
		}
		my @radio_buttons = ans_radio_buttons(@in);
		$out = "\n<BR>" . join "\n<BR>", @radio_buttons;
 		$out .= "<BR>\n";
	} elsif ($main::displayMode eq 'Latex2HTML') {
		foreach my $ans (@answers) {
			push (@in, ($main::ALPHABET[$i], "\\begin{rawhtml}<B> $main::ALPHABET[$i]. </B> \\end{rawhtml} $ans"));
			$i++;
		}
		my @radio_buttons = ans_radio_buttons(@in);
		$out = "\\begin{rawhtml}<BR>\\end{rawhtml}" . join "\\begin{rawhtml}<BR>\\end{rawhtml}", @radio_buttons;
		$out .= " \\begin{rawhtml}<BR>\\end{rawhtml} ";
	}  elsif ($main::displayMode eq 'TeX') {
		foreach my $ans (@answers) {
			push (@in, ($main::ALPHABET[$i], "$main::ALPHABET[$i]. $ans"));
			$i++;
		}
		my @radio_buttons = ans_radio_buttons(@in);
		#$out = "\n\\par\\begin{itemize}\n";
		$out .= join '', @radio_buttons;
		#$out .= "\\end{itemize}\n";
	} else {
		$out = "Error: PGchoicemacros: radio_print_a: Unknown displayMode: $main::displayMode.\n";
	}
	$out;

}

#Second alternate method of printing answers as a list of radio buttons for multiple choice
#Method for naming radio buttons is no longer round about and hackish
sub checkbox_print_a {
    my $self = shift;
    my (@answers) = @_;
    my $out = "";
	my $i =0;
    my @in = ();
# 	if ($main::displayMode eq 'HTML' || $main::displayMode eq 'HTML_tth') {
 	if ($main::displayMode =~ /^HTML/) {
		foreach my $ans (@answers) {
			push (@in, ($main::ALPHABET[$i], "<B> $main::ALPHABET[$i]. </B> $ans"));
			$i++;
		}
		my @checkboxes = ans_checkbox(@in);
		$out = "\n<BR>" . join "\n<BR>", @checkboxes;
 		$out .= "<BR>\n";
	} elsif ($main::displayMode eq 'Latex2HTML') {
		foreach my $ans (@answers) {
			push (@in, ($main::ALPHABET[$i], "\\begin{rawhtml}<B> $main::ALPHABET[$i]. </B> \\end{rawhtml} $ans"));
			$i++;
		}
		my @checkboxes = ans_checkbox(@in);
		$out = "\\begin{rawhtml}<BR>\\end{rawhtml}" . join "\\begin{rawhtml}<BR>\\end{rawhtml}", @checkboxes;
		$out .= " \\begin{rawhtml}<BR>\\end{rawhtml} ";
	}  elsif ($main::displayMode eq 'TeX') {
		foreach my $ans (@answers) {
			push (@in, ($main::ALPHABET[$i], "$main::ALPHABET[$i]. $ans"));
			$i++;
		}
		my @radio_buttons = ans_checkbox(@in);
		#$out = "\n\\par\\begin{itemize}\n";
		$out .= join '', @radio_buttons ;
		#$out .= "\\end{itemize}\n";
	} else {
		$out = "Error: PGchoicemacros: checkbox_print_a: Unknown displayMode: $main::displayMode.\n";
	}
	$out;

}


#Standard method of printing questions in a matching or select list
sub std_print_q {
    my $self = shift;
    my (@questions) = @_;
    my $length = $self->{ans_rule_len};
    my $out = "";
 	#if ($main::displayMode eq 'HTML' || $main::displayMode eq 'HTML_tth') {
 	if ($main::displayMode =~ /^HTML/) {
 		my $i=1; my $quest;
 		foreach $quest (@questions) {
 			 $out.=	"\n<BR>" . ans_rule($length) . "<B>$i.</B> $quest";
 			 $i++;
 		}
 		$out .= "<br>\n";
	} elsif ($main::displayMode eq 'Latex2HTML') {
		my $i=1; my $quest;
		foreach $quest (@questions) {
			 $out.=	" \\begin{rawhtml}<BR>\\end{rawhtml} " . ans_rule($length) . "\\begin{rawhtml}<B>\\end{rawhtml} $i. \\begin{rawhtml}</B>\\end{rawhtml}   $quest"; #"$i.   $quest";
			 $i++;
		}
		$out .= " \\begin{rawhtml}<BR>\\end{rawhtml} ";
	}  elsif ($main::displayMode eq 'TeX') {
	    $out = "\n\\par\\begin{enumerate}\n";
	    my $i=1; my $quest;
	 	foreach $quest (@questions) {
	 		$out .= "\\item[" . ans_rule($length) . "$i.] $quest\n";
	 		$i++;
	 	}
	 	$out .= "\\end{enumerate}\n";
	} else {
		$out = "Error: PGchoicemacros: std_print_q: Unknown displayMode: $main::displayMode.\n";
	}
	$out;

}



=head3 legacy macros

These are maintained for backward compatibility.
They can still be useful in constructing non-standard lists that don't fit
the various list objects.  In general the using the list objects is likely
to give better results and is preferred.

=cut

=head4 qa

=cut

sub qa {
	my($questionsRef,$answersRef,@questANDanswer) = @_;
	while (@questANDanswer) {
		push(@$questionsRef,shift(@questANDanswer));
		push(@$answersRef,shift(@questANDanswer));

	}
}

=head4 invert

=cut

sub invert {
	my @array = @_;
	my @out = ();
	my $i;
	for ($i=0;$i<=$#array;$i++) {
		$out[$array[$i]]=$i;
	}
	@out;
}

=head4 NchooseK

=cut

sub NchooseK {
	my($n,$k)=@_;;
	my @array = 0..($n-1);
	my @out = ();
	while (@out<$k) {
		push(@out, splice(@array,    random(0,$#array,1) ,         1) );
	}
	@out;
}

=head4 shuffle

=cut

sub shuffle {
	my ($i) = @_;
	my @out = &NchooseK($i,$i);
	@out;
}

=head4 match_questions_list

=cut

sub match_questions_list {
	my (@questions) = @_;
	my $out = "";
	#if ($main::displayMode eq 'HTML' || $main::displayMode eq 'HTML_tth') {
 	if ($main::displayMode =~ /^HTML/) {
		my $i=1; my $quest;
		foreach $quest (@questions) {
			 $out.=	"\n<BR>" . ans_rule(4) . "<B>$i.</B> $quest";
			 $i++;
		}
		$out .= "<br>\n";
	} elsif ($main::displayMode eq 'Latex2HTML') {
		my $i=1; my $quest;
		foreach $quest (@questions) {
			 $out.=	" \\begin{rawhtml}<BR>\\end{rawhtml} " . ans_rule(4) . "\\begin{rawhtml}<B>\\end{rawhtml} $i. \\begin{rawhtml}</B>\\end{rawhtml}   $quest"; #"$i.   $quest";
			 $i++;
		}
		$out .= " \\begin{rawhtml}<BR>\\end{rawhtml} ";
	} elsif ($main::displayMode eq 'TeX') {
	  	$out = "\n\\par\\begin{enumerate}\n";
	  	my $i=1; my $quest;
	 	foreach $quest (@questions) {
	 		$out .= "\\item[" . ans_rule(3) . "$i.] $quest\n";
	 		$i++;
	 		}
	 	$out .= "\\end{enumerate}\n";
	} else {
		$out = "Error: PGchoicemacros: match_questions_list: Unknown displayMode: $main::displayMode.\n";
	}
	$out;
}



sub match_questions_list_varbox {
	my ($length, @questions) = @_;
	my $out = "";
	#if ($main::displayMode eq 'HTML' || $main::displayMode eq 'HTML_tth') {
 	if ($main::displayMode =~ /^HTML/) {
		my $i=1; my $quest;
		foreach $quest (@questions) {
			$out.=	"\n<BR>" . ans_rule($length) . "<B>$i.</B> $quest";
			$i++;
		}
		$out .= "<br>\n";
	} elsif ($main::displayMode eq 'Latex2HTML') {
		my $i=1; my $quest;
		foreach $quest (@questions) {
			$out.=	" \\begin{rawhtml}<BR>\\end{rawhtml} " . ans_rule($length) . "\\begin{rawhtml}<B>\\end{rawhtml} $i. \\begin{rawhtml}</B>\\end{rawhtml}   $quest"; #"$i.   $quest";
			$i++;
		}
		$out .= " \\begin{rawhtml}<BR>\\end{rawhtml} ";
	} elsif ($main::displayMode eq 'TeX') {
		$out = "\n\\par\\begin{enumerate}\n";
		my $i=1; my $quest;
	 	foreach $quest (@questions) {
	 		$out .= "\\item[" . ans_rule($length) . "$i.] $quest\n";
	 		$i++;
	 	}
	 	$out .= "\\end{enumerate}\n";
	} else {
		$out = "Error: PGchoicemacros: match_questions_list_varbox: Unknown displayMode: $main::displayMode.\n";
	}
	$out;
}



1;
