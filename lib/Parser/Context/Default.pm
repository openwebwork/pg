#########################################################################

package Parser::Context::Default;
use vars qw($operators $parens $lists $constants $variables $functions $strings $flags); 
use strict;

#
#  The default operators, functions, etc.
#
$operators = {
   ',' => {precedence => 0, associativity => 'left', type => 'bin', string => ',',
           class => 'Parser::BOP::comma', isComma => 1},

   'U' => {precedence => 0.5, associativity => 'left', type => 'bin', isUnion => 1,
           string => ' U ', TeX => '\cup ', class => 'Parser::BOP::union'},

   '+' => {precedence => 1, associativity => 'left', type => 'both', string => '+',
           class => 'Parser::BOP::add'},

   '-' => {precedence => 1, associativity => 'left', type => 'both', string => '-',
           class => 'Parser::BOP::subtract', rightparens => 'same'},

   '><'=> {precedence => 2, associativity => 'left', type => 'bin',
           string => ' >< ', TeX => '\times ', perl => ' x ', fullparens => 1,
           class => 'Parser::BOP::cross'},

   '.' => {precedence => 2, associativity => 'left', type => 'bin',
           string => '.', TeX => '\cdot ', class => 'Parser::BOP::dot'},

   '*' => {precedence => 3, associativity => 'left', type => 'bin', space => ' *',
           string => '*', TeX => '', class => 'Parser::BOP::multiply'},

   '/' => {precedence => 3, associativity => 'left', type => 'bin', string => '/',
           class => 'Parser::BOP::divide', space => ' /',
           rightparens => 'all', leftparens => 'all', fullparens => 1},

   ' /' => {precedence => 2.8, associativity => 'left', type => 'bin', string => '/',
           class => 'Parser::BOP::divide',
           rightparens => 'all', leftparens => 'all', fullparens => 1, hidden => 1},

   '/ ' => {precedence => 2.8, associativity => 'left', type => 'bin', string => '/',
           class => 'Parser::BOP::divide',
           rightparens => 'all', leftparens => 'all', fullparens => 1},

   ' *'=> {precedence => 2.8, associativity => 'left', type => 'bin', string => '*',
           class => 'Parser::BOP::multiply', TeX => '', hidden => 1},

   '* '=> {precedence => 2.8, associativity => 'left', type => 'bin', string => '*',
           class => 'Parser::BOP::multiply', TeX => ''},

   'fn'=> {precedence => 2.9, associativity => 'left', type => 'unary', string => '',
           parenPrecedence => 5, hidden => 1},

   ' ' => {precedence => 3.1, associativity => 'left', type => 'bin', string => '*',
           class => 'Parser::BOP::multiply', space => ' *', hidden => 1},

   'u+'=> {precedence => 6, associativity => 'left', type => 'unary', string => '+',
           class => 'Parser::UOP::plus', hidden => 1, allowInfinite => 1},

   'u-'=> {precedence => 6, associativity => 'left', type => 'unary', string => '-',
           class => 'Parser::UOP::minus', hidden => 1, allowInfinite => 1},

   '^' => {precedence => 7, associativity => 'right', type => 'bin', string => '^', perl => '**',
           class => 'Parser::BOP::power', leftf => 1, fullparens => 1, isInverse => 1},

   '**'=> {precedence => 7, associativity => 'right', type => 'bin', string => '^', perl => '**',
           class => 'Parser::BOP::power', leftf => 1, fullparens => 1, isInverse => 1},

   '!' => {precedence => 8, associativity => 'right', type => 'unary', string => '!',
           class => 'Parser::UOP::factorial', perl => 'Factorial'},

   '_' => {precedence => 9, associativity => 'left', type => 'bin', string => '_',
           class => 'Parser::BOP::underscore'},
};

$parens = {
   '(' => {close => ')', type => 'Point', formMatrix => 1, formInterval => ']',
           formList => 1, removable => 1, emptyOK => 1, function => 1},
   '[' => {close => ']', type => 'Point', formMatrix => 1, formInterval => ')', removable => 1},
   '<' => {close => '>', type => 'Vector', formMatrix => 1},
   '{' => {close => '}', type => 'Point', removable => 1},
   '|' => {close => '|', type => 'AbsoluteValue'},
   'start' => {close => 'start', type => 'List', formList => 1,
               removable => 1, emptyOK => 1, hidden => 1},
   'interval' => {type => 'Interval', hidden => 1},
   'list'     => {type => 'List', hidden => 1},
};

