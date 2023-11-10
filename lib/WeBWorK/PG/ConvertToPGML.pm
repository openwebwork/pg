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

WeBWorK::PG::ConvertToPGML

=head1 DESCRIPTION

Converts a pg file to PGML format.

=head1 OPTIONS

=cut

package WeBWorK::PG::ConvertToPGML;
use parent qw(Exporter);

use strict;
use warnings;

our @EXPORT = qw(convertToPGML);

# This subroutine converts the file that is passed in as a multi-line string and
# assumed to be an older-style PG file with BEGIN_TEXT/END_TEXT, BEGIN_SOLUTION/END_SOLUTION,
# and BEGIN_HINT/END_HINT blocks.

# * parses the loadMacros line(s) to include PGML.pl (and eliminate MathObjects.pl, which)
#    is imported by PGML.pl.  This also adds PGcourse.pl to the end of the list.

# input is a string containing the source of the pg file to be converted.
# returns a string that is the converted input string.

sub convertToPGML {
	my ($pg_source) = @_;
	my @pgml_block;
	my $in_pgml_block = 0;
	my @all_lines;

	my @rows = split(/\n/, $pg_source);

	while (@rows) {
		my $row = shift @rows;
		if ($row =~ /BEGIN_(TEXT|HINT|SOLUTION)/ || $row =~ /SOLUTION\(EV3\(<<\'END_SOLUTION\'\)\);/) {
			push(@pgml_block, $row);
			$in_pgml_block = 1;
		} elsif ($row =~ /END_(TEXT|HINT|SOLUTION)/) {
			push(@pgml_block, $row);
			$in_pgml_block = 0;
			push(@all_lines, @{ convertPGMLBlock(\@pgml_block) });
			@pgml_block = ();
		} elsif ($in_pgml_block) {
			push(@pgml_block, $row);
		} elsif ($row =~ /loadMacros\(/) {
			# Parse the macros, which may be on multiple rows.
			# Remove comments within loadMacros block (should we keep them?)
			my $macros = $row;
			while ($row && $row !~ /\);\s*$/) {
				$row = shift @rows;
				my @mrow = split(/#/, $row);
				# This only adds the row if there is something relevent to the left of a #
				$macros .= $mrow[0] if $mrow[0] !~ /^\s*$/;
			}
			# Split by commas and pull out the quotes.
			my @macros =
				grep { $_ !~ /^#/ }
				grep {
					$_ !~ /(PGstandard|PGML|PGauxiliaryFunctions|PGbasicmacros|PGanswermacros|MathObjects|PGcourse).pl/
				}
				map {s/['"\s]//gr}
				split(/\s*,\s*/, $macros =~ s/loadMacros\((.*)\)\;$/$1/r);

			# my @macros = map {s/['"\s]//gr} split(/\s*,\s*/, $macros =~ s/loadMacros\((.*)\)\;$/$1/r);
			# @macros = grep {
			# 	$_ !~ /(PGstandard|PGML|PGauxiliaryFunctions|PGbasicmacros|PGanswermacros|MathObjects|PGcourse).pl/
			# } @macros;
			# @macros = grep { $_ !~ /^#/ } @macros;

			push(@all_lines,
				'loadMacros('
					. join(', ', map {"'$_'"} ('PGstandard.pl', 'PGML.pl', @macros, 'PGcourse.pl'))
					. ');');
		} else {
			push(@all_lines, cleanUpCode($row));
		}
	}

	# remove blank lines if there are more than one.
	my @empty_lines = grep { $all_lines[$_] =~ /^\s*$/ } (0 .. $#all_lines);

	for (my $n = $#empty_lines; $n >= 1; $n--) {
		if ($empty_lines[$n] == $empty_lines[ $n - 1 ] + 1) {
			splice(@all_lines, $empty_lines[$n], 1);
		}
	}
	return join "\n", @all_lines;
}

# This subroutine converts a block (passed in as an array ref of strings) to
# PGML format.  This includes:
# * converting BEGIN_TEXT/END_TEXT to BEGIN_PGML/END_PGML
# * converting BEGIN_HINT/END_HINT to BEGIN_PGML_HINT/END_PGML_HINT
# * converting BEGIN_SOLUTION/END_SOLUTION to BEGIN_PGML_SOLUTION/END_PGML_SOLUTION
# * converting begin end math with PGML versions
# * adding an extra space before or after a $PAR depending on where it is.
# * adding two spaces at the end of a line for a $BR at the end of a line
# * converting $HR to ---
# * convert center, bold and italics to PGML forms.
# * converting other variables from $var to [$var]
# * converting ans_rule to [_]{} format
# * converting \{ \} to [@ @]

sub convertPGMLBlock {
	my ($block) = @_;
	my @new_rows;
	for my $row (@$block) {
		my $add_blank_line_before = ($row =~ /^\s*\$PAR/);
		my $add_blank_line_after  = ($row =~ /\$PAR\s*$/);
		$row =~ s/(BEGIN|END)_TEXT/$1_PGML/;
		$row =~ s/(BEGIN|END)_(SOLUTION|HINT)/$1_PGML_$2/;
		$row =~ s/SOLUTION\(EV3P?\(<<\'END_PGML_SOLUTION\'\)\);/BEGIN_PGML_SOLUTION/;
		# remove $PAR, and $SPACE
		$row =~ s/\$PAR//g;
		$row =~ s/\$SPACE//g;

		# If a $BR is at the end of the line add two spaces, else make two blank lines.
		$row =~ s/\$BR$/  /g;
		$row =~ s/\$BR/\n\n/g;

		# Switch bold, italics, centering and math modes.
		$row =~ s/\s*\$\{?EBOLD\}?/*/g;
		$row =~ s/\$\{?BBOLD\}?\s*/*/g;
		$row =~ s/\s*\$\{?EITALIC\}?/_/g;
		$row =~ s/\$\{?BITALIC\}?\s*/_/g;
		$row =~ s/\$\{?BCENTER\}?/>>/g;
		$row =~ s/\$\{?ECENTER\}?/<</g;
		$row =~ s/\\\(/[`/g;
		$row =~ s/\\\)/`]/g;
		$row =~ s/\\\[/[```/g;
		$row =~ s/\\\]/```]/g;

		# replace the variables in the PGML block.  Don't if it is in a \{ \}
		# Note that the first is for variables at the end of the line.
		$row =~ s/(\$\w+)$/[$1]/g;
		$row =~ s/(\$\w+)(\W)/[$1]$2/g unless $row =~ /\\\{.*(\$\w+)(\W).*\\\}/;

		# match all forms of ans_rule
		$row = convertANSrule($row);

		$row =~ s/\\\{/[@ /g;
		$row =~ s/\\\}/ @]*/g;

		# if there is an $HR, add blank lines before and after the PGML "---"
		if ($row =~ /\$HR/) {
			push @new_rows, '', '---', '';
		} elsif ($add_blank_line_before) {
			push @new_rows, '', $row;
		} elsif ($add_blank_line_after) {
			push @new_rows, $row, '';
		} else {
			push @new_rows, $row;
		}
	}
	return \@new_rows;
}

# Convert the ans_rule constructs to [_]{$var}.  This is called recursively to handle multiple ans_rule
# on a single line.

sub convertANSrule {
	my ($str) = @_;
	if ($str =~ /(.*)\\\{\s*((\$\w+)->)?ans_rule(\((\d+)\))?\s*\\\}(.*)$/) {
		my $var  = $3 // '';
		my $size = $5 ? "{$5}" : '';
		return convertANSrule($1 // '') . '[_]' . "{$var}$size" . convertANSrule($6 // '');
	} else {
		return $str;
	}
}

# remove some unnecessary code including:
# * removing TEXT(beginproblem())
# * removing Context()->texStrings;
# * removing Context()->normalStrings;
# * commenting out ANS, WEIGHTED_ANS, NAMED_ANS or LABELED_ANS
# * removing any line that only comment symbols.

sub cleanUpCode {
	my ($row) = @_;
	$row =~ s/^\s*#+\s*$//;
	$row =~ s/Context\(\)->normalStrings;//;
	$row =~ s/Context\(\)->texStrings;//;
	$row =~ s/TEXT\(\s*&?beginproblem(\(\))?\s*\);//;
	$row =~ s/^(LABELED_|NAMED_|WEIGHTED_|)ANS(.*)/# $1ANS$2/;
	return $row;
}

1;
