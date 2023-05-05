#!/usr/bin/env perl

use Test2::V0 '!E', { E => 'EXISTS' };

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
do "$ENV{PG_ROOT}/t/build_PG_envir.pl";

loadMacros('randomNamesPronouns.pl');

my $p1 = Person->new(name => 'Fred',      pronoun => 'he');
my $p2 = Person->new(name => 'Gabriella', pronoun => 'she');
my $p3 = Person->new(name => 'Kai',       pronoun => 'they');

subtest 'Tests for he pronouns' => sub {
	is $p1->name,       'Fred', 'Test the name method for Fred';
	is $p1->subject,    'he',   'Test the pronoun method for Fred';
	is $p1->Subject,    'He',   'Test the capital pronoun method for Fred';
	is $p1->possessive, 'his',  'Test for the possessive adjective for Fred';
	is $p1->Possessive, 'His',  'Test for the capital possessive adjective for Fred';
	is $p1->possession, 'his',  'Test for the possessive pronoun for Fred';
	is $p1->Possession, 'His',  'Test for the capital possessive pronoun for Fred';
	is $p1->object,     'him',  'Test for the object pronoun for Fred';
	is $p1->Object,     'Him',  'Test for the capital object pronoun for Fred';
};

subtest 'Tests for verbs for he pronouns' => sub {
	is $p1->verb('find'), 'finds', 'Tests the conjugation of the verb to find for Fred.';
	is $p1->verb('Find'), 'Finds', 'Tests the conjugation and capitalization of the verb to find for Fred.';

	is $p1->verb('kiss'), 'kisses', 'Tests the conjugation of the verb to kiss for Fred';
	is $p1->verb('Kiss'), 'Kisses', 'Tests the conjugation and capitalization of the verb to kiss for Fred';

	is $p1->verb('touch'), 'touches', 'Tests the conjugation of the verb to touch for Fred';
	is $p1->verb('Touch'), 'Touches', 'Tests the conjugation and capitalization of the verb to touch for Fred';

	is $p1->verb('fly'), 'flies', 'Tests the conjugation of the verb to fly for Fred.';
	is $p1->verb('Fly'), 'Flies', 'Tests the conjugation and capitalization of the verb to fly for Fred.';

	is $p1->verb('say'), 'says', 'Tests the conjugation of the verb to say for Fred.';
	is $p1->verb('Say'), 'Says', 'Tests the conjugation and capitalization of the verb to say for Fred.';

	is $p1->verb('buy'), 'buys', 'Tests the conjugation of the verb to buy for Fred.';
	is $p1->verb('Buy'), 'Buys', 'Tests the conjugation and capitalization of the verb to buy for Fred.';

	is $p1->verb('deploy'), 'deploys', 'Tests the conjugation of the verb to deploy for Fred.';
	is $p1->verb('Deploy'), 'Deploys', 'Tests the conjugation and capitalization of the verb to deploy for Fred.';

	is $p1->verb('volley'), 'volleys', 'Tests the conjugation of the verb to volley for Fred.';
	is $p1->verb('Volley'), 'Volleys', 'Tests the conjugation and capitalization of the verb to volley for Fred.';

	is $p1->verb('vex', 'vexes'), 'vexes', 'Tests the conjugation of the verb to vex for Fred.';
	is $p1->verb('Vex', 'Vexes'), 'Vexes', 'Tests the conjugation and capitalization of the verb to vex for Fred.';

	is $p1->do,         'does', 'Tests the conjugation of the verb to do for Fred';
	is $p1->verb('do'), 'does', 'Tests the conjugation of the verb to do for Fred';
	is $p1->Do,         'Does', 'Tests the conjugation and capitalization of the verb to do for Fred';
	is $p1->verb('Do'), 'Does', 'Tests the conjugation and capitalization of the verb to do for Fred';

	is $p1->are,         'is', 'Tests the conjugation of the verb to do for Fred';
	is $p1->verb('are'), 'is', 'Tests the conjugation of the verb to do for Fred';
	is $p1->Are,         'Is', 'Tests the conjugation and capitalization of the verb to do for Fred';
	is $p1->verb('Are'), 'Is', 'Tests the conjugation and capitalization of the verb to do for Fred';

	is $p1->go,         'goes', 'Tests the conjugation of the verb to do for Fred';
	is $p1->verb('go'), 'goes', 'Tests the conjugation of the verb to do for Fred';
	is $p1->Go,         'Goes', 'Tests the conjugation and capitalization of the verb to do for Fred';
	is $p1->verb('Go'), 'Goes', 'Tests the conjugation and capitalization of the verb to do for Fred';

	is $p1->have,         'has', 'Tests the conjugation of the verb to do for Fred';
	is $p1->verb('have'), 'has', 'Tests the conjugation of the verb to do for Fred';
	is $p1->Have,         'Has', 'Tests the conjugation and capitalization of the verb to do for Fred';
	is $p1->verb('Have'), 'Has', 'Tests the conjugation and capitalization of the verb to do for Fred';

	is $p1->were,         'was', 'Tests the conjugation of the past tense of to be for Fred';
	is $p1->verb('were'), 'was', 'Tests the conjugation of the past tense of to be for Fred';
	is $p1->Were,         'Was', 'Tests the conjugation and capitalization of the past tense of to be for Fred';
	is $p1->verb('Were'), 'Was', 'Tests the conjugation and capitalization of the past tense of to be for Fred';

	# test verb with other method names
	is $p1->verb('object'),  'objects',  'Tests the conjugation of the verb object for Fred';
	is $p1->verb('Object'),  'Objects',  'Tests the conjugation of the verb Object for Fred';
	is $p1->verb('subject'), 'subjects', 'Tests the conjugation of the verb subject for Fred';
	is $p1->verb('Subject'), 'Subjects', 'Tests the conjugation of the verb subject for Fred';
	is $p1->verb('name'),    'names',    'Tests the conjugation of the verb name for Fred';
	is $p1->verb('Name'),    'Names',    'Tests the conjugation of the verb Name for Fred';
};

