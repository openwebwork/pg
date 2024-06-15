#!/usr/bin/env perl
################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2024 The WeBWorK Project, https://github.com/openwebwork
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

convert-to-pgml.pl -- Convert pg problem with non-pgml structure to PGML structure.

=head1 SYNOPSIS

    convert-to-pgml -b -s pgml file1.pg file2.pg ...

=head1 DESCRIPTION

This converts each pg file to PGML formatting.  In particular, text blocks are
converted to their PGML forms.  This includes BEGIN_TEXT/END_TEXT, BEGIN_HINT/END_HINT,
BEGIN_SOLUTION/END_SOLUTION.

Within each block, the following are converted:  math modes to their PGML version,
$BR and $PAR to line breaks or empty lines, C<$HR> to C<--->, bold and italics pairs,
any variables of the form C<$var> to C<[$var]>, scripts from \{ \} to [@ @], and C<ans_rule>
to the form C<[_]{}>

Many code features that are no longer needed are removed including
C<TEXT(beginproblem())>, C<<Context()->texStrings;>> and C<<Context()->normalStrings;>>.
Any C<ANS> commands are commented out.

The C<loadMacros> command is parsed, the C<PGML.pl> is included and C<MathObjects.pl>
is removed (because it is loaded by C<PGML.pl>) and C<PGcourse.pl> is added to the
end of the list.

Note: many of the features are converted correctly, but often there will be errors
after the conversion.  Generally after using this script, the PGML style answers
will need to have their corresponding variable added.

=head2 OPTIONS

The option C<-b> or C<--backup> will create a C<.bak> file with the original code and
replace the current file with the converted code.

The option C<-s xyz> or C<--suffix=xyz> will convert the code and write the results in a file
with the given suffix C<xyz> appended to the file name.  If this is not given
C<pgml> is used. If the C<-b> flag is used, this option will be ignored.

=cut

use strict;
use warnings;
use experimental 'signatures';

use Mojo::File qw(curfile);
use Getopt::Long;

use lib curfile->dirname->dirname . '/lib';

use WeBWorK::PG::ConvertToPGML qw(convertToPGML);

my $backup  = 0;
my $verbose = 0;
my $suffix  = 'pgml';

GetOptions(
	"b|backup"   => \$backup,
	"s|suffix=s" => \$suffix,
	"v|verbose"  => \$verbose,
);

die 'arguments must have a list of pg files' unless @ARGV > 0;
convertFile($_) for (grep { $_ =~ /\.pg$/ } @ARGV);

sub convertFile ($filename) {
	my $path = Mojo::File->new($filename);
	die "The file: $filename does not exist or is not readable" unless -r $path;

	my $pg_source        = $path->slurp;
	my $converted_source = convertToPGML($pg_source);

	# copy the original file to a backup and then write the file
	my $new_path    = $backup ? $path : Mojo::File->new($filename =~ s/\.pg/.$suffix/r);
	my $backup_file = $filename =~ s/\.pg$/.pg.bak/r;
	$path->copy_to($backup_file) if $backup;
	$new_path->spurt($converted_source);
	print "Writing converted file to $new_path\n"      if $verbose;
	print "Backing up original file to $backup_file\n" if $verbose && $backup;
}

1;
