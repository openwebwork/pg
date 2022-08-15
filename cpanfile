# install required module dependancies listed here (runtime and test) with
# cpanm --installdeps .

on runtime => sub {
    requires   'perl' => '5.20.3'; # guessing at a minimum viable version
    recommends 'perl' => '5.30.0'; # needed for Statistics::R::IO

    requires 'DBI';
    requires 'Digest::MD5';
    requires 'Encode';
    requires 'Encode::Encoding';
    requires 'GD';
    requires 'HTML::Parser';
    requires 'HTML::Entities';
    requires 'JSON';
    requires 'Locale::Maketext';
    requires 'Tie::IxHash';
    requires 'UUID::Tiny';

    # needed for Rserve
    recommends 'Statistics::R::IO::Rserve';
    recommends 'Class::Tiny';
    recommends 'IO::Handle';
};

on test => sub {
    requires 'HTML::TagParser';         # for t/macros/basicmacros.t
    requires 'Test2::V0';               # for t/units/*

    recommends 'Data::Dumper';          # for debugging data structures
    recommends 'Test::Number::Delta';   # future unit tests using tolerance
    recommends 'Test2::Tools::Explain'; # for debugging data structures
};

# install author dependancies with
# cpanm --installdeps --with-develop --with-recommends .

on develop => sub {
    recommends 'Module::CPANfile';
    recommends 'Test::CPANfile';   # verifies this file has all the dependancies
};
