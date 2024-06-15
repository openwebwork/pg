################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2024 The WeBWorK Project, https://github.com/openwebwork
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

PGessaymacros.pl - Macros for building answer evaluators.

=head2 SYNPOSIS

Answer Evaluators:

    essay_cmp()

Answer Boxes:

    essay_box()

To use essay answers call C<essay_box()> in your problem file wherever you want
the input box to go, and then use C<essay_cmp()> for the corresponding checker.
You will then need to grade the problem manually.

    explanation_box()

Like an C<essay_box()>, except that it can be turned off at a configuration
level.  This is intended for two-part questions where the first answer is
automatically assessible, and the second part is an explanation or "show your
work" type answer. An instructor may want to turn these off to use the problem
but without the manual grading component. These necessarily supply their own
C<essay_cmp()>.

=cut

sub _PGessaymacros_init {
	loadMacros('PGbasicmacros.pl', 'text2PG.pl');
}

sub essay_cmp {
	my (%options) = @_;
	my $ans = AnswerEvaluator->new;

	$ans->ans_hash(
		type             => 'essay',
		correct_ans      => 'Undefined',
		correct_value    => '',
		scaffold_force   => 1,
		feedback_options => sub {
			my ($ansHash, $options) = @_;

			$options->{manuallyGraded} = 1;

			if ($envir{needs_grading}
				|| !defined $ansHash->{ans_label}
				|| !defined $inputs_ref->{"previous_$ansHash->{ans_label}"}
				|| $inputs_ref->{ $ansHash->{ans_label} } ne $inputs_ref->{"previous_$ansHash->{ans_label}"})
			{
				$options->{needsGrading} = 1;
				$options->{resultTitle}  = maketext('Ungraded');
			} else {
				$options->{resultTitle} = maketext('Graded');
				$ansHash->{ans_message} = '';
			}

			$options->{resultClass}      = '';
			$options->{insertMethod}     = 'append_content';
			$options->{btnClass}         = 'btn-info';
			$options->{btnAddClass}      = '';
			$options->{wrapPreviewInTex} = 0;
			$options->{showEntered}      = 0;                  # Suppress output of the feedback entered answer.
			$options->{showCorrect}      = 0;                  # Suppress output of the feedback correct answer.
		},
		%options,
	);

	$ans->install_evaluator(sub {
		my $ans_hash = shift;

		$ans_hash->{original_student_ans} //= '';
		$ans_hash->{_filter_name}        = 'Essay Check';
		$ans_hash->{score}               = 0;
		$ans_hash->{ans_message}         = maketext('This answer will be graded at a later time.');
		$ans_hash->{preview_text_string} = '';

		loadMacros('contextTypeset.pl');
		my $oldContext = Context();
		Context('Typeset');
		$ans_hash->{preview_latex_string} =
			EV3P({ processCommands => 0, processVariables => 0 }, text2PG($ans_hash->{original_student_ans}));
		Context($oldContext);

		return $ans_hash;
	});

	return $ans;
}

sub NAMED_ESSAY_BOX {
	my ($name, $row, $col) = @_;
	$row //= 8;
	$col //= 75;

	my $height       = .07 * $row;
	my $answer_value = $inputs_ref->{$name} // '';
	$name = RECORD_ANS_NAME($name, $answer_value);

	# Get rid of tabs since they mess up the past answer db.
	# FIXME: This fails because this only modifies the value for the next submission.
	# It doesn't change the value in the already submitted form.
	$answer_value =~ s/\t/\&nbsp;\&nbsp;\&nbsp;\&nbsp;\&nbsp;/;

	return MODES(
		TeX  => qq!\\vskip $height in \\hrulefill\\quad !,
		HTML => tag(
			'textarea',
			name       => $name,
			id         => $name,
			aria_label => generate_aria_label($name),
			rows       => $row,
			cols       => $col,
			class      => 'latexentryfield',
			title      => 'Enclose math expressions with backticks or use LaTeX.',
			# Answer Value needs to have special characters replaced by the html codes
			encode_pg_and_html($answer_value)
			)
			. tag(
				'div',
				class                        => 'latexentry-button-container d-flex gap-2 mt-2',
				id                           => "$name-latexentry-button-container",
				data_feedback_insert_element => $name,
				tag(
					'button',
					class => 'latexentry-preview btn btn-secondary btn-sm',
					type  => 'button',
					maketext('Preview')
				)
			)
			. tag('input', type => 'hidden', name => "previous_$name", value => $answer_value),
		PTX => '<var form="essay" width="' . $col . '" height="' . $row . '" />',
	);
}

sub essay_help {
	return MODES(
		TeX  => '',
		HTML => tag(
			'p',
			maketext(
				'This is an essay answer text box. You can type your answer in here and, after you hit submit, '
					. 'it will be saved so that your instructor can grade it at a later date. If your instructor '
					. 'makes any comments on your answer those comments will appear on this page after the question '
					. 'has been graded. You can use LaTeX to make your math equations look pretty. '
					. 'LaTeX expressions should be enclosed using the parenthesis notation and not dollar signs.'
			)
		),
		PTX => '',
	);
}

sub essay_box {
	my ($row, $col) = @_;
	$row ||= 8;
	$col ||= 75;
	my $name = NEW_ANS_NAME();
	main::RECORD_IMPLICIT_ANS_NAME($name);
	NAMED_ESSAY_BOX($name, $row, $col);

}

# Makes an essay box and calls essay_cmp()
# Can be turned off using $pg{specialPGEnvironmentVars}{waiveExplanations}
# Takes options:
#   row (or height): height of essay box; defaults to 8
#   col (or width):  width of essay box;  defaults to 75
#   message: a message preceding the essay box; default is 'Explain.'
#   help: boolean for whether to display the essay help message; default is true
sub explanation_box {
	my %options = @_;

	if ($envir{waiveExplanations}) {
		return '';
	} else {
		ANS(essay_cmp());
		return
			($options{message} // 'Explain.')
			. $PAR
			. essay_box($options{row} // $options{height} // 8, $options{col} // $options{width} // 75)
			. (($options{help} // 1) ? essay_help() : '');
	}
}

1;
