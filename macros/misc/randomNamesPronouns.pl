
=head1 NAME

randomNamesPronouns.pl - Load macros for random names.

=head2 SYNOPSIS

 loadMacros('randomNamesPronouns.pl');

=head2 DESCRIPTION

C<randomNamesPronouns.pl> provides a randomName function that generates a random
name with subject pronouns, possessive pronouns, adjectives and object pronouns
with and without capitilization and verb conjugation.

Note: this idea and the names were taken from the C<PCCmacros.pl> C<RandomName>
subroutine to extend to the handling of pronouns. Most of the names in here were
taken from that macro.  Many thanks to those who worked on that macro.

=head2 USAGE

First load the C<randomNamesPronouns> macro with

  loadMacros('randomNamesPronouns.pl');

and then call the randomPerson subroutine

  $p1 = randomPerson()

The variable C<$p1> is now a C<Person> object with methods to access the names, pronouns
and verb conjugation.  It is can be used within a problem as

  BEGIN_PGML
  [$p1->name] [@ $p1->verb('travel') @] 1.5 miles to school.  After school,
  [$p1->subject] then [@$p1->verb('goes','go')@] to work.

  [$p1->possession] dog greets [$p1->object] when [$p1->object] gets home.

  The books on the table are [$p1->possessive].
  END_PGML

Additionally, you can specify names/pronouns if you like.  For example

  ($p1,$p2) = randomPerson(names => [['Bart', 'he'], ['Lisa', 'she']]);

or without the pronouns which will be assigned randomly beteween he/she/they:

  ($p1,$p2) = randomPerson(names => ['Bart', 'Lisa']);

And if you would like multiple people to be randomly choosen with unique names, then

  @persons = randomPerson(n => 4);

generates 4 C<Person> objects as an array.
=cut

loadMacros('PGbasicmacros.pl', 'PGauxiliaryFunctions.pl');

