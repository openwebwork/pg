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
			my $pgml_rows = convertPGMLBlock(\@pgml_block);
			push(@all_lines, @$pgml_rows);
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
			my @macros = map {s/['"\s]//gr} split(/\s*,\s*/, $macros =~ s/loadMacros\((.*)\)\;$/$1/r);
			@macros = grep {
				$_ !~ /(PGstandard|PGML|PGauxiliaryFunctions|PGbasicmacros|PGanswermacros|MathObjects|PGcourse).pl/
			} @macros;
			@macros = grep { $_ !~ /^#/ } @macros;

			push(@all_lines,
				'loadMacros('
					. join(', ', map {"'$_'"} ('PGstandard.pl', 'PGML.pl', @macros, 'PGcourse.pl'))
					. ');');
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

	return join "\n", @all_lines;
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

sub convertPGMLBlock {
	my ($block) = @_;
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
		$row = $row =~ s/\s*\$\{?EITALIC\}?/_/gr;
		$row = $row =~ s/\$\{?BITALIC\}?\s*/_/gr;
		$row = $row =~ s/\$\{?BCENTER\}?/>>/gr;
		$row = $row =~ s/\$\{?ECENTER\}?/<</gr;
		$row = $row =~ s/\\\(/[`/gr;
		$row = $row =~ s/\\\)/`]/gr;
		$row = $row =~ s/\\\[/[```/gr;
		$row = $row =~ s/\\\]/```]/gr;
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

sub cleanUpCode {
	my ($row) = @_;
	$row = $row =~ s/^\s*#+\s*$//r;
	$row = $row =~ s/Context\(\)->normalStrings;//r;
	$row = $row =~ s/Context\(\)->texStrings;//r;
	$row = $row =~ s/TEXT\(\s*beginproblem(\(\))?\s*\);//r;
	$row = $row =~ s/^ANS(.*)/# ANS$1/r;
	return $row;
}

1;
