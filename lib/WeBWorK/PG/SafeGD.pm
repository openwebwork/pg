package WeBWorK::PG::SafeGD;

=head1 NAME

WeBWorK::PG::SafeGD - Restrict GD::Image new method file path arguments to
permitted_read_dir.

=head1 DESCRIPTION

GD is shared into the safe compartment for graphing macros (via WWPlot and the
PGgraphmacros.pl macro). Several of the GD::Image methods take a file path
argument and open it directly, with no restriction (C<new>, C<newFromPng>,
C<newFromJpeg>, C<newFromGif>, C<newFromTiff>, C<newFromXbm>, C<newFromWebp>,
C<newFromHeif>, C<newFromWBMP>, C<newFromBmp>, C<newFromGd>, C<newFromGd2>,
C<newFromGd2Part>, and C<newFromXpm>). The C<restrict> method in this package
ensures that if those methods are called on an unsafe path (a path not in the
C<permitted_read_dir>), the methods do not reveal anything about the existence
or lack thereof for the file path argument. The C<WWPlot> package does not use
these path-taking forms (only the numeric-size constructor is used).

C<restrict> patches the GD::Image symbol table in place, so it only needs to run
once per process, after GD itself has been loaded.

=cut

use strict;
use warnings;

use WeBWorK::PG::IO;

my $patched = 0;

# Only reject arguments that look like they're meant to be a path (a plain string, not an
# already-open filehandle/IO object) and that GD would otherwise try to open unrestricted.
sub _unsafe_path {
	my $path = shift;
	return 0 if ref $path;
	return 0 unless defined $path && length $path;
	return !WeBWorK::PG::IO::path_is_subdir($path, $WeBWorK::PG::IO::pg_envir->{directories}{permitted_read_dir});
}

sub restrict {
	return if $patched || !GD::Image->can('_make_filehandle');
	$patched = 1;

	no warnings qw(redefine prototype);

	# Every newFrom* method implemented in GD/Image.pm other than the XS methods (Png, Jpeg, Gif, Tiff, Xbm, Webp, Heif,
	# WBMP, and Bmp) call _make_filehandle. The new method does as well, but is wrapped separately below, since it
	# touches the filesystem before calling this.
	my $orig_make_filehandle = \&GD::Image::_make_filehandle;
	*GD::Image::_make_filehandle = sub {
		die "GD: refusing to open \"$_[1]\" as it is not in an allowed location.\n" if _unsafe_path($_[1]);
		goto &$orig_make_filehandle;
	};

	# The single argument form of new executes -f tests on the given file path argument before it calls
	# _make_filehandle. Skip the check only when the argument is recognized as raw image data rather than a path at all,
	# since then no file access happens anywhere. Otherwise $! is set for non-existent files, and so this can be used
	# for a file existence test in a problem.
	my $orig_new = \&GD::Image::new;
	*GD::Image::new = sub {
		die "GD: refusing to open \"$_[1]\" as it is not in an allowed location.\n"
			if @_ == 2 && !ref $_[1] && !GD::Image::_image_type($_[1]) && _unsafe_path($_[1]);
		goto &$orig_new;
	};

	# These are implemented in XS and take a file path directly, bypassing _make_filehandle.
	no strict 'refs';
	for my $method (qw(newFromGd newFromGd2 newFromGd2Part newFromXpm)) {
		next unless GD::Image->can($method);
		my $orig = \&{"GD::Image::$method"};
		*{"GD::Image::$method"} = sub {
			die "GD: refusing to open \"$_[1]\" as it is not in an allowed location.\n" if _unsafe_path($_[1]);
			goto &$orig;
		};
	}
	use strict 'refs';

	# stringFT's font file argument is only restricted when it looks like an absolute path, since it may legitimately be
	# a relative name or fontconfig pattern (e.g. after useFontConfig) instead of a path.
	if (GD::Image->can('stringFT')) {
		my $orig_string_ft = \&GD::Image::stringFT;
		*GD::Image::stringFT = sub {
			die "GD: refusing to open \"$_[2]\" as it is not in an allowed location.\n"
				if defined $_[2] && !ref $_[2] && $_[2] =~ m{^/} && _unsafe_path($_[2]);
			goto &$orig_string_ft;
		};
		# stringTTF is a plain alias for stringFT set up when GD::Image was loaded, so it still points
		# to the original, unwrapped sub unless it is re-aliased here.
		*GD::Image::stringTTF = \&GD::Image::stringFT;
	}

	use warnings qw(redefine prototype);

	return;
}

1;
