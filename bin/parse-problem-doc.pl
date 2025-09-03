#!/usr/bin/env perl

=head1 NAME

parse-problem-doc.pl - Parse sample problem documentation.

=head1 SYNOPSIS

parse-problem-doc.pl [options]

 Options:
   -d|--problem-dir      Directory containing sample problems to be parsed.
                         This defaults to the tutorial/sample-problems directory
                         in the PG root directory if not given.
   -o|--out-dir          Directory to save the output files to. (required)
   -p|--pod-base-url     Base URL location for POD on server. (required)
   -s|--sample-problem-base-url
                         Base URL location for sample problems on server. (required)
   -v|--verbose          Give verbose feedback.

=head1 DESCRIPTION

Parse sample problem documentation.

=cut

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
use File::Basename qw(basename);
use Getopt::Long;
use Pod::Usage;
use File::Copy qw(copy);
use Pod::Simple::Search;

use WeBWorK::PG::SampleProblemParser qw(parseSampleProblem generateMetadata);

my $problem_dir = "$pg_root/tutorial/sample-problems";

my ($out_dir, $pod_base_url, $sample_problem_base_url);
my $verbose = 0;

GetOptions(
	"d|problem-dir=s"             => \$problem_dir,
	"o|out-dir=s"                 => \$out_dir,
	"p|pod-base-url=s"            => \$pod_base_url,
	"s|sample-problem-base-url=s" => \$sample_problem_base_url,
	"v|verbose"                   => \$verbose
);

pod2usage(2) unless $out_dir && $pod_base_url && $sample_problem_base_url;

my $mt           = Mojo::Template->new(vars => 1);
my $template_dir = "$pg_root/tutorial/templates";

(undef, my $macro_files) = Pod::Simple::Search->new->inc(0)->survey("$pg_root/macros");
my $macro_locations = { map { basename($_) => ($_ =~ s!$pg_root/macros/!!r) =~ s/\.pl/.html/r } keys %$macro_files };

my @problem_types = qw(sample technique snippet);

$pod_base_url .= '/macros';
mkdir $out_dir unless -d $out_dir;

# Build a hash of all PG files for linking.
my $index_table = generateMetadata($problem_dir, macro_locations => $macro_locations, verbose => $verbose);

for (keys %$index_table) {
	renderSampleProblem(
		$_ =~ s/.pg$//r,
		metadata                => $index_table,
		macro_locations         => $macro_locations,
		pod_base_url            => $pod_base_url,
		sample_problem_base_url => $sample_problem_base_url,
		url_extension           => '.html',
		problem_dir             => $problem_dir,
		out_dir                 => $out_dir,
		template_dir            => $template_dir,
		mt                      => $mt,
		verbose                 => $verbose
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

# Output index files.
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

# Copy the CSS file into the output directory.
copy("$pg_root/tutorial/css/sample-problem.css", $out_dir);

1;
