package WeBWorK::PG::PGProblemCritic;
use parent qw(Exporter);

use strict;
use warnings;
use experimental 'signatures';
use feature 'say';

use Mojo::File qw(curfile);
use Data::Dumper;

our @EXPORT_OK = qw(analyzePGfile analyzePGcode getDeprecatedMacros);

=head1 NAME

PGProblemCritic - Parse a PG program and analyze the contents for good and bad features.

=head1 DESCRIPTION

Analyze a pg file for use of old and current methods.

=over

=item  C<deprecated_macros>: a list of the macros that the problem uses that is in the C<macros/deprecated>
folder.

=item  Positive features:

=over 10

=item Uses PGML

=item Provides a solution

=item Provides a hint

=item Uses Scaffolds

=item Uses a custom checker

=item Uses a multianswer

=item Uses answer hints

=item Uses nicetables

=back

=item Old and deprecated features

=over 10

=item Use of BEGIN_TEXT/END_TEXT

=item Include the C<TEXT(beginproblem)>

=item Include old tables (for example from C<unionTables.pl>)

=item The use of C<num_cmp>, C<str_cmp> and C<fun_cmp> in lieu of using MathObjects

=item Including C<< Context()->TeXStrings >>

=item Calling C<loadMacros> more than once.

=item Using the line C< $showPartialCorrectAnswers = 1 > which is the default behavior and thus unnecessary.

=item Using methods from C<PGchoicemacros.pl>

=item Inlcuding code or other text below the C<ENDDOCUMENT();> line indicating the end of the problem.

=back

=back


=cut

