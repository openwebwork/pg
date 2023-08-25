#!/usr/bin/env perl
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

=head1 NAME

convert-to-pgml.pl -- Convert pg problem with non-pgml structure to PGML structure.

=head1 SYNOPSIS

    convert-to-pgml file1.pg file2.pg ...

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

=cut

use strict;
use warnings;
use experimental 'signatures';
use feature 'say';

use File::Copy;

die 'arguments must have a list of pg files' unless @ARGV > 0;
convertFile($_) for (grep { $_ =~ /.pg$/ } @ARGV);

# This subroutine converts the file assumed to be an older-style PG file with
# BEGIN_TEXT/END_TEXT, BEGIN_SOLUTION/END_SOLUTION, and BEGIN_HINT/END_HINT blocks.

# * parses the loadMacros line(s) to include PGML.pl (and eliminate MathObjects.pl, which)
#    are included in PGML.pl.  This also adds PGcourse.pl to the end of the list.

sub convertFile ($file) {

	open(my $FH, '<:encoding(UTF-8)', $file) or do {
		warn qq{Could not open file "$file": $!};
		return {};
	};
	my @file_contents = <$FH>;
	close $FH;

	my @pgml_block;
	my $in_pgml_block = 0;
	my @all_lines;

	while (my $row = shift @file_contents) {
		chomp($row);
		if ($row =~ /BEGIN_(TEXT|HINT|SOLUTION)/ || $row =~ /SOLUTION\(EV3\(<<\'END_SOLUTION\'\)\);/) {
			push(@pgml_block, $row);
			$in_pgml_block = 1;
		} elsif ($row =~ /END_(TEXT|HINT|SOLUTION)/) {
			push(@pgml_block, $row);
			$in_pgml_block = 0;
			my $pgml_rows = convertPGMLBlock(\@pgml_block);
			push(@all_lines, @$pgml_rows);
			@pgml_block = ();
		} elsif ($in_pgml_block) {
			push(@pgml_block, $row);
		} elsif ($row =~ /loadMacros\(/) {
			chomp($row);
			# Parse the macros, which may be on multiple rows.
			my $macros = $row;
			while ($row && $row !~ /\);\s*$/) {
				$row = shift @file_contents;
				chomp($row);
				$macros .= $row;
			}
			# Split by commas and pull out the quotes.
			my @macros = map  {s/['"\s]//gr} split(/\s*,\s*/, $macros =~ s/loadMacros\((.*)\)\;$/$1/r);
			my @m2     = grep { $_ !~ /(PGstandard|PGML|MathObjects|PGcourse).pl/ } @macros;

			push(@all_lines,
				"loadMacros('PGstandard.pl', 'PGML.pl', " . join(', ', map {"'$_'"} @m2) . ", 'PGcourse.pl');");
		} else {
			$row = cleanUpCode($row);
			push(@all_lines, $row);
		}
	}

	# remove blank lines if there are more than one.
	my @empty_lines = grep { $all_lines[$_] =~ /^\s*$/ } (0 .. $#all_lines);
	for (my $n = $#empty_lines; $n >= 1; $n--) {
		splice(@all_lines, $empty_lines[$n], 1) if ($empty_lines[$n] == $empty_lines[ $n - 1 ] + 1);
	}

	# copy the original file to a backup and then write the file
	copy($file, $file =~ s/.pg$/.pg.bak/r);
	open($FH, '>:encoding(UTF-8)', $file) or do {
		warn qq{Could not write to file "$file": $!};
		return {};
	};
	for my $line (@all_lines) {
		print $FH "$line\n";
	}
}

# This subroutine converts a block (passed in as an array ref of strings) to
# PGML format.  This inlcudes:
# * converting BEGIN_TEXT/END_TEXT to BEGIN_PGML/END_PGML
# * converting BEGIN_HINT/END_HINT to BEGIN_PGML_HINT/END_PGML_HINT
# * converting BEGIN_SOLUTION/END_SOLUTION to BEGIN_PGML_SOLUTION/END_PGML_SOLUTION
# * converting begin end math with PGML versions
# * removing $PAR and $BR
# * converting $HR to ---
# * converting other variables from $var to [$var]
# * converting ans_rule to [_]{} format
# * converting \{ \} to [@ @]

# * removing TEXT(beginproblem())
# * removing Context()->texStrings;
# * removing Context()->normalStrings;
# * comment out ANS().

sub convertPGMLBlock ($block) {
	my @new_rows;
	for my $row (@$block) {
		my $add_blank_line = ($row =~ /\$PAR/);
		$row = $row =~ s/(BEGIN|END)_TEXT/$1_PGML/r;
		$row = $row =~ s/(BEGIN|END)_(SOLUTION|HINT)/$1_PGML_$2/r;
		$row = $row =~ s/SOLUTION\(EV3P?\(<<\'END_PGML_SOLUTION\'\)\);/BEGIN_PGML_SOLUTION/r;
		# remove $PAR, and $SPACE
		$row = $row =~ s/\$PAR//gr;
		$row = $row =~ s/\$SPACE//gr;

		# If a $BR is at the end of the line add two spaces, else make two blank lines.
		$row = $row =~ s/\$BR$/  /gr;
		$row = $row =~ s/\$BR/\n\n/gr;

		# Switch bold, italics, centering and math modes.
		$row = $row =~ s/\s*\$\{?EBOLD\}?/*/gr;
		$row = $row =~ s/\$\{?BBOLD\}?\s*/*/gr;
		$row = $row =~ s/\s*\$\{?EITALICS\}?/_/gr;
		$row = $row =~ s/\$\{?BITALICS\}?\s*/_/gr;
		$row = $row =~ s/\$\{?BCENTER\}?/>>/gr;
		$row = $row =~ s/\$\{?ECENTER\}?/<</gr;
		$row = $row =~ s/\\\(/[`/gr;
		$row = $row =~ s/\\\)/`]/gr;
		$row = $row =~ s/\\\[/[``/gr;
		$row = $row =~ s/\\\]/``]/gr;
		$row = $row =~ s/\$HR/\n---\n/gr;

		# replace the variables in the PGML block.  Don't if it is in a \{ \}
		# Note that the first is for variables at the end of the line.
		$row = $row =~ s/(\$\w+)$/[$1]/gr;
		$row = $row =~ s/(\$\w+)(\W)/[$1]$2/gr unless $row =~ /\\\{.*(\$\w+)(\W).*\\\}/;

		# match all forms of ans_rule
		if ($row =~ /(.*)\\\{\s*((\$\w+)->)?ans_rule(\((\d+)\))?\s*\\\}(.*)$/) {
			my $var  = $3 // '';
			my $size = $5 ? "{$5}" : '';
			$row = $1 . '[_]' . "{$var}$size$6";
		}

		$row = $row =~ s/\\\{/[@/gr;
		$row = $row =~ s/\\\}/@]*/gr;
		push(@new_rows, $row);
		push(@new_rows, '') if $add_blank_line;
	}
	return \@new_rows;
}

# remove some unnecessary code

sub cleanUpCode ($row) {
	$row = $row =~ s/Context\(\)->normalStrings;//r;
	$row = $row =~ s/Context\(\)->texStrings;//r;
	$row = $row =~ s/TEXT\(\s*beginproblem(\(\))?\s*\);//r;
	$row = $row =~ s/^ANS(.*)/# ANS$1/r;
	return $row;
}

1;
