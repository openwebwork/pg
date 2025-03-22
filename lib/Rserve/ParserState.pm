package Rserve::ParserState;

use strict;
use warnings;

sub new {
	my ($invocant, @args) = @_;
	my $class = ref($invocant) || $invocant;

	my $attributes = {};

	if (@args == 1) {
		if (ref $args[0] eq 'HASH') {
			$attributes = $args[0];
		} else {
			$attributes->{name} = $args[0];
		}
	} elsif (@args % 2) {
		die "The new method for $class expects a hash reference or a key/value list."
			. " You passed an odd number of arguments\n";
	} else {
		$attributes = {@args};
	}

	# Split strings into a list of individual characters.
	if (defined $attributes->{data} && !ref($attributes->{data})) {
		$attributes->{data} = [ split //, $attributes->{data} ];
	}

	my $self = bless $attributes, $class;

	$self->{data}     //= [];
	$self->{position} //= 0;

	die 'foo' unless ref($self->data) eq 'ARRAY';

	return $self;
}

sub data     { my $self = shift; return $self->{data}; }
sub position { my $self = shift; return $self->{position}; }

sub at {
	my $self = shift;
	return $self->data->[ $self->position ];
}

sub next {
	my $self = shift;
	return ref($self)->new(data => $self->data, position => $self->position + 1);
}

sub eof {
	my $self = shift;
	return $self->position >= @{ $self->data };
}

1;

__END__

=encoding UTF-8

=head1 NAME

Rserve::ParserState - Current state of the parser

=head1 SYNOPSIS

    use Rserve::ParserState;

    my $state = Rserve::ParserState->new(data => 'file.rds');
    say $state->at
    say $state->next->at;

=head1 DESCRIPTION

You shouldn't create instances of this class, it exists mainly to handle
deserialization of R data files.

=head1 METHODS

=head2 ACCESSORS

=head3 data

An array reference to the data being parsed. The constructs accepts a scalar,
which will be L<split> into individual characters.

=head3 position

Position of the next data element to be processed.

=head3 at

Returns the element (byte) at the current C<position>.

=head3 eof

Returns true if the cursor (C<position>) is at the end of the C<data>.

=head2 MUTATORS

C<ParserState> is intended to be immutable, so the "mutator" methods actually
return a new instance with appropriately modified values of the attributes.

=head3 next

Returns a new ParserState instance with C<position> advanced by one.

=cut
