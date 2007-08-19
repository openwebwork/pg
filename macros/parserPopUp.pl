loadMacros('MathObjects.pl','contextString.pl');

Context("Numeric");

sub _parserPopUp_init {}; # don't reload this file

=head1 DESCRIPTION

 ####################################################################
 #
 #  This file implements a pop-up menu object that is compatible
 #  with Value objects, and in particular, with the MultiPart object.
 #
 #  To create a PopUp object, use
 #
 #    $popup = PopUp([choices,...],correct);
 #
 #  where "choices" are the strings for the items in the popup menu,
 #  and "correct" is the choice that is the correct answer for the
 #  popup.
 #
 #  To insert the popup menu into the problem text, use
 #
 #    BEGIN_TEXT
 #      \{$popup->menu\}
 #    END_TEXT
 #
 #  and then
 #
 #    ANS($popup->cmp);
 #
 #  to get the answer checker for the popup.
 #
 #  You can use the PopUp menu object in MultiPart objects.  This is
 #  the reason for the pop-up menu's ans_rule method (since that is what
 #  MultiPart calls to get answer rules).
 #

=cut

sub PopUp {parserPopUp->new(@_)}

#
#  The package that implements pop-up menus
#
package parserPopUp;
our @ISA = qw(Value::String);

sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $choices = shift; my $value = shift;
  Value::Error("A PopUp's first argument should be a list of menu items")
    unless ref($choices) eq 'ARRAY';
  Value::Error("A PopUp's second argument should be the correct menu choice")
    unless defined($value) && $value ne "";
  my $oldContext = main::Context();
  my $context = $main::context{String}->copy;
  main::Context($context);
  $context->strings->add(map {$_=>{}} @{$choices});
  my $self = bless Value::String->new($value), $class;
  $self->{isValue} = 1; $self->{choices} = $choices;
  $self->{context} = $context;
  main::Context($oldContext);
  return $self;
}

sub menu {
  my $self = shift;
  main::pop_up_list($self->{choices});
}

sub ans_rule {shift->menu(@_)}

1;
