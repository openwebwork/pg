#!/usr/bin/env perl

use strict;
use warnings;
use experimental 'signatures';
use feature 'say';

use Mojo::Template;
use Mojo::File qw(curfile);
use Text::MultiMarkdown;
use File::Basename;
use Getopt::Long;
use File::Find qw(find);
use File::Copy qw(copy);
use YAML::XS qw(LoadFile);

my ($problem_dir, $out_dir, $pod_root, $pg_doc_home);
my $verbose = 0;

GetOptions(
	"d|problem_dir=s" => \$problem_dir,
	"o|out_dir=s"     => \$out_dir,
	"v|verbose"       => \$verbose,
	"p|pod_root=s"    => \$pod_root,
	"h|pg_doc_home=s" => \$pg_doc_home,
);

die "problem_dir, out_dir, pod_root, and pg_doc_home must be provided.\n"
	unless $problem_dir && $out_dir && $pod_root && $pg_doc_home;

my $pg_root = curfile->dirname->dirname;

my $mt              = Mojo::Template->new(vars => 1);
my $md              = Text::MultiMarkdown->new;
my $template_dir    = "$pg_root/doc/templates";
my $macro_locations = LoadFile("$pg_root/doc/sample-problems/macro_pod.yaml");

my @samples;
my @snippets;
my ($subjects, $techniques);

$pod_root .= '/pg/macros';
mkdir $out_dir unless -d $out_dir;

my $categories = {};

find({ wanted => \&processSample }, $problem_dir);
outputIndices($categories, $subjects);

# Copy the PG.js file into the output directory.
copy("$pg_root/doc/js/PG.js", $out_dir);

sub processSample {
	my $path = $File::Find::name;
	say "Processing file: $path" if $verbose;

	if ($path =~ /\.pg$/) {
		my ($filename, $filepath) = fileparse($path, qr/\.pg/);

		# Find the directory of the file relative to $problem_dir.
		my $relative_dir = ($filepath =~ s/$problem_dir\/?//r) =~ s/\/*$//r;

		my $parsed_file = parseFile($path);

		mkdir "$out_dir/$relative_dir" unless -d "$out_dir/$relative_dir";

		say "Printing to '$out_dir/$relative_dir/$filename.html'" if $verbose;
		open(my $FH, '>:encoding(UTF-8)', "$out_dir/$relative_dir/$filename.html")
			or die qq{Could not open output file "$out_dir/$relative_dir/$filename.html": $!};

		print $FH $mt->render_file("$template_dir/problem-template.mt",
			{ %$parsed_file, macro_loc => $macro_locations->{macros}, pod_dir => $pod_root, filename => $filename }
		);
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
	}

	return;
}

sub parseFile ($file) {
	open(my $FH, '<:encoding(UTF-8)', $file) or die qq{Could not open file "$file": $!};
	my @file_contents = <$FH>;
	close $FH;

	my (@blocks, @doc_rows, @code_rows, @categories, @description, @macros, @types, @subjects);
	my (%options, $descr, $type, $name);
	my @problem_types = qw/sample technique snippet/;

	while (my $row = shift @file_contents) {
		chomp($row);
		$row =~ s/\t/    /g;
		if ($row =~ /^#:%\s*(categor(y|ies)|types?|subjects?|name)\s*=\s*(.*)\s*$/) {
			# The row has the form #:% categories = [cat1, cat2, ...].
			my $label = lc($1);
			my @opts  = $3 =~ /\[(.*)\]/ ? map { $_ =~ s/^\s*|\s*$//r } split(/,/, $1) : ($3);
			if ($label =~ /types?/) {
				for my $opt (@opts) {
					die "The type of problem must be one of @problem_types"
						unless grep { lc($opt) eq $_ } @problem_types;
				}
				@types = map { lc($_) } @opts;
			} elsif ($label =~ /^catego/) {
				@categories = @opts;
			} elsif ($label =~ /^subject/) {
				@subjects = map { lc($_) } @opts;
			} elsif ($label eq 'name') {
				$name = $opts[0];
			}
		} elsif ($row =~ /^#:%\s*(.*)?/) {
			# The row has the form #:% section = NAME.
			# This should parse the previous named section and then reset @doc_rows and @code_rows.
			push(@blocks, { %options, doc => $md->markdown(join("\n", @doc_rows)), code => join("\n", @code_rows) })
				if %options;
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
			# Split by commans and pull out the quotes.
			@macros = map {s/['"]//gr} split(/\s*,\s*/, $macros =~ s/loadMacros\((.*)\)\;$/$1/r);
		} elsif ($row =~ /^#:/) {
			# This is a documentation line. Just push the row onto @doc_rows.
			$row = $row =~ s/^#://r;
			# parse any PODLINK commands in the documentation.
			if ($row =~ /PODLINK\('(.*?)'\s*(,\s*'(.*)')?\)/) {
				my $url = $pod_root . '/' . $macro_locations->{macros}{ $3 // $1 };
				$row = $row =~ s/PODLINK\('(.*?)'\s*(,\s*'(.*)')?\)/[$1]($url)/gr;
			}
			push(@doc_rows, $row);
		} elsif ($row =~ /^##\s*(END?)DESCRIPTION\s*$/) {
			$descr = $1 ? 0 : 1;
		} elsif ($row =~ /^##/ && $descr) {
			push(@description, $row =~ s/^##\s*//r);
			push(@code_rows,   $row);
		} else {
			push(@code_rows, $row);
		}
	}
	die "The type of sample problem is missing for $file"           unless scalar(@types) > 0;
	die "The name attribute must be assigned for a problem/snipped" unless $name;

	# The @doc_rows must be parsed then added to the @blocks.
	push(@blocks, { %options, doc => $md->markdown(join("\n", @doc_rows)), code => join("\n", @code_rows) });

	return {
		home        => $pg_doc_home,
		name        => $name,
		types       => \@types,
		subjects    => \@subjects,
		blocks      => \@blocks,
		categories  => \@categories,
		macros      => \@macros,
		description => join("\n", @description)
	};
}

# This produces the categories, problem techniques and snippets file.
sub outputIndices ($categories, $subjects) {
	say 'Creating categories' if $verbose;
	if (open my $FH, '>', "$out_dir/categories.html") {
		print $FH $mt->render_file(
			"$template_dir/general-layout.mt",
			{
				sidebar      => $mt->render_file("$template_dir/category-sidebar.mt", { categories => $categories }),
				main_content => $mt->render_file("$template_dir/category-main.mt",    { categories => $categories }),
				active       => 'categories'
			}
		);
		close $FH;
	}

	say 'Creating Subject Areas' if $verbose;
	if (open my $FH, '>', "$out_dir/subjects.html") {
		print $FH $mt->render_file(
			"$template_dir/general-layout.mt",
			{
				sidebar      => $mt->render_file("$template_dir/subject-sidebar.mt", { subjects => $subjects }),
				main_content => $mt->render_file("$template_dir/subject-main.mt",    { subjects => $subjects }),
				active       => 'subjects'
			}
		);
		close $FH;
	}

	say 'Creating Problem Techniques' if $verbose;
	if (open my $FH, '>', "$out_dir/techniques.html") {
		print $FH $mt->render_file(
			"$template_dir/general-layout.mt",
			{
				sidebar      => $mt->render_file("$template_dir/techniques-sidebar.mt"),
				main_content => $mt->render_file("$template_dir/techniques-main.mt", { techniques => $techniques }),
				active       => 'techniques'
			}
		);
		close $FH;
	}

	return;
}

1;
