#########################################################################
=head1 DESCRIPTION
#
# Defines the assumptions about symbols for
# the following contexts
#   Full     => tries to include everything, but has some compromises
#   Numeric  => includes lists, but no complexes, points, vector, intervals, etc.
#   Complex  => has complexes, but no points, vectors, etc.
#   Point    => numeric context with syntax for points
#   Vector   => numeric context with points and vectors
#   Vector2D => vector context where i and j are vectors in 2D rather than 3D
#   Matrix   => numeric context with points, vectors and matrices
#   Interval => numeric context with syntax for intervals and unions
#   Complex-Point  => like Point but for complex numbers
#   Complex-Vector => like Vector but with complex numbers
#   Complex-Matrix => like Matrix but with complex numbers
#
# You can list the defined contexts using:
#
# \{join($BR, lex_sort keys  %Parser::Context::Default::context )\}

=cut

package Parser::Context::Default;
use vars qw($operators $parens $lists $constants $variables $functions $strings $flags);
use strict;

=head2 Context hashes

#
#  Define the default  operators, parens, constants, variables functions, etc.
#
#  List types: e.g. Point, Vector, Matrix, -- define open and close brackets
#
#  strings, flags

=cut

$operators = {
   ',' => {precedence => 0, associativity => 'left', type => 'bin', string => ',',
           class => 'Parser::BOP::comma', isComma => 1},

   '+' => {precedence => 1, associativity => 'left', type => 'both', string => '+',
           class => 'Parser::BOP::add'},

   '-' => {precedence => 1, associativity => 'left', type => 'both', string => '-',
           class => 'Parser::BOP::subtract', rightparens => 'same'},

   'U' => {precedence => 1.5, associativity => 'left', type => 'bin', isUnion => 1,
           string => ' U ', TeX => '\cup ', class => 'Parser::BOP::union'},

   '><'=> {precedence => 2, associativity => 'left', type => 'bin',
           string => ' >< ', TeX => '\times ', perl => 'x', fullparens => 1,
           class => 'Parser::BOP::cross'},

   '.' => {precedence => 2, associativity => 'left', type => 'bin',
           string => '.', TeX => '\cdot ', class => 'Parser::BOP::dot'},

   '*' => {precedence => 3, associativity => 'left', type => 'bin', space => ' *',
           string => '*', TeX => '', class => 'Parser::BOP::multiply'},

   '/' => {precedence => 3, associativity => 'left', type => 'bin', string => '/',
           class => 'Parser::BOP::divide', space => ' /',
           rightparens => 'all', leftparens => 'extra', fullparens => 1},

   '//'=> {precedence => 3, associativity => 'left', type => 'bin', string => '/',
           class => 'Parser::BOP::divide',
           rightparens => 'all', leftparens => 'extra', fullparens => 1, noFrac => 1},

   ' /' => {precedence => 2.8, associativity => 'left', type => 'bin', string => '/',
           class => 'Parser::BOP::divide',
           rightparens => 'all', leftparens => 'extra', fullparens => 1, hidden => 1},

   '/ ' => {precedence => 2.8, associativity => 'left', type => 'bin', string => '/',
           class => 'Parser::BOP::divide',
           rightparens => 'all', leftparens => 'extra', fullparens => 1},

   ' *'=> {precedence => 2.8, associativity => 'left', type => 'bin', string => '*',
           class => 'Parser::BOP::multiply', TeX => '', hidden => 1},

   '* '=> {precedence => 2.8, associativity => 'left', type => 'bin', string => '*',
           class => 'Parser::BOP::multiply', TeX => ''},

   'fn'=> {precedence => 2.9, associativity => 'left', type => 'unary', string => '',
           parenPrecedence => 5, hidden => 1},

   ' ' => {precedence => 3.1, associativity => 'left', type => 'bin', string => '*',
           class => 'Parser::BOP::multiply', space => ' *', hidden => 1},

   'u+'=> {precedence => 6, associativity => 'left', type => 'unary', string => '+',
           class => 'Parser::UOP::plus', hidden => 1, allowInfinite => 1, nofractionparens => 1},

   'u-'=> {precedence => 6, associativity => 'left', type => 'unary', string => '-',
           class => 'Parser::UOP::minus', hidden => 1, allowInfinite => 1, nofractionparens => 1},

   '^' => {precedence => 7, associativity => 'right', type => 'bin', string => '^', perl => '**',
           class => 'Parser::BOP::power', leftf => 1, fullparens => 1, isInverse => 1},

   '**'=> {precedence => 7, associativity => 'right', type => 'bin', string => '^', perl => '**',
           class => 'Parser::BOP::power', leftf => 1, fullparens => 1, isInverse => 1},

   '!' => {precedence => 8, associativity => 'right', type => 'unary', string => '!',
           class => 'Parser::UOP::factorial', isCommand => 1},

   '_' => {precedence => 9, associativity => 'left', type => 'bin', string => '_',
           class => 'Parser::BOP::underscore', leftparens => 'all'},
};

