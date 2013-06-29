sub _contextComplexJ_init {
  my $context = $main::context{Complex} = Parser::Context->getCopy("Complex");
  $context->{value}{Complex} = "context::Complex";
  $context->constants->remove("i");
  $context->constants->add(j => context::Complex->new(0,1));
  $context->constants->set(j => {isConstant => 1, perl=>"j"});
}

package context::Complex;
our @ISA = ('Value::Complex');

sub string {
  my $self = shift;
  my $z = Value::Complex::format($self->{format},$self->value,'string',@_);
  $z =~ s/i/j/;
  return $z;
}
sub TeX {
  my $self = shift;
  my $z = Value::Complex::format($self->{format},$self->value,'TeX',@_);
  $z =~ s/i/j/;
  return $z;
}
