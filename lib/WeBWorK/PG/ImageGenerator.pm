################################################################################
# WeBWorK mod_perl (c) 2000-2002 WeBWorK Project
# $Id$
################################################################################

package WeBWorK::PG::ImageGenerator;

=head1 NAME

WeBWorK::PG::ImageGenerator - create an object for holding bits of math for
LaTeX, and then to process them all at once.

=head1 SYNPOSIS

FIXME: add this

=cut

# Note, this now has the ability to communicate with mysql for storing depths of
# images for alignments.  If you want to provide another way of storing the depths,
# make up another "magic" alignment name, look for explicit mentions of mysql here
# and add statements for the new special alignment name.  Most of the action is
# in the function update_depth_cache near the end of this file.  Also look for the
# place where PG creates a new ImageGenerator object, and possibly adjust there as
# well.

use strict;
use warnings;
use DBI;
use PGcore;
use WeBWorK::Constants;
use WeBWorK::EquationCache;

# can't use WeBWorK::Utils from here, so we define the needed functions here
#use WeBWorK::Utils qw/readFile readDirectory makeTempDirectory removeTempDirectory/;

use constant MKDIR_ATTEMPTS => 10;
use File::Path qw(rmtree);

sub readFile($) {
	my $filename = shift;
	my $contents = '';
	local(*FILEH);
	open FILEH,  "<$filename" or die "Unable to read $filename";
	local($/) = undef;
	$contents = <FILEH>;
	close(FILEH);
	return($contents);
}

sub readDirectory($) {
	my $dirName = shift;
	opendir my $dh, $dirName
		or die "Failed to read directory $dirName: $!";
	my @result = readdir $dh;
	close $dh;
	return @result;
}

sub makeTempDirectory($$) {
	my ($parent, $basename) = @_;
	# Loop until we're able to create a directory, or it fails for some
	# reason other than there already being something there.
	my $triesRemaining = MKDIR_ATTEMPTS;
	my ($fullPath, $success);
	do {
		my $suffix = join "", map { ('A'..'Z','a'..'z','0'..'9')[int rand 62] } 1 .. 8;
		$fullPath = "$parent/$basename.$suffix";
		$success = mkdir $fullPath;
	} until ($success or not $!{EEXIST});
	unless ($success) {
		my $msg = '';
		$msg    .=  "Server does not have write access to the directory $parent" unless -w $parent;
		die "$msg\r\nFailed to create directory $fullPath:\r\n $!"
	}

	return $fullPath;
}

sub removeTempDirectory($) {
	my ($dir) = @_;
	rmtree($dir, 0, 0);
}

################################################################################

=head1 CONFIGURATION VARIABLES

=over

=item $DvipngArgs

Arguments to pass to dvipng.

=cut

our $DvipngArgs = "" unless defined $DvipngArgs;

=item $PreserveTempFiles

If true, don't delete temporary files.

=cut

our $PreserveTempFiles = 0 unless defined $PreserveTempFiles;

=item $TexPreamble

TeX to prepend to equations to be processed.

=cut

our $TexPreamble = "" unless defined $WeBWorK::PG::ImageGenerator::TexPreamble;

=item $TexPostamble

TeX to append to equations to be processed.

=cut

our $TexPostamble = "" unless defined $TexPostamble;

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

 dvipng_align    => vertical alignment option (a string to use like baseline, or 'mysql')
 dvipng_depth_db => database connection information for a "depths database"
 useMarkers      => if you want to have the dvipng images vertically aligned, this involves adding markers

=cut

