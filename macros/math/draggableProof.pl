################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2023 The WeBWorK Project, https://github.com/openwebwork
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

=encoding utf8

=head1 NAME

draggableProof.pl

=head1 DESCRIPTION

This macro helps the instructor create a drag-and-drop environment in which
students are asked to arrange predefined statements into a correct sequence.

=head1 TERMINOLOGY

An HTML element into or out of which other elements may be dragged will be
called a "bucket".

An HTML element which houses a collection of buckets will be called a "bucket
pool".

=head1 USAGE

To initialize a C<DraggableProof> bucket pool in a .pg problem, insert the line:

    $draggable = DraggableProof(
        $statements,
        $extra_statements,
        option1 => $value1,
        option2 => $value2,
        ...
    );

Then insert the draggable proof bucket pool into the problem text with

    BEGIN_TEXT
    \{$draggable->ans_rule\}
    END_TEXT

for basic PG, or

    BEGIN_PGML
    [_]{$draggable}
    END_PGML

for PGLM.  Note the following also works, but is deprecated.  However, if you
want your problem to be compatible with previous versions of PG this must be
used.  Call

    \{$draggable->Print\} (or [@ $draggable->Print @]* )

within the BEGIN_TEXT / END_TEXT (or BEGIN_PGML / END_PGML ) environment.
Then call

    ANS($draggable->cmp)

after END_TEXT (or END_PGML).

C<$statements>, e.g. ["Socrates is a man.", "Socrates is mortal.", ...], is an
array reference to the list of statements used in the correct proof.

C<$extra_statements>, e.g. ["Roses are red."], is an array reference to the list
statements extraneous to the proof.  If there are no extraneous statements, use
the empty array reference [].

By default, the score of the student answer is 100% if the draggable statements
are placed in the exact same order as in the array referenced by C<$statements>,
with no inclusion of any statement from C<$extra_statements>. The score is 0%
otherwise.

Available Options:

    NumBuckets         => 1 or 2
    SourceLabel        => <string>
    TargetLabel        => <string>
    Levenshtein        => 0 or 1
    DamerauLevenshtein => 0 or 1
    InferenceMatrix    => <array reference>
    IrrelevancePenalty => <float>
    ResetButtonText    => <string>

Their usage is explained in the example below.

=head1 EXAMPLE

    DOCUMENT();
    loadMacros(
        'PGstandard.pl',
        'PGML.pl',
        'MathObjects.pl',
        'draggableProof.pl'
    );

    $draggable = DraggableProof(
        # The proof given in the correct order.
        [
            'All men are mortal.', # index 0
            'Socrates is a man.',  # index 1
            'Socrates is mortal.'  # index 2
        ],

        # Extra statements that are not part of the correct answer.
        [
            'Some animals are men.',
            'Beauty is immortal.',
            'Not all animals are men.'
        ],

        # Number of drag and drop buckets.  Must be either 1 or 2.
        # The default value if not given is 2.
        NumBuckets => 2,

        # Label of first bucket if NumBuckets = 2.
        # The default value if not given is 'Choose from these sentences:'
        SourceLabel => "${BBOLD}Axioms${EBOLD}",

        # Label of second bucket if NumBuckets = 2,
        # or of the only bucket if NumBuckets = 1.
        # The default value if not given is 'Your Proof:'.
        TargetLabel => "${BBOLD}Reasoning${EBOLD}",

        # If equal to 1, scoring is determined by the Levenshtein edit distance
        # between student answer and correct answer.
        # The default value if not given is 0.
        Levenshtein => 1,

        # If equal to 1, scoring is determined by the Damerau-Levenshtein
        # distance between student answer and correct answer.  A pair of
        # transposed adjacent statements is counted as two mistakes under
        # Levenshtein scoring, but as one mistake under Damerau-Levenshtein
        # scoring.
        # The default value if not given is 0.
        DamerauLevenshtein => 1,

        # (i, j)-entry is nonzero <=> statement i implies statement j.  The
        # score of each corresponding inference is weighted according to the
        # value of the matrix entry.
        # The default value if not given is [].
        InferenceMatrix => [
            [0, 0, 1],
            [0, 0, 1],
            [0, 0, 0]
        ],

        # This option is processed only if the InferenceMatrix option is set.
        # Penalty for each extraneous statement in the student answer is
        # <IrrelevancePenalty> divided by the total number of inference points
        # (i.e. sum of all entries in the InferenceMatrix).
        # The default value if not given is 1.
        IrrelevancePenalty => 1

        # This is the text label for the button shown that resets the drag and
        # drop element to its default state.  The default value if not given is
        # "Reset".
        ResetButtonText => 'zurücksetzen'

        # These are options that will be passed to the $draggable->cmp method.
        cmpOptions => { checker => sub { ... } }
    );

    BEGIN_PGML
    Show that Socrates is mortal by dragging the relevant *Axioms* into the
    *Reasoning* box in an appropriate order.

    [_]{$draggable}
    END_PGML

    ENDDOCUMENT();

