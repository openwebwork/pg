################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2024 The WeBWorK Project, https://github.com/openwebwork
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of either: (a) the GNU General Public License as published by the
# Free Software Foundation; either version 2, or (at your option) any later
# version, or (b) the "Artistic License" which comes with this package.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See either the GNU General Public License or the
# Artistic License for more details.
################################################################################

loadMacros('MathObjects.pl');

sub _parserWordCompletion_init {
	parser::WordCompletion::Init();
	return;
}

sub WordCompletion { parser::WordCompletion->new(@_) }

package parser::WordCompletion;
our @ISA = qw(Value::String);

my $context;

# Setup the context and the PopUp() command
sub Init {
	# Make a context in which arbitrary strings can be entered.
	$context = Parser::Context->getCopy('Numeric');
	$context->{name} = 'WordCompletion';
	$context->parens->clear;
	$context->variables->clear;
	$context->constants->clear;
	$context->operators->clear;
	$context->functions->clear;
	$context->strings->clear;
	$context->{pattern}{number}         = "^\$";
	$context->variables->{patterns}     = {};
	$context->strings->{patterns}{'.*'} = [ -20, 'str' ];
	$context->{parser}{String}          = 'parser::WordCompletion::String';
	$context->update;
	return;
}

# Create a new WordCompletion object
sub new {
	my ($invocant, @options) = @_;
	shift @options if Value::isContext($options[0]);    # Remove context, if given (it is not used).
	my $choices = shift @options;
	my $value   = shift @options;

	Value::Error(q{A WordCompletion's first argument should be a list of menu items})
		unless ref($choices) eq 'ARRAY';
	Value::Error(q{A WordCompletion's second argument should be the correct menu choice})
		unless defined $value && $value ne '';
	Value::Error('The correct choice must be one of the WordCompletion menu items')
		unless grep { $_ eq $value } @$choices;

	my $this_context = $context->copy;
	$this_context->flags->set(validChoices => $choices);

	return bless { data => [$value], context => $this_context, choices => $choices }, ref($invocant) || $invocant;
}

sub cmp_defaults { return (shift->SUPER::cmp_defaults(@_), mathQuillOpts => 'disabled') }

sub menu {
	my ($self, $name, $size) = @_;
	$size ||= 20;

	main::RECORD_IMPLICIT_ANS_NAME($name = main::NEW_ANS_NAME()) unless $name;

	my $answer_value = $main::inputs_ref->{$name} // '';
	$answer_value = [ split("\0", $answer_value) ] if $answer_value =~ /\0/;
	if (ref($answer_value) eq 'ARRAY') {
		my @answers = @$answer_value;
		$answer_value = shift(@answers) // '';
		$main::rh_sticky_answers->{$name} = \@answers;
	}
	$answer_value =~ s/\s+/ /g;

	$name = main::RECORD_ANS_NAME($name, $answer_value);

	my $tcol = $size / 2 > 3 ? $size / 2 : 3;
	$tcol = $tcol < 40 ? $tcol : 40;

	return main::MODES(
		TeX  => "{\\answerRule[$name]{$tcol}}",
		HTML => main::tag(
			'span',
			class => 'text-nowrap',
			main::tag(
				'input',
				type           => 'text',
				class          => 'codeshard',
				size           => $size,
				name           => $name,
				id             => $name,
				list           => "$name-list",
				aria_label     => $options{aria_label} // main::generate_aria_label($name),
				dir            => 'auto',
				autocomplete   => 'off',
				autocapitalize => 'off',
				spellcheck     => 'false',
				value          => $answer_value
				)
				. main::tag(
					'datalist',
					id               => "$name-list",
					class            => 'word-completion-data',
					data_answer_name => $name,
					join('', map { main::tag('option', value => $_) } @{ $self->{choices} })
				)
			)
			. main::tag('input', type => 'hidden', name => $previous_name, value => $answer_value),
		PTX => qq!<fillin name="$name" characters="$size" />!
	);
}

sub choices_text {
	my $self = shift;
	return join ', ', @{ $self->{choices} };
}

sub choices_list {
	my $self = shift;
	return main::MODES(
		TeX  => "\\begin{itemize}\n" . join("\n", map {"\\item $_"} @{ $self->{choices} }) . "\\end{itemize}\n",
		HTML => main::tag('ul', join('', map { main::tag('li', $_) } @{ $self->{choices} }))
	);
}

sub ans_rule                 { return shift->menu('', @_) }
sub named_ans_rule           { return shift->menu(@_) }
sub named_ans_rule_extension { return shift->menu(@_) }

# Replacement for Parser::String that takes the complete parse string as its value and gives an error if the answer
# given is not one of the allowed answers.
package parser::WordCompletion::String;
our @ISA = ('Parser::String');

sub new {
	my ($self, $equation, $value, $ref) = @_;

	Value::Error('Your answer is not a valid answer. Please choose from the list of allowable '
			. 'answers that appears when you type into the answer blank.')
		unless grep { $_ eq $value } @{ $self->context->flags->get('validChoices') };

	return $self->SUPER::new($equation, $equation->{string}, $ref);
}

1;

__END__

=head1 NAME

parserWordCompletion.pl

=head1 DESCRIPTION

Provides free response, fill in the blank questions.  As a student types in the
answer blank, a drop-down list of allowable answers appears that matches what
has already been typed is shown.  A warning message is shown if an answer is
submitted that is not among the allowed choices.  Choices in the drop-down list
and the correct answer are specified by the problem author.  WordCompletion
objects are compatible with Value objects, and in particular, can be used with
MultiAnswer objects.

To create a WordCompletion object, use

    $w = WordCompletion(['choice 1', 'choice 2', ...], correct);

where C<'choice 1', 'choice 2', ...> are the allowed answers that will be shown
in the drop-down list and C<correct> is the correct answer from the list.

To insert the WordCompletion answer rule into a problem use

    BEGIN_PGML
	[_]{$w}{40}
    END_PGML

or

    BEGIN_TEXT
    \{ $w->ans_rule(40) \}
    END_TEXT

    ANS($wb->cmp);

You can explicitly list all of the choices using

    $w->choices_text

for a comma separated list of the choices (inline, text style) and

    $w->choices_list

for an unordered list (display style).

=cut