$parens = {
   '(' => {close => ')', type => 'Point', formMatrix => 1, formInterval => ']',
           formList => 1, removable => 1, emptyOK => 1, function => 1},
   '[' => {close => ']', type => 'Point', formMatrix => 1, formInterval => ')', removable => 1},
   '<' => {close => '>', type => 'Vector'},
   '{' => {close => '}', type => 'Point', removable => 1},
   '|' => {close => '|', type => 'AbsoluteValue'},
   'start' => {close => 'start', type => 'List', formList => 1,
               removable => 1, emptyOK => 1, hidden => 1},
   'interval' => {type => 'Interval', hidden => 1},
   'list'     => {type => 'List', hidden => 1},
};

$lists = {
   'Point'         => {class =>'Parser::List::Point',         open => '(', close => ')', separator => ','},
   'Vector'        => {class =>'Parser::List::Vector',        open => '<', close => '>', separator => ','},
   'Matrix'        => {class =>'Parser::List::Matrix',        open => '[', close => ']', separator => ','},
   'List'          => {class =>'Parser::List::List',          open => '',  close => '',  separator => ', ',
                                                              nestedOpen => '(', nestedClose => ')'},
   'Interval'      => {class =>'Parser::List::Interval',      open => '(', close => ')', separator => ','},
   'Set'           => {class =>'Parser::List::Set',           open => '{', close => '}', separator => ','},
   'Union'         => {class =>'Parser::List::Union',         open => '',  close => '',  separator => ' U '},
   'AbsoluteValue' => {class =>'Parser::List::AbsoluteValue', open => '|', close => '|', separator => ''},
};

$constants = {
   'e'  => exp(1),
   'pi' => 4*atan2(1,1),
   'i'  => Value::Complex->new(0,1),
   'j'  => Value::Vector->new(0,1,0)->with(ijk=>1),
   'k'  => Value::Vector->new(0,0,1)->with(ijk=>1),
   '_blank_' => {value => 0, hidden => 1, string => "", TeX => ""},
};

$variables = {
   'x' => 'Real',
   'y' => 'Real',
   'z' => 'Real',
};

