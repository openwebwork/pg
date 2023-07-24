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

This converts each pg file to PGML formatting.  Note: many of the features are
converted correctly, but often there will be errors after the conversion.

=cut

use strict;
use warnings;
use experimental 'signatures';
use feature 'say';

use Getopt::Long;
use File::Copy;

use Data::Dumper;

my $problem_dir;
# GetOptions("d|problem_dir=s" => \$problem_dir,);

convertFile($_) for (@ARGV);

# This subroutine converts the file passed in to PGML format.  This includes
# * converting BEGIN_TEXT/END_TEXT, BEGIN_SOLUTION/END_SOLUTION, and BEGIN_HINT/END_HINT
#    blocks to PGML.
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
		if ($row =~ /BEGIN_(TEXT|HINT|SOLUTION)/) {
			push(@pgml_block, $row);
			$in_pgml_block = 1;
		} elsif ($row =~ /END_(TEXT|HINT|SOLUTION)/) {
			push(@pgml_block, $row);
			$in_pgml_block = 0;
			my $pgml_rows = convertPGMLBlock(\@pgml_block);
			push(@all_lines, @$pgml_rows);
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

			# print Dumper \@macros;
			# print Dumper \@m2;
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
# * converting other variables from $var to [$var]
# * converting ans_rule to [_]{} format
# * converting \{ \} to [@ @]

# * removing TEXT(beginproblem())
# * removing Context()->texStrings;
# * removing Context()->normalStrings;

sub convertPGMLBlock ($block) {
	my @new_rows;
	for my $row (@$block) {
		my $add_blank_line = ($row =~ /\$PAR/);
		$row = $row =~ s/(BEGIN|END)_TEXT/$1_PGML/r;
		$row = $row =~ s/(BEGIN|END)_(SOLUTION|HINT)/$1_PGML_$2/r;
		$row = $row =~ s/\$PAR//gr;
		# need to add blank lines;
		$row = $row =~ s/\$BR$/ /gr;
		# how to handle $BR in middle of a line
		$row = $row =~ s/\$(E|B)BOLD/*/gr;
		$row = $row =~ s/\$(E|B)ITALICS/_/gr;
		$row = $row =~ s/\$BCENTER/>>/r;
		$row = $row =~ s/\$ECENTER/<</r;
		$row = $row =~ s/\\\(/[`/gr;
		$row = $row =~ s/\\\)/`]/gr;
		$row = $row =~ s/\\\[/[``/gr;
		$row = $row =~ s/\\\]/``]/gr;
		$row = $row =~ s/(\$\w+)(\W)/[$1]$2/gr;

		$row = $row =~ s/\\\{\s*ans_rule\((\d+)\)\s*\\\}/\[_\]{}{$1}/gr;

		$row = $row =~ s/\\\{/[@/r;
		$row = $row =~ s/\\\}/@]/r;
		push(@new_rows, $row);
		push(@new_rows, '') if $add_blank_line;
	}
	return \@new_rows;
}

sub cleanUpCode ($row) {
	$row = $row =~ s/Context\(\)->normalStrings;//r;
	$row = $row =~ s/Context\(\)->texStrings;//r;
	$row = $row =~ s/TEXT\(\s*beginproblem\(\)\s*\);//r;
	return $row;
}

1;
