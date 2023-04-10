#!/usr/bin/env perl

use Test2::V0 '!E', { E => 'EXISTS' };

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
do "$ENV{PG_ROOT}/t/build_PG_envir.pl";

loadMacros('randomNamesPronouns.pl');

my $p1 = Person->new(name => 'Fred',      pronoun => 'he');
my $p2 = Person->new(name => 'Gabriella', pronoun => 'she');
my $p3 = Person->new(name => 'Kai',       pronoun => 'they');

subtest 'Tests for he pronouns' => sub {
	is $p1->name,                 'Fred',    'Test the name method for Fred';
	is $p1->subject,              'he',      'Test the pronoun method for Fred';
	is $p1->Subject,              'He',      'Test the capital pronoun method for Fred';
	is $p1->possessive,           'his',     'Test for the possessive adjective for Fred';
	is $p1->Possessive,           'His',     'Test for the capital possessive adjective for Fred';
	is $p1->possession,           'his',     'Test for the possessive pronoun for Fred';
	is $p1->Possession,           'His',     'Test for the capital possessive pronoun for Fred';
	is $p1->object,               'him',     'Test for the object pronoun for Fred';
	is $p1->Object,               'Him',     'Test for the capital object pronoun for Fred';
	is $p1->verb('find'),         'finds',   'Tests the conjugation of the verb to find for Fred.';
	is $p1->verb('kiss'),         'kisses',  'Tests the conjugation of the verb to kiss for Fred';
	is $p1->verb('touch'),        'touches', 'Tests the conjugation of the verb to touch for Fred';
	is $p1->verb('fly', 'flies'), 'flies',   'Tests the conjugation of the verb to fly for Fred.';
	is $p1->dodoes,               'does',    'Tests the conjugation of the verb to do for Fred';
	is $p1->areis,                'is',      'Tests the conjugation of the verb to do for Fred';
	is $p1->gogoes,               'goes',    'Tests the conjugation of the verb to do for Fred';
	is $p1->havehas,              'has',     'Tests the conjugation of the verb to do for Fred';
};

subtest 'Tests for she pronouns' => sub {
	is $p2->name,                 'Gabriella', 'Test the name method for Gabriella';
	is $p2->subject,              'she',       'Test the pronoun method for Gabriella';
	is $p2->Subject,              'She',       'Test the capital pronoun method for Gabriella';
	is $p2->possessive,           'her',       'Test for the possessive adjective for Gabriella';
	is $p2->Possessive,           'Her',       'Test for the capital possessive adjective for Gabriella';
	is $p2->possession,           'hers',      'Test for the possessive pronoun for Gabriella';
	is $p2->Possession,           'Hers',      'Test for the capital possessive pronoun for Gabriella';
	is $p2->object,               'her',       'Test for the object pronoun for Gabriella';
	is $p2->Object,               'Her',       'Test for the capital object pronoun for Gabriella';
	is $p2->verb('find'),         'finds',     'Tests the conjugation of the verb to find for Gabriella.';
	is $p2->verb('kiss'),         'kisses',    'Tests the conjugation of the verb to kiss for Gabriella';
	is $p2->verb('touch'),        'touches',   'Tests the conjugation of the verb to touch for Gabriella';
	is $p2->verb('fly', 'flies'), 'flies',     'Tests the conjugation of the verb to fly for Gabriella.';
	is $p2->dodoes,               'does',      'Tests the conjugation of the verb to do for Gabriella';
	is $p2->areis,                'is',        'Tests the conjugation of the verb to do for Gabriella';
	is $p2->gogoes,               'goes',      'Tests the conjugation of the verb to do for Gabriella';
	is $p2->havehas,              'has',       'Tests the conjugation of the verb to do for Gabriella';
};

