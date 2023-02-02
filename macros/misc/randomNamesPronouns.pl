
=head1 NAME

randomNamesPronouns.pl - Load macros for random names.

=head2 SYNOPSIS

 loadMacros('randomNamesPronouns.pl');

=head2 DESCRIPTION

randomNamesPronouns.pl provides a randomName function that generates a random name with pronouns.  In addition,
there is the capability of providing pronouns, possessive pronouns, adjectives and object pronouns
with and without capitilization and verb conjugation.

Note: this idea and the names wer taken from the PCCmacros.pl RandomName subroutine to extend to
the handling of pronouns. Most of the names in here were taken from that macro.  Many thanks to those
who worked on that macro.

=head2 USAGE

First load the C<randomNamesPronouns> macro with

  loadMacros('randomNamesPronouns.pl');

and then call the randomPerson subroutine

  $p1 = randomPerson()

The variable C<$p1> is now a C<Person> object with methods to access the names, pronouns
and verb conjugation.  It is can be used within a problem as

  BEGIN_PGML
  [@ $p1->name @] [@ $p1->verb('travel') @] 1.5 miles to school.  After school,
  [$p1->pronoun] then [@$p1->verb('goes','go')@] to work.

  [@ $p1->Poss_adj @] dog greets [@ $p1->obj_pronoun @] when [@ $p1->obj_pronoun @] gets home.

  The books on the table are [@ $p1->poss_pronoun @].
  END_PGML

=cut

sub _randomNamesPronouns_init { }

my $names = {
	'Aaliyah'   => 'she',
	'Aaron'     => 'he',
	'Adrian'    => 'she',
	'Aiden'     => 'they',
	'Alejandro' => 'he',
	'Aleric'    => 'he',
	'Alex'      => 'they',
	'Alisa'     => 'she',
	'Alyson'    => 'she',
	'Amber'     => 'she',
	'Andrew'    => 'he',
	'Annaly'    => 'she',
	'Anthony'   => 'he',
	'Ashley'    => 'she',
	'Barbara'   => 'she',
	'Benjamin'  => 'he',
	'Blake'     => 'he',
	'Bobbi'     => 'she',
	'Brad'      => 'he',
	'Brent'     => 'he',
	'Briana'    => 'she',
	'Candi'     => 'she',
	'Carl'      => 'he',
	'Carly'     => 'she',
	'Carmen'    => 'she',
	'Casandra'  => 'she',
	'Charity'   => 'she',
	'Charlotte' => 'she',
	'Cheryl'    => 'she',
	'Chris'     => 'he',
	'Cody'      => 'he',
	'Connor'    => 'he',
	'Corey'     => 'he',
	'Daniel'    => 'he',
	'Dave'      => 'he',
	'Dawn'      => 'she',
	'Dennis'    => 'he',
	'Derick'    => 'he',
	'Devon'     => 'he',
	'Diane'     => 'she',
	'Don'       => 'they',
	'Donna'     => 'she',
	'Douglas'   => 'he',
	'Dylan'     => 'they',
	'Eileen'    => 'she',
	'Eliot'     => 'they',
	'Elishua'   => 'she',
	'Emiliano'  => 'he',
	'Emily'     => 'she',
	'Eric'      => 'he',
	'Evan'      => 'he',
	'Fabrienne' => 'she',
	'Farshad'   => 'he',
	'Gosheven'  => 'he',
	'Grant'     => 'he',
	'Gregory'   => 'he',
	'Gustav'    => 'he',
	'Haley'     => 'she',
	'Hannah'    => 'she',
	'Hayden'    => 'he',
	'Heather'   => 'she',
	'Henry'     => 'he',
	'Holli'     => 'she',
	'Huynh'     => 'he',
	'Irene'     => 'she',
	'Ivan'      => 'he',
	'Izabelle'  => 'she',
	'James'     => 'he',
	'Janieve'   => 'she',
	'Jay'       => 'he',
	'Jeff'      => 'he',
	'Jenny'     => 'she',
	'Jerry'     => 'he',
	'Jessica'   => 'she',
	'Jon'       => 'he',
	'Jordan'    => 'they',
	'Joseph'    => 'he',
	'Joshua'    => 'he',
	'Julie'     => 'she',
	'Kandace'   => 'she',
	'Kara'      => 'she',
	'Katherine' => 'she',
	'Kayla'     => 'she',
	'Ken'       => 'he',
	'Kenji'     => 'he',
	'Kim'       => 'she',
	'Kimball'   => 'he',
	'Kristen'   => 'she',
	'Kurt'      => 'he',
	'Kylie'     => 'she',
	'Kyrie'     => 'he',
	'Laney'     => 'she',
	'Laurie'    => 'she',
	'Lesley'    => 'she',
	'Lily'      => 'she',
	'Lin'       => 'he',
	'Lindsay'   => 'she',
	'Lisa'      => 'she',
	'Luc'       => 'they',
	'Malik'     => 'he',
	'Marc'      => 'he',
	'Maria'     => 'she',
	'Martha'    => 'she',
	'Matthew'   => 'he',
	'Matty'     => 'they',
	'Max'       => 'they',
	'Maygen'    => 'she',
	'Michael'   => 'he',
	'Michele'   => 'she',
	'Morah'     => 'she',
	'Nathan'    => 'he',
	'Neil'      => 'he',
	'Nenia'     => 'she',
	'Nicholas'  => 'he',
	'Nina'      => 'she',
	'Olivia'    => 'she',
	'Page'      => 'she',
	'Parnell'   => 'he',
	'Penelope'  => 'she',
	'Perlia'    => 'she',
	'Peter'     => 'he',
	'Phil'      => 'he',
	'Priscilla' => 'she',
	'Randi'     => 'he',
	'Ravi'      => 'he',
	'Ray'       => 'they',
	'Rebecca'   => 'she',
	'Renee'     => 'she',
	'Rita'      => 'she',
	'Ronda'     => 'she',
	'Ross'      => 'he',
	'Ryan'      => 'he',
	'Samantha'  => 'she',
	'Sarah'     => 'she',
	'Scot'      => 'he',
	'Sean'      => 'he',
	'Sebastian' => 'he',
	'Selena'    => 'she',
	'Shane'     => 'he',
	'Sharell'   => 'she',
	'Sharnell'  => 'she',
	'Sherial'   => 'she',
	'Stephanie' => 'she',
	'Stephen'   => 'he',
	'Subin'     => 'she',
	'Sydney'    => 'she',
	'Tammy'     => 'she',
	'Teresa'    => 'she',
	'Thanh'     => 'he',
	'Tien'      => 'he',
	'Tiffany'   => 'she',
	'Timothy'   => 'he',
	'Tracey'    => 'she',
	'Virginia'  => 'she',
	'Wendy'     => 'she',
	'Wenwu'     => 'he',
	'Will'      => 'he'
};

