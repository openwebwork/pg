
=head1 NAME

DragNDrop.pm - Drag-N-Drop Module

=head1 DESCRIPTION

DragNDrop.pm is a module which facilitates the implementation of 'Drag-And-Drop'
in WeBWorK problems. It is meant to be used by other macros such as
draggableProof.pl and draggableSubsets.pl

=head1 TERMINOLOGY

An HTML element into or out of which other elements may be dragged will be
called a "bucket".

An HTML element which houses a collection of buckets will be called a "bucket
pool".

=head1 USAGE

Each macro aiming to implement drag-n-drop features must call at its
initialization:

    ADD_JS_FILE('node_modules/sortablejs/Sortable.min.js', 0, { defer => undef });
    ADD_CSS_FILE('js/DragNDrop/dragndrop.css', 0);
    ADD_JS_FILE('js/DragNDrop/dragndrop.js', 0, { defer => undef });
    PG_restricted_eval('sub DraggableSubsets {draggableSubsets->new(@_)}');

To initialize a bucket pool call the constructor. For example,

    my $dnd = new DragNDrop($answerName, $itemList);

$answerName is the HTML input 'name' for the corresponding answer.  It should be
generated with NEW_ANS_NAME.

$itemList is a reference to an array containing the HTML content of the
draggable items.

For example,

    $itemList = [
        'socrates is a man',
        'all men are mortal',
        'therefore socrates is mortal'
    ];

=head2 OPTIONS

There are a few options that you can supply to control the appearance and
behavior of the C<DragNDrop> JavaScript output, listed below.  These are set as
additional options to the constructor.  For example,

    DragNDrop($answerName, $itemList, allowNewBuckets => 1);

=over

=item allowNewBuckets (Default: C<0>)

If this is set to 1 then a button is added to the HTML output which adds a new
drag and drop bucket when clicked on.

=item bucketLabelFormat (Default: C<undef>)

If the C<bucketLabelFormat> option is defined, then buckets for which an
explicit label is not provided will be will be created with the label with the
C<%s> in the string replaced with the bucket number in the pool.  This also
applies to new buckets that are added by the user via JavaScript if
C<allowNewBuckets> is 1.  An example value for this option is C<'Subset %s'>.

=item resetButtonText (Default: C<< 'Reset' >>)

This is the text label for the reset button.

=item addButtonText (Default: C<< 'Add Bucket' >>)

This is the text label for the button shown that adds new buckets.  The button
is only shown if AllowNewBuckets is 1.

=item removeButtonText (Default: C<< 'Remove' >>)

This is the text label for any remove buttons that are added to removable
buckets.

=item multicolsWidth (Default: C<< '300pt' >>)

This sets the size for which the TeX output for hardcopy uses two columns or not.
If the current C<\linewidth> is greater than or equal to this size then two columns
will be used, otherwise only single column is used.

=item showUniversalSet (Default: C<0>)

If 1 then the set of all elements passed in the C<$itemList> will be shown
in a separate bucket.  Elements can be dragged from this set and into other
buckets, but not into it.

=item universalSetLabel (Default: C<< 'Universal Set' >>)

Label shown for the universal set bucket if C<showUniversalSet> is 1.

=item addFromUniversalText

The aria announcement text format that is used when a universal set item is
added to a bucket via keyboard controls. The default format for this text is
C<'Item %1s in the universal set added as item %2s to list %3s.'>.  Note that if
this is customized it must contain C<%1s>, C<%2s>, and C<%3s> as in the default
value.

=item removeUniversalItemText

The aria announcement text format that is used when an item from the universal
set that is in a bucket is removed via keyboard controls. The default format for
this text is C<'Item %1s removed from list %2s.'>.  Note that if this is
customized it must contain C<%1s> and C<%2s> as in the default value.

=item reorderText

The aria announcement text format that is used when an item is moved up or down
in a bucket via keyboard controls. The default format for this text is
C<'Moved item %1s in list %2s to item %3s.'>.  Note that if this is customized
it must contain C<%1s>, C<%2s>, and C<%3s> as in the default value.

=item moveText

The aria announcement text format that is used when an item is moved from one
bucket to another via keyboard controls. The default format for this text is
C<'Moved item %1s in list %2s to item %3s in list %4s.'>.  Note that if this is
customized it must contain C<%1s>, C<%2s>, C<%3s>, and C<%4s> as in the default
value.

=item helpButtonText (Default: C<'Drag and Drop Help'>)

The text shown on the button that opens the drag and drop help.

=item closeHelpButtonText (Default: C<'Close Help'>)

The text shown on the button that closes the drag and drop help.

=item dragAndDropHelpText

The help that is shown when the drag and drop help button is pressed.

The default text is

=over 4