$functions = {
   'sin'   => {class => 'Parser::Function::trig', TeX => '\sin', inverse => 'asin', simplePowers => 1},
   'cos'   => {class => 'Parser::Function::trig', TeX => '\cos', inverse => 'acos', simplePowers => 1},
   'tan'   => {class => 'Parser::Function::trig', TeX => '\tan', inverse => 'atan', simplePowers => 1},
   'sec'   => {class => 'Parser::Function::trig', TeX => '\sec', inverse => 'asec', simplePowers => 1},
   'csc'   => {class => 'Parser::Function::trig', TeX => '\csc', inverse => 'acsc', simplePowers => 1},
   'cot'   => {class => 'Parser::Function::trig', TeX => '\cot', inverse => 'acot', simplePowers => 1},
   'asin'  => {class => 'Parser::Function::trig', TeX => '\sin^{-1}'},
   'acos'  => {class => 'Parser::Function::trig', TeX => '\cos^{-1}'},
   'atan'  => {class => 'Parser::Function::trig', TeX => '\tan^{-1}'},
   'asec'  => {class => 'Parser::Function::trig', TeX => '\sec^{-1}'},
   'acsc'  => {class => 'Parser::Function::trig', TeX => '\csc^{-1}'},
   'acot'  => {class => 'Parser::Function::trig', TeX => '\cot^{-1}'},

   'sinh'   => {class => 'Parser::Function::hyperbolic', TeX => '\sinh',
		inverse => 'asinh', simplePowers => 1},
   'cosh'   => {class => 'Parser::Function::hyperbolic', TeX => '\cosh',
		inverse => 'acosh', simplePowers => 1},
   'tanh'   => {class => 'Parser::Function::hyperbolic', TeX => '\tanh',
		inverse => 'atanh', simplePowers => 1},
   'sech'   => {class => 'Parser::Function::hyperbolic', inverse => 'asech', simplePowers => 1},
   'csch'   => {class => 'Parser::Function::hyperbolic', inverse => 'acsch', simplePowers => 1},
   'coth'   => {class => 'Parser::Function::hyperbolic', TeX => '\coth',
		inverse => 'acoth', simplePowers => 1},
   'asinh'  => {class => 'Parser::Function::hyperbolic', TeX => '\sinh^{-1}'},
   'acosh'  => {class => 'Parser::Function::hyperbolic', TeX => '\cosh^{-1}'},
   'atanh'  => {class => 'Parser::Function::hyperbolic', TeX => '\tanh^{-1}'},
   'asech'  => {class => 'Parser::Function::hyperbolic', TeX => '\mathop{\rm sech}^{-1}'},
   'acsch'  => {class => 'Parser::Function::hyperbolic', TeX => '\mathop{\rm csch}^{-1}'},
   'acoth'  => {class => 'Parser::Function::hyperbolic', TeX => '\coth^{-1}'},

   'ln'    => {class => 'Parser::Function::numeric', inverse => 'exp',
	       TeX => '\ln', simplePowers => 1},
   'log'   => {class => 'Parser::Function::numeric', TeX => '\log', simplePowers => 1},
   'log10' => {class => 'Parser::Function::numeric', nocomplex => 1, TeX => '\log_{10}'},
   'exp'   => {class => 'Parser::Function::numeric', inverse => 'log', TeX => '\exp'},
   'sqrt'  => {class => 'Parser::Function::numeric', braceTeX => 1, TeX => '\sqrt'},
   'abs'   => {class => 'Parser::Function::numeric'},
   'int'   => {class => 'Parser::Function::numeric'},
   'sgn'   => {class => 'Parser::Function::numeric', nocomplex => 1},

   'atan2' => {class => 'Parser::Function::numeric2'},

   'norm'  => {class => 'Parser::Function::vector', vectorInput => 1},
   'unit'  => {class => 'Parser::Function::vector', vectorInput => 1, vector => 1},

   'arg'   => {class => 'Parser::Function::complex'},
   'mod'   => {class => 'Parser::Function::complex'},
   'Re'    => {class => 'Parser::Function::complex', TeX => '\Re'},
   'Im'    => {class => 'Parser::Function::complex', TeX => '\Im'},
   'conj'  => {class => 'Parser::Function::complex', complex => 1, TeX => '\overline', braceTeX => 1, matrix => 1},

   # Det, Inverse, Transpose, Floor, Ceil?

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

   'logten' => {alias => 'log10'},
};

$strings = {
   'infinity'  => {infinite => 1},
   'inf'  => {alias => 'infinity'},
   'NONE' => {},
   'DNE'  => {},
#   'T' => {true => 1},
#   'F' => {false => 1},
};

$flags = {
  ijk => 0,                     # 1 = show all vectors in ijk form
  ijkAnyDimension => 1,         # 1 = add/remove trailing zeros to match dimension in comparisons
  reduceConstants => 1,         # 1 = automatically combine constants
  reduceConstantFunctions => 1, # 1 = compute function values of constants
  showExtraParens => 1,         # 1 = add useful parens, 2 = make things painfully unambiguous
  formatStudentAnswer => 'evaluated',  # or 'parsed' or 'reduced'
  allowMissingOperands => 0,           # 1 is used by Typeset context
  allowMissingFunctionInputs => 0,     # 1 is used by Typeset context
  allowBadOperands => 0,               # 1 is used by Typeset context (types need not match)
  allowBadFunctionInputs => 0,         # 1 is used by Typeset context (types need not match)
  allowWrongArgCount => 0,             # 1 = numbers need not be correct
};

############################################################################
############################################################################
#
#  Special purpose contexts
#

use vars qw(%context);
my $context;

#
#  The default Context
#
$context = $context{Full} = new Parser::Context(
  operators => $operators,
  functions => $functions,
  constants => $constants,
  variables => $variables,
  strings   => $strings,
  parens    => $parens,
  lists     => $lists,
  flags     => $flags,
  reduction => $Parser::reduce,
);

$context->constants->set(
  pi => {TeX => '\pi ', perl => 'pi'},
  i => {isConstant => 1, perl => 'i'},
  j => {TeX => '\boldsymbol{j}', perl => 'j'},
  k => {TeX => '\boldsymbol{k}', perl => 'k'},
);

$context->usePrecedence('Standard');
$context->{name} = "Full";

