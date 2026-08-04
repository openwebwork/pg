
=head1 NAME

WeBWorK::PG::ConvertToPGML - convert a file in original PG format to PGML

=head1 DESCRIPTION

Converts a pg file to PGML format.

This script does a number of conversions:

=over

=item *

Update the loadMacros call to include C<PGML.pl>, eliminate C<MathObjects.pl>
and C<niceTables.pl> (since they are loaded by C<PGML.pl>) and adds
C<PGcourse.pl> to the end of the list.

=item *

Coverts C<BEGIN_TEXT>/C<END_TEXT>, C<BEGIN_SOLUTION>/C<END_SOLUTION>,
C<BEGIN_HINT>/C<END_HINT>, and the older
C<TEXT(EV2(<<TERM));>/C<SOLUTION(EV3(<<TERM));>/C<HINT(EV2(<<TERM));> heredoc
forms (with C<TERM> being any terminator the problem author chose) to their
newer C<BEGIN_PGML> blocks.

=item *

Convert math mode in these blocks to PGML style math mode.

=item *

Convert other styling (bold, italics) to PGML style.

=item *

Convert variables to the interpolated C<[$var]> PGML style.

=item *

Leave answer rules and answer evaluators as they were, as ordinary Perl code
inside a C<[@ @]> block. Pairing them up and converting them to PGML answer
blanks is left entirely to manual review.

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

use PPI;

require WeBWorK::PG::Translator;

our @EXPORT_OK = qw(convertToPGML);

=head2 convertToPGML

This subroutine converts the file that is passed in as a multi-line string and
assumed to be an older-style PG file with BEGIN_TEXT/END_TEXT,
BEGIN_SOLUTION/END_SOLUTION, and BEGIN_HINT/END_HINT blocks.

The input is expected to be a string containing the source of the pg file to be
converted.  This returns a string that is the converted input string.

=cut

