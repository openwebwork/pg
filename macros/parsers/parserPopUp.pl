################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2023 The WeBWorK Project, https://github.com/openwebwork
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

=head1 NAME

parserPopUp.pl - Pop-up menus compatible with Value objects.

=head1 DESCRIPTION

This file implements a pop-up menu object that is compatible with
MathObjects, and in particular, with the MultiAnswer object, and with
PGML.

To create a PopUp object, use one of:

    $popup = PopUp([choices,...], correct);
    $dropdown = DropDown([choices,...], correct);
    $truefalse = DropDownTF(correct);

where "choices" are the strings for the items in the popup menu,
and "correct" is the choice that is the correct answer for the
popup (or its index, with 0 being the first one).

The difference between C<PopUp()> and C<DropDown() >is that in HTML,
the latter will have an unselectable placeholder value. This value is '?'
by default, but can be customized with a C<placeholder> option.

C<DropDownTF()> is like C<DropDown> with options being localized versions of
"True" and "False". 1 is understood as "True" and 0 as "False". The initial
letter of the localized word is understood as that word if those letter are
different. All of this is case-insensitive. Also, in static output (PDF, PTX)
C<showInStatic> is 0. It is assumed that context makes the menu redundant.

By default, the choices are left in the order that you provide them,
but you can cause some or all of them to be ordered randomly by
enclosing those that should be randomized within a second set of
brackets.  For example

    $radio = PopUp([
                     "First Item",
                     ["Random 1","Random 2","Random 3"],
                     "Last Item"
                   ],
                   "Random 3"
                 );

will make a pop-up menu that has the first item always on top, the
next three ordered randomly, and the last item always on the bottom.
In this example

    $radio = PopUp([["Random 1","Random 2","Random 3"]],2);

all the entries are randomized, and the correct answer is "Random 3"
(the one with index 2 in the original, unrandomized list).  You can
have as many randomized groups, with as many static items in between,
as you want.

Note that pop-up menus can not contain mathematical notation, only
plain text.  This is because the PopUp object uses the browser's
native menus, and these can contain only text, not mathematics or
graphics.

To insert the pop-up menu into the problem text, use

    BEGIN_TEXT
    \{$popup->menu\}
    END_TEXT

and then

    ANS($popup->cmp);

to get the answer checker for the popup.

You can use the PopUp menu object in MultiAnswer objects.  This is
the reason for the pop-up menu's ans_rule method (since that is what
MultiAnswer calls to get answer rules).

There is one option, C<showInStatic>. It is 1 by default, except for
C<DropDownTF> it is 0. This option controls whether or not the menu
is displayed in a static output format (PDF hardcopy or PTX).

=cut

loadMacros('MathObjects.pl');

sub _parserPopUp_init { parser::PopUp::Init() };    # don't reload this file

#
#  The package that implements pop-up menus
#
package parser::PopUp;
our @ISA = ('Value::String');
my $context;

#
#  Setup the context and the PopUp() command
#
sub Init {
	#
	# make a context in which arbitrary strings can be entered
	#
	$context = Parser::Context->getCopy("Numeric");
	$context->{name} = "PopUp";
	$context->parens->clear();
	$context->variables->clear();
	$context->constants->clear();
	$context->operators->clear();
	$context->functions->clear();
	$context->strings->clear();
	$context->{pattern}{number}         = "^\$";
	$context->variables->{patterns}     = {};
	$context->strings->{patterns}{".*"} = [ -20, 'str' ];
	$context->{parser}{String}          = "parser::PopUp::String";
	$context->update;
	main::PG_restricted_eval('sub PopUp {parser::PopUp->new(@_)}');
	main::PG_restricted_eval('sub DropDown {parser::PopUp->DropDown(@_)}');
	main::PG_restricted_eval('sub DropDownTF {parser::PopUp->DropDownTF(@_)}');
}

#
#  Create a new PopUp object
#
sub new {
	my $self  = shift;
	my $class = ref($self) || $self;
	shift if Value::isContext($_[0]);    # remove context, if given (it is not used)
	my $choices = shift;
	my $value   = shift;
	my %options = @_;
	Value->Error("A PopUp's first argument should be a list of menu items")
		unless ref($choices) eq 'ARRAY';
	Value->Error("A PopUp's second argument should be the correct menu choice")
		unless defined($value) && $value ne "";
	$self = bless {
		data         => [$value],
		context      => $context,
		choices      => $choices,
		placeholder  => $options{placeholder}  // '',
		showInStatic => $options{showInStatic} // 1
	}, $class;
	$self->getChoiceOrder;
	my %choice;
	map { $choice{$_} = 1 } @{ $self->{choices} };

	if (!$choice{$value}) {
		my @order = map { ref($_) eq "ARRAY" ? @$_ : $_ } @$choices;
		if ($value =~ m/^\d+$/ && $order[$value]) { $self->{data}[0] = $order[$value] }
		else { Value->Error("The correct choice must be one of the PopUp menu items") }
	}
	return $self;
}

#
#  Get the choices into the correct order (randomizing where requested)
#
sub getChoiceOrder {
	my $self    = shift;
	my @choices = ();
	foreach my $choice (@{ $self->{choices} }) {
		if   (ref($choice) eq "ARRAY") { push(@choices, $self->randomOrder($choice)) }
		else                           { push(@choices, $choice) }
	}
	$self->{choices} = \@choices;
}

