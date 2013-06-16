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

PGessaymacros.pl - Macros for building answer evaluators.

=head SYNPOSIS

Answer Evaluators:

	essay_cmp()   - 

Answer Boxes
    
        essay_box()

    To use essay answers just put an essay_box() into your problem file wherever you want the input box to go and then use essay_cmp() for the corresponding checker.  You will then need grade the problem manually.  The grader can be found in the "Detail Set List".

=cut

sub _PGessaymacros_init {
	loadMacros('PGbasicmacros.pl');   
}


sub essay_cmp {

    my $self = shift;
    my $ans = new AnswerEvaluator;

    $ans->ans_hash(
	type => "essay",
	correct_ans => "Undefined",
	correct_value => $self,
	@_,
	);

    $ans->install_evaluator(sub { 			
	my $student = shift;
	my %response_options = @_;
	### the answer needs to be sanitized.  It could currently contain badness written 
	### into the answer by the student
	my $scrubber = HTML::Scrubber->new(
	    default=> 1,
	    script => 0,
	    process => 0,
	    comment => 0
	    );
	
	$student->{original_student_ans} = $scrubber->scrub(
		(defined $student->{original_student_ans})? $student->{original_student_ans} :''
	);

	# always returns false but stuff should check for the essay flag and avoid the red highlighting
	loadMacros("contextTypeset.pl");
	my $oldContext = Context();
	Context("Typeset");
	my $answer_value = EV3P({processCommands=>0,processVariables=>0},$student->{original_student_ans});
	Context($oldContext);
	my $ans_hash = new AnswerHash(
	    'score'=>"0",
	    'correct_ans'=>"Undefined",
#	    'student_ans'=>$student->{student_ans},
	    'student_ans'=>'', #supresses output to original answer field
	    'original_student_ans' => $student->{original_student_ans},
	    'type' => 'essay',
	    'ans_message'=>'This answer will be graded at a later time.',
	    'preview_text_string'=>'',
	    'preview_latex_string'=>$answer_value,
	    );

	return $ans_hash;
			    }
	);
    
    $ans->install_pre_filter('erase') if $self->{ans_name};
    
    return $ans;
}

sub  NAMED_ESSAY_BOX {
	my($name,$row,$col) = @_;
	$row = 8 unless defined($row);
	$col = 75 unless defined($col);

	my $height = .07*$row;
	my $answer_value = '';
	$answer_value = $inputs_ref->{$name} if defined( $inputs_ref->{$name} );
	$name = RECORD_ANS_NAME($name, $answer_value);
	$answer_value =~ tr/$@//d;   #`## make sure student answers can not be interpolated by e.g. EV3

	#### Answer Value needs to have special characters replaced by the html codes
	$answer_value =~ s/\\/\&\#92;/g;
	$answer_value =~ s/</\&lt;/g; 
	$answer_value =~ s/>/\&gt;/g;
	$answer_value =~ s/`/&#96;/g;
		
	# Get rid of tabs since they mess up the past answer db
	$answer_value =~ s/\t/\&nbsp;\&nbsp;\&nbsp;\&nbsp;\&nbsp;/;

	#INSERT_RESPONSE($name,$name,$answer_value); # no longer needed?
	my $out = MODES(
	     TeX => qq!\\vskip $height in \\hrulefill\\quad !,
	     Latex2HTML => qq!\\begin{rawhtml}<TEXTAREA NAME="$name" id="$name" ROWS="$row" COLS="$col" >$answer_value</TEXTAREA>\\end{rawhtml}!,
	    HTML => qq!
         <TEXTAREA NAME="$name" id="$name" ROWS="$row" COLS="$col"
               WRAP="VIRTUAL" title="Enclose math expressions with backticks ` or use LaTeX.">$answer_value</TEXTAREA>
           <INPUT TYPE=HIDDEN  NAME="previous_$name" VALUE = "$answer_value">
           !
         );

	$out;
}

sub  essay_help {

	my $out = MODES(
	     TeX => '',
	     Latex2HTML => '',
	    HTML => qq!
            <P>  This is an essay answer text box.  You can type your answer in here and, after you hit submit, 
                 it will be saved so that your instructor can grade it at a later date.  If your instructor makes 
                 any comments on your answer those comments will appear on this page after the question has been 
                 graded.  You can use LaTeX to make your math equations look pretty.   
                 LaTeX expressions should be enclosed using the parenthesis notation and not dollar signs. 
            </P> 
           !
         );

	$out;
}


sub essay_box {
	my $row = shift;
	my $col =shift;
	$row = 8 unless $row;
	$col = 75 unless $col;
	my $name = NEW_ANS_NAME();
	NAMED_ESSAY_BOX($name ,$row,$col);

}

1;
