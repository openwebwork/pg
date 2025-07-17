sub _choiceUtils_init { };    # don't reload this file

#
#  A replacement for std_print_q that uses tables to align the questions, so
#  that if a question wraps, it is properly indented.
#

sub alt_print_q {
	my $self      = shift;
	my @questions = @_;
	my $length    = $self->{ans_rule_len};
	my $sep       = $self->{separation};
	$sep = 0 unless defined($sep);
	my $valign = $self->{valign};
	$valign = "TOP" unless defined($valign);
	my $i = 1;
	my $quest;

	my $out = "";
	if ($main::displayMode =~ m/^HTML/) {
		$out = "\n<P>\n<TABLE BORDER=0 CELLPADDING=0 CELLSPACING=$sep>\n";
		foreach $quest (@questions) {
			$out .=
				'<TR VALIGN="'
				. $valign
				. '"><TD>'
				. ans_rule($length)
				. "&nbsp;</TD><TD><B>"
				. $i++
				. ".</B>&nbsp;</TD><TD>$quest</TD></TR>\n";
		}
		$out .= "</TABLE>\n";
	} elsif ($main::displayMode eq 'TeX') {
		$out = "\n\\par\\begin{enumerate}\n\\advance\\leftskip by 2em";
		foreach $quest (@questions) { $out .= "\\item[" . ans_rule($length) . ' ' . $i++ . ".] $quest\n" }
		$out .= "\\end{enumerate}\n";
	} else {
		$out = "Error: alt_print_q: Unknown displayMode: $main::displayMode.";
	}
	$out;
}

sub alt_print_a {
	my $self    = shift;
	my (@array) = @_;
	my $sep     = $self->{separation} || 0;
	my $valign  = $self->{valign}     || "TOP";
	my $i       = 0;

	my $out = MODES(
		TeX  => "\\begin{enumerate}\n",
		HTML => qq{<TABLE BORDER="0" CELLSPACING="$sep" CELLPADDING=0>},
	);
	my $elem;
	foreach $elem (@array) {
		my $c = $main::ALPHABET[$i];
		$out .= MODES(
			TeX  => "\\item[$c.] $elem\n",
			HTML => qq{<TR VALIGN="$valign"><TD STYLE="height: 1.5em"><B>$c.</B>&nbsp;</TD><TD>$elem</TD></TR>\n},
		);
		$i++;
	}
	$out .= MODES(
		TeX  => "\\end{enumerate}\n",
		HTML => "</TABLE>\n",
	);
	$out;
}

1;
