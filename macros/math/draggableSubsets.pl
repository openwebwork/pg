################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2022 The WeBWorK Project, https://github.com/openwebwork
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

draggableSubsets.pl

=head1 DESCRIPTION

This macro helps the instructor create a drag-and-drop environment in which a
pre-specified set of elements may be dragged to different "buckets", effectively
partitioning the original set into subsets.

=head1 TERMINOLOGY

An HTML element into or out of which other elements may be dragged will be
called a "bucket".

An HTML element which houses a collection of buckets will be called a "bucket
pool".

=head1 USAGE

To initialize a C<DraggableSubset> bucket pool in a .pg problem, insert the line

    $draggable = DraggableSubsets(
        $full_set,
        $answer_sets,
        option1 => $value1,
        option2 => $value2,
        ...
    );

Then insert the draggable subset bucket pool into the problem text with

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

    \{$draggable->Print\} (or [@ $draggable->Print @]* for PGML)

within the BEGIN_TEXT / END_TEXT (or BEGIN_PGML / END_PGML ) environment.
Then call

    ANS($draggable->cmp)

after END_TEXT (or END_PGML).

$full_set, e.g. ["statement1", "statement2", ...], is an array reference to the
list of elements, given as strings, in the original full set.

$answer_sets, e.g. [[1, 2, 3], [4, 5], ...], is an array reference to a list of
array references corresponding to the correct answer which is a set of subsets.
Each subset element is specified via the index of the element in the $full_set,
with the first element having index 0.

Available Options:

    DefaultSubsets    => <array reference>
    OrderedSubsets    => 0 or 1
    AllowNewBuckets   => 0 or 1
    BucketLabelFormat => <string>
    ResetButtonText   => <string>
    AddButtonText     => <string>
    RemoveButtonText  => <string>

Their usage is demonstrated in the example below.

=head1 EXAMPLE

    DOCUMENT();
    loadMacros(
        'PGstandard.pl',
        'PGML.pl',
        'MathObjects.pl',
        'draggableSubsets.pl'
    );

    $draggable = DraggableSubsets(
        # Full set.  Make sure to use "\(...\)" for math and not "`...`" for correct display.
        [
            "\(e\)",    # index 0
            "\(r\)",    # index 1
            "\(r^2\)",  # index 2
            "\(s\)",    # index 3
            "\(sr\)",   # index 4
            "\(sr^2\)", # index 5
        ],

        # Reference to array of arrays of indices, corresponding to
        # the correct set of subsets.
        [ [0, 3], [1, 4], [2, 5] ],

        # Default instructor-provided subsets.
        # The default value if not given is [] which is interpreted to mean that
        # the full set will be the only subset initially shown.
        DefaultSubsets => [
            {
                # Label of the bucket.
                label     => 'coset 1',
                # Specifies pre-included elements in the bucket via their indices.
                indices   => [ 1, 3, 4, 5 ],
                # Specifies whether student may remove bucket.
                removable => 0
            },
            {
                label     => 'coset 2',
                indices   => [ 0 ],
                removable => 1
            },
            {
                label     => 'coset 3',
                indices   => [ 2 ],
                removable => 1
            }
        ],

        # 0 means order of subsets does not matter. 1 means otherwise.
        # (The order of elements within each subset never matters.)
        # The default value if not given is 0.
        OrderedSubsets => 0,

        # 0 means no new buckets may be added by student. 1 means otherwise.
        # The default value if not given is 1.
        AllowNewBuckets => 1,

        # If this option is defined then labels for buckets for which a specific
        # label is not provided will be created by replacing %s with the bucket
        # number to this prefix.  These labels will also be used for buckets
        # added by the user if AllowNewBuckets is 1.  This string should contain
        # exactly one instance of %s.  The default value if not given is
        # undefined.
        BucketLabelFormat => 'Subset %s'

        # This is the text label for the button shown that resets the drag and
        # drop element to its default state.  The default value if not given is
        # "Reset".
        ResetButtonText => 'zurücksetzen'

        # This is the text label for the button shown that adds new buckets.
        # The button is only shown if AllowNewBuckets is 1.
        # The default value if not given is "Add Bucket".
        AddButtonText => 'Add Subset'

        # This is the text label for the remove button that is added to any
        # removable buckets.  The default value if not given is "Remove".
        RemoveButtonText => 'Delete'

        # These are options that will be passed to the $draggable->cmp method.
        cmpOptions => { checker => sub { ... } }
    );

    BEGIN_PGML
    Let [``G = D_3 = \{ e, r, r^2, s, sr, sr^2 \}``] be the Dihedral group of
    order [`6`], where [`r`] is counter-clockwise rotation by [`2\pi/3`], and
    [`s`] is the reflection across the [`x`]-axis.

    Partition [`G = D_3`] into *right* cosets of the subgroup
    [`H = \{ e, s \}`].

    Give your result by dragging the following elements into separate buckets,
    each corresponding to a coset.

    [_]{$draggable}
    END_PGML

    ENDDOCUMENT();

