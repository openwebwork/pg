#!/usr/bin/env perl

use strict;
use warnings;
use experimental 'signatures';
use feature 'say';

my $pg_root;

BEGIN {
	use Mojo::File qw(curfile);
	$pg_root = curfile->dirname->dirname;
}

use lib "$pg_root/lib";

use Mojo::Template;
use File::Basename qw(fileparse basename);
use Getopt::Long;
use File::Copy qw(copy);
use YAML::XS qw(DumpFile);
use Pod::Simple::Search;

use SampleProblemParser qw(parseSampleProblem generateMetadata);

my $problem_dir = "$pg_root/doc/sample-problems";

my ($out_dir, $pod_root, $pg_doc_home);
my $verbose = 0;

GetOptions(
	"d|problem_dir=s" => \$problem_dir,
	"o|out_dir=s"     => \$out_dir,
	"v|verbose"       => \$verbose,
	"p|pod_root=s"    => \$pod_root,
	"h|pg_doc_home=s" => \$pg_doc_home,
);

die "out_dir, pod_root, and pg_doc_home must be provided.\n"
	unless $out_dir && $pod_root && $pg_doc_home;

my $mt           = Mojo::Template->new(vars => 1);
my $template_dir = "$pg_root/doc/templates";

(undef, my $macro_files) = Pod::Simple::Search->new->inc(0)->survey("$pg_root/macros");
my $macro_locations = { map { basename($_) => ($_ =~ s!$pg_root/macros/!!r) =~ s/\.pl/.html/r } keys %$macro_files };

my @problem_types = qw(sample technique snippet);

$pod_root .= '/pg/macros';
mkdir $out_dir unless -d $out_dir;

# Build a hash of all PG files for linking.
my $index_table = generateMetadata($problem_dir, macro_locations => $macro_locations, verbose => $verbose);

for (keys %$index_table) {
	renderSampleProblem(
		$_ =~ s/.pg$//r,
		metadata        => $index_table,
		macro_locations => $macro_locations,
		pod_root        => $pod_root,
		pg_doc_home     => $pg_doc_home,
		url_extension   => '.html',
		problem_dir     => $problem_dir,
		out_dir         => $out_dir,
		template_dir    => $template_dir,
		mt              => $mt,
		verbose         => $verbose
	);
}

sub renderSampleProblem ($filename, %global) {
	my $relative_dir = $global{metadata}{"$filename.pg"}{dir};
	my $path         = "$global{problem_dir}/$relative_dir/$filename.pg";
	say "Processing file: $path" if $global{verbose};
	my $parsed_file = parseSampleProblem($path, %global);

	mkdir "$global{out_dir}/$relative_dir" unless -d "$global{out_dir}/$relative_dir";

	say "Printing to '$global{out_dir}/$relative_dir/$filename.html'" if $global{verbose};
	open(my $html_fh, '>:encoding(UTF-8)', "$global{out_dir}/$relative_dir/$filename.html")
		or die qq{Could not open output file "$global{out_dir}/$relative_dir/$filename.html": $!};
	print $html_fh $global{mt}->render_file("$global{template_dir}/problem-template.mt",
		{ %$parsed_file, %global, filename => "$filename.pg" });
	close $html_fh;

	# Write the code to a separate file
	open(my $pg_fh, '>:encoding(UTF-8)', "$global{out_dir}/$relative_dir/$filename.pg")
		or die qq{Could not open output file "$global{out_dir}/$relative_dir/$filename.pg": $!};
	print $pg_fh $parsed_file->{code};
	close $pg_fh;
	say "Printing pg file to '$global{out_dir}/$relative_dir/$filename.pg'" if $global{verbose};
	return;
}

# Ouput index files.
for (qw(categories subjects macros techniques)) {
	my $options = {
		metadata     => $index_table,
		template_dir => $template_dir,
		out_dir      => $out_dir,
		mt           => $mt,
		verbose      => $verbose,
	};
	my $params = buildIndex($_, %$options);
	writeIndex($params, %$options);
}

sub buildIndex ($type, %options) {
	my %labels = (
		categories => 'Categories',
		subjects   => 'Subject Areas',
		macros     => 'Problems by Macro',
		techniques => 'Problem Techniques'
	);

	my $list = {};
	if ($type =~ /^(categories|subjects|macros)$/) {
		for my $sample_file (keys %{ $options{metadata} }) {
			for my $category (@{ $options{metadata}{$sample_file}{$type} }) {
				$list->{$category}{ $options{metadata}{$sample_file}{name} } =
					"$options{metadata}{$sample_file}{dir}/" . ($sample_file =~ s/\.pg$/.html/r);
			}
		}
	} elsif ($type eq 'techniques') {
		for my $sample_file (keys %{ $options{metadata} }) {
			if (grep { $_ eq 'technique' } @{ $options{metadata}{$sample_file}{types} }) {
				$list->{ $options{metadata}{$sample_file}{name} } =
					"$options{metadata}{$sample_file}{dir}/" . ($sample_file =~ s/\.pg$/.html/r);
			}
		}
	}

	return {
		label  => $labels{$type},
		list   => $list,
		type   => $type,
		output => "$options{out_dir}/$type.html"
	};
}

sub writeIndex ($params, %options) {
	say "Creating $params->{label} index" if $options{verbose};
	if (open my $FH, '>:encoding(UTF-8)', $params->{output}) {
		print $FH $options{mt}->render_file(
			"$options{template_dir}/general-layout.mt",
			{
				sidebar      => $options{mt}->render_file("$options{template_dir}/general-sidebar.mt", $params),
				main_content => $options{mt}->render_file("$options{template_dir}/general-main.mt",    $params),
				active       => $params->{type}
			}
		);
		close $FH;
	}
	return;
}

# Copy the PG.js file and CSS file into the output directory.
copy("$pg_root/doc/js/PG.js",               $out_dir);
copy("$pg_root/doc/css/sample-problem.css", $out_dir);

1;
