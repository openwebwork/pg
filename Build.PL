use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'PGcore',
    license             => 'perl',
    dist_abstract       => 'Hello short description',
    dist_author         => 'Author Name <email_addy@goes.here>',
    build_requires => {
        'Test::More' => '0.10',
    },
    test_files => 't/**/*.t'
);

$builder->create_build_script();
