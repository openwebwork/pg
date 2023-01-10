
# not sure why these are loaded.  They are not used in this file.  If these are loaded
# there is an error during the load_macros.t test.

# loadMacros("unionImage.pl", "unionTables.pl",);

$bHTML = '\begin{rawhtml}';
$eHTML = '\end{rawhtml}';

#  HTML(htmlcode)
#  HTML(htmlcode,texcode)
#
#  Insert $html in HTML mode.  In TeX mode, insert nothing for the first form,
#  and $tex for the second form.
#
sub HTML {
	my ($html, $tex) = @_;
	return ('') unless (defined($html) && $html ne '');
	$tex = ''   unless (defined($tex));
	MODES(TeX => $tex, HTML => $html);
}

#
#  Begin and end <TT> mode
#
$BTT = HTML('<TT>',  '\texttt{');
$ETT = HTML('</TT>', '}');

#
#  Begin and end <SMALL> mode
#
$BSMALL = HTML('<SMALL>',  '{\small ');
$ESMALL = HTML('</SMALL>', '}');

#
#  Block quotes
#
$BBLOCKQUOTE = HTML('<BLOCKQUOTE>', '\hskip3em ');
$EBLOCKQUOTE = HTML('</BLOCKQUOTE>');

#
#  Smart-quotes in TeX mode, regular quotes in HTML mode
#
$LQ = MODES(TeX => '``', HTML => '"');
$RQ = MODES(TeX => "''", HTML => '"');

#
#  make sure all characters are displayed
#
sub protectHTML {
	my $string = shift;
	$string =~ s/&/\&amp;/g;
	$string =~ s/</\&lt;/g;
	$string =~ s/>/\&gt;/g;
	$string;
}

sub _parserUtils_init { }

1;
