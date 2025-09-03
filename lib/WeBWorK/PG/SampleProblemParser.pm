package WeBWorK::PG::SampleProblemParser;
use parent qw(Exporter);

use strict;
use warnings;
use experimental 'signatures';
use feature 'say';

my $pgRoot;

use Mojo::File qw(curfile);
BEGIN { $pgRoot = curfile->dirname->dirname->dirname->dirname; }

use File::Basename qw(dirname basename);
use File::Find     qw(find);
use Mojo::File     qw(path);
use Mojo::JSON     qw(decode_json encode_json);
use Pandoc;
use Pod::Simple::Search;
use Pod::Simple::SimpleTree;

our @EXPORT_OK = qw(parseSampleProblem generateMetadata getSampleProblemCode getSearchData);

=head1 NAME

WeBWorK::PG::SampleProblemParser - Parse sample problems and extract metadata,
documentation, and code.

=head2 parseSampleProblem

Parse a PG file with extra documentation comments. The input is the file and a
hash of global variables:

=over

=item *

C<metadata>: A reference to a hash which has information (name, directory,
types, subjects, categories) of every sample problem file.

=item *

C<macro_locations>: A reference to a hash of macros to include as links within a
problem.

=item *

C<pod_base_url>: The base URL for the POD HTML files.

=item *

C<sample_problem_base_url>: The base URL for the sample problem HTML files.

=item *

C<url_extension>: The html url extension (including the dot) to use for pg doc
links.  The default is the empty string.

=back

=cut