=head1 CUSTOM CHECKERS

Custom checkers can also be used by passing the C<checker> or C<list_checker>
options to the C<cmp> method.  See
L<https://webwork.maa.org/wiki/Custom_Answer_Checkers>, and
L<https://webwork.maa.org/wiki/Custom_Answer_Checkers_for_Lists> for details on
how to use these.

Note that if using a standard C<checker> the the correct and student answers
will be the MathObject List of indices corresponding to the only bucket if
C<NumBuckets> is 1, and will be the MathObject List of indices corresponding to
the second bucket if C<NumBuckets> is 2.  The checker should return a number
between 0 and 1 inclusive.

For a C<list_checker> the correct and student answers will be perl arrays
containing MathObject Lists for all buckets.  So if C<NumBuckets> is 1, the
arrays will only contain one list corresponding to the only bucket, and if
C<NumBuckets> is 2, the arrays will contain two lists corresponding to the two
buckets.  Usually the first (source) list is ignored for grading if
C<NumBuckets> is 2.  So if you want to determine the score using both buckets
this is the only option.  Note that the checker should return a number
between 0 and 1 inclusive regardless of the number of buckets.

=cut

loadMacros('PGchoicemacros.pl', 'MathObjects.pl');

sub _draggableProof_init {
	ADD_JS_FILE('node_modules/sortablejs/Sortable.min.js', 0, { defer => undef });
	ADD_CSS_FILE('js/DragNDrop/dragndrop.css', 0);
	ADD_JS_FILE('js/DragNDrop/dragndrop.js', 0, { defer => undef });
	PG_restricted_eval('sub DraggableProof {parser::DraggableProof->new(@_)}');
	return;
}

package parser::DraggableProof;
our @ISA = qw(Value::List);

