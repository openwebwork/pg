package Perl::Critic::Policy::PG::ProhibitDeprecatedMultipleChoice;
use Mojo::Base 'Perl::Critic::Policy', -signatures;

use Perl::Critic::Utils qw(:severities :classification :ppi);

use WeBWorK::PG::Critic::Utils qw(getDeprecatedMacros);

use constant DESCRIPTION => 'The deprecated %s function is called';
use constant EXPLANATION => 'The deprecated %s function should be replaced with a modern alternative.';
use constant SCORE       => -20;
use constant SAMPLE_PROBLEMS => [
	[ 'Multiple Choice with Checkbox'      => 'Misc/MultipleChoiceCheckbox' ],
	[ 'Multiple Choice with Popup'         => 'Misc/MultipleChoicePopup' ],
	[ 'Multiple Choice with Radio Buttons' => 'Misc/MultipleChoiceRadio' ]
];

# Note that new_match_list is not in this list because there is not a modern alternative yet.
# The qa method is also not listed because it is needed with new_match_list.
use constant MULTIPLE_CHOICE_METHODS => {
	new_checkbox_multiple_choice => 1,
	new_multiple_choice          => 1,
	new_pop_up_select_list       => 1,
	new_select_list              => 1
};

sub supported_parameters ($) {return}
sub default_severity ($)     { return $SEVERITY_HIGHEST }
sub default_themes ($)       { return qw(pg) }
sub applies_to ($)           { return qw(PPI::Token::Word) }

sub violates ($self, $element, $) {
	return unless MULTIPLE_CHOICE_METHODS->{$element} && is_function_call($element);
	return $self->violation(sprintf(DESCRIPTION, $element),
		{ score => SCORE, explanation => sprintf(EXPLANATION, $element), sampleProblems => SAMPLE_PROBLEMS },
		$element);
}

1;

__END__

=head1 NAME

Perl::Critic::Policy::PG::ProhibitDeprecatedMultipleChoice - Replace usage of
L<PGchoicemacros.pl> multiple choice methods with the appropriate MathObject
multiple choice
macro.

=head1 DESCRIPTION

Replace usage of L<PGchoicemacros.pl> multiple choice methods with the
appropriate modern multiple choice macro.  For example, consider using
L<parserPopUp.pl>, L<parserCheckboxList.pl>, or L<parserRadioButtons.pl>.

=cut
