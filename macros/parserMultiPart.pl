################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2018 The WeBWorK Project, http://openwebwork.sf.net/
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

parserMultiPart.pl - [DEPRECATED] Renamed to MultiAnswer.

=head1 DESCRIPTION

This object has been renamed MultiAnswer and is now available in
parserMultiAnswer.pl.  Using a MultiPart object will produce a
warning to that effect.

=cut

sub _parserMultiPart_init {}

loadMacros("parserMultiAnswer.pl");
sub MultiPart {
  warn "The MultiPart object has been deprecated.${BR}You should use MultiAnswer object instead";
  parser::MultiAnswer->new(@_);
}


1;
