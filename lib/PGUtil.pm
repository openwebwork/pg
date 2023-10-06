###############################################################################
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

package PGUtil;
use parent 'Exporter';

=head1 NAME

PGUtil.pm - Utility Methods

=head1 METHODS

=cut

use strict;
use warnings;

our @EXPORT_OK = qw(not_null pretty_print);

=head2 not_null

Usage:

    not_null($item)

Returns 1 if C<$item> is not null, and 0 otherwise.  Undefined quantities, empty
arrays, empty hashes, and strings containing only whitespace are null and return
0.

=cut

sub not_null {
	my $item = shift;
	return 0 unless defined $item;
	if (ref($item) =~ /ARRAY/) {
		return scalar(@$item);    # return the length
	} elsif (ref($item) =~ /HASH/) {
		return scalar(keys %$item);
	} else {    # string case return 1 if none empty
		return ($item =~ /\S/) ? 1 : 0;
	}
}

=head2 pretty_print

Usage:

    pretty_print($rh_hash_input, $displayMode, $level)

This method is useful for displaying the contents of objects while debugging.

The C<$displayMode> parameter should be one of "TeX", "text", or "html"
The default is "html".

The C<$level> parameter is the cut off for the depth into objects to show.  The
default is 5.

=cut

sub pretty_print {
	my ($r_input, $displayMode, $level) = @_;
	$displayMode //= 'html';    # default printing style is html
	$level       //= 5;         # default is 5 levels deep
	if ($displayMode eq 'TeX') {
		return '{\\tiny' . pretty_print_tex($r_input, $level) . '}';
	} elsif ($displayMode eq 'text') {
		return pretty_print_text($r_input, $level);
	} else {
		return pretty_print_html($r_input, $level);    #default
	}
}

# Note that the following methods use `eval { %$r_input || 1 }` to detect all objectes that can be accessed like a hash.
# `ref $r_input` will not see blessed objects that can be accessed like a hash.  Previously `"$r_input" =~ /hash/i` was
# used.  This will also detect strings containing the word hash, and will cause errors.

sub pretty_print_html {    # provides html output -- NOT a method
	my ($r_input, $level) = @_;
	return 'undef' unless defined $r_input;

	my $ref = ref $r_input;

	# Don't display PGalias.  It has too much information.
	return 'PGalias has too much info. Try $PG->{PG_alias}{resource_list}' if $ref eq 'PGalias';

	--$level;
	return 'too deep' unless $level > 0;

	# Protect against modules defined in Safe which can't find their stringify procedure.
	return "Unable to determine stringify for this item.\n$@\n" if !eval { "$r_input" || 1 } || $@;

	if (!$ref) {
		return $r_input =~ s/</&lt;/gr;
	} elsif (eval { %$r_input || 1 }) {
		return '<div style="display:table;border:1px solid black;background-color:#fff;">'
			. ($ref eq 'HASH'
				? ''
				: '<div style="'
				. 'display:table-caption;padding:3px;border:1px solid black;background-color:#fff;text-align:center;">'
				. "$ref</div>")
			. '<div style="display:table-row-group">'
			. join(
				'',
				map {
					'<div style="display:table-row"><div style="display:table-cell;vertical-align:middle;padding:3px">'
					. ($_ =~ s/</&lt;/gr)
					. '</div>'
					. qq{<div style="display:table-cell;vertical-align:middle;padding:3px">=&gt;</div>}
					. qq{<div style="display:table-cell;vertical-align:middle;padding:3px">}
					. pretty_print_html($r_input->{$_}, $level)
					. '</div></div>'
				}
				sort keys %$r_input
			) . '</div></div>';
	} elsif ($ref eq 'ARRAY') {
		return '[ ' . join(', ', map { pretty_print_html($_, $level) } @$r_input) . ' ]';
	} elsif ($ref eq 'CODE') {
		return 'CODE';
	} else {
		return $r_input =~ s/</&lt;/gr;
	}
}

sub pretty_print_tex {
	my ($r_input, $level) = @_;
	return 'undef' unless defined $r_input;

	my $ref = ref($r_input);

	# Don't display PGalias.  It has too much information.
	return 'PGalias has too much info. Try \\$PG->{PG\\_alias}->{resource\\_list}' if $ref eq 'PGalias';

	--$level;
	return 'too deep' unless $level > 0;

	# Protect against modules defined in Safe which can't find their stringify procedure.
	return "Unable to determine stringify for this item.\n$@\n" if !eval { "$r_input" || 1 } || $@;

	my $protect_tex = sub { my $str = shift; return (($str =~ s/_/\\\_/gr) =~ s/&/\\\&/gr) =~ s/\$/\\\$/gr; };

	# Note: Do not add newlines to this.  If this is in a PGML section
	# those will cause errors due to PGML's catcode hackery.
	if (!$ref) {
		return $protect_tex->($r_input);
	} elsif (eval { %$r_input || 1 }) {
		return
			"\\begin{tabular}{|l|l|}\\hline "
			. ($ref eq 'HASH' ? '' : "\\multicolumn{2}{|l|}{" . $protect_tex->($ref) . "}\\\\ \\hline ")
			. join('',
			map { $protect_tex->($_) . " & " . pretty_print_tex($r_input->{$_}, $level) . "\\\\ \\hline "; }
			sort (keys %$r_input))
			. "\\end{tabular}";
	} elsif ($ref eq 'ARRAY') {
		return '[ ' . join(', ', map { pretty_print_tex($_, $level) } @$r_input) . ' ]';
	} elsif ($ref eq 'CODE') {
		return 'CODE';
	} else {
		return $protect_tex->($r_input);
	}
}

sub pretty_print_text {
	my ($r_input, $level, $print_level) = @_;
	return 'undef' unless defined $r_input;

	my $ref = ref($r_input);

	# Don't display PGalias.  It has too much information.
	return 'PGalias has too much info. Try $PG->{PG_alias}->{resource_list}' if $ref eq 'PGalias';

	--$level;
	return 'too deep' unless $level > 0;

	# Protect against modules defined in Safe which can't find their stringify procedure.
	return "Unable to determine stringify for this item.\n$@\n" if !eval { "$r_input" || 1 } || $@;

	$print_level //= 1;

	if (!$ref) {
		return $r_input;
	} elsif (eval { %$r_input || 1 }) {
		return
			($ref eq 'HASH' ? '' : "$ref ") . "{\n"
			. join(",\n",
			map { ('  ' x $print_level) . "$_ => " . pretty_print_text($r_input->{$_}, $level, $print_level + 1) }
			sort keys %$r_input)
			. "\n"
			. ('  ' x ($print_level - 1)) . "}";
	} elsif ($ref eq 'ARRAY') {
		return
			"[\n"
			. join(",\n", map { ('  ' x $print_level) . pretty_print_text($_, $level, $print_level + 1) } @$r_input)
			. "\n"
			. ('  ' x ($print_level - 1)) . "]";
	} elsif ($ref eq 'CODE') {
		return 'CODE';
	} else {
		return $r_input;
	}
}

1;