sub parseSampleProblem ($file, %global) {
	my $filename = basename($file);
	open(my $FH, '<:encoding(UTF-8)', $file) or do {
		warn qq{Could not open file "$file": $!};
		return {};
	};
	my @file_contents = <$FH>;
	close $FH;

	my (@blocks,  @doc_rows, @code_rows, @description);
	my (%options, $descr,    $type,      $name);

	$global{url_extension} //= '';

	while (my $row = shift @file_contents) {
		chomp($row);
		$row =~ s/\t/    /g;
		if ($row =~ /^#:%\s*(categor(y|ies)|types?|subjects?|see_also|name)\s*=\s*(.*)\s*$/) {
			# skip this, already parsed.
		} elsif ($row =~ /^#:%\s*(.*)?/) {
			# The row has the form #:% section = NAME.
			# This should parse the previous named section and then reset @doc_rows and @code_rows.
			push(
				@blocks,
				{
					%options,
					doc  => pandoc->convert(markdown => 'html', join("\n", @doc_rows)),
					code => join("\n", @code_rows)
				}
			) if %options;
			%options   = split(/\s*:\s*|\s*,\s*|\s*=\s*|\s+/, $1);
			@doc_rows  = ();
			@code_rows = ();
		} elsif ($row =~ /^#:/) {
			# This section is documentation to be parsed.
			$row = $row =~ s/^#:\s?//r;

			# Parse any LINK/PODLINK/PROBLINK commands in the documentation.
			if ($row =~ /(POD|PROB)?LINK\('(.*?)'\s*(,\s*'(.*)')?\)/) {
				my $link_text = defined($1) ? $1 eq 'POD' ? $2 : $global{metadata}{$2}{name} : $2;
				my $url =
					defined($1)
					? $1 eq 'POD'
						? "$global{pod_base_url}/" . $global{macro_locations}{ $4 // $2 }
						: "$global{sample_problem_base_url}/$global{metadata}{$2}{dir}/"
						. ($2 =~ s/.pg$/$global{url_extension}/r)
					: $4;
				$row = $row =~ s/(POD|PROB)?LINK\('(.*?)'\s*(,\s*'(.*)')?\)/[$link_text]($url)/gr;
			}

			push(@doc_rows, $row);
		} elsif ($row =~ /^##\s*(END)?DESCRIPTION\s*$/) {
			$descr = $1 ? 0 : 1;
		} elsif ($row =~ /^##/ && $descr) {
			push(@description, $row =~ s/^##\s*//r);
			push(@code_rows,   $row);
		} else {
			push(@code_rows, $row);
		}
	}

	# The last @doc_rows must be parsed then added to the @blocks.
	push(
		@blocks,
		{
			%options,
			doc  => pandoc->convert(markdown => 'html', join("\n", @doc_rows)),
			code => join("\n", @code_rows)
		}
	);

	return {
		name        => $global{metadata}{$filename}{name},
		blocks      => \@blocks,
		code        => join("\n", map { $_->{code} } @blocks),
		description => join("\n", @description)
	};
}

=head2 generateMetadata

Build a hash of metadata for all PG files in the given directory.  A reference
to the hash that is built is returned.

=cut

sub generateMetadata ($problem_dir, %options) {
	my $index_table = {};

	find(
		{
			wanted => sub {
				say "Reading file: $File::Find::name" if $options{verbose};

				if ($File::Find::name =~ /\.pg$/) {
					my $metadata = parseMetadata($File::Find::name, $problem_dir);
					unless (@{ $metadata->{types} }) {
						warn "The type of sample problem is missing for $File::Find::name.";
						return;
					}
					unless ($metadata->{name}) {
						warn "The name attribute is missing for $File::Find::name.";
						return;
					}
					$index_table->{ basename($File::Find::name) } = $metadata;
				}
			}
		},
		$problem_dir
	);

	return $index_table;
}

my @macros_to_skip = qw(
	PGML.pl
	PGcourse.pl
	PGstandard.pl
);

sub parseMetadata ($path, $problem_dir) {
	open(my $FH, '<:encoding(UTF-8)', $path) or do {
		warn qq{Could not open file "$path": $!};
		return {};
	};
	my @file_contents = <$FH>;
	close $FH;

	my @problem_types = qw(sample technique snippet);

	my $metadata = { dir => (dirname($path) =~ s/$problem_dir\/?//r) =~ s/\/*$//r };

	while (my $row = shift @file_contents) {
		if ($row =~ /^#:%\s*(categor(y|ies)|types?|subjects?|see_also|name)\s*=\s*(.*)\s*$/) {
			# The row has the form #:% categories = [cat1, cat2, ...].
			my $label = lc($1);
			my @opts  = $3 =~ /\[(.*)\]/ ? map { $_ =~ s/^\s*|\s*$//r } split(/,/, $1) : ($3);
			if ($label =~ /types?/) {
				for my $opt (@opts) {
					warn "The type of problem must be one of @problem_types"
						unless grep { lc($opt) eq $_ } @problem_types;
				}
				$metadata->{types} = [ map { lc($_) } @opts ];
			} elsif ($label =~ /^categor/) {
				$metadata->{categories} = \@opts;
			} elsif ($label =~ /^subject/) {
				$metadata->{subjects} = [ map { lc($_) } @opts ];
			} elsif ($label eq 'name') {
				$metadata->{name} = $opts[0];
			} elsif ($label eq 'see_also') {
				$metadata->{related} = \@opts;
			}
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
			my @macros = map {s/['"\s]//gr} split(/\s*,\s*/, $macros =~ s/loadMacros\((.*)\)\;$/$1/r);
			$metadata->{macros} = [];
			for my $macro (@macros) {
				push(@{ $metadata->{macros} }, $macro) unless grep { $_ eq $macro } @macros_to_skip;
			}
		}
	}

	return $metadata;
}

=head2 getSampleProblemCode

Parse a PG file with extra documentation comments and strip that all out
returning the clean problem code. This returns the same code that
C<parseSampleProblem> returns, except at much less expense as it does not parse
the documentation, it does not require that the metadata be parsed first, and it
does not need macro POD information.

=cut

sub getSampleProblemCode ($file) {
	my $filename = basename($file);
	open(my $FH, '<:encoding(UTF-8)', $file) or do {
		warn qq{Could not open file "$file": $!};
		return '';
	};
	my @file_contents = <$FH>;
	close $FH;

	my (@code_rows, $inCode);

	while (my $row = shift @file_contents) {
		chomp($row);
		$row =~ s/\t/    /g;
		if ($row =~ /^#:(.*)?/) {
			# This is documentation so skip it.
		} elsif ($row =~ /^\s*(END)?DOCUMENT.*$/) {
			$inCode = $1 ? 0 : 1;
			push(@code_rows, $row);
		} elsif ($inCode) {
			push(@code_rows, $row);
		}
	}

	return join("\n", @code_rows);
}

=head2 getSearchData

Generate search data for sample problem files and macro POD. The only argument
is required and should be a file name to write the search data to. If the file
does not exist, then a new file containing the generated search data will be
written. If the file exists and contains search data from previously using this
method, then the data will be updated based on file modification times of the
sample problem files and macros. In any case an array reference containing the
generated search data will be returned.

=cut

my $stopWordsCache;

sub getSearchData ($searchDataFileName) {
	my $searchDataFile = path($searchDataFileName);
	my %files = map { $_->{filename} => $_ } @{ (eval { decode_json($searchDataFile->slurp('UTF-8')) } // []) };
	my @updatedFiles;

	my $stopWords = sub ($word) {
		return $stopWordsCache->{$word} if $stopWordsCache;
		$stopWordsCache = {};

		my $contents = eval { path("$pgRoot/assets/stop-words-en.txt")->slurp('UTF-8') };
		return $stopWordsCache if $@;

		for my $line (split("\n", $contents)) {
			chomp $line;
			next if $line =~ /^#/ || !$line;
			$stopWordsCache->{$line} = 1;
		}

		return $stopWordsCache->{$word};
	};

	my $processLine = sub ($line) {
		my %words;

		# Extract linked macros and problems.
		my @linkedFiles = $line =~ /(?:PODLINK|PROBLINK)\('([\w.]+)'\)/g;
		$words{$_} = 1 for @linkedFiles;

		# Replace any non-word characters with spaces.
		$line =~ s/\W/ /g;

		for my $word (split(/\s+/, $line)) {
			next if $word =~ /^\d*$/;
			$word = lc($word);
			$words{$word} = 1 if !$stopWords->($word);
		}
		return keys %words;
	};

	# Extract the text for a section from the given POD with a section header title.
	my $extractHeadText = sub ($root, $title) {
		my @index = grep { ref($root->[$_]) eq 'ARRAY' && $root->[$_][2] eq $title } 0 .. $#$root;
		return unless @index == 1;

		my $node = $root->[ $index[0] + 1 ];
		my $str  = '';
		for (2 .. $#$node) {
			$str .= ref($node->[$_]) eq 'ARRAY' ? $node->[$_][2] : $node->[$_];
		}
		return $str;
	};

	# Extract terms form POD headers.
	my $extractHeaders = sub ($root) {
		my %terms =
			map  { $_ => 1 }
			grep { $_ && !$stopWords->($_) }
			map  { split(/\s+/, $_) }
			map  { lc($_) =~ s/\W/ /gr }
			map {
				grep { !ref($_) }
				@$_[ 2 .. $#$_ ]
			} grep { ref($_) eq 'ARRAY' && $_->[0] =~ /^head\d+$/ } @$root;
		return [ keys %terms ];
	};

	# Process the sample problems in the sample problem directory.
	find(
		{
			wanted => sub {
				return unless $_ =~ /\.pg$/;

				my $file         = path($File::Find::name);
				my $lastModified = $file->stat->mtime;

				if ($files{$_}) {
					push(@updatedFiles, $files{$_});
					return if $files{$_}{lastModified} >= $lastModified;
				}

				my @fileContents = eval { split("\n", $file->slurp('UTF-8')) };
				return if $@;

				if (!$files{$_}) {
					$files{$_} = {
						type     => 'sample problem',
						filename => $_,
						dir      => $file->dirname->basename
					};
					push(@updatedFiles, $files{$_});
				}
				$files{$_}{lastModified} = $lastModified;

				my (%words, @kw, @macros, @subjects, $description);

				while (@fileContents) {
					my $line = shift @fileContents;
					if ($line =~ /^#:%\s*(\w+)\s*=\s*(.*)\s*$/) {
						# Store the name and subjects.
						$files{$_}{name} = $2 if $1 eq 'name';
						if ($1 eq 'subject') {
							@subjects = split(',\s*', $2 =~ s/\[(.*)\]/$1/r);
						}
					} elsif ($line =~ /^#:\s*(.*)?/) {
						my @newWords = $processLine->($1);
						@words{@newWords} = (1) x @newWords if @newWords;
					} elsif ($line =~ /loadMacros\(/) {
						my $macros = $line;
						while ($line && $line !~ /\);\s*$/) {
							$line = shift @fileContents;
							$macros .= $line;
						}
						my @usedMacros =
							map {s/['"\s]//gr} split(/\s*,\s*/, $macros =~ s/loadMacros\((.*)\)\;$/$1/r);

						# Get the macros other than PGML.pl, PGstandard.pl, and PGcourse.pl.
						for my $m (@usedMacros) {
							push(@macros, $m) unless $m =~ /^(PGML|PGstandard|PGcourse)\.pl$/;
						}
					} elsif ($line =~ /##\s*KEYWORDS\((.*)\)/) {
						@kw = map {s/^'(.*)'$/$1/r} split(/,\s*/, $1);
					} elsif ($line =~ /^##\s*DESCRIPTION/) {
						$line = shift(@fileContents);
						while ($line && $line !~ /^##\s*ENDDESCRIPTION/) {
							$description .= ($line =~ s/^##\s+//r) . ' ';
							$line = shift(@fileContents);
						}
						$description =~ s/\s+$//;
					}
				}

				$files{$_}{description} = $description;
				$files{$_}{subjects}    = \@subjects;
				$files{$_}{terms}       = [ keys %words ];
				$files{$_}{keywords}    = \@kw;
				$files{$_}{macros}      = \@macros;

				return;
			}
		},
		"$pgRoot/tutorial/sample-problems"
	);

	# Process the POD in macros in the macros directory.
	(undef, my $macroFiles) = Pod::Simple::Search->new->inc(0)->survey("$pgRoot/macros");
	for my $macroFile (sort keys %$macroFiles) {
		next if $macroFile =~ /deprecated/;

		my $file         = path($macroFile);
		my $fileName     = $file->basename;
		my $lastModified = $file->stat->mtime;

		if ($files{$fileName}) {
			push(@updatedFiles, $files{$fileName});
			next if $files{$fileName}{lastModified} >= $lastModified;
		}

		if (!$files{$fileName}) {
			$files{$fileName} = {
				type     => 'macro',
				id       => scalar(keys %files) + 1,
				filename => $fileName,
				dir      => $file->dirname->to_rel($pgRoot)->to_string
			};
			push(@updatedFiles, $files{$fileName});
		}
		$files{$fileName}{lastModified} = $lastModified;

		my $root = Pod::Simple::SimpleTree->new->parse_file($file->to_string)->root;

		$files{$fileName}{terms} = $extractHeaders->($root);

		if (my $nameDescription = $extractHeadText->($root, 'NAME')) {
			(undef, my $description) = split(/\s*-\s*/, $nameDescription, 2);
			$files{$fileName}{description} = $description if $description;
		}
	}

	# Re-index in case files were added or removed.
	my $count = 0;
	$_->{id} = ++$count for @updatedFiles;

	$searchDataFile->spew(encode_json(\@updatedFiles), 'UTF-8');

	return \@updatedFiles;
}

1;