sub randomOrder {
	my $self    = shift;
	my $choices = shift;
	my %index   = (map { $main::PG_random_generator->rand => $_ } (0 .. scalar(@$choices) - 1));
	return (map { $choices->[ $index{$_} ] } main::PGsort(sub { $_[0] lt $_[1] }, keys %index));
}

#
#  Create the menu list
#
sub menu { shift->MENU(0, @_) }

sub MENU {
	my $self        = shift;
	my $extend      = shift;
	my $name        = shift;
	my $size        = shift;
	my %options     = @_;
	my @list        = @{ $self->{choices} };
	my $placeholder = $self->{placeholder};
	my $menu        = "";
	main::RECORD_IMPLICIT_ANS_NAME($name = main::NEW_ANS_NAME()) unless $name;
	my $answer_value = (defined($main::inputs_ref->{$name}) ? $main::inputs_ref->{$name} : '');
	my $label        = main::generate_aria_label($name);

	if ($main::displayMode =~ m/^HTML/) {
		$menu = main::tag(
			'span',
			class                       => 'text-nowrap',
			data_feedback_insert_elt    => $name,
			data_feedback_insert_method => 'append_content',
			main::tag(
				'select',
				class      => 'pg-select',
				name       => $name,
				id         => $name,
				aria_label => $label,
				size       => 1,
				(
					$placeholder
					? main::tag(
						'option',
						disabled => undef,
						selected => undef,
						value    => '',
						class    => 'tex2jax_ignore',
						$placeholder
						)
					: ''
					)
					. join(
						'',
						map {
							main::tag(
								'option', $_ eq $answer_value ? (selected => undef) : (),
								value => $_,
								class => 'tex2jax_ignore',
								$self->quoteHTML($_, 1)
							)
						} @list
					)
			)
		);
	} elsif ($main::displayMode eq 'PTX') {
		if ($self->{showInStatic}) {
			$menu = qq(<var form="popup" name="$name">) . "\n";
			foreach my $item (@list) {
				$menu .= '<li>';
				my $escaped_item = $item;
				$escaped_item =~ s/&/&amp;/g;
				$escaped_item =~ s/</&lt;/g;
				$escaped_item =~ s/>/&gt;/g;
				$menu .= $escaped_item . '</li>' . "\n";
			}
			$menu .= '</var>';
		} else {
			$menu = qq(<fillin name="$name"/>);
		}
	} elsif ($main::displayMode eq "TeX" && $self->{showInStatic}) {
		# if the total number of characters is not more than
		# 30 and not containing / or ] then we print out
		# the select as a string: [A/B/C]
		if (length(join('', @list)) < 25
			&& !grep(/(\/|\[|\])/, @list))
		{
			$menu = '[' . join('/', map { $self->quoteTeX($_) } @list) . ']';
		} else {
			#otherwise we print a bulleted list
			$menu = '\par\vtop{\def\bitem{\hbox\bgroup\indent\strut\textbullet\ \ignorespaces}\let\eitem=\egroup';
			$menu = "\n" . $menu . "\n";
			foreach my $option (@list) {
				$menu .= '\bitem ' . $self->quoteTeX($option) . "\\eitem\n";
			}
			$menu .= '\vskip3pt}' . "\n";
		}
	}
	main::RECORD_ANS_NAME($name, $answer_value) unless $extend;    # record answer name
	main::INSERT_RESPONSE($options{answer_group_name}, $name, $answer_value) if $extend;
	return $menu;
}

#
#  Answer rule is the menu list
#
sub ans_rule                 { shift->MENU(0, '', @_) }
sub named_ans_rule           { shift->MENU(0, @_) }
sub named_ans_rule_extension { shift->MENU(1, @_) }

#
# DropDown() variant of PopUp() with placeholder
#

sub DropDown {
	my $self    = shift;
	my $choices = shift;
	my $value   = shift;
	my %options = (
		placeholder => '?',
		@_
	);
	return parser::PopUp->new($choices, $value, %options);
}

#
# TrueFalse() variant of PopUp()
#

sub DropDownTF {
	my $self    = shift;
	my $value   = lc(main::maketext(shift));
	my %options = (
		showInStatic => 0,
		@_
	);
	my $true         = main::maketext('True');
	my $false        = main::maketext('False');
	my %sanitization = (
		lc($true)  => $true,
		1          => $true,
		lc($false) => $false,
		0          => $false
	);
	if (lc(substr($true, 0, 1)) ne lc(substr($false, 0, 1))) {
		$sanitization{ lc(substr($true,  0, 1)) } = $true;
		$sanitization{ lc(substr($false, 0, 1)) } = $false;
	}
	my $sanitized_value = $sanitization{$value};
	Value->Error("The value should be one of $true or $false") unless defined $sanitized_value;
	return parser::PopUp->DropDown([ $true, $false ], $sanitized_value, %options);
}

##################################################
#
#  Replacement for Parser::String that takes the
#  complete parse string as its value
#
package parser::PopUp::String;
our @ISA = ('Parser::String');

sub new {
	my $self = shift;
	my ($equation, $value, $ref) = @_;
	$value = $equation->{string};
	$self->SUPER::new($equation, $value, $ref);
}

##################################################

1;
