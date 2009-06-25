################################################################################
# WeBWorK Online Homework Delivery System
# Copyright © 2000-2007 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader$
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

problemPreserveAnswers.pl - Allow sticky answers to preserve special characters.

=head1 DESCRIPTION

This file implements a fragile hack to overcome a problem with
PGbasicmacros.pl, which removes special characters from student
answers (in order to prevent EV3 from mishandling them).

Unfortunately, this means that "sticky" answers will lose
those characters, which makes it very difficult to answer
problems with more than one answer when the student wants
to submit several times while working on later parts.

The real fix to to rewrite PGbasicmacros.pl to handle
this better, but this hack will handle the situation for
now until that can be accomplished.

To use this hack, simply load the file using

	loadMacros("problemPreserveAnswers.pl");

at the top of your PG file.

=cut

sub _problemPreserveAnswers_init {PreserveAnswers::Init()}

package PreserveAnswers;

#
#  Escape the specials in answers, and then
#  override ENDDOCUMENT() to restore the answers
#  to their original values.
#
sub Init {
  PreserveAnswers::EscapeAnswers();
  $PreserveAnswers::ENDDOCUMENT = \&main::ENDDOCUMENT;
  main::PG_restricted_eval
    ('sub ENDDOCUMENT {PreserveAnswers::RestoreAnswers(); &$PreserveAnswers::ENDDOCUMENT(@_)}');
}

#
#  This is a fragile hack to prevent PG from removing the
#  dollar signs in currency answers (and everything else as well).
#  PGbasicmacros.pl needs to be fixed to allow this without
#  having to do this terrible hack.
#
sub EscapeAnswers {
  my $original = $main::inputs_ref_orig = {%{$main::inputs_ref}};
  my $inputs   = $main::inputs_ref;
  foreach my $id (keys %{$original}) {
    my $value = $original->{$id};
    next if !defined($value) || ref($value);
    $value =~ s/([\\\$@\`"&<>])/EscapeHTMLchar($1)/ge;
    $inputs->{$id} = $value;
  }
}

sub EscapeHTMLchar {main::spf(ord(shift),"&#x%02X;")}

sub RestoreAnswers {
  my $original = $main::inputs_ref_orig;
  my $inputs   = $main::inputs_ref;
  foreach my $id (keys %{$original}) {$inputs->{$id} = $original->{$id}}
}

our $ENDDOCUMENT; # holds pointer to original ENDDOCUMENT

######################################################################

1;
