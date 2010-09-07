################################################################################
# WeBWorK Program Generation Language
# Copyright � 2000-2007 The WeBWorK Project, http://openwebwork.sf.net/
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

PGchoicemacros.pl - Macros for multiple choice, matching, and true/false questions.

=head1 SYNOPSIS

Matching example:

 loadMacros("PGchoicemacros.pl");
 
 # create a new match list
 $ml = new_match_list();
 
 # enter three questions and their answers
 $ml->qa(
 	"What color is a rose?",
 	"Red",
 	"What color is the sky?",
 	"Blue",
 	"What color is the sea?",
 	"Green",
 );
 
 # choose two of these questions, ordered at random,
 # which will be printed in the problem.
 $ml->choose(2);
 
 # print the question and answer choices
 BEGIN_TEXT
 Match the answers below with these questions: $BR
 \{ $ml->print_q \} $BR
 Answers:
 \{ $ml->print_a \}
 END_TEXT
 
 # register the correct answer
 ANS($ml->ra_correct_ans);

=head1 DESCRIPTION

There are two types of choice macros. The older versions are simple subroutines.
The newer versions involve the List class and its sub-classes and the use of
objects based on these classes. The list sub-classes are:

=over

=item *

B<Match>, which aids in setting up matching question and answer lists,

=item *

B<Select>, which aids in selecting and presenting a subset of questions with short
answers (e.g. true/false questions) from a larger question set, and

=item *

B<Multiple>, which aids in setting up a standard one-question-many-answers multiple
choice question.

=back

=cut

# ^uses be_strict
BEGIN{
	be_strict;
}

package main;


BEGIN {
	be_strict();
}

# ^function _PGchoicemacros_init

sub _PGchoicemacros_init{
}

=head1 MACROS

=cut

################################################################################

=head2 Match lists

=over

=item new_match_list

 $ml = new_match_list();

new_match_list() creates a new Match object and initializes it with sensible
defaults. It is equivalent to:

 $ml = new Match(random(1,2000,1), ~~&std_print_q, ~~&std_print_a);

The first argument is the seed for the match list (choosen at random between 1
and 2000 in the example above). The next two arguments are references to the
print subroutines used to print the questions and the answers. Other printing
methods can be used instead of the standard ones. An example of how to do this
is demonstrated with pop_up_list_print_q() below.

=cut

# ^function new_match_list
# ^uses Match::new
# ^uses &std_print_q
# ^uses &std_print_a

sub new_match_list {
	new Match(random(1,2000,1), \&std_print_q, \&std_print_a);
}

=back

=cut

################################################################################

=head2 Select lists

=over

=item new_select_list

 $sl = new_select_list();

new_select_list() creates a new Select object and initializes it with sensible
defaults. It is equivalent to:

 $sl = new Select(random(1,2000,1), ~~&std_print_q, ~~&std_print_a);

The parameters to the Select constructor are the same as those for the Match
constrcutor described above under new_match_list().

See the documentation for the Select class to see how to use this object to
create a true/false question.

std_print_a is only intended to be used for debugging with select lists, as
there is rarely a reason to print out the answers to a select list.

=cut

# ^function new_select_list
# ^uses Select::new
# ^uses &std_print_q
# ^uses &std_print_a

sub new_select_list {
	new Select(random(1,2000,1), \&std_print_q, \&std_print_a);
}

=item new_pop_up_select_list()

 $sl = new_pop_up_select_list();

new_popup_select_list() creates a new Select object and initializes it such that
it will render as a popup list. It is equivalent to:

 $selectlist = new Select(random(1,2000,1), ~~&pop_up_list_print_q, ~~&std_print_a);

=cut

# ^function new_pop_up_select_list
# ^uses Select::new
# ^uses &pop_up_list_print_q
# ^uses &std_print_a

sub new_pop_up_select_list {
	new Select(random(1,2000,1), \&pop_up_list_print_q, \&std_print_a);
}