sub new {
	my ($invocant, %options) = @_;
	my $class = ref $invocant || $invocant;
	my $self = {
		names   => [],
		strings => [],
		texPreambleAdditions => undef,
		depths => {},
		%options,
	};

	# set some values
	$self->{dvipng_align} = 'absmiddle' unless defined($self->{dvipng_align});
	$self->{store_depths} = 1 if ($self->{dvipng_align} eq 'mysql');
	$self->{useMarkers} = $self->{useMarkers} || 0;
	
	if ($self->{useCache}) {
		$self->{dir} = $self->{cacheDir};
		$self->{url} = $self->{cacheURL};
		$self->{basename} = "";
		$self->{equationCache} = WeBWorK::EquationCache->new(cacheDB => $self->{cacheDB});
	}
	
	bless $self, $class;
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

sub addToTeXPreamble {
	my $self  = shift;
	my $str   = shift;
	$self->{texPreambleAdditions} = $str if defined $str;
	$self->{texPreambleAdditions};
}

=item refresh(1)

Forces every equation picture to be recalculated. Useful for debugging.
	$rh_envir->{imagegen}->refresh(1);

=cut

sub refresh {
	my $self  = shift;
	my $in   = shift;
	$self->{refresh} = $in if defined($in);
	$self->{refresh};
}

=item add($string, $mode)

Adds the equation in C<$string> to the object. C<$mode> can be "display" or
"inline". If not specified, "inline" is assumed. Returns the proper HTML tag
for displaying the image.

=cut

sub add {
	my ($self, $string, $mode) = @_;
	
	my $names    = $self->{names};
	my $strings  = $self->{strings};
	my $dir      = $self->{dir};
	my $url      = $self->{url};
	my $basename = $self->{basename};
	my $useCache = $self->{useCache};
	my $depths   = $self->{depths};
	
	# if the string came in with delimiters, chop them off and set the mode
	# based on whether they were \[ .. \] or \( ... \). this means that if
	# the string has delimiters, the mode *argument* is ignored.
	if ($string =~ s/^\\\[(.*)\\\]$/$1/s) {
		$mode = "display";
	} elsif ($string =~ s/^\\\((.*)\\\)$/$1/s) {
		$mode = "inline";
	}
	# otherwise, leave the string and the mode alone.
	
	# assume that a bare string with no mode specified is inline
	$mode ||= "inline";
	
	# now that we know what mode we're dealing with, we can generate a "real"
	# string to pass to latex
	my $realString = ($mode eq "display")
		? '\(\displaystyle{' . $string . '}\)'
		: '\(' . $string . '\)';
	
	# alignment tag could be a fixed default
	my ($imageNum, $aligntag) = (0, qq|align="$self->{dvipng_align}"|);
	# if the default is for variable heights, the default should be meaningful
	# in an answer preview, $self->{dvipng_align} might be 'mysql', but we still
        # use a static alignment
	$aligntag = 'align="baseline"' if ($self->{dvipng_align} eq 'mysql');

	# determine what the image's "number" is
	if($useCache) {
		$imageNum = $self->{equationCache}->lookup($realString);
		$aligntag = 'MaRkEr'.$imageNum if $self->{useMarkers};
		$depths->{"$imageNum"} = 'none' if ($self->{dvipng_align} eq 'mysql');
		# insert a slash after 2 characters
		# this effectively divides the images into 16^2 = 256 subdirectories
		substr($imageNum,2,0) = '/';
	} else {
		$imageNum = @$strings + 1;
	}
	
	# We are banking on the fact that if useCache is true, then basename is empty.
	# Maybe we should simplify and drop support for useCache =0 and having a basename.

	# get the full file name of the image
	my $imageName = ($basename)
		? "$basename.$imageNum.png"
		: "$imageNum.png";
	
	# store the full file name of the image, and the "real" tex string to the object
	push @$names, $imageName;
	push @$strings, $realString;
	#warn "ImageGenerator: added string $realString with name $imageName\n";
	
	# ... and the full URL.
	my $imageURL = "$url/$imageName";
	
	my $safeString = PGcore::encode_pg_and_html($string);

	my $imageTag  = ($mode eq "display")
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

=for comment

If the key "mtime" in C<%options> is given, its value will be interpreted as a
unix date and compared with the modification date on any existing copy of the
first image to be generated. It is recommended that the modification time of the
source file from which the equations originate be used for this value. If the
key "refresh" in C<%options> is true, images will be regenerated regardless of
when they were last modified. If neither option is supplied, "refresh" is
assumed.

NOTE: It's not clear to me that mtime has been implemented -- MEG - 2011/06

=cut

sub render {
	my ($self, %options) = @_;
	
	my $tempDir  = $self->{tempDir};
	my $dir      = $self->{dir};
	my $basename = $self->{basename};
	my $latex    = $self->{latex};
	my $dvipng   = $self->{dvipng};
	my $names    = $self->{names};
	my $strings  = $self->{strings};
	my $depths   = $self->{depths};
	$self->{body_text} = $options{body_text};
	my $forceRefresh = $self->{refresh} || 0;      # recreate every equation image -- default is do not refresh

	###############################################
	# check that the equations directory exists and create if it doesn't
	###############################################
	unless (-e "$dir") {
		my $success = mkdir "$dir";
		warn "Could not make directory $dir" unless $success;
	}
	
	###############################################			
	# determine which images need to be generated
	###############################################
	my (@newStrings, @newNames);
	for (my $i = 0; $i < @$strings; $i++) {
		my $string = $strings->[$i];
		my $name = $names->[$i];
		if (!$forceRefresh and -e "$dir/$name") {
			#warn "ImageGenerator: found a file named $name, skipping string $string\n";
		} else {
			#warn "ImageGenerator: didn't find a file named $name, including string $string\n";
			push @newStrings, $string;
			push @newNames, $name;
		}
	}
	
    if(@newStrings) { # Don't run latex if there are no images to generate
		
		# create temporary directory in which to do TeX processing
		my $wd = makeTempDirectory($tempDir, "ImageGenerator");
		
		# store equations in a tex file
		my $texFile = "$wd/equation.tex";
		open my $tex, ">", $texFile
			or die "failed to open file $texFile for writing: $!";
		print $tex $TexPreamble;
		print $tex $self->{texPreambleAdditions} if defined($self->{texPreambleAdditions});
		print $tex "$_\n" foreach @newStrings;
		print $tex $TexPostamble;
		close $tex;
		warn "tex file $texFile was not written" unless -e $texFile;
		
		###############################################
		# call LaTeX
		###############################################
		my $latexCommand  = "cd $wd && $latex equation > latex.out 2> latex.err";
		my $latexStatus = system $latexCommand;
	
		if ($latexStatus and $latexStatus !=256) {
			warn "$latexCommand returned non-zero status $latexStatus: $!";
			warn "cd $wd failed" if system "cd $wd";
			warn "Unable to write to directory $wd. " unless -w $wd;
			warn "Unable to execute $latex " unless -e $latex ;
			
			warn `ls -l $wd`;
			my $errorMessage = '';
			if (-r "$wd/equation.log") {
				$errorMessage = readFile("$wd/equation.log");
				warn "<pre> Logfile contents:\n$errorMessage\n</pre>";
			} else {
			   warn "Unable to read logfile $wd/equation.log ";
			}
		}
	
		warn "$latexCommand failed to generate a DVI file"
			unless -e "$wd/equation.dvi";
		
		############################################
		# call dvipng
		############################################
		my $dvipngCommand = "cd $wd && $dvipng " . $DvipngArgs . " equation > dvipng.out 2> dvipng.err";
		my $dvipngStatus = system $dvipngCommand;
		warn "$dvipngCommand returned non-zero status $dvipngStatus: $!"
			if $dvipngStatus;
		# get depths
		my $dvipngout = '';
		$dvipngout = readFile("$wd/dvipng.out") if(-r "$wd/dvipng.out");
		my @dvipngdepths = ($dvipngout =~ /depth=(\d+)/g);
		# kill them all if something goes wrnog
		@dvipngdepths = () if(scalar(@dvipngdepths) != scalar(@newNames));
	
		############################################
		# move/rename images
		############################################
	
	  chmod (0664,<$wd/*>);  # first make everything group writable so that a WeBWorK admin can delete images
		foreach my $image (readDirectory($wd)) {
			# only work on equation#.png files
			next unless $image =~ m/^equation(\d+)\.png$/;
			
			# get image number from above match
			my $imageNum = $1;
			# note, problems with solutions/hints can have empty values in newNames
			next unless $newNames[$imageNum-1];
	
			# record the dvipng offset
			my $hashkey = $newNames[$imageNum-1];
			$hashkey =~ s|/||;
			$hashkey =~ s|\.png$||;
			$depths->{"$hashkey"} = $dvipngdepths[$imageNum-1] if(defined($dvipngdepths[$imageNum-1]));
			
			#warn "ImageGenerator: found generated image $imageNum with name $newNames[$imageNum-1]\n";
			
			# move/rename image
			#my $mvCommand = "cd $wd && /bin/mv $wd/$image $dir/$basename.$imageNum.png";
			# check to see if this requires a directory we haven't made yet
			my $newdir = $newNames[$imageNum-1];
			$newdir =~ s|/.*$||;
			if($newdir and not -d "$dir/$newdir") {
				my $success = mkdir "$dir/$newdir";
				chmod (0775,<$dir/$newdir>); # make the directory group writable so that a WeBWorK admin can delete images
				warn "Could not make directory $dir/$newdir" unless $success;
			}
			my $mvCommand = "cd $wd && /bin/mv $wd/$image $dir/" . $newNames[$imageNum-1];
			my $mvStatus = system $mvCommand;
			if ( $mvStatus) {
				warn "$mvCommand returned non-zero status $mvStatus: $!";
				warn "Can't write to tmp/equations directory $dir" unless -w $dir;
			}
	
		}
		############################################
		# remove temporary directory (and its contents)
		############################################
	
		if ($PreserveTempFiles) {
			warn "ImageGenerator: preserved temp files in working directory '$wd'.\n";
			chmod (0775,$wd);
			chmod (0664,<$wd/*>);
		} else {
			removeTempDirectory($wd);
		}
    }
    $self->update_depth_cache() if $self->{store_depths};
    $self->fix_markers() if ($self->{useMarkers} and defined $self->{body_text});
}

# internal utility function for updating both our internal record of dvipng depths,
# but also the database.  This is the main function to change (provide an alternate
# method for) if you want to use another method for storing dvipng depths

sub update_depth_cache {
	my $self = shift;
	return() unless ($self->{dvipng_align} eq 'mysql');
	my $dbh = DBI->connect_cached($self->{dvipng_depth_db}->{dbsource},
	   $self->{dvipng_depth_db}->{user}, $self->{dvipng_depth_db}->{passwd});
	my $sth = $dbh->prepare("INSERT IGNORE INTO depths(md5, depth) VALUES (?,?)");
	my $depthhash = $self->{depths};
	for my $md5 (keys %{$depthhash}) {
		if($depthhash->{$md5} eq 'none') {
			my $got_values = $dbh->selectall_arrayref('select depth from depths where md5 = ?', undef, "$md5");
			$depthhash->{"$md5"} = $got_values->[0]->[0] if(scalar(@{$got_values}));
			#warn "Get depth from mysql for $md5" . $depthhash->{"$md5"};
		} else {
			#warn "Put depth $depthhash->{$md5} for $md5 into mysql";
			$sth->execute($md5, $depthhash->{$md5});
		}
	}
	return();
}

sub fix_markers {
	my $self = shift;
	my %depths = %{$self->{depths}};
	for my $depthkey (keys %depths) {
		if($depths{$depthkey} eq 'none') { # we never found its depth :(
			${ $self->{body_text} } =~ s/MaRkEr$depthkey/align="ABSMIDDLE"/g;
		} else {
			my $ndepth = 0 - $depths{$depthkey};
			${ $self->{body_text} } =~ s/MaRkEr$depthkey/style="vertical-align:${ndepth}px"/g;
		}
	}
	return();
}


=back

=cut

1;