sub new {
	my ($invocant, $statements, $extra_statements, %options) = @_;

	my $base = {
		SourceLabel        => 'Choose from these sentences:',
		TargetLabel        => 'Your Proof:',
		NumBuckets         => 2,
		lines              => [ @$statements, @$extra_statements ],
		numNeeded          => scalar(@$statements),
		ResetButtonText    => 'Reset',
		cmpOptions         => {},
		Levenshtein        => 0,
		DamerauLevenshtein => 0,
		InferenceMatrix    => [],
		IrrelevancePenalty => 1,
		%options
	};

	$base->{order} = do {
		my @indices = 0 .. $#{ $base->{lines} };
		[ map { splice(@indices, main::random(0, $#indices), 1) } @indices ];
	};
	@{ $base->{unorder} }[ @{ $base->{order} } ] = 0 .. $#{ $base->{order} };

	$base->{shuffledLines} = [ map { $base->{lines}[$_] } @{ $base->{order} } ];

	my $context = Parser::Context->getCopy('Numeric');
	$context->parens->set(
		'(' => { close => ')', type => 'List', formList => 1, formMatrix => 0, removable => 0 },
		'{' => { close => '}', type => 'List', formList => 1, formMatrix => 0, removable => 0, emptyOK => 1 }
	);
	$context->lists->set(
		'DraggableProof' => {
			class       => 'Parser::List::List',
			open        => '(',
			close       => ')',
			separator   => ', ',
			nestedOpen  => '{',
			nestedClose => '}'
		}
	);

	my $self = $invocant->SUPER::new(
		$context,
		$base->{NumBuckets} == 2
		? (
			'{' . join(', ', @{ $base->{unorder} }[ $base->{numNeeded} .. $#{ $base->{lines} } ]) . '}',
			'{' . join(', ', @{ $base->{unorder} }[ 0 .. $base->{numNeeded} - 1 ]) . '}'
			)
		: '{' . join(', ', @{ $base->{unorder} }[ 0 .. $base->{numNeeded} - 1 ]) . '}'
	);
	$self->{$_} = $base->{$_} for keys %$base;

	$self->{extra_statements} = [ @{ $self->{unorder} }[ $self->{numNeeded} .. $#{ $self->{lines} } ] ];

	return $self;
}

sub ANS_NAME {
	my $self = shift;
	$self->{answer_name} = main::NEW_ANS_NAME() unless defined $self->{answer_name};
	return $self->{answer_name};
}

sub lines       { return @{ shift->{lines} } }
sub numNeeded   { return shift->{numNeeded} }
sub numProvided { return scalar shift->lines }
sub order       { return @{ shift->{order} } }
sub unorder     { return @{ shift->{unorder} } }

# Deprecated alias for ans_rule.
sub Print { return shift->ans_rule; }

sub ans_rule {
	my $self = shift;

	if ($self->{NumBuckets} == 2) {
		$self->{dnd} = DragNDrop->new(
			$self->ANS_NAME,
			$self->{shuffledLines},
			[
				{ indices => [ 0 .. $#{ $self->{lines} } ], label => $self->{SourceLabel} },
				{ indices => [],                            label => $self->{TargetLabel} }
			],
			resetButtonText => $self->{ResetButtonText}
		);
	} elsif ($self->{NumBuckets} == 1) {
		$self->{dnd} = DragNDrop->new(
			$self->ANS_NAME,
			$self->{shuffledLines},
			[ { indices => [ 0 .. $#{ $self->{lines} } ], label => $self->{TargetLabel} } ],
			resetButtonText => $self->{ResetButtonText}
		);
	}

	my $ans_rule = main::NAMED_HIDDEN_ANS_RULE($self->ANS_NAME);
	if ($main::displayMode eq 'TeX') {
		return $self->{dnd}->TeX;
	} else {
		return '<div>' . $ans_rule . $self->{dnd}->HTML . '</div>';
	}
}

sub cmp_defaults {
	my ($self, %options) = @_;
	return (
		$self->SUPER::cmp_defaults(%options),
		ordered   => 1,
		list_type => 'statement',
	);
}

sub cmp {
	my ($self, %options) = @_;
	return $self->SUPER::cmp(%{ $self->{cmpOptions} }, %options);
}

sub cmp_preprocess {
	my ($self, $ans) = @_;

	if (defined $ans->{student_value}) {
		my @student = @{ $ans->{student_value}{data}[ $self->{NumBuckets} - 1 ]{data} };

		$ans->{student_ans} = @student ? '(see preview)' : '';

		$ans->{preview_latex_string} =
			"\n\\begin{array}{l}\n"
			. ($main::displayMode eq 'TeX' ? "\\\\[-10pt]\n" : '')
			. join(
				"\n", map {"\\bullet\\;\\; \\text{$_} \\\\"}
				map { $self->{lines}[ $self->{order}[$_] ] } @student
			)
			. ($main::displayMode eq 'TeX' ? "\n\\\\[-10pt]" : '')
			. "\n\\end{array}\n";
	}

	return;
}

sub string {
	return '';
}

sub TeX {
	my $self = shift;

	return
		"\n\\begin{array}{l}\n"
		. ($main::displayMode eq 'TeX' ? "\\\\[-10pt]\n" : '')
		. join("\n",
			map {"\\bullet\\;\\; \\text{$self->{lines}[ $self->{order}[$_] ]} \\\\"}
			@{ $self->{data}[ $self->{NumBuckets} == 2 ? 1 : 0 ]{data} })
		. ($main::displayMode eq 'TeX' ? "\n\\\\[-10pt]" : '')
		. "\n\\end{array}\n";
}

sub cmp_equal {
	my ($self, $ans) = @_;

	if ($self->{Levenshtein} == 1) {
		$ans->{score} = 1 - main::min(
			1,
			Levenshtein(
				$ans->{correct_value}{data}[ $self->{NumBuckets} - 1 ],
				$ans->{student_value}{data}[ $self->{NumBuckets} - 1 ],
			) / $self->{numNeeded}
		);
	} elsif ($self->{DamerauLevenshtein} == 1) {
		$ans->{score} = 1 - main::min(
			1,
			DamerauLevenshtein(
				$ans->{correct_value}{data}[ $self->{NumBuckets} - 1 ],
				$ans->{student_value}{data}[ $self->{NumBuckets} - 1 ],
				scalar(@{ $self->{lines} })
			) / ($self->{numNeeded})
		);
	} elsif (@{ $self->{InferenceMatrix} } != 0) {
		my @unshuffledStudentIndices =
			map { $self->{order}[$_] } $ans->{student_value}{data}[ $self->{NumBuckets} - 1 ]->value;
		my @inferenceMatrix = @{ $self->{InferenceMatrix} };
		my $inferenceScore  = 0;
		for (my $j = 0; $j < @unshuffledStudentIndices; $j++) {
			if ($unshuffledStudentIndices[$j] < $self->{numNeeded}) {
				for (my $i = $j - 1; $i >= 0; $i--) {
					if ($unshuffledStudentIndices[$i] < $self->{numNeeded}) {
						$inferenceScore +=
							$inferenceMatrix[ $unshuffledStudentIndices[$i] ][ $unshuffledStudentIndices[$j] ];
					}
				}
			}
		}
		my $total = 0;
		for my $row (@inferenceMatrix) {
			for (@$row) {
				$total += $_;
			}
		}
		$ans->{score} = $inferenceScore / $total;

		my %invoked = map { $_ => 1 } $ans->{student_value}{data}[ $self->{NumBuckets} - 1 ]->value;
		for (@{ $self->{extra_statements} }) {
			if (exists($invoked{$_})) {
				$ans->{score} = main::max(0, $ans->{score} - $self->{IrrelevancePenalty} / $total);
			}
		}
	} else {
		my ($score, @errors);

		if (ref($ans->{list_checker}) eq 'CODE') {
			eval {
				($score, @errors) =
					&{ $ans->{list_checker} }([ $self->value ], [ $ans->{student_value}->value ], $ans, 'a proof');
			};
			if (!defined($score)) {
				die $@                 if $@ ne '' && $self->{context}{error}{flag} == 0;
				$self->cmp_error($ans) if $self->{context}{error}{flag};
			}
		} else {
			($score, @errors) = $self->cmp_list_compare(
				[ $self->data->[ $self->{NumBuckets} - 1 ] ],
				[ $ans->{student_value}{data}[ $self->{NumBuckets} - 1 ] ],
				$ans, 'a proof'
			);
		}
		return unless defined $score;

		$ans->score($score);
		$ans->{error_message} = $ans->{ans_message} = join("\n", @errors);
	}

	return;
}

sub Levenshtein {
	my ($correct, $student) = @_;

	my @ar1 = $correct->value;
	my @ar2 = $student->value;

	my @dist = ([ 0 .. @ar2 ]);
	$dist[$_][0] = $_ for (1 .. @ar1);

	for my $i (0 .. $#ar1) {
		for my $j (0 .. $#ar2) {
			$dist[ $i + 1 ][ $j + 1 ] =
				main::min($dist[$i][ $j + 1 ] + 1, $dist[ $i + 1 ][$j] + 1, $dist[$i][$j] + ($ar1[$i] ne $ar2[$j]));
		}
	}
	return $dist[-1][-1];
}

# Damerau-Levenshtein distance with adjacent transpositions.
# https://en.wikipedia.org/wiki/Damerau-Levenshtein_distance
sub DamerauLevenshtein {
	my ($correct, $student, $numProvided) = @_;

	my @ar1 = $correct->value;
	my @ar2 = $student->value;

	my @da = (0) x $numProvided;
	my @d  = ();

	my $maxdist = @ar1 + @ar2;
	for my $i (1 .. @ar1 + 1) {
		push(@d, [ (0) x (@ar2 + 2) ]);
		$d[$i][0] = $maxdist;
		$d[$i][1] = $i - 1;
	}
	for my $j (1 .. @ar2 + 1) {
		$d[0][$j] = $maxdist;
		$d[1][$j] = $j - 1;
	}
	my $db;
	for my $i (2 .. @ar1 + 1) {
		$db = 0;
		my ($k, $l, $cost);
		for my $j (2 .. @ar2 + 1) {
			$k = $da[ $ar2[ $j - 2 ] ];
			$l = $db;
			if ($ar1[ $i - 2 ] == $ar2[ $j - 2 ]) {
				$cost = 0;
				$db   = $j;
			} else {
				$cost = 1;
			}
			$d[$i][$j] = main::min(
				$d[ $i - 1 ][ $j - 1 ] + $cost,
				$d[$i][ $j - 1 ] + 1,
				$d[ $i - 1 ][$j] + 1,
				$d[ $k - 1 ][ $l - 1 ] + ($i - $k - 1) + 1 + ($j - $l - 1)
			);
		}
		$da[ $ar1[ $i - 2 ] ] = $i;
	}
	return $d[-1][-1];
}

1;