$lists = {
   'Point'         => {class =>'Parser::List::Point'},
   'Vector'        => {class =>'Parser::List::Vector'},
   'Matrix'        => {class =>'Parser::List::Matrix', open => '[', close => ']'},
   'List'          => {class =>'Parser::List::List'},
   'Interval'      => {class =>'Parser::List::Interval'},
   'AbsoluteValue' => {class =>'Parser::List::AbsoluteValue'},
};

$constants = {
   'e'  => exp(1),
   'pi' => 4*atan2(1,1),
   'i'  => Value::Complex->new(0,1),
   'j'  => Value::Vector->new(0,1,0),
   'k'  => Value::Vector->new(0,0,1),
};

$variables = {
   'x' => 'Real',
   'y' => 'Real',
   'z' => 'Real',
};

$functions = {
   'sin'   => {class => 'Parser::Function::trig', TeX => '\sin', inverse => 'asin'},
   'cos'   => {class => 'Parser::Function::trig', TeX => '\cos', inverse => 'acos'},
   'tan'   => {class => 'Parser::Function::trig', TeX => '\tan', inverse => 'atan'},
   'sec'   => {class => 'Parser::Function::trig', TeX => '\sec', inverse => 'asec'},
   'csc'   => {class => 'Parser::Function::trig', TeX => '\csc', inverse => 'acsc'},
   'cot'   => {class => 'Parser::Function::trig', TeX => '\cot', inverse => 'acot'},
   'asin'  => {class => 'Parser::Function::trig', TeX => '\sin^{-1}'},
   'acos'  => {class => 'Parser::Function::trig', TeX => '\cos^{-1}'},
   'atan'  => {class => 'Parser::Function::trig', TeX => '\tan^{-1}'},
   'asec'  => {class => 'Parser::Function::trig', TeX => '\sec^{-1}'},
   'acsc'  => {class => 'Parser::Function::trig', TeX => '\csc^{-1}'},
   'acot'  => {class => 'Parser::Function::trig', TeX => '\cot^{-1}'},

   'sinh'   => {class => 'Parser::Function::hyperbolic', TeX => '\sinh', inverse => 'asinh'},
   'cosh'   => {class => 'Parser::Function::hyperbolic', TeX => '\cosh', inverse => 'acosh'},
   'tanh'   => {class => 'Parser::Function::hyperbolic', TeX => '\tanh', inverse => 'atanh'},
   'sech'   => {class => 'Parser::Function::hyperbolic', inverse => 'asech'},
   'csch'   => {class => 'Parser::Function::hyperbolic', inverse => 'acsch'},
   'coth'   => {class => 'Parser::Function::hyperbolic', TeX => '\coth', inverse => 'acoth'},
   'asinh'  => {class => 'Parser::Function::hyperbolic', TeX => '\sinh^{-1}'},
   'acosh'  => {class => 'Parser::Function::hyperbolic', TeX => '\cosh^{-1}'},
   'atanh'  => {class => 'Parser::Function::hyperbolic', TeX => '\tanh^{-1}'},
   'asech'  => {class => 'Parser::Function::hyperbolic', TeX => '\mathop{\rm sech}^{-1}'},
   'acsch'  => {class => 'Parser::Function::hyperbolic', TeX => '\mathop{\rm csch}^{-1}'},
   'acoth'  => {class => 'Parser::Function::hyperbolic', TeX => '\coth^{-1}'},

   'log'   => {class => 'Parser::Function::numeric', inverse => 'exp', TeX => '\log'},
   'log10' => {class => 'Parser::Function::numeric', nocomplex => 1, TeX => '\log_{10}'},
   'exp'   => {class => 'Parser::Function::numeric', inverse => 'log', TeX => '\exp'},
   'sqrt'  => {class => 'Parser::Function::numeric', braceTeX => 1, TeX => '\sqrt'},
   'abs'   => {class => 'Parser::Function::numeric'},
   'int'   => {class => 'Parser::Function::numeric'},
   'sgn'   => {class => 'Parser::Function::numeric', nocomplex => 1},

   'atan2' => {class => 'Parser::Function::numeric2'},
   
   'norm'  => {class => 'Parser::Function::vector', vectorInput => 1},
   'unit'  => {class => 'Parser::Function::vector', vectorInput => 1},
   
   'arg'   => {class => 'Parser::Function::complex'},
   'mod'   => {class => 'Parser::Function::complex'},
   'Re'    => {class => 'Parser::Function::complex', TeX => '\Re'},
   'Im'    => {class => 'Parser::Function::complex', TeX => '\Im'},
   'conj'  => {class => 'Parser::Function::complex', complex => 1, TeX=>'\overline', braceTeX => 1},
   
   # Det, Inverse, Transpose, Floor, Ceil

   'arcsin' => {alias => 'asin'},
   'arccos' => {alias => 'acos'},
   'arctan' => {alias => 'atan'},
   'arcsec' => {alias => 'asec'},
   'arccsc' => {alias => 'acsc'},
   'arccot' => {alias => 'acot'},

   'arcsinh' => {alias => 'asinh'},
   'arccosh' => {alias => 'acosh'},
   'arctanh' => {alias => 'atanh'},
   'arcsech' => {alias => 'asech'},
   'arccsch' => {alias => 'acsch'},
   'arccoth' => {alias => 'acoth'},

   'ln'     => {alias => 'log'},
   'logten' => {alias => 'log10'},
};

