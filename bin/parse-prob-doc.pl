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
	# Store the block names, code, document comments and full file with MD comments stripped
	my @blocks;
	my $code = {};
	my $doc  = {};
	my @full_file;

	# Store the flags for inside code and document blocks;
	my ($inside_doc, $inside_code);

	open(my $FH, '<:encoding(UTF-8)', $file) || die "Could not open file '$file' $!";
	while (my $row = <$FH>) {
		chomp($row) if $row;
		if ($row =~ /^#:(\w+):begin*$/) {
			$inside_doc  = 1;
			$inside_code = 0;
			push(@blocks, $1);
			$code->{ $blocks[$#blocks] } = [];
			$doc->{ $blocks[$#blocks] }  = [];
		} elsif ($row =~ /^\s*#:(\w+):code\s*$/) {
			die 'A :XXXX:code statement encountered before a :XXXX:begin statement' unless $inside_doc;
			die "A :$blocks[$#blocks]:code expected"                                unless $blocks[$#blocks] eq $1;
			$inside_code = 1;
			$inside_doc  = 0;
		} elsif ($row =~ /^\s*#:(\w+):end\s*$/) {
			die "Missing '$blocks[$#blocks]:end'" unless $blocks[$#blocks] eq $1;
			$inside_doc  = '';
			$inside_code = '';
		} else {
			push(@{ $code->{ $blocks[$#blocks] } }, $row)             if $inside_code;
			push(@{ $doc->{ $blocks[$#blocks] } },  $row =~ s/^#://r) if $inside_doc;
		}
		push(@full_file, $row) unless $row =~ /^#:/;
	}
	close $FH;

	for my $b (@blocks) {
		$code->{$b} = join("\n", @{ $code->{$b} });
		$doc->{$b}  = $md->markdown(join("\n", @{ $doc->{$b} }));
	}
	# print Dumper \@full_file;
	return {
		blocks => \@blocks,
		code   => $code,
		doc    => $doc
	};
}

# parseFile($ARGV[0]);

# print Dumper $mt->render_file($out_template, parseFile($ARGV[0]));

1;