my $names_pronouns = {
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

@last_names = qw(
	Adams   Allen     Alvarez    Anderson Bailey  Baker    Bennet    Brooks
	Brown   Campbell  Carter     Castillo Chavez  Clark    Collins   Cook
	Cooper  Cox       Cruz       Davis    Diaz    Edwards  Evans     Flores
	Foster  Garcia    Gomez      Gonzales Gray    Green    Gutierrez Hall
	Harris  Hernandez Hill       Howard   Hughes  Jackson  James     Jimenez
	Johnson Jones     Kelly      Kim      King    Lee      Lewis     Long
	Lopez   Martin    Martinez   Mendoza  Miller  Mitchell Moore     Morales
	Morgan  Morris    Murphy     Myers    Nelson  Nguyen   Ortiz     Parker
	Patel   Perez     Peterson   Phillips Pina    Price    Ramirez   Ramos
	Reed    Reyes     Richardson Rivera   Roberts Robinson Rodriguez Rogers
	Ross    Ruiz      Sanchez    Sanders  Scott   Smith    Stewart   Sullivan
	Taylor  Thomas    Thompson   Torres   Turner  Walker   Ward      Watson
	White   Williams  Wilson     Wood     Wright  Young
);

# need to have the keys sorted to have a consistent set of names for a given seed, so
# we build an array of the first_names sorted.
my @first_names;

sub _randomNamesPronouns_init {
	@first_names = lex_sort(keys(%$names_pronouns));
}

=head2 randomPerson

Returns a person as a Person object from a list in the macro.

=head3 Examples and options

=over

=item * No arguments returns a single random person

Example

  randomPerson()

=item * C<n =E<gt> k> returns an array of k Person objects with unique names.

Example

  randomPerson(n=>5)

returns an array of 5 Person objects with unique names.

=item * C<names =E<gt> arrayref> returns an array of specified Person objects.

If the arrayref is in the form of C<[['name1','pronoun1'],['name2','pronoun2'],...]> then
an array of Person objects of the names and pronouns specified.

Example:

  my ($a,$b,$c) = randomPerson(names => [['Bart','he'], ['Lisa','she'], ['Matty','they']]);

If the arrayref is just in the form of C<['name1','name2',...]> then the names are specified
and the pronouns are randomly generated.

  my ($p1, $p2, $p3) = randomPerson( names => ['Larry', 'Moe', 'Curly']);

=back

=cut

sub randomPerson {
	my %options = (
		n => 1,
		@_
	);

	# if the names are passed in.
	return
		map { Person->new(name => $_->[0] // $_, pronoun => $_->[1] // list_random('he', 'she', 'they')) }
		@{ $options{names} }
		if ($options{names});

	if ($options{n} == 1) {
		my $random_name = list_random(@first_names);
		return Person->new(name => $random_name, pronoun => $names_pronouns->{$random_name});
	} else {
		my $indices = random_subset($options{n}, 0 .. scalar(@first_names) - 1);
		return
			map { Person->new(name => $first_names[$_], pronoun => $names_pronouns->{ $first_names[$_] }); } @$indices;
	}
}

=head3 randomLastName

This returns a random last name based on popular last names in the United States.  Example

  $p = randomLastName();

Note: it is just a string, and doesn't have the pronoun's that the Person object does.

If a number is passed in the form C< n =E<gt> k>, then k unique last names are returned.

  @last_names = randomLastName(n=>4);

generates 4 unique last names.

=cut

sub randomLastName {
	my %options = (
		n => 1,
		@_
	);
	return list_random(@last_names) if $options{n} == 1;
	my $indices = random_subset($options{n}, 0 .. scalar(@last_names) - 1);
	return map { $last_names[$_] } @$indices;
}

=head2 CONSTRUCTOR Person

This makes a Person object to handle name and pronouns of a Person.

Make a person with

  Person->new(name => 'Roger', pronoun => 'he')

as an example. This is often used with the C<randomPerson> method which returns a blessed Person object
which can be used in problems to write a problem with a random name with pronouns
and verb conjugation.

=cut

package Person;

sub new {
	my ($class, %opts) = @_;
	my @v = grep { $opts{pronoun} eq $_ } qw/he she they/;
	die "The pronoun must be either he, she or they. You passed in $opts{pronoun}"
		if scalar(@v) != 1;
	die 'The field name must be passed in' unless defined($opts{name});
	my $self = {
		_name    => $opts{name},
		_pronoun => $opts{pronoun}
	};
	bless $self, $class;
	return $self;
}

=head2 name

This returns the name of the person.

  my $p = new Person(name => 'Roger', pronoun => 'he');

  $p->name;

returns the name 'Roger'.
=cut

sub name { return shift->{_name}; }

=head2 subject

This returns the subject pronoun as a lower case.

  $p->subject;

returns the pronoun. In this case 'he'.

=cut

sub subject { return shift->{_pronoun}; }

=head2 Subject

This returns the subject pronoun as an upper case.

  $p->Subject;

returns the upper case pronoun. In this case 'He'.

=cut

sub Subject { return ucfirst(shift->{_pronoun}); }

=head2 possessive

This returns the possessive adjective

  $p->possessive;

returns (his, her, their) for the pronouns (he/she/they)

=cut

sub possessive {
	my $p = shift->{_pronoun};
	return $p eq 'he' ? 'his' : ($p eq 'she' ? 'her' : 'their');
}

=head2 Possessive

This returns the captilized possessive adjective

  $p->Possessive;

returns (His, Her, Their) for the pronouns (he/she/they)

=cut

sub Possessive {
	return ucfirst(shift->possessive);
}

=head2 possession

This returns the possessive pronoun

  $p->possession;

returns (his, hers, theirs) for the pronouns (he/she/they)

=cut

sub possession {
	my $p = shift->{_pronoun};
	return $p eq 'he' ? 'his' : ($p eq 'she' ? 'hers' : 'theirs');
}

=head2 Possession

This returns the capitalized versions of possessive pronoun

  $p->Possession;

returns (His, Hers, Theirs) for the pronouns (he/she/they)

=cut

sub Possession {
	return ucfirst(shift->possession);
}

=head2 object

This returns the object pronoun

  $p->object;

returns (him, her, them) for the pronouns (he/she/they)

=cut

sub object {
	my $p = shift->{_pronoun};
	return $p eq 'he' ? 'him' : ($p eq 'she' ? 'her' : 'them');
}

=head2 Object

This returns the captilized object pronoun

  $p->Object;

returns (Him, Her, Them) for the pronouns (he/she/they)

=cut

sub Object {
	return ucfirst(shift->object);
}

=head2 verb

Returns the correct conjugation of the verb.  If only one verb is passed in, it should
be regular and the plural (without an s) version.

For example

  $p1 = new Person(name => 'Roger', pronoun => 'he');
  $p2 = new Person(name => 'Max', pronoun => 'they');

  $p1->verb('find');

returns 'finds'

  $p2->verb('find')

returns 'find'


If two arguments are passed in, they should be the singular and plural forms of the
verbs in that order.

For example if

  $p1 = new Person(name => 'Roger', pronoun => 'he');
  $p2 = new Person(name => 'Max', pronoun 'they');

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