sub analyzePGcode ($code) {
	# default flags for presence of features in a PG problem
	my $features = {
		metadata => { DBsubject => 0, DBchapter => 0, DBsection => 0, KEYWORDS => 0 },
		good     => {
			PGML           => 0,
			solution       => 0,
			hint           => 0,
			scaffold       => 0,
			custom_checker => 0,
			multianswer    => 0,
			answer_hints   => 0,
			nicetable      => 0,
		},
		bad => {
			BEGIN_TEXT              => 0,
			beginproblem            => 0,
			oldtable                => 0,
			num_cmp                 => 0,
			str_cmp                 => 0,
			fun_cmp                 => 0,
			context_texstrings      => 0,
			multiple_loadmacros     => 0,
			showPartialCorrect      => 0,
			old_multiple_choice     => 0,
			lines_below_enddocument => 0,
		},
		deprecated_macros => [],
		macros            => []
	};

	# Get a list of all deprecated macros.
	my $all_deprecated_macros = getDeprecatedMacros(curfile->dirname->dirname->dirname->dirname);

	# determine if the loadMacros has been parsed.
	my $loadmacros_parsed = 0;

	my @pglines = split /\n/, $code;
	my $line    = '';
	while (1) {
		$line = shift @pglines;
		# print Dumper $line;
		last unless defined($line);    # end of the file.
		next if $line =~ /^\s*$/;      # skip any blank lines.

		# Determine if some of the metadata tags are present.
		for (qw(DBsubject DBchapter DBsection KEYWORDS)) {
			$features->{metadata}{$_} = 1 if $line =~ /$_\(/i;
		}

		# Skip any full-line comments.
		next if $line =~ /^\s*#/;

		$features->{good}{solution} = 1 if $line =~ /BEGIN_(PGML_)?SOLUTION/;
		$features->{good}{hint}     = 1 if $line =~ /BEGIN_(PGML_)?HINT/;

		# Analyze the loadMacros info.
		if ($line =~ /loadMacros\(/) {
			$features->{bad}{multiple_loadmacros} = 1 if $loadmacros_parsed == 1;
			$loadmacros_parsed = 1;
			# Parse the macros, which may be on multiple rows.
			my $macros = $line;
			while ($line && $line !~ /\);\s*$/) {
				$line = shift @pglines;

				# Strip any comments at the end of lines.
				$line =~ s/(.*)#.*/$1/;
				$macros .= $line;
			}
			# Split by commas and pull out the quotes.
			# TODO: handle cases with loadMacros(qw/macro1.pl macro2.pl/);
			my @macros = map {s/['"\s]//gr} split(/\s*,\s*/, $macros =~ s/loadMacros\((.*)\)\;$/$1/r);
			$features->{macros} = \@macros;
			for my $macro (@macros) {
				push(@{ $features->{deprecated_macros} }, $macro) if (grep { $macro eq $_ } @$all_deprecated_macros);
			}
		} elsif ($line =~ /BEGIN_PGML(_SOLUTION|_HINT)?/) {
			$features->{good}{PGML} = 1;
			my @pgml_lines;
			while (1) {
				$line = shift @pglines;
				last if $line =~ /END_PGML(_SOLUTON|_HINT)?/;
				push(@pgml_lines, $line);
			}

			my $pgml_features = analyzePGMLBlock(@pgml_lines);
			$features->{bad}{missing_alt_tag} = 1 if $pgml_features->{missing_alt_tag};
		}

		if ($line =~ /ENDDOCUMENT/) {    # scan if there are any lines below the ENDDOCUMENT

			do {
				$line = shift @pglines;
				last unless defined($line);
				$features->{bad}{lines_below_enddocument} = 1 if $line !~ /^\s*$/;
			} while (defined($line));
		}

		# Check for bad features.
		$features->{bad}{beginproblem}       = 1 if $line =~ /beginproblem\(\)/;
		$features->{bad}{BEGIN_TEXT}         = 1 if $line =~ /(BEGIN_(TEXT|HINT|SOLUTION))|EV[23]/;
		$features->{bad}{context_texstrings} = 1 if $line =~ /->(texStrings|normalStrings)/;
		for (qw(num str fun)) {
			$features->{bad}{ $_ . '_cmp' } = 1 if $line =~ /${_}_cmp\(/;
		}
		$features->{bad}{oldtable}            = 1 if $line =~ /BeginTable/i;
		$features->{bad}{showPartialCorrect}  = 1 if $line =~ /\$showPartialCorrectAnswers\s=\s1/;
		$features->{bad}{old_multiple_choice} = 1
			if $line =~ /new_checkbox_multiple_choice/
			|| $line =~ /new_match_list/
			|| $line =~ /new_select_list/
			|| $line =~ /new_multiple_choice/
			|| $line =~ /qa\s\(/;

		# check for good features
		$features->{good}{scaffold}       = 1 if $line =~ /Scaffold::Begin/;
		$features->{good}{answer_hints}   = 1 if $line =~ /AnswerHints/;
		$features->{good}{multianswer}    = 1 if $line =~ /MultiAnswer/;
		$features->{good}{custom_checker} = 1 if $line =~ /checker =>/;
		$features->{good}{nicetables}     = 1 if $line =~ /DataTable|LayoutTable/;

	}
	return $features;
}

# Return a list of the macro filenames in the 'macros/deprecated' directory.
sub getDeprecatedMacros ($pgroot) {
	return Mojo::File->new($pgroot)->child('macros/deprecated')->list->map(sub { $_->basename })->to_array;
}

sub analyzePGfile ($file) {
	my $path = Mojo::File->new($file);
	die "The file: $file does not exist or is not readable" unless -r $path;

	return analyzePGcode($path->slurp);
}

# Parse a string that is a function in the form of "funct($arg1, $arg2, ..., param1 => val1, param2 => val2 , ...)"
# A hashref of the form {_args = [$arg1, $arg2, ...], param1 => val1, param2 => val2} is returned.

sub parseFunctionString($string) {

	my ($funct, $args);
	if ($string =~ /(\w+)\(\s*(.*)\)/) {
		($funct, $args) = ($1, $2);
	} else {
		return ();
	}

	my @args = split(/,\s/, $args);

	my %params = (_name => $funct, _args => []);
	for (@args) {
		if ($_ !~ /=>/) {
			push(@{ $params{_args} }, $_);
		} else {
			if ($_ =~ /(\w+)\s*=>\s*["']?([^"]*)["']?/) {
				my ($key, $value) = ($1, $2);
				$params{$key} = $value;
			}
		}
	}
	return %params;
}

# Perform some analysis of a PGML block.

sub analyzePGMLBlock(@lines) {
	my $pgml_features = {};

	while (1) {
		my $line = shift @lines;
		last unless defined($line);

		# If there is a perl block analyze  [@ @]
		if ($line =~ /\[@/) {
			my $perl_line = $line;
			while ($perl_line !~ /@\]/) {
				$line = shift @lines;
				$perl_line .= $line;
			}
			my ($perlcode) = $perl_line =~ /\[@\s*(.*)\s*@\]/;

			my %funct_info = parseFunctionString($perlcode);
			if (%funct_info && $funct_info{_name} =~ /image/) {
				if (defined($funct_info{extra_html_tags}) && $funct_info{extra_html_tags} !~ /alt/) {
					$pgml_features->{missing_alt_tag} = 1;
				}
			}

		} elsif (my ($alt_text) = $line =~ /\[!(.*)!\]/) {
			$pgml_features->{missing_alt_tag} = 1 if $alt_text =~ /^\s$/;
		}

	}
	return $pgml_features;
}
