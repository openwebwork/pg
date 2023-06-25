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

package SampleProblemParser;
use parent qw(Exporter);

use strict;
use warnings;
use experimental 'signatures';
use feature 'say';

use File::Basename qw(dirname basename);
use File::Find qw(find);
use Pandoc;

our @EXPORT_OK = qw(parseSampleProblem generateMetadata);

=head1 NAME

SampleProblemParser - Parse the documentation in a sample problem in the /doc
directory.

=head2 C<parseSampleProblem>

Parse a PG file with extra documentation comments. The input is the file and a
hash of global variables:

=over

=item C<metadata>: A reference to a hash which has information (name, directory,
types, subjects, categories) of every sample problem file.

=item C<macro_locations>: A reference to a hash of macros to include as links
within a problem.

=item C<pod_root>: The root directory of the POD.

=item C<pg_doc_home>: The url of the pg_doc home.

=item C<url_extension>: The html url extension (including the dot) to use for pg
doc links.  The default is the empty string.

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
			$row = $row =~ s/^#://r;

			# Parse any PODLINK/PROBLINK commands in the documentation.
			if ($row =~ /(POD|PROB)?LINK\('(.*?)'\s*(,\s*'(.*)')?\)/) {
				my $link_text = $1 eq 'POD' ? $2 : $global{metadata}{$2}{name};
				my $url =
					$1 eq 'POD'
					? "$global{pod_root}/" . $global{macro_locations}{ $4 // $2 }
					: "$global{pg_doc_home}/$global{metadata}{$2}{dir}/" . ($2 =~ s/.pg$/$global{url_extension}/r);
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

=head2 C<generateMetadata>

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
					my $metadata = parseMetadata($File::Find::name, $problem_dir, $options{macro_locations});
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

sub parseMetadata ($path, $problem_dir, $macro_locations = {}) {
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

1;
