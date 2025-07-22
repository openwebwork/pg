
=head1 NAME

contextLeadingZero.pl - Require numeric answers to have a 0 before the decimal point.

=head1 DESCRIPTION

Require numeric answers to have a 0 before the decimal point.

=cut

loadMacros("contextLimitedNumeric.pl");

$context{LeadingZero} = Parser::Context->getCopy("LimitedNumeric");
$context{LeadingZero}->{name} = "LeadingZero";
$context{LeadingZero}->flags->set(
	NumberCheck => sub {
		my $self = shift;
		$self->Error("Decimals must have a number before the decimal point")
			if $self->{value_string} =~ m/^\./;
	}
);
