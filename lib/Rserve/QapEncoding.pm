package Rserve::QapEncoding;

use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK   = qw(decode);
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

use Carp qw(carp croak);

use Rserve::Parser qw(:all);
use Rserve::ParserState;
use Rserve::REXP::Character;
use Rserve::REXP::Complex;
use Rserve::REXP::Double;
use Rserve::REXP::Integer;
use Rserve::REXP::List;
use Rserve::REXP::Logical;
use Rserve::REXP::Raw;
use Rserve::REXP::Language;
use Rserve::REXP::Symbol;
use Rserve::REXP::Null;
use Rserve::REXP::Unknown;

use constant {
	DT_INT        => 1,     # int
	DT_CHAR       => 2,     # char
	DT_DOUBLE     => 3,     # double
	DT_STRING     => 4,     # zero- terminated string
	DT_BYTESTREAM => 5,     # stream of bytes (unlike DT_STRING may contain 0)
	DT_SEXP       => 10,    # encoded SEXP
	DT_ARRAY      => 11,    # array of objects (i.e. first 4 bytes specify how many subsequent
							# objects are part of the array; 0 is legitimate)
	DT_CUSTOM     => 32,    # custom types not defined in the protocol but used by applications
	DT_LARGE      => 64,    # new in 0102: if this flag is set then the length of the object
							# is coded as 56-bit integer enlarging the header by 4 bytes
};

# eXpression Types:  transport format of the encoded SEXPs:
# [0] int type/len (1 byte type, 3 bytes len - same as SET_PAR)
# [4] REXP attr (if bit 8 in type is set)
# [4/8] data .. */
# Expression type classification:
#    P = primary type
#    s = secondary type - its decoding is identical to a primary type and thus the client doesn't need to decode it
#        separately.
#    - = deprecated/removed. if a client doesn't need to support old Rserve versions, those can be safely skipped.
# XT_* types:
use constant {
	XT_NULL          => 0,      # P data: [0]
	XT_INT           => 1,      # - data: [4]int
	XT_DOUBLE        => 2,      # - data: [8]double
	XT_STR           => 3,      # P data: [n]char null-term. strg.
	XT_LANG          => 4,      # - data: same as XT_LIST
	XT_SYM           => 5,      # - data: [n]char symbol name
	XT_BOOL          => 6,      # - data: [1]byte boolean (1=TRUE, 0=FALSE, 2=NA)
	XT_S4            => 7,      # P data: [0]
	XT_VECTOR        => 16,     # P data: [?]REXP,REXP,...
	XT_LIST          => 17,     # - X head, X vals, X tag (since 0.1-5)
	XT_CLOS          => 18,     # P X formals, X body (closure; since 0.1-5)
	XT_SYMNAME       => 19,     # s same as XT_STR (since 0.5)
	XT_LIST_NOTAG    => 20,     # s same as XT_VECTOR (since 0.5)
	XT_LIST_TAG      => 21,     # P X tag, X val, Y tag, Y val, ... (since 0.5)
	XT_LANG_NOTAG    => 22,     # s same as XT_LIST_NOTAG (since 0.5)
	XT_LANG_TAG      => 23,     # s same as XT_LIST_TAG (since 0.5)
	XT_VECTOR_EXP    => 26,     # s same as XT_VECTOR (since 0.5)
	XT_VECTOR_STR    => 27,     # - same as XT_VECTOR (since 0.5 but unused, use XT_ARRAY_STR instead)
	XT_ARRAY_INT     => 32,     # P data: [n*4]int,int,...
	XT_ARRAY_DOUBLE  => 33,     # P data: [n*8]double,double,...
	XT_ARRAY_STR     => 34,     # P data: string,string,... (string = byte, byte, ..., 0) padded with '\01'
	XT_ARRAY_BOOL_UA => 35,     # - data: [n]byte,byte,... (unaligned! NOT supported anymore)
	XT_ARRAY_BOOL    => 36,     # P data: int(n),byte,byte,...
	XT_RAW           => 37,     # P data: int(n),byte,byte,...
	XT_ARRAY_CPLX    => 38,     # P data: [n*16]double,double,... (Re,Im,Re,Im,...)
	XT_UNKNOWN       => 48,     # P data: [4]int - SEXP type (as from TYPEOF(x))
	XT_LARGE         => 64,     # new in 0102: if this flag is set then the length of the object
								# is coded as 56-bit integer enlarging the header by 4 bytes
	XT_HAS_ATTR      => 128,    # flag; if set, the following REXP is the attribute
};

