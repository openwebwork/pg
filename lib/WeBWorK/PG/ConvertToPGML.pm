
=head1 NAME

WeBWorK::PG::ConvertToPGML - convert a file in original PG format to PGML

=head1 DESCRIPTION

Converts a pg file to PGML format.

This script does a number of conversions:

=over

=item *

Update the loadMacros call to include C<PGML.pl>, eliminate C<MathObject.pl> (since it is loaded by C<PGML.pl>)
and adds C<PGcourse.pl> to the end of the list.

=item *

Coverts C<BEGIN_TEXT>/C<END_TEXT> (and older versions of this), C<BEGIN_SOLUTION>/C<END_SOLUTION>,
C<BEGIN_HINT>/C<END_HINT> to their newer C<BEGIN_PGML> blocks.

=item *

Convert math mode in these blocks to PGML style math mode.

=item *

Convert other styling (bold, italics) to PGML style.

=item *

Convert variables to the interpolated C<[$var]> PGML style.

=item *

Convert some of the answer rules to newer PGML style.

=item *

Remove some outdated code.

=item *

A few other minor things.

=back

=head1 FUNCTIONS

=cut

package WeBWorK::PG::ConvertToPGML;
use parent qw(Exporter);

use strict;
use warnings;

our @EXPORT_OK = qw(convertToPGML);

=head2 convertToPGML

This subroutine converts the file that is passed in as a multi-line string and
assumed to be an older-style PG file with BEGIN_TEXT/END_TEXT, BEGIN_SOLUTION/END_SOLUTION,
and BEGIN_HINT/END_HINT blocks.

The input is expected to be a string containing the source of the pg file to be converted.
This returns a string that is the converted input string.

=cut

# This stores the answers inside of ANS and related functions.
my @ans_list;

sub convertToPGML {
	my ($pg_source) = @_;

	# Get a list of all of the ANS, LABELED_ANS, etc. in the problem.
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
			# Parse the macros, which may be on multiple rows and may be in a qw block.
			my $macros          = '';
			my $num_macro_lines = 1; # store the number of lines in the loadMacro so the output is similar to the input.
			while ($row !~ /\)\s*;/) {
				# Remove comments within loadMacros block (should we keep them?)
				$row =~ s/#.*$//;
				$macros .= $row;
				++$num_macro_lines;
				$row = shift @rows;
				my @mrow = split(/#/, $row);
				# This only adds the row if there is something relevant to the left of a #
				$macros .= $mrow[0] if $mrow[0] !~ /^\s*$/;
			}
			$macros .= $row;

			my $load_macros_block = parseLoadMacros($macros);

			# If PGML.pl is a macro and there are no BEGIN_TEXT/HINT/SOLUTION blocks
			# return the original source.
			return { pgmlCode => $pg_source }
				if (!defined($load_macros_block->{errors})
					&& grep { $_ eq 'PGML.pl' } @{ $load_macros_block->{macros} }
					&& $pg_source !~ /^\s*BEGIN_(TEXT|HINT|SOLUTION)/m);

			return { errors => $load_macros_block->{errors}, pgmlCode => $pg_source } if ($load_macros_block->{errors});

			if ($load_macros_block->{qw_start}) {
				if ($num_macro_lines > 1) {    # put each macro on a separate line
					push(@all_lines, 'loadMacros(qw' . $load_macros_block->{qw_start});
					push(@all_lines, "\t$_") for (@{ $load_macros_block->{macros} });
					push(@all_lines, $load_macros_block->{qw_end} . ');');
				} else {
					push(@all_lines,
						'loadMacros(qw'
							. $load_macros_block->{qw_start}
							. join(' ', @{ $load_macros_block->{macros} })
							. $load_macros_block->{qw_end} . ');',
						'');
				}
			} else {
				push(@all_lines, 'loadMacros(' . join(', ', map {"'$_'"} @{ $load_macros_block->{macros} }) . ');', '');
			}
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
	return { pgmlCode => join "\n", @all_lines };
}

sub parseLoadMacros {
	my ($macros) = @_;

	my $error_string = 'The loadMacros statement could not be parsed. Check for syntax errors.';

	return { errors => $error_string }
		if $macros =~ /loadMacros\(.*?\)(.*?);/s && $1 !~ /^\s*$/m;

	my @macros;
	my ($qw_start, $qw_end);    # the characters if the loadMacros has a qw block.
	my $qw_matches = { '{' => '}', '(' => ')', '[' => ']', '/' => '/', '|' => '|' };

	# The following can parse loadMacros in the form loadMacros('macro1.pl', 'macro2.pl'); or
	# loadMacros(qw{macro1.pl macro2.pl});
	if ($macros =~ /loadMacros\((.*?)\);/ms) {
		my @macro_str = split(/\s*,\s*/, $1);

		for my $str (@macro_str) {
			if ($str =~ /^qw(.)/) {
				$qw_start = $1;
				$qw_end   = $qw_matches->{$qw_start};
				push(@macros, split(/\s+/, $1)) if $str =~ /^qw\Q${qw_start}\E(.*?)\Q${qw_end}\E/;
			} else {
				push(@macros, $str);
			}
		}

		@macros =
			grep {
				$_
				&& $_ !~
				/(PGstandard|PGML|PGauxiliaryFunctions|PGbasicmacros|PGanswermacros|MathObjects|PGcourse|AnswerFormatHelp).pl/x
			}
			map {s/['"]//gr} @macros;

		# Remove any duplicates:
		my %seen;
		@macros = grep { !$seen{$_}++ } @macros;
	} else {
		return { errors => $error_string };
	}

	@macros = ('PGstandard.pl', 'PGML.pl', @macros, 'PGcourse.pl');
	return {
		qw_start => $qw_start,
		qw_end   => $qw_end,
		macros   => \@macros
	};
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
		# If a variable is inside [_]{}, like '[_]{$a}', then leave it alone.
		if (my @matches = $row =~ /\$[\w\_]+/g) {
			my %seen;
			for my $m (grep { !$seen{$_}++ } @matches) {
				# $row =~ s/(?<!\{)(\Q$m\E)(?!\})/[$1]/g;
				$row =~ s/\[_+\]\{\Q$m\E\}(*SKIP)(*F)|(\Q$m\E)/[$1]/g;
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