$strings = {
   'infinity'  => {infinite => 1},
   'INFINITY'  => {alias => 'infinity'},
   'inf'  => {alias => 'infinity'},
   'INF'  => {alias => 'infinity'},

   'NONE' => {},
   'none' => {alias => 'NONE'},

   'DNE'  => {},
   'dne'  => {alias => 'DNE'},

#   'T' => {true => 1},
#   'F' => {false => 1},
};

$flags = {
  ijk => 0,
};

############################################################################
############################################################################
#
#  Special purpose contexts
#

use vars qw(%context);
use vars qw($fullContext $numericContext $complexContext
	    $vectorContext $matrixContext $intervalContext);

#
#  The default Context
#
$fullContext = new Parser::Context(
  operators => $operators,
  functions => $functions,
  constants => $constants,
  variables => $variables,
  strings   => $strings,
  parens    => $parens,
  lists     => $lists,
  flags     => $flags,
);

$fullContext->constants->set(
  pi => {TeX => '\pi ', perl => ' pi'},
  i => {isConstant => 1, perl => ' i'},
  j => {TeX => '\boldsymbol{j}', perl => ' j'},
  k => {TeX => '\boldsymbol{k}', perl => ' k'},
);

$fullContext->usePrecedence('Standard');

#
#  Numeric context (no vectors, matrices or complex numbers)
#
$numericContext = $fullContext->copy;
$numericContext->variables->are(x=>'Real');
$numericContext->operators->undefine('><','.');
$numericContext->functions->undefine('norm','unit','arg','mod','Re','Im','conj');
$numericContext->constants->remove('i','j','k');
$numericContext->parens->remove('<');
$numericContext->parens->set(
   '(' => {type => 'List', formMatrix => 0},
   '[' => {type => 'List', formMatrix => 0},
   '{' => {type => 'List'},
);

#
#  Complex context (no vectors or matrices)
#
$complexContext = $fullContext->copy;
$complexContext->variables->are(z=>'Complex');
$complexContext->operators->undefine('><','.');
$complexContext->functions->undefine('norm','unit');
$complexContext->constants->remove('j','k');
$complexContext->parens->remove('<');
$complexContext->parens->set(
   '(' => {type => 'List', formMatrix => 0},
   '[' => {type => 'List', formMatrix => 0},
   '{' => {type => 'List'},
);

#
#  Vector context (no complex numbers)
#
$vectorContext = $fullContext->copy;
$vectorContext->variables->are(x=>'Real',y=>'Real',z=>'Real');
$vectorContext->functions->undefine('arg','mod','Re','Im','conj');
$vectorContext->constants->replace(i=>Value::Vector->new(1,0,0));
$vectorContext->constants->set(i=>{TeX=>'\boldsymbol{i}', perl => ' i'});

#
#  Matrix context (square brackets make matrices in preference to points or intervals)
#
$matrixContext = $vectorContext->copy;
$matrixContext->parens->set('[' => {type => 'Matrix', removable => 0});

#
#  Interval context (make intervals rather than lists)
#
$intervalContext = $numericContext->copy;
$intervalContext->parens->set(
   '(' => {type => 'Interval'},
   '[' => {type => 'Interval'},
   '{' => {type => 'Interval'},
);

#########################################################################

#
#  list of all default contexts (users can add more)
#
%context = (
  Full     => $fullContext,
  Numeric  => $numericContext,
  Complex  => $complexContext,
  Vector   => $vectorContext,
  Matrix   => $matrixContext,
  Interval => $intervalContext,
);

#########################################################################

1;
