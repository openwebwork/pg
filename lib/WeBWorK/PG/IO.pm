################################################################################
# WeBWorK mod_perl (c) 2000-2002 WeBWorK Project
# $Id$
################################################################################

package WeBWorK::PG::IO;
use base qw(Exporter);
use WeBWorK::PG::Translator;

=head1 NAME

WeBWorK::PG::IO - Private functions used by WeBWorK::PG::Translator for file IO.

=cut

use strict;
use warnings;

BEGIN {
	our @EXPORT = qw(
		includePGtext
		read_whole_problem_file
		read_whole_file
		convertPath
		getDirDelim
		fileFromPath
		directoryFromPath
		createFile
		createDirectory
	);

	our %SHARE = map { $_ => __PACKAGE__ } @EXPORT;
	
	if (defined $main::VERSION) {
		my $mod;
		for ($main::VERSION) {
			/^1\./          and $mod = "WeBWorK::PG::IO::WW1";
			/^2\./          and $mod = "WeBWorK::PG::IO::WW2";
			/^Daemon\s*2\./ and $mod = "WeBWorK::PG::IO::Daemon2";
		}
		
		eval "package Main; require $mod; import $mod"; # this is runtime_use
		die $@ if $@;
	} else {
		warn "\$main::VERSION not defined -- not loading version-specific IO functions";
	}
}

=head1 SYNOPSIS

 BEGIN { $main::VERSION = "2.0" }
 use WeBWorK::PG::IO;
 my %functions_to_share = %WeBWorK::PG::IO::SHARE;

=head1 DESCRIPTION

This module defines several functions to be shared with a safe compartment by
the PG translator. It also loads a version-specific module (if found) based on
the value of the C<$main::VERSION> variable.

This module also maintains a hash C<%WeBWorK::PG::IO::SHARE>. The keys of this
hash are the names of functions, and the values are the name of the package that
contains the function.

=head1 FUNCTIONS

=over

=item includePGtext($string_ref, $envir_ref)


This is used in processing some of the sample CAPA files and in creating aliases to redirect calls to duplicate problems so that 
they go to the original problem instead.  It is called by includePGproblem.

It reads and evaluates the string in the same way that the Translator evaluates the string in a PG file.

=cut

sub includePGtext  {
	my $evalString = shift;
	if (ref($evalString) eq 'SCALAR') {
		$evalString = $$evalString;
	}
#	$evalString =~ s/\nBEGIN_TEXT/\nTEXT\(EV3\(<<'END_TEXT'\)\);/g;
#	$evalString =~ s/\\/\\\\/g; # \ can't be used for escapes because of TeX conflict
#	$evalString =~ s/~~/\\/g;   # use ~~ as escape instead, use # for comments
	no strict;
	$evalString = eval( q! &{$main::PREPROCESS_CODE}($evalString) !); 
	# current preprocessing code passed from Translator (see Translator::initialization)
	my $errors = $@;
	eval("package main; $evalString") ;
	$errors .= $@;
	die eval(q! "ERROR in included file:\n$main::envir{probFileName}\n $errors\n$evalString"!) if $errors;
	use strict;
	return "";
}

=item read_whole_problem_file($filePath)

Don't use for huge files. The file name will have .pg appended to it if it
doesn't already end in .pg.  Files may become double spaced.?  Check the join
below. This is used in importing additional .pg files as is done in the sample
problems translated from CAPA. Returns a reference to a string containing the
contents of the file.

=cut

sub read_whole_problem_file {
	my $filePath = shift;
	$filePath =~s/^\s*//; # get rid of initial spaces
	$filePath =~s/\s*$//; # get rid of final spaces
	$filePath = "$filePath.pg" unless $filePath =~ /\.pg$/;
	read_whole_file($filePath);
}

sub read_whole_file {
	my $filePath = shift;
	local (*INPUT);
	open(INPUT, "<$filePath") || die "$0: read_whole_file subroutine: <BR>Can't read file $filePath";
	local($/)=undef;
	my $string = <INPUT>;  # can't append spaces because this causes trouble with <<'EOF'   \nEOF construction
	close(INPUT);
	\$string;
}

=item convertPath($path)

Currently a no-op. Returns $path unmodified.

=cut

sub convertPath {
    return wantarray ? @_ : shift;
}

sub getDirDelim {
	return ("/");
}

=item fileFromPath($path)

Uses C<&getDirDelim> to determine the path delimiter.  Returns the last segment
of the path (i.e. the text after the last delimiter).

=cut

sub fileFromPath {
	my $path = shift;
	my $delim = &getDirDelim();
	$path = convertPath($path);
	$path =~ m|([^$delim]+)$|;
	$1;
}

=item directoryFromPath($path)

Uses C<&getDirDelim> to determine the path delimiter.  Returns the initial
segments of the of the path (i.e. the text up to the last delimiter).

=cut
   
sub directoryFromPath {
	my $path = shift;
	my $delim = &getDirDelim();
	$path = convertPath($path);
	$path =~ s|[^$delim]*$||;
	$path;
}

=item createFile($fileName, $permission, $numgid)

Creates a file with the given name, permission bits, and group ID.

=cut

sub createFile {
	my ($fileName, $permission, $numgid) = @_;
	open(TEMPCREATEFILE, ">$fileName")
		or die "Can't open $fileName: $!";
	my @stat = stat TEMPCREATEFILE;
	close(TEMPCREATEFILE);
	
	# if the owner of the file is running this script (e.g. when the file is
	# first created) set the permissions and group correctly
	if ($< == $stat[4]) {
		my $tmp = chmod($permission, $fileName)
			or warn "Can't do chmod($permission, $fileName): $!";
		chown(-1, $numgid, $fileName)
			or warn "Can't do chown($numgid, $fileName): $!";
	}
}

=item createDirectory($dirName, $permission, $numgid)

Creates a directory with the given name, permission bits, and group ID.

=cut

sub createDirectory {
	my ($dirName, $permission, $numgid) = @_;
	$permission = (defined($permission)) ? $permission : '0770';
	# FIXME -- find out where the permission is supposed to be defined
	my $errors = '';
	mkdir($dirName, $permission)
		or $errors .= "Can't do mkdir($dirName, $permission): $!\n".caller(3);
	chmod($permission, $dirName)
		or $errors .= "Can't do chmod($permission, $dirName): $!\n".caller(3);
	unless ($numgid == -1) {
		chown(-1,$numgid,$dirName)
			or $errors .= "Can't do chown(-1,$numgid,$dirName): $!\n".caller(3);
	}
	if ($errors) {
		warn $errors;
		return 0;
	} else {
		return 1;
	}
}

=back

=cut

1;
