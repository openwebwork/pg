#!/usr/bin/env perl

=head1 NAME

generate-pg-pod.pl - Convert PG POD into HTML form.

=head1 SYNOPSIS

generate-pg-pod.pl [options]

 Options:
   -o|--output-dir       Directory to save the output files to. (required)
   -b|--base-url         Base url location used on server. (default: /)
                         This is needed for internal POD links to work correctly.
   -h|--home-url         Home page url on the server. (default: /)
   -v|--verbose          Increase the verbosity of the output.
                         (Use multiple times for more verbosity.)

=head1 DESCRIPTION

Convert PG POD into HTML form.

=cut

use strict;
use warnings;

use Getopt::Long qw(:config bundling);
use Pod::Usage;

my ($output_dir, $base_url, $home_url);
my $verbose = 0;
GetOptions(
	'o|output-dir=s' => \$output_dir,
	'b|base-url=s'   => \$base_url,
	'h|home-url=s'   => \$home_url,
	'v|verbose+'     => \$verbose
);

pod2usage(2) unless $output_dir;

$base_url = "/" if !$base_url;
$home_url = "/" if !$home_url;

use Mojo::Template;
use IO::File;
use File::Copy;
use File::Path     qw(make_path remove_tree);
use File::Basename qw(dirname);
use Cwd            qw(abs_path);

use lib abs_path(dirname(dirname(__FILE__))) . '/lib';

use WeBWorK::Utils::PODtoHTML;

my $pg_root = abs_path(dirname(dirname(__FILE__)));

print "Reading: $pg_root\n" if $verbose;

remove_tree($output_dir);
make_path($output_dir);

my $htmldocs = WeBWorK::Utils::PODtoHTML->new(
	source_root        => $pg_root,
	dest_root          => $output_dir,
	template_dir       => "$pg_root/assets/pod-templates",
	dest_url           => $base_url,
	home_url           => $home_url,
	home_url_link_name => 'PG Documentation Home',
	verbose            => $verbose
);
$htmldocs->convert_pods;

make_path("$output_dir/assets");
copy("$pg_root/htdocs/js/PODViewer/podviewer.css", "$output_dir/assets/podviewer.css");
print "copying $pg_root/htdocs/js/PODViewer/podviewer.css to $output_dir/assets/podviewer.css\n" if $verbose;
copy("$pg_root/htdocs/js/PODViewer/podviewer.js", "$output_dir/assets/podviewer.js");
print "copying $pg_root/htdocs/js/PODViewer/podviewer.css to $output_dir/assets/podviewer.js\n" if $verbose;

1;