=back

=cut

################################################################################

=head2 Multiple choice quesitons

=over

=item new_multiple_choice()

 $mc = new_multiple_choice();

new_multiple_choice() creates a new Multiple object that presents a question and
a number possible answers, only one of which can be chosen. It is equivalent to:

 $mc = new Multiple(random(1,2000,1), ~~&std_print_q, ~~&radio_print_a);

The parameters to the Multiple constructor are the same as those for the Match
constrcutor described above under new_match_list().

=cut

# ^function new_multiple_choice
# ^uses Multiple::new
# ^uses &std_print_q
# ^uses &radio_print_a

sub new_multiple_choice {
	new Multiple(random(1,2000,1), \&std_print_q, \&radio_print_a);
}

=item new_checkbox_multiple_choice()

 $mc = new_checkbox_multiple_choice();

new_checkbox_multiple_choice() creates a new Multiple object that presents a
question and a number possible answers, any number of which can be chosen. It is
equivalent to:

 $mc = new Multiple(random(1,2000,1), ~~&std_print_q, ~~&checkbox_print_a);

=cut

# ^function new_checkbox_multiple_choice
# ^uses Multiple::new
# ^uses &std_print_q
# ^uses &checkbox_print_a
sub new_checkbox_multiple_choice {
	new Multiple(random(1,2000,1), \&std_print_q, \&checkbox_print_a);
}

=back

=cut

################################################################################

=head2 Question printing subroutines

=over

=item std_print_q()

 # $list can be a matching list, a select list, or a multiple choice list
 $list->rf_print_q(~~&std_print_q);
 TEXT($list->print_q);

This formatting routine is the default method for formatting the way questions
are printed for each of the three List sub-classes. It lists the questions
vertically, numbering them sequentially and providing an answer blank before
each question. std_print_q() checks which mode the user is trying to print the
questions from and returns the appropriately formatted string.

=cut


# ^function std_print_q