Drag to reorganize items within lists or to move items to a different list. Tab
and shift-tab can be used to focus list items.  The left and right arrow keys
move a focused list item to the list to the left or right.  The up and down
arrow keys move a focused list item up and down inside a list.

=back

=item universalSetHelpText

If the option C<showUniversalSet> is set to 1, then this is shown before the
C<dragAndDropHelpText> in the help.

The default text for this is

=over 4

Drag items in the universal set to copy them to a list.  Tab and shift-tab can
be used to focus universal set items.  A focused item in the universal set can
be added to the first list with the right or down arrow keys, or added to the
last list with the left or up arrow keys. A focused item in a list can be
removed by using the left or right arrow key until it returns to the universal
set.

=back

=back

=head2 METHODS

The following are methods that can be called with the constructed DragNDrop
object.

=over

=item $dnd->HTML()

This outputs the bucket pool to HTML.

=item $dnd->TeX()

This outputs the bucket pool to LaTeX.

=back

=head1 EXAMPLES

See draggableProof.pl and draggableSubsets.pl

=cut

package DragNDrop;

use strict;
use warnings;

use Mojo::JSON qw(encode_json);

use PGcore;

# $answerName is the html 'name' of the <input> tag corresponding to the answer blank.
# $itemList is an array of all statements provided.
# $defaultBuckets is a reference to an array of default buckets that are shown when the object is in its default state.
sub new {
	my ($self, $answerName, $itemList, $defaultBuckets, %options) = @_;

	my $PG = eval('$main::PG');

	return bless {
		answerName           => $answerName,
		itemList             => $itemList,
		defaultBuckets       => $defaultBuckets,
		allowNewBuckets      => 0,
		bucketLabelFormat    => undef,
		resetButtonText      => $PG->maketext('Reset'),
		addButtonText        => $PG->maketext('Add Bucket'),
		removeButtonText     => $PG->maketext('Remove'),
		multicolsWidth       => '300pt',
		showUniversalSet     => 0,
		universalSetLabel    => $PG->maketext('Universal Set'),
		addFromUniversalText =>
			$PG->maketext('Item [_1] in the universal set added as item [_2] to list [_3].', '%1s', '%2s', '%3s'),
		removeUniversalItemText => $PG->maketext('Item [_1] removed from list [_2].', '%1s', '%2s'),
		reorderText             => $PG->maketext('Moved item [_1] in list [_2] to item [_3].', '%1s', '%2s', '%3s'),
		moveText                =>
			$PG->maketext('Moved item [_1] in list [_2] to item [_3] in list [_4].', '%1s', '%2s', '%3s', '%4s'),
		helpButtonText      => $PG->maketext('Drag and Drop Help'),
		closeHelpButtonText => $PG->maketext('Close Help'),
		dragAndDropHelpText => $PG->maketext(
			'Drag to reorganize items within lists or to move items to a different list. '
				. 'Tab and shift-tab can be used to focus list items. '
				. 'The left and right arrow keys move a focused list item to the list to the left or right. '
				. 'The up and down arrow keys move a focused list item up and down inside a list.'
		),
		universalSetHelpText => $PG->maketext(
			'Drag items in the universal set to copy them to a list. '
				. 'Tab and shift-tab can be used to focus universal set items. '
				. 'A focused item in the universal set can be added to the first list with the right or down arrow '
				. 'keys, or added to the last list with the left or up arrow keys. A focused item in a list can '
				. 'be removed by using the left or right arrow key until it returns to the universal set.'
		),
		%options,
		},
		ref($self) || $self;
}

