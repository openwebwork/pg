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
applies to new buckets that are added by JavaScript.  An example value for this
option is C<< 'Subset %s' >>.

=item resetButtonText (Default: C<< 'Reset' >>)

This is the text label for the reset button.

=item addButtonText (Default: C<< 'Add Bucket' >>)

This is the text label for the button shown that adds new buckets.  The button
is only shown if AllowNewBuckets is 1.

=item removeButtonText (Default: C<< 'Remove' >>

This is the text label for any remove buttons that are added to removable
buckets.

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

use JSON;

use PGcore;

# $answerName is the html 'name' of the <input> tag corresponding to the answer blank.
# $itemList is an array of all statements provided.
# $defaultBuckets is a reference to an array of default buckets that are shown when the object is in its default state.
sub new {
	my ($self, $answerName, $itemList, $defaultBuckets, %options) = @_;

	return bless {
		answerName        => $answerName,
		itemList          => $itemList,
		defaultBuckets    => $defaultBuckets,
		allowNewBuckets   => 0,
		bucketLabelFormat => undef,
		resetButtonText   => 'Reset',
		addButtonText     => 'Add Bucket',
		removeButtonText  => 'Remove',
		%options,
		},
		ref($self) || $self;
}

sub HTML {
	my $self = shift;

	my $out = qq{<div class="dd-bucket-pool" data-answer-name="$self->{answerName}"};
	$out .= ' data-item-list="' . PGcore::encode_pg_and_html(JSON->new->encode($self->{itemList})) . '"';
	$out .= ' data-default-state="' . PGcore::encode_pg_and_html(JSON->new->encode($self->{defaultBuckets})) . '"';
	$out .= qq{ data-remove-button-text="$self->{removeButtonText}"};
	$out .= qq{ data-label-format="$self->{bucketLabelFormat}"} if $self->{bucketLabelFormat};
	$out .= '>';

	$out .= '<div class="dd-buttons">';
	$out .= qq{<button type="button" class="btn btn-secondary dd-reset-buckets">$self->{resetButtonText}</button>};
	$out .= qq{<button type="button" class="btn btn-secondary dd-add-bucket">$self->{addButtonText}</button>}
		if ($self->{allowNewBuckets});
	$out .= '</div></div>';

	return $out;
}

sub TeX {
	my $self = shift;

	my $out = "\n\\hrule\n\\vspace{0.5\\baselineskip}\n";

	for my $i (0 .. $#{ $self->{defaultBuckets} }) {
		my $bucket = $self->{defaultBuckets}[$i];
		if ($i != 0) {
			if   ($i % 2 == 0) { $out .= "\n\\hrule\n\\vspace{0.5\\baselineskip}\n" }
			else               { $out .= "\n\\ifdefined\\nocolumns\\else\\hrule\n\\vspace{0.5\\baselineskip}\n\\fi" }
		}

		$out .=
			"\n\\begin{minipage}{\\linewidth}\n\\setlength{\\columnseprule}{0.2pt}\n"
			. "\\ifdefined\\nocolumns\\begin{multicols}{2}\\else\\fi\n"
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

		if ($i % 2 == 0) { $out .= "\\columnbreak\n\n" if $i != $#{ $self->{defaultBuckets} } }
		else             { $out .= "\\ifdefined\\nocolumns\\end{multicols}\\else\\fi\n\\end{minipage}\n" }
		$out .= "\\vspace{0.75\\baselineskip}\n";
	}
	$out .= "\n\\hrule\n\\vspace{0.25\\baselineskip}\n";

	return $out;
}
1;