# Matches the start of any old-style BEGIN_TEXT/HINT/SOLUTION content block, or TEXT(EV2(<<TERM)); /
# SOLUTION(EV3(<<'TERM')); / HINT(EV2(<<"TERM")); forms. TERM is whatever bareword the problem author chose as the
# heredoc or nowdoc terminator. It is captured here, and used by the main loop below to find the matching end-of-block
# row. The EVn form is sometimes seen called with an explicit & sigil, e.g. &SOLUTION(EV3(<<'EOT'));, which is tolerated
# here too. The BEGIN_TEXT/HINT/SOLUTION line itself must have nothing but horizontal whitespace before it and nothing
# but horizontal whitespace and/or semicolons after it just as in translation, so a line that would not actually be
# treated as BEGIN_TEXT in translation is not treated as one here either. This is shared between the main conversion
# loop and the "is this already converted" check so the two can't drift out of sync.
my $OLD_BLOCK_START_RE = qr/
	^\h*BEGIN_(?<beginKind>TEXT|HINT|SOLUTION)[\h;]*$ |
	&?(?:TEXT|HINT|SOLUTION)\s*\(\s*EV[23]\s*\(\s*<<\s*(?<termQuote>['"]?)(?<term>\w+)\k<termQuote>\s*\)\s*\)\s*;?
/xm;

# Maps a bracket-style quote-like delimiter to its closing character.
my %QUOTE_LIKE_CLOSE = ('(' => ')', '{' => '}', '[' => ']', '<' => '>');

# Returns an error message if $pg_source is not structurally well-formed Perl once translated, or undef if it is. This
# uses PPI, and does not actually compile or execute the code which would be a security vulnerability. PPI is a
# heuristic parser rather than a full Perl grammar, so it is not a perfect substitute for actually compiling or
# executing the file, but it reliably flags the kind of gross structural breakage (unbalanced quotes/braces/parens, an
# unterminated heredoc, a truncated statement) this check is for.
sub checkPGSyntax {
	my ($pg_source) = @_;
	my $translated = WeBWorK::PG::Translator::default_preprocess_code($pg_source);

	my $document = PPI::Document->new(\$translated);
	return 'The file could not be parsed by PPI: ' . PPI::Document->errstr unless $document;

	my @unclosed = grep { !defined $_->finish } @{ $document->find('PPI::Structure') || [] };
	return 'The file contains an unclosed ' . $unclosed[0]->braces . ' delimiter.' if @unclosed;

	return;
}

sub convertToPGML {
	my ($pg_source) = @_;

	# Check the source syntax and stop before attempting the conversion if there are syntax errors, rather than risk
	# silently producing a mangled result from source that was already broken to begin with.
	if (my $compileError = checkPGSyntax($pg_source)) {
		return {
			error    => "The file could not be converted because it does not compile: $compileError",
			pgmlCode => $pg_source
		};
	}

	my @pgml_block;
	my $in_pgml_block = 0;
	my $block_end_re;
	my @all_lines;

	my @rows = split(/\n/, $pg_source);

	while (@rows) {
		my $row = shift @rows;
		if (!$in_pgml_block && $row =~ $OLD_BLOCK_START_RE) {
			push(@pgml_block, $row);
			$in_pgml_block = 1;
			# BEGIN_TEXT/HINT/SOLUTION is closed by the matching END_ keyword, allowing the same horizontal
			# whitespace/semicolons that are allowed in translation and nothing else. The EV2/EV3 heredoc forms are
			# closed by a line consisting of just the captured terminator, and the terminator must be alone on the line
			# with no whitespace at all, since translation does not strip that.
			$block_end_re = defined $+{term} ? qr/^\Q$+{term}\E$/ : qr/^\h*END_\Q$+{beginKind}\E[\h;]*$/;
		} elsif ($in_pgml_block && $row =~ $block_end_re) {
			push(@pgml_block, $row);
			$in_pgml_block = 0;
			push(@all_lines, @{ convertPGMLBlock(\@pgml_block) });
			@pgml_block = ();
		} elsif ($in_pgml_block) {
			push(@pgml_block, $row);
		} elsif ($row !~ /^\s*#/ && $row =~ /loadMacros\(/) {
			# Parse the macros, which may be on multiple rows and may be in a qw block.
			my $macros          = '';
			my $num_macro_lines = 1; # Store the number of lines in the loadMacro so the output is similar to the input.
			while ($row !~ /\)\s*;/) {
				$macros .= "$row\n";
				++$num_macro_lines;
				$row = shift @rows;
			}
			$macros .= $row;

			my $load_macros_block = parseLoadMacros($macros);

			# If the original loadMacros call already listed PGML.pl and there are no old-style content blocks,
			# this file has already been converted.  So return the original source unchanged.
			return { pgmlCode => $pg_source }
				if (!defined($load_macros_block->{error})
					&& $load_macros_block->{already_had_pgml}
					&& $pg_source !~ $OLD_BLOCK_START_RE);

			return { error => $load_macros_block->{error}, pgmlCode => $pg_source } if ($load_macros_block->{error});

			# Only a comment that trailed a macro which survived filtering, deduplication, and reordering is kept.  See
			# parseLoadMacros for how that is determined. Anything else (a comment on a macro that was dropped, a whole
			# commented-out line, a comment after the closing sign) has no macro left to sit next to in the rebuilt
			# call, so it is dropped rather than relocated somewhere that would misattribute it.
			my %comments_to_keep;
			for my $name (@{ $load_macros_block->{macros} }) {
				my $lines = $load_macros_block->{macro_comments}{$name};
				$comments_to_keep{$name} = $lines if $lines && @$lines;
			}

			if (%comments_to_keep) {
				# qw(...) has no comment syntax of its own, so this uses the quoted, one-macro-per-line form
				# regardless of how the original was written, since that is the only way to keep a comment
				# attached to the right line.
				push(@all_lines, 'loadMacros(');
				my @names = @{ $load_macros_block->{macros} };
				for my $i (0 .. $#names) {
					my $name  = $names[$i];
					my $comma = $i < $#names ? ',' : '';
					if ($comments_to_keep{$name}) {
						my @commentLines = @{ $comments_to_keep{$name} };
						push(@all_lines, "\t'$name'$comma " . shift(@commentLines));
						push(@all_lines, "\t\t$_") for @commentLines;
					} else {
						push(@all_lines, "\t'$name'$comma");
					}
				}
				push(@all_lines, ');');
			} elsif ($load_macros_block->{qw_start}) {
				if ($num_macro_lines > 1) {    # put each macro on a separate line
					push(@all_lines, 'loadMacros(qw' . $load_macros_block->{qw_start});
					push(@all_lines, "\t$_") for (@{ $load_macros_block->{macros} });
					push(@all_lines, $load_macros_block->{qw_end} . ');');
				} else {
					push(@all_lines,
						'loadMacros(qw'
							. $load_macros_block->{qw_start}
							. join(' ', @{ $load_macros_block->{macros} })
							. $load_macros_block->{qw_end}
							. ');');
				}
			} else {
				push(@all_lines, 'loadMacros(' . join(', ', map {"'$_'"} @{ $load_macros_block->{macros} }) . ');');
			}
			push(@all_lines, '');
		} else {
			push(@all_lines, cleanUpCode($row));
		}
	}

	# Remove blank lines if there are more than one.
	my @empty_lines = grep { $all_lines[$_] =~ /^\s*$/ } (0 .. $#all_lines);

	for (my $n = $#empty_lines; $n >= 1; --$n) {
		if ($empty_lines[$n] == $empty_lines[ $n - 1 ] + 1) {
			splice(@all_lines, $empty_lines[$n], 1);
		}
	}

	return { pgmlCode => join("\n", @all_lines) };
}

# Splits $row into a code part and a trailing # comment, skipping over any quote-like content first so a # inside a
# quoted string is not mistaken for the start of one. Returns (code, comment); comment is undef if $row had none.
# The comment keeps its leading #.
sub splitTrailingComment {
	my ($row) = @_;
	my $pos   = 0;
	my $len   = length($row);
	while ($pos < $len) {
		my $next = skipQuoteLike($row, $pos);
		if (defined $next) {
			$pos = $next;
			next;
		}
		return (substr($row, 0, $pos), substr($row, $pos)) if substr($row, $pos, 1) eq '#';
		++$pos;
	}
	return ($row, undef);
}

# Returns the content of $str trimmed of surrounding whitespace with one layer of Perl string quoting removed, or undef
# if it is not actually quoted at all. This handles the quote forms '...', "...", q(...), q{...}, qq(...), etc.
# (qw(...) is handled separately in parseLoadMacros, since it expands to multiple items, not one.)
sub matchQuotedString {
	my ($str) = @_;
	$str =~ s/^\s+|\s+$//g;

	return $2 if $str =~ /^(['"])(.*)\1$/s;

	if ($str =~ /^q{1,2}\s*(\S)/) {
		my $openDelim  = $1;
		my $closeDelim = $QUOTE_LIKE_CLOSE{$openDelim} // $openDelim;
		return $1 if $str =~ /^q{1,2}\s*\Q$openDelim\E(.*)\Q$closeDelim\E$/s;
	}

	return;
}

# Strips one layer of Perl string quoting from a single loadMacros list item to obtain the bare macro filename, but
# falls back to the trimmed item unchanged if it was not actually quoted.
sub unquoteMacroItem {
	my ($str) = @_;
	$str =~ s/^\s+|\s+$//g;
	my $inner = matchQuotedString($str);
	return defined $inner ? $inner : $str;
}

sub parseLoadMacros {
	my ($macros) = @_;

	my $error_string = 'The loadMacros statement could not be parsed. Check for syntax errors.';

	return { error => $error_string } unless $macros =~ /loadMacros\s*\(/;
	my $openParen = $+[0] - 1;

	# Find the matching closing parenthesis for a `loadMacros(` call. Anything after the `;` other than a comment
	# means this was not really a bare loadMacros(...); statement.
	my $closeParen = matchingDelimiter($macros, $openParen);
	return { error => $error_string }
		unless defined $closeParen && substr($macros, $closeParen + 1) =~ /^\s*;\s*(?:#.*)?$/;

	my $inner = substr($macros, $openParen + 1, $closeParen - $openParen - 1);

	my @macros;
	my ($qw_start, $qw_end);    # The characters if the loadMacros has a qw block.
	my $already_had_pgml;       # Whether the original loadMacros call already listed PGML.pl.

	# The following can parse loadMacros in the form `loadMacros('macro1.pl', 'macro2.pl');`,
	# `loadMacros(q(macro1.pl));`, or `loadMacros(qw{macro1.pl macro2.pl});` including qw blocks mixed with other quoted
	# forms. A list item that is not a qw(...) block and not actually a quoted string is treated as a parse error.
	for my $str (splitTopLevelArgs($inner)) {
		if ($str =~ /^qw(.)/) {
			$qw_start = $1;
			$qw_end   = $QUOTE_LIKE_CLOSE{$qw_start} // $qw_start;
			push(@macros, split(/\s+/, $1)) if $str =~ /^qw\Q${qw_start}\E(.*?)\Q${qw_end}\E/;
		} else {
			my $name = matchQuotedString($str);
			return { error => $error_string } unless defined $name;
			push(@macros, $name);
		}
	}

	# Collect any comment trailing each macro's own line, keeping it with that macro so it can be kept only if the
	# macro itself survives filtering below. A comment-only line is treated as continuing the comment on the line
	# right before it, but only if that line had a comment of its own to continue - a comment-only line right
	# after a macro with no comment (e.g. a whole commented-out macro entry a couple of lines down from the last
	# real comment) is not attributed to that earlier macro. This still cannot reliably tell an intentional
	# continuation apart from an unrelated comment that happens to immediately follow one, so it is a best effort.
	# A line with a qw(...) block is not attributed to any one macro in it, since qw() has no comment syntax of
	# its own to preserve one inline anyway.
	my %macro_comments;
	my $currentMacro;
	my $chaining = 0;
	for my $line (split /\n/, $inner) {
		my ($code, $comment) = splitTrailingComment($line);
		if ($code =~ /\S/) {
			my @items = splitTopLevelArgs($code);
			$currentMacro = @items && $items[-1] !~ /^qw/ ? unquoteMacroItem($items[-1]) : undef;
			if (defined $comment) {
				push(@{ $macro_comments{$currentMacro} }, $comment) if defined $currentMacro;
				$chaining = 1;
			} else {
				$chaining = 0;
			}
		} elsif (defined $comment && $chaining) {
			push(@{ $macro_comments{$currentMacro} }, $comment) if defined $currentMacro;
		} else {
			$chaining = 0;
		}
	}

	# Determine if the *original* loadMacros call already listed PGML.pl before it is added unconditionally below.
	# This is used by the caller to decide whether this file has already been converted.
	$already_had_pgml = !!(grep { $_ eq 'PGML.pl' } @macros);

	@macros =
		grep {
			$_ && $_ !~ /(
			AnswerFormatHelp |
			MathObjects |
			niceTables |
			PGML |
			PGanswermacros |
			PGauxiliaryFunctions |
			PGbasicmacros |
			PGcourse |
			PGstandard
			).pl/x
		} @macros;

	# Remove any duplicates:
	my %seen;
	@macros = grep { !$seen{$_}++ } @macros;

	@macros = ('PGstandard.pl', 'PGML.pl', @macros, 'PGcourse.pl');
	return {
		qw_start         => $qw_start,
		qw_end           => $qw_end,
		macros           => \@macros,
		already_had_pgml => $already_had_pgml,
		macro_comments   => \%macro_comments
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
# * converting \{ \} to [@ @] without altering code within the \{ \}, including any answer rule inside it, which is
#   left as ordinary Perl code for manual conversion.
sub convertPGMLBlock {
	my ($block) = @_;
	my @new_rows;

	# The TEXT(EV2(<<TERM)); / SOLUTION(EV3(<<'TERM')); / HINT(EV2(<<"TERM")); forms end with a line that is just TERM,
	# which could be any bareword the problem author chose, so unlike the mirroring BEGIN_TEXT/END_TEXT keyword
	# substitutions below, both the opening and closing rows for this form are rewritten here by position (the
	# first/last row of the block, which the main loop already identified using this same terminator) rather than by
	# searching for TERM as text in every row, which risked corrupting an unrelated row that coincidentally contained
	# TERM as a substring. A leading & (e.g. &SOLUTION(EV3(<<'EOT'));) is stripped along with the rest of the call.
	if ($block->[0] =~ /^\s*&?(TEXT|HINT|SOLUTION)\s*\(\s*EV[23]\s*\(\s*<<\s*(['"]?)(\w+)\2\s*\)\s*\)\s*;?/) {
		my ($kind, $term) = ($1, $3);
		my $tag = $kind eq 'TEXT' ? 'PGML' : "PGML_$kind";
		$block->[0]  = "BEGIN_$tag";
		$block->[-1] = "END_$tag" if @$block > 1 && $block->[-1] =~ /^\Q$term\E$/;
	}

	while (@$block) {
		my $row                   = shift @$block;
		my $add_blank_line_before = ($row =~ /^\s*\$PAR/);
		my $add_blank_line_after  = ($row =~ /\$PAR\s*$/);

		# A row can hold more than one \{ \} escape (they do not nest), so each is pulled out into its own entry
		# and replaced with a placeholder, to be wrapped in [@ @] and put back after the other substitutions below,
		# none of which should touch Perl code.
		my ($extractedRow, $perlBlocks) = extractPerlBlocks($row, $block);
		$row = $extractedRow;

		# The whole row is consumed and replaced, not just the keyword, so that any horizontal whitespace and/or
		# semicolons that would be stripped in translation do not linger in the output.
		$row =~ s/^\h*(BEGIN|END)_TEXT[\h;]*$/$1_PGML/;
		$row =~ s/^\h*(BEGIN|END)_(SOLUTION|HINT)[\h;]*$/$1_PGML_$2/;

		# Remove $PAR, and $SPACE.
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

		# If there is an $HR, add blank lines before and after the PGML "---", and move on to the next row. $row itself
		# is not touched, so falling through to the rest of this loop and the push at the bottom would push the row a
		# second time, with its still-unconverted $HR wrapped into [$HR] by the variable interpolation below.
		if ($row =~ /^(.*)\$HR(.*)$/) {
			push @new_rows, $1 // '', '', '---', '', $2 // '';
			next;
		}

		# After many other variables have been replaced, replace the variables in the PGML block. An answer blank
		# like '[_]{$a}' is Perl code, not PGML text, so its variable is protected from this and restored
		# unchanged afterward.
		my ($protectedRow, $protectedBlanks) = protectAnswerBlanks($row);
		$protectedRow = wrapInterpolatedVariables($protectedRow);
		$row          = restoreAnswerBlanks($protectedRow, $protectedBlanks);

		# Wrap each extracted \{ \} block in [@ @] and put it back where its placeholder is. Adding a blank line
		# before or after for a $PAR is independent of this, so it wraps around the whole row once this is done.
		for my $lines (@$perlBlocks) {
			my @lines = grep { $_ !~ /^\s*$/ } @$lines;
			$lines[$_] =~ s/AnswerFormatHelp\(["']([\w\s]+)["']\)/helpLink('$1')/g for 0 .. $#lines;
			$row =~ s/\x02\d+\x02/'[@ ' . join("\n", @lines) . ' @]*'/e;
		}

		if ($add_blank_line_before) {
			push @new_rows, '', $row;
		} elsif ($add_blank_line_after) {
			push @new_rows, $row, '';
		} else {
			push @new_rows, $row;
		}

	}
	return \@new_rows;
}

# Pulls every \{ ... \} escape out of $row, replacing each with a placeholder, and returns the modified row along
# with an array reference of the removed blocks (each itself an array reference of the lines making up that block),
# in the order the placeholders reference them. A \{ \} escape does not nest, so the first \} found after a \{
# always closes it. If a \} is not found on the same row, rows are consumed from $block (further rows of the
# surrounding BEGIN_TEXT/END_TEXT block being converted) until one is found, making a multi-line block. If $block
# runs out first, the unterminated \{ and everything after it are left in the row as ordinary text.
sub extractPerlBlocks {
	my ($row, $block) = @_;
	my @extracted;
	my $out = '';
	while ((my $open = index($row, '\{')) >= 0) {
		$out .= substr($row, 0, $open);
		$row = substr($row, $open + 2);

		my @lines;
		my $close = index($row, '\}');
		while ($close < 0 && @$block) {
			push(@lines, $row);
			$row   = shift @$block;
			$close = index($row, '\}');
		}
		if ($close < 0) {
			$out .= '\{' . join("\n", @lines, $row);
			$row = '';
			last;
		}
		push(@lines, substr($row, 0, $close));
		$row = substr($row, $close + 2);

		$out .= "\x02" . scalar(@extracted) . "\x02";
		push(@extracted, \@lines);
	}
	$out .= $row;
	return ($out, \@extracted);
}

# Returns the index of the first character after a quote-like construct.  Quote-like constructs include '...', "...",
# q<delim>...<delim>, qq, qw, or qr, and delimited forms like q{...} that may nest.  Otherwise returns undef, and the
# caller should treat the character at $pos as an ordinary one.  m, s, tr, and y are not handled for now. Treating a
# bare "s" or "y" as the start of one risks misreading ordinary barewords or hash keys (e.g. "s => 5") as the start
# of a quote-like construct instead.
sub skipQuoteLike {
	my ($str, $pos) = @_;
	my $c = substr($str, $pos, 1);

	return skipDelimitedRun($str, $pos + 1, $c, $c) if $c eq q(') || $c eq q(");

	pos($str) = $pos;
	return unless $str =~ /\G(qw|qq|qr|q)\b\s*([^a-zA-Z0-9_\s=])/gc;
	my $delim = $2;
	return skipDelimitedRun($str, pos($str), $delim, $QUOTE_LIKE_CLOSE{$delim} // $delim);
}

# Skips from $pos which should be the index of the first character after the opening delimiter in $str passed in
# $openDelim to the first character in $str after the matching closing delimiter passed in $closeDelim. This honors
# backslash escapes and, when $openDelim and $closeDelim differ (a bracket-style delimiter), nesting of the delimiter
# pair (e.g.  q{a{b}c} balances its inner braces). Returns undef if the string ends before the close delimiter is found.
sub skipDelimitedRun {
	my ($str, $pos, $openDelim, $closeDelim) = @_;
	my $depth = 1;
	my $len   = length($str);
	while ($pos < $len) {
		my $c = substr($str, $pos, 1);
		if ($c eq '\\') {
			$pos += 2;
			next;
		} elsif ($openDelim ne $closeDelim && $c eq $openDelim) {
			++$depth;
		} elsif ($c eq $closeDelim) {
			--$depth;
			return $pos + 1 if $depth == 0;
		}
		++$pos;
	}
	return;
}

# Given a string and the index of an opening delimiter character in it, scans forward treating any of ( [ { as
# equivalent openers and ) ] } as closers (skipping over quote-like constructs and comments) and returns the index of
# the matching closing delimiter.  Returns undef if the string ends before the closing delimiter is found.
sub matchingDelimiter {
	my ($str, $pos) = @_;
	my $depth = 0;
	my $len   = length($str);
	while ($pos < $len) {
		my $next = skipQuoteLike($str, $pos);
		if (defined $next) {
			$pos = $next;
			next;
		}
		my $c = substr($str, $pos, 1);
		if ($c eq '#') {
			my $nl = index($str, "\n", $pos);
			return if $nl < 0;
			$pos = $nl;
		} elsif ($c =~ /[(\[{]/) {
			++$depth;
		} elsif ($c =~ /[)\]}]/) {
			--$depth;
			return $pos if $depth == 0;
		}
		++$pos;
	}
	return;
}

# Replaces each already-formed answer blank (a '[_]{...}', '[__]{...}', etc., with the brace content possibly spanning
# nested delimiters) in $row with a placeholder, so that it can be passed through other substitutions unchanged and then
# restored with restoreAnswerBlanks. Returns the modified row and an array reference of the blanks that were removed, in
# the order the placeholders reference them.
sub protectAnswerBlanks {
	my ($row) = @_;
	my @protected;
	my $out = '';
	my $pos = 0;
	while ($row =~ /\[_+\]\{/g) {
		my $matchStart = $-[0];
		my $braceEnd   = matchingDelimiter($row, $+[0] - 1);
		last unless defined $braceEnd;
		$out .= substr($row, $pos, $matchStart - $pos) . "\x01" . scalar(@protected) . "\x01";
		push(@protected, substr($row, $matchStart, $braceEnd - $matchStart + 1));
		$pos = $braceEnd + 1;
		pos($row) = $pos;
	}
	$out .= substr($row, $pos);
	return ($out, \@protected);
}

sub restoreAnswerBlanks {
	my ($row, $protected) = @_;
	$row =~ s/\x01(\d+)\x01/$protected->[$1]/g;
	return $row;
}

# Given a string and the index of a $ sigil in it, returns the index just past the full variable expression there:
# the bare name, plus any immediately following chain of subscripts ($var[0], $var{key}) and arrow dereferences
# ($var->[0], $var->{key}), matching what Perl itself interpolates for $var in a double-quoted string - a bare
# ->method call, for example, is not part of that and is correctly left out. Returns undef if $pos is not the start
# of a variable name.
sub scalarVariableEnd {
	my ($str, $pos) = @_;
	return unless substr($str, $pos, 1) eq '$';
	return unless substr($str, $pos + 1) =~ /^([A-Za-z_]\w*)/;
	my $end = $pos + 1 + length($1);

	while (1) {
		my $subStart = $end;
		$subStart += 2 if substr($str, $subStart, 2) eq '->' && substr($str, $subStart + 2, 1) =~ /[\[{]/;
		last unless substr($str, $subStart, 1) =~ /[\[{]/;
		my $close = matchingDelimiter($str, $subStart);
		last unless defined $close;
		$end = $close + 1;
	}
	return $end;
}

# Wraps every $var interpolation in $str in [ ], PGML style, including any subscript or dereference chain (see
# scalarVariableEnd) so that e.g. $sa[0] becomes [$sa[0]], not [$sa][0].
sub wrapInterpolatedVariables {
	my ($str) = @_;
	my $out   = '';
	my $pos   = 0;
	my $len   = length($str);
	while ($pos < $len) {
		my $end = scalarVariableEnd($str, $pos);
		if (defined $end) {
			$out .= '[' . substr($str, $pos, $end - $pos) . ']';
			$pos = $end;
		} else {
			$out .= substr($str, $pos, 1);
			++$pos;
		}
	}
	return $out;
}

# Removes every unquoted # comment (from # to the next newline, if any) from $str. The content of any quote-like
# construct (see skipQuoteLike), where a # is not a comment, is left untouched, and so are newlines themselves - only
# the comment text between # and the end of its line is dropped.
sub stripComments {
	my ($str) = @_;
	my $out   = '';
	my $pos   = 0;
	my $len   = length($str);
	while ($pos < $len) {
		my $next = skipQuoteLike($str, $pos);
		if (defined $next) {
			$out .= substr($str, $pos, $next - $pos);
			$pos = $next;
			next;
		}
		if (substr($str, $pos, 1) eq '#') {
			my $nl = index($str, "\n", $pos);
			$pos = $nl < 0 ? $len : $nl;
			next;
		}
		$out .= substr($str, $pos, 1);
		++$pos;
	}
	return $out;
}

# Splits a string (the inside of a balanced pair of brackets, not including the brackets themselves) on commas that
# are at bracket depth 0 and outside of quote-like constructs (see skipQuoteLike), after first removing any #
# comments (see stripComments) - not just skipping over them, since a comment between two commas would otherwise be
# folded into whichever part follows it. This lets e.g. a loadMacros() list with macro names wrapped in q(...), or
# with comments between entries, split into exactly the intended items.
sub splitTopLevelArgs {
	my ($str) = @_;
	$str = stripComments($str);
	my @parts;
	my $depth = 0;
	my $start = 0;
	my $len   = length($str);
	my $pos   = 0;
	while ($pos < $len) {
		my $next = skipQuoteLike($str, $pos);
		if (defined $next) {
			$pos = $next;
			next;
		}
		my $c = substr($str, $pos, 1);
		if ($c =~ /[(\[{]/) {
			++$depth;
		} elsif ($c =~ /[)\]}]/) {
			--$depth;
		} elsif ($c eq ',' && $depth == 0) {
			push(@parts, substr($str, $start, $pos - $start));
			$start = $pos + 1;
		}
		++$pos;
	}
	push(@parts, substr($str, $start));
	return grep {/\S/} map {s/^\s+|\s+$//gr} @parts;
}

# Removes some unnecessary code, including:
# * TEXT(beginproblem())
# * Context()->texStrings;
# * Context()->normalStrings;
# * a line that is only comment symbols.
sub cleanUpCode {
	my ($row) = @_;
	$row =~ s/^\s*#+\s*$//;
	$row =~ s/Context\(\)->normalStrings;//;
	$row =~ s/Context\(\)->texStrings;//;
	$row =~ s/TEXT\(\s*&?beginproblem(\(\))?\s*\);//;
	return $row;
}

1;
