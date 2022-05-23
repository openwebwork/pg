# install required module dependancies listed here (runtime and test) with
# cpanm --installdeps .

on runtime => sub {
    requires   'perl' => '5.20.3'; # guessing at a minimum viable version
    recommends 'perl' => '5.30.0'; # for Statistics::R::IO

    requires 'DBI';
    requires 'Digest::MD5';
    requires 'HTML::Entities';
    requires 'JSON';
    requires 'Tie::IxHash';
    requires 'URI::Escape';
    requires 'UUID::Tiny';
};

on test => sub {
    requires 'Test2::V0';

    recommends 'Data::Dumper';        # for debugging data structures
    recommends 'Test::Number::Delta'; # future unit tests using tolerance
};

# install author dependancies with
# cpanm --installdeps --with-develop --with-recommends .

on develop => sub {
    recommends 'Module::CPANfile';
    recommends 'Test::CPANfile';   # verifies this file has all the dependancies
};
