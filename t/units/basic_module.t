use Test2::V0;

use Units;

# get unit hashes
my %joule = evaluate_units('J');
my %newton_metre = evaluate_units('N*m');
my %energy_base_units = evaluate_units('kg*m^2/s^2');

# basic definitions of energy equivalence
is \%joule, \%newton_metre,
    'A joule is a newton-metre';
is \%joule, \%energy_base_units,
    'A joule is a kg metre squared per second squared';


# test the error handling
my $fake = 'bleurg';
ok my %error = evaluate_units($fake);
like $error{ERROR}, qr/UNIT ERROR Unrecognizable unit: \|$fake\|/,
    "No unit '$fake' defined in Units file";


done_testing;
