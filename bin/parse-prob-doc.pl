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
use File::Basename;
use Getopt::Long;
use File::Find qw(find);
use File::Copy qw(copy);
use YAML::XS qw(LoadFile DumpFile);

use SampleProblemParser qw(renderSampleProblem buildIndex writeIndex);

my ($problem_dir, $out_dir, $pod_root, $pg_doc_home);
my ($verbose, $build_index, $generate_prob_files) = (0, 0, 0);

GetOptions(
	"d|problem_dir=s"       => \$problem_dir,
	"b|build_index"         => \$build_index,
	"g|generate_prob_files" => \$generate_prob_files,
	"o|out_dir=s"           => \$out_dir,
	"v|verbose"             => \$verbose,
	"p|pod_root=s"          => \$pod_root,
	"h|pg_doc_home=s"       => \$pg_doc_home,
);

die "problem_dir, out_dir, pod_root, and pg_doc_home must be provided.\n"
	unless $problem_dir && $out_dir && $pod_root && $pg_doc_home;

my $mt              = Mojo::Template->new(vars => 1);
my $template_dir    = "$pg_root/doc/templates";
my $macro_locations = LoadFile("$pg_root/doc/sample-problems/macro_pod.yaml");

my @samples;
my @snippets;
my ($subjects, $techniques, $categories, $macros, $index_table);

my @problem_types = qw/sample technique snippet/;

$pod_root .= '/pg/macros';
mkdir $out_dir unless -d $out_dir;

# build a hash of all PG files for linking
find(
	{
		wanted => sub {
			my $path = $File::Find::name;
			say "Reading file: $path" if $verbose;

			if ($path =~ /\.pg$/) {
				my $metadata = parseMetaData($path);
				$index_table->{ $metadata->{filename} } = $metadata;
				die "The type of sample problem is missing for $path" unless scalar(@{ $metadata->{types} }) > 0;
				die "The name attribute must be assigned for a problem/snippet" unless $metadata->{name};
			}
		}
	},
	$problem_dir
);

DumpFile("$pg_root/doc/sample-problems/sample_prob_meta.yaml", $index_table) if $build_index;

if ($generate_prob_files) {
	for (keys %$index_table) {
		renderSampleProblem(
			$_ =~ s/.pg$//r,
			metadata        => $index_table,
			macro_locations => $macro_locations,
			pod_root        => $pod_root,
			pg_doc_home     => $pg_doc_home,
			problem_dir     => $problem_dir,
			out_dir         => $out_dir,
			template_dir    => $template_dir,
			mt              => $mt,
			verbose         => $verbose
		);
	}
}

# outputIndices($categories, $subjects);
for (qw/categories subjects macros techniques/) {
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

# Copy the PG.js file and CSS file into the output directory.
copy("$pg_root/doc/js/PG.js",               $out_dir);
copy("$pg_root/doc/css/sample-problem.css", $out_dir);

sub parseMetaData ($path) {
	# Find the directory of the file relative to $problem_dir.
	my ($filename, $filepath) = fileparse($path);
	my $relative_dir = ($filepath =~ s/$problem_dir\/?//r) =~ s/\/*$//r;
	my $out          = { filename => $filename, dir => $relative_dir };
	open(my $FH, '<:encoding(UTF-8)', $path) or die qq{Could not open file "$path": $!};
	my @file_contents = <$FH>;
	close $FH;
	while (my $row = shift @file_contents) {
		if ($row =~ /^#:%\s*(categor(y|ies)|types?|subjects?|see_also|name)\s*=\s*(.*)\s*$/) {
			# The row has the form #:% categories = [cat1, cat2, ...].
			my $label = lc($1);
			my @opts  = $3 =~ /\[(.*)\]/ ? map { $_ =~ s/^\s*|\s*$//r } split(/,/, $1) : ($3);
			if ($label =~ /types?/) {
				for my $opt (@opts) {
					die "The type of problem must be one of @problem_types"
						unless grep { lc($opt) eq $_ } @problem_types;
				}
				$out->{types} = [ map { lc($_) } @opts ];
			} elsif ($label =~ /^categor/) {
				$out->{categories} = \@opts;
			} elsif ($label =~ /^subject/) {
				$out->{subjects} = [ map { lc($_) } @opts ];
			} elsif ($label eq 'name') {
				$out->{name} = $opts[0];
			} elsif ($label eq 'see_also') {
				$out->{related} = \@opts;
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
			$out->{macros} = [];
			for my $macro (@macros) {
				push(@{ $out->{macros} }, $macro) if (!grep { $_ eq $macro } @{ $macro_locations->{macros_to_skip} });
			}
		}
	}
	return $out;
}

1;
