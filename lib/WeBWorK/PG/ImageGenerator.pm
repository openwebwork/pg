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

package WeBWorK::PG::ImageGenerator;

=head1 NAME

WeBWorK::PG::ImageGenerator - create an object for holding bits of math for
LaTeX, and then to process them all at once.

=head1 SYNPOSIS

    my $image_generator = WeBWorK::PG::ImageGenerator->new(
        tempDir         => $pg_envir->{directories}{tmp},
        latex           => $pg_envir->{externalPrograms}{latex},
        dvipng          => $pg_envir->{externalPrograms}{dvipng},
        useCache        => 1,
        cacheDir        => $pg_envir->{directories}{equationCache},
        cacheURL        => $pg_envir->{URLs}{equationCache},
        cacheDB         => $pg_envir->{equationCacheDB},
        useMarkers      => 0,
        dvipng_align    => $pg_envir->{displayModeOptions}{images}{dvipng_align},
        dvipng_depth_db => $pg_envir->{displayModeOptions}{images}{dvipng_depth_db},
    );

=cut

use strict;
use warnings;
use feature 'signatures';
no warnings qw(experimental::signatures);

use DBI;
use PGcore;
use WeBWorK::PG::Constants;
use WeBWorK::PG::EquationCache;

use File::Path qw(rmtree);

sub readFile ($filename) {
	my $contents = '';
	open(my $fh, '<', $filename) or die "Unable to read $filename";
	local $/ = undef;
	$contents = <$fh>;
	close $fh;
	return $contents;
}

sub readDirectory ($dirName) {
	opendir my $dh, $dirName
		or die "Failed to read directory $dirName: $!";
	my @result = readdir $dh;
	close $dh;
	return @result;
}

sub makeTempDirectory ($parent, $basename) {
	# Loop until we're able to create a directory, or it fails for some
	# reason other than there already being something there.
	my ($fullPath, $success);
	do {
		my $suffix = join '', map { ('A' .. 'Z', 'a' .. 'z', '0' .. '9')[ int rand 62 ] } 1 .. 8;
		$fullPath = "$parent/$basename.$suffix";
		$success  = mkdir $fullPath;
	} until ($success or not $!{EEXIST});
	unless ($success) {
		my $msg = '';
		$msg .= "Server does not have write access to the directory $parent" unless -w $parent;
		die "$msg\r\nFailed to create directory $fullPath:\r\n $!";
	}

	return $fullPath;
}

sub removeTempDirectory ($dir) {
	rmtree($dir, 0, 0);
	return;
}

################################################################################

=head1 CONFIGURATION VARIABLES

=over

=item $DvipngArgs

Arguments to pass to dvipng.

=cut

our $DvipngArgs = '' unless defined $DvipngArgs;

=item $PreserveTempFiles

If true, don't delete temporary files.

=cut

our $PreserveTempFiles = 0 unless defined $PreserveTempFiles;

=item $TexPreamble

TeX to prepend to equations to be processed.

=cut

our $TexPreamble = '' unless defined $TexPreamble;

=item $TexPostamble

TeX to append to equations to be processed.

=cut

our $TexPostamble = '' unless defined $TexPostamble;

=back

=cut

################################################################################

=head1 METHODS

=over

=item new

Returns a new ImageGenerator object. C<%options> must contain the following
entries:

 tempDir  => directory in which to create temporary processing directory
 latex    => path to latex binary
 dvipng   => path to dvipng binary
 useCache => boolean, whether to use global image cache

If C<useCache> is false, C<%options> must also contain the following entries:

 dir	  => directory for resulting files
 url	  => url to directory for resulting files
 basename => base name for image files (i.e. "eqn-$psvn-$probNum")

If C<useCache> is true, C<%options> must also contain the following entries:

 cacheDir => directory for resulting files
 cacheURL => url to cacheDir
 cacheDB  => path to cache database file