sub std_print_q {
    my $self = shift;
    my (@questions) = @_;
    my $length = $self->{ans_rule_len};
    my $out = "";
 	#if ($main::displayMode eq 'HTML' || $main::displayMode eq 'HTML_tth') {
 	if ($main::displayMode =~ /^HTML/) {
	        my $i=1; my $quest; $out = "\n<P>\n";
 		foreach $quest (@questions) {
 			 $out.=	ans_rule($length) . "&nbsp;<B>$i.</B> $quest<BR>";
 			 $i++;
 		}
	} elsif ($main::displayMode eq 'Latex2HTML') {
	        my $i=1; my $quest; $out = "\\par\n";
		foreach $quest (@questions) {
			 $out.=	ans_rule($length) . "\\begin{rawhtml}<B>$i. </B>\\end{rawhtml} $quest\\begin{rawhtml}<BR>\\end{rawhtml}\n";
			 $i++;
		}
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

=item pop_up_list_print_q()

 $sl->rf_print_q(~~&pop_up_list_print_q);
 $sl->ra_pop_up_list([T => 'True', F => 'False']);
 TEXT($sl->print_q);

Alternate method for print questions with pop up lists.

This printing routine is used to print the questions for a true/false or other
select list with a preceding pop up list of possible answers. A list of values
and labels need to be given to the pop_up_list so that the intended answer is
returned when a student selects an answer form the list. Note the use of => in
the example above to associate the values on the left with the labels on the
right, this means that, for instance, the student will see the word True in the
pop_up_list but the answer that is returned to the grader is T, so that it
corresponds with what the professor typed in as the answer when using
$sl->qa('blah blah', 'T');

=cut


# ^function pop_up_list_print_q

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



=item quest_first_pop_up_list_print_q()

 $sl->rf_print_q(~~&quest_first_pop_up_list_print_q);
 $sl->ra_pop_up_list([T => 'True', F => 'False']);
 TEXT($sl->print_q);

Similar to pop_up_list_print_q(), but places the popup list after the question
text in the output.

=cut

# To put pop-up-list at the end of a question.
# contributed by Mark Schmitt 3-6-03

# ^function quest_first_pop_up_list_print_q

sub quest_first_pop_up_list_print_q {
    my $self = shift;
    my (@questions) = @_;
    my $length = $self->{ans_rule_len};
    my @list = @{$self->{ra_pop_up_list} };
    my $out = "";

	if ($main::displayMode eq 'HTML_MathJax'
	 || $main::displayMode eq 'HTML_dpng'
	 || $main::displayMode eq 'HTML'
	 || $main::displayMode eq 'HTML_tth'
	 || $main::displayMode eq 'HTML_jsMath'
	 || $main::displayMode eq 'HTML_asciimath' 
	 || $main::displayMode eq 'HTML_LaTeXMathML'
	 || $main::displayMode eq 'HTML_img') {
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

=item ans_in_middle_pop_up_list_print_q()

 $sl->rf_print_q(~~&ans_in_middle_pop_up_list_print_q);
 $sl->ra_pop_up_list([T => 'True', F => 'False']);
 TEXT($sl->print_q);

Similar to quest_first_pop_up_list_print_q(), except that no linebreaks are
printed between questions, allowing for the popup list to be placed in the
middle of the text of a problem.

=cut

# To put pop-up-list in the middle of a question.
# contributed by Mark Schmitt 3-6-03

# ^function ans_in_middle_pop_up_list_print_q

sub ans_in_middle_pop_up_list_print_q {
    my $self = shift;
    my (@questions) = @_;
    my $length = $self->{ans_rule_len};
    my @list = @{$self->{ra_pop_up_list} };
    my $out = "";

	if ($main::displayMode eq 'HTML_MathJax'
	 || $main::displayMode eq 'HTML_dpng'
	 || $main::displayMode eq 'HTML'
	 || $main::displayMode eq 'HTML_tth'
	 || $main::displayMode eq 'HTML_jsMath'
	 || $main::displayMode eq 'HTML_asciimath' 
	 || $main::displayMode eq 'HTML_LaTeXMathML'
	 || $main::displayMode eq 'HTML_img') {
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

=item units_list_print_q

A simple popup question printer. No question text is printed, instead the
pop_up_list contents only are printed as a popup menu.

=cut

# Units for physics class
# contributed by Mark Schmitt 3-6-03

# ^function units_list_print_q

sub units_list_print_q {
    my $self = shift;
    my (@questions) = @_;
    my $length = $self->{ans_rule_len};
    my @list = @{$self->{ra_pop_up_list} };
    my $out = '';

	$out.= pop_up_list(@list);

    $out;
}

=back

=cut

################################################################################

=head2 Answer printing subroutines

=over

=item std_print_a

 # $list can be a matching list, a select list, or a multiple choice list
 $list->rf_print_a(~~&std_print_a);
 TEXT($list->print_a);

This simple formatting routine is the default method for formatting the answers
for matching lists.  It lists the answers vertically lettered sequentially.

=cut

#Standard method of printing answers in a matching list
# ^function std_print_a
sub std_print_a {
	my $self = shift;
	my(@array) = @_;
	my $i = 0;
	my @alpha = ('A'..'Z', 'AA'..'ZZ');
	my $letter;
	my	$out= 	&main::M3(
					"\\begin{enumerate}\n",
					" \\begin{rawhtml} <OL TYPE=\"A\" VALUE=\"1\"> \\end{rawhtml} ",
					# kludge to fix IE/CSS problem
					#"<OL COMPACT TYPE=\"A\" START=\"1\">\n"
					"<BLOCKQUOTE>\n"
	) ;
	my $elem;
	foreach $elem (@array) {
		$letter = shift @alpha;
		$out .= &main::M3(
					"\\item[$main::ALPHABET[$i].] $elem\n",
					" \\begin{rawhtml} <LI> \\end{rawhtml} $elem  ",
					#"<LI> $elem</LI>\n"
					"<br /> <b>$letter.</b> $elem\n"
		) ;
		$i++;
	}
	$out .= &main::M3(
				"\\end{enumerate}\n",
				" \\begin{rawhtml} </OL>\n \\end{rawhtml} ",
				#"</OL>\n"
				"</BLOCKQUOTE>\n"
	) ;
	$out;

}

=item radio_print_a()

 # $list can be a matching list, a select list, or a multiple choice list
 $list->rf_print_q(~~&radio_print_q);
 TEXT($list->print_q);

This simple printing routine is used to print the answers to multiple choice
questions in a bulleted style with radio buttons preceding each possible answer.
When a multiple choice object is created, a reference to radio_print_a is passed
to that object so that it can be used from within the object later.

radio_print_a checks which mode the user is trying to print the answers from and
returns the appropriately formatted string.

=cut

#Alternate method of printing answers as a list of radio buttons for multiple choice
#Method for naming radio buttons is no longer round about and hackish

# ^function radio_print_a
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

=item checkbox_print_a()

 # $list can be a matching list, a select list, or a multiple choice list
 $list->rf_print_q(~~&radio_print_q);
 TEXT($list->print_q);

This simple printing routine is used to print the answers to multiple choice
questions in a bulleted style with checkboxes preceding each possible answer.
When a multiple choice object is created, a reference to checkbox_print_a is passed
to that object so that it can be used from within the object later.

checkbox_print_a checks which mode the user is trying to print the answers from and
returns the appropriately formatted string.

=cut



# ^function checkbox_print_a
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

=back

=cut

################################################################################

=head2 Legacy macros

These are maintained for backward compatibility. They can still be useful in
constructing non-standard lists that don't fit the various list objects. In
general the using the list objects is likely to give better results and is
preferred.

=over

=item [DEPRECATED] qa()

 qa($questions, $answers, @new_qa);

$questions and $answers are references to arrays, and @new_qa is a list of
questions and answers to add to the $questions and $answers arrays.

=cut

# ^function qa   [DEPRECATED]
# 
sub qa {
	my($questionsRef,$answersRef,@questANDanswer) = @_;
	while (@questANDanswer) {
		push(@$questionsRef,shift(@questANDanswer));
		push(@$answersRef,shift(@questANDanswer));

	}
}

=item [DEPRECATED] invert()

 @b = invert(@a);

Inverts an arrays values and indexes. For example, C<invert(1,2,4,8)> returns
C<undef,0,1,undef,2,undef,undef,undef,4>.

=cut

# ^function invert   [DEPRECATED]
sub invert {
	my @array = @_;
	my @out = ();
	my $i;
	for ($i=0;$i<=$#array;$i++) {
		$out[$array[$i]]=$i;
	}
	@out;
}

=item [DEPRECATED] NchooseK()

 @b = NchooseK($N, $K);

Selects $K random nonrepeating elements in the range 0 to $N-1.

=cut

# ^function NchooseK   [DEPRECATED]

sub NchooseK {
	my($n,$k)=@_;;
	my @array = 0..($n-1);
	my @out = ();
	while (@out<$k) {
		push(@out, splice(@array,    random(0,$#array,1) ,         1) );
	}
	@out;
}

=item [DEPRECATED] shuffle()

 @b = shuffle($i);

Returns the integers from 0 to $i-1 in random order.

=cut

# ^function shuffle   [DEPRECATED]

sub shuffle {
	my ($i) = @_;
	my @out = &NchooseK($i,$i);
	@out;
}

=item [DEPRECATED] match_questions_list()

=cut

# ^function match_questions_list   [DEPRECATED]

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

=item [DEPRECATED] match_questions_list_varbox()

=cut

# ^function match_questions_list_varbox   [DEPRECATED]

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

=back

=cut

1;

