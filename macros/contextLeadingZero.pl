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
