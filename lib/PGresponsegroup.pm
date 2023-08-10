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
package PGresponsegroup;
use parent qw(PGanswergroup);

use strict;
use warnings;

use PGUtil qw(not_null);

# An object which contains student response(s).
# 1. Needs to be able to hold one or more responses.
# 2. Needs space for auxiliary answer labels. For example, all of the entries in an array.
# 3. Needs to coordinate answer labels with the PGanswergroup holding it.
#    This is accomplished by having it point to it's enclosing answergroup.
# 4. May have additional methods for processing and storing response strings.
#      The responses for radio buttons and check boxes should be of the form:
#          response_label => [['value1', 'CHECKED'], ['value2', ''], ['value3', ''],  ...]
# 5. Should be called with at least one label, response pair.
# 6. By convention the first response usually has the same label as the parent answergroup.
#    This is always true if there is only a single response.

# Create a new empty response group object.
# Optionally append label/response pairs.
sub new {
	my ($class, $answergroup_label, @responses) = @_;
	my $self = bless {
		answergroup_label => $answergroup_label,    # enclosing answergroup that created this responsegroup
		response_order    => [],                    # response labels
		responses         => {},                    # response label/response value pair,
													# value could be an arrayref in the case of radio or checkbox groups
	}, $class;
	$self->append_responses(@responses);
	return $self;

}

# Append label/response pairs to the response hash.
# Response order is recorded in the response_order array.
sub append_response {
	my ($self, $response_label, $response_value) = @_;
	if (not_null($response_label)) {
		if (not exists($self->{responses}{$response_label})) {
			push @{ $self->{response_order} }, $response_label;
			$self->{responses}{$response_label} =
				ref($response_value) eq 'HASH'
				? [ map { [ $_ => $response_value->{$_} ] } keys %$response_value ]
				: $response_value;
		} else {
			$self->internal_debug_message(
				"PGresponsegroup::append_response error: there is already an answer labeled $response_label",
				caller(2), "\n");
		}
	} else {
		$self->internal_debug_message('PGresponsegroup::append_response error: undefined or empty response label');
	}
	return;
}

# Append label/response pairs to the response hash.
sub append_responses {
	my ($self, @response_list) = @_;
	while (@response_list) {
		$self->append_response(shift @response_list, shift @response_list);
	}
	return;
}

# Replace the response to one response label entry.
sub replace_response {
	my ($self, $response_label, $response_value) = @_;
	if (defined $self->{responses}{$response_label}) {
		$self->{responses}{$response_label} = $response_value if defined $response_value;
		return $self->{responses}{$response_label};
	} else {
		warn "response label |$response_label| not defined";
		return;
	}
}

# Extend the response to an array for this response label entry.  This is used for check boxes and radio buttons.  This
# converts the reponse value into an array of label/value pairs if it is a hash to begin with.  Otherwise it just adds a
# label/value pair to the existing array.
sub extend_response {
	my ($self, $response_label, $new_value_key, $selected) = @_;

	if (defined $self->{responses}{$response_label}) {
		my $response_value = $self->{responses}{$response_label};
		$response_value //= [];

		if (ref($response_value) !~ /^(HASH|ARRAY)$/) {
			$self->internal_debug_message("PGresponsegroup::extend_response: error in extending response ",
				ref($response_value), $response_value);
			$response_value = [ [ $response_value => $selected ] ];
		}

		if (ref($response_value) eq 'HASH') {
			$response_value = [ map { [ $_ => $response_value->{$_} ] } keys %$response_value ];
		}
		push(@$response_value, [ $new_value_key => $selected ]);
		$self->{responses}{$response_label} = $response_value;
		return $response_value;
	} else {
		$self->internal_debug_message("PGresponsegroup::extend_response: response label |$response_label| not defined");
		return;
	}
}

# Get the responses for a label.
sub get_response {
	my ($self, $response_label) = @_;
	return $self->{responses}{$response_label};
}

sub get_answergroup_label {
	my $self = shift;
	if (!not_null($self->{answergroup_label})) {
		$self->{answergroup_label} = ${ $self->{response_order} }[0];
	}
	return $self->{answergroup_label} if not_null($self->{answergroup_label});
	warn 'This answer group has no labeled responses.';
	return;
}

# Sets the PGresponsegroup to empty
sub clear {
	my $self = shift;
	$self->{response_order} = [];
	$self->{responses}      = {};
	return;
}

# Returns the entry ordered list of response labels
sub response_labels {
	my $self = shift;
	return @{ $self->{response_order} };
}

# Returns the entry ordered list of response values.
sub values {
	my $self = shift;
	my @out;
	for my $key (@{ $self->{response_order} }) {
		push @out, $self->get_response($key);
	}
	return @out;
}

# Synonym for values.
sub responses {
	my ($self, @responses) = shift;
	return $self->values(@responses);
}

sub data {
	my $self = shift;
	return {%$self};
}

1;