subtest 'Tests for they pronouns' => sub {
	is $p3->name,       'Kai',    'Test the name method for Kai';
	is $p3->subject,    'they',   'Test the pronoun method for Kai';
	is $p3->Subject,    'They',   'Test the pronoun method for Kai';
	is $p3->possessive, 'their',  'Test for the possessive adjective for Kai';
	is $p3->Possessive, 'Their',  'Test for the capital possessive adjective for Kai';
	is $p3->possession, 'theirs', 'Test for the possessive pronoun for Kai';
	is $p3->Possession, 'Theirs', 'Test for the capital possessive pronoun for Kai';
	is $p3->object,     'them',   'Test for the object pronoun for Kai';
	is $p3->Object,     'Them',   'Test for the capital object pronoun for Kai';

	is $p3->verb('find'),         'find',  'Tests the conjugation of the verb to find for Kai';
	is $p3->verb('kiss'),         'kiss',  'Tests the conjugation of the verb to kiss for Kai';
	is $p3->verb('touch'),        'touch', 'Tests the conjugation of the verb to touch for Kai';
	is $p3->verb('fly', 'flies'), 'fly',   'Tests the conjugation of the verb to fly for Kai';
	is $p3->dodoes,               'do',    'Tests the conjugation of the verb to do for Kai';
	is $p3->areis,                'are',   'Tests the conjugation of the verb to do for Kai';
	is $p3->gogoes,               'go',    'Tests the conjugation of the verb to do for Kai';
	is $p3->havehas,              'have',  'Tests the conjugation of the verb to do for Kai';
};

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

	my $p = randomPerson(names => [ [ 'Bart', 'he' ], [ 'Lisa', 'she' ], [ 'Matty', 'they' ] ]);
	is ref $p,      'Person', 'The random person is a Person object.';
	is $p->subject, 'he',     'Check for pronoun' if ($p->name eq 'Bart');
	is $p->subject, 'she',    'Check for pronoun' if ($p->name eq 'Lisa');
	is $p->subject, 'they',   'Check for pronoun' if ($p->name eq 'Matty');

	my $p1 = randomPerson(names => [ 'Larry', 'Moe', 'Curly' ]);
	is ref $p1, 'Person', 'The random person is a Person object.';
	like $p1->subject, qr/she|he|they/, 'Making sure the pronoun is set.';

	my @p2 = randomPerson(n => 2, names => [ [ 'Bart' => 'he' ], [ 'Lisa' => 'she' ], [ 'Matty' => 'they' ] ]);
	is scalar(@p2),            2,                      'randomPerson return correct number of Persons';
	is [ map { ref $_ } @p2 ], [ 'Person', 'Person' ], 'testing randomPerson returns 2 Person object.';

};

subtest 'Test alternative API for randomPerson' => sub {
	my $p = randomPerson(
		names => [
			{ name => 'Bart',  pronoun => 'he' },
			{ name => 'Lisa',  pronoun => 'she' },
			{ name => 'Matty', pronoun => 'they' }
		]
	);

	is ref $p,      'Person', 'The random person is a Person object.';
	is $p->subject, 'he',     'Check for pronoun' if ($p->name eq 'Bart');
	is $p->subject, 'she',    'Check for pronoun' if ($p->name eq 'Lisa');
	is $p->subject, 'they',   'Check for pronoun' if ($p->name eq 'Matty');

	my @p2 = randomPerson(
		n     => 2,
		names => [ { name => 'Bart', pronoun => 'he' }, { name => 'Lisa', pronoun => 'she' }, { name => 'Matty' } ]
	);
	is scalar(@p2),            2,                      'randomPerson return correct number of Persons';
	is [ map { ref $_ } @p2 ], [ 'Person', 'Person' ], 'testing randomPerson returns 2 Person object.';

	like dies { randomPerson(names => [ { xxx => 'hi', pronoun => 'he' } ]); },
		qr/^The field 'pronoun' must be passed in./,
		'Make sure an error is thrown if the name is not passed in.';
};

done_testing;
