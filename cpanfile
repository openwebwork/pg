# Install required module dependancies listed here (runtime and test) with
# cpanm --installdeps .

on runtime => sub {
	requires 'perl' => '5.20.3';

	requires 'DBI';
	requires 'Digest::MD5';
	requires 'Class::Accessor';
	requires 'Encode';
	requires 'Encode::Encoding';
	requires 'Exporter';
	requires 'GD';
	requires 'HTML::Entities';
	requires 'HTML::Parser';
	requires 'Mojo::JSON';
	requires 'Locale::Maketext';
	requires 'Locale::Maketext::Lexicon';
	requires 'Mojolicious';
	requires 'Tie::IxHash';
	requires 'Types::Serialiser';
	requires 'UUID::Tiny';
	requires 'YAML::XS';

	# Needed for Rserve
	recommends 'IO::Handle';

	# Needed for WeBWorK::PG::Tidy
	recommends 'Perl::Tidy';

	# Needed for WeBWorK::PG::PGProblemCritic
	recommends 'Perl::Critic';
};

on test => sub {
	requires 'Test2::V0' => '0.000139';
	requires 'Test::MockObject::Extends';
	requires 'HTML::TagParser';         # Used by t/macros/basicmacros.t

	recommends 'Data::Dumper';          # For debugging data structures
	recommends 'Test2::Tools::Explain'; # For debugging data structures
};

# Install development dependancies with
# cpanm --installdeps --with-develop --with-recommends .

on develop => sub {
	recommends 'Module::CPANfile';
	recommends 'Test::CPANfile';   # Verifies this file has all the dependancies
};