=head2 randomPerson

Returns a person as a Person object from a list in the macro.

=cut

sub randomPerson {
	my $random_name = list_random(keys(%$names));
	return Person->new({ name => $random_name, pronoun => $names->{$random_name} });
}

=head2 CONSTRUCTOR Person

This makes a Person object to handle name and pronouns of a Person.

Make a person with

  Person->new({ name => 'Roger', pronoun => 'he'})

as an example. This is often used with the C<randomPerson> method which returns a blessed Person object
which can be used in problems to write a problem with a random name with pronouns
and verb conjugation.

=cut

package Person;

sub new {
	my ($class, $p) = @_;
	my @v = grep { $p->{pronoun} eq $_ } qw/he she they/;
	return Value::Error("The pronoun must be either he, she or they. You passed in $p->{pronoun}")
		if scalar(@v) != 1;
	my $self = {
		_name    => $p->{name},
		_pronoun => $p->{pronoun}
	};
	bless $self, $class;
	return $self;
}

=head2 name

This returns the name of the person.

  my $p = new Person({ name => 'Roger', pronoun => 'he'});

  $p->name;

returns the name ('Roger').
=cut

sub name { return shift->{_name}; }

=head2 pronoun

This returns the pronoun as a lower case.

  $p->pronoun;

returns the pronoun. In this case 'he'.

=cut

sub pronoun { return shift->{_pronoun}; }

=head2 Pronoun

This returns the pronoun as an upper case.

  $p->Pronoun;

returns the upper case pronoun. In this case 'He'.

=cut

sub Pronoun { return ucfirst(shift->{_pronoun}); }

=head2 poss_adj

This returns the possessive adjective

  $p->poss_adj;

returns (his, her, their) for the pronouns (he/she/they)

=cut

sub poss_adj {
	my $p = shift->{_pronoun};
	return $p eq 'he' ? 'his' : ($p eq 'she' ? 'her' : 'their');
}

=head2 Poss_adj

This returns the captilized possessive adjective

  $p->Poss_adj;

returns (His, Her, Their) for the pronouns (he/she/they)

=cut

sub Poss_adj {
	return ucfirst(shift->poss_adj);
}

=head2 poss_pronoun

This returns the possessive pronoun

  $p->poss_pronoun;

returns (his, hers, theirs) for the pronouns (he/she/they)

=cut

sub poss_pronoun {
	my $p = shift->{_pronoun};
	return $p eq 'he' ? 'his' : ($p eq 'she' ? 'hers' : 'theirs');
}

=head2 Poss_pronoun

This returns the capitalized versions of possessive pronoun

  $p->Poss_pronoun;

returns (His, Hers, Theirs) for the pronouns (he/she/they)

=cut

sub Poss_pronoun {
	return ucfirst(shift->poss_pronoun);
}

=head2 obj_pronoun

This returns the object pronoun

  $p->obj_pronoun;

returns (him, her, them) for the pronouns (he/she/they)

=cut

sub obj_pronoun {
	my $p = shift->{_pronoun};
	return $p eq 'he' ? 'him' : ($p eq 'she' ? 'her' : 'them');
}

=head2 Obj_pronoun

This returns the captilized object pronoun

  $p->Obj_pronoun;

returns (Him, Her, Them) for the pronouns (he/she/they)

=cut

sub Obj_pronoun {
	return ucfirst(shift->obj_pronoun);
}

=head2 verb

Returns the correct conjugation of the verb.  If only one verb is passed in, it should
be regular and the plural (without an s) version.

For example

  $p1 = new Person({ name => 'Roger', pronoun => 'he' });
  $p2 = new Person({ name => 'Max', pronoun => 'they'});

  $p1->verb('find');

returns 'finds'

  $p2->verb('find')

returns 'find'


If two arguments are passed in, they should be the singular and plural forms of the
verbs in that order.

For example if

  $p1 = new Person({ name => 'Roger', pronoun => 'he' });
  $p2 = new Person({ name => 'Max', pronoun 'they'});

  $p1->verb('is', 'are');

returns 'is'

  $p2->verb('is', 'are');

returns C<'are'>

=cut

sub verb {
	my ($self, $sing, $plur) = @_;
	return
		defined($plur)
		? ($self->{_pronoun} eq 'they' ? $plur : $sing)
		: ($self->{_pronoun} eq 'they' ? $sing : $sing . 's');
}

1;
