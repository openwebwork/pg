###############################################################################
# WeBWorK Online Homework Delivery System
# Copyright © 2000-2007 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader: pg/lib/PGcore.pm,v 1.6 2010/05/25 22:47:52 gage Exp $
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

##################################
# Utility macro 
##################################

=head2  Utility Macros


=head4  not_null
     
  not_null(item)  returns 1 or 0
     
     empty arrays, empty hashes, strings containing only whitespace are all NULL and return 0
     all undefined quantities are null and return 0


=cut

use strict;
use warnings;
use Exporter 'import';
our @EXPORT = qw(
	not_null 
	pretty_print
);

sub not_null {        # empty arrays, empty hashes and strings containing only whitespace are all NULL
                      # in modern perl // would be a reasonable and more robust substitute
                      # a function, not a method
    my $item = shift;
	return 0 unless defined($item);
	if (ref($item)=~/ARRAY/) {
		return scalar(@{$item});     # return the length    
	} elsif (ref($item)=~/HASH/) {
	    return scalar( keys %{$item});
	} else {   # string case return 1 if none empty	
	  return ($item =~ /\S/)? 1:0;
	}
}

=head4 pretty_print

	Usage: warn pretty_print( $rh_hash_input)
		   TEXT(pretty_print($ans_hash));
		   TEXT(pretty_print(~~%envir ));

This can be very useful for printing out HTML messages about objects while debugging

=cut

# ^function pretty_print
# ^uses lex_sort
# ^uses pretty_print


sub pretty_print {
	my $r_input        = shift;
	my $displayMode    = shift;
	my $out = '';
	if ($displayMode eq 'TeX' ) {
	    $out .="{\\tiny";
		$out .= pretty_print_tex($r_input);	
		$out .="}";
	} else {
		$out =pretty_print_html($r_input);  #default
	}
	$out;
}

sub pretty_print_html {    # provides html output -- NOT a method
    my $r_input = shift;
    my $level = shift;
    $level = 5 unless defined($level);
    $level--;
    return "PGalias has too much info. Try \$PG->{PG_alias}->{resource_list}" if ref($r_input) eq 'PGalias';  # PGalias just has too much information
    return 'too deep' unless $level > 0;  # only print four levels of hashes (safety feature)
    my $out = '';
    if ( not ref($r_input) ) {
    	$out = $r_input if defined $r_input;    # not a reference
    	$out =~ s/</&lt;/g  ;  # protect for HTML output
    } elsif ("$r_input" =~/hash/i) {  # this will pick up objects whose '$self' is hash and so works better than ref($r_iput).
	    local($^W) = 0;
	    
		$out .= "$r_input " ."<TABLE border = \"2\" cellpadding = \"3\" BGCOLOR = \"#FFFFFF\">";
		
		
		foreach my $key ( sort ( keys %$r_input )) {
			$out .= "<tr><TD> $key</TD><TD>=&gt;</td><td>&nbsp;".pretty_print_html($r_input->{$key}, $level) . "</td></tr>";
		}
		$out .="</table>";
	} elsif (ref($r_input) eq 'ARRAY' ) {
		my @array = @$r_input;
		$out .= "( " ;
		while (@array) {
			$out .= pretty_print_html(shift @array, $level) . " , ";
		}
		$out .= " )";
	} elsif (ref($r_input) eq 'CODE') {
		$out = "$r_input";
	} else {
		$out = $r_input;
		$out =~ s/</&lt;/g; # protect for HTML output
	}
		$out;
}

sub pretty_print_tex {
	my $r_input = shift;
	my $level   = shift;
    $level      = 5 unless defined($level);
	$level--;
	return "PGalias has too much info. Try \\\$PG->{PG\\_alias}->{resource\\_list}" if ref($r_input) eq 'PGalias';  # PGalias just has too much information
	return 'too deep' unless $level>0;  #only print four levels of hashes (safety feature)
	
	my $protect_tex = sub {my $str = shift; $str=~s/_/\\\_/g; $str };

	my $out = '';
	if ( not  ref($r_input) ) {
		$out = $r_input if defined $r_input;
		$out =~ s/_/\\\_/g;   # protect tex
		$out =~ s/&/\\\&/g;
		$out =~ s/\$/\\\$/g;
	} elsif ("$r_input" =~/hash/i) {  # this will pick up objects whose '$self' is hash and so works better than ref($r_iput).
		local($^W) = 0;
	    
		$out .= "\\begin{tabular}{| l | l |}\\hline\n\\multicolumn{2}{|l|}{$r_input}\\\\ \\hline\n";
		
		
		foreach my $key ( sort ( keys %$r_input )) {
			$out .= &$protect_tex(  $key ). " & ".pretty_print_tex($r_input->{$key}, $level) . "\\\\ \\hline\n";
		}
		$out .="\\end{tabular}\n";
	} elsif (ref($r_input) eq 'ARRAY' ) {
		my @array = @$r_input;
		$out .= "( " ;
		while (@array) {
			$out .= pretty_print_tex(shift @array, $level) . " , ";
		}
		$out .= " )";
	} elsif (ref($r_input) eq 'CODE') {
		$out = "$r_input";
	} else {
		$out = $r_input if defined $r_input;
		$out =~ s/_/\\\_/g;   # protect tex
		$out =~ s/&/\\\&/g;
	}
		$out;
}

1;
