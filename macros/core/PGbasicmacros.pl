
=head1 NAME

PGbasicmacros.pl - A set of basic functions and constants for PG problems.

=head1 DESCRIPTION

This includes constants and basic functions for PG.

=cut

#####sub _PGbasicmacros_init { }
### In this file the _init subroutine is defined further down
### It actually initializes something!

# this is equivalent to use strict, but can be used within the Safe compartment

BEGIN { strict->import; }

my $displayMode;

my (
	$PAR,               $BR,       $BRBR,    $LQ,                  $RQ,
	$BM,                $EM,       $BDM,     $EDM,                 $LTS,
	$GTS,               $LTE,      $GTE,     $BEGIN_ONE_COLUMN,    $END_ONE_COLUMN,
	$SOL,               $SOLUTION, $HINT,    $COMMENT,             $US,
	$SPACE,             $NBSP,     $NDASH,   $MDASH,               $BLABEL,
	$ELABEL,            $BBOLD,    $EBOLD,   $BITALIC,             $EITALIC,
	$BUL,               $EUL,      $BCENTER, $ECENTER,             $BLTR,
	$ELTR,              $BKBD,     $EKBD,    $HR,                  $LBRACE,
	$RBRACE,            $LB,       $RB,      $DOLLAR,              $PERCENT,
	$CARET,             $PI,       $E,       $LATEX,               $TEX,
	$APOS,              @ALPHABET, $envir,   $PG_random_generator, $inputs_ref,
	$rh_sticky_answers, $r_ans_rule_count,
);

our %envir;

sub _PGbasicmacros_init {
	# The big problem is that at compile time in the cached Safe compartment
	# main:: has one definition, probably Safe::Root1::
	# At runtime main has another definition Safe::Rootx:: where x is > 1

	# It is important to
	# initialize the my variable version of $displayMode from the "runtime" version
	# of main::displayMode

	$displayMode = main::PG_restricted_eval(q!$main::displayMode!);

	# This is initializes the remaining variables in the runtime main:: compartment.

	main::PG_restricted_eval(<<'EndOfFile');
	$displayMode            = $displayMode;

	$main::PAR              = PAR();
	$main::BR               = BR();
	$main::BRBR             = BRBR();
	$main::LQ               = LQ();
	$main::RQ               = RQ();
	$main::BM               = BM();
	$main::EM               = EM();
	$main::BDM              = BDM();
	$main::EDM              = EDM();
	$main::LTS              = LTS();
	$main::GTS              = GTS();
	$main::LTE              = LTE();
	$main::GTE              = GTE();
	$main::BEGIN_ONE_COLUMN = BEGIN_ONE_COLUMN();
	$main::END_ONE_COLUMN   = END_ONE_COLUMN();
	$main::SOL              = SOLUTION_HEADING();
	$main::SOLUTION         = SOLUTION_HEADING();
	$main::HINT             = HINT_HEADING();
	$main::US               = US();
	$main::SPACE            = SPACE();
	$main::NBSP             = NBSP();
	$main::NDASH            = NDASH();
	$main::MDASH            = MDASH();
	$main::BLABEL           = BLABEL();
	$main::ELABEL           = ELABEL();
	$main::BBOLD            = BBOLD();
	$main::EBOLD            = EBOLD();
	$main::BITALIC          = BITALIC();
	$main::EITALIC          = EITALIC();
	$main::BUL              = BUL();
	$main::EUL              = EUL();
	$main::BCENTER          = BCENTER();
	$main::ECENTER          = ECENTER();
	$main::BLTR             = BLTR();
	$main::ELTR             = ELTR();
	$main::BKBD             = BKBD();
	$main::EKBD             = EKBD();
	$main::HR               = HR();
	$main::LBRACE           = LBRACE();
	$main::RBRACE           = RBRACE();
	$main::LB               = LB();
	$main::RB               = RB();
	$main::DOLLAR           = DOLLAR();
	$main::PERCENT          = PERCENT();
	$main::CARET            = CARET();
	$main::PI               = PI();
	$main::E                = E();
	$main::LATEX            = LATEX();
	$main::TEX              = TEX();
	$main::APOS             = APOS();
	@main::ALPHABET         = ('A'..'ZZ');
	%main::STICKY_ANSWERS   = ();

EndOfFile

	# Next we transfer the correct definitions in the main:: compartment to the local my variables
	# This can't be done inside the eval above because my variables seem to be invisible inside the eval

	$PAR              = PAR();
	$BR               = BR();
	$BRBR             = BRBR();
	$LQ               = LQ();
	$RQ               = RQ();
	$BM               = BM();
	$EM               = EM();
	$BDM              = BDM();
	$EDM              = EDM();
	$LTS              = LTS();
	$GTS              = GTS();
	$LTE              = LTE();
	$GTE              = GTE();
	$BEGIN_ONE_COLUMN = BEGIN_ONE_COLUMN();
	$END_ONE_COLUMN   = END_ONE_COLUMN();
	$SOL              = SOLUTION_HEADING();
	$SOLUTION         = SOLUTION_HEADING();
	$HINT             = HINT_HEADING();
	$US               = US();
	$SPACE            = SPACE();
	$NBSP             = NBSP();
	$NDASH            = NDASH();
	$MDASH            = MDASH();
	$BLABEL           = BLABEL();
	$ELABEL           = ELABEL();
	$BBOLD            = BBOLD();
	$EBOLD            = EBOLD();
	$BITALIC          = BITALIC();
	$EITALIC          = EITALIC();
	$BUL              = BUL();
	$EUL              = EUL();
	$BCENTER          = BCENTER();
	$ECENTER          = ECENTER();
	$BLTR             = BLTR();
	$ELTR             = ELTR();
	$BKBD             = BKBD();
	$EKBD             = EKBD();
	$HR               = HR();
	$LBRACE           = LBRACE();
	$RBRACE           = RBRACE();
	$LB               = LB();
	$RB               = RB();
	$DOLLAR           = DOLLAR();
	$PERCENT          = PERCENT();
	$CARET            = CARET();
	$PI               = PI();
	$E                = E();
	$LATEX            = LATEX();
	$TEX              = TEX();
	$APOS             = APOS();
	@ALPHABET         = ('A' .. 'ZZ');

	$envir               = PG_restricted_eval(q!\%main::envir!);
	$PG_random_generator = PG_restricted_eval(q!$main::PG_random_generator!);
	$inputs_ref          = $envir{inputs_ref};
	$rh_sticky_answers   = PG_restricted_eval(q!\%main::STICKY_ANSWERS!);
	$r_ans_rule_count    = PG_restricted_eval(q!\$ans_rule_count!);
}

=head2  Answer blank macros:

These produce answer blanks of various sizes or pop up lists or radio answer
buttons. The names for the answer blanks are generated and implicitly
associated with answer evaluators via the C<ANS> method.

    ans_rule(width)
    ans_radio_buttons(value1 => name1, value2, name2 => value3, name3 => ...)
    pop_up_list(@list)      # list consists of (value => label, PR => "Product rule", ...)
    pop_up_list([@list])    # list consists of values

In the last case, one can use C<pop_up_list(['?', 'yes', 'no'])> to produce a
pop-up list containing the three strings listed, and then use str_cmp to check
the answer.

To indicate the checked position of radio buttons put a '%' in front of the
value: C<ans_radio_buttons(1, 'Yes', '%2', 'No')> will have 'No' checked.

The following method is defined in F<PG.pl> for entering the answer evaluators
corresponding to answer rules with automatically generated names. The answer
evaluators are matched with the answer rules in the order in which they appear
on the page.

    ANS(ans_evaluator1, ans_evaluator2, ...);

These are more primitive macros which produce answer blanks for specialized
cases when complete control over the matching of answers blanks and answer
evaluators is desired.  The names of the answer blanks must be generated
manually, and it is best if they do NOT begin with the default answer prefix
(currently AnSwEr).

    NAMED_ANS_RULE(name, width)
    labeled_ans_rule(name, width)    # alias for NAMED_ANS_RULE
	NAMED_ANS_BOX(name, rows, cols)
    NAMED_ANS_RADIO(name, value, name)
    NAMED_ANS_RADIO_EXTENSION(name, value, name)
    NAMED_ANS_RADIO_BUTTONS(name, value1, name1, value2, name2, ...)
    NAMED_POP_UP_LIST($name, @list)     # list consists of (value => tag, PR => "Product rule", ...)
    NAMED_POP_UP_LIST($name, [@list])   # list consists of a list of values
                                        # (and each tag will be set to the corresponding value)

(Name is the name of the input, value is the value given to the input when
this option is selected, and label is the text printed next to the button or
check box. Check box variables can have multiple values.)

NAMED_ANS_RADIO_BUTTONS creates a sequence of NAMED_ANS_RADIO and
NAMED_ANS_RADIO_EXTENSION items which are output either as an array or, in
scalar context, as the array glued together with spaces. It is usually easier
to use this than to manually construct the radio buttons by hand. However,
sometimes extra flexibility is desiredin which case:

When entering radio buttons using the "NAMED" format, you should use
NAMED_ANS_RADIO button for the first button and then use
NAMED_ANS_RADIO_EXTENSION for the remaining buttons. NAMED_ANS_RADIO requires a
matching answer evaluator, while NAMED_ANS_RADIO_EXTENSION does not. The name
used for NAMED_ANS_RADIO_EXTENSION should match the name used for
NAMED_ANS_RADIO (and the associated answer evaluator).

The following method is defined for entering the answer evaluators corresponding
to answer rules. The answer evaluators are matched with the answer rules in the
order in which they appear on the page.

    NAMED_ANS(name1 => ans_evaluator1, name2 => ans_evaluator2, ...);

Auxiliary macros defined in PG.pl:

=over

=item NEW_ANS_NAME()

Produces a new anonymous answer blank name by appending a number to the prefix
(AnSwEr).

=item ANS_NUM_TO_NAME(number)

Prepends the prefix (AnSwEr) to the number, but does nothing else.

=item RECORD_ANS_NAME(name)

Records the order in which the answer blank is rendered. All answer rules must
be recorded by this method. All named answer rule methods in this macro do this.
Most answer rules created elsewhere call a named answer rule method in this
macro to handle this.

=item RECORD_IMPLICIT_ANS_NAME(name)

Records answer names which are to be implicitly associated with an answer This
is called by the internal answer rule methods, but must be called for all answer
rules constructed elsewhere as well. After this is called C<RECORD_ANS_NAME>
must be called as well. Usually the appropriate named answer rule method should
be called which will do this.

=back

Deprecated macro (still used by many problems):

    ANS_RULE(number, width);    # equivalent to ans_rule(width) -- number is ignored

=cut

# Alias for NAMED_ANS_RULE
sub labeled_ans_rule {
	my ($name, $col, %options) = @_;
	return NAMED_ANS_RULE($name, $col, %options);
}

sub NAMED_ANS_RULE {
	my ($name, $col, %options) = @_;
	$col ||= 20;
	my $answer_value = $inputs_ref->{$name} // '';
	$answer_value = [ split("\0", $answer_value) ] if $answer_value =~ /\0/;

	if (ref($answer_value) eq 'ARRAY') {
		my @answers = @$answer_value;
		$answer_value = shift(@answers) // '';                  # Use up the first answer.
		$rh_sticky_answers->{$name} = \@answers;                # Store the rest.
	}

	$name = RECORD_ANS_NAME($name, $answer_value);
	my $previous_name = "previous_$name";
	$name          = ($envir{use_opaque_prefix}) ? "%%IDPREFIX%%$name"          : $name;
	$previous_name = ($envir{use_opaque_prefix}) ? "%%IDPREFIX%%$previous_name" : $previous_name;

	my $tcol = $col / 2 > 3 ? $col / 2 : 3;    # get max
	$tcol = $tcol < 40 ? $tcol : 40;           # get min

	return MODES(
		TeX => "{\\answerRule[$name]{$tcol}}",
		# Note: codeshard is used in the css to identify input elements that come from pg.
		HTML => tag(
			'div',
			class => 'text-nowrap d-inline',
			tag(
				'input',
				type           => 'text',
				class          => 'codeshard',
				size           => $col,
				name           => $name,
				id             => $name,
				aria_label     => $options{aria_label} // generate_aria_label($name),
				dir            => 'auto',
				autocomplete   => 'off',
				autocapitalize => 'off',
				spellcheck     => 'false',
				value          => $answer_value
			)
			)
			. tag('input', type => 'hidden', name => $previous_name, value => $answer_value),
		PTX => qq!<fillin name="$name" characters="$col" />!
	);
}

sub NAMED_HIDDEN_ANS_RULE {
	my ($name, $col) = @_;
	$col ||= 20;
	my $answer_value = $inputs_ref->{$name} // '';
	$answer_value = [ split("\0", $answer_value) ] if $answer_value =~ /\0/;

	if (ref($answer_value) eq 'ARRAY') {
		my @answers = @$answer_value;
		$answer_value = shift(@answers) // '';                  # Use up the first answer.
		$rh_sticky_answers->{$name} = \@answers;                # Store the rest.
	}

	$answer_value =~ s/\s+/ /g;                                 # Remove excessive whitespace from student answer.

	$name = RECORD_ANS_NAME($name, $answer_value);

	my $tcol = $col / 2 > 3 ? $col / 2 : 3;                     # get max
	$tcol = $tcol < 40 ? $tcol : 40;                            # get min

	return MODES(
		TeX  => "{\\answerRule[$name]{$tcol}}",
		HTML => tag('input', type => 'hidden', name => $name, id => $name, value => $answer_value)
			. tag('input', type => 'hidden', name => "previous_$name", id => "previous_$name", value => $answer_value),
		PTX => '',
	);
}

sub NAMED_ANS_RULE_EXTENSION {
	my ($name, $col, %options) = @_;

	# $answer_group_name is the name of the parent answer group
	# the group name is usually the same as the answer blank name
	# when there is only one answer blank.
	my $answer_group_name = $options{answer_group_name} // '';
	unless ($answer_group_name) {
		WARN_MESSAGE(
			"Error in NAMED_ANSWER_RULE_EXTENSION: every call to this subroutine needs
			to have \$options{answer_group_name} defined. For a single answer blank this is
			usually the same as the answer blank name. Answer blank name: $name"
		);
	}

	my $answer_value = $inputs_ref->{$name} // '';
	if (defined $rh_sticky_answers->{$name}) {
		$answer_value = shift(@{ $rh_sticky_answers->{$name} }) // '';
	}

	$answer_value =~ s/\s+/ /g;    # remove excessive whitespace from student answer

	INSERT_RESPONSE($answer_group_name, $name, $answer_value);

	my $tcol = $col / 2 > 3 ? $col / 2 : 3;    # get max
	$tcol = $tcol < 40 ? $tcol : 40;           # get min

	return MODES(
		TeX  => "{\\answerRule[$name]{$tcol}}",
		HTML => tag(
			'input',
			type           => 'text',
			class          => 'codeshard',
			size           => $col,
			name           => $name,
			id             => $name,
			aria_label     => $options{aria_label} // generate_aria_label($name),
			dir            => 'auto',
			autocomplete   => 'off',
			autocapitalize => 'off',
			spellcheck     => 'false',
			value          => $answer_value
			)
			. tag('input', type => 'hidden', name => "previous_$name", id => "previous_$name", value => $answer_value),
		PTX => qq!<fillin name="$name" characters="$col" />!,
	);
}

