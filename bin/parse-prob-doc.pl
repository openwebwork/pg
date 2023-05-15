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

my ($prob_dir, $out_dir, $pod_root);
my $verbose = 1;
GetOptions(
	"problem_dir=s" => \$prob_dir,
	"out_dir=s"     => \$out_dir,
	"verbose"       => \$verbose,
	"pod_root=s"    => \$pod_root
);

use Data::Dumper;

my $mt            = Mojo::Template->new(vars => 1);
my $md            = Text::MultiMarkdown->new;
my $template_dir  = curfile->dirname . '/../doc/templates';
my $prob_template = "$template_dir/prob-template.mt";
my $macro_loc     = LoadFile("$template_dir/../sample-problems/macro_pod.yaml");

$pod_root .= '/pg/macros';
mkdir $out_dir unless -d $out_dir;

my $categories = {};

# print Dumper parseFile('/opt/webwork/pg/doc/sample-problems/Algebra/AlgebraicFractionAnswer.pg');

find({ wanted => \&processSample }, $prob_dir);
outputCategoryFiles($categories);

sub processSample {
	my $path = $File::Find::name;
	say "Processing file: $path" if $verbose;

	if ($path =~ /\.pg$/) {
		my $filename = fileparse($path) if $path =~ /\.pg$/;
		# Find the directory structure inside the $prob_dir
		my ($dirs) = $path =~ m/$prob_dir\/(.*)\/$filename/;
		# print Dumper $dirs;
		# print Dumper parseFile($path);
		my $parsed_file =
			{ %{ parseFile($path) }, macro_loc => $macro_loc->{macros}, pod_dir => $pod_root, filename => $filename };

		my $sample_prob_html = $mt->render_file($prob_template, $parsed_file);
		mkdir "$out_dir/$dirs" unless -d "$out_dir/$dirs";
		say "printing to '$out_dir/$dirs/$filename.html'" if $verbose;
		open my $FH, '>', "$out_dir/$dirs/$filename.html";
		print $FH $sample_prob_html;
		close $FH;
		for my $cat (@{ $parsed_file->{categories} }) {
			$categories->{$cat} = [] unless $categories->{$cat};
			push(@{ $categories->{$cat} }, "$dirs/$filename.html");
		}
	}
}

sub parseFile ($file) {
	my @blocks;
	my @doc_rows;
	my @code_rows;
	my @categories;
	my @description;
	my @macros;
	open(my $FH, '<:encoding(UTF-8)', $file) || die "Could not open file '$file' $!";

	my %options;
	my $descr;
	while (my $row = <$FH>) {
		chomp($row) if $row;
		# If the row has the form #:% categories = [cat1,cat2,] parse as categories to add to the categories array
		if ($row =~ /^#:%\s*categories\s*=\s*\[(.*)\]\s*$/) {
			@categories = map { $_ =~ s/^\s*|\s*$//r } split(/,/, $1);
			# If the row starts with #:%, it should be a line of section=NAME.
			# TODO: throw error if not of this form?
		} elsif ($row =~ /^#:%\s*(.*)?/) {
			# this should parse the previous named section and the reset @doc_rows and @code_rows.
			push(@blocks, { %options, doc => $md->markdown(join("\n", @doc_rows)), code => join("\n", @code_rows) })
				if %options;
			%options   = split(/\s*:\s*|\s*,\s*|\s*=\s*|\s+/, $1);
			@doc_rows  = ();
			@code_rows = ();
		} elsif ($row =~ /loadMacros\(/) {
			# parse the macros, which may be on multiples rows;
			push(@code_rows, $row);
			my $macros = $row;
			while ($row !~ /\);\s*$/) {
				$row = <$FH>;
				chomp($row) if $row;
				$macros .= $row;
				push(@code_rows, $row);
			}
			# Split by commans and pull out the quotes
			@macros = map {s/['"]//gr} split(/\s*,\s*/, $macros =~ s/loadMacros\((.*)\)\;$/$1/r);
			# This is a documentation line. Just push the row onto @doc_rows
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
	close $FH;
	# The @doc_rows must be parsed then added to the @blocks.
	push(@blocks, { %options, doc => $md->markdown(join("\n", @doc_rows)), code => join("\n", @code_rows) });
	return {
		blocks      => \@blocks,
		categories  => \@categories,
		macros      => \@macros,
		description => join("\n", @description)
	};
}

# This produces the directory of files for links based on the catagories.
sub outputCategoryFiles ($categories) {
	# Create the directory structure for the HTML files
	mkdir "$out_dir/categories" unless -d "$out_dir/categories";

	my $categories_template = "$template_dir/catagory_layout.mt";
	my $cat_links           = "$template_dir/links.mt";
	my $categories_html     = $mt->render_file($categories_template, { categories => $categories, content => '' });

	say 'creating categories index' if $verbose;
	open my $FH, '>', "$out_dir/categories/index.html";
	print $FH $categories_html;
	close $FH;

	for my $cat (keys %$categories) {
		# replace spaces with underscore for filenames.
		my $filename       = $cat =~ s/\s/_/rg;
		my $link_list_html = $mt->render_file($cat_links, { cat => $cat, links => $categories->{$cat} });
		my $cat_html =
			$mt->render_file($categories_template, { categories => $categories, content => $link_list_html });
		say "creating category file $filename.html" if $verbose;
		open my $FH, '>', "$out_dir/categories/$filename.html";
		print $FH $cat_html;
		close $FH;
	}
}

1;