Options may also contain:

 dvipng_align    => Vertical alignment option.  This should be any of the valid values
                    for the css vertical-align rule like 'baseline' or 'middle'.
 dvipng_depth_db => Database connection information for a database that has the 'depths' table.
 useMarkers      => If you want to have the dvipng images vertically aligned, this involves adding markers.
                    This only works if dvipng depths are stored and the body_text is provided.


=cut

sub new ($invocant, %options) {
	my $class = ref $invocant || $invocant;
	my $self  = {
		names                => [],
		strings              => [],
		texPreambleAdditions => undef,
		depths               => {},
		%options,
	};

	$self->{dvipng_align} //= 'baseline';

	# Fix invalid mysql values.
	$self->{dvipng_align} = 'baseline' if $self->{dvipng_align} eq 'mysql';

	$self->{store_depths} = 1 if $self->{dvipng_depth_db}{dbsource} ne '';
	$self->{useMarkers}   = 0 unless $self->{store_depths};

	if ($self->{useCache}) {
		$self->{dir}           = $self->{cacheDir};
		$self->{url}           = $self->{cacheURL};
		$self->{basename}      = '';
		$self->{equationCache} = WeBWorK::PG::EquationCache->new(cacheDB => $self->{cacheDB});
	}

	return bless $self, $class;
}

=item addToTeXPreamble($string)

Adds the string as part of the TeX preamble for all equations in the problem.
For example
   $rh_envir->{imagegen}->addToTeXPreamble("\newcommand{\myVec}[#1]{\vec{#1}} ");

Will define a question wide style for interpreting
   \( \myVec{v}  \)

If this statement is placed in PGcourse.pl then the backslashes must be doubled since it is a .pl file
not a .pg file

=cut

sub addToTeXPreamble ($self, $str = undef) {
	$self->{texPreambleAdditions} = $str if defined $str;
	return $self->{texPreambleAdditions};
}

=item refresh(1)

Forces every equation picture to be recalculated. Useful for debugging.

	$rh_envir->{imagegen}->refresh(1);

=cut

sub refresh ($self, $in) {
	$self->{refresh} = $in if defined($in);
	return $self->{refresh};
}

=item add($string, $mode)

Adds the equation in C<$string> to the object. C<$mode> can be "display" or
"inline". If not specified, "inline" is assumed. Returns the proper HTML tag
for displaying the image.

=cut

sub add ($self, $string, $mode = 'inline') {
	my $names    = $self->{names};
	my $strings  = $self->{strings};
	my $dir      = $self->{dir};
	my $url      = $self->{url};
	my $basename = $self->{basename};
	my $useCache = $self->{useCache};
	my $depths   = $self->{depths};

	# If the string came in with delimiters, chop them off and set the mode
	# based on whether they were \[ .. \] or \( ... \). this means that if
	# the string has delimiters, the mode *argument* is ignored.
	if ($string =~ s/^\\\[(.*)\\\]$/$1/s) {
		$mode = "display";
	} elsif ($string =~ s/^\\\((.*)\\\)$/$1/s) {
		$mode = "inline";
	}

	# Generate the string to pass to latex.
	my $realString = ($mode eq "display") ? '\(\displaystyle{' . $string . '}\)' : '\(' . $string . '\)';

	# Alignment tag could be a fixed default
	my ($imageNum, $aligntag) = (0, qq{style="vertical-align:$self->{dvipng_align}"});

	# Determine what the image's "number" is.
	if ($useCache) {
		$imageNum            = $self->{equationCache}->lookup($realString);
		$aligntag            = 'MaRkEr' . $imageNum if $self->{useMarkers};
		$depths->{$imageNum} = 'none'               if $self->{store_depths};
		# Insert a slash after 2 characters.  This effectively divides the images into 16^2 = 256 subdirectories.
		substr($imageNum, 2, 0) = '/';
	} else {
		$imageNum = @$strings + 1;
	}

	# We are banking on the fact that if useCache is true, then basename is empty.
	# Maybe we should simplify and drop support for useCache = 0 and having a basename.

	# get the full file name of the image
	my $imageName = $basename ? "$basename.$imageNum.png" : "$imageNum.png";

	# Store the full file name of the image, and the tex string to the object.
	push @$names,   $imageName;
	push @$strings, $realString;

	my $imageURL   = "$url/$imageName";
	my $safeString = PGcore::encode_pg_and_html($string);

	my $imageTag =
		($mode eq "display")
		? "<div align=\"center\"><img src=\"$imageURL\" $aligntag alt=\"$safeString\"></div>"
		: "<img src=\"$imageURL\" $aligntag alt=\"$safeString\">";

	return $imageTag;
}