# Deprecated
sub ANS_RULE {
	my ($number, $col) = @_;
	my $name = NEW_ANS_NAME();
	RECORD_IMPLICIT_ANS_NAME($name);
	return NAMED_ANS_RULE($name, $col);
}

sub NAMED_ANS_BOX {
	my ($name, $row, $col, %options) = @_;
	$row //= 10;
	$col //= 80;

	my $height       = .07 * $row;
	my $answer_value = $inputs_ref->{$name} // '';
	$name = RECORD_ANS_NAME($name, $answer_value);
	my $label = $options{aria_label} // generate_aria_label($name);

	return MODES(
		TeX  => qq!\\vskip $height in \\hrulefill\\quad !,
		HTML => tag(
			'div',
			class => 'text-nowrap d-inline',
			tag(
				'textarea',
				name       => $name,
				id         => $name,
				rows       => $row,
				cols       => $col,
				aria_label => $label,
				encode_pg_and_html($answer_value)
			)
			)
			. tag('input', type => 'hidden', name => "previous_$name", value => $answer_value),
		PTX => '<var name="' . "$name" . '" height="' . "$row" . '" width="' . "$col" . '" />',
	);
}

sub NAMED_ANS_RADIO {
	my ($name, $value, $tag, $extend, %options) = @_;

	my $checked = '';
	if ($value =~ /^\%/) {
		$value =~ s/^\%//;
		$checked = 'CHECKED';
	}
	$checked = $inputs_ref->{$name} eq $value ? 'CHECKED' : '' if defined $inputs_ref->{$name};

	$name = RECORD_ANS_NAME($name, { $value => $checked }) unless $extend;
	INSERT_RESPONSE($options{answer_group_name}, $name, { $value => $checked }) if $extend;

	return MODES(
		TeX  => qq!\\item{$tag}\n!,
		HTML => tag(
			'label',
			tag(
				'input',
				type  => 'radio',
				name  => $name,
				id    => $name,
				value => $value,
				$checked ? (checked => undef) : (),
				%{ $options{attributes} }
				)
				. $tag
		),
		PTX => '<li>' . "$tag" . '</li>' . "\n",
	);
}

