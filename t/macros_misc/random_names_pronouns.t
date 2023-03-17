#!/usr/bin/env perl

use Test2::V0 '!E', { E => 'EXISTS' };

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
do "$ENV{PG_ROOT}/t/build_PG_envir.pl";

loadMacros('randomNamesPronouns.pl');

my $p1 = Person->new({ name => 'Fred',      pronoun => 'he' });
my $p2 = Person->new({ name => 'Gabriella', pronoun => 'she' });
my $p3 = Person->new({ name => 'Kai',       pronoun => 'they' });

subtest 'Tests for he pronouns' => sub {

	is($p1->name,              'Fred',  'Test the name method for Fred');
	is($p1->pronoun,           'he',    'Test the pronoun method for Fred');
	is($p1->Pronoun,           'He',    'Test the capital pronoun method for Fred');
	is($p1->poss_adj,          'his',   'Test for the possessive adjective for Fred');
	is($p1->Poss_adj,          'His',   'Test for the capital possessive adjective for Fred');
	is($p1->poss_pronoun,      'his',   'Test for the possessive pronoun for Fred');
	is($p1->Poss_pronoun,      'His',   'Test for the capital possessive pronoun for Fred');
	is($p1->obj_pronoun,       'him',   'Test for the object pronoun for Fred');
	is($p1->Obj_pronoun,       'Him',   'Test for the capital object pronoun for Fred');
	is($p1->verb('find'),      'finds', 'Tests the conjugation of the verb find for Fred.');
	is($p1->verb('is', 'are'), 'is',    'Tests the conjugation of the verb is for Fred.');
};

subtest 'Tests for she pronouns' => sub {
	is($p2->name,              'Gabriella', 'Test the name method for Gabriella');
	is($p2->pronoun,           'she',       'Test the pronoun method for Gabriella');
	is($p2->Pronoun,           'She',       'Test the pronoun method for Gabriella');
	is($p2->poss_adj,          'her',       'Test for the possessive adjective for Gabriella');
	is($p2->Poss_adj,          'Her',       'Test for the capital possessive adjective for Gabriella');
	is($p2->poss_pronoun,      'hers',      'Test for the possessive pronoun for Gabriella');
	is($p2->Poss_pronoun,      'Hers',      'Test for the capital possessive pronoun for Gabriella');
	is($p2->obj_pronoun,       'her',       'Test for the object pronoun for Gabriella');
	is($p2->Obj_pronoun,       'Her',       'Test for the capital object pronoun for Gabriella');
	is($p2->verb('find'),      'finds',     'Tests the conjugation of the verb find for Gabriella.');
	is($p2->verb('is', 'are'), 'is',        'Tests the conjugation of the verb is for Gabriella.');
};

subtest 'Tests for they pronouns' => sub {
	is($p3->name,         'Kai',    'Test the name method for Kai');
	is($p3->pronoun,      'they',   'Test the pronoun method for Kai');
	is($p3->Pronoun,      'They',   'Test the pronoun method for Kai');
	is($p3->poss_adj,     'their',  'Test for the possessive adjective for Kai');
	is($p3->Poss_adj,     'Their',  'Test for the capital possessive adjective for Kai');
	is($p3->poss_pronoun, 'theirs', 'Test for the possessive pronoun for Kai');
	is($p3->Poss_pronoun, 'Theirs', 'Test for the capital possessive pronoun for Kai');
	is($p3->obj_pronoun,  'them',   'Test for the object pronoun for Kai');
	is($p3->Obj_pronoun,  'Them',   'Test for the capital object pronoun for Kai');

	is($p3->verb('find'),      'find', 'Tests the conjugation of the verb find for Kai.');
	is($p3->verb('is', 'are'), 'are',  'Tests the conjugation of the verb is for Kai.');
};

subtest 'Other person tests' => sub {
	my $rando = randomPerson();
	is(ref $rando, 'Person', 'Check that the randomPerson method returns an object of Person class');

	like(
		dies { Person->new({ name => 'Head', pronoun => 'xxx' }) },
		qr/The pronoun must be/,
		"An invalid pronoun is passed in."
	);

	my $last_name = randomLastName();
	like $last_name, qr/^[a-zA-Z]+$/, 'last name contains only letters';
};

done_testing;
