########################################################################### 
#
#  Implements the Formula class.
#
package Value::Formula;
my $pkg = 'Value::Formula';

use strict;
use vars qw(@ISA);
@ISA = qw(Parser Value);

use overload
       '+'    => \&add,
       '-'    => \&sub,
       '*'    => \&mult,
       '/'    => \&div,
       '**'   => \&power,
       '.'    => \&Value::_dot,
       'x'    => \&cross,
       '<=>'  => sub {Value::nomethod(@_,'<=>')},
       '~'    => sub {Parser::Function->call('conj',$_[0])},
       'neg'  => sub {$_[0]->neg},
       'sin'  => sub {Parser::Function->call('sin',$_[0])},
       'cos'  => sub {Parser::Function->call('cos',$_[0])},
       'exp'  => sub {Parser::Function->call('exp',$_[0])},
       'abs'  => sub {Parser::Function->call('abs',$_[0])},
       'log'  => sub {Parser::Function->call('log',$_[0])},
       'sqrt' => sub {Parser::Function->call('sqrt',$_[0])},
      'atan2' => \&atan2,
   'nomethod' => \&Value::nomethod,
         '""' => \&stringify;

#
#  Call Parser to make the new item
#
sub new {shift; $pkg->SUPER::new(@_)}

#
#  Create the new parser with no string
#    (we'll fill in its tree by hand)
#
sub blank {$pkg->SUPER::new('')}

#
#  Get the type from the tree
#
sub typeRef {(shift)->{tree}->typeRef}

#
#  Create a BOP from two operands
#  
#  Get the context and variables from the left and right operands
#    if they are formulas
#  Make them into Value objects if they aren't already.
#  Convert '+' to union for intervals or unions.
#  Make a new BOP with the two operands.
#  Record the variables.
#  Evaluate the formula if it is constant.
#
sub bop {
  my ($l,$r,$flag,$bop) = @_;
  if ($l->promotePrecedence($r)) {return $r->add($l,!$flag)}
  if ($flag) {my $tmp = $l; $l = $r; $r = $tmp}
  my $formula = $pkg->blank;
  my $vars = {};
  if (ref($r) eq $pkg) {
    $formula->{context} = $r->{context};
    $vars = {%{$vars},%{$r->{variables}}};
    $r = $r->{tree}->copy($formula);
  }
  if (ref($l) eq $pkg) {
    $formula->{context} = $l->{context};
    $vars = {%{$vars},%{$l->{variables}}};
    $l = $l->{tree}->copy($formula);
  }
  $l = $pkg->new($l) if (!ref($l) && Value::getType($formula,$l) eq "unknown");
  $r = $pkg->new($r) if (!ref($r) && Value::getType($formula,$r) eq "unknown");
  $l = Parser::Value->new($formula,$l) unless ref($l) =~ m/^Parser::/;
  $r = Parser::Value->new($formula,$r) unless ref($r) =~ m/^Parser::/;
  $bop = 'U' if $bop eq '+' &&
    ($l->type =~ m/Interval|Union/ || $r->type =~ m/Interval|Union/);
  $formula->{tree} = Parser::BOP->new($formula,$bop,$l,$r);
  $formula->{variables} = {%{$vars}};
  return $formula->eval if scalar(%{$vars}) == 0;
  return $formula;
}

sub add   {bop(@_,'+')}
sub sub   {bop(@_,'-')}
sub mult  {bop(@_,'*')}
sub div   {bop(@_,'/')}
sub power {bop(@_,'**')}
sub dot   {bop(@_,'.')}
sub cross {bop(@_,'x')}

#
#  Form the negation of a formula
#
sub neg {
  my $self = shift;
  my $formula = $self->blank;
  $formula->{context} = $self->{context};
  $formula->{variables} = $self->{variables};
  $formula->{tree} = Parser::UOP->new($formula,'u-',$self->{tree}->copy($formula));
  return $formula->eval if scalar(%{$formula->{variables}}) == 0;
  return $formula;
}

#
#  Form the function atan2 function call on two operands
#
sub atan2 {
  my ($l,$r,$flag) = @_;
  if ($flag) {my $tmp = $l; $l = $r; $r = $tmp}
  Parser::Function->call('atan2',$l,$r);
}

#
#  Let the Parser object handle it
#
sub stringify {(shift)->string}

###########################################################################

1;
