package Parser;
my $pkg = "Parser";
use strict; no strict "refs";

BEGIN {
  #
  #  Map class names to packages (added to Context, and
  #  can be overriden to customize the parser)
  #
  our $class = {Formula => 'Value::Formula'};

  #
  #  Collect the default reduction flags for use in the context
  #
  our $reduce = {};
}

##################################################
#
#  Parse a string and create a new Parser object
#  If the string is already a parsed object then copy the parse tree
#  If it is a Value, make an appropriate tree for it.
#
sub new {
  my $self = shift;
  my $context = (Value::isContext($_[0]) ? shift : $self->context);
  my $class = $self->Item("Formula",$context);
  my $string = shift;
  $string = $context->Package("List")->new($context,$string,@_) if scalar(@_) > 0;
  $string = $context->Package("List")->new($context,$string)->with(open=>'[',close=>']')
    if ref($string) eq 'ARRAY';
  my $math = bless {
    string => undef,
    tokens => [], tree => undef,
    variables => {}, values => {},
    context => $context,
  }, $class;
  if (Value::isParser($string) || Value::isFormula($string)) {
    my $tree = $string; $tree = $tree->{tree} if defined $tree->{tree};
    $math->{tree} = $tree->copy($math);
    $math->{variables} = $math->{tree}->getVariables;
  } elsif (Value::isValue($string)) {
    $math->{tree} = $math->Item("Value")->new($math,$string);
  } elsif (($string//'') eq '' && $context->{flags}{allowEmptyStrings}) {
    $math->{string} = "";
    $math->{tree} = $math->Item("Value")->new($math,"");
  } else {
    $math->{string} = $string;
    $math->tokenize;
    $math->parse;
  }
  return $math;
}

#
#  Get the object's context, or the default one
#
sub context {
  my $self = shift; my $context = shift;
  if (Value::isHash($self)) {
    if ($context && $self->{context} != $context) {
      $self->{context} = $context;
      $self->{tree} = $self->{tree}->copy($self) if $self->{tree};
    }
    return $self->{context} if $self->{context};
  }
  Parser::Context->current;
}

#
#  Get the package for a parser item
#
sub Item {Parser::Item::Item(@_)}

#
#  Make a copy of a formula
#
sub copy {
  my $self = shift;
  my $copy  = bless {%{$self}}, ref($self);
  foreach my $id (Value::Formula::noinherit($self)) {delete $copy->{$id}}
  $copy->{tree} = $self->{tree}->copy($copy);
  foreach my $id (keys %{$self}) {
    $copy->{$id} = {%{$self->{$id}}} if ref($self->{$id}) eq 'HASH';
    $copy->{$id} = [@{$self->{$id}}] if ref($self->{$id}) eq 'ARRAY';
  }
  return $copy;
}

##################################################
#
#  Break the string into tokens based on the patterns for the various
#  types of objects.
#
sub tokenize {
  my $self = shift; my $space; my @match;
  my $tokens = $self->{tokens}; my $string = $self->{string};
  my $tokenPattern = $self->{context}{pattern}{token};
  my $tokenType = $self->{context}{pattern}{tokenType};
  my @patternType = @{$self->{context}{pattern}{type}};
  $string =~ tr/\N{U+FF01}-\N{U+FF5E}/\x21-\x7E/ if $self->{context}->flag('convertFullWidthCharacters');
  @{$tokens} = (); $self->{error} = 0;
  $string =~ m/^\s*/gc; my $p0; my $p1;
  while (pos($string) < length($string)) {
    $p0 = pos($string);
    if (@match = ($string =~ m/\G$tokenPattern/)) {
      foreach my $i (0..$#patternType) {
	if (defined($match[$i])) {
	  $p1 = pos($string) = pos($string) + length($match[$i]);
	  my ($class, $id) = ($patternType[$i] || $tokenType->{$match[$i]}, $match[$i]);
	  ($class,$id) = @$class if ref($class) eq 'ARRAY';
	  push(@{$tokens},[$class,$id,$p0,$p1,$space]);
	  last;
	}
      }
    } else {
      push(@{$tokens},['error',substr($string,$p0,1),$p0,$p0+1]);
      $self->{error} = 1;
      last;
    }
    $space = ($string =~ m/\G\s+/gc);
  }
}

##################################################
#
#  Parse the token list to produce the expression tree.  This does syntax checks
#  and reports "compile-time" errors.
#
#  Start with a stack that has a single entry (an OPEN object for the expression)
#  For each token, try to add that token to the tree.
#  After all tokens have been finished, add a CLOSE object for the initial OPEN
#    and save the complete tree
#
sub parse {
  my $self = shift;
  $self->{tree} = undef; $self->{error} = 0;
  $self->{stack} = [{type => 'open', value => 'start'}];
  foreach my $ref (@{$self->{tokens}}) {
    $self->{ref} = $ref; $self->{space} = $ref->[4];
    for ($ref->[0]) {
      /open/  and do {$self->Open($ref->[1]); last};
      /close/ and do {$self->Close($ref->[1],$ref); last};
      /op/    and do {$self->Op($ref->[1],$ref); last};
      /num/   and do {$self->Num($ref->[1]); last};
      /const/ and do {$self->Const($ref->[1]); last};
      /var/   and do {$self->Var($ref->[1]); last};
      /fn/    and do {$self->Fn($ref->[1]); last};
      /str/   and do {$self->Str($ref->[1]); last};
      /error/ and do {$self->Error(["Unexpected character '%s'",$ref->[1]],$ref); last};
    }
    return if ($self->{error});
  }
  $self->Close('start'); return if ($self->{error});
  $self->{tree} = $self->{stack}[0]{value};
}


#  Get the top or previous item of the stack
#
sub top {
  my $self = shift; my $i = shift || 0;
  return $self->{stack}[$i-1];
}
sub prev {(shift)->top(-1)}

#
#  Push or pop the top of the stack
#
sub pop {pop(@{(shift)->{stack}})}
sub push {push(@{(shift)->{stack}},@_)}

#
#  Return the type of the top item
#
sub state {(shift)->top->{type}}

#
#  Report an error at a given possition (if possible)
#
sub Error {
  my $self = shift; my $context = $self->context;
  my $message = shift; my $ref = shift;
  my $string; my $more = "";
  if ($ref) {
    $more = "; see position %d of formula";
    $string = $self->{string};
    $ref = [$ref->[2],$ref->[3]];
  }
  $context->setError($message,$string,$ref,$more);
  die $context->{error}{message} . Value::getCaller();
}

#
#  Insert an implicit multiplication
#  (fix up the reference for spaces or juxtaposition)
#
sub ImplicitMult {
  my $self = shift;
  my $ref = $self->{ref}; my $iref = [@{$ref}];
  $iref->[2]--; $iref->[3] = $iref->[2]+1;
  $iref->[3]++ unless substr($self->{string},$iref->[2],1) eq ' ';
  $self->Error("Can't perform implied multiplication in this context",$iref)
    unless $self->{context}->operators->resolveDef(' ')->{class};
  $self->Op(' ',$iref);
  $self->{ref} = $ref;
}

#
#  Push an operator onto the expression stack.
#  We save the operator symbol, the precedence, etc.
#
sub pushOperator {
  my $self = shift;
  my ($op,$precedence,$reverse) = @_;
  $self->push({
    type => 'operator', ref => $self->{ref},
    name => $op, precedence => $precedence, reverse => $reverse
  });
}

#
#  Push an operand onto the expression stack.
#
sub pushOperand {
  my $self = shift; my $value = shift;
  $self->push({type => 'operand', ref => $self->{ref}, value => $value});
}

#
#  Push a blank operand (just as a place-holder)
#
sub pushBlankOperand {
  my $self = shift;
  $self->pushOperand($self->Item("Constant")->new($self,"_blank_",$self->{ref}));
}

##################################################
#
#  Handle an operator token
#
#  Get the operator data from the context
#  If the top of the stack is an operand
#    If the operator is a left-associative unary operator
#      Insert an implicit multiplication and save the operator
#    Otherwise
#      Complete any pending operations of higher precedence
#      If the top item is still an operand
#        If we have a (right associative) unary operator
#          Apply it to the top operand
#        Otherwise (binary operator)
#          Convert the space operator to explicit multiplication
#          Save the opertor on the stack
#      Otherwise, (top is not an operand)
#        If the operator is an explicit one or the top is a function
#          Call Op again to report the error, or to apply
#            the operator to the function (this happens when
#            there is a function to a power, for example)
#  Otherwise (top is not an operand)
#    If this is a left-associative unary operator, save it on the stack
#    Otherwise, if it is a left-associative operator that CAN be unary
#      Save the unary version of the operator on the stack
#    Otherwise, if the top item is a function
#      If the operator can be applied to functions, save it on the stack
#      Otherwise, report that the function is missing its inputs
#    Otherwise, report the missing operand for this operator
#
sub Op {
  my $self = shift; my $name = shift; my $NAME = $name;
  my $ref = $self->{ref} = shift;
  my $context = $self->{context}; my $op;
  ($name,$op) = $context->operators->resolve($name);
  ($name,$op) = $context->operators->resolve($op->{space}) if $self->{space} && defined($op->{space});
  if ($self->state eq 'operand') {
    if ($op->{type} eq 'unary' && $op->{associativity} eq 'left') {
      $self->ImplicitMult();
      $self->pushOperator($name,$op->{precedence});
    } else {
      $self->Precedence($op->{precedence});
      if ($self->state eq 'operand') {
        if ($op->{type} eq 'unary') {
          my $top = $self->pop;
          $self->pushOperand($self->Item("UOP")->new($self,$name,$top->{value},$ref));
        } else {
          my $def = $context->operators->resolveDef(' ');
          $name = $def->{string} if defined($NAME) and ($NAME eq ' ' or $NAME eq $def->{space});
          $self->pushOperator($name,$op->{precedence});
        }
      } elsif (($ref && $NAME ne ' ') || $self->state ne 'fn') {$self->Op($NAME,$ref)}
    }
  } else {
    ($name,$op) = $context->operators->resolve('u'.$name)
      if ($op->{type} eq 'both' && defined $context->{operators}{'u'.$name});
    if ($op->{type} eq 'unary' && $op->{associativity} eq 'left') {
      $self->pushOperator($name,$op->{precedence});
    } elsif ($self->state eq 'fn') {
      if ($op->{leftf}) {
        $self->pushOperator($name,$op->{precedence},1);
      } elsif ($self->{context}->flag("allowMissingFunctionInputs")) {
	$self->pushBlankOperand;
	$self->CloseFn;
	$self->pushOperator($name,$op->{precedence});
      } else {
        my $top = $self->top;
        $self->Error(["Function '%s' is missing its input(s)",$top->{name}],$top->{ref});
      }
    } elsif ($self->{context}->flag("allowMissingOperands")) {
      $self->pushBlankOperand;
      $self->Op($name,$ref);
    } else {$self->Error(["Missing operand before '%s'",$name],$ref)}
  }
}

##################################################
#
#  Handle an open parenthesis
#
#  If the top of the stack is an operand
#    Check if the open paren is really a close paren (for when the open
#      and close symbol are the same)
#    Otherwise insert an implicit multiplication
#  Save the open object on the stack
#
sub Open {
  my $self = shift; my $type = shift;
  if ($self->state eq 'operand') {
    my $parens = $self->{context}->parens;
    if ($self->{context}->parens->match($type,$type)) {
      my $stack = $self->{stack}; my $i = scalar(@{$stack})-1;
      while ($i >= 0 && $stack->[$i]{type} ne "open") {$i--}
      if ($i >= 0 && $parens->match($stack->[$i]{value},$type)) {
	$self->Close($type,$self->{ref});
	return;
      }
    }
    $self->ImplicitMult();
  }
  $self->push({type => 'open', value => $type, ref => $self->{ref}});
}

##################################################
#
#  Handle a close parenthesis
#
#  When the top stack object is
#    An open parenthesis (that is empty):
#      Get the data for the type of parentheses
#      If the parentheses can be empty and the parentheses match
#        Save the empty list
#      Otherwise report a message appropriate to the type of parentheses
#
#    An operand:
#      Complete any pending operations, and stop if there was an error
#      If the top is no longer an operand
#        Call Close to report the error and return
#      Get the item before the operand (an OPEN object), and its parenthesis type
#      If the parens match
#        Pop the operand off the stack
#        If the parens can't be removed, or if the operand is a list
#          Make the operand into a list object
#        Replace the paren object with the operand
#        If the parentheses are used for function calls and the
#          previous stack object is a function call, do the function apply
#      Otherwise if the parens can form Intervals, do so
#      Otherwise report an appropriate error message
#
#    A function:
#      Report an error message about missing inputs
#
#    An operator:
#      Report the missing operation
#
sub Close {
  my $self = shift; my $type = shift;
  my $ref = $self->{ref} = shift;
  my $parens = $self->{context}->parens;

  for ($self->state) {
    /open/ and do {
      my $top = $self->pop;
      my ($open,$paren) = $parens->resolve($top->{value});
      if ($paren->{emptyOK} && $parens->match($open,$type)) {
        $self->pushOperand($self->Item("List")->new($self,[],1,$paren,undef,$open,$paren->{close}))
      }
      elsif ($type eq 'start') {$self->Error(["Missing close parenthesis for '%s'",$top->{value}],$top->{ref})}
      elsif ($open eq 'start') {$self->Error(["Extra close parenthesis '%s'",$type],$ref)}
      else {$top->{ref}[3]=$ref->[3]; $self->Error("Empty parentheses",$top->{ref})}
      last;
    };

    /operand/ and do {
      $self->Precedence(-1); return if ($self->{error});
      if ($self->state ne 'operand') {$self->Close($type,$ref); return}
      my ($open,$paren) = $parens->resolve($self->prev->{value});
      if ($parens->match($open,$type)) {
        my $top = $self->pop;
        if (!$paren->{removable} || ($top->{value}->type eq "Comma")) {
          $top = $top->{value};
          $top = {type => 'operand', value =>
	          $self->Item("List")->new($self,[$top->makeList],$top->{isConstant},$paren,
                    ($top->type eq 'Comma') ? $top->entryType : $top->typeRef,
                    ($type ne 'start') ? ($open,$paren->{close}) : () )};
        } else {
	  $top->{value}{hadParens} = 1;
	}
        $self->pop; $self->push($top);
        $self->CloseFn() if ($paren->{function} && $self->prev->{type} eq 'fn');
      } elsif ($paren->{formInterval} eq $type && $self->top->{value}->length == 2) {
        my $top = $self->pop->{value}; $self->pop;
        $self->pushOperand(
           $self->Item("List")->new($self,[$top->makeList],$top->{isConstant},
				     $paren,$top->entryType,$open,$type));
      } else {
        my $prev = $self->prev;
        if    ($type eq "start") {$self->Error(["Missing close parenthesis for '%s'",$prev->{value}],$prev->{ref})}
        elsif ($open eq "start") {$self->Error(["Extra close parenthesis '%s'",$type],$ref)}
        else {$self->Error(["Mismatched parentheses: '%s' and '%s'",$prev->{value},$type],$ref)}
        return;
      }
      last;
    };

    /fn/ and do {
      if ($self->{context}->flag("allowMissingFunctionInputs")) {
	$self->pushBlankOperand;
	$self->Close($type,$ref);
      } else {
        my $top = $self->top;
        $self->Error(["Function '%s' is missing its input(s)",$top->{name}],$top->{ref});
      }
      return;
    };

    /operator/ and do {
      if ($self->{context}->flag("allowMissingOperands")) {
	$self->pushBlankOperand;
	$self->Close($type,$ref);
      } else {
        my $top = $self->top(); my $name = $top->{name}; $name =~ s/^u//;
        $self->Error(["Missing operand after '%s'",$name],$top->{ref});
      }
      return;
    };
  }
}

##################################################
#
#  Handle any pending operations of higher precedence
#
#  While the top stack item is an operand:
#    When the preceding item is:
#      An pending operator:
#        Get the precedence of the operator (use the special right-hand prrecedence
#          of there is one, otherwise use the general precedence)
#        Stop processing if the current operator precedence is higher
#        If the stacked operator is binary or if it is reversed (for function operators)
#          Stop processing if the precedence is equal and we are right associative
#          If the operand for the stacked operator is a function
#            If the operation is ^(-1) (for inverses)
#              Push the inverse function name
#            Otherwise
#              Reverse the order of the stack, so that the function can be applied
#                to the next operand (it will be unreversed later)
#          Otherwise (not a function, so an operand)
#            Get the operands and binary operator off the stack
#            If it is reversed (for functions), get the order right
#            Save the result of the binary operation as an operand on the stack
#        Otherwise (the stack contains a unary operator)
#          Get the operator and operand off the stack
#          Push the result of the unary operator as an operand on the stack
#
#      A pending function call:
#        Keep working if the precedence of the operator is higher than a function call
#        Otherwise apply the function to the operator and continue
#
#      Anything else:
#        Return (no more pending operations)
#
#    If there was an error, stop processing
#
sub Precedence {
  my $self = shift; my $precedence = shift;
  my $context = $self->{context};
  while ($self->state eq 'operand') {
    my $prev = $self->prev;
    for ($prev->{type}) {

      /operator/ and do {
        my $def = $context->operators->resolveDef($prev->{name});
        my $prev_prec = $def->{rprecedence};
        $prev_prec = $prev->{precedence} unless $prev_prec;
        return if ($precedence > $prev_prec);
        if ($self->top(-2)->{type} eq 'operand' || $prev->{reverse}) {
          return if ($precedence == $prev_prec && $def->{associativity} eq 'right');
          if ($self->top(-2)->{type} eq 'fn') {
            my $top = $self->pop; my $op = $self->pop; my $fun = $self->pop;
            if (Parser::Function::checkInverse($self,$fun,$op,$top)) {
              $fun->{name} = $context->functions->resolveDef($fun->{name})->{inverse};
              $self->push($fun);
            } else {$self->push($top,$op,$fun)}
          } else {
            my $rop = $self->pop; my $op = $self->pop; my $lop = $self->pop;
            if ($op->{reverse}) {my $tmp = $rop; $rop = $lop; $lop = $tmp}
            $self->pushOperand($self->Item("BOP")->new($self,$op->{name},
                 $lop->{value},$rop->{value},$op->{ref}),$op->{reverse});
          }
        } else {
          my $rop = $self->pop; my $op = $self->pop;
          $self->pushOperand($self->Item("UOP")->new
	       ($self,$op->{name},$rop->{value},$op->{ref}),$op->{reverse});
        }
        last;
      };

      /fn/ and do {
        return if ($precedence > $context->{operators}{fn}{precedence});
        $self->CloseFn();
        last;
      };

      return;

    }
    return if ($self->{error});
  }
}

##################################################
#
#  Apply a function to its parameters
#
#  If the operand is a list and the parens are those for function calls
#    Use the list items as the parameters, otherwise use the top item
#  Pop the function object, and push the result of the function call
#
sub CloseFn {
  my $self = shift; my $context = $self->{context};
  my $top = $self->pop->{value}; my $fn = $self->pop;
  my $constant = $top->{isConstant};
  if ($top->{open} && $context->parens->resolveDef($top->{open})->{function} &&
      $context->parens->match($top->{open},$top->{close}) &&
      !$context->functions->resolveDef($fn->{name})->{vectorInput})
         {$top = $top->coords} else {$top = [$top]}
  $self->pushOperand($self->Item("Function")->new($self,$fn->{name},$top,$constant,$fn->{ref}));
}

##################################################
#
#  Handle a numeric token
#
#  Add an implicit multiplication, if needed
#  Create the number object and check it
#  Save the number as an operand
#
sub Num {
  my $self = shift;
  $self->ImplicitMult() if $self->state eq 'operand';
  my $num = $self->Item("Number")->new($self,shift,$self->{ref});
  my $check = $self->{context}->flag('NumberCheck');
  &$check($num) if $check;
  $self->pushOperand($num);
}

##################################################
#
#  Handle a constant token
#
#  Add an implicit multiplication, if needed
#  Save the number as an operand
#
sub Const {
  my $self = shift; my $ref = $self->{ref}; my $name = shift;
  my $const = $self->{context}->constants->resolveDef($name);
  $self->ImplicitMult() if $self->state eq 'operand';
  if (defined($self->{context}{variables}{$name})) {
    $self->pushOperand($self->Item("Variable")->new($self,$name,$ref));
  } elsif ($const->{keepName}) {
    $self->pushOperand($self->Item("Constant")->new($self,$name,$ref));
  } else {
    $self->pushOperand($self->Item("Value")->new($self,[$const->{value}],$ref));
  }
}

##################################################
#
#  Handle a variable token
#
#  Add an implicit multiplication, if needed
#  Save the variable as an operand
#
sub Var {
  my $self = shift;
  $self->ImplicitMult() if $self->state eq 'operand';
  $self->pushOperand($self->Item("Variable")->new($self,shift,$self->{ref}));
}

##################################################
#
#  Handle a function token
#
#  Add an implicit multiplication, if needed
#  Save the function object on the stack
#
sub Fn {
  my $self = shift;
  $self->ImplicitMult() if $self->state eq 'operand';
  $self->push({type => 'fn', name => shift, ref => $self->{ref}});
}

##################################################
#
#  Handle a string constant
#
#  Add an implicit multiplication, if needed (will report an error)
#  Save the string object on the stack
#
sub Str {
  my $self = shift;
  $self->ImplicitMult() if $self->state eq 'operand';
  $self->pushOperand($self->Item("String")->new($self,shift,$self->{ref}));
}

##################################################
##################################################
#
#  Evaluate the equation using the given values
#
sub eval {
  my $self = shift;
  $self->setValues(@_);
  foreach my $x (keys %{$self->{values}}) {
    $self->Error(["The value of '%s' can't be a formula",$x])
      if Value::isFormula($self->{values}{$x});
  }
  my $value = Value::makeValue($self->{tree}->eval,context=>$self->context)->with(equation=>$self);
  $value->transferFlags("equation");
  $self->unsetValues;
  return $value;
}

##################################################
#
#  Removes redundent items (like x+-y, 0+x and 1*x, etc)
#  using the provided flags
#
sub reduce {
  my $self = shift;
  $self = $self->copy($self);
  my $reduce = $self->{context}{reduction};
  $self->{context}{reduction} = {%{$reduce},@_};
  $self->{tree} = $self->{tree}->reduce;
  $self->{variables} = $self->{tree}->getVariables;
  $self->{context}{reduction} = $reduce if $reduce;
  delete $self->{f};
  return $self;
}

##################################################
#
#  Substitute values for one or more variables
#
sub substitute {
  my $self = shift;
  $self = $self->copy($self);
  $self->setValues(@_);
  foreach my $x (keys %{$self->{values}}) {delete $self->{variables}{$x}}
  $self->{tree} = $self->{tree}->substitute;
  $self->unsetValues;
  foreach my $id ("test_values","test_adapt","string","f",
                  "stack","ref","tokens","space","domainMismatch") {delete $self->{$id}}
  return $self;
}

##################################################
#
#  Produces a printable string (substituting the given values).
#
sub string {
  my $self = shift;
  $self->setValues(@_);
  my $string = $self->{tree}->string;
  $self->unsetValues;
  return $string;
}

##################################################
#
#  Produces a TeX string (substituting the given values).
#
sub TeX {
  my $self = shift;
  $self->setValues(@_);
  my $tex = $self->{tree}->TeX;
  $self->unsetValues;
  return $tex;
}

##################################################
#
#  Produces a perl eval string (substituting the given values).
#
sub perl {
  my $self = shift;
  $self->setValues(@_);
  my $perl = $self->{tree}->perl;
  $perl = $self->Package("Real").'->new('.$perl.')' if $self->isRealNumber;
  $self->unsetValues;
  return $perl;
}

##################################################
#
#  Produce a perl function
#
#  (Parameters specify an optional name and an array reference of
#   optional variables. If the name is not included, an anonymous
#   code reference is returned.  If the variables are not included,
#   then the variables from the formula are used in sorted order.)
#
sub perlFunction {
  my $self = shift; my $name = shift || ''; my $vars = shift;
  $vars = [sort(keys %{$self->{variables}})] unless $vars;
  $vars = [$vars] unless ref($vars) eq 'ARRAY';
  my $n = scalar(@{$vars}); my $vnames = ''; my %isArg;
  my $variables = $self->context->variables;
  if ($n > 0) {
    my @v = ();
    foreach my $x (@{$vars}) {
      my $perl = $variables->get($x)->{perl} || "\$".$x;
      substr($perl,1) =~ s/([^a-z0-9_])/"_".ord($1)/ge;
      CORE::push(@v,$perl);
      $isArg{$x} = 1;
    }
    $vnames = "my (".join(',',@v).") = \@_;";
  }
  foreach my $x (keys %{$self->{variables}}) {
    unless ($isArg{$x}) {
      my $perl = $variables->get($x)->{perl} || "\$".$x;
      substr($perl,1) =~ s/([^a-z0-9_])/"_".ord($1)/ge;
      $vnames .= "\n      my $perl = main::Formula('$x');";
    }
  }
  my $context = $self->context;
  my $fn = eval
   "package main;
    sub $name {
      die \"Wrong number of arguments".($name?" to '$name'":'')."\" if scalar(\@_) != $n;
      $vnames
      my \$oldContext = \$\$Value::context; \$\$Value::context = \$context;
      my \@result = ".$self->perl.";
      \$\$Value::context = \$oldContext;
      return (wantarray ? \@result : \$result[0]);
    }";
  $self->Error($@) if $@;
  return $fn;
}


##################################################
#
#  Sets the values of variables for evaluation purposes
#
sub setValues {
  my $self = shift; my ($xref,$value,$type);
  my $context = $self->context;
  my $variables = $context->{variables};
  while (scalar(@_)) {
    $xref = shift; $value = shift;
    if (ref($xref) eq "ARRAY") {
      $value = Value::makeValue($value,context=>$context) unless ref($value);
      $value = [$value->value] if Value::isValue($value);
      $value = @{$value}[0,1] if Value::classMatch("Interval");
      $value = [$value] unless ref($value) eq 'ARRAY';
    } else {
      $xref = [$xref]; $value = [$value];
    }
    foreach my $i (0..scalar(@$xref)-1) {
      my $x = $xref->[$i]; my $v = $value->[$i];
      $self->Error(["Null value can't be assigned to variable '%s'",$x]) unless defined $v;
      $self->Error(["Undeclared variable '%s'",$x]) unless defined $variables->{$x};
      $v = Value::makeValue($v,context=>$context);
      ($v,$type) = Value::getValueType($self,$v);
      $self->Error(["Variable '%s' should be of type %s",$x,$variables->{$x}{type}{name}])
	unless Parser::Item::typeMatch($type,$variables->{$x}{type});
      $v->inContext($self->context) if $v->context != $self->context;
      $self->{values}{$x} = $v;
    }
  }
}

sub unsetValues {
  my $self = shift;
  delete $self->{values};
}


##################################################
##################################################
#
#  Produce a vector in ijk form
#
sub ijk {
  my $self = shift;
  $self->{tree}->ijk(@_);
}

#########################################################################
#########################################################################
#
#  Load the sub-classes and Value.pm
#

END {
  use Parser::Item;
  use Value;
  use Parser::Context;
  use Parser::Context::Default;
  use Parser::Differentiation;
}

###########################################################################

our $installed = 1;

###########################################################################

1;

