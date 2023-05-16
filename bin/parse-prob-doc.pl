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
use YAML::XS qw(LoadFile);

my ($problem_dir, $out_dir, $pod_root);
my $verbose = 0;

GetOptions(
	"d|problem_dir=s" => \$problem_dir,
	"o|out_dir=s"     => \$out_dir,
	"v|verbose"       => \$verbose,
	"p|pod_root=s"    => \$pod_root
);

die "problem_dir, out_dir, and pod_root must be provided.\n" unless $problem_dir && $out_dir && $pod_root;

my $pg_root = curfile->dirname->dirname;

my $mt              = Mojo::Template->new(vars => 1);
my $md              = Text::MultiMarkdown->new;
my $template_dir    = "$pg_root/doc/templates";
my $macro_locations = LoadFile("$pg_root/doc/sample-problems/macro_pod.yaml");

$pod_root .= '/pg/macros';
mkdir $out_dir unless -d $out_dir;

my $categories = {};

find({ wanted => \&processSample }, $problem_dir);
outputIndex($categories);

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
		open(my $FH, '>', "$out_dir/$relative_dir/$filename.html")
			or die qq{Could not open output file "$out_dir/$relative_dir/$filename.html": $!};
		print $FH $mt->render_file("$template_dir/problem-template.mt",
			{ %$parsed_file, macro_loc => $macro_locations->{macros}, pod_dir => $pod_root, filename => $filename }
		);
		close $FH;

		for my $category (@{ $parsed_file->{categories} }) {
			push(@{ $categories->{$category} }, "$relative_dir/$filename.html");
		}
	}

	return;
}

sub parseFile ($file) {
	open(my $FH, '<:encoding(UTF-8)', $file) or die qq{Could not open file "$file": $!};
	my @file_contents = <$FH>;
	close $FH;

	my (@blocks, @doc_rows, @code_rows, @categories, @description, @macros);
	my (%options, $descr);

	while (my $row = shift @file_contents) {
		chomp($row);
		# If the row has the form #:% categories = [cat1,cat2,] parse as categories to add to the categories array.
		if ($row =~ /^#:%\s*categories\s*=\s*\[(.*)\]\s*$/) {
			@categories = map { $_ =~ s/^\s*|\s*$//r } split(/,/, $1);
			# If the row starts with #:%, it should be a line of section=NAME.
			# TODO: throw error if not of this form?
		} elsif ($row =~ /^#:%\s*(.*)?/) {
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
				$macros .= $row;
				push(@code_rows, $row);
			}
			# Split by commans and pull out the quotes.
			@macros = map {s/['"]//gr} split(/\s*,\s*/, $macros =~ s/loadMacros\((.*)\)\;$/$1/r);
			# This is a documentation line. Just push the row onto @doc_rows.
		} elsif ($row =~ /^#:/) {
			push(@doc_rows, $row =~ s/^#://r);
		} elsif ($row =~ /^##\s*(\w*)DESCRIPTION\s*$/) {
			$descr = $1 ? 0 : 1;
		} elsif ($row =~ /^##/ && $descr) {
			push(@description, $row =~ s/^##\s*//r);
			push(@code_rows,   $row);
		} else {
			push(@code_rows, $row);
		}
	}

	# The @doc_rows must be parsed then added to the @blocks.
	push(@blocks, { %options, doc => $md->markdown(join("\n", @doc_rows)), code => join("\n", @code_rows) });

	return {
		blocks      => \@blocks,
		categories  => \@categories,
		macros      => \@macros,
		description => join("\n", @description)
	};
}

# This produces the index file.
sub outputIndex ($categories) {
	say 'Creating index' if $verbose;
	open my $FH, '>', "$out_dir/index.html";
	print $FH $mt->render_file("$template_dir/category-layout.mt", { categories => $categories });
	close $FH;

	return;
}

1;
