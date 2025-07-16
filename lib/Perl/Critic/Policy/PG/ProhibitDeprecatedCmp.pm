package Perl::Critic::Policy::PG::ProhibitDeprecatedCmp;
use Mojo::Base 'Perl::Critic::Policy', -signatures;

use Perl::Critic::Utils qw(:severities :classification :ppi);

use constant DESCRIPTION => 'The deprecated %s method is called';
use constant EXPLANATION => 'Convert the answer into a MathObject and use the cmp method of the object.';
use constant SCORE       => 55;

use constant CMP_METHODS => {
	str_cmp                         => 1,
	std_str_cmp                     => 1,
	std_str_cmp_list                => 1,
	std_cs_str_cmp                  => 1,
	std_cs_str_cmp_list             => 1,
	strict_str_cmp                  => 1,
	strict_str_cmp_list             => 1,
	unordered_str_cmp               => 1,
	unordered_str_cmp_list          => 1,
	unordered_cs_str_cmp            => 1,
	unordered_cs_str_cmp_list       => 1,
	ordered_str_cmp                 => 1,
	ordered_str_cmp_list            => 1,
	ordered_cs_str_cmp              => 1,
	ordered_cs_str_cmp_list         => 1,
	num_cmp                         => 1,
	num_rel_cmp                     => 1,
	std_num_cmp                     => 1,
	std_num_cmp_list                => 1,
	std_num_cmp_abs                 => 1,
	std_num_cmp_abs_list            => 1,
	frac_num_cmp                    => 1,
	frac_num_cmp_list               => 1,
	frac_num_cmp_abs                => 1,
	frac_num_cmp_abs_list           => 1,
	arith_num_cmp                   => 1,
	arith_num_cmp_list              => 1,
	arith_num_cmp_abs               => 1,
	arith_num_cmp_abs_list          => 1,
	strict_num_cmp                  => 1,
	strict_num_cmp_list             => 1,
	strict_num_cmp_abs              => 1,
	strict_num_cmp_abs_list         => 1,
	std_num_str_cmp                 => 1,
	fun_cmp                         => 1,
	function_cmp                    => 1,
	function_cmp_up_to_constant     => 1,
	function_cmp_abs                => 1,
	function_cmp_up_to_constant_abs => 1,
	adaptive_function_cmp           => 1,
	multivar_function_cmp           => 1,
	cplx_cmp                        => 1,
	multi_cmp                       => 1,
	radio_cmp                       => 1,
	checkbox_cmp                    => 1,
};

sub supported_parameters ($) {return}
sub default_severity ($)     { return $SEVERITY_HIGHEST }
sub default_themes ($)       { return qw(pg) }
sub applies_to ($)           { return qw(PPI::Token::Word) }

sub violates ($self, $element, $document) {
	return unless CMP_METHODS->{$element} && is_function_call($element);
	return $self->violation(sprintf(DESCRIPTION, $element), { score => SCORE, explanation => EXPLANATION }, $element);
}

1;

__END__

=head1 NAME

Perl::Critic::Policy::PG::ProhibitDeprecatedCmp - Use C<MathObjects> instead of
the deprecated C<cmp> methods.

=head1 DESCRIPTION

Convert answers into a C<MathObjects> and use the C<cmp> method of the object
instead of using any of the deprecated C<cmp> methods such as C<str_cmp> from
the L<PGstringevaluators.pl> macro, C<num_cmp> from the
L<PGnumericevaluators.pl> macro, or C<fun_cmp> from the
L<PGfunctionevaluators.pl> macro.

=cut
