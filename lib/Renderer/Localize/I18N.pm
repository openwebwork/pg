package Renderer::Localize::I18N;
use base 'Locale::Maketext';
use Locale::Maketext::Lexicon {
	'*'       => [ Gettext => "/opt/webwork/pg/lib/Renderer/Localize/*.po" ],
	_decode   => 1,
	_encoding => undef
};

# use File::Spec;
# use Locale::Maketext::Lexicon;

# my $path = "/opt/webwork/pg/lib/WeBWorK/Localize";
# my $pattern = File::Spec->catfile($path, '*.[pm]o');

# '*' => [Gettext => '/usr/local/share/locale/*/LC_MESSAGES/hello.mo'],

# Locale::Maketext::Lexicon->import({
# 		'i-default' => [ 'Auto' ],
# 		'*'	=> [ Gettext => \$pattern ],
# 		_decode => 1,
# 		_encoding => undef
# });
*tense = sub { \$_[1] . ((\$_[2] eq 'present') ? 'ing' : 'ed') };

1;
