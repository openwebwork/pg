#########################################################################
#
#  Implements named variables
#
package Parser::Variable;
use strict; no strict "refs";
our @ISA = qw(Parser::Item);

$Parser::class->{Variable} = 'Parser::Variable';

#
#  Error if the variable is not declared in the current context.
#  Record the variable in the equation's list of variables.
#
sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $equation = shift; my $variables = $equation->{context}{variables};
  my ($name,$ref) = @_;
  unless ($variables->{$name}) {
    my $string = substr($equation->{string},$ref->[2]);
    if ($string =~ m/^([a-z][a-z]+)/i) {
      $ref->[3] = $ref->[2]+length($1);
      $equation->Error(["'%s' is not defined in this context",$1],$ref);
    }
    $equation->Error(["Variable '%s' is not defined in this context",$name],$ref);
  }
  $equation->Error(["Variable '%s' is not defined in this context",$name],$ref)
    if $variables-> {$name}{parameter} && $equation->{context}{flags}{no_parameters};
  $equation->{variables}{$name} = 1;
  my $def = $variables->{$name};
  my $v = bless {
    name => $name, def => $def, type => $def->{type},
    ref => $ref, equation => $equation
  }, $class;
  $v->weaken;
  return $v;
}

#
#  Replace the variable with its value, if one was given
#
sub reduce {
  my $self = shift; my $equation = $self->{equation};
  my $value = $equation->{values}{$self->{name}};
  $self = $self->Item("Value")->new($equation,[$value]) if defined($value);
  return $self;
}

#
#  Substitute a variable's value, if there is one
#
sub substitute {
  my $self = shift; my $equation = $self->{equation};
  my $value = $equation->{values}{$self->{name}};
  $self = $self->Item("Value")->new($equation,[$value]) if defined($value);
  return $self;
}

#
#  Replace the variable with its value, if one was given
#
sub eval {
  my $self = shift;
  my $value = $self->{equation}{values}{$self->{name}};
  return $value if defined($value);
  $self->Error("No value given for variable '%s'",$self->{name});
}

#
#  Add the variable name to the equation's list of variables
#    unless the variable has been assigned a value
#
sub getVariables {
  my $self = shift; my $variables = $self->{equation}{variables};
  return {} if defined($self->{equation}{values}{$self->{name}});
  return {$self->{name} => 1};
}

#
#  Copy the variable, and add the name to the new equation's list
#
sub copy {
  my $self = shift;
  $self = $self->SUPER::copy(@_);
  my $variables = $self->{equation}{variables};
  $variables->{$self->{name}} = 1
    unless defined($self->{equation}{values}{$self->{name}});
  return $self;
}

#
#  Return the variable's name or value
#
sub string {
  my $self = shift;
  my $value = $self->{equation}{values}{$self->{name}};
  return $value if defined($value);
  return $self->{name};
}
#
#  Make a subscripted variable name if it ends in numbers
#
sub TeX {
  my $self = shift; my $name = $self->{name};
  my $value = $self->{equation}{values}{$name};
  return $value if defined($value);
  return $self->{def}{TeX} if defined $self->{def}{TeX};
  $name = $1.'_{'.$2.'}' if ($name =~ m/^([^_]+)_?(\d+)$/);
  $name = '\boldsymbol '.$name if $self->{type}{name} eq 'Vector';
  return $name;
}
#
#  Make a variable reference
#
sub perl {
  my $self = shift;
  my $value = $self->{equation}{values}{$self->{name}};
  return $value if defined($value);
  my $perl = $self->{def}{perl} || '$'.$self->{name};
  substr($perl,1) =~ s/([^a-z0-9_])/"_".ord($1)/ge;
  return $perl;
}

#########################################################################

1;
