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

loadMacros('MathObjects.pl');

sub _quickMatrixEntry_init {
	ADD_JS_FILE('js/QuickMatrixEntry/quickmatrixentry.js', 0, { defer => undef });
	return;
}

sub QuickMatrixEntry { return parser::QuickMatrixEntry->new(@_) }

package parser::QuickMatrixEntry;
our @ISA = qw(Value::Matrix);

# Allow promotion of Value::Matrix objects.
sub promote {
	my ($self, @args) = @_;
	my $context = Value::isContext($args[0]) ? shift @args : $self->context;
	my $x       = @args                      ? shift @args : $self;
	return $self->new($context, $x, @args) if @args || ref($x) eq 'ARRAY';
	$x = Value::makeValue($x, context => $context);
	return $x->inContext($context)              if ref($x) eq 'Value::Matrix' || ref($x) eq (ref($self) || $self);
	return $self->make($context, @{ $x->data }) if Value::classMatch($x, 'Point', 'Vector');
	Value::Error(q{Can't convert %s to %s}, Value::showClass($x), Value::showClass($self));
	return;
}

sub ans_array {
	my ($self, $size, @options) = @_;

	my $name = main::NEW_ANS_NAME();
	main::RECORD_IMPLICIT_ANS_NAME($name);

	my ($rows, $columns) = $self->dimensions;

	return main::tag(
		'div',
		class => 'my-2',
		main::tag(
			'button',
			class        => 'quick-matrix-entry-btn btn btn-secondary',
			type         => 'button',
			name         => $name,
			data_rows    => $rows,
			data_columns => $columns,
			main::maketext('Quick Entry')
		)
	) . $self->SUPER::named_ans_array($name, $size, @options, answer_group_name => $name);
}

sub type  { return 'Matrix'; }
sub class { return 'Matrix'; }

# Backwards compatibility. This is deprecated and should not be used.

package main;

sub INITIALIZE_QUICK_MATRIX_ENTRY { }

sub MATRIX_ENTRY_BUTTON {
	my ($matrix, $rows, $columns) = @_;

	my $answer_number;

	if (Value::isValue($matrix) && Value::classMatch($matrix, 'Matrix')) {
		# Given a MathObject matrix.
		($rows, $columns) = $matrix->dimensions;
		# This assumes that the quick entry button comes before the matrix answer blanks.
		$answer_number = $main::PG->{answer_name_count} + 1;
	} else {
		$answer_number = $matrix;
	}

	$rows    //= 1;
	$columns //= 5;

	return tag(
		'div',
		class => 'my-2',
		tag(
			'button',
			class        => 'quick-matrix-entry-btn btn btn-secondary',
			type         => 'button',
			name         => 'AnSwEr' . sprintf('%04d', $answer_number),
			data_rows    => $rows,
			data_columns => $columns,
			maketext('Quick Entry')
		)
	);
}

1;

__END__

=head1 NAME

quickMatrixEntry.pl - Add a button to MathObject C<Matrix> array answers that
allows pasting of matrix contents.

=head1 DESCRIPTION

A QuickMatrixEntry object lets you add a "Quick Entry" button to a MathObject
C<Matrix> array answer.  When the button is clicked it opens a dialog in which
you can edit the entries of the matrix in a text area.  This allows pasting of
large matrices from other sources.

A QuickMatrixEntry object is created in much the same way that a MathObject
C<Matrix> is created.  Set the context to the C<Matrix> context, and call the
C<QuickMatrixEntry> method with an array of arrays. For example,

    Context('Matrix');

    $matrix = QuickMatrixEntry([
        [ 1, 2, 3, 4, 5, 6, 7, 8 ],
        [ 8, 7, 6, 5, 4, 3, 2, 1 ],
        [ 1, 2, 3, 4, 5, 6, 7, 8 ],
        [ 8, 7, 6, 5, 4, 3, 2, 1 ],
        [ 1, 2, 3, 4, 5, 6, 7, 8 ]
    ]);

Then add the array of answer rules to the problem with

    BEGIN_PGML
    [_]*{$matrix}{4}
    END_PGML

Other than the button that is added above the array of answers, the
C<QuickMatrixEntry> is just a MathObject C<Matrix>, and everything that can be
done with a MathObject C<Matrix> can also be done with a C<QuickMatrixEntry>.
However, if not used via C<ans_array> (the starred answer form in PGML) the
button will not be added and the C<QuickMatrixEntry> object will be nothing more
than a MathObject C<Matrix>.  This generally should not be done.

=cut
