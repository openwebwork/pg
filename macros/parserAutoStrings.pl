
=head1 AutoStrings();

=head1 DefineStrings("string1","string2",...);

######################################################################
#
#  This file allows you to force String() to accept ANY string as a
#  legal value.  (It will add the string to the context if it isn't
#  already defined.)
#
#  To acocmplish this, put the lines
#
#    loadMacros("parserAutoStrings.pl");
#    AutoStrings();
#
#  (You can also pass AutoStrings a context pointer if you wish to
#  alter context other than the current one.)
#
#  There is also a routine to help making strings easier to predefine.
#  Fr example:
#
#    loadMacros("parserAutoStrings.pl");
#    DefineStrings("string1","string2");
#
#  would define two new strings (string1 and string2).  You can pass
#  a context reference as the first argument to add strings to that
#  context rather than the active one.
#
######################################################################

=cut

sub _parserAutoStrings_init {}

######################################################################

sub AutoStrings {(shift || Value->context)->{value}{"String()"} = "parser::AutoStrings"};

sub DefineStrings {
  my $context = (Value::isContext($_[0]) ? shift : Value->context);
  foreach my $x (@_)
    {$context->strings->add($x=>{}) unless defined $context->{strings}{$x}}
}

######################################################################

package parser::AutoStrings;
our @ISA = ("Value::String");

sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $context = (Value::isContext($_[0]) ? shift : $self->context);
  my $x = join('',@_);
  $context->strings->add($x=>{}) unless defined $context->{strings}{$x};
  $self->SUPER::new($x);
}

######################################################################

1;