sub NAMED_ANS_RADIO_EXTENSION {
	my ($name, $value, $tag, %options) = @_;

	my $checked = '';
	if ($value =~ /^\%/) {
		$value =~ s/^\%//;
		$checked = 'CHECKED';
	}
	$checked = $inputs_ref->{$name} eq $value ? 'CHECKED' : '' if defined $inputs_ref->{$name};

	EXTEND_RESPONSE($options{answer_group_name} // $name, $name, $value, $checked);

	return MODES(
		TeX  => qq!\\item{$tag}\n!,
		HTML => tag(
			'label',
			tag(
				'input',
				type  => 'radio',
				name  => $name,
				id    => $options{id} // "${name}_$value",
				value => $value,
				$checked ? (checked => undef) : (),
				%{ $options{attributes} }
				)
				. $tag
		),
		PTX => '<li>' . "$tag" . '</li>' . "\n",
	);
}

sub NAMED_ANS_RADIO_BUTTONS {
	my ($name, $value, $tag, @buttons) = @_;

	my @out;
	push(@out, NAMED_ANS_RADIO($name, $value, $tag));
	my $label = generate_aria_label($name);
	my $count = 2;
	while (@buttons) {
		$value = shift @buttons;
		$tag   = shift @buttons;
		push(@out, NAMED_ANS_RADIO_EXTENSION($name, $value, $tag, aria_label => $label . "option $count "));
		$count++;
	}
	return wantarray ? @out : join(" ", @out);
}

##############################################
#   generate_aria_label( $name )
#   takes the name of an ANS_RULE and generates an appropriate
#   aria label for screen readers
##############################################

sub generate_aria_label {
	my $name  = shift;
	my $label = '';

	# if we dont have an AnSwEr type name then we do the best we can
	if ($name !~ /AnSwEr\d+/) {
		return maketext('answer [_1] ', $name);
	}

	# check for quiz prefix
	if ($name =~ /^Q\d+/ || $name =~ /^MaTrIx_Q\d+/) {
		$name =~ s/Q0*(\d+)_//;
		$label .= maketext('problem [_1] ', $1);
	}

	# get answer number
	$name =~ /AnSwEr0*(\d+)/;
	$label .= maketext('answer [_1] ', $1);

	# check for Multianswer
	if ($name =~ /MuLtIaNsWeR_/) {
		$name =~ s/MuLtIaNsWeR_//;
		$name =~ /AnSwEr(\d+)_(\d+)/;
		$label .= maketext('part [_1] ', $2 + 1);
	}

	# check for Matrix
	if ($name =~ /^MaTrIx_/) {
		$name =~ /_(\d+)_(\d+)$/;
		$label .= maketext('row [_1] column [_2] ', $1 + 1, $2 + 1);
	}

	return $label;
}

##############################################
#   contained_in( $elem, $array_reference or null separated string);
#   determine whether element is equal
#   ( in the sense of eq,  not ==, ) to an element in the array.
##############################################
sub contained_in {
	my $element     = shift;
	my @input_list  = @_;
	my @output_list = ();
	# Expand the list -- convert references to  arrays to arrays
	# Convert null separated strings to arrays
	foreach my $item (@input_list) {
		if ($item =~ /\0/) {
			push @output_list, split('\0', $item);
		} elsif (ref($item) =~ /ARRAY/) {
			push @output_list, @{$item};
		} else {
			push @output_list, $item;
		}
	}

	my @match_list = grep { $element eq $_ } @output_list;
	if (@match_list) {
		return 1;
	} else {
		return 0;
	}
}

sub NAMED_ANS_CHECKBOX {
	my ($name, $value, $tag, $extend, %options) = @_;

	my $checked = '';
	if ($value =~ /^\%/) {
		$value =~ s/^\%//;
		$checked = 'CHECKED';
	}

	# If multiple boxes are checked then the $inputs_ref->{name} will be a null separated string
	# or a reference to an array.
	$checked = contained_in($value, $inputs_ref->{$name}) ? 'CHECKED' : '' if defined $inputs_ref->{$name};

	$name = RECORD_ANS_NAME($name, { $value => $checked }) unless $extend;
	INSERT_RESPONSE($options{answer_group_name}, $name, { $value => $checked }) if $extend;

	return MODES(
		TeX  => qq!\\item{$tag}\n!,
		HTML => tag(
			'label',
			tag(
				'input',
				type       => 'checkbox',
				name       => $name,
				id         => $name,
				aria_label => $options{aria_label} // (generate_aria_label($name) . maketext('option [_1] ', 1)),
				value      => $value,
				$checked ? (checked => undef) : (),
				%{ $options{attributes} }
				)
				. $tag
		),
		PTX => "<li>$tag</li>\n",
	);
}

sub NAMED_ANS_CHECKBOX_OPTION {
	my ($name, $value, $tag, %options) = @_;

	my $checked = '';
	if ($value =~ /^\%/) {
		$value =~ s/^\%//;
		$checked = 'CHECKED';
	}
	$checked = contained_in($value, $inputs_ref->{$name}) ? 'CHECKED' : '' if defined $inputs_ref->{$name};

	EXTEND_RESPONSE($options{answer_group_name} // $name, $name, $value, $checked);

	return MODES(
		TeX  => qq!\\item{$tag}\n!,
		HTML => tag(
			'label',
			tag(
				'input',
				type       => 'checkbox',
				name       => $name,
				id         => $options{id}         // "${name}_$value",
				aria_label => $options{aria_label} // generate_aria_label($name),
				value      => $value,
				$checked ? (checked => undef) : (),
				%{ $options{attributes} }
				)
				. $tag
		),
		PTX => "<li>$tag</li>\n",
	);
}

sub NAMED_ANS_CHECKBOX_BUTTONS {
	my ($name, $value, $tag, @buttons) = @_;

	my @out;
	push(@out, NAMED_ANS_CHECKBOX($name, $value, $tag));
	my $label = generate_aria_label($name);
	my $count = 2;
	while (@buttons) {
		$value = shift @buttons;
		$tag   = shift @buttons;
		push(@out,
			NAMED_ANS_CHECKBOX_OPTION($name, $value, $tag, aria_label => $label . maketext('option [_1] ', $count))
		);
		$count++;
	}

	return wantarray ? @out : join(" ", @out);
}

sub ans_rule {
	my $len  = shift;
	my $name = NEW_ANS_NAME();
	RECORD_IMPLICIT_ANS_NAME($name);
	return NAMED_ANS_RULE($name, $len || 20);
}

sub ans_radio_buttons {
	my $name = NEW_ANS_NAME();
	RECORD_IMPLICIT_ANS_NAME($name);
	my @radio_buttons = NAMED_ANS_RADIO_BUTTONS($name, @_);

	if ($displayMode eq 'TeX') {
		$radio_buttons[0] = "\n\\begin{itemize}\n" . $radio_buttons[0];
		$radio_buttons[$#radio_buttons] .= "\n\\end{itemize}\n";
	} elsif ($displayMode eq 'PTX') {
		$radio_buttons[0] = '<var form="buttons">' . "\n" . $radio_buttons[0];
		$radio_buttons[$#radio_buttons] .= '</var>';
	} else {
		$radio_buttons[0] =
			qq{<div class="radio-buttons-container" }
			. qq{data-feedback-insert-element="$name" data-feedback-insert-method="append_content" }
			. qq{data-feedback-btn-add-class="ms-3">$radio_buttons[0]};
		$radio_buttons[-1] .= "</div>";
	}

	return wantarray ? @radio_buttons : join(" ", @radio_buttons);
}

sub ans_checkbox {
	my $name = NEW_ANS_NAME();
	RECORD_IMPLICIT_ANS_NAME($name);
	my @checkboxes = NAMED_ANS_CHECKBOX_BUTTONS($name, @_);

	if ($displayMode eq 'TeX') {
		$checkboxes[0] = "\n\\begin{itemize}\n" . $checkboxes[0];
		$checkboxes[$#checkboxes] .= "\n\\end{itemize}\n";
	} elsif ($displayMode eq 'PTX') {
		$checkboxes[0] = '<var form="checkboxes">' . "\n" . $checkboxes[0];
		$checkboxes[$#checkboxes] .= '</var>';
	} else {
		$checkboxes[0] =
			qq{<div class="checkboxes-container" }
			. qq{data-feedback-insert-element="$name" data-feedback-insert-method="append_content" }
			. qq{data-feedback-btn-add-class="ms-3">$checkboxes[0]};
		$checkboxes[-1] .= '</div>';
	}

	return wantarray ? @checkboxes : join(" ", @checkboxes);
}

sub ans_box {
	my ($row, $col) = @_;
	my $name = NEW_ANS_NAME();
	RECORD_IMPLICIT_ANS_NAME($name);
	return NAMED_ANS_BOX($name, $row || 5, $col || 80);
}

# this is legacy code; use ans_checkbox instead
sub checkbox {
	my %options = @_;
	qq!<INPUT TYPE="checkbox" NAME="$options{'-name'}" VALUE="$options{'-value'}">$options{'-label'}!;
}

sub NAMED_POP_UP_LIST {
	my ($name, @list) = @_;

	my %options      = ref($list[0]) eq 'ARRAY' ? (map { $_ => $_ } @{ $list[0] }) : @list;
	my @ordered_keys = ref($list[0]) eq 'ARRAY' ? @{ $list[0] } : @list[ grep { !($_ % 2) } 0 .. $#list ];

	my $moodle_prefix = $envir{use_opaque_prefix} ? '%%IDPREFIX%%' : '';

	my $answer_value = $inputs_ref->{$name} // '';
	$name = RECORD_ANS_NAME($name, $answer_value);

	if ($displayMode eq 'HTML_MathJax'
		|| $displayMode eq 'HTML_dpng'
		|| $displayMode eq 'HTML'
		|| $displayMode eq 'HTML_tth')
	{
		return tag(
			'div',
			class => 'text-nowrap d-inline',
			tag(
				'select',
				class => 'pg-select',
				name  => "$moodle_prefix$name",
				id    => "$moodle_prefix$name",
				size  => 1,
				join(
					'',
					map { tag('option', value => $_, $_ eq $answer_value ? (selected => undef) : (), $options{$_}) }
						@ordered_keys
				)
			)
		);
	} elsif ($displayMode eq "TeX") {
		return "\\fbox{?}";
	} elsif ($displayMode eq "PTX") {
		return '<var form="popup">' . "\n" . join('', map {"<li>$options{$_}</li>\n"} keys %options) . '</var>';
	}
}

sub pop_up_list {
	my @list = @_;
	my $name = NEW_ANS_NAME();
	RECORD_IMPLICIT_ANS_NAME($name);
	return NAMED_POP_UP_LIST($name, @list);
}

=head2  answer_matrix

Usage:

    \[ \{ answer_matrix(rows, columns, width_of_ans_rule, @options) \} \]

Creates an array of answer blanks and passes it to display_matrix which returns
text which represents the matrix in TeX format used in math display mode. Answers
are then passed back to whatever answer evaluators you write at the end of the problem.
(note, if you have an m x n matrix, you will need mn answer evaluators, and they will be
returned to the evaluaters starting in the top left hand corner and proceed to the left
and then at the end moving down one row, just as you would read them.)

The options are passed on to display_matrix.

Note (7/21/2017) The above usage does not work. Omitting the \[ \] works, but also must
load PGmatrixmacros.pl to get display_matrix used below

=cut

sub answer_matrix {
	my ($m, $n, $width, @options) = @_;
	my @array;
	for (my $i = 0; $i < $m; $i += 1) {
		my @row_array;

		for (my $i = 0; $i < $n; $i += 1) {
			push @row_array, ans_rule($width);
		}
		push @array, \@row_array;
	}
	# display_matrix hasn't been loaded into the cache safe compartment
	# so we need to refer to the subroutine in this way to make
	# sure that main is defined correctly.
	my $ra_local_display_matrix = PG_restricted_eval(q!\&main::display_matrix!);
	return &$ra_local_display_matrix(\@array, @options);
}

sub NAMED_ANS_ARRAY_EXTENSION {
	my ($name, $col, %options) = @_;
	$col ||= 20;

	my $answer_value = $inputs_ref->{$name} // '';
	$answer_value = [ split("\0", $answer_value) ] if $answer_value =~ /\0/;

	if (ref($answer_value) eq 'ARRAY') {
		my @answers = @$answer_value;
		$answer_value = shift(@answers);
		$answer_value = '' unless defined($answer_value);
	}

	my $label = $options{aria_label} // generate_aria_label($name);

	# the name of the answer evaluator controlling this collection of responses.
	my $answer_group_name;

	# catch deprecated use of ans_label to pass answer_group_name
	if (defined($options{ans_label})) {
		WARN_MESSAGE(
			"Error in NAMED_ANS_ARRAY_EXTENSION: the answer group name should be passed in ",
			"\%options using answer_group_name=>\$answer_group_name",
			"The use of ans_label=>\$answer_group_name is deprecated.",
			"Answer blank name: $name"
		);
		$answer_group_name = $options{ans_label};
	}
	if (defined($options{answer_group_name})) {
		$answer_group_name = $options{answer_group_name};
	}

	if ($answer_group_name) {
		INSERT_RESPONSE($options{answer_group_name}, $name, $answer_value);
	} else {
		WARN_MESSAGE("Error: answer_group_name must be defined for $name");
	}

	my $tcol = $col / 2 > 3 ? $col / 2 : 3;    # get max
	$tcol = $tcol < 40 ? $tcol : 40;           # get min

	return MODES(
		TeX  => "{\\answerRule[$name]{$tcol}}",
		HTML => tag(
			'input',
			type           => 'text',
			size           => $col,
			name           => $name,
			id             => $name,
			class          => 'codeshard',
			aria_label     => $label,
			autocomplete   => 'off',
			autocapitalize => 'off',
			spellcheck     => 'false',
			value          => $answer_value
		),
		PTX => qq!<fillin name="$name" characters="$col" />!,
	);
}

sub ans_array {
	my ($m, $n, $col, @options) = @_;
	$col ||= 20;

	my $ans_label = NEW_ANS_NAME();
	RECORD_IMPLICIT_ANS_NAME($ans_label);

	$main::vecnum = -1;
	CLEAR_RESPONSES($ans_label);

	my @array;
	for (my $i = 0; $i < $n; $i += 1) {
		my $name = NEW_ANS_ARRAY_NAME_EXTENSION(0, $i);
		$array[0][$i] = NAMED_ANS_ARRAY_EXTENSION($name, $col, ans_label => $ans_label);
	}

	for (my $j = 1; $j < $m; $j += 1) {
		for (my $i = 0; $i < $n; $i += 1) {
			my $name = NEW_ANS_ARRAY_NAME_EXTENSION($j, $i);
			$array[$j][$i] = NAMED_ANS_ARRAY_EXTENSION($name, $col, ans_label => $ans_label);
		}
	}
	my $ra_local_display_matrix = PG_restricted_eval(q!\&main::display_matrix!);

	return $ra_local_display_matrix->(\@array, @options);
}

# end answer blank macros

=head2 Hints, solutions, and statement macros

    solution('text', 'text2', ...);
    SOLUTION('text', 'text2', ...); # equivalent to TEXT(solution(...));

    hint('text', 'text2', ...);
    HINT('text', 'text2', ...);    # equivalent to TEXT("$BR$HINT" . hint(@_) . "$BR") if hint(@_);

    statement('text');
    STATEMENT('text');            # equivalent to TEXT(statement(...));

statement takes a string, probably from EV3P, and possibly wraps opening and closing
content, paralleling one feature of solution and hint.

If $envir{showSolutions} is set to 1 then the solution is displayed.

If $envir{showHints} is set to 1 then the hint is displayed.

=cut

# $main::solutionExists is passed to processProblem which displays a "show Solution" button
# when a solution is available for viewing

sub escapeSolutionHTML {
	my $str = join('', @_);
	$str = $main::PG->encode_base64($str);
	$str;
}

sub solution {
	my @in = @_;
	$main::solutionExists = 1;
	return $envir->{showSolutions} ? join('', @in) : '';
}

sub SOLUTION {
	my $solution_body = solution(@_);
	return "" if $solution_body eq "";

	if ($displayMode =~ /HTML/) {
		TEXT(tag(
			'div',
			class => 'solution accordion my-3',
			tag(
				'details',
				class => 'accordion-item',
				tag(
					'summary',
					class => 'accordion-button collapsed text-primary fw-bold py-2',
					tag('span', class => 'accordion-header user-select-none', SOLUTION_HEADING())
					)
					. tag(
						'div',
						class => 'accordion-collapse collapse',
						tag('div', class => 'accordion-body', $solution_body)
					)
			)
		));
	} elsif ($displayMode =~ /TeX/) {
		TEXT(
			"\n%%% BEGIN SOLUTION\n"
			,    #Marker used in PreTeXt LaTeX extraction; contact alex.jordan@pcc.edu before modifying
			"\\par\\smallskip", SOLUTION_HEADING(), $solution_body, "\\par\\medskip",
			"\n%%% END SOLUTION\n" #Marker used in PreTeXt LaTeX extraction; contact alex.jordan@pcc.edu before modifying
		);
	} elsif ($displayMode =~ /PTX/) {
		TEXT('<solution>', "\n", $solution_body, "\n", '</solution>', "\n\n");
	} else {
		TEXT($PAR, $solution_body, $PAR);
	}
}

sub hint {
	my @in = @_;
	$main::hintExists = 1;
	return $envir->{showHints} ? join('', @in) : '';
}

sub HINT {
	my $hint_body = hint(@_);
	return unless $hint_body;
	if ($displayMode =~ /HTML/) {
		TEXT(tag(
			'div',
			class => 'hint accordion my-3',
			tag(
				'details',
				class => 'accordion-item',
				tag(
					'summary',
					class => 'accordion-button collapsed text-primary fw-bold py-2',
					tag('span', class => 'accordion-header user-select-none', HINT_HEADING())
					)
					. tag(
						'div',
						class => 'accordion-collapse collapse',
						tag('div', class => 'accordion-body', $hint_body)
					)
			)
		));
	} elsif ($displayMode =~ /TeX/) {
		TEXT(
			"\n%%% BEGIN HINT\n"
			,    #Marker used in PreTeXt LaTeX extraction; contact alex.jordan@pcc.edu before modifying
			"\\par\\smallskip", HINT_HEADING(), $hint_body, "\\par\\medskip",
			"\n%%% END HINT\n"    #Marker used in PreTeXt LaTeX extraction; contact alex.jordan@pcc.edu before modifying
		);
	} elsif ($displayMode =~ /PTX/) {
		TEXT('<hint>', "\n", $hint_body, "\n", '</hint>', "\n\n");
	} else {
		TEXT($PAR, HINT_HEADING(), $BR . $hint_body . $PAR);
	}
}

sub statement {
	my @in  = @_;
	my $out = join(' ', @in);
	$out;
}

sub STATEMENT {
	if ($displayMode eq 'PTX') { TEXT('<statement>', "\n", statement(@_), "\n", '</statement>', "\n"); }
	else                       { TEXT(statement(@_)) }
}

# End hints and solutions and statement macros
#################################

=head2 Comments to instructors

	COMMENT('text', 'text2', ...);

Takes the text to be lines of a comment to be shown only
in the Library Browser below the rendered problem.

The function COMMENT stores the needed html in the variable
pgComment, which gets transfered to the flag 'comment' in PG_FLAGS.

=cut

# Add a comment which will display in the Library browser
#  Currently, the only output is html

sub COMMENT {
	my @in  = @_;
	my $out = join("$BR", @in);
	$out = '<div class=\"AuthorComment\">' . $out . '</div>';
	PG_restricted_eval(q!$main::pgComment .= "! . $out . q!"!);
	return ('');
}

#################################
#	Produces a random number between $begin and $end with increment 1.
#	You do not have to worry about integer or floating point types.

=head2 Pseudo-random number generator

Usage:

    random(0, 5, .1)          # produces a random number between 0 and 5 in increments of .1
    non_zero_random(0, 5, .1) # gives a non-zero random number

    list_random(2, 3, 5, 6, 7, 8, 10) # produces random value from the list
    list_random(2, 3, (5..8), 10) # does the same thing

    SRAND(seed)     # resets the main random generator -- use very cautiously

SRAND(time) will create a different problem everytime it is called.  This makes it difficult
to check the answers :-).

SRAND($envir->{'inputs_ref'}->{'key'} ) will create a different problem for each login session.
This is probably what is desired.

=cut

sub random {
	my ($begin, $end, $incr) = @_;
	$PG_random_generator->random($begin, $end, $incr);
}

sub non_zero_random {    ##gives a non-zero random number
	my (@arguments) = @_;
	my $a           = 0;
	my $i           = 100;    #safety counter
	while ($a == 0 && (0 < $i--)) {
		$a = random(@arguments);
	}
	$a;
}

sub list_random {
	my @li = @_;
	return $li[ random(1, scalar(@li)) - 1 ];
}

sub SRAND {    # resets the main random generator -- use cautiously
	my $seed = shift;
	$PG_random_generator->srand($seed);
}

# display macros

=head2 Display Macros

These macros produce different output depending on the display mode being used to show
the problem on the screen, or whether the problem is being converted to TeX to produce
a hard copy output.

    MODES   ( TeX        => "Output this in TeX mode",
              HTML       => "output this in HTML mode",
              HTML_tth   => "output this in HTML_tth mode",
              HTML_dpng  => "output this in HTML_dpng mode",
             )

    M3      (tex_version, latex2html_version, html_version) #obsolete
            Note the LaTeX2HTML version remains for backward compatibility.

=cut

sub M3 {
	my ($tex, $l2h, $html) = @_;
	MODES(TeX => $tex, HTML => $html, HTML_tth => $html, HTML_dpng => $html);
}

# MODES() is now table driven
our %DISPLAY_MODE_FAILOVER = (
	TeX          => [],
	HTML         => [],
	PTX          => ["HTML"],
	HTML_tth     => ["HTML"],
	HTML_dpng    => [ "HTML_tth",  "HTML" ],
	HTML_MathJax => [ "HTML_dpng", "HTML_tth", "HTML" ]
);

# This replaces M3.  You can add new modes at will to this one.
sub MODES {
	my %options = @_;

	# is a string supplied for the current display mode? if so, return it
	return $options{$main::displayMode} if defined $options{$main::displayMode};

	# otherwise, fail over to backup modes
	my @backup_modes;
	if (exists $DISPLAY_MODE_FAILOVER{$main::displayMode}) {
		@backup_modes = @{ $DISPLAY_MODE_FAILOVER{$main::displayMode} };
		foreach my $mode (@backup_modes) {
			return $options{$mode} if defined $options{$mode};
		}
	}
	warn "ERROR in defining MODES: neither display mode '$main::displayMode' nor",
		" any fallback modes (", join(", ", @backup_modes), ") supplied.";
}

# end display macros

=head2  Display constants

	@ALPHABET           ALPHABET()           capital letter alphabet -- ALPHABET[0] = 'A'
	$PAR                PAR()                paragraph character (\par or <p>)
	$BR                 BR()                 line break character
	$BRBR               BRBR()               line break character
	$LQ                 LQ()                 left double quote
	$RQ                 RQ()                 right double quote
	$BM                 BM()                 begin math
	$EM                 EM()                 end math
	$BDM                BDM()                begin display math
	$EDM                EDM()                end display math
	$LTS                LTS()                strictly less than
	$GTS                GTS()                strictly greater than
	$LTE                LTE()                less than or equal
	$GTE                GTE()                greater than or equal
	$BEGIN_ONE_COLUMN   BEGIN_ONE_COLUMN()   begin one-column mode
	$END_ONE_COLUMN     END_ONE_COLUMN()     end one-column mode
	$SOL                SOLUTION_HEADING()   solution headline
	$SOLUTION           SOLUTION_HEADING()   solution headline
	$HINT               HINT_HEADING()       hint headline
	$US                 US()                 underscore character
	$SPACE              SPACE()              space character (tex and latex only)
	$NBSP               NBSP()               non breaking space character
	$NDASH              NDASH()              en dash character
	$MDASH              MDASH()              em dash character
	$BLABEL             BLABEL()             begin label (for input)
	$ELABEL             ELABEL()             end label (for input)
	$BBOLD              BBOLD()              begin bold typeface
	$EBOLD              EBOLD()              end bold typeface
	$BITALIC            BITALIC()            begin italic typeface
	$EITALIC            EITALIC()            end italic typeface
	$BUL                BUL()                begin underlined type
	$EUL                EUL()                end underlined type
	$BCENTER            BCENTER()            begin centered environment
	$ECENTER            ECENTER()            end centered environment
	$BLTR               BLTR()               begin left to right environment
	$ELTR               ELTR()               end left to right environment
	$BKBD               BKBD()               begin "keyboard" input text
	$EKBD               EKBD()               end "keyboard" input text
	$HR                 HR()                 horizontal rule
	$LBRACE             LBRACE()             left brace
	$LB                 LB ()                left brace
	$RBRACE             RBRACE()             right brace
	$RB                 RB ()                right brace
	$DOLLAR             DOLLAR()             a dollar sign
	$PERCENT            PERCENT()            a percent sign
	$CARET              CARET()              a caret sign
	$PI                 PI()                 the number pi
	$E                  E()                  the number e
	$LATEX              LATEX()              the LaTeX logo
	$TEX                TEX()                the TeX logo
	$APOS               APOS()               an apostrophe

=cut

# A utility variable.  Notice that "B" = $ALPHABET[1] and
# "ABCD" = @ALPHABET[0..3].

sub ALPHABET {
	('A' .. 'ZZ')[@_];
}

###############################################################
# Some constants which are different in tex and in HTML
# The order of arguments is TeX, HTML
# Adopted Davide Cervone's improvements to PAR, LTS, GTS, LTE, GTE, LBRACE, RBRACE, LB, RB. 7-14-03 AKP
sub PAR {
	MODES(
		TeX  => '\\vskip\\baselineskip ',
		HTML => '<div style="margin-top:1em"></div>',
		PTX  => "\n\n"
	);
}
#sub BR { MODES( TeX => '\\par\\noindent ', HTML => '<BR>'); };
# Alternate definition of BR which is slightly more flexible and gives more white space in printed output
# which looks better but kills more trees.
sub BR {
	MODES(
		TeX  => '\\leavevmode\\\\\\relax ',
		HTML => '<BR>',
		PTX  => "\n\n"
	);
}

sub BRBR {
	MODES(
		TeX  => '\\leavevmode\\\\\\relax \\leavevmode\\\\\\relax ',
		HTML => '<P>',
		PTX  => "\n"
	);
}
sub LQ { MODES(TeX => "\\lq\\lq{}", HTML         => '&quot;', PTX  => '<lq/>'); }
sub RQ { MODES(TeX => "\\rq\\rq{}", HTML         => '&quot;', PTX  => '<rq/>'); }
sub BM { MODES(TeX => '\\(',        HTML_MathJax => '\\(',    HTML => '', PTX => '<m>'); };     # begin math mode
sub EM { MODES(TeX => '\\)',        HTML_MathJax => '\\)',    HTML => '', PTX => '</m>'); };    # end math mode

sub BDM {
	MODES(TeX => '\\[', HTML_MathJax => '\\[', HTML => '<P ALIGN=CENTER>', PTX => '<me>');
};                                                                                              #begin displayMath mode

sub EDM {
	MODES(TeX => '\\]', HTML_MathJax => '\\]', HTML => '</P>', PTX => '</me>');
};                                                                                              #end displayMath mode

sub LTS {
	MODES(TeX => '<', HTML => '&lt;', HTML_tth => '<', PTX => '\lt');
};    #only for use in math mode

sub GTS {
	MODES(TeX => '>', HTML => '&gt;', HTML_tth => '>', PTX => '\gt');
};    #only for use in math mode

sub LTE {
	MODES(TeX => '\\le ', HTML => '<U>&lt;</U>', HTML_tth => '\\le ', PTX => '\leq');
};    #only for use in math mode

sub GTE {
	MODES(TeX => '\\ge ', HTML => '<U>&gt;</U>', HTML_tth => '\\ge ', PTX => '\geq');
};    #only for use in math mode

sub BEGIN_ONE_COLUMN {    # deprecated
	return '';
}

sub END_ONE_COLUMN {    # deprecated
	return '';
}

sub SOLUTION_HEADING {
	MODES(
		TeX  => '{\\bf ' . maketext('Solution:') . ' }',
		HTML => maketext('Solution'),
		PTX  => ''
	);
}

sub HINT_HEADING {
	MODES(
		TeX  => '{\\bf ' . maketext('Hint:') . ' }',
		HTML => maketext('Hint'),
		PTX  => ''
	);
}
sub US { MODES(TeX => '\\_', HTML => '_', PTX => '_'); };    # underscore, e.g. file${US}name

# force a space in latex, doesn't force extra space in html
sub SPACE {
	MODES(TeX => '\\ ', HTML => '&nbsp;', PTX => ' ');
}
sub NBSP    { MODES(TeX => '~',            HTML => '&nbsp;',    PTX => '<nbsp/>'); }
sub NDASH   { MODES(TeX => '--',           HTML => '&ndash;',   PTX => '<ndash/>'); }
sub MDASH   { MODES(TeX => '---',          HTML => '&mdash;',   PTX => '<mdash/>'); }
sub BBOLD   { MODES(TeX => '{\\bf ',       HTML => '<STRONG>',  PTX => '<alert>'); }
sub EBOLD   { MODES(TeX => '}',            HTML => '</STRONG>', PTX => '</alert>'); }
sub BLABEL  { MODES(TeX => '',             HTML => '<LABEL>',   PTX => ''); }
sub ELABEL  { MODES(TeX => '',             HTML => '</LABEL>',  PTX => ''); }
sub BITALIC { MODES(TeX => '{\\it ',       HTML => '<I>',       PTX => '<em>'); }
sub EITALIC { MODES(TeX => '} ',           HTML => '</I>',      PTX => '</em>'); }
sub BUL     { MODES(TeX => '\\underline{', HTML => '<U>',       PTX => '<em>'); }
sub EUL     { MODES(TeX => '}',            HTML => '</U>',      PTX => '</em>'); }

sub BCENTER {
	MODES(
		TeX  => '\\begin{center} ',
		HTML => '<div align="center">',
		PTX  => ''
	);
}

sub ECENTER {
	MODES(
		TeX  => '\\end{center} ',
		HTML => '</div>',
		PTX  => ''
	);
}

sub BLTR {
	MODES(
		TeX  => ' ',
		HTML => '<span dir="ltr">',
		PTX  => ''
	);
}
sub ELTR { MODES(TeX => ' ',         HTML => '</span>', PTX => ''); }
sub BKBD { MODES(TeX => '\\texttt{', HTML => '<KBD>',   PTX => ''); }
sub EKBD { MODES(TeX => '}',         HTML => '</KBD>',  PTX => ''); }

sub HR {
	MODES(
		TeX  => '\\par\\hrulefill\\par ',
		HTML => '<HR>',
		PTX  => ''
	);
}

sub LBRACE {
	MODES(TeX => '\{', HTML => '{', HTML_tth => '\\lbrace', PTX => '{');
};    #not for use in math mode

sub RBRACE {
	MODES(TeX => '\}', HTML => '}', HTML_tth => '\\rbrace', PTX => '}');
};    #not for use in math mode

sub LB {
	MODES(TeX => '\{', HTML => '{', HTML_tth => '\\lbrace', PTX => '{');
};    #not for use in math mode

sub RB {
	MODES(TeX => '\}', HTML => '}', HTML_tth => '\\rbrace', PTX => '}');
};    #not for use in math mode
sub DOLLAR  { MODES(TeX => '\\$',       HTML => '&#36;', PTX => '$'); }
sub PERCENT { MODES(TeX => '\\%',       HTML => '%',     PTX => '%'); }
sub CARET   { MODES(TeX => '\\verb+^+', HTML => '^',     PTX => '^'); }
sub PI      { 4 * atan2(1, 1); }
sub E       { exp(1); }
sub LATEX   { MODES(TeX => '\\LaTeX', HTML => '\\(\\mathrm\\LaTeX\\)', PTX => '<latex/>'); }
sub TEX     { MODES(TeX => '\\TeX',   HTML => '\\(\\mathrm\\TeX\\)',   PTX => '<tex/>'); }
sub APOS    { MODES(TeX => "'",       HTML => "'",                     PTX => "\\'"); }

###############################################################

=head2 SPAN and DIV macros

These are functions primarly meant to add
HTML block level DIV or inline SPAN
tags and the relevant closing tags for HTML output.

At present, these macros require the user to provide TeX and
preTeXt strings which will be used in those modes instead of the
HTML block level DIV or inline SPAN tag.

If they are missing, they will default to the empty string.
If only one string is given, it will be assumed to be the TeX string.

At present only the following 4 HTML attributes can be set:
                 lang, dir, class, style.
Using the style option requires creating valid CSS text.
For safety some parsing/cleanup is done and various sorts of
(apparently) invalid values may be dropped. See the code for
details of what input sanitation is done.

Since the use of style is particularly dangerous, in order to
enable its use you must set allowStyle to 1 in the hash. It is
possible to prevent the use of some of the other options by
setting certain control like allowLang to 0.

Usage:

    openSpan( options_hash,  "tex code", "ptx code" );
    closeSpan("tex code", "ptx code");

Usage where TeX and PTX output will be empty by default:

    openSpan( options_hash );
    closeSpan();

Sample options hashes

    { "lang" => "he",
      "dir" => "rtl",
      "class" => "largeText class123" }

    { "lang" => "he",
      "allowStyle" => 1,
       "style" => "background-color: \"#afafaf; float: left;\t height: 12px;" }

=cut

sub processDivSpanOptions {
	my $option_ref = {};
	$option_ref = shift if ref($_[0]) eq 'HASH';

	my %options = (
		allowLang  => 1,    # Setting the lang  tag is allowed by default
		allowDir   => 1,    # Setting the dir   tag is allowed by default
		allowClass => 1,    # Setting the class tag is allowed by default
		allowStyle => 0,    # Setting the style tag is FORBIDDEN by default, use with care!
		%{$option_ref},
	);

	my $LangVal = "";
	if ($options{allowLang} && defined($options{lang})) {
		# The standard for how the lang tag should be set is explained in
		# https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/lang
		# based on the BCP47 standard from https://www.ietf.org/rfc/bcp/bcp47.txt

		# We are going to do only minimal cleanup to the value provided
		# making sure that all the characters are in the valid range A-Za-z0-9\-
		# but not checking the inner structure
		$LangVal = $options{lang};
		if ($LangVal =~ /[^\w\-]/) {
			# Clean it up
			$LangVal =~ s/[^\w\-]//g;    # Drop invalid characters
			WARN_MESSAGE(
				"processDivSpanOptions received an HTML LANG attribute setting with invalid characters which were removed. The value after cleanup is $LangVal which may not be what was intended. See https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/lang for information on how this value should be set"
			);
		}
	}

	my $DirVal = "";
	if ($options{allowDir} && defined($options{dir})) {
		# the ONLY allowed values are: ltr rtl auto
		if (($options{dir} eq "ltr")
			|| ($options{dir} eq "rtl")
			|| ($options{dir} eq "auto"))
		{
			$DirVal = $options{dir};
		} else {
			WARN_MESSAGE(
				"processDivSpanOptions received an invalid value for the HTML DIR attribute. Only ltr rtl auto are allowed. As a result the DIR attribute has not been set."
			);
		}
	}

	my $ClassVal = "";
	if ($options{allowClass} && defined($options{class})) {
		# Class names which are permitted here must start with a letter [A-Za-z]
		# and the rest of the class name can be characters in [A-Za-z0-9\-\_].

		# A space is used to separate class names

		# The offical W3C documentation allows class names to follow a far more general
		# grammar, but this is not being permitted here at present.
		# See: https://www.w3.org/TR/css-syntax-3/#token-diagrams

		my $hadBadClassNames = 0;
		my @rawList          = split(' ', $options{class});
		my @okList;    # Will collect valid class names
		my $cl;
		while (@rawList) {
			$cl = shift(@rawList);
			if ($cl =~ /^[A-Za-z][\w\-\_]*$/) {
				push(@okList, $cl);
			} else {
				$hadBadClassNames = 1;
				# print "Invalid classname $cl dropped\n";
			}
		}
		if (@okList) {
			$ClassVal = join(' ', @okList);
			WARN_MESSAGE(
				"processDivSpanOptions received some CSS class names which are not permitted by PG for the HTML CLASS attribute. Any invalid names were dropped."
			) if ($hadBadClassNames);
		} else {
			# No good values arrived
			WARN_MESSAGE(
				"processDivSpanOptions received ONLY CSS class names which are not permitted by PG for the HTML CLASS attribute. As a result the CLASS attribute has not been set."
			) if ($hadBadClassNames);
		}
	}

	my $StyleVal = "";
	if ($options{allowStyle} && defined($options{style})) {
		# The value is validated in a very minimal sense only - use with great care

		# Replace tab with space
		$options{style} =~ s/\t/ /g;

		$StyleVal = $options{style};

		# Mininal cleanup for safety
		$StyleVal =~ s/["']//g;    # Drop quotes
		if ($StyleVal eq $options{style}) {
			# no quotes, so now drop other characters we consider invalid
			# ONLY A-Za-z-_ #:; are currently allowed.
			$StyleVal =~ s/[^\w\-\_ #:;]//g;
		}

		if ($StyleVal ne $options{style}) {
			# Did not seem safe
			$StyleVal = "";
			WARN_MESSAGE(
				"processDivSpanOptions received some characters in the STYLE string which are not permitted by PG. As a result the entire STYLE string was dropped"
			);
		}
	}

	# Construct the desired HTML attributes
	my $html_attribs = "";
	$html_attribs .= "lang=\"$LangVal\" "   if ($LangVal ne "");
	$html_attribs .= "dir=\"$DirVal\" "     if ($DirVal ne "");
	$html_attribs .= "class=\"$ClassVal\" " if ($ClassVal ne "");
	$html_attribs .= "style=\"$StyleVal\" " if ($StyleVal ne "");
	return ($html_attribs);
}

sub openDivSpan {
	my $type = shift;    # "Span" or "Div";
	if ($type eq "Span" || $type eq "Div") {
		# OK
	} else {
		WARN_MESSAGE("openDivSpan called with an invalid first argument. The entire call was discarded.");
		return ();
	}
	my $option_ref   = {};
	my $html_attribs = '';
	if (ref($_[0]) eq 'HASH') {
		$option_ref   = shift;
		$html_attribs = processDivSpanOptions($option_ref);
	}

	my $tex_code = shift;    # TeX     code to be used for this - currently needs to be set by hand
	my $ptx_code = shift;    # preTeXt code to be used for this - currently needs to be set by hand

	# Fall back to empty TeX / preTeXt code if none was provided.
	$tex_code = defined($tex_code) ? $tex_code : "";
	$ptx_code = defined($ptx_code) ? $ptx_code : "";

	# Make a call to track this as opening a "object" which needs to be closed
	# ON HOLD - as the internal balancing support is still work in progress
	# internalBalancingIncrement("open${type}");

	MODES(
		TeX  => "$tex_code",
		HTML => qq!<$type $html_attribs>\n!,
		PTX  => "$ptx_code",
	);
}

sub closeDivSpan {
	my $type = shift;    # "Span" or "Div";
	if ($type eq "Span" || $type eq "Div") {
		# OK
	} else {
		WARN_MESSAGE("closeDivSpan called with an invalid first argument. The entire call was discarded.");
		return ();
	}

	my $tex_code = shift;    # TeX     code to be used for this - currently needs to be set by hand
	my $ptx_code = shift;    # preTeXt code to be used for this - currently needs to be set by hand

	# Fall back to empty TeX / preTeXt code if none was provided.
	$tex_code = defined($tex_code) ? $tex_code : "";
	$ptx_code = defined($ptx_code) ? $ptx_code : "";

	# Make a call to track this as closing a tracked "object" which was reported as opened
	# ON HOLD - as the internal balancing support is still work in progress
	# internalBalancingDecrement("open${type}");

	MODES(
		TeX  => "$tex_code",
		HTML => qq!</$type>\n!,
		PTX  => "$ptx_code",
	);
}

sub openSpan {
	openDivSpan(("Span", @_));
}

sub openDiv {
	openDivSpan(("Div", @_));
}

sub closeSpan {
	closeDivSpan(("Span", @_));
}

sub closeDiv {
	closeDivSpan(("Div", @_));
}

###############################################################
## Evaluation macros

=head2 TEXT macros

Usage:

        TEXT(@text);

This is the simplest way to print text from a problem.  The strings in the array C<@text> are concatenated
with spaces between them and printed out in the text of the problem.  The text is not processed in any other way.
C<TEXT> is defined in PG.pl.

Usage:

        BEGIN_TEXT
            text.....
        END_TEXT

This is the most common way to enter text into the problem.  All of the text between BEGIN_TEXT and END_TEXT
is processed by the C<EV3> macro described below and then printed using the C<TEXT> command.  The two key words
must appear on lines by themselves.  The preprocessing that makes this construction work is done in F<PGtranslator.pm>.
See C<EV3> below for details on the processing.

=cut

=head2 Evaluation macros

=head3 EV3

        TEXT(EV3("This is a formulat \( \int_0^5 x^2 \, dx \) ");
        TEXT(EV3(@text));

        TEXT(EV3(<<'END_TEXT'));
            text stuff...
        END_TEXT

The BEGIN_TEXT/END_TEXT construction is translated into the construction above by PGtranslator.pm.  END_TEXT must appear
on a line by itself and be left justified.  (The << construction is known as a "here document" in UNIX and in PERL.)

The single quotes around END_TEXT mean that no automatic interpolation of variables takes place in the text.
Using EV3 with strings which have been evaluated by double quotes may lead to unexpected results.

The evaluation macro E3 first evaluates perl code inside the braces:  C<\{  code \}>.
Any perl statment can be put inside the braces.  The
result of the evaluation (i.e. the last statement evaluated) replaces the C<\{ code \}> construction.

Next interpolation of all variables (e.g. C<$var or @array> ) is performed.

Then mathematical formulas in TeX are evaluated within the
C<\(  tex math mode \)> and
C<\[ tex display math mode \] >
constructions, in that order:

=head3 refreshEquations

    refreshEquations(1);

Prevents equations generated in "image mode" from being cached.  This can be useful for debugging.
It has no effect in the other modes.

=cut

sub refreshEquations {
	my $in = shift;
	if ($displayMode eq "HTML_dpng") {
		$envir->{imagegen}->refresh($in);
	}
}

=head3 addToTeXPreamble

    addToTeXPreamble("\newcommand{\myVec}[1]{\vec{#1}} ");

Defines C<\myVec > for all the equations in the file. You can change the vector notation for an entire PG question
by changing just this line.

If you place this macro in PGcourse.pl remember to use double backslashes because it is a .pl file.
In .pg files use single backslashes. This is in accordance with the usual rules for backslash
in PG.

For the moment this change only works in image mode.  It does not work in
MathJax mode.  Stay tuned.

Adding this command

    \newcommand{\myVec}[1]{\vec{#1}}

to TeX(hardcopy) portion of the setHeaderCombinedFile.pg ( or to the setHeaderHardcopyFile.pg
for each homework set will take care of the TeX hardcopy version

You can also modify the TexPreamble file in   webwork2/conf/snippets to set the definition
of \myVec for hardcopy for the entire site.

There are ways you can use course.conf to allow course by course modification by choosing
different TeXPreamble files for different courses

=cut

sub addToTeXPreamble {
	my $str = shift;
	if ($displayMode eq "HTML_dpng") {
		$envir->{imagegen}->addToTeXPreamble($str . "\n");
	} elsif ($displayMode eq "TeX" and $envir->{probNum} == 0) {

		# in TeX mode we are typically creating an entire homework set
		# and typesetting that so w only want the TeXPreamble to
		# appear once -- toward the beginning.
		# This is potentially fragile -- if one starts
		# typesetting problems separately this will fail.
		# The reason for the multicols commands is baroque
		# If they are not there then the newcommand gets printed
		# inside a multicols environment and its scope doesn't reach the whole file
		# It has to do with the way the multicol single col stuff was set up
		# when printing hardcopy.  --it's weird and there must be a better way.
		TEXT("\\ifdefined\\nocolumns\\else \\end{multicols} \\fi\n",
			$str, "\n", "\\ifdefined\\nocolumns\\else \\begin{multicols}{2}\\columnwidth=\\linewidth \\fi\n");
	} else {    # for MathJax mode
		my $mathstr = "\\(" . $str . "\\)";    #add math mode.
		$mathstr =~ s/\\/\\\\/g;               # protect math modes ($str has a true TeX command,
											   # with single backslashes.  The backslashes have not
											   # been protected by the .pg problem preprocessor
		TEXT(EV3($mathstr));
	}
}

=head3 FEQ

    FEQ($string);   # processes and outputs the string

The mathematical formulas are run through the macro C<FEQ> (Format EQuations) which performs
several substitutions (see below).
In C<HTML_tth> mode the resulting code is processed by tth to obtain an HTML version
of the formula.

The resulting string is output (and usually fed into TEXT to be printed in the problem).

Usage:

        $string2 = FEQ($string1);

This is a filter which is used to format equations by C<EV2> and C<EV3>, but can also be used on its own.  It is best
understood with an example.

        $string1 = "${a}x^2 + ${b}x + {$c:%.1f}"; $a = 3;, $b = -2; $c = -7.345;

when interpolated becomes:

        $string1 = '3x^2 + -2x + {-7.345:%0.1f}

FEQ first changes the number of decimal places displayed, so that the last term becomes -7.3 Then it removes the
extraneous plus and minus signs, so that the final result is what you want:

        $string2 = '3x^2 - 2x -7.3';

(The %0.1f construction
is the same formatting convention used by Perl and nearly identical to the one used by the C printf statement. Some common
usage:  %0.3f 3 decimal places, fixed notation; %0.3e 3 significant figures exponential notation; %0.3g uses either fixed
or exponential notation depending on the size of the number.)

Two additional legacy formatting constructions are also supported:

C<!{$c:%0.3f} > will give a number with 3 decimal places and a negative
sign if the number is negative, no sign if the number is positive.  Since this is
identical to the behavior of C<{$c:%0.3f}> the use of this syntax is depricated.

C<?{$c:%0.3f}> determines the sign and prints it
whether the number is positive or negative.  You can use this
to force an expression such as C<+5.456>.

=head3 EV2

        TEXT(EV2(@text));

        TEXT(EV2(<<END_OF_TEXT));
            text stuff...
        END_OF_TEXT

This is a precursor to EV3.  In this case the constants are interpolated first, before the evaluation of the \{ ...code...\}
construct. This can lead to unexpected results.  For example C<\{ join(" ", @text) \}> with C<@text = ("Hello", "World");> becomes,
after interpolation, C<\{ join(" ", Hello World) \}> which then causes an error when evaluated because Hello is a bare word.
C<EV2> can still be useful if you allow for this, and in particular it works on double quoted strings, which lead to
unexpected results with C<EV3>. Using single quoted strings with C<EV2> may lead to unexpected results.

The unexpected results have to do with the number of times backslashed constructions have to be escaped. It is quite messy.  For
more details get a good Perl book and then read the code. :-)

=cut

sub ev_substring {
	my $string      = shift;
	my $start_delim = shift;
	my $end_delim   = shift;
	my $actionRef   = shift;
	my ($eval_out, $PG_eval_errors, $PG_full_error_report) = ();
	my $out = "";
	while ($string ne "") { #  DPVC -- 2001/12/07 - original "while ($string)" fails to process the string "0" correctly
		if ($string =~ /\Q$start_delim\E/s) {
			#print "$start_delim $end_delim evaluating_substring=$string<BR>";
			$string =~ s/^(.*?)\Q$start_delim\E//s
				;           # get string up to next \{ ---treats string as a single line, ignoring returns
			$out .= $1;
			#print "$start_delim $end_delim substring_out=$out<BR>";
			$string =~
				s/^(.*?)\Q$end_delim\E//s; # get perl code up to \} ---treats string as a single line,  ignoring returns
										   #print "$start_delim $end_delim evaluate_string=$1<BR>";
			($eval_out, $PG_eval_errors, $PG_full_error_report) = &$actionRef($1);
			$eval_out = "$start_delim $eval_out $end_delim" if $PG_full_error_report;
			$out      = $out . $eval_out;
			#print "$start_delim $end_delim new substring_out=$out<BR><p><BR>";
			$out .= "$PAR ERROR $0 in ev_substring, PGbasicmacros.pl:$PAR <PRE>  $@ </PRE>$PAR" if $@;
		} else {
			$out .= $string;               # flush the last part of the string
			last;
		}

	}
	$out;
}

sub safe_ev {
	my ($out, $PG_eval_errors, $PG_full_error_report) = &old_safe_ev;    # process input by old_safe_ev first
	$out = "" unless defined($out) and $out =~ /\S/;
	$out =~ s/\\/\\\\/g;                                                 # protect any new backslashes introduced.
	($out, $PG_eval_errors, $PG_full_error_report);
}

sub safe_evp {
	my @result = &safe_ev;
	$result[0] = '${__blank__}' . $result[0] . '${__blank__}';
	return @result;
}

sub old_safe_ev {
	my $in = shift;
	my ($out, $PG_eval_errors, $PG_full_error_report) = PG_restricted_eval($in);
	if ($PG_eval_errors) {
		my @errorLines = split("\n", $PG_eval_errors);
		warn "There is an error occuring inside evaluation brackets \\{ ...code... \\}\n"
			. "somewhere in an EV2, EV3, or BEGIN_TEXT block.\n"
			. "Code evaluated:\n$in\n"
			. "Errors:\n"
			. join("\n", @errorLines) . "\n";
		$out = "$BBOLD$in$EBOLD";
	}

	return ($out, $PG_eval_errors, $PG_full_error_report);
}

sub FEQ {    # Format EQuations
	my $in = shift;
	# formatting numbers -- the ?{} and !{} constructions
	$in =~ s/\?\s*\{([.\-\$\w\d]+):?([%.\da-z]*)\}/${ \( &sspf($1, $2) )}/g;
	$in =~ s/\!\s*\{([.\-\$\w\d]+):?([%.\da-z]*)\}/${ \( &spf($1, $2) )}/g;

	# more formatting numbers -- {number:format} constructions
	$in =~ s/\{(\s*[\+\-\d\.]+[eE]*[\+\-]*\d*):(\%\d*.\d*\w)}/${ \( &spf($1, $2) )}/g;
	$in =~ s/\+\s*\-/ - /g;
	$in =~ s/\-\s*\+/ - /g;
	$in =~ s/\+\s*\+/ + /g;
	$in =~ s/\-\s*\-/ + /g;
	$in;
}

sub math_ev3 {
	my $in = shift;
	return general_math_ev3($in, "inline");
}

sub display_math_ev3 {
	my $in = shift;
	return general_math_ev3($in, "display");
}

sub general_math_ev3 {
	my $in   = shift;
	my $mode = shift || "inline";

	$in = FEQ($in);                          # Format EQuations
	$in =~ s/((^|[^\\])(\\\\)*)%/$1\\%/g;    # avoid % becoming TeX comments (unless already escaped)

	## remove leading and trailing spaces so that HTML mode will
	## not include unwanted spaces as per Davide Cervone.
	$in =~ s/^\s+//;
	$in =~ s/\s+$//;
	## If it ends with a backslash, there should be another space
	## at the end
	if ($in =~ /(^|[^\\])(\\\\)*\\$/) { $in .= ' ' }

	# some modes want the delimiters, some don't
	my $in_delim = $mode eq "inline" ? "\\($in\\)" : "\\[$in\\]";

	my $out;
	if ($displayMode eq "HTML_MathJax") {
		$out = '<script type="math/tex' . ($mode eq 'display' ? '; mode=display' : '') . '">' . $in . '</script>';
	} elsif ($displayMode eq "HTML_dpng") {
		# for jj's version of ImageGenerator
		#$out = $envir->{'imagegen'}->add($in_delim);
		# for my version of ImageGenerator
		$out = $envir->{'imagegen'}->add($in, $mode);
	} elsif ($displayMode eq "HTML_tth") {
		$out = tth($in_delim);
		## remove leading and trailing spaces as per Davide Cervone.
		$out =~ s/^\s+//;
		$out =~ s/\s+$//;
	} elsif ($displayMode eq "PTX") {
		# protect XML control characters
		$in =~ s/\&(?!([\w#]+;))/\\amp /g;
		$in =~ s/</\\lt /g;
		# attempt to parse align|alignat|gather into complete md/mrow structure, otherwise use me
		if ($mode eq 'inline') {
			$out = "<m>$in</m>";
		} elsif ($mode eq 'display' && $in =~ /^\s*\\begin\{(align|alignat|gather)}((?!\\end\{\1}).)*\\end\{\1}\s*$/s) {
			my $alignment = $1;
			my $lines =
				($in =~ s/^\s*\\begin\{$alignment}\s*(((?!\\end\{$alignment}).)*)\s*\\end\{$alignment}\s*$/$1/sr);
			$lines =~ s/^\{\d+\}// if ($alignment eq 'alignat');
			my @lines = split(/\\\\\n?/, $lines);
			@lines = map { $_ =~ s/^\s+|\s+$//r } @lines;
			my @rows = map {"<mrow>$_</mrow>"} @lines;
			my $rows = join("\n", @rows);
			$alignment = ($alignment eq 'align') ? '' : " alignment=\"$alignment\"";
			$out       = "<md${alignment}>\n$rows\n</md>";
		} elsif ($mode eq 'display') {
			$out = "<me>$in</me>";
		}
	} elsif ($displayMode eq "HTML") {
		$in_delim = HTML::Entities::encode_entities($in_delim);
		$out      = "<span class='tex2jax_ignore'>$in_delim</span>";
	} else {
		$out = $in_delim;
	}
	return $out;
}

sub EV2 {
	my $string = join(" ", @_);
	# evaluate code inside of \{  \}  (no nesting allowed)
	$string = ev_substring($string, "\\{", "\\}", \&old_safe_ev);
	$string = ev_substring($string, "\\<", "\\>", \&old_safe_ev);
	$string = ev_substring($string, "\\(", "\\)", \&math_ev3);
	$string = ev_substring($string, "\\[", "\\]", \&display_math_ev3);
	# macros for displaying math
	$string =~ s/\\\(/$BM/g;
	$string =~ s/\\\)/$EM/g;
	$string =~ s/\\\[/$BDM/g;
	$string =~ s/\\\]/$EDM/g;
	$string;
}

sub EV3 {
	my $string = join(" ", @_);
	# evaluate code inside of \{  \}  (no nesting allowed)
	$string = ev_substring($string, "\\\\{", "\\\\}", \&safe_ev);   # handles \{ \} in single quoted strings of PG files
																	# interpolate variables
	my ($evaluated_string, $PG_eval_errors, $PG_full_errors) =
		PG_restricted_eval("<<END_OF_EVALUATION_STRING\n$string\nEND_OF_EVALUATION_STRING\n");
	if ($PG_eval_errors) {
		my @errorLines = split("\n", $PG_eval_errors);
		$string =~ s/</&lt;/g;
		$string =~ s/>/&gt;/g;
		$evaluated_string =
			"<PRE>$PAR % ERROR in $0:EV3, PGbasicmacros.pl: $PAR % There is an error occuring in the following code:$BR $string $BR % $BR % $errorLines[0]\n % $errorLines[1]$BR % $BR % $BR </PRE> ";
		$@ = "";
	}
	$string = $evaluated_string;
	$string = ev_substring($string, "\\(", "\\)", \&math_ev3);
	$string = ev_substring($string, "\\[", "\\]", \&display_math_ev3);
	$string;
}

sub EV4 {
	if ($displayMode eq "HTML_dpng") {
		my $string = join(" ", @_);
		my ($evaluated_string, $PG_eval_errors, $PG_full_errors) =
			PG_restricted_eval("<<END_OF_EVALUATION_STRING\n$string\nEND_OF_EVALUATION_STRING\n");
		if ($PG_eval_errors) {
			my @errorLines = split("\n", $PG_eval_errors);
			$string =~ s/</&lt;/g;
			$string =~ s/>/&gt;/g;
			$evaluated_string =
				"<PRE>$PAR % ERROR in $0:EV3, PGbasicmacros.pl:"
				. "$PAR % There is an error occuring in the following code:$BR "
				. "$string $BR % $BR % $errorLines[0]\n % $errorLines[1]$BR "
				. "% $BR % $BR </PRE> ";
		}
		$string = $evaluated_string;
		$string = $envir{'imagegen'}->add($string);
		$string;
	} else {
		EV3(@_);
	}
}

=head3 EV3P

	######################################################################
	#
	#  New version of EV3 that allows `...` and ``...`` to insert TeX produced
	#  by the new Parser (in math and display modes).
	#
	#  Format:  EV3P(string, ...);
	#           EV3P({options}, string, ...);
	#
	#           `x^2/5` will become \(\frac{x^2}{5}\) and then rendered for hardcopy or screen output
	#
	#  where options can include:
	#
	#    processCommands => 0 or 1     Indicates if the student's answer will
	#                                  be allowed to process \{...\}.
	#                                    Default: 1
	#
	#    processVariables => 0 1       Indicates whether variable substitution
	#                                  should be performed on the student's
	#                                  answer.
	#                                    Default: 1
	#
	#    processMath => 0 or 1         Indicates whether \(...\), \[...\],
	#                                  `...` and ``...`` will be processed
	#                                  in the student's answer.
	#                                    Default: 1
	#
	#    processParser => 0 or 1       Indicates if `...` and ``...`` should
	#                                  be processed when math is being
	#                                  processed.
	#                                    Default: 1
	#
	#    fixDollars => 0 or 1          Specifies whether dollar signs not followed
	#                                  by a letter should be replaced by ${DOLLAR}
	#                                  prior to variable substitution (to prevent
	#                                  accidental substitution of strange Perl
	#                                  values).
	#                                    Default: 1
	#

=cut

sub EV3P {
	my $option_ref = {};
	$option_ref = shift if ref($_[0]) eq 'HASH';
	my %options = (
		processCommands  => 1,
		processVariables => 1,
		processParser    => 1,
		processMath      => 1,
		fixDollars       => 1,
		%{$option_ref},
	);
	my $string = join(" ", @_);
	$string = ev_substring($string, "\\\\{", "\\\\}", $options{processVariables} ? \&safe_evp : \&safe_ev)
		if $options{processCommands};
	if ($options{processVariables}) {
		my $eval_string = $string;
		$eval_string =~ s/\$(?![a-z\{])/\${DOLLAR}/gi if $options{fixDollars};
		my ($evaluated_string, $PG_eval_errors, $PG_full_errors) = PG_restricted_eval(
			q{my $__blank__ = '';} . "<<END_OF_EVALUATION_STRING\n$eval_string\nEND_OF_EVALUATION_STRING\n");
		if ($PG_eval_errors) {
			my $error = (split("\n", $PG_eval_errors))[0];
			$error  =~ s/at \(eval.*//gs;
			$string =~ s/&/&amp;/g;
			$string =~ s/</&lt;/g;
			$string =~ s/>/&gt;/g;
			$evaluated_string = $BBOLD . "(Error: $error in '$string')" . $EBOLD;
		}
		$string = $evaluated_string;
	} else {
		$string =~ s/\\\\/\\/g;
	}

	if ($options{processMath}) {
		$string = EV3P_parser($string) if $options{processParser};
		$string = ev_substring($string, "\\(", "\\)", \&math_ev3);
		$string = ev_substring($string, "\\[", "\\]", \&display_math_ev3);
	}

	if ($displayMode eq 'PTX') { $string = PTX_cleanup($string) }

	return $string;
}

#
#  Look through a string for ``...`` or `...` and use
#  the parser to produce TeX code for the specified mathematics.
#  ``...`` does display math, `...` does in-line math.  They
#  can also be used within math mode already, in which case they
#  use whatever mode is already in effect.
#
sub EV3P_parser {
	my $string = shift;
	return $string unless $string =~ m/`/;
	my $start = '';
	my %end   = ('\(' => '\)', '\[' => '\]');
	my @parts = split(/(``.*?``\*?|`.+?`\*?|(?:\\[()\[\]]))/s, $string);
	foreach my $part (@parts) {
		if ($part =~ m/^(``?)(.*)\1(\*?)$/s) {
			my ($delim, $math, $star) = ($1, $2, $3);
			my $f = Parser::Formula($math);
			if (defined($f)) {
				$f    = $f->reduce if $star;
				$part = $f->TeX;
				$part = ($delim eq '`' ? '\(' . $part . '\)' : '\[' . $part . '\]') if (!$start);
			} else {
				## FIXME:  use context->{error}{ref} to highlight error in $math.
				$part = $BBOLD . "(Error: $$Value::context->{error}{message} '$math')" . $EBOLD;
				$part = $end{$start} . " " . $part . " " . $start if $start;
			}
		} elsif ($start) {
			$start = '' if $part eq $end{$start};
		} elsif ($end{$part}) {
			$start = $part;
		}
	}
	return join('', @parts);
}

sub PTX_cleanup {
	my $string = shift;
	# Wrap <p> tags where necessary, and other cleanup
	# Nothing else should be creating p tags, so assume all p tags created here
	# The only supported top-level elements within a statement, hint, or solution in a problem
	# are p, blockquote, pre, tabular, image, video
	if ($displayMode eq 'PTX') {
		#encase entire string in <p>
		#except not for certain "sub" structures that are also passed through EV3
		$string = "<p>" . $string . "</p>"
			unless (($string =~ /^<fillin[^>]*\/>$/)
				|| ($string =~ /^<var.*<\/var>$/s)
				|| ($string =~ /^<ul[^>]*form=[^>]*>/s));

		#inside a li, the only permissible children are title, p, image, video, and tabular
		#insert opening and closing p, to be removed later if they enclose a title, image, video or tabular
		#we are not going to look to see if there is a nested list in there
		$string =~ s/(<li[^>]*(?<!\/)>)/$1\n<p>/g;
		$string =~ s/(<\/li>)/<\/p>\n$1/g;

		#close p right before any title, blockquote, pre, image, video, or tabular
		#and open p immediately following. Later any potential side effects are cleaned up.
		$string =~ s/(<(title|blockquote|pre|image|video|tabular)[^>]*(?<!\/)>)/<\/p>\n$1/g;
		$string =~ s/(<\/(title|blockquote|pre|image|video|tabular)>)/$1\n<p>/g;
		$string =~ s/(<(title|blockquote|pre|image|video|tabular)[^>]*(?<=\/)>)/<\/p>\n$1\n<p>/g;

		#within a <cell>, we may have an issue if there was an image that had '<\p>' and '<p>' wrapped around
		#it from the above block. If the '</p>' has a preceding '<p>' within the cell, no problem. Otherwise,
		#the '</p>' must go. Likewise at the other end.
		$string =~ s/(?s)(<cell>.*?)<\/p>\n(<image[^>]*(?<=\/)>)\n<p>(.*?<\/cell>)/$1$2$3/g;

		#remove blank lines; assume the intent was to end a p and start a new one
		#but don't put closing and opening p replacing the blank lines if they precede or follow a <row>
		#or an <li>
		$string =~ s/(\r\n?|\n)(\r\n?|\n)+(?!(<row>|<\/tabular>|<li>|\r\n?|\n))/<\/p>\n<p>/g;
		$string =~ s/(\r\n?|\n)(\r\n?|\n)+(?=(<row>|<\/tabular>|<li>|\r\n?|\n))/\n/g;

		#remove whitespace following <p>
		$string =~ s/(?s)(<p>)\s*/$1/g;

		#remove whitespace preceding </p>
		$string =~ s/(?s)\s*(<\/p>)/$1/g;

		#move PTX warnings from the beginning of inside a p to just before the p.
		$string =~ s/<p>(<!\-\- PTX:WARNING.*?-->)/$1\n<p>/g;

		#remove doulbe p's we may have created
		$string =~ s/<p><p>/<p>/g;
		$string =~ s/<\/p><\/p>/<\/p>/g;

		#remove empty p
		$string =~ s/(\r\n?|\n)?<p><\/p>//g;

		#a tabular cell may have <p> and </p> but no corresponding width specification in a col.
		#if so, remove all <p> and </p> from all cells.
		my $previous;
		do {
			$previous = $string;
			$string =~
				s/(?s)(<tabular[^>]*>(?:\s|<col (?:(?!width=").)*?>)((?!<\/tabular>).)*?<cell[^>]*>((?!<\/tabular>).)*?)<p>(((?!<\/tabular>).)*?)<\/p>(((?!<\/tabular>).)*?<\/tabular>)/$1$4$6/g;
		} until ($previous eq $string);

	}
	$string;
}

=head2 Formatting macros

    beginproblem()  # Adds a custom TeX preamble.  This is deprecated and should not be used in newly written problems.
    OL(@array)      # formats the array as an Ordered List ( <OL> </OL> ) enumerated by letters.
                    # See BeginList()  and EndList in unionLists.pl for a more powerful version
                    # of this macro.
    knowlLink($display_text, url => $url, value =>'', type =>'' )
                    # Places a reference to a knowl for the URL with the specified text in the problem.
                    # A common usage is \{ 'for help', url =>knowlLink(alias('prob1_help.html')) \} )
                    # where alias finds the full address of the prob1_help.html file in the same directory
                    # as the problem file
    knowlLink($display_text,  url => '', type =>'', value = <<EOF );  # this starts a here document that ends at EOF (left justified)
                    help text goes here .....
    EOF
                    # This version of the knowl reference facilitates immediate reference to a HERE document
                    # The function should be called either with value specified (immediate reference) or
                    # with url specified in which case the revealed text is taken from the URL $url.
                    # The $display_text is always visible and is clicked to see the contents of the knowl.
    iframe($url, height=>'', width=>'', id=>'', name=>'' )
                    # insert the web page referenced by $url in a space defined by height and width
                    # if the webpage contains a form then this must be inserted between
                    # BEGIN_POST_HEADER_TEXT/END_POST_HEADER_TEXT  to avoid having one
                    # form(from the webpage) inside another (the defining form for the problem
A wide variety of google widgets, youtube videos, and other online resources can be imbedded using this macro. In HTML mode it creates an iframe, in TeX mode it prints the url.

    helpLink($type)
                   Allows site specific help.
                   The parameter localHelpURL  must be defined in the environment
                   and is set by default to pg/htdocs/helpFiles
                   Standard helpFile types
                        'angle'
                        'decimal'
                        'equation'
                        'essay'
                        'exponent'
                        'formula'
                        'fraction'
                        'inequalit'
                        'limit'
                        'log'
                        'number'
                        'point'
                        'vector'
                        'interval'
                        'unit'
                        'syntax'

    low level:

    spf($number, $format)   # prints the number with the given format
    sspf($number, $format)  # prints the number with the given format, always including a sign.
    nicestring($coefficients, $terms) # print a linear combinations of terms using coefficients
    nicestring($coefficients) # uses the coefficients to make a polynomial
            # For example
            # nicestring([1, -2, 0]) produces 'x^2-2x'
            # nicestring([2, 0, -1], ['', 't', 't^2']) produces '2-t^2'
    protect_underbar($string) # protects the underbar (class_name) in strings which may have to pass through TeX.

=cut

sub beginproblem {
	my $out = MODES(%{ main::PG_restricted_eval(q!$main::problemPreamble!) });
	if ($displayMode eq 'PTX') { $out = '' }
	$out;
}

sub nicestring {
	my $thingy = shift;
	my @coefs  = @{$thingy};
	my $n      = scalar(@coefs);
	$thingy = shift;
	my @others;
	if (defined($thingy)) {
		@others = @{$thingy};
	} else {
		for my $j (1 .. ($n - 2)) {
			$others[ $j - 1 ] = "x^" . ($n - $j);
		}
		if ($n >= 2) { $others[ $n - 2 ] = "x"; }
		$others[ $n - 1 ] = "";
	}
	my ($j, $k) = (0, 0);
	while (($k < $n) && ($coefs[$k] == 0)) { $k++; }
	if ($k == $n) { return ("0"); }
	my $ans;
	if    ($coefs[$k] == 1)  { $ans = ($others[$k]) ? "$others[$k]" : "1"; }
	elsif ($coefs[$k] == -1) { $ans = ($others[$k]) ? "- $others[$k]" : "-1" }
	else                     { $ans = "$coefs[$k] $others[$k]"; }
	$k++;

	for $j ($k .. ($n - 1)) {
		if ($coefs[$j] != 0) {
			if ($coefs[$j] == 1) {
				$ans .= ($others[$j]) ? "+ $others[$j]" : "+ 1";
			} elsif ($coefs[$j] == -1) {
				$ans .= ($others[$j]) ? "- $others[$j]" : "-1";
			} else {
				$ans .= "+ $coefs[$j] $others[$j]";
			}
		}
	}
	return ($ans);
}

# kludge to clean up path names
## allow underscore character in set and section names and also allows line breaks at /
sub protect_underbar {
	my $in = shift;
	if ($displayMode eq 'TeX') {
		$in =~ s|_|\\\_|g;
		$in =~ s|/|\\\-/|g;    # allows an optional hyphenation of the path (in tex)
	}
	$in;
}

#	An example of a macro which prints out a list (with letters)
sub OL {
	my @array = @_;
	my $i     = 0;
	my @alpha = ('A' .. 'Z', 'AA' .. 'ZZ');
	my $letter;
	my $out = MODES(
		TeX  => "\\begin{enumerate}\n",
		HTML => "<BLOCKQUOTE>\n",
		PTX  => '<ol label="A.">' . "\n",
	);
	my $elem;
	foreach $elem (@array) {
		$letter = shift @alpha;
		$out .= MODES(
			TeX       => "\\item[$ALPHABET[$i].] $elem\n",
			HTML      => "<br /> <b>$letter.</b> $elem\n",
			HTML_dpng => "<br /> <b>$letter.</b> $elem \n",
			PTX       => "<li><p>$elem</p></li>\n",
		);
		$i++;
	}
	$out .= MODES(
		TeX  => "\\end{enumerate}\n",
		HTML => "</BLOCKQUOTE>\n",
		PTX  => '</ol>' . "\n",
	);
}

=head2 htmlLink

Usage:

    htmlLink($url, $text, @attributes)

Places an HTML link to C<$url> with the specified C<$text> in the problem. The
C<@attributes> are optional.  They should be provided as attribute/value pairs,
but a single text string argument can be given (although calling C<htmlLink> in
that way is deprecated and should not be done in new problems).  For example,

    BEGIN_PGML
    Download the [@ htmlLink($url, 'dataset', download => 'dataset.csv') @]*
    for this problem.

=cut

sub htmlLink {
	my ($url, $text, @options) = @_;
	return "$BBOLD [ the link to '$text'  is broken ] $EBOLD" unless $url;
	my $attributes = @options == 1 ? $options[0] : {@options};
	MODES(
		TeX  => "{\\bf \\underline{$text}}",
		HTML => ref($attributes) eq 'HASH'
		? tag('a', href => $url, %$attributes, $text)
		: qq{<a href="$url" $attributes>$text</a>},
		PTX => '<url href="' . ($url =~ s/&/&amp;/g) . qq{">$text</url>},
	);
}

=head2 knowlLink

Inserts a knowl link into the problem.  Usually you should not call this method
directly.  Instead use C<helpLink> below.

Usage:

    knowlLink($displayText, %options)

C<$display_text> is the text that will be shown for the link.

The following options may be included in C<%options>.  Note that one of C<url>
or C<value> is required.

=over

=item url

A URL whose contents will be shown in a modal dialog when the knowl link is
clicked.  These contents will be fetched by JavaScript and injected into the
knowl modal dialog.

=item value

The direct contents that will be shown in a modal dialog when the knowl link is
clicked.

=item title

A string that will be used for the title of the modal dialog that opens when the
knowl link is clicked. If this is not provided, then C<$display_text> will be
used for the title.

=item type

A string that will be set as the data-type attribute of the knowl link. This is
only used by PreTeXt.

=back

Example usage:

    knowlLink('Click Me', title => 'Fascinating Contents', value => 'Here are my facinating contents.');
    knowlLink('Help Me', title => 'Help Contents', url => 'https://my.domain.edu/helpfile-contents');

=cut

sub knowlLink {
	my ($display_text, %options) = @_;

	WARN_MESSAGE(
		'usage:  knowlLink($display_text, [url => $url, value => $contents, title => $title, type => "help"]);',
		'One of "url => $url" or "value => $contents" is required.')
		unless $options{value} || $options{url};

	if ($displayMode eq 'TeX') {
		return "{\\bf\\underline{$display_text}}";
	} elsif ($displayMode eq 'PTX') {
		return ($options{type} && $options{type} eq 'help')
			? ''
			: '<url ' . ($options{url} ? qq{href="$options{url}"} : '') . " >$display_text</url>";
	} else {
		my %properties;
		if ($options{value}) {
			$properties{data_knowl_contents} =
				$options{base64} ? $main::PG->decode_base64($options{value}) : $options{value};
		} elsif ($options{url}) {
			$properties{data_knowl_url} = $options{url};
		}

		$properties{data_knowl_title} = $options{title} if $options{title};
		$properties{data_type}        = $options{type}  if $options{type};
		return tag('button', type => 'button', class => 'knowl', %properties, $display_text);
	}
}

sub iframe {
	my ($url, %attributes) = @_;
	MODES(
		TeX  => "\\framebox{" . protect_underbar($url) . "}\n",
		HTML => tag('iframe', src => $url, %attributes),
		PTX  => '<url href="' . $url . '" />',
	);
}

=head2 helpLink

Usage:

    helpLink($type, $display_text, $helpurl)

Creates links for students to help documentation on formatting answers and
allows for custom help links.

There are 16 predefined help links: angles, decimals, equations, exponents,
formulas, fractions, inequalities, intervals, limits, logarithms, matrices,
numbers, points, syntax, units, vectors.

Usage:

     DOCUMENT();
     loadMacros("PGstandard.pl");
     BEGIN_TEXT
     \{ ans_rule(20) \} \{ helpLink("formulas") \}
     $PAR
     \{ ans_rule(20) \} \{ helpLink("equations", "help entering equations") \}
     $PAR
     \{ ans_rule(20) \}
     \{ helpLink("my custom help", undef, "custom_help.html") \}
     END_TEXT
     ENDDOCUMENT();


The first example uses the default link text and displays the help link next to
the answer blank which is recommended.

The second example customizes the link text displayed to the student, but the
actual help document is unaffected.

The third example displays a link to the contents of C<custom_help.html>.  Note
that the file C<custom_help.html> must be located in the location defined in the
environment variable C<$envir{localHelpURL}>.  The value of that variable can be
customized by a problem.

=cut

sub helpLink {
	my $type         = shift;
	my $display_text = shift;
	my $helpurl      = shift;
	return "" if (not defined($envir{'localHelpURL'}));
	if (defined $helpurl) {
		return knowlLink($display_text // $type, url => $envir{'localHelpURL'} . $helpurl, type => 'help');
	}
	my %typeHash = (
		'angle'     => [ 'Entering-Angles.html',       'help (angles)' ],
		'decimal'   => [ 'Entering-Decimals.html',     'help (decimals)' ],
		'equation'  => [ 'Entering-Equations.html',    'help (equations)' ],
		'essay'     => [ 'Entering-Essays.html',       'help (essays)' ],
		'exponent'  => [ 'Entering-Exponents.html',    'help (exponents)' ],
		'formula'   => [ 'Entering-Formulas.html',     'help (formulas)' ],
		'fraction'  => [ 'Entering-Fractions.html',    'help (fractions)' ],
		'inequalit' => [ 'Entering-Inequalities.html', 'help (inequalities)' ],
		'limit'     => [ 'Entering-Limits.html',       'help (limits)' ],
		'log'       => [ 'Entering-Logarithms.html',   'help (logarithms)' ],
		'matri'     => [ 'Entering-Matrices.html',     'help (matrices)' ],
		'number'    => [ 'Entering-Numbers.html',      'help (numbers)' ],
		'point'     => [ 'Entering-Points.html',       'help (points)' ],
		'vector'    => [ 'Entering-Vectors.html',      'help (vectors)' ],
		'interval'  => [ 'IntervalNotation.html',      'help (intervals)' ],
		'unit'      => [ 'Units.html',                 'help (units)' ],
		'syntax'    => [ 'Syntax.html',                'help (syntax)' ]
	);

	my $infoRef = '';
	my $refhold = '';
	for my $ref (keys %typeHash) {
		if ($type =~ /$ref/i) {
			$infoRef = $typeHash{$ref}[0];
			$refhold = $ref;
			$display_text //= $typeHash{$ref}[1];
			last;
		}
	}
	$display_text //= $type;

	# We use different help files in some cases when BaseTenLog is set
	if (PG_restricted_eval(q/$envir{useBaseTenLog}/)) {
		$infoRef = 'Entering-Logarithms10.html' if ($refhold eq 'log');
		$infoRef = 'Entering-Formulas10.html'   if ($refhold eq 'formula');
	}

	# If infoRef is still '', we give up and just print plain text
	return $display_text unless ($infoRef);
	return knowlLink($display_text, url => $envir{'localHelpURL'} . $infoRef, type => 'help');
}

# This method is deprecated.  There is no hope for the problems that use it.  Java and flash are dead.
sub appletLink {
	warn 'Applet problems that use the appletLink method are no longer supported.';
	MODES(
		TeX  => "{\\bf WeBWorK does not support appletLink}",
		HTML => "<div style='background-color:pink'>WeBWorK does not support appletLink</div>",
		PTX  => 'PreTeXt does not support appletLink',
	);
}

sub spf {
	my ($number, $format) = @_;          # attention, the order of format and number are reversed
	$format = "%4.3g" unless $format;    # default value for format
	sprintf($format, $number);
}

sub sspf {
	my ($number, $format) = @_;          # attention, the order of format and number are reversed
	$format = "%4.3g" unless $format;    # default value for format
	my $sign = $number >= 0 ? " + " : " - ";
	$number = $number >= 0 ? $number : -$number;
	$sign . sprintf($format, $number);
}

=head2 PGsort

Because of the way sort is optimized in Perl, the symbols $a and $b
have special significance.

    sort {$a<=>$b} @list
    sort {$a cmp $b} @list

sorts the list numerically and lexically respectively.

If C<my $a;> is used in a problem, before the sort routine is defined in a macro, then
things get badly confused.  To correct this the macro PGsort is defined below.  It is
evaluated before the problem template is read.  In PGbasicmacros.pl, the two subroutines

    PGsort sub { $_[0] < $_[1] }, @list;
    PGsort sub { $_[0] lt $_[1] }, @list;

(called num_sort and lex_sort) provide slightly slower, but safer, routines for the PG language.
(The subroutines for ordering are B<required>. Note the commas!)

=cut

sub PGsort {
	my ($cmp, @list) = @_;
	die "Must supply an ordering function with PGsort: PGsort sub {\$_[0]  < \$_[1] }, \@list\n"
		unless ref $cmp eq 'CODE';

	return if @list == 0;

	my $b_item = shift @list;
	my ($small, $large);
	for my $a_item (@list) {
		push @{ &$cmp($a_item, $b_item) ? $small : $large }, $a_item;
	}
	return PGsort($cmp, @$small), $b_item, PGsort($cmp, @$large);
}

=head2  Sorting and other list macros

Usage:

    lex_sort(@list);   # outputs list in lexigraphic (alphabetical) order
    num_sort(@list);   # outputs list in numerical order
    uniq( @list);      # outputs a list with no duplicates.  Order is unspecified.

    PGsort( \&sort_subroutine, @list);
    # &sort_subroutine defines order. It's output must be 1 or 0 (true or false)

=cut

#  uniq gives unique elements of a list:
sub uniq {
	my @in = @_;
	my %seen;
	return grep { !$seen{$_}++ } @in;
}

sub lex_sort {
	PGsort(sub { $_[0] lt $_[1] }, @_);
}

sub num_sort {
	PGsort(sub { $_[0] < $_[1] }, @_);
}

=head2 Macros for handling tables

B<< Note: that these are deprecated.  See L<nicetables.pl> for a replacement. >>

Usage:

    begintable( number_of_columns_in_table)
    row(@dataelements)
    endtable()

Example of useage:

    BEGIN_TEXT
        This problem tests calculating new functions from old ones:$BR
        From the table below calculate the quantities asked for:$BR
        \{begintable(scalar(@firstrow)+1)\}
        \{row(" \(x\) ", @firstrow)\}
        \{row(" \(f(x)\) ", @secondrow)\}
        \{row(" \(g(x)\) ", @thirdrow)\}
        \{row(" \(f'(x)\) ", @fourthrow)\}
        \{row(" \(g'(x)\) ", @fifthrow)\}
        \{endtable()\}

     (The arrays contain numbers which are placed in the table.)

    END_TEXT

=cut

sub begintable {
	my $number  = shift;    #number of columns in table
	my %options = @_;
	warn "begintable(cols) requires a number indicating the number of columns" unless defined($number);
	my $out = "";
	if ($displayMode eq 'TeX') {
		$out .= "\n\\par\\smallskip\\begin{center}\\begin{tabular}{" . "|c" x $number . "|} \\hline\n";
	} elsif ($displayMode eq 'PTX') {
		$out .= "\n" . '<tabular top="medium" bottom="medium" left="medium" right="medium">' . "\n";
	} elsif ($displayMode eq 'HTML_MathJax'
		|| $displayMode eq 'HTML_dpng'
		|| $displayMode eq 'HTML'
		|| $displayMode eq 'HTML_tth')
	{
		$out .= '<table class="pg-table">';
	} else {
		$out = "Error: PGbasicmacros: begintable: Unknown displayMode: $displayMode.\n";
	}
	$out;
}

sub endtable {
	my $out = "";
	if ($displayMode eq 'TeX') {
		$out .= "\n\\end {tabular}\\end{center}\\par\\smallskip\n";
	} elsif ($displayMode eq 'PTX') {
		$out .= "\n" . '</tabular>' . "\n";
	} elsif ($displayMode eq 'HTML_MathJax'
		|| $displayMode eq 'HTML_dpng'
		|| $displayMode eq 'HTML'
		|| $displayMode eq 'HTML_tth')
	{
		$out .= '</table>';
	} else {
		$out = "Error: PGbasicmacros: endtable: Unknown displayMode: $displayMode.\n";
	}
	$out;
}

sub row {
	my @elements = @_;
	my $out      = "";
	if ($displayMode eq 'TeX') {
		while (@elements) {
			$out .= shift(@elements) . " &";
		}
		chop($out);    # remove last &
		$out .= "\\\\ \\hline \n";
		# carriage returns must be added manually for tex
	} elsif ($displayMode eq 'PTX') {
		$out .= '<row>' . "\n";
		while (@elements) {
			$out .= '<cell>' . shift(@elements) . '</cell>' . "\n";
		}
		$out .= '</row>' . "\n";
	} elsif ($displayMode eq 'HTML_MathJax'
		|| $displayMode eq 'HTML_dpng'
		|| $displayMode eq 'HTML'
		|| $displayMode eq 'HTML_tth')
	{
		$out .= "<TR>\n";
		while (@elements) {
			$out .= "<TD>" . shift(@elements) . "</TD>";
		}
		$out .= "\n</TR>\n";
	} else {
		$out = "Error: PGbasicmacros: row: Unknown displayMode: $displayMode.\n";
	}
	$out;
}

=head2 Macros for displaying images

Usage:

    image($image, width => ..., height => ..., tex_size => ..., valign => ..., alt => ..., long_description => ... );

where C<$image> can be a local file path, URL, WWPlot object, PGlateximage object,
PGtikz object, Plots::Plot object, or parser::GraphTool object.

C<width> and C<height> are positive integer pixel counts for HTML display. If both
are missing, C<width> will default to 200 and C<height> will remain undeclared,
letting the browser display the image with its natural aspect ratio. Except with
a parser::GraphTool object, if both are missing then nothing will be passed along
to the GraphTool method for display, and that macro's defaults will be used.

C<tex_size> is also a positive integer, per 1000 applied to the line width in TeX.
For example 800 leads to 0.8\linewidth. If over 1000, then 1000 will be used.
If missing, this defaults to C<int(width/0.6)> so the image is proportional to its
HTML version with a 600 pixel wide reading area. If C<width> is missing and C<height>
is declared, we presume this is a wide image and then C<tex_size> defaults to 800.

C<valign> can be 'top', 'middle', or 'bottom'.  This aligns the image relative to
the surrounding line of text.

C<alt> should be a string, ideally with fewer than 125 characters, that describes the
most important features of the image. This should always be used. If the image is
decorative, C<< alt => '' >> should be used.

C<long_description> provides an optional way to give a more complete description of
an image. This may include a table (for example to describe complex data in a graph).
It may be helpful to generate blocks of text and tables and store them in a variable,
and pass that variable to C<long_description>.

C<long_description_width> defaults to 1. This should be a positive number at most 1.
In hardcopy output, this portion of the line width will be used to cap the width
of the long description (if there is one). This is useful for example when the image
is inside a table.

C<extra_html_tags> [DEPRECATED] can be a string will directly be placed into the
HTML img element. For example, C<< extra_html_tags => 'style="border:solid black 1pt"' >>.

The first argument to C<image()> can alternatively be an array of images:

    image([$image1, $image2], ...);

If so then if C<alt> or C<long_description> are not arrays, they will be used
repeatedly for each image. Each of C<alt> and C<long_description> can instead be
arrays of the same length and their entries will be used with the corresponding
image.

In array context, using C<image()> this way will produces an array in array context
and join the elements with C<' '> in scalar context.

=cut

#   More advanced macros
sub image {
	my $image_ref = shift;
	my @opt       = @_;
	unless (scalar(@opt) % 2 == 0) {
		warn "ERROR in image macro.  A list of macros must be inclosed in square brackets.";
	}
	my %in_options    = @opt;
	my %known_options = (
		width    => '',
		height   => '',
		tex_size => '',
		valign   => 'middle',
		# default value for alt is undef, since an empty string is the explicit indicator of a decorative image
		alt                    => undef,
		long_description       => undef,
		long_description_width => 1,
		extra_html_tags        => '',
	);
	# handle options
	my %out_options = %known_options;
	foreach my $opt_name (keys %in_options) {
		if (exists($known_options{$opt_name})) {
			$out_options{$opt_name} = $in_options{$opt_name} if exists($in_options{$opt_name});
		} else {
			die "Option $opt_name not defined for image. " . "Default options are:<BR> ",
				display_options2(%known_options);
		}
	}

	# Get options for width, height, and tex_size, with a sanity check for integer values.
	my $width    = $out_options{width}    =~ /^[1-9]\d*$/ ? $out_options{width}    : '';
	my $height   = $out_options{height}   =~ /^[1-9]\d*$/ ? $out_options{height}   : '';
	my $tex_size = $out_options{tex_size} =~ /^[1-9]\d*$/ ? $out_options{tex_size} : '';
	$width = 200 unless ($width || $height);

	$tex_size = $width ? int($width / 0.6) : 800 unless $tex_size;
	$tex_size = 1000 if $tex_size > 1000;

	my $alt         = $out_options{alt};
	my $desc        = $out_options{long_description};
	my $ldw         = $out_options{long_description_width};
	my $width_ratio = $tex_size * 0.001;
	my @image_list  = ();
	my @alt_list    = ();
	my @desc_list   = ();
	my $valign      = 'middle';
	$valign = 'top'    if ($out_options{valign} eq 'top');
	$valign = 'bottom' if ($out_options{valign} eq 'bottom');

	# if width and/or height are explicit, create string for attribute to be used in HTML
	my $width_attrib  = ($width)  ? qq{ width="$width"}   : '';
	my $height_attrib = ($height) ? qq{ height="$height"} : '';

	if (ref($image_ref) =~ /ARRAY/) {
		@image_list = @{$image_ref};
	} else {
		push(@image_list, $image_ref);
	}
	if (ref($alt) =~ /ARRAY/) {
		@alt_list = @{$alt};
	} else {
		for my $i (@image_list) { push(@alt_list, $alt) }
	}
	if (ref($desc) =~ /ARRAY/) {
		@desc_list = @{$desc};
	} else {
		for my $i (@image_list) { push(@desc_list, $desc) }
	}

	my @output_list = ();
	while (@image_list) {
		my $image_item          = shift @image_list;
		my $description_details = $desc ? shift(@desc_list) : '';
		if ($desc && $displayMode ne 'PTX' && $displayMode ne 'TeX') {
			$description_details = tag(
				'details',
				'aria-live' => 'polite',
				class       => 'image-details',
				name        => 'image-details',
				tag(
					'summary',
					class => 'mt-1',
					title => 'details',
					tag(
						'span',
						class         => 'image-details-btn btn btn-sm btn-secondary fw-bold',
						'aria-hidden' => 'true',
						maketext('image description')
					)
					)
					. tag(
						'div',
						id    => 'LONG-DESCRIPTION-ID',
						class => 'image-details-content bg-white py-2 px-3 my-2 border',
						$description_details
						. tag(
							'div',
							class => 'd-flex justify-content-end mt-2',
							tag(
								'button',
								class => 'image-details-dismiss btn btn-sm btn-secondary',
								type  => 'button',
								maketext('Close image description')
							)
						)
					)
			);
		}
		if (ref $image_item eq 'parser::GraphTool') {
			push(
				@output_list,
				$image_item->generateAnswerGraph(
					$out_options{width} || $out_options{height}   ? (width           => $width, height => $height) : (),
					$out_options{tex_size} || $out_options{width} ? (texSize         => $tex_size)                 : (),
					$desc                                         ? (longDescription => $description_details)      : (),
					ariaDescription => shift @alt_list // ''
				)
			);
			next;
		}
		if (ref $image_item eq 'Plots::Plot') {
			# Update image attributes as needed.
			$image_item->{width}    = $width    if $out_options{width};
			$image_item->{height}   = $height   if $out_options{height};
			$image_item->{tex_size} = $tex_size if $out_options{tex_size};

			if ($image_item->ext eq 'html') {
				$image_item->axes->style(aria_description => shift @alt_list) if $out_options{alt};
				$image_item->{description_details} = $description_details;
				push(@output_list, $image_item->draw);
				next;
			}

			# Use Plots default size and not the 200 default size of image.
			$width_attrib  = qq{ width="$image_item->{width}"}   if $width_attrib;
			$height_attrib = qq{ height="$image_item->{height}"} if $height_attrib;
			$width_ratio   = 0.001 * $image_item->{tex_size};
		}
		$image_item = insertGraph($image_item)
			if (ref $image_item eq 'WWPlot'
				|| ref $image_item eq 'Plots::Plot'
				|| ref $image_item eq 'PGlateximage'
				|| ref $image_item eq 'PGtikz');
		my $imageURL = alias($image_item) // '';
		$imageURL = ($envir{use_site_prefix}) ? $envir{use_site_prefix} . $imageURL : $imageURL;
		my $id  = $main::PG->getUniqueName('img');
		my $out = '';

		if ($displayMode eq 'TeX') {
			my $imagePath = $imageURL;    # in TeX mode, alias gives us a path, not a URL

			# We're going to create PDF files with our TeX (using LaTeX), so
			# alias should have given us the path to a PNG image.
			if ($imagePath) {
				if ($desc) {
					$out .= "\\parbox{$ldw\\linewidth}{";
					$width_ratio = $width_ratio / $ldw;
				}
				if ($valign eq 'top') {
					$out .= '\settoheight{\strutheight}{\strut}\raisebox{-\height + \strutheight}'
						. "{\\includegraphics[width=$width_ratio\\linewidth]{$imagePath}}\n";
				} elsif ($valign eq 'bottom') {
					$out .= "\\includegraphics[width=$width_ratio\\linewidth]{$imagePath}\n";
				} else {
					$out .= '\settoheight{\strutheight}{\strut}\raisebox{-0.5\height + 0.5\strutheight}'
						. "{\\includegraphics[width=$width_ratio\\linewidth]{$imagePath}}\n";
				}
				if ($desc) {
					$out .=
						"\\newline\\par\\parbox{\\linewidth}{{\\scshape\\underline{"
						. maketext('image description')
						. "}}\\newline{}$description_details\\par\\hfill\\(\\overline{\\mbox{\\scshape "
						. maketext('end image description')
						. "}}\\)}}\\par\n";
				}
			}
		} elsif ($displayMode eq 'HTML_MathJax'
			|| $displayMode eq 'HTML_dpng'
			|| $displayMode eq 'HTML'
			|| $displayMode eq 'HTML_tth')
		{
			my $altattrib = '';
			if (defined $alt_list[0]) { $altattrib = 'alt="' . encode_pg_and_html(shift @alt_list) . '"' }
			if ($desc) {
				$out .= tag(
					'div',
					class => 'image-container pb-2',
					qq!<img src="$imageURL" class="image-view-elt $valign" tabindex="0" role="button"!
						. qq!$width_attrib$height_attrib aria-details="${id}_details" $out_options{extra_html_tags} $altattrib>!
						. ($description_details =~ s/LONG-DESCRIPTION-ID/${id}_details/r)
				);
			} else {
				$out .= qq!<img src="$imageURL" class="image-view-elt $valign" tabindex="0" role="button"!
					. qq!$width_attrib$height_attrib $out_options{extra_html_tags} $altattrib>!;
			}
		} elsif ($displayMode eq 'PTX') {
			my $ptxwidth = ($width ? int($width / 6) : 80);
			$out = qq!<image width="$ptxwidth%" source="$imageURL">!;
			if (defined $alt) {
				$out .= "\n<shortdescription>$alt</shortdescription>";
			}
			if (defined $desc) {
				$out .= "\n<description>\n" . PTX_cleanup($description_details) . "\n</description>";
			}
			if (defined $alt || defined $desc) {
				$out .= "\n";
			}
			$out .= '</image>';
		} else {
			$out = "Error: PGbasicmacros: image: Unknown displayMode: $displayMode.\n";
		}
		push(@output_list, $out);
	}
	return wantarray ? @output_list : join(' ', @output_list);
}

#This is bare bones code for embedding svg
sub embedSVG {
	my $file_name        = shift;          # just input the file name of the svg image
	my $backup_file_name = shift // '';    # a png version
	my $str              = '';
	if ($backup_file_name) {
		$str = q!" oneerror="this.src='! . alias($backup_file_name) . q!'!;
	}
	return MODES(
		HTML => q!
		<img src="! . alias($file_name) . $str . q!">!,
		TeX => "\\includegraphics[width=6in]{" . alias($file_name) . "}",
		PTX => '<image source="' . alias($file_name) . '" />',
	);
}

# This is bare bones code for embedding png files -- what else should be added? (there are .js scripts for example)
sub embedPDF {
	my $file_name = shift;    # just input the file name of the svg image
							  #my $backup_file_name = shift//'';  # a png version
	return MODES(
		HTML => q!
		<object data=! . alias($file_name) . q!  type="application/pdf"
		width="100%"
		height="100%"></object>!,
		TeX => "\\includegraphics[width=6in]{" . alias($file_name) . "}",
		PTX => '<image source="' . alias($file_name) . '" />',
	);
}

sub video {
	my $video_ref = shift;
	my @opt       = @_;
	unless (scalar(@opt) % 2 == 0) {
		warn "ERROR in video macro.  A list of macros must be inclosed in square brackets.";
	}
	my %in_options    = @opt;
	my %known_options = (
		width           => 400,
		height          => 400,
		extra_html_tags => '',
	);
	# handle options
	my %out_options = %known_options;
	foreach my $opt_name (keys %in_options) {
		if (exists($known_options{$opt_name})) {
			$out_options{$opt_name} = $in_options{$opt_name} if exists($in_options{$opt_name});
		} else {
			die "Option $opt_name not defined for video. " . "Default options are:<BR> ",
				display_options2(%known_options);
		}
	}
	my $width  = $out_options{width};
	my $height = $out_options{height};

	my @video_list = ();

	if (ref($video_ref) =~ /ARRAY/) {
		@video_list = @{$video_ref};
	} else {
		push(@video_list, $video_ref);
	}

	my @output_list = ();
	while (@video_list) {

		my $video    = shift @video_list // '';
		my $videoURL = alias($video)     // '';
		$video =~ /.*\.(\w*)/;
		my $type = $1;
		my $out;
		my $htmlmessage = maketext("Your browser does not support the video tag.");

		if ($displayMode eq 'TeX') {

			$videoURL = ($envir{use_site_prefix}) ? $envir{use_site_prefix} . $videoURL : $videoURL;
			$out =
				"\\begin{center} {\\bf "
				. maketext("This problem contains a video which must be viewed online.")
				. "} \\end{center}";

		} elsif ($displayMode eq 'HTML_MathJax'
			|| $displayMode eq 'HTML_dpng'
			|| $displayMode eq 'HTML'
			|| $displayMode eq 'HTML_tth')
		{
			$out = qq!<VIDEO WIDTH="$width" HEIGHT="$height" CONTROLS>\n
			<SOURCE SRC="$videoURL" TYPE="video/$type">\n
			${htmlmessage}\n
			</VIDEO>\n
			!
		} elsif ($displayMode eq 'PTX') {
			my $ptxwidth = 400 * $width / 600;
			$out = qq!<video source="$videoURL" width="$ptxwidth%" />!;
		} else {
			$out = "Error: PGbasicmacros: video: Unknown displayMode: $displayMode.\n";
		}
		push(@output_list, $out);
	}
	return wantarray ? @output_list : $output_list[0];
}

# This is legacy code.
sub images {
	my @in      = @_;
	my @outlist = ();
	while (@in) {
		push(@outlist, &image(shift(@in)));
	}
	@outlist;
}

sub caption {
	my ($out) = @_;
	$out = " $out \n" if $displayMode eq 'TeX';
	$out = " $out  "  if $displayMode eq 'HTML';
	$out = " $out  "  if $displayMode eq 'HTML_tth';
	$out = " $out  "  if $displayMode eq 'HTML_dpng';
	$out;
}

sub captions {
	my @in      = @_;
	my @outlist = ();
	while (@in) {
		push(@outlist, &caption(shift(@in)));
	}
	@outlist;
}

sub imageRow {

	my $pImages   = shift;
	my $pCaptions = shift;
	my $out       = "";
	my @images    = @$pImages;
	my @captions  = @$pCaptions;
	my $number    = @images;
	# standard options
	my %options = (
		'tex_size' => 200,    # width for fitting 4 across
		'height'   => 200,
		'width'    => 200,
		@_                    # overwrite any default options
	);

	if ($displayMode eq 'TeX') {
		$out .= "\n\\par\\smallskip\\begin{center}\\begin{tabular}{" . "|c" x $number . "|} \\hline\n";
		while (@images) {
			$out .= &image(shift(@images), %options) . '&';
		}
		chop($out);
		$out .= "\\\\ \\hline \n";
		while (@captions) {
			$out .= &caption(shift(@captions)) . '&';
		}
		chop($out);
		$out .= "\\\\ \\hline \n\\end {tabular}\\end{center}\\par\\smallskip\n";
	} elsif ($displayMode eq 'HTML_MathJax'
		|| $displayMode eq 'HTML_dpng'
		|| $displayMode eq 'HTML'
		|| $displayMode eq 'HTML_tth')
	{
		$out .= "<P>\n <TABLE BORDER=2 CELLPADDING=3 CELLSPACING=2><TR ALIGN=CENTER VALIGN=MIDDLE>\n";
		while (@images) {
			$out .= " \n<TD>" . &image(shift(@images), %options) . "</TD>";
		}
		$out .= "</TR>\n<TR>";
		while (@captions) {
			$out .= " <TH>" . &caption(shift(@captions)) . "</TH>";
		}
		$out .= "\n</TR></TABLE></P>\n";
	} else {
		$out = "Error: PGbasicmacros: imageRow: Unknown displayMode: $displayMode.\n";
		warn $out;
	}
	$out;
}

=head2 Tag helper method:

	tag('input', name => 'AnSwEr0001', id => 'answer_id')
	tag('div', class => 'style-class', 'This is my content')

This produces an html tag with attributes.  This is designed to be similar to
the Mojolicious::Plugin::TagHelpers tag method (although much simpler and not
nearly as versatile).  The first argument is the tag name and is required.  This
is followed by attribute C<< name => value >> pairs.  Note that all underscores
in attribute names are converted into hyphens.  The final argument is the
content of the tag.  If not given the tag will have no content.  This is ignored
for a self closing tag if given.

Currently this is only designed to be used for HTML output, but perhaps could be
extended for XML (PTX) output.

=cut

# Self closing tags.
my %SELF_CLOSING = map { $_ => 1 } qw(area base br col embed hr img input link meta source track wbr);

sub tag {
	my ($tag, @data) = @_;
	my $content    = @data % 2 ? pop @data : '';
	my %attributes = @data;

	my $attributes_str = join(
		' ',
		map {
			($_ =~ s/_/-/gr) . (defined $attributes{$_} ? ('="' . encode_pg_and_html($attributes{$_})) . '"' : '')
		}
			keys %attributes
	);

	return "<$tag" . ($attributes_str ? " $attributes_str" : '') . '>' . ($SELF_CLOSING{$tag} ? '' : "$content</$tag>");
}

###########
# Auxiliary macros

sub display_options2 {
	my %options    = @_;
	my $out_string = "";
	foreach my $key (keys %options) {
		$out_string .= " $key => $options{$key}, <BR>";
	}
	$out_string;
}

1;
