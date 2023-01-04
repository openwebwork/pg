#!/usr/bin/env perl

use Test2::V0 '!E', { E => 'EXISTS' };

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
do "$ENV{PG_ROOT}/t/build_PG_envir.pl";

loadMacros('randomNamesPronouns.pl');

my $p1 = Person->new({ name => 'Fred',      pronoun => 'he' });
my $p2 = Person->new({ name => 'Gabriella', pronoun => 'she' });
my $p3 = Person->new({ name => 'Kai',       pronoun => 'they' });

is($p1->name,              'Fred',  'Test the name method for Fred');
is($p1->pronoun,           'he',    'Test the pronoun method for Fred');
is($p1->Pronoun,           'He',    'Test the pronoun method for Fred');
is($p1->verb('find'),      'finds', 'Tests the conjugation of the verb find for Fred.');
is($p1->verb('is', 'are'), 'is',    'Tests the conjugation of the verb is for Fred.');

is($p2->name,              'Gabriella', 'Test the name method for Gabriella');
is($p2->pronoun,           'she',       'Test the pronoun method for Gabriella');
is($p2->Pronoun,           'She',       'Test the pronoun method for Gabriella');
is($p2->verb('find'),      'finds',     'Tests the conjugation of the verb find for Gabriella.');
is($p2->verb('is', 'are'), 'is',        'Tests the conjugation of the verb is for Gabriella.');

is($p3->name,              'Kai',  'Test the name method for Kai');
is($p3->pronoun,           'they', 'Test the pronoun method for Kai');
is($p3->Pronoun,           'They', 'Test the pronoun method for Kai');
is($p3->verb('find'),      'find', 'Tests the conjugation of the verb find for Kai.');
is($p3->verb('is', 'are'), 'are',  'Tests the conjugation of the verb is for Kai.');

my $rando = randomPerson();
is(ref $rando, 'Person', 'Check that the randomPerson method returns an object of Person class');

like(
		dies { Person->new({ name => 'Head', pronoun => 'xxx'}) },
		qr/The pronoun must be/,
		"An invalid pronoun is passed in."
	);

done_testing;