sub unpack_sexp_info {
	return bind(
		\&any_uint32,
		sub {
			my $object_info = shift // return;
			my $is_long     = $object_info & XT_LARGE;

			if ($is_long) {
				# TODO: if `is_long`, then the next 4 bytes contain the upper half of the length
				error q{Sorry, long packets aren't supported yet};
			} else {
				mreturn {
					has_attributes => $object_info & XT_HAS_ATTR,
					is_long        => $is_long,
					object_type    => $object_info & 0x3F,
					length         => $object_info >> 8,
				};
			}
		}
	);
}

sub sexp_data {
	my $object_info = shift;

	return bind(
		maybe_attributes($object_info),
		sub {
			my ($object_info, $attributes) = @{ shift() };

			if ($object_info->{object_type} == XT_NULL) {
				# encoded Nil
				mreturn(Rserve::REXP::Null->new);
			} elsif ($object_info->{object_type} == XT_ARRAY_INT) {
				# integer vector
				intsxp($object_info, $attributes);
			} elsif ($object_info->{object_type} == XT_ARRAY_BOOL) {
				# logical vector
				lglsxp($object_info, $attributes);
			} elsif ($object_info->{object_type} == XT_ARRAY_DOUBLE) {
				# numeric vector
				dblsxp($object_info, $attributes);
			} elsif ($object_info->{object_type} == XT_ARRAY_CPLX) {
				# complex vector
				cplxsxp($object_info, $attributes);
			} elsif ($object_info->{object_type} == XT_ARRAY_STR) {
				# character vector
				strsxp($object_info, $attributes);
			} elsif ($object_info->{object_type} == XT_RAW) {
				# raw vector
				rawsxp($object_info);
			} elsif ($object_info->{object_type} == XT_VECTOR) {
				# list (generic vector)
				vecsxp($object_info, $attributes);
			} elsif ($object_info->{object_type} == XT_VECTOR_EXP) {
				# expression vector
				expsxp($object_info, $attributes);
			} elsif ($object_info->{object_type} == XT_LIST_NOTAG) {
				# pairlist with no tags
				$object_info->{has_tags} = 0;
				listsxp($object_info);
			} elsif ($object_info->{object_type} == XT_LIST_TAG) {
				# pairlist with tags
				$object_info->{has_tags} = 1;
				listsxp($object_info);
			} elsif ($object_info->{object_type} == XT_LANG_NOTAG) {
				# language without tags
				$object_info->{has_tags} = 0;
				langsxp($object_info, $attributes);
			} elsif ($object_info->{object_type} == XT_LANG_TAG) {
				# language with tags
				$object_info->{has_tags} = 1;
				langsxp($object_info, $attributes);
			} elsif ($object_info->{object_type} == XT_SYMNAME) {
				# symbol
				symsxp($object_info);
			} elsif ($object_info->{object_type} == XT_UNKNOWN) {
				# unknown
				nosxp($object_info, $attributes);
			} else {
				error 'unimplemented XT_TYPE: ' . $object_info->{object_type};
			}
		}
	);
}

sub maybe_attributes {
	my $object_info = shift;

	return sub {
		my $state = shift or return;
		my $attributes;

		if ($object_info->{has_attributes}) {
			my $attributes_start = $state->position;
			my $result           = dt_sexp_data()->($state) or return;

			$attributes = { tagged_pairlist_to_attribute_hash(shift @$result) };
			$state      = shift @$result;

			# adjust SEXP length for that already consumed by attributes
			$object_info->{length} -= $state->position - $attributes_start;
		}

		[ [ $object_info, $attributes ], $state ];
	}
}

sub tagged_pairlist_to_rexp_hash {
	my $list = shift or return;

	croak 'Tagged element has an attribute?!'
		if exists $list->{attributes}
		&& grep { $_ ne 'names' } keys %{ $list->{attributes} };

	my @elements = @{ $list->elements };
	my @names    = @{ $list->attributes->{names}->elements };
	die 'length of tags does not match the elements' unless @elements == @names;

	my %rexps;
	@rexps{@names} = @elements;
	return %rexps;
}

sub tagged_pairlist_to_attribute_hash {
	my $list      = shift;
	my %rexp_hash = tagged_pairlist_to_rexp_hash($list);

	my $row_names = $rexp_hash{'row.names'};
	if ($row_names && $row_names->type eq 'integer' && !defined $row_names->elements->[0]) {
		# compact encoding when rownames are integers 1..n: the
		# length n is in the second element, but can be negative to
		# denote "automatic" rownames
		my $n = abs($row_names->elements->[1]);
		$rexp_hash{'row.names'} = Rserve::REXP::Integer->new([ 1 .. $n ]);
	}

	return %rexp_hash;
}

sub symsxp {
	my $object_info = shift;

	return bind(
		count($object_info->{length}, \&any_char),
		sub {
			my @chars = @{ shift or return };
			pop @chars while @chars && !ord($chars[-1]);
			return mreturn(Rserve::REXP::Symbol->new(join('', @chars)));
		}
	);
}

sub nosxp {
	my ($object_info, $attributes) = (shift, shift);

	return bind(
		\&any_uint32,
		sub {
			my $sexp_id = shift or return;
			my %args    = (sexptype => $sexp_id);
			$args{attributes} = $attributes if $attributes;
			return mreturn(Rserve::REXP::Unknown->new(%args));
		}
	);
}

sub intsxp {
	my ($object_info, $attributes) = @_;

	if ($object_info->{length} % 4 == 0) {
		return bind(
			count($object_info->{length} / 4, any_int32_na),
			sub {
				my @ints = @{ shift or return };
				my %args = (elements => [@ints]);
				$args{attributes} = $attributes if $attributes;
				return mreturn(Rserve::REXP::Integer->new(%args));
			}
		);
	} else {
		error q{TODO: intsxp length doesn't align by 4: } . $object_info->{length};
		return;
	}
}

sub dblsxp {
	my ($object_info, $attributes) = @_;

	if ($object_info->{length} % 8 == 0) {
		return bind(
			count($object_info->{length} / 8, any_real64_na),
			sub {
				my @dbls = @{ shift or return };
				my %args = (elements => [@dbls]);
				$args{attributes} = $attributes if $attributes;
				return mreturn(Rserve::REXP::Double->new(%args));
			}
		);
	} else {
		error q{TODO: dblsxp length doesn't align by 8: } . $object_info->{length};
		return;
	}
}

sub cplxsxp {
	my ($object_info, $attributes) = @_;

	if ($object_info->{length} % 16 == 0) {
		return bind(
			count($object_info->{length} / 8, any_real64_na),
			sub {
				my @dbls = @{ shift or return };
				my @cplx;
				while (my ($re, $im) = splice(@dbls, 0, 2)) {
					if (defined $re && defined $im) {
						push(@cplx, Math::Complex::cplx($re, $im));
					} else {
						push(@cplx, undef);
					}
				}
				my %args = (elements => [@cplx]);
				$args{attributes} = $attributes if $attributes;
				return mreturn(Rserve::REXP::Complex->new(%args));
			}
		);
	} else {
		error q{TODO: cplxsxp length doesn't align by 16: } . $object_info->{length};
		return;
	}
}

sub lglsxp {
	my ($object_info, $attributes) = @_;

	my $dt_length = $object_info->{length},;
	if ($dt_length) {
		return bind(
			\&any_uint32,
			sub {
				my $true_length = shift;
				return unless defined $true_length;
				my $padding_length = $dt_length - $true_length - 4;

				bind(
					seq(count($true_length, \&any_uint8), count($padding_length, \&any_uint8)),
					sub {
						my ($elements, $padding) = @{ shift or return };
						my %args = (elements => [ map { $_ == 2 ? undef : $_ } @$elements ]);
						$args{attributes} = $attributes if $attributes;
						return mreturn(Rserve::REXP::Logical->new(%args));
					}
				);
			}
		);
	} else {
		return mreturn(Rserve::REXP::Logical->new);
	}
}

sub rawsxp {
	my $object_info = shift;

	my $dt_length = $object_info->{length},;
	if ($dt_length) {
		return bind(
			\&any_uint32,
			sub {
				my $true_length = shift;
				return unless defined $true_length;
				my $padding_length = $dt_length - $true_length - 4;

				bind(
					seq(count($true_length, \&any_uint8), count($padding_length, \&any_uint8)),
					sub {
						my ($elements, $padding) = @{ shift or return };
						return mreturn(Rserve::REXP::Raw->new($elements));
					}
				);
			}
		);
	} else {
		return mreturn(Rserve::REXP::Raw->new);
	}
}

sub strsxp {
	my ($object_info, $attributes) = @_;

	my $length = $object_info->{length};
	if ($length) {
		return sub {
			my $state  = shift;
			my $end_at = $state->position + $length;

			my @elements;      # elements of the vector
			my @characters;    # characters in the current element
			while ($state->position < $end_at) {
				my $ch = $state->at;
				if (ord($ch)) {
					push @characters, $ch;
				} else {
					my $element = join('', @characters);
					if ($element eq "\xFF") {
						# NaStringRepresentation
						push @elements, undef;
					} else {
						# unescape real \xFF characters
						$element =~ s/\xFF\xFF/\xFF/g;
						push @elements, $element;
					}
					@characters = ();
				}
				$state = $state->next;
			}

			my %args = (elements => [@elements]);
			$args{attributes} = $attributes if $attributes;
			return [ Rserve::REXP::Character->new(%args), $state ];
		}
	} else {
		return mreturn(Rserve::REXP::Character->new);
	}
}

sub vecsxp {
	my ($object_info, $attributes) = @_;

	my $length = $object_info->{length};
	return sub {
		my $state  = shift;
		my $end_at = $state->position + $length;

		my @elements;
		while ($state->position < $end_at) {
			my $result = dt_sexp_data()->($state) or return;

			push @elements, shift @$result;
			$state = shift @$result;
		}
		my %args = (elements => [@elements]);
		$args{attributes} = $attributes if $attributes;
		return [ Rserve::REXP::List->new(%args), $state ];
	}
}

sub expsxp {
	my @args = @_;
	return bind(
		vecsxp(@args),
		sub {
			my $list       = shift;
			my %args       = (elements => $list->elements);
			my $attributes = $list->attributes;
			$args{attributes} = $attributes if $attributes;
			return mreturn(Rserve::REXP::Expression->new(%args));
		}
	);
}

sub tagged_pairlist {
	my $object_info = shift;

	my $length = $object_info->{length};
	if ($length) {
		return sub {
			my $state  = shift;
			my $end_at = $state->position + $length;

			my @elements;
			while ($state->position < $end_at) {
				my $result = dt_sexp_data()->($state) or return;

				my $value = shift @$result;
				$state = shift @$result;

				my $element = { value => $value };
				if ($object_info->{has_tags}) {
					$result = dt_sexp_data()->($state) or return;
					my $tag = shift @$result;

					$element->{tag} = $tag unless $tag->is_null;
					$state = shift @$result;
				}

				push @elements, $element;
			}
			return [ [@elements], $state ];
		}
	} else {
		return mreturn [];
	}
}

# At the REXP level, pairlists are treated the same as generic
# vectors, i.e., as instances of type List. Tags, if present, become
# the name attribute.
sub listsxp {
	my $object_info = shift;
	# The `tagged_pairlist` returns an array of cons cells, and we
	# must separate the tags from the elements before invoking the
	# List constructor, with the tags becoming the names attribute
	return bind(
		tagged_pairlist($object_info),
		sub {
			my $list = shift or return;

			my @elements;
			my @names;
			for my $element (@$list) {
				my $tag   = $element->{tag};
				my $value = $element->{value};
				push @elements, $value;
				push @names,    $tag ? $tag->name : '';
			}

			my %args = (elements => [@elements]);
			# if no element is tagged, then don't construct the
			# 'names' attribute
			if (grep { exists $_->{tag} } @$list) {
				$args{attributes} = { names => Rserve::REXP::Character->new([@names]) };
			}

			return mreturn(Rserve::REXP::List->new(%args));
		}
	);
}

# Language expressions are pairlists, but with a certain structure:
# - the first element is the reference (name or another language
#   expression) to the function call
# - the rest of the list are the arguments of the call, with optional
#   tags to name them
sub langsxp {
	my ($object_info, $attributes) = @_;
	# After the pairlist has been parsed by `tagged_pairlist`, we
	# separate the tags from the elements before invoking the Language
	# constructor, with the tags becoming the names attribute
	return bind(
		tagged_pairlist($object_info),
		sub {
			my $list = shift or return;

			my @elements;
			my @names;
			for my $element (@$list) {
				my $tag   = $element->{tag};
				my $value = $element->{value};
				push @elements, $value;
				push @names,    $tag ? $tag->name : '';
			}

			my %args = (elements => [@elements]);
			# if no element is tagged, then don't construct the 'names' attribute
			if (grep { exists $_->{tag} } @$list) {
				$attributes //= {};    # initialize the hash
				$attributes->{names} = Rserve::REXP::Character->new([@names]);
			}
			$args{attributes} = $attributes if $attributes;

			return mreturn(Rserve::REXP::Language->new(%args));
		}
	);
}

sub dt_sexp_data {
	return bind(unpack_sexp_info, \&sexp_data);
}

sub decode_sexp {
	return bind(seq(uint8(DT_SEXP), \&any_uint24, dt_sexp_data), sub { mreturn shift->[2]; });
}

sub decode_int {
	die 'TODO: implement';
}

sub decode {
	my $data = shift;
	return error 'Decode requires a scalar data or array reference' if ref $data && ref $data ne 'ARRAY';

	endianness('<');

	my $result = decode_sexp->(Rserve::ParserState->new(data => $data));

	if ($result) {
		my $state = $result->[1];
		carp('remaining data: ' . (scalar(@{ $state->data }) - $state->position))
			unless $state->eof;
	}

	return $result;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Rserve::QapEncoding - Functions for parsing Rserve packets

=head1 SYNOPSIS

    use Rserve::QapEncoding qw(decode);

    # Assume $data comes from an Rserve response body.
    my ($rexp, $state) = @{ decode($data) } or die "couldn't parse";

    # If reading a QAP response, there should be no data left unparsed.
    die 'Unread data remaining' unless $state->eof;

    # The result of the unserialization is a REXP.
    say $rexp;

    # REXPs can be converted to the closest native Perl data type
    print $rexp->to_perl;

=head1 DESCRIPTION

This module implements the actual reading of serialized R objects encoded with
Rserve's QAP protocol and their conversion to a L<Rserve::REXP>. You are not
expected to use it directly, as it's normally wrapped by L<Rserve/eval>.

=head1 SUBROUTINES

=head2 decode

    decode($data)

Constructs a L<Rserve::REXP> object from its serialization in C<$data>. Returns
a pair of the object and the L<Rserve::ParserState> at the end of serialization.

=head2 decode_sexp

=head2 decode_int

Parsers for Rserve's C<DT_SEXP> and C<DT_INT> data types, respectively.

=head2 dt_sexp_data

Parses the body of an RServe C<DT_SEXP> object by parsing its header (C<XT_>
type and length) and content (done by sequencing L</unpack_sexp_info> and
L</sexp_data>.

=head2 unpack_sexp_info

Parser for the header (consisting of the C<XT_*> type, flags, and object length)
of a serialized SEXP. Returns a hash with keys "object_type", "has_attributes",
and "length", each corresponding to the field in R serialization described in
L<QAP1 protocol description|http://www.rforge.net/Rserve/dev.html>.

=head2 sexp_data

    sexp_data($obj_info)

Parser for a QAP-serialized R object, using the object type stored in
C<$obj_info> hash's "object_type" key to use the correct parser for the
particular type.

=head2 intsxp

=head2 langsxp

=head2 lglsxp

=head2 listsxp

=head2 rawsxp

=head2 dblsxp

=head2 cplxsxp

=head2 strsxp

=head2 symsxp

=head2 vecsxp

=head2 expsxp

Parsers for the corresponding R SEXP-types.

=head2 nosxp

Parser for the Rserve's C<XT_UNKNOWN> type, encoding an R SEXP-type that does
not have a corresponding representation in QAP.

=head2 maybe_attributes

    maybe_attributes($object_info)

Convenience parser for SEXP attributes, which are serialized as a tagged
pairlist C<XT_LIST_TAG> followed by a SEXP for the object value. Attributes are
stored only if C<$object_info> indicates their presence. Returns a pair of
C<$object_info> and a hash reference to the attributes, as returned by
L</tagged_pairlist_to_attribute_hash>.

=head2 tagged_pairlist

Parses a pairlist (optionally tagged) and returns an array where each element is
a hash containing keys C<value> (the REXP of the pairlist element) and,
optionally, C<tag>.

=head2 tagged_pairlist_to_rexp_hash

Converts a pairlist to a REXP hash whose keys are the pairlist's element tags
and values the pairlist elements themselves.

=head2 tagged_pairlist_to_attribute_hash

Converts object attributes, which are serialized as a pairlist with attribute
name in the element's tag, to a hash that can be used as the C<attributes>
argument to L<Rserve::REXP> constructors.

Some attributes are serialized using a compact encoding (for instance, when a
table's row names are just integers 1:nrows), and this function will decode them
to a complete REXP.

=cut