=item render(%options)

Uses LaTeX and dvipng to render the equations stored in the object.

The option C<body_text> is a reference to the text of the problem's text.  After
rendering the images and figuring out their depths, we go through and fix the tags
of the images to get the vertical alignment right.  If it is left out, then we skip
that step.

=back

=cut

sub render ($self, %options) {
	my $tempDir  = $self->{tempDir};
	my $dir      = $self->{dir};
	my $basename = $self->{basename};
	my $latex    = $self->{latex};
	my $dvipng   = $self->{dvipng};
	my $names    = $self->{names};
	my $strings  = $self->{strings};
	my $depths   = $self->{depths};
	$self->{body_text} = $options{body_text};

	# Recreate every equation image (default is do not refresh).
	my $forceRefresh = $self->{refresh} || 0;

	# Check that the equations directory exists and create if it doesn't.
	unless (-e $dir) {
		my $success = mkdir $dir;
		warn "Could not make directory $dir" unless $success;
	}

	# Determine which images need to be generated.
	my (@newStrings, @newNames);
	for (my $i = 0; $i < @$strings; $i++) {
		my $string = $strings->[$i];
		my $name   = $names->[$i];
		if ($forceRefresh || !-e "$dir/$name") {
			push @newStrings, $string;
			push @newNames,   $name;
		}
	}

	if (@newStrings) {    # Don't run latex if there are no images to generate

		# Create a temporary directory in which to do TeX processing.
		my $wd = makeTempDirectory($tempDir, "ImageGenerator");

		# Store equations in a tex file.
		my $texFile = "$wd/equation.tex";
		open my $tex, ">", $texFile
			or die "failed to open file $texFile for writing: $!";
		print $tex $TexPreamble;
		print $tex $self->{texPreambleAdditions} if defined($self->{texPreambleAdditions});
		print $tex "$_\n" foreach @newStrings;
		print $tex $TexPostamble;
		close $tex;
		warn "tex file $texFile was not written" unless -e $texFile;

		# Call LaTeX
		my $latexCommand = "cd $wd && $latex equation > latex.out 2> latex.err";
		my $latexStatus  = system $latexCommand;

		if ($latexStatus and $latexStatus != 256) {
			warn "$latexCommand returned non-zero status $latexStatus: $!";
			warn "cd $wd failed" if system "cd $wd";
			warn "Unable to write to directory $wd. " unless -w $wd;
			warn "Unable to execute $latex "          unless -e $latex;

			warn `ls -l $wd`;
			my $errorMessage = '';
			if (-r "$wd/equation.log") {
				$errorMessage = readFile("$wd/equation.log");
				warn "<pre>Logfile contents:\n$errorMessage\n</pre>";
			} else {
				warn "Unable to read logfile $wd/equation.log ";
			}
		}

		warn "$latexCommand failed to generate a DVI file"
			unless -e "$wd/equation.dvi";

		# Call dvipng
		my $dvipngCommand = "cd $wd && $dvipng " . $DvipngArgs . " equation > dvipng.out 2> dvipng.err";
		my $dvipngStatus  = system $dvipngCommand;
		warn "$dvipngCommand returned non-zero status $dvipngStatus: $!"
			if $dvipngStatus;

		# Get depths
		my $dvipngout = '';
		$dvipngout = readFile("$wd/dvipng.out") if (-r "$wd/dvipng.out");
		my @dvipngdepths = ($dvipngout =~ /depth=(\d+)/g);

		# Kill them all if something goes wrong
		@dvipngdepths = () if (scalar(@dvipngdepths) != scalar(@newNames));

		# move/rename images
		chmod(0664, <$wd/*>);    # Make everything group writable so that a WeBWorK admin can delete images
		foreach my $image (readDirectory($wd)) {
			# Only work on equation*.png files
			next unless $image =~ m/^equation(\d+)\.png$/;

			# Get image number from above match
			my $imageNum = $1;
			# Note, problems with solutions/hints can have empty values in newNames.
			next unless $newNames[ $imageNum - 1 ];

			# Record the dvipng offset.
			my $hashkey = $newNames[ $imageNum - 1 ];
			$hashkey =~ s|/||;
			$hashkey =~ s|\.png$||;
			$depths->{$hashkey} = $dvipngdepths[ $imageNum - 1 ] if defined $dvipngdepths[ $imageNum - 1 ];

			# Check to see if this requires a directory we haven't made yet.
			my $newdir = $newNames[ $imageNum - 1 ];
			$newdir =~ s|/.*$||;
			if ($newdir and not -d "$dir/$newdir") {
				my $success = mkdir "$dir/$newdir";
				# Make the directory group writable so that a WeBWorK admin can delete images
				chmod(0775, <$dir/$newdir>);
				warn "Could not make directory $dir/$newdir" unless $success;
			}

			# move/rename image
			my $mvCommand = "cd $wd && /bin/mv $wd/$image $dir/" . $newNames[ $imageNum - 1 ];
			my $mvStatus  = system $mvCommand;
			if ($mvStatus) {
				warn "$mvCommand returned non-zero status $mvStatus: $!";
				warn "Can't write to tmp/equations directory $dir" unless -w $dir;
			}

		}

		if ($PreserveTempFiles) {
			warn "ImageGenerator: preserved temp files in working directory '$wd'.\n";
			chmod(0775, $wd);
			chmod(0664, <$wd/*>);
		} else {
			# Remove the temporary directory and its contents.
			removeTempDirectory($wd);
		}
	}

	$self->update_depth_cache;
	$self->fix_markers;

	return;
}

# Internal utility function for updating both the internal record of dvipng depths
# and the database.  This is the main function to change (provide an alternate
# method for) if you want to add another method for storing dvipng depths
sub update_depth_cache ($self) {
	return unless $self->{store_depths};

	my $dbh = DBI->connect_cached(
		$self->{dvipng_depth_db}{dbsource},
		$self->{dvipng_depth_db}{user},
		$self->{dvipng_depth_db}{passwd}
	);
	my $sth =
		$dbh->prepare($self->{dvipng_depth_db}{dbsource} =~ /:SQLite:/
			? 'INSERT OR IGNORE INTO depths(md5, depth) VALUES (?,?)'
			: 'INSERT IGNORE INTO depths(md5, depth) VALUES (?,?)');

	for my $md5 (keys %{ $self->{depths} }) {
		if ($self->{depths}{$md5} eq 'none') {
			my $got_values = $dbh->selectall_arrayref('SELECT depth FROM depths WHERE md5 = ?', undef, $md5);
			$self->{depths}{$md5} = $got_values->[0][0] if @$got_values;
		} else {
			$sth->execute($md5, $self->{depths}{$md5});
		}
	}
	return;
}

sub fix_markers ($self) {
	return unless $self->{useMarkers} && defined $self->{body_text};

	my %depths = %{ $self->{depths} };
	for my $depthkey (keys %depths) {
		if ($depths{$depthkey} eq 'none') {
			${ $self->{body_text} } =~ s/MaRkEr$depthkey/style="vertical-align:"$self->{dvipng_align}"/g;
		} else {
			my $ndepth = 0 - $depths{$depthkey};
			${ $self->{body_text} } =~ s/MaRkEr$depthkey/style="vertical-align:${ndepth}px"/g;
		}
	}
	return;
}

1;
