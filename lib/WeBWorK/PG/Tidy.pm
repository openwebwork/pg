################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2024 The WeBWorK Project, https://github.com/openwebwork
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

=head1 NAME

WeBWorK::PG::Tidy -- perltidy pg problem files.

=head1 DESCRIPTION

perltidy pg problem files.

=head1 OPTIONS

This module is a wrapper around Perl::Tidy and just calls C<Perl::Tidy::perltidy>.
Any options passed on the command line are passed to Perl::Tidy::perltidy See
the L<Perl::Tidy::perltidy> documentation for details.

Note that if the C<-pro=file> option is not given, then this module will attempt
to use the perltidy-pg.rc file in the PG bin directory for this option.  For
this to work the perltidy-pg.rc file in the PG bin directory must be readable.

=cut

package WeBWorK::PG::Tidy;
use parent qw(Exporter);

use strict;
use warnings;

use Perl::Tidy;
use Mojo::File qw(curfile);

our @EXPORT = qw(pgtidy);

my $perltidy_pg_rc = curfile->dirname->dirname->dirname->dirname . '/bin/perltidy-pg.rc';

# Apply the same preprocessing as the PG Translator, except for the removal of everything after ENDDOCUMENT.
my $prefilter = sub {
	my $evalString = shift // '';

	$evalString =~ s/\n\h*END_TEXT[\h;]*\n/\nEND_TEXT\n/g;
	$evalString =~ s/\n\h*END_PGML[\h;]*\n/\nEND_PGML\n/g;
	$evalString =~ s/\n\h*END_PGML_SOLUTION[\h;]*\n/\nEND_PGML_SOLUTION\n/g;
	$evalString =~ s/\n\h*END_PGML_HINT[\h;]*\n/\nEND_PGML_HINT\n/g;
	$evalString =~ s/\n\h*END_SOLUTION[\h;]*\n/\nEND_SOLUTION\n/g;
	$evalString =~ s/\n\h*END_HINT[\h;]*\n/\nEND_HINT\n/g;
	$evalString =~ s/\n\h*BEGIN_TEXT[\h;]*\n/\nSTATEMENT\(EV3P\(<<'END_TEXT'\)\);\n/g;
	$evalString =~ s/\n\h*BEGIN_PGML[\h;]*\n/\nSTATEMENT\(PGML::Format2\(<<'END_PGML'\)\);\n/g;
	$evalString =~ s/\n\h*BEGIN_PGML_SOLUTION[\h;]*\n/\nSOLUTION\(PGML::Format2\(<<'END_PGML_SOLUTION'\)\);\n/g;
	$evalString =~ s/\n\h*BEGIN_PGML_HINT[\h;]*\n/\nHINT\(PGML::Format2\(<<'END_PGML_HINT'\)\);\n/g;
	$evalString =~ s/\n\h*BEGIN_SOLUTION[\h;]*\n/\nSOLUTION\(EV3P\(<<'END_SOLUTION'\)\);\n/g;
	$evalString =~ s/\n\h*BEGIN_HINT[\h;]*\n/\nHINT\(EV3P\(<<'END_HINT'\)\);\n/g;
	$evalString =~ s/\n\h*(.*)\h*->\h*BEGIN_TIKZ[\h;]*\n/\n$1->tex\(<<END_TIKZ\);\n/g;
	$evalString =~ s/\n\h*END_TIKZ[\h;]*\n/\nEND_TIKZ\n/g;
	$evalString =~ s/\n\h*(.*)\h*->\h*BEGIN_LATEX_IMAGE[\h;]*\n/\n$1->tex\(<<END_LATEX_IMAGE\);\n/g;
	$evalString =~ s/\n\h*END_LATEX_IMAGE[\h;]*\n/\nEND_LATEX_IMAGE\n/g;

	$evalString =~ s/\\/\\\\/g;
	$evalString =~ s/~~/\\/g;

	return $evalString;
};

# Reverse the above preprocessing after perltidy is run.  This does not reverse the clean up of
# horizontal whitespace and semicolons done in the preprocessing stage.
my $postfilter = sub {
	my $evalString = shift // '';

	$evalString =~ s/\h*STATEMENT\(EV3P\(<<'END_TEXT'\)\);/BEGIN_TEXT/g;
	$evalString =~ s/\h*STATEMENT\(PGML::Format2\(<<'END_PGML'\)\);/BEGIN_PGML/g;
	$evalString =~ s/\h*SOLUTION\(PGML::Format2\(<<'END_PGML_SOLUTION'\)\);/BEGIN_PGML_SOLUTION/g;
	$evalString =~ s/\h*HINT\(PGML::Format2\(<<'END_PGML_HINT'\)\);/BEGIN_PGML_HINT/g;
	$evalString =~ s/\h*SOLUTION\(EV3P\(<<'END_SOLUTION'\)\);/BEGIN_SOLUTION/g;
	$evalString =~ s/\h*HINT\(EV3P\(<<'END_HINT'\)\);/BEGIN_HINT/g;
	$evalString =~ s/(.*)->tex\(<<END_TIKZ\);/$1->BEGIN_TIKZ/g;
	$evalString =~ s/(.*)->tex\(<<END_LATEX_IMAGE\);/$1->BEGIN_LATEX_IMAGE/g;

	# Care is needed to reverse the preprocessing here.
	# First in all occurences of an odd number of backslashes the first backslash is replaced with two tildes.
	$evalString =~ s/(?<!\\) \\ ((?:\\{2})*) (?!\\)/~~$1/gx;
	# Then all pairs of backslashes are replaced with a single backslash.
	$evalString =~ s/\\\\/\\/g;

	return $evalString;
};

sub pgtidy {
	my %options = @_;

	local @ARGV = @ARGV;

	# Get the options that were passed.  If the profile option was not set, then set it to be the
	# perltidy-pg.rc file in the root pg directory.
	Perl::Tidy::perltidy(dump_options => \my %internal_options);
	unshift(@ARGV, "-pro=$perltidy_pg_rc") if !defined $internal_options{profile} && -r $perltidy_pg_rc;

	return Perl::Tidy::perltidy(prefilter => $prefilter, postfilter => $postfilter, %options);
}

1;
