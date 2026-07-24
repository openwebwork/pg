#!/usr/bin/env perl

=head1 NAME

convert-to-pgml.pl -- Convert pg problem with non-pgml structure to PGML structure.

=head1 SYNOPSIS

    convert-to-pgml -b -s pgml file1.pg file2.pg ...

Options:

    -b|--backup               Create a backup of the original file before converting.
    -e|--extension-prefix=s   Extension prefix for the converted files. Default is 'pgml'.
    -p|--output-path=s        Output directory in which to save the converted problem files.
    -v|--verbose              Print verbose output.
    -h|--help                 Show the help message.


=head1 DESCRIPTION

This converts each pg file to PGML formatting.  In particular, text blocks are
converted to their PGML forms.  This includes BEGIN_TEXT/END_TEXT, BEGIN_HINT/END_HINT,
BEGIN_SOLUTION/END_SOLUTION.

Within each block, the following are converted:  math modes to their PGML version,
$BR and $PAR to line breaks or empty lines, C<$HR> to C<--->, bold and italics pairs,
any variables of the form C<$var> to C<[$var]>, scripts from \{ \} to [@ @], and
C<< $var->ans_rule() >> to the form C<[_]{$var}>.

A bare C<ans_rule()> call with no answer object cannot be paired with its C<ANS>
call reliably from the source alone, so it is left as a raw Perl call inside a
C<[@ @]> block instead of being converted to a C<[_]{}> answer blank. C<ANS>
commands are never modified or commented out; pairing them with converted or
unconverted answer rules is left entirely to manual review.

Many code features that are no longer needed are removed including
C<TEXT(beginproblem())>, C<< Context()->texStrings; >> and C<< Context()->normalStrings; >>.

The C<loadMacros> command is parsed, the C<PGML.pl> is included and C<MathObjects.pl>
is removed (because it is loaded by C<PGML.pl>) and C<PGcourse.pl> is added to the
end of the list.

Note: many of the features are converted correctly, but there may be errors
after the conversion.  Generally after using this script, the answer rules and
answer evaluators will need to be reviewed and paired up by hand.

=head2 OPTIONS

The option C<-b> or C<--backup> will create a C<.bak> file with the original
code and replace the current file with the converted code.

The option C<-e xyz> or C<--extension-prefix=xyz> will convert the code and
write the results in a file with the given extension prefix C<xyz> before the
C<.pg> extension.  If this is not given C<pgml> is used. So, for example, with
the default value of this option, if the file C<problemFile.pg> is converted,
the file C<problemFile.pgml.pg> will be written.  If the C<-b> flag is used,
this option will be ignored.

The option C<-p path> or C<--output-path=path> is the location to save the
converted problem files to.  If this option is not provided, then the converted
files will be saved in the same directory as the original file. Note that if
this option is used, then the C<-b> or C<--backup> and C<-e> or
C<--extension-prefix> options are ignored unless the path chosen by this option
is the directory containing the original problem file. Also note that if this
option is used, then files in the provided output path will be unconditionally
overwritten unless the file happens to be the original input file.

=cut

use Mojo::Base -signatures;

use Mojo::File qw(path curfile);
use Getopt::Long;
use Pod::Usage;

use lib curfile->dirname->dirname . '/lib';

use WeBWorK::PG::ConvertToPGML qw(convertToPGML);

GetOptions(
	'b|backup'             => \my $backup,
	'e|extension-prefix=s' => \my $extensionPrefix,
	'p|output-path=s'      => \my $outputPath,
	'v|verbose'            => \my $verbose,
	'h|help'               => \my $show_help
);
pod2usage(2) if $show_help || @ARGV == 0;

$extensionPrefix //= 'pgml';
convertFile($_) for (grep { $_ =~ /\.pg$/ } @ARGV);

sub convertFile ($filename) {
	my $path = path($filename);
	die "The file: $filename does not exist or is not readable.\n" unless -r $path;

	my $pg_source = $path->slurp;
	my $result    = convertToPGML($pg_source);
	if ($result->{error}) {
		warn "Error parsing $filename. " . $result->{error} . "\n";
		return;
	}

	# If --output-path is given and is not the directory the original file is in, then write to that location.
	die qq{The output path "$outputPath" does not exist or is not a directory.\n}
		if $outputPath && !-d $outputPath;
	if ($outputPath && path($outputPath)->realpath ne $path->dirname->realpath) {
		my $new_path = path($outputPath, $path->basename);
		$new_path->spurt($result->{pgmlCode});
		say "Writing converted file to $new_path" if $verbose;
		return;
	}

	# Copy the original file to a backup and then write the file.
	my $new_path    = $backup ? $path : path($filename =~ s/\.pg/.$extensionPrefix.pg/r);
	my $backup_file = $filename =~ s/\.pg$/.pg.bak/r;
	$path->copy_to($backup_file) if $backup;
	$new_path->spurt($result->{pgmlCode});
	say "Writing converted file to $new_path"      if $verbose;
	say "Backing up original file to $backup_file" if $verbose && $backup;
}

1;