subtest 'Tests for she pronouns' => sub {
	is $p2->name,       'Gabriella', 'Test the name method for Gabriella';
	is $p2->subject,    'she',       'Test the pronoun method for Gabriella';
	is $p2->Subject,    'She',       'Test the capital pronoun method for Gabriella';
	is $p2->possessive, 'her',       'Test for the possessive adjective for Gabriella';
	is $p2->Possessive, 'Her',       'Test for the capital possessive adjective for Gabriella';
	is $p2->possession, 'hers',      'Test for the possessive pronoun for Gabriella';
	is $p2->Possession, 'Hers',      'Test for the capital possessive pronoun for Gabriella';
	is $p2->object,     'her',       'Test for the object pronoun for Gabriella';
	is $p2->Object,     'Her',       'Test for the capital object pronoun for Gabriella';

};

subtest 'Tests for verbs for she pronouns' => sub {
	is $p2->verb('find'), 'finds', 'Tests the conjugation of the verb to find for Gabriella.';
	is $p2->verb('Find'), 'Finds', 'Tests the conjugation and capitalization of the verb to find for Gabriella.';

	is $p2->verb('kiss'), 'kisses', 'Tests the conjugation of the verb to kiss for Gabriella';
	is $p2->verb('Kiss'), 'Kisses', 'Tests the conjugation and capitalization of the verb to kiss for Gabriella';

	is $p2->verb('touch'), 'touches', 'Tests the conjugation of the verb to touch for Gabriella';
	is $p2->verb('Touch'), 'Touches', 'Tests the conjugation and capitalization of the verb to touch for Gabriella';

	is $p2->verb('fly'), 'flies', 'Tests the conjugation of the verb to fly for Gabriella.';
	is $p2->verb('Fly'), 'Flies', 'Tests the conjugation and capitalization of the verb to fly for Gabriella.';

	is $p2->verb('say'), 'says', 'Tests the conjugation of the verb to say for Gabriella.';
	is $p2->verb('Say'), 'Says', 'Tests the conjugation and capitalization of the verb to say for Gabriella.';

	is $p2->verb('buy'), 'buys', 'Tests the conjugation of the verb to buy for Gabriella.';
	is $p2->verb('Buy'), 'Buys', 'Tests the conjugation and capitalization of the verb to buy for Gabriella.';

	is $p2->verb('deploy'), 'deploys', 'Tests the conjugation of the verb to deploy for Gabriella.';
	is $p2->verb('Deploy'), 'Deploys',
		'Tests the conjugation and capitalization of the verb to deploy for Gabriella.';

	is $p2->verb('volley'), 'volleys', 'Tests the conjugation of the verb to volley for Gabriella.';
	is $p2->verb('Volley'), 'Volleys',
		'Tests the conjugation and capitalization of the verb to volley for Gabriella.';

	is $p2->verb('vex', 'vexes'), 'vexes', 'Tests the conjugation of the verb to vex for Gabriella.';
	is $p2->verb('Vex', 'Vexes'), 'Vexes',
		'Tests the conjugation and capitalization of the verb to vex for Gabriella.';

	is $p2->do,         'does', 'Tests the conjugation of the verb to do for Gabriella';
	is $p2->verb('do'), 'does', 'Tests the conjugation of the verb to do for Gabriella';
	is $p2->Do,         'Does', 'Tests the conjugation and capitalization of the verb to do for Gabriella';
	is $p2->verb('Do'), 'Does', 'Tests the conjugation and capitalization of the verb to do for Gabriella';

	is $p2->are,         'is', 'Tests the conjugation of the verb to do for Gabriella';
	is $p2->verb('are'), 'is', 'Tests the conjugation of the verb to do for Gabriella';
	is $p2->Are,         'Is', 'Tests the conjugation and capitalization of the verb to do for Gabriella';
	is $p2->verb('Are'), 'Is', 'Tests the conjugation and capitalization of the verb to do for Gabriella';

	is $p2->go,         'goes', 'Tests the conjugation of the verb to do for Gabriella';
	is $p2->verb('go'), 'goes', 'Tests the conjugation of the verb to do for Gabriella';
	is $p2->Go,         'Goes', 'Tests the conjugation and capitalization of the verb to do for Gabriella';
	is $p2->verb('Go'), 'Goes', 'Tests the conjugation and capitalization of the verb to do for Gabriella';

	is $p2->have,         'has', 'Tests the conjugation of the verb to do for Gabriella';
	is $p2->verb('have'), 'has', 'Tests the conjugation of the verb to do for Gabriella';
	is $p2->Have,         'Has', 'Tests the conjugation and capitalization of the verb to do for Gabriella';
	is $p2->verb('Have'), 'Has', 'Tests the conjugation and capitalization of the verb to do for Gabriella';

	is $p2->were,         'was', 'Tests the conjugation of the past tense of to be for Gabriella';
	is $p2->verb('were'), 'was', 'Tests the conjugation of the past tense of to be for Gabriella';
	is $p2->Were,         'Was', 'Tests the conjugation and capitalization of the past tense of to be for Gabriella';
	is $p2->verb('Were'), 'Was',
		'Tests the conjugation and capitalization of the past tense of to be for Gabriella';

	# test verb with other method names
	is $p2->verb('object'),  'objects',  'Tests the conjugation of the verb object for Gabriella';
	is $p2->verb('Object'),  'Objects',  'Tests the conjugation of the verb Object for Gabriella';
	is $p2->verb('subject'), 'subjects', 'Tests the conjugation of the verb subject for Gabriella';
	is $p2->verb('Subject'), 'Subjects', 'Tests the conjugation of the verb subject for Gabriella';
	is $p2->verb('name'),    'names',    'Tests the conjugation of the verb name for Gabriella';
	is $p2->verb('Name'),    'Names',    'Tests the conjugation of the verb Name for Gabriella';

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
};