#
#  Numeric context (no vectors, matrices or complex numbers)
#
$context = $context{Numeric} = $context{Full}->copy;
$context->variables->are(x=>'Real');
$context->operators->undefine('><','.');
$context->functions->undefine('norm','unit','arg','mod','Re','Im','conj');
$context->constants->remove('i','j','k');
$context->parens->remove('<');
$context->parens->set(
   '(' => {type => 'List', formMatrix => 0},
   '[' => {type => 'List', formMatrix => 0},
   '{' => {type => 'List'},
);
$context->{name} = "Numeric";

#
#  Vector context (no complex numbers)
#
$context = $context{Vector} = $context{Full}->copy;
$context->variables->are(x=>'Real',y=>'Real',z=>'Real');
$context->functions->undefine('arg','mod','Re','Im','conj');
$context->constants->replace(i=>Value::Vector->new(1,0,0)->with(ijk=>1));
$context->constants->set(i=>{TeX=>'\boldsymbol{i}', perl=>'i'});
$context->parens->set('(' => {formMatrix => 0});

$context = $context{Vector2D} = $context{Vector}->copy;
$context->constants->replace(
  i => Value::Vector->new(1,0)->with(ijk=>1),
  j => Value::Vector->new(0,1)->with(ijk=>1),
);
$context->constants->set(
  i => {TeX=>'\boldsymbol{i}', perl=>'i'},
  j => {TeX=>'\boldsymbol{j}', perl=>'j'}
);
$context->constants->remove("k");
$context->{name} = "Vector2D";

#
#  Point context (for symmetry)
#
$context = $context{Point} = $context{Vector}->copy;
$context->operators->undefine("><",".");
$context->functions->undefine('norm','unit');
$context->constants->remove('i','j','k');
$context->parens->remove("<");
$context->{name} = "Point";

#
#  Matrix context (square brackets make matrices in preference to points or intervals)
#
$context = $context{Matrix} = $context{Vector}->copy;
$context->parens->set(
  '(' => {formMatrix => 1},
  '[' => {type => 'Matrix', removable => 0},
);
$context->{name} = "Matrix";

#
#  Interval context (make intervals rather than lists)
#
$context = $context{Interval} = $context{Numeric}->copy;
$context->parens->set(
   '(' => {type => 'Interval'},
   '[' => {type => 'Interval'},
   '{' => {type => 'Set', removable => 0, emptyOK => 1},
);
my $infinity = Value::Infinity->new();
$context->constants->add(
  R => Value::Interval->new('(',-$infinity,$infinity,')'),
);
$context->constants->set(R => {TeX => '{\bf R}'});
$context->{name} = "Interval";

#
#  Complex context (no vectors or matrices)
#
$context = $context{Complex} = $context{Full}->copy;
$context->variables->are(z=>'Complex');
$context->operators->undefine('><','.');
$context->functions->undefine('norm','unit');
$context->constants->remove('j','k');
$context->parens->remove('<');
$context->parens->set(
   '(' => {type => 'List', formMatrix => 0},
   '[' => {type => 'List', formMatrix => 0},
   '{' => {type => 'List'},
);
$context->operators->set(
  '^'  => {class => 'Parser::Function::complex_power', negativeIsComplex => 1},
  '**' => {class => 'Parser::Function::complex_power', negativeIsComplex => 1},
);
$context->functions->set(
  'sqrt' => {class => 'Parser::Function::complex_numeric', negativeIsComplex => 1},
  'log'  => {class => 'Parser::Function::complex_numeric', negativeIsComplex => 1},
);
$context->{name} = "Complex";

#
#  Complex-Vector context
#
$context = $context{"Complex-Vector"} = $context{Complex}->copy;
$context->operators->redefine('><','.');
$context->parens->add('<' => {close => '>', type => 'Vector'});
$context->parens->set(
  '(' => {type => "Point", formMatrix => 0},
  '[' => {type => "Point", formMatrix => 0},
  '{' => {type => "Point"},
);
$context->{name} = "Complex-Vector";

#
#  Complex-Point context
#
$context = $context{"Complex-Point"} = $context{"Complex-Vector"}->copy;
$context->operators->undefine("><",".");
$context->parens->remove("<");
$context->{name} = "Complex-Point";

#
#  Complex-Matrix context
#
$context = $context{"Complex-Matrix"} = $context{"Complex-Vector"}->copy;
$context->parens->set(
  '(' => {formMatrix => 1},
  '[' => {type => 'Matrix', removable => 0},
);
$context->{name} = "Complex-Matrix";


#########################################################################

1;
