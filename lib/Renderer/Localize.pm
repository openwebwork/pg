package Renderer::Localize;

use base qw/Locale::Maketext/;

use strict;
use warnings;

use feature "say";

die 'not found.' unless -r "/opt/webwork/pg/lib/Renderer/Localize/en.po";

use Locale::Maketext::Lexicon {
	# '*' => [Gettext => "/Users/pstaab/Downloads/test_localization/loc/*.po"],
	'en'      => [ Gettext => "/opt/webwork/pg/lib/Renderer/Localize/en.po" ],
	_auto     => 1,
	_decode   => 1,
	_encoding => undef
};

use Data::Dumper;

# This subroutine is shared with the safe compartment in PG to
# allow maketext() to be constructed in PG problems and macros
# It seems to be a little fragile -- possibly it breaks
# on perl 5.8.8
sub getLoc {
	my $lang = shift;
	my $lh   = Renderer::Localize->get_handle($lang);
	return sub {
		# say 'in getLoc sub';
		print Dumper \@_;
		$lh->maketext(@_);
	};
}

sub getLangHandle {
	return Renderer::Localize->get_handle(shift);
}

# this is like [quant] but it doesn't write the number
#  usage: [quant,_1,<singular>,<plural>,<optional zero>]

sub plural {
	my ($handle, $num, @forms) = @_;

	return ""        if @forms == 0;
	return $forms[2] if @forms > 2 and $num == 0;

	# Normal case:
	return ($handle->numerate($num, @forms));
}

# this is like [quant] but it also has -1 case
#  usage: [negquant,_1,<neg case>,<singular>,<plural>,<optional zero>]

sub negquant {
	my ($handle, $num, @forms) = @_;

	return $num if @forms == 0;

	my $negcase = shift @forms;
	return $negcase if $num < 0;

	return $forms[2] if @forms > 2 and $num == 0;
	return ($handle->numf($num) . ' ' . $handle->numerate($num, @forms));
}

1;