=head1 CUSTOM CHECKERS

A custom checkers can also be used by passing the C<list_checker> option to the
C<cmp> method.  See L<https://webwork.maa.org/wiki/Custom_Answer_Checkers_for_Lists>
for details on how to use a custom list checker.  This follows the usual rules
for the return value of the C<list_checker> method.

Note that the correct and student answers will be Perl arrays containing
MathObject Lists corresponding to all buckets in the answer.

=cut

loadMacros('MathObjects.pl');

sub _draggableSubsets_init {
	ADD_JS_FILE('node_modules/sortablejs/Sortable.min.js', 0, { defer => undef });
	ADD_CSS_FILE('js/apps/DragNDrop/dragndrop.css', 0);
	ADD_JS_FILE('js/apps/DragNDrop/dragndrop.js', 0, { defer => undef });
	PG_restricted_eval('sub DraggableSubsets {parser::DraggableSubsets->new(@_)}');
	return;
}

package parser::DraggableSubsets;
our @ISA = qw(Value::List);

sub new {
	my ($invocant, $set, $subsets, %options) = @_;

	my $base = bless {
		set               => $set,
		DefaultSubsets    => [],
		OrderedSubsets    => 0,
		AllowNewBuckets   => 1,
		cmpOptions        => {},
		BucketLabelFormat => undef,
		ResetButtonText   => 'Reset',
		AddButtonText     => 'Add Bucket',
		RemoveButtonText  => 'Remove',
		%options
		},
		ref($invocant) || $invocant;

	$base->{order} = do {
		my @indices = 0 .. $#{ $base->{set} };
		[ map { splice(@indices, main::random(0, $#indices), 1) } @indices ];
	};
	@{ $base->{unorder} }[ @{ $base->{order} } ] = 0 .. $#{ $base->{order} };

	$base->{shuffledSet} = [ map { $base->{set}[$_] } @{ $base->{order} } ];

	my $context = Parser::Context->getCopy('Numeric');
	$context->parens->set(
		'(' => { close => ')', type => 'List', formList => 1, formMatrix => 0, removable => 0 },
		'{' => { close => '}', type => 'Set',  formList => 0, formMatrix => 0, removable => 0, emptyOK => 1 }
	);
	$context->lists->set(
		'DraggableSubsets' => {
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
		map {
			my $subset = $_;
			'{' . join(',', map { $base->{unorder}[$_] } @$subset) . '}'
		} @$subsets
	);
	$self->{$_} = $base->{$_} for keys %$base;

	return $self;
}

sub type { return 'List' }

sub ANS_NAME {
	my $self = shift;
	$self->{answer_name} = main::NEW_ANS_NAME() unless defined $self->{answer_name};
	return $self->{answer_name};
}

# Deprecated alias for ans_rule.
sub Print { return shift->ans_rule; }

sub ans_rule {
	my $self = shift;

	my @buckets;
	if (@{ $self->{DefaultSubsets} }) {
		for my $bucket (@{ $self->{DefaultSubsets} }) {
			push(
				@buckets,
				{
					label     => $bucket->{label},
					indices   => [ map { $self->{unorder}[$_] } @{ $bucket->{indices} } ],
					removable => $bucket->{removable},
				}
			);
		}
	} else {
		push(@buckets, { label => '', indices => [ 0 .. $#{ $self->{set} } ] });
	}

	$self->{dnd} = DragNDrop->new(
		$self->ANS_NAME, $self->{shuffledSet}, \@buckets,
		allowNewBuckets   => $self->{AllowNewBuckets},
		bucketLabelFormat => $self->{BucketLabelFormat},
		resetButtonText   => $self->{ResetButtonText},
		addButtonText     => $self->{AddButtonText},
		removeButtonText  => $self->{RemoveButtonText}
	);

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
		ordered           => $self->{OrderedSubsets},
		implicitList      => 0,
		requireParenMatch => 0,
		entry_type        => 'subset'
	);
}

sub cmp {
	my ($self, %options) = @_;
	return $self->SUPER::cmp(%{ $self->{cmpOptions} }, %options);
}

sub TeX {
	my $self = shift;

	return join(
		',',
		map {
			"\\{\\text{"
				. join(',', map { $self->{shuffledSet}[$_] } @{ $_->{data} }) . "}\\}"
		} @{ $self->{data} }
	);
}

sub cmp_preprocess {
	my ($self, $ans) = @_;

	if (defined $ans->{student_value}) {
		$ans->{student_ans} = '(see preview)';

		# Note the grep is for backwards compatibility.  Previously the empty set was stored as (-1).
		# Now it is stored as {}.
		$ans->{preview_latex_string} = join(
			',',
			map {
				"\\{\\text{"
					. join(',', map { $self->{shuffledSet}[$_] } grep { $_ >= 0 } @{ $_->{data} }) . "}\\}"
			} @{ $ans->{student_value}{data} }
		);
	}

	return;
}

1;
