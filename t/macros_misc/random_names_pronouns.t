#!/usr/bin/env perl

use Test2::V0 '!E', { E => 'EXISTS' };

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
do "$ENV{PG_ROOT}/t/build_PG_envir.pl";

loadMacros('randomNamesPronouns.pl');

my $p1 = Person->new(name => 'Fred',      pronoun => 'he');
my $p2 = Person->new(name => 'Gabriella', pronoun => 'she');
my $p3 = Person->new(name => 'Kai',       pronoun => 'they');

subtest 'Tests for he pronouns' => sub {

	is($p1->name,              'Fred',  'Test the name method for Fred');
	is($p1->subject,           'he',    'Test the pronoun method for Fred');
	is($p1->Subject,           'He',    'Test the capital pronoun method for Fred');
	is($p1->possessive,        'his',   'Test for the possessive adjective for Fred');
	is($p1->Possessive,        'His',   'Test for the capital possessive adjective for Fred');
	is($p1->possession,        'his',   'Test for the possessive pronoun for Fred');
	is($p1->Possession,        'His',   'Test for the capital possessive pronoun for Fred');
	is($p1->object,            'him',   'Test for the object pronoun for Fred');
	is($p1->Object,            'Him',   'Test for the capital object pronoun for Fred');
	is($p1->verb('find'),      'finds', 'Tests the conjugation of the verb find for Fred.');
	is($p1->verb('is', 'are'), 'is',    'Tests the conjugation of the verb is for Fred.');
};

subtest 'Tests for she pronouns' => sub {
	is($p2->name,              'Gabriella', 'Test the name method for Gabriella');
	is($p2->subject,           'she',       'Test the pronoun method for Gabriella');
	is($p2->Subject,           'She',       'Test the pronoun method for Gabriella');
	is($p2->possessive,        'her',       'Test for the possessive adjective for Gabriella');
	is($p2->Possessive,        'Her',       'Test for the capital possessive adjective for Gabriella');
	is($p2->possession,        'hers',      'Test for the possessive pronoun for Gabriella');
	is($p2->Possession,        'Hers',      'Test for the capital possessive pronoun for Gabriella');
	is($p2->object,            'her',       'Test for the object pronoun for Gabriella');
	is($p2->Object,            'Her',       'Test for the capital object pronoun for Gabriella');
	is($p2->verb('find'),      'finds',     'Tests the conjugation of the verb find for Gabriella.');
	is($p2->verb('is', 'are'), 'is',        'Tests the conjugation of the verb is for Gabriella.');
};

subtest 'Tests for they pronouns' => sub {
	is($p3->name,       'Kai',    'Test the name method for Kai');
	is($p3->subject,    'they',   'Test the pronoun method for Kai');
	is($p3->Subject,    'They',   'Test the pronoun method for Kai');
	is($p3->possessive, 'their',  'Test for the possessive adjective for Kai');
	is($p3->Possessive, 'Their',  'Test for the capital possessive adjective for Kai');
	is($p3->possession, 'theirs', 'Test for the possessive pronoun for Kai');
	is($p3->Possession, 'Theirs', 'Test for the capital possessive pronoun for Kai');
	is($p3->object,     'them',   'Test for the object pronoun for Kai');
	is($p3->Object,     'Them',   'Test for the capital object pronoun for Kai');

	is($p3->verb('find'),      'find', 'Tests the conjugation of the verb find for Kai.');
	is($p3->verb('is', 'are'), 'are',  'Tests the conjugation of the verb is for Kai.');
};

use Data::Dumper;
subtest 'Other person tests' => sub {
	my $rando = randomPerson();
	is ref $rando, 'Person', 'Check that the randomPerson method returns an object of Person class';

	like
		dies { Person->new(name => 'Head', pronoun => 'xxx') },
		qr/The pronoun must be/,
		"An invalid pronoun is passed in.";

	my $last_name = randomLastName();
	like $last_name, qr/^[a-zA-Z]+$/, 'last name contains only letters';

	my @last_names = randomLastName(n => 5);
	is scalar(@last_names), 5, 'generate 5 last names';

	my %tmp;
	$tmp{ $last_names[$_] } = $last_names[$_] for (0 .. scalar(@last_names - 1));
	is scalar(keys(%tmp)), 5, 'check that the last names are unique.';
};

subtest 'Test options for randomPerson' => sub {
	my @persons = randomPerson(n => 5);
	is scalar(@persons), 5, 'check that the option for number of names works';
	my %tmp;
	$tmp{ $persons[$_]->name } = $persons[$_]->name for (0 .. (scalar(@persons) - 1));
	is scalar(keys(%tmp)), 5, 'check that the names are unique';

	my ($a, $b, $c) = randomPerson(names => [ [ 'Bart', 'he' ], [ 'Lisa', 'she' ], [ 'Matty', 'they' ] ]);
	is $a->name,    'Bart',   'Specifying the names of a random person';
	is $a->subject, 'he',     'Specifying the pronoun of a random person';
	is ref $a,      'Person', 'The random person is a Person object.';

	is $b->name,    'Lisa',   'Specifying the names of a random person';
	is $b->subject, 'she',    'Specifying the pronoun of a random person';
	is ref $b,      'Person', 'The random person is a Person object.';

	is $c->name,    'Matty',  'Specifying the names of a random person';
	is $c->subject, 'they',   'Specifying the pronoun of a random person';
	is ref $c,      'Person', 'The random person is a Person object.';

	my ($p1, $p2, $p3) = randomPerson(names => [ 'Larry', 'Moe', 'Curly' ]);
	is ref $p1,   'Person', 'The random person is a Person object.';
	is $p1->name, 'Larry',  'Specifying the name of a random person';
	like $p1->subject, qr/she|he|they/, 'Making sure the pronoun is set.';
};

done_testing;
