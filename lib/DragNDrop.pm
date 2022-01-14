################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2021 The WeBWorK Project, https://github.com/openwebwork
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

DragNDrop.pm is a backend Perl module which facilitates the implementation of
'Drag-And-Drop' in WeBWorK problems. It is meant to be used by other perl macros
such as draggableProof.pl and draggableSubsets.pl

=head1 TERMINOLOGY

An HTML element into or out of which other elements may be dragged will be called a "bucket".
An HTML element which houses a collection of buckets will be called a "bucket pool".

=head1 USAGE

Each macro aiming to implement drag-n-drop features must call at its initialization:

 ADD_CSS_FILE("https://cdnjs.cloudflare.com/ajax/libs/nestable2/1.6.0/jquery.nestable.min.css", 1);
 ADD_JS_FILE("https://cdnjs.cloudflare.com/ajax/libs/nestable2/1.6.0/jquery.nestable.min.js", 1, { defer => undef });
 ADD_CSS_FILE("js/apps/DragNDrop/dragndrop.css", 0);
 ADD_JS_FILE("js/apps/DragNDrop/dragndrop.js", 0, { defer => undef });

To initialize a bucket pool, do:

 my $bucket_pool = new DragNDrop($answerInputId, $aggregateList);

$answerInputId is a unique identifier for the bucket_pool, it is recommended that
it be generated with NEW_ANS_NAME.

$aggregateList is a reference to an array of all "statements" intended to be draggable.
Example:

 $aggregateList = ['socrates is a man', 'all men are mortal', 'therefore socrates is mortal'];

It is imperative that square brackets be used.

OPTIONAL:

 DragNDrop($answerInputId, $aggregateList, AllowNewBuckets => 1);

allows student to create new buckets by clicking on a button.

To add a bucket to an existing pool $bucket_pool, do:

 $bucket_pool->addBucket($indices);

$indices is the reference to the array of indices corresponding to the statements in $aggregateList
to be pre-included in the bucket.

For example, if the $aggregateList is:

 ['Socrates is a man', 'all men are mortal', 'therefore Socrates is mortal']

and the bucket consists of:

 { 'Socrates is a man', 'therefore Socrates is mortal' }

then:

 $indices = [0, 2].

An empty array reference, e.g. $bucket_pool->addBucket([]), gives an empty bucket.

OPTIONAL:

 $bucket_pool->addBucket($indices, label => 'Barrel', removable => 1)

puts the label 'Barrel' at the top of the bucket.
With the removable option set to 1, the bucket may be removed by the student via the click of a "Remove" button
at the bottom of the bucket.
(The first created bucket may never be removed.)

To output the bucket pool to HTML, call:

 $bucket_pool->HTML

To output the bucket pool to LaTeX, call:

 $bucket_pool->TeX

=head1 EXAMPLES

See draggableProof.pl and draggableSubsets.pl

=cut

use strict;
use warnings;

package DragNDrop;

sub new {
	my $self  = shift;
	my $class = ref($self) || $self;

	# 'id' of html <input> tag corresponding to the answer blank. Must be unique to each pool of DragNDrop buckets
	my $answerInputId = shift;

	# array of all statements provided
	my $aggregateList = shift;

	# instructor-provided default buckets with pre-included statements encoded
	# by the array of corresponding statement indices
	my $defaultBuckets = shift;

	my %options = (
		AllowNewBuckets => 0,
		@_
	);

	$self = bless {
		answerInputId  => $answerInputId,
		bucketList     => [],
		aggregateList  => $aggregateList,
		defaultBuckets => $defaultBuckets,
		%options,
	}, $class;

	return $self;
}

sub addBucket {
	my $self = shift;

	my $indices = shift;

	my %options = (
		label     => "",
		removable => 0,
		@_
	);

	my $bucket = {
		indices   => $indices,
		list      => [ map { $self->{aggregateList}->[$_] } @$indices ],
		bucket_id => scalar @{ $self->{bucketList} },
		label     => $options{label},
		removable => $options{removable},
	};
	push(@{ $self->{bucketList} }, $bucket);

}

sub HTML {
	my $self = shift;

	my $out = '';
	$out .= "<div class='dd-bucket-pool' data-ans='$self->{answerInputId}'>";

	# buckets from instructor-defined default settings
	for (my $i = 0; $i < @{ $self->{defaultBuckets} }; $i++) {
		my $defaultBucket = $self->{defaultBuckets}->[$i];
		$defaultBucket->{removable} //= 0;
		$out .= "<div class='dd-hidden dd-default dd-bucket' data-bucket-id='$i' data-removable='$defaultBucket->{removable}'>";
		$out .= "<div class='dd-label'>$defaultBucket->{label}</div>";
		$out .= "<ol class='dd-answer'>";
		for my $j (@{ $defaultBucket->{indices} }) {
			$out .= "<li data-shuffled-index='$j'>$self->{aggregateList}->[$j]</li>";
		}
		$out .= "</ol></div>";
	}

	# buckets from past answers
	for my $bucket (@{ $self->{bucketList} }) {
		$out .= "<div class='dd-hidden dd-past-answers dd-bucket' data-bucket-id='$bucket->{bucket_id}' ";
		$out .= "data-removable='$bucket->{removable}'>";
		$out .= "<div class='dd-label'>$bucket->{label}</div>";
		$out .= "<ol class='dd-answer'>";

		for my $index (@{ $bucket->{indices} }) {
			$out .= "<li data-shuffled-index='$index'>$self->{aggregateList}->[$index]</li>";
		}
		$out .= "</ol>";
		$out .= "</div>";
	}
	$out .= '</div>';
	$out .= "<div class='dd-buttons'><button type='button' class='btn btn-secondary dd-reset-buckets'>reset</button>";
	if ($self->{AllowNewBuckets} == 1) {
		$out .= "<button type='button' class='btn btn-secondary dd-add-bucket' data-ans='$self->{answerInputId}'>add bucket</button>";
	}
	$out .= "</div>";

	return $out;
}

sub TeX {
	my $self = shift;

	my $out = "";

	# default buckets;
	for (my $i = 0; $i < @{ $self->{defaultBuckets} }; $i++) {
		$out .= "\n";
		my $defaultBucket = $self->{defaultBuckets}->[$i];
		if (@{ $defaultBucket->{indices} } > 0) {
			$out .= "\n\\hrule\n\\begin{itemize}";
			for my $j (@{ $defaultBucket->{indices} }) {
				$out .= "\n\\item[$j.]\n $self->{aggregateList}->[$j]";
			}
			$out .= "\n\\end{itemize}";
		}
		$out .= "\n\\hrule\n";
	}
	return $out;
}
1;
