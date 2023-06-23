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

use experimental 'signatures';
use base qw(Exporter);
use feature 'say';

use File::Basename;
use Pandoc;

our @EXPORT    = ();
our @EXPORT_OK = qw(renderSampleProblem);

=head1 NAME

SampleProblemParser - parse the documentation in a sample problem in the /doc
directory.

=head2 C<parseSampleProblem>

parse a PG file with extra documentation comments. The input is the file and
a hashef of global variables:

=over

=item C<metadata> a hashref which has information (name, directory, types, subjects, categories)
of every sample problem file.

=item C<macro_locations> a hashref of both C<macros_to_skip> in the documentation
as well as C<macros> to include as links within a problem.

=item C<pod_root> the root directory of the POD.

=item C<pg_doc_home> the url of the pg_doc home.

=back

=cut

sub parseSampleProblem ($file, %global) {
	my ($filename) = fileparse($file);
	open(my $FH, '<:encoding(UTF-8)', $file) or die qq{Could not open file "$file": $!};
	my @file_contents = <$FH>;
	close $FH;

	my (@blocks, @doc_rows, @code_rows, @categories, @description, @macros, @types, @subjects, @related);
	my (%options, $descr, $type, $name);

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
		} elsif ($row =~ /loadMacros\(/) {
			# Parse the macros, which may be on multiple rows.
			push(@code_rows, $row);
			my $macros = $row;
			while ($row && $row !~ /\);\s*$/) {
				$row = shift @file_contents;
				chomp($row);
				$row =~ s/\t/    /g;
				$macros .= $row;
				push(@code_rows, $row);
			}
			# Split by commas and pull out the quotes.
			@macros = map {s/['"\s]//gr} split(/\s*,\s*/, $macros =~ s/loadMacros\((.*)\)\;$/$1/r);
		} elsif ($row =~ /^#:/) {
			# This section is documentation to be parsed.
			$row = $row =~ s/^#://r;

			# Parse any PODLINK/PROBLINK commands in the documentation.
			if ($row =~ /(POD|PROB)?LINK\('(.*?)'\s*(,\s*'(.*)')?\)/) {
				my $link_text = $1 eq 'POD' ? $2 : $global{metadata}{$2}{name};
				my $url =
					$1 eq 'POD'
					? "$global{pod_root}/" . $global{macro_locations}{macros}{ $4 // $2 }
					: "$global{pg_doc_home}/" . $global{metadata}{$2}{dir} . '/' . ($2 =~ s/.pg$/.html/r);
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

	# The @doc_rows must be parsed then added to the @blocks.
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
		types       => \@types,
		related     => \@related,
		subjects    => \@subjects,
		blocks      => \@blocks,
		code        => join("\n", map { $_->{code} } @blocks),
		categories  => \@categories,
		macros      => \@macros,
		description => join("\n", @description)
	};
}

=head2 C<renderSampleProblem>

render a sample problem and output an HTML version of the problem.

=cut

use Data::Dumper;

sub renderSampleProblem ($filename, %global) {
	my $relative_dir = $global{metadata}{"$filename.pg"}{dir};
	my $path = "$global{problem_dir}/$relative_dir/$filename.pg";
	say "Processing file: $path" if $global{verbose};
	my $parsed_file = parseSampleProblem($path, %global);

	mkdir "$global{out_dir}/$relative_dir" unless -d "$out_dir/$relative_dir";

	say "Printing to '$global{out_dir}/$relative_dir/$filename.html'" if $global{verbose};
	open(my $FH, '>:encoding(UTF-8)', "$global{out_dir}/$relative_dir/$filename.html")
		or die qq{Could not open output file "$global{out_dir}/$relative_dir/$filename.html": $!};

	print $FH $global{mt}->render_file("$global{template_dir}/problem-template.mt",
		{ %$parsed_file, %global, filename => $filename });
	close $FH;

	push(@samples,  $path) if grep { $_ eq 'sample' } @{ $parsed_file->{types} };
	push(@snippets, $path) if grep { $_ eq 'snippet' } @{ $parsed_file->{types} };

	$techniques->{ $parsed_file->{name} } = "$relative_dir/$filename.html"
		if grep { $_ eq 'technique' } @{ $parsed_file->{types} };

	for my $category (@{ $parsed_file->{categories} }) {
		$categories->{$category}{ $parsed_file->{name} } = "$relative_dir/$filename.html";
	}

	for my $subject (@{ $parsed_file->{subjects} }) {
		$subjects->{$subject}{ $parsed_file->{name} } = "$relative_dir/$filename.html";
	}

	for my $macro (@{ $parsed_file->{macros} }) {
		$macros->{$macro}{ $parsed_file->{name} } = "$relative_dir/$filename.html";
	}

	# Write the code to a separate file
	open($FH, '>:encoding(UTF-8)', "$global{out_dir}/$relative_dir/$filename.pg")
		or die qq{Could not open output file "$global{out_dir}/$relative_dir/$filename.pg": $!};
	print $FH $parsed_file->{code};
	close $FH;
	say "Printing pg file to '$global{out_dir}/$relative_dir/$filename.pg'" if $global{verbose};
	return;
}

sub writeIndex ($type, $index_table) {
	$index_info = {
		category => {
			label => 'Categories',
			template => 'general',
		}
	}

}

1;
