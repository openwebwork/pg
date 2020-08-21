################################################################################
# WeBWorK mod_perl (c) 2000-2002 WeBWorK Project
# $Id$
################################################################################

package WeBWorK::EquationCache;

=head1 NAME

WeBWorK::EquationCache - create and cache images of TeX equations.

=head1 SYNPOSIS

 my $cache = WeBWorK::EquationCache->new(cacheDB => "/path/to/equationcache.db");
 my $imageName = $cache->lookup('\[3x^2\]');

=head1 DESCRIPTION

WeBWorK::PG::EquationCache maintains a list of unique identifiers for TeX
strings. The unique identifier is based on an MD5 hash of the TeX string, and a
sequence number. Before calcuating the MD5 hash of a TeX string, all whitespace
is removed.

=head2 FILE FORMAT

The cache database file is a text file consisting of lines of the following
form:

 md5_hash     sequence_number     tex_string

Any amount of whitespace may separate the fields. Lines which do not conform to
this format are ignored. Any string of characters beginning with `#' and
extending to the end of the line is also ignored.

=cut

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use Encode qw(encode_utf8 decode_utf8 decode);
use Fcntl qw(:DEFAULT :flock);
BEGIN { my @_junk = (O_RDWR,O_CREAT,LOCK_EX) } # get rid of "subroutine redefined" warnings

=head1 METHODS

=over

=item new(%options)

Returns a new EquationCache object. C<%options> must contain the following
entries:

 cacheDB => path to image cache database file

If cacheDB is the empty string, don't use a cache file and assume that there
are no md5 collisions.

=cut

sub new {
	my ($invocant, %options) = @_;
	my $class = ref $invocant || $invocant;
	my $self = {
		%options,
	};
	
	bless $self, $class;
}

=item lookup

Looks up a TeX string in the database. A unique identifier for the cached image
is returned. If necessary, the string is added to the database.

=cut

sub lookup {
	my ($self, $tex) = @_;
	# There are several ways to normalize TeX strings.  Use only
	# one of them.

	# Option 1 (default): remove leading and trailing whitespace, and
	# compress all other whitespace to single spaces.
	$tex =~ s/^\s+//g;
	$tex =~ s/\s+$//g;
	$tex =~ s/\s+/ /g;
	# Option 2 (the old default): remove all whitespace
	# $tex =~ s/\s+//g;

	my $md5 = md5_hex(encode_utf8($tex));
	
	my $db = $self->{cacheDB};
	unless($db) { return($md5 ."1"); }
	sysopen(DB, $db, O_RDWR|O_CREAT)
		or die "failed to create/open cacheDB $db: $!";
	flock(DB, LOCK_EX)
		or die "failed to write-lock cacheDB $db: $!";
	
	my $line = 0;
	my $max = 0;
	my $match = 0;
	local $/ = "\n";
	while (<DB>) {
		# find matching MD5 hashes
		next unless m/^$md5\s+(\d+)\s+(.*)$/;
		if ($tex = $2) {
			# the TeX string matches: use this instance number and stop looking
			$match = $1;
			last;
		} else {
			# the TeX string doesn't match: record instance number and keep looking
			$max = $1 if $1 > $max;
		}
	}
	
	unless ($match) {
		# no match: invent a new instance number and add TeX string to DB
		$match = $max + 1;
		seek(DB, 0, 2); # we should already be at EOF, but what the hell.
		print DB "$md5\t$match\t$tex\n";
	}
	
	close(DB);
	return "$md5$match";
}

1;