subtest 'Tests for verbs for she pronouns' => sub {
	is $p3->verb('find'), 'find', 'Tests the conjugation of the verb to find for Kai.';
	is $p3->verb('Find'), 'Find', 'Tests the conjugation and capitalization of the verb to find for Kai.';

	is $p3->verb('kiss'), 'kiss', 'Tests the conjugation of the verb to kiss for Kai';
	is $p3->verb('Kiss'), 'Kiss', 'Tests the conjugation and capitalization of the verb to kiss for Kai';

	is $p3->verb('touch'), 'touch', 'Tests the conjugation of the verb to touch for Kai';
	is $p3->verb('Touch'), 'Touch', 'Tests the conjugation and capitalization of the verb to touch for Kai';

	is $p3->verb('fly'), 'fly', 'Tests the conjugation of the verb to fly for Kai.';
	is $p3->verb('Fly'), 'Fly', 'Tests the conjugation and capitalization of the verb to fly for Kai.';

	is $p3->verb('say'), 'say', 'Tests the conjugation of the verb to say for Kai.';
	is $p3->verb('Say'), 'Say', 'Tests the conjugation and capitalization of the verb to say for Kai.';

	is $p3->verb('buy'), 'buy', 'Tests the conjugation of the verb to buy for Kai.';
	is $p3->verb('Buy'), 'Buy', 'Tests the conjugation and capitalization of the verb to buy for Kai.';

	is $p3->verb('deploy'), 'deploy', 'Tests the conjugation of the verb to deploy for Kai.';
	is $p3->verb('Deploy'), 'Deploy', 'Tests the conjugation and capitalization of the verb to deploy for Kai.';

	is $p3->verb('volley'), 'volley', 'Tests the conjugation of the verb to volley for Kai.';
	is $p3->verb('Volley'), 'Volley', 'Tests the conjugation and capitalization of the verb to volley for Kai.';

	is $p3->verb('vex', 'vexes'), 'vex', 'Tests the conjugation of the verb to vex for Kai.';
	is $p3->verb('Vex', 'Vexes'), 'Vex', 'Tests the conjugation and capitalization of the verb to vex for Kai.';

	is $p3->do,         'do', 'Tests the conjugation of the verb to do for Kai';
	is $p3->verb('do'), 'do', 'Tests the conjugation of the verb to do for Kai';
	is $p3->Do,         'Do', 'Tests the conjugation and capitalization of the verb to do for Kai';
	is $p3->verb('Do'), 'Do', 'Tests the conjugation and capitalization of the verb to do for Kai';

	is $p3->are,         'are', 'Tests the conjugation of the verb to do for Kai';
	is $p3->verb('are'), 'are', 'Tests the conjugation of the verb to do for Kai';
	is $p3->Are,         'Are', 'Tests the conjugation and capitalization of the verb to do for Kai';
	is $p3->verb('Are'), 'Are', 'Tests the conjugation and capitalization of the verb to do for Kai';

	is $p3->go,         'go', 'Tests the conjugation of the verb to do for Kai';
	is $p3->verb('go'), 'go', 'Tests the conjugation of the verb to do for Kai';
	is $p3->Go,         'Go', 'Tests the conjugation and capitalization of the verb to do for Kai';
	is $p3->verb('Go'), 'Go', 'Tests the conjugation and capitalization of the verb to do for Kai';

	is $p3->have,         'have', 'Tests the conjugation of the verb to do for Kai';
	is $p3->verb('have'), 'have', 'Tests the conjugation of the verb to do for Kai';
	is $p3->Have,         'Have', 'Tests the conjugation and capitalization of the verb to do for Kai';
	is $p3->verb('Have'), 'Have', 'Tests the conjugation and capitalization of the verb to do for Kai';

	is $p3->were,         'were', 'Tests the conjugation of the past tense of to be for Kai';
	is $p3->verb('were'), 'were', 'Tests the conjugation of the past tense of to be for Kai';
	is $p3->Were,         'Were', 'Tests the conjugation and capitalization of the past tense of to be for Kai';
	is $p3->verb('Were'), 'Were', 'Tests the conjugation and capitalization of the past tense of to be for Kai';

	# test verb with other method names
	is $p3->verb('object'),  'object',  'Tests the conjugation of the verb object for Kai';
	is $p3->verb('Object'),  'Object',  'Tests the conjugation of the verb Object for Kai';
	is $p3->verb('subject'), 'subject', 'Tests the conjugation of the verb subject for Kai';
	is $p3->verb('Subject'), 'Subject', 'Tests the conjugation of the verb subject for Kai';
	is $p3->verb('name'),    'name',    'Tests the conjugation of the verb name for Kai';
	is $p3->verb('Name'),    'Name',    'Tests the conjugation of the verb Name for Kai';

};

subtest 'Other person tests' => sub {
	my $rando = randomPerson();
	is ref $rando, 'Person', 'Check that the randomPerson method returns an object of Person class';

	like
		dies { Person->new(name => 'Head', pronoun => 'xxx') },
		qr/The acceptable pronouns are:/,
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

	# this was giving an error.
	my @p3 = randomPerson(n => 1, names => [ [ 'Bart', 'he' ] ]);
	is ref $p3[0],      'Person', 'Check that a Person object is created.';
	is $p3[0]->name,    'Bart',   'Check that the name is correct.';
	is $p3[0]->subject, 'he',     'Check that the subject pronoun is correct.';
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
		qr/^The field "name" must be passed in./,
		'Make sure an error is thrown if the name is not passed in.';
};

done_testing;
