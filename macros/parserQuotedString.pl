package QuotedString;
@ISA = qw(Parser::String);

sub new {
  my $self = shift; my ($equation,$value,$ref) = @_;
  my $str = $self->SUPER::new(@_);
  unless ($str->{equation}{context}{strings}{$str->{value}}) {
    $equation->Error("Missing close quote",$ref) if $str->{value} eq '"';
    $str->{value} =~ s/^"(.*)"$/$1/;
    $str->{value} =~ s/\\"/"/g;
    $str->{isQuoted} = 1;
  }
  return $str;
}

sub string {
  my $self = shift; my $string = $self->SUPER::string(@_);
  if ($self->{isQuoted}) {
    $string =~ s/"/\\"/g;
    $string = '"'.$string.'"';
  }
  return $string
}

sub enable {
  my $context = shift;
  QuotedString::enableQuotes($context);
  QuotedString::enableAdd($context);
}

sub enableQuotes {
  my $context = shift;
  $context->{parser}{String} = 'QuotedString';
  bless $context->{_strings}, 'QuotedString::Data';
  $context->strings->update;
}

sub enableAdd {
  my $context = shift;
  $context->operators->set('+' => {class=>"QuotedString::BOP::add"});
}

package QuotedString::Data;
@ISA = qw(Parser::Context::Strings);

sub update {
  my $self = shift;
  $self->SUPER::update;
  $self->{patterns}{'"(?:[^\\\\]|\\\\.)*?"|"'} = [10,'str'];
  $self->{context}->update;
}

package QuotedString::BOP::add;
@ISA = qw(Parser::BOP::add);

sub checkStrings {
  my $self = shift;
  my $ltype = $self->{lop}->typeRef; my $rtype = $self->{rop}->typeRef;
  return 1 if $ltype->{name} eq 'String' && $rtype->{name} eq 'String';
  return $self->SUPER::checkStrings(@_);
}

sub _eval {
  my $self = shift;
  my $ltype = $self->{lop}->typeRef; my $rtype = $self->{rop}->typeRef;
  return Value::String->make($_[0] . $_[1])
    if $ltype->{name} eq 'String' && $rtype->{name} eq 'String';
  $self->SUPER::_eval(@_);
}

1;
