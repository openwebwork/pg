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

my $prob_dir = '';
my $out_dir  = '';
my $verbose  = 1;
my $recursive;
GetOptions(
	"problem_dir=s" => \$prob_dir,
	"out_dir=s"     => \$out_dir,
	'recursive'     => \$recursive,
	"verbose"       => \$verbose
);

use Data::Dumper;

my $mt           = Mojo::Template->new(vars => 1);
my $md           = Text::MultiMarkdown->new;
my $out_template = curfile->dirname . '/prob-template.mt';

while (my $file = glob("$prob_dir/*.pg")) {
	my ($filename, $dir) = fileparse($file);
	say "Reading file $file" if $verbose;
	my $sample_prob_html = $mt->render_file($out_template, parseFile($file));
	say "printing to '$out_dir/$filename.html'" if $verbose;
	open my $FH, '>', "$out_dir/$filename.html";
	print $FH $sample_prob_html;
	close $FH;
}

sub parseFile ($file) {
	my @blocks;
	my @doc_rows;
	my @code_rows;

	open(my $FH, '<:encoding(UTF-8)', $file) || die "Could not open file '$file' $!";

	my %options;
	while (my $row = <$FH>) {
		chomp($row) if $row;
		if ($row =~ /^#:%(\w+)\s*(.*)?/) {
			push(@blocks, { %options, doc => $md->markdown(join("\n", @doc_rows)), code => join("\n", @code_rows) })
				if %options;
			%options       = split(/\s*:\s*|\s*,\s*|\s*=\s*|\s+/, $2);
			$options{name} = $1;
			@doc_rows      = ();
			@code_rows     = ();
		} elsif ($row =~ /^#:/) {
			push(@doc_rows, $row =~ s/^#://r);
		} else {
			push(@code_rows, $row);
		}
	}
	close $FH;
	push(@blocks, { %options, doc => $md->markdown(join("\n", @doc_rows)), code => join("\n", @code_rows) });
	return { blocks => \@blocks };
}

1;