sub HTML {
	my $self = shift;

	my $out = qq{<div class="dd-bucket-pool" data-answer-name="$self->{answerName}"};
	$out .= ' data-item-list="' . PGcore::encode_pg_and_html(encode_json($self->{itemList})) . '"';
	$out .= ' data-default-state="' . PGcore::encode_pg_and_html(encode_json($self->{defaultBuckets})) . '"';
	$out .= qq{ data-remove-button-text="$self->{removeButtonText}"};
	$out .= qq{ data-label-format="$self->{bucketLabelFormat}"} if $self->{bucketLabelFormat};
	$out .= " data-show-universal-set"                          if $self->{showUniversalSet};
	$out .= ' data-universal-set-label="' . PGcore::encode_pg_and_html($self->{universalSetLabel}) . '"';
	$out .= ' data-add-from-universal-text="' . PGcore::encode_pg_and_html($self->{addFromUniversalText}) . '"';
	$out .= ' data-remove-universal-item-text="' . PGcore::encode_pg_and_html($self->{removeUniversalItemText}) . '"';
	$out .= ' data-reorder-text="' . PGcore::encode_pg_and_html($self->{reorderText}) . '"';
	$out .= ' data-move-text="' . PGcore::encode_pg_and_html($self->{moveText}) . '"';
	$out .= '>';

	$out .= '<div class="dd-buttons"';
	$out .= qq{ data-feedback-insert-element="$self->{answerName}" data-feedback-insert-method="append_content">};
	$out .= qq{<button type="button" class="btn btn-secondary dd-reset-buckets">$self->{resetButtonText}</button>};
	$out .= qq{<button type="button" class="btn btn-secondary dd-add-bucket">$self->{addButtonText}</button>}
		if ($self->{allowNewBuckets});
	$out .= '</div>';

	$out .=
		'<div class="d-flex justify-content-center mt-3">'
		. '<button type="button" class="btn btn-secondary" data-bs-toggle="modal" '
		. qq{data-bs-target="#$self->{answerName}-help">$self->{helpButtonText}</button>}
		. qq{<div class="modal fade" id="$self->{answerName}-help" tabindex="-1" role="dialog" }
		. qq{aria-labelledby="$self->{answerName}-help-label" aria-hidden="true">}
		. '<div class="modal-dialog modal-dialog-centered">'
		. '<div class="modal-content">'
		. '<div class="modal-header">'
		. qq{<h1 class="modal-title fs-5" id="$self->{answerName}-help-label">$self->{helpButtonText}</h1>}
		. qq{<button type="button" class="btn-close" data-bs-dismiss="modal" }
		. qq{aria-label="$self->{closeHelpButtonText}"></button>}
		. '</div>'
		. '<div class="modal-body">'
		. ($self->{showUniversalSet} ? qq{<p class="mt-0 mb-3">$self->{universalSetHelpText}</p>} : '')
		. qq{<p class="m-0">$self->{dragAndDropHelpText}</p>}
		. '</div>'
		. '<div class="modal-footer">'
		. '<button type="button" class="btn btn-secondary" data-bs-dismiss="modal">'
		. $self->{closeHelpButtonText}
		. '</button>'
		. '</div>'
		. '</div>'
		. '</div>'
		. '</div>'
		. '</div>';

	$out .= '</div>';

	return $out;
}

sub TeX {
	my $self = shift;

	my $out = '';

	if ($self->{showUniversalSet}) {
		$out .= "\n\\hrule\n\\vspace{0.5\\baselineskip}\n";
		$out .= "\\parbox{0.9\\linewidth}{\n";
		$out .= "$self->{universalSetLabel}\n";
		$out .= "\\begin{itemize}\n";
		$out .= "\\item $_\n" for (@{ $self->{itemList} });
		$out .= "\\end{itemize}\n";
		$out .= "}\n";
	}

	$out .=
		"\n\\hrule\n\\vspace{0.5\\baselineskip}\n\\newif\\ifdndcolumns\n"
		. "\\ifdim\\linewidth<$self->{multicolsWidth}\\relax\\dndcolumnsfalse\\else\\dndcolumnstrue\\fi\n";

	for my $i (0 .. $#{ $self->{defaultBuckets} }) {
		my $bucket = $self->{defaultBuckets}[$i];
		if ($i != 0) {
			if   ($i % 2 == 0) { $out .= "\n\\hrule\n\\vspace{0.5\\baselineskip}\n"; }
			else               { $out .= "\n\\ifdndcolumns\\else\\hrule\n\\vspace{0.5\\baselineskip}\\fi\n"; }
		}

		$out .=
			"\n\\begin{minipage}{\\linewidth}\n\\setlength{\\columnseprule}{0.2pt}\n"
			. "\\ifdndcolumns\\begin{multicols}{2}\\fi\n"
			if $i % 2 == 0 && $i != $#{ $self->{defaultBuckets} };

		$out .= "\\parbox{0.9\\linewidth}{\n";
		$out .=
			($bucket->{label} // ($self->{bucketLabelFormat} ? sprintf($self->{bucketLabelFormat}, $i) : '')) . "\n";
		if (@{ $bucket->{indices} }) {
			$out .= "\\begin{itemize}\n";
			for my $j (@{ $bucket->{indices} }) {
				$out .= "\\item $self->{itemList}[$j]\n";
			}
			$out .= "\\end{itemize}\n";
		} else {
			$out .= "\\vspace{3\\baselineskip}\n";
		}
		$out .= "}";

		if ($i % 2 == 0) {
			$out .= "\\ifdndcolumns\\columnbreak\\fi\n\n" if $i != $#{ $self->{defaultBuckets} };
		} else {
			$out .= "\\ifdndcolumns\\end{multicols}\\fi\n\\end{minipage}\n";
		}
		$out .= "\\vspace{0.75\\baselineskip}\n";
	}
	$out .= "\n\\hrule\n\\vspace{0.25\\baselineskip}\n";

	return $out;
}
1;
