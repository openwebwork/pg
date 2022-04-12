#!/usr/bin/env perl

use strict;
use warnings;

my $pg_dir;

BEGIN {
	$pg_dir = $ENV{PG_ROOT};
	die "The pg directory must be defined in PG_ROOT" unless (-e $pg_dir);
}

use lib "$pg_dir/lib";

use PGEnvironment;
use Data::Dumper;
use Renderer::Localize;

# my $lh = Renderer::Localize->get_handle('en');


my $pg_env = PGEnvironment->new(course_name => "staab_course");
my $lh = $pg_env->{environment}->{language_handle};
my $mt =  Renderer::Localize::getLoc('fr');

print Dumper $mt;


print Dumper &$mt('Solution:');
print Dumper &$mt('All students in course');
print Dumper &$mt('Fred:');

 # Depending on the user's locale, etc., this will
 # make a language handle from among the classes available,
 # and any defaults that you declare.
# die "Couldn't make a language handle??" unless $lh;