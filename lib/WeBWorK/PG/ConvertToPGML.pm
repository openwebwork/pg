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

This script does a number of conversions:

=over
=item  Update the loadMacros call to include PGML.pl, eliminate MathObject.pl (since it is loaded by PGML.pl)
and adds PGcourse.pl to the end of the list.
=item  Coverts BEGIN_TEXT/END_TEXT (and older versions of this), BEGIN_SOLUTION/END_SOLUTION, BEGIN_HINT/END_HINT
to their newer BEGIN_PGML blocks.
=item  Convert math mode in these blocks to PGML style math mode.
=item  Convert other styling (bold, italics) to PGML style.
=item Convert variables to the interpolated [$var] PGML style.
=item  Convert some of the answer rules to newer PGML style.
=item Remove some outdated code.
=item A few other minor things.
=back

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

# This stores the answers inside of ANS and related functions.
my @ans_list;

sub convertToPGML {
	my ($pg_source) = @_;

	# First get a list of all of the ANS, LABELED_ANS, etc. in the problem.
	@ans_list = getANS($pg_source);

	my @pgml_block;
	my $in_pgml_block = 0;
	my @all_lines;

	my @rows = split(/\n/, $pg_source);

	while (@rows) {
		my $row = shift @rows;
		if ($row =~ /BEGIN_(TEXT|HINT|SOLUTION)/
			|| $row =~ /SOLUTION\(EV3\(<<\'END_SOLUTION\'\)\);/
			|| $row =~ /TEXT\(EV2\(<<EOT\)\)/)
		{
			push(@pgml_block, $row);
			$in_pgml_block = 1;
		} elsif ($row =~ /END_(TEXT|HINT|SOLUTION)|EOT/) {
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
					$_ !~
					/(PGstandard|PGML|PGauxiliaryFunctions|PGbasicmacros|PGanswermacros|MathObjects|PGcourse|AnswerFormatHelp).pl/
				}
				map {s/['"\s]//gr}
				split(/\s*,\s*/, $macros =~ s/loadMacros\((.*)\)\;$/$1/r);

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
# * converting \{ \} to [@ @] without altering code within the \{ \}.

sub convertPGMLBlock {
	my ($block) = @_;
	my @new_rows;
	while (@$block) {
		my $row                   = shift @$block;
		my $add_blank_line_before = ($row =~ /^\s*\$PAR/);
		my $add_blank_line_after  = ($row =~ /\$PAR\s*$/);

		# match all forms of ans_rule
		$row = convertANSrule($row);

		# Capture any perl blocks inside \{ \}
		my @perl_block;

		if ($row =~ /^(.*)\\\{(.*)\\\}(.*)/) {
			push(@perl_block, $2);
			$row = "$1 PERL_BLOCK $3";
		} elsif ($row =~ /^(.*)\\\{(.*)$/) {    # This is a multi-line perl block
			my $tmp = $1;
			push(@perl_block, $2);
			do {
				$row = shift @$block;
				push(@perl_block, $row) unless $row =~ /^(.*)\\\}(.*)$/;
			} until $row =~ /^(.*)\\\}(.*)$/;
			push(@perl_block, $1);
			$row = "$tmp PERL_BLOCK $2";
		}

		$row =~ s/(BEGIN|END)_TEXT/$1_PGML/;
		$row =~ s/TEXT\(EV2\(<<EOT\)\)/BEGIN_PGML/;
		$row =~ s/EOT/END_PGML/;
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

		# if there is an $HR, add blank lines before and after the PGML "---"

		if ($row =~ /^(.*)\$HR(.*)$/) {
			push @new_rows, $1 // '', '', '---', '', $2 // '';
		}

		# After many other variables have been replaced, replace the variables in the PGML block.
		# However if not in a {}, assumed to be in an answer blank.
		if (my @matches = $row =~ /\$[\w\_]+/g) {
			for my $m (@matches) {
				$m =~ s/\$/\\\$/;
				# Wrap variables in [].  Handle arrays, hashes, array refs and hashrefs.
				$row =~ s/(?<!\]{)($m+(\[\d+\])?((->)?\{.*?\})?)/[$1]/;
			}
		}

		# Do some converting inside a perl block:
		for (0 .. $#perl_block) {
			$perl_block[$_] =~ s/AnswerFormatHelp\(["']([\w\s]+)["']\)/helpLink('$1')/g;
		}

		if ($add_blank_line_before) {
			push @new_rows, '', $row;
		} elsif ($add_blank_line_after) {
			push @new_rows, $row, '';
		} elsif ($row =~ /^(.*)?\sPERL_BLOCK\s(.*)?$/) {
			# remove any empty lines in the block
			@perl_block = grep { $_ !~ /^\s*$/ } @perl_block;
			# Wrap the perl block in [@ @]
			if ($#perl_block == 0) {
				push(@new_rows, ($1 // '') . ' [@ ' . $perl_block[0] . ' @]*' . ($2 // ''));
			} else {
				push(@new_rows, ($1 // '') . ' [@ ' . shift(@perl_block), @perl_block, ' @]*' . ($2 // ''));
			}
		} else {
			push @new_rows, $row;
		}

	}
	return \@new_rows;
}

# Convert many ans_rule constructs to the PGML answer blank form [_]{$var}.
# This is called recursively to handle multiple ans_rule on a single line.

sub convertANSrule {
	my ($str) = @_;
	if ($str =~ /(.*)\\\{\s*((\$\w+)->)?ans_rule(\((\d*)\))?\s*\\\}(.*)$/) {
		my $ans  = shift(@ans_list);
		my $var  = $3 // $ans->{arg} // '';
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

# Loads the entire file searching for instances of ANS, WEIGHTED_ANS, NAMED_ANS or LABELED_ANS
# and returns an arrayref with an ordered list of them.
sub getANS {
	my ($pg_source) = @_;
	my @ans_list;
	for my $row (split(/\n/, $pg_source)) {
		if ($row !~ /^\s*#/ && $row =~ /(LABELED_|NAMED_|WEIGHTED_|)ANS/) {
			# For style like ANS($ans->cmp());
			if ($row =~ /((LABELED_|NAMED_|WEIGHTED_|)ANS)\(\s*([\$\w]+)->(\w+)(\(\))?\s*\)/) {
				push(@ans_list, { type => $1, arg => $3 });
				# for style like ANS(num_cmp($ans))
			} elsif ($row =~ /((LABELED_|NAMED_|WEIGHTED_|)ANS)\(\s*(([\w\_]+)\((\$[\w\_]+)\))\)/) {
				my $type = $1;
				my $arg  = $3 =~ s/(std_)?num_cmp/Real/r;
				$arg =~ s/str_cmp|std_num_cmp/String/;
				$arg =~ s/interval_cmp/Interval/;
				$arg =~ s/fun_cmp/Formula/;
				$arg =~ s/radio_cmp|checkbox_cmp//;
				push(@ans_list, { type => $type, arg => $arg });
			}
		}
	}
	return @ans_list;
}

1;
