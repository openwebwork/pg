loadMacros("Parser.pl");

package Typeset;

sub addVariables {
  my $context = shift; my @vars;
  foreach my $v ('a'..'z','A'..'Z') {push(@vars,$v=>'Real')}
  $context->variables->are(@vars);
  $context->variables->remove('U'); # used as operator below
}

######################################################################

package Typeset::Function;
@ISA = qw(Parser::Function);

sub _check {
  my $self = shift;
  $self->{type} = $Value::Type{number};
}

sub eval {
  my $self = shift;
  $self->Error("Can't evaluate '%s'",$self->{name});
}

sub perl {
  my $self = shift;
  $self->Error("No perl form for '%s'",$slef->{name});
}

######################################################################

package Typeset::Function::named;
@ISA = qw(Typeset::Function);

# just override the _check method

######################################################################

package Typeset::Function::text;
@ISA = qw(Typeset::Function);

sub TeX {
  my $self = shift; my @params;
  foreach my $p (@{$self->{params}}) {push(@params,$p->{isQuoted}? $p->{value}: $p->string)};
  return '\hbox{'.join('',@params).'}';
}

######################################################################

package Typeset::Function::TeX;
@ISA = qw(Typeset::Function);

sub TeX {
  my $self = shift; my @params;
  foreach my $p (@{$self->{params}}) {push(@params,$p->{isQuoted}? $p->{value}: $p->string)};
  return join('',@params);
}

######################################################################

package Typeset::Function::bf;
@ISA = qw(Typeset::Function);

sub TeX {
  my $self = shift; my @params;
  foreach my $p (@{$self->{params}}) {push(@params,$p->TeX)};
  return '{\bf '.join('',@params).'}';
}

######################################################################

package Typeset::Function::cal;
@ISA = qw(Typeset::Function);

sub TeX {
  my $self = shift; my @params;
  foreach my $p (@{$self->{params}}) {push(@params,$p->TeX)};
  return '{\cal '.join('',@params).'}';
}

######################################################################

package Typeset::Function::det;
@ISA = qw(Typeset::Function);

sub TeX {
  my $self = shift;
  return $self->SUPER::TeX(@_) unless $self->{params}[0]->type eq 'Matrix';
  my $M = bless {%{$self->{params}[0]}, open => '|', close => '|'}, ref($self->{params}[0]);
  return '\det'.$M->TeX;
}

######################################################################

package Typeset::Function::accent;
@ISA = qw(Typeset::Function);

sub _check {
  my $self = shift;
  return if $self->checkArgCount(1);
  $self->{type} = $self->{params}[0]->typeRef;
}

sub TeX {
  my $self = shift; 
  return '{'.$self->{def}{TeX}.'{'.$self->{params}[0]->TeX.'}}';
}

######################################################################

package Typeset::Function::overunder;
@ISA = qw(Typeset::Function);

sub _check {
  my $self = shift;
  return if $self->checkArgCount(1);
  $self->{type} = $self->{params}[0]->typeRef;
}

sub TeX {
  my $self = shift; 
  return $self->{def}{TeX}.'{'.$self->{params}[0]->TeX.'}';
}

######################################################################

package Typeset::Function::Fence;
@ISA = qw(Typeset::Function);

sub _check {
  my $self = shift; my $n = scalar(@{$self->{params}});
  $self->Error("Fence requires an open parenthesis, a formula, and a close parenthesis") if $n < 3;
  if ($n > 3) {$self->{type} = Value::Type("List",$n,$Value::Type{unknown})}
    else {$self->{type} = $self->{params}[1]->typeRef}
}

sub TeX {
  my $self = shift; my @params = @{$self->{params}};
  my $open = shift(@params); my $close = pop(@params);
  $open = $open->{isQuoted}? $open->{value}: $open->string;
  $close = $close->{isQuoted}? $close->{value}: $close->string;
  $open = "." unless $open; $close = "." unless $close;
  $open = '\{' if $open eq '{'; $close = '\}' if $close eq '}';
  foreach my $p (@params) {$p = $p->TeX}
  return '\left'.$open." ".join(',',@params).'\right'.$close." ";
}

######################################################################

package Typeset::Function::Cases;
@ISA = qw(Typeset::Function);

sub _check {
  my $self = shift;
  $self->{formulas} = []; $self->{conditions} = [];
  $self->Error("There must be at least one argument for '%s'",$self->{name})
    unless scalar(@{$self->{params}}) > 0;
  foreach my $p (@{$self->{params}}) {
    if ($p->type eq 'List' && $p->length == 2) {
      push(@{$self->{formulas}},$p->{coords}[0]);
      push(@{$self->{conditions}},$p->{coords}[1]);
    } elsif ($p->class eq 'BOP' && $p->{bop} eq '->') {
      push(@{$self->{formulas}},$p->{rop});
      push(@{$self->{conditions}},$p->{lop});
    } elsif ($p->class eq 'BOP' && $p->{bop} eq 'if ') {
      push(@{$self->{formulas}},$p->{lop});
      my $if = $self->{equation}{context}{parser}{UOP}->new($self->{equation},'_if_',$p->{rop});
      push(@{$self->{conditions}},$if);
    } elsif ($p->class eq 'UOP' && $p->{uop} eq 'otherwise') {
      push(@{$self->{formulas}},$p->{op});
      my $otherwise = $self->{equation}{context}{parser}{String}->new($self->{equation},'"otherwise"');
      push(@{$self->{conditions}},$otherwise);
    } else {
      $self->Error("The arguments for '%s' must be function-condition pairs",$self->{name});
    }
  }
  my $type = $self->{formulas}[0]->typeRef;
  foreach my $f (@{$self->{formulas}}) {
    $self->Error("The formulas for '%s' must all be of the same type",$self->{name})
      unless Parser::Item::typeMatch($type,$f->typeRef);
  }
  $self->{type} = $type;
}

sub TeX {
  my $self = shift; my @rows = ();
  my @f = @{$self->{formulas}}; my @c = @{$self->{conditions}};
  foreach my $i (0..$#f) {push(@rows,$f[$i]->TeX.'&'.$c[$i]->TeX."\\\\ ")}
  return '\begin{cases}'.join('',@rows).'\end{cases}';
}

######################################################################

package Typeset::Function::Array;
@ISA = qw(Typeset::Function);

sub _check {
  my $self = shift;
  my $equation = $self->{equation}; my $context = $equation->{context};
  my $template; my $param = $self->{params}[0];
  $self->Error("Array requires a list of entries") unless defined $param;
  if ($param && $param->class eq 'QuotedString') {
    $template = shift(@{$self->{params}})->{value};
  }
  if (scalar(@{$self->{params}}) == 1 && $self->{params}[0]->type eq 'Matrix') {
    $self->{M} = $self->{params}[0];
  } else {
    my $null = $context->{parser}{Constant}->new($equation,"Null");
    my @rows = @{$self->{params}};
    @rows = @{$rows[0]->{coords}} if scalar(@rows) == 1 && $rows[0]->class eq 'List';
    my $c = 0; foreach my $r (@rows) {$c = $r->length if $r->length > $c}
    if ($c == 1 && scalar(@rows) > 1) {
      $c = scalar(@rows);
      @rows = ($context->{parser}{List}->new($equation,[@rows],0,$context->{parens}{start}));
    }
    foreach my $r (@rows) {
      $r = ($r->class eq 'List'? $r->{coords} : [$r]);
      while (scalar(@{$r}) < $c) {push(@{$r},$null)};
      $r = bless
        $context->{parser}{List}->new($equation,$r,0,$context->{parens}{start},$Value::Type{number},'[',']'),
        $context->{lists}{Matrix}{class};
    }
    $self->{M} = bless
        $context->{parser}{List}->new($equation,\@rows,0,$context->{parens}{start},$rows[0]->typeRef),
        $context->{lists}{Matrix}{class};
  }
  $self->{M}{open} = $self->{M}{close} = '';
  $self->{M}{array_template} = $template;
  $self->{type} = $self->{M}->typeRef;
}

sub TeX {my $self = shift; $self->{M}->TeX}

######################################################################

package Typeset::Function::bigOp;
@ISA = qw(Typeset::Function);

sub _check {
  my $self = shift; my $name = $self->{name};
  my @params = @{$self->{params}}; my $allowMax = !$self->{def}{noMax};
  ## check for (x;fn),  (m,M; fn),  (x:m,M; fn),  (x,m,M; fn),  (x->m; fn)
  if (scalar(@params) == 2) {
    $self->{op} = $params[1]; my $lop = $params[0];
    if ($lop->type eq 'List') {
      if ($lop->length == 2 && $allowMax) {
	$self->{min} = $lop->{coords}[0];
	$self->{max} = $lop->{coords}[1];
      } elsif ($lop->length == 3 && $lop->{coords}[0]->class eq 'Variable' && $allowMax) {
	$self->{var} = $lop->{coords}[0];
	$self->{min} = $lop->{coords}[1];
	$self->{max} = $lop->{coords}[2];
      } else {
	$self->{min} = $lop;
      }
    } elsif ($lop->class eq 'Variable') {
      $self->{var} = $lop;
    } elsif ($lop->class eq 'BOP' && $lop->{bop} eq ':') {
      if ($lop->{lop}->class eq 'Variable') {
	$self->{var} = $lop->{lop};
	if ($lop->{rop}->class eq 'List' && $lop->{rop}->length == 2 && $allowMax) {
	  $self->{min} = $lop->{rop}{coords}[0];
	  $self->{max} = $lop->{rop}{coords}[1];
	} else {$self->{min} = $lop->{rop}}
      } else {$self->{min} = $lop}
    } elsif ($lop->class eq 'BOP' && $lop->{bop} eq '->') {
      if ($lop->{lop}->class eq 'Variable' && $self->{def}{allowArrow}) {
	$self->{var} = $lop->{lop};
	$self->{min} = $lop->{rop};
      } else {$self->{min} = $lop}
    } else {$self->{min} = $lop}
  } elsif (scalar(@params) == 1) {
    $self->{op} = $params[0];
  } else {
    $self->Error("Function '%s' has too many inputs",$name) if scalar(@params) > 2;
    $self->Error("Function '%s' requires a formula as input",$name) unless scalar(@params) < 1;
  }
  if (!$self->{var}) {
    my $variable = $self->{equation}{context}{parser}{Variable};
    my @vars = keys %{$self->{op}->getVariables};
    if (scalar(@vars) == 1) {
      $self->{var} = $variable->new($self->{equation},$vars[0]);
      $self->{implicitVar} = 1;
    }
  }
  $self->{type} = $self->{op}->typeRef;
}

sub TeX {
  my ($self,$precedence,$showparens,$position) = @_;
  my $fn = $self->{def}; my $x = $self->{var};
  my $min = $self->{min}; my $max = $self->{max};
  $min = $min->TeX if defined $min;
  $max = $max->TeX if defined $max;
  $min = (defined($min)? $x->TeX.($fn->{allowArrow} ? '\to ' : '=').$min : $x->TeX)
    if defined $x && !$fn->{dx};
  my $TeX = $fn->{TeX}.(defined($min)? "_{$min}": "").
                       (defined($max)? "^{$max}": "")." ".$self->{op}->TeX;
  $TeX .= '\,d'.$x->TeX if defined $x && $fn->{dx};
  if (defined($precedence) and $precedence > $fn->{precedence})
    {$TeX = '\left('.$TeX.'\right)'} else {$TeX = "{$TeX}"}
  return $TeX;
}

sub string {
  my ($self,$precedence,$showparens,$position,$outerRight,$power) = @_;
  my $fn = $self->{equation}{context}{operators}{'fn'};
  my $fn_precedence = $fn->{precedence};
  $fn_precedence = $fn->{parenPrecedence}
    if ($position && $position eq 'right' && $fn->{parenPrecedence});
  $fn = $self->{def}; my $x = $self->{var};
  my $min = $self->{min}; my $max = $self->{max};
  $min = $min->string if defined $min;
  $max = $max->string if defined $max;
  $min = (defined($min)? $x->string.($fn->{allowArrow}? "->": ":").$min : $x->string)
    if defined $x && !$self->{implicitVar};
  my $string = (defined($min)? $min: "").(defined($max)? ",$max": "");
  $string .= ";" if $string ne "";
  $string = $self->{name}.'('.$string.$self->{op}->string.')';
  $string = $self->addParens($string) if (defined($precedence) and $precedence > $fn_precedence);
  return $string;
}

######################################################################

package Typeset::BOP;
@ISA = qw(Parser::BOP);

######################################################################

package Typeset::BOP::TeX;
@ISA = qw(Typeset::BOP);

sub _check {
  my $self = shift;
  $self->{isConstant} = 0;
  $self->{type} = $Value::Type{number};
}

sub _eval {
  my $self = shift;
  my $name = $self->{def}{string} || $self->{bop};
  $self->Error("Can't evaluate '%s'",$name);
}

sub perl {
  my $self = shift;
  my $name = $self->{def}{string} || $self->{bop};
  $self->Error("No perl form for '%s'",$name);
}

######################################################################

package Typeset::BOP::subtract;
@ISA = qw(Parser::BOP::subtract);

sub matchError {
  my $self = shift; my ($ltype,$rtype) = @_;
  return $self->SUPER::matchError(@_)
    unless $ltype->{name} =~ m/Number|Set/ && $rtype->{name} =~ m/Number|Set/;
  $self->{type} = Value::Type('Set',1);
}

######################################################################

package Typeset::BOP::union;
@ISA = qw(Parser::BOP::union);

# handle _check to set type for numbers and sets

######################################################################

package Typeset::BOP::divide;
@ISA = qw(Parser::BOP::divide);

sub TeX {
  my $self = shift;
  my ($precedence,$showparens,$position,$outerRight) = @_;
  my $TeX; my $bop = $self->{def};
  return $self->SUPER::TeX(@_) if $self->{def}{noFrac};
  $showparens = '' unless defined($showparens);
  my $addparens =
      defined($precedence) &&
      ($showparens eq 'all' || ($precedence > $bop->{precedence} && $showparens ne 'nofractions') ||
      ($precedence == $bop->{precedence} &&
        ($bop->{associativity} eq 'right' || $showparens eq 'same')));

  $self->{lop}{showParens} = $self->{rop}{showParens} = 0;
  $TeX = '\frac{'.($self->{lop}->TeX).'}{'.($self->{rop}->TeX).'}';
  $self->{lop}{showParens} = $self->{rop}{showParens} = 1;

  $TeX = '\left('.$TeX.'\right)' if $addparens;
  return $TeX;
}


######################################################################

package Typeset::BOP::power;
@ISA = qw(Parser::BOP::power);

sub TeX {
  my $self = shift; my $rop = $self->{rop};
  my ($open,$close,$parens) = ($rop->{open},$rop->{close});
  $rop->{open} = $rop->{close} = "" if $rop->{isSetType} || $rop->{isListType};
  my $tex = Parser::BOP::underscore::TeX($self,@_);
  $rop->{open} = $open; $rop->{close} = $close;
  return $tex;
}

######################################################################

package Typeset::BOP::underscore;
@ISA = qw(Typeset::BOP::TeX);

sub TeX {
  my $self = shift; my $rop = $self->{rop};
  my ($open,$close,$parens) = ($rop->{open},$op->{close});
  $rop->{open} = $rop->{close} = "" if $rop->{isSetType} || $rop->{isListType};
  my $tex = Parser::BOP::underscore::TeX($self,@_);
  $rop->{open} = $open; $rop->{close} = $close;
  return $tex;
}

######################################################################

package Typeset::BOP::colon;
@ISA = qw(Typeset::BOP::TeX);

sub string {
  my $self = shift;
  my ($lop,$rop) = ($self->{lop},$self->{rop});
  return $self->SUPER::string(@_) unless $lop->class eq 'Variable' &&
    $rop->class eq 'BOP' && $rop->{def}{isFnArrow};
  return $lop->string.': '.$rop->string;
}

sub TeX {
  my $self = shift;
  my ($lop,$rop) = ($self->{lop},$self->{rop});
  return $self->SUPER::TeX(@_) unless $lop->class eq 'Variable' &&
    $rop->class eq 'BOP' && $rop->{def}{isFnArrow};
  return $lop->TeX.'\colon '.$rop->TeX;
}

######################################################################

package Typeset::BOP::semicolon;
@ISA = qw(Typeset::BOP);

sub _check {
  my $self = shift;
  my ($ltype,$rtype) = ($self->{lop}->typeRef,$self->{rop}->typeRef);
  my $type = Value::Type('Comma',2,$Value::Type{unknown});
  if ($ltype->{name} eq 'Comma' && $self->{lop}{isSemicolon}) {
    $type->{length} += $self->{lop}->length - 1;
    $ltype = $self->{lop}->entryType;
  }
  $type->{entryType} = $ltype if (Parser::Item::typeMatch($ltype,$rtype));
  $self->{type} = $type;
  $self->{isSemicolon} = 1;
}

sub _eval {($_[1],$_[2])}

sub makeList {
  my $self = shift;
  return $self unless $self->{isSemicolon};
  my ($lop,$rop) = ($self->{lop},$self->{rop});
  my $equation = $self->{equation}; my $context = $equation->{context};
  $lop = $context->{parser}{List}->
    new($equation,[$lop->makeList],$lop->{isConstant},$context->{parens}{start},$lop->entryType,'(',')')
      if $lop->{def}{isComma} && !$lop->{isSemicolon};
  $rop = $context->{parser}{List}->
    new($equation,[$rop->makeList],$dop->{isConstant},$context->{parens}{start},$rop->entryType,'(',')')
      if $rop->{def}{isComma};
  return (($self->{lop}{isSemicolon} ? $lop->makeList : $lop),
	  ($self->{rop}{isSemicolon} ? $rop->makeList : $rop));
}

######################################################################

package Typeset::UOP;
@ISA = qw(Parser::UOP);

sub TeX {
  my ($self,$precedence,$showparens,$position,$outerRight) = @_;
  my $TeX; my $uop = $self->{def}; $position = '' unless defined($position);
  my $fracparens = ($uop->{nofractionparens}) ? "nofractions" : "";
  my $addparens = $outerRight;
  $TeX = (defined($uop->{TeX}) ? $uop->{TeX} : $uop->{string});
  if ($uop->{associativity} eq "right") {
    $TeX = $self->{op}->TeX($uop->{precedence},$fracparens) . $TeX;
  } else {
    $TeX = $TeX . $self->{op}->TeX($uop->{precedence},$fracparens);
  }
  $TeX = '\left('.$TeX.'\right)' if $addparens;
  return $TeX;
}

######################################################################

package Typeset::UOP::TeX;
@ISA = qw(Typeset::UOP);

sub _check {
  my $self = shift;
  $self->{isConstant} = 0;
  $self->{type} = $Value::Type{number};
}

sub _eval {
  my $self = shift;
  my $name = $self->{def}{string} || $self->{bop};
  $self->Error("Can't evaluate '%s'",$name);
}

sub TeX {
  my ($self,$precedence) = @_;
  my $TeX; my $uop = $self->{def};
  $TeX = (defined($uop->{TeX}) ? $uop->{TeX} : $uop->{string});
  if ($uop->{associativity} eq "right")
     {$TeX = $self->{op}->TeX($uop->{precedence}) . $TeX} else
     {$TeX = $TeX . $self->{op}->TeX($uop->{precedence})}
  return $TeX;
}

sub perl {
  my $self = shift;
  my $name = $self->{def}{string} || $self->{bop};
  $self->Error("No perl form for '%s'",$name);
}

######################################################################

package Typeset::UOP::_if_;
@ISA = qw(Typeset::UOP::TeX);

sub string {
  my $self = shift;
  return ' if '.$self->{op}->string;
}

sub TeX {
  my $self = shift;
  return '\hbox{if }'.$self->{op}->TeX;
}

######################################################################

package Typeset::UOP::prime;
@ISA = qw(Typeset::UOP::TeX);

sub string {
  my ($self,$precedence,$showparens,$position,$outerRight) = @_;
  my $uop = $self->{def}; $position = '' unless defined($position);
  my $addparens = defined($precedence) &&
    ($precedence > $uop->{precedence} || $position eq 'right' || $outerRight);
  my $string = $self->{op}->string($uop->{precedence},$fracparens) . "'";
  $string = '\left('.$string.'\right)' if $addparens;
  return $string;
}

sub TeX {
  my ($self,$precedence,$showparens,$position,$outerRight) = @_;
  my $uop = $self->{def}; $position = '' unless defined($position);
  my $addparens = defined($precedence) &&
    ($precedence > $uop->{precedence} || $position eq 'right' || $outerRight);
  my $TeX = $self->{op}->TeX($uop->{precedence},$fracparens) . "'";
  $TeX = '\left('.$TeX.'\right)' if $addparens;
  return $TeX;
}

######################################################################

package Typeset::UOP::root;
@ISA = qw(Typeset::UOP::TeX);

sub TeX {
  my $self = shift;
  return "\\root ".$self->{op}->TeX if $self->{op}->class eq 'BOP' && $self->{op}{bop} eq 'of ';
  return "\\root ".$self->{op}{coords}[0]->TeX." \\of {".$self->{op}{coords}[1]->TeX."}"
    if $self->{op}->class eq 'List' && scalar(@{$self->{op}{coords}}) == 2;
  return "\\sqrt{".$self->{op}->TeX."}";
}

package Typeset::BOP::of;
@ISA = qw(Typeset::BOP::TeX);

sub TeX {
  my $self = shift;
  return $self->{lop}->TeX . " \\of {" . $self->{rop}->TeX . "}";
}

######################################################################

package Typeset::List;
@ISA = qw(Parser::List);

sub _eval {
  my $self = shift;
  return $self->SUPER::_eval(@_) unless $self->type eq 'Number';
  $self->{coords}[0]->eval(@_);
}

sub new {
  my $self = shift;
  my $equation = shift; my $coords = shift;
  my $constant = shift; my $paren = shift;
  my $entryType = shift || $Value::Type{unknown};
  my $open = shift || ''; my $close = shift || '';
  my $context = $equation->{context};
  my $parens = $context->{parens};

  if ($paren && $close && $paren->{formInterval}) {
    $paren = $parens->{interval}
      if ($paren->{close} ne $close || (scalar(@{$coords}) == 2 &&
           ($coords->[0]->{isInfinite} || $coords->[1]->{isInfinite})));
  }
  my $type = Value::Type($paren->{type},scalar(@{$coords}),$entryType,
                                list => 1, formMatrix => $paren->{formMatrix});
  if ($type->{name} ne 'Interval' && ($type->{name} ne 'Set' || $type->{length} != 0)) {
    if ($paren->{formMatrix} && $entryType->{formMatrix}) {$type->{name} = 'Matrix'}
    elsif ($entryType->{name} eq 'unknown') {
      if ($paren->{formList}) {$type->{name} = 'List'}
      elsif ($type->{name} eq 'Point') {
        $equation->Error("Entries in a Matrix must be of the same type and length")}
      elsif ($type->{name} ne 'Set') {
	$type->{name} = "Matrix" if $paren->{formMatrix};
	$equation->Error(["Entries in a %s must be of the same type",$type->{name}]);
      }
    }
  }
  $open = '' if $open eq 'start'; $close = '' if $close eq 'start';
  my $list = bless {
    coords => $coords, type => $type, open => $open, close => $close,
    paren => $paren, equation => $equation, isConstant => $constant
  }, $context->{lists}{$type->{name}}{class};
  $list->weaken;

  my $zero = 1;
  foreach my $x (@{$coords}) {$zero = 0, last unless $x->{isZero}}
  $list->{isZero} = 1 if $zero && scalar(@{$coords}) > 0;

  $list->_check;

#  warn ">> $list->{type}{name} of $list->{type}{entryType}{name} of length $list->{type}{length}\n";

  if ($list->{isConstant} && $context->flag('reduceConstants')) {
    $type = $list->{type};
    $list = $list->Item("Value")->new($equation,[$list->eval]);
    $list->{type} = $type; $list->{open} = $open; $list->{close} = $close;
    $list->{value}->{open} = $open, $list->{value}->{close} = $close
      if ref($list->{value});
  }
  return $list;
}

######################################################################

package Typeset::List::List;
@ISA = qw(Typeset::List Parser::List::List);

sub _check {
  my $self = shift;
  $self->{isListType} = 1; $self->{showParens} = 1;
  return unless $self->length == 1;
  $self->{type} = {%{$self->{coords}[0]->typeRef}};
  $self->{type}{formMatrix} = 1 if $self->context->{parens}{$self->{open}}{formMatrix};
  $self->{isSingle} = 1;
  $self->entryType->{entryType} = $self->{coords}[0]->type if scalar(@{$self->{coords}}) == 1;
}

sub TeX {
  my $self = shift;
  return $self->SUPER::TeX(@_) if $self->{showParens} || $self->length != 1;
  return $self->{coords}[0]->TeX(@_);
}

######################################################################

package Typeset::List::Vector;
@ISA = qw(Parser::List::List);

sub TeX {
  my $self = shift; my $precedence = shift; my @coords = ();
  my $def = $self->context->{lists}{Vector};
  my ($open,$close) = ($def->{TeX_open},$def->{TeX_close});
  $open = '\{' if $open eq '{'; $close = '\}' if $close eq '}';
  $open  = '\left' .$open  if $open  ne '';
  $close = '\right'.$close if $close ne '';
  foreach my $x (@{$self->{coords}}) {push(@coords,$x->TeX)}
  return $open.join(',',@coords).$close unless $self->{ColumnVector};
  '\left[\begin{array}{c}'.join('\cr'."\n",@coords).'\cr\end{array}\right]';
}

######################################################################

package Typeset::List::Set;
@ISA = qw(Typeset::List);

sub _check {
  my $self = shift;
  $self->{isSetType} = 1; $self->{showParens} = 1;
  return unless $self->length == 1;
  my $x = $self->{coords}[0];
  if ($x->{isSetType}) {
    $x->{showParens} = 1;
    $self->{showParens} = 0;
  } else {
    if ($x->class =~ m/BOP|UOP/) {
      $self->{type} = $self->{coords}[0]->typeRef;
      $self->{showParens} = 0;
    }
  }
}

sub canBeInUnion {1};

sub string {
  my $self = shift; my $precedence = shift;
  return $self->SUPER::string(@_) if $self->{showParens} || $self->length > 1;
  my $set = $self->{coords}[0];
  return '{ '.$set->string.' }' if $set->class eq 'BOP' && $set->{def}{formSet};
  return $self->{coords}[0]->string;
}

sub TeX {
  my $self = shift; my $precedence = shift;
  return $self->SUPER::TeX(@_) if $self->{showParens} || $self->length > 1;
  my $set = $self->{coords}[0];
  return '\left\{\,'.$set->TeX.'\,\right\}' if $set->class eq 'BOP' && $set->{def}{formSet};
  return $self->{coords}[0]->TeX;
}

######################################################################

package Typeset::List::AbsoluteValue;
@ISA = qw(Parser::List::AbsoluteValue);

sub TeX {
  my $self = shift;
  return $self->SUPER::TeX(@_) unless $self->{coords}[0]->type eq 'Matrix';
  my $M = bless {%{$self->{coords}[0]}, open => '|', close => '|'}, ref($self->{coords}[0]);
  $M->TeX;
}

######################################################################

package main;

$context{Typeset} = $Parser::Context::Default::context{Full}->copy;
$context{Typeset}->flags->set(
  reduceConstants => 0,
  reduceConstantFunctions => 0,
  allowMissingOperands => 1,          # turn off most error checking
  allowMissingFunctionInputs => 1,    #  by setting these four
  allowBadOperands => 1,              #  flags to 1
  allowBadFunctionInputs => 1,        #
  showExtraParens => 0,               # Try to keep the author's parens
);
$context{Typeset}->{_initialized} = 0;  # prevent updating of patterns until we're done

sub TeXOp {
  my $type = shift; my $prec = shift; my $assoc = shift;
  my $op = shift; my $string = shift; my $tex = shift;
  $tex = "" unless defined $tex; $tex .= " " if substr($tex,0,1) eq "\\";
  my $class = 'Typeset::'.($type eq 'bin'? "BOP" : "UOP").'::TeX';
  return $op => {precedence => $prec, associativity => $assoc, type => $type,
	  string => $string, TeX=>$tex, class=>$class, @_};
}
sub TeXUnary {my $op = shift; TeXOp("unary",1,"left",$op," $op ",@_)}
sub TeXBin {my $op = shift; TeXOp("bin",.8,"left",$op," $op ",@_)}
sub TeXRel {my $op = shift; TeXOp("bin",.7,"left",$op," $op ",@_)}
sub TeXArrow {my $op = shift; TeXOp("bin",.7,"left",$op," $op ",@_)}

$context{Typeset}->operators->add(
  ';' => {
    precedence => 0, associativity => 'left', type => 'bin', string => ';',
    class => 'Typeset::BOP::semicolon', isComma => 1
  },
  '_if_' => {
    precedence => .61, associativity => 'left', type => 'unary', string => ' if ',
    class => 'Typeset::UOP::_if_', hidden => 1
  },
  "'" => {
    precedence => 7.5, associativity => 'right', type => 'unary', string => "'",
    class => 'Typeset::UOP::prime'
  },
);

$context{Typeset}->operators->set(
  ',' => {precedence=>.5},
  '_' => {class=>'Typeset::BOP::underscore',associativity=>"right"},
  ' ' => {string => 'space'},
  'space' => {precedence => 3, associativity => 'left', type => 'bin',
	      string => '', TeX => '', class => 'Parser::BOP::multiply', hidden => 1},
  '/'  => {class => 'Typeset::BOP::divide'},
  '/ ' => {class => 'Typeset::BOP::divide'},
  ' /' => {class => 'Typeset::BOP::divide'},
  '^'  => {class => 'Typeset::BOP::power'},
  '**' => {class => 'Typeset::BOP::power'},
  '-'  => {class => 'Typeset::BOP::subtract'},
  'U'  => {class => 'Typeset::BOP::union'},
);

$context{Typeset}->operators->redefine('&', using => ",", from=>$context{Typeset});
$context{Typeset}->operators->redefine("\\\\", using => ";", from => $context{Typeset});
$context{Typeset}->operators->redefine("cross", using => "><", from => $context{Typeset});

$context{Typeset}->operators->add(
  TeXArrow('->','\to',isFnArrow=>1),
  TeXArrow('-->','\longrightarrow'),
  TeXArrow('<-','\leftarrow'),
  TeXArrow('<--','\longleftarrow'),
  TeXArrow('<->','\leftrightarrow'),
  TeXArrow('<-->','\longleftrightarrow'),
  TeXArrow('|->','\mapsto'),
  TeXArrow('|-->','\longmapsto'),
  TeXArrow('*->','\hookrightarrow'),
  TeXArrow('<-*','\hookleftarrow'),
  TeXArrow('=>','\Rightarrow'),
  TeXArrow('==>','\Longrightarrow'),
  TeXArrow('<=:','\Leftarrow'),
  TeXArrow('<==','\Longleftarrow'),
  TeXArrow('<=>','\Leftrightarrow'),
  TeXArrow('<==>','\Longleftrightarrow'),
  TeXArrow("up",'\uparrow'),
  TeXArrow('down','\downarrow'),
  TeXArrow('updown','\updownarrow'),
  TeXArrow('Up','\Uparrow'),
  TeXArrow('Down','\Downarrow'),
  TeXArrow('Updown','\Updownarrow'),
  TeXArrow('NW','\nwarrow'),
  TeXArrow('SE','\searrow'),
  TeXArrow('SW','\swarrow'),
  TeXArrow('NE','\nearrow'),
  TeXArrow('iff','\Leftrightarrow'),

  TeXRel('<','<'),                  TeXRel('lt','<'),
  TeXRel('>','>'),                  TeXRel('gt','>'),
  TeXRel('<=','\le'),               TeXRel('le'),
  TeXRel('>=','\ge'),               TeXRel('ge'),
  TeXRel('=','='),
  TeXRel('!=','\ne'),               TeXRel('ne','\ne'),
  TeXRel('<<','\ll'),
  TeXRel('>>','\gg'),
  TeXRel('sim','\sim'),             TeXRel('~','\sim'),
  TeXRel('simeq','\simeq'),         TeXRel('~-','\simeq'),
  TeXRel('cong','\cong'),           TeXRel('~=','\cong'),
  TeXRel('approx','\approx'),       TeXRel('~~','\approx'),
  TeXRel('equiv','\equiv'),         TeXRel('-=','\equiv'),
  TeXRel('vdash','\vdash'),         TeXRel('|--','\vdash'),
  TeXRel('dashv','\dashv'),         TeXRel('--|','\dashv'),
  TeXRel('perp','\perp'),           TeXRel('_|_','\perp'),
  TeXRel('parallel','\parallel'),   TeXRel('||','\parallel'),
  TeXRel('doteq','\doteq'),         TeXRel('=.=','\doteq'),
  TeXRel('models','\models'),       TeXRel('|==','\models'),
  TeXRel('in','\in'),
  TeXRel('subset','\subset'),
  TeXRel('subseteq','\subseteq'),
  TeXRel('sqsubseteq','\sqsubseteq'),
  TeXRel('supset','\supset'),
  TeXRel('supseteq','\supseteq'),
  TeXRel('sqsupseteq','\sqsupseteq'),
  TeXRel('prec','\prec'),           TeXRel('-<','\prec'),
  TeXRel('preceq','\preceq'),       TeXRel('-<=','\preceq'),
  TeXRel('succ','\succ'),           TeXRel('>-','\succ'),
  TeXRel('succeq','\succeq'),       TeXRel('>-=','\succeq'),
  TeXRel('propto','\propto'),
  TeXRel('mid','\mid', precedence=>.3,formSet=>1),
                                    TeXRel('s.t. ','\mid',string=>" s.t. ",precedence=>.3,formSet=>1),
  TeXRel('ni','\ni'),               TeXRel('gets','\gets'),
  TeXRel('smile','\smile'),
  TeXRel('frown','\frown'),
  TeXRel('asymp','\asymp'),
  TeXRel('bowtie','\bowtie'),

  TeXRel('!<','\not<'),                TeXRel('!lt','\not<'),
  TeXRel('!>','\not>'),                TeXRel('!gt','\not>'),
  TeXRel('!<=','\not\le'),             TeXRel('!ge','\not\le'),
  TeXRel('!>=','\not\ge'),             TeXRel('!le','\not\ge'),
  TeXRel('!sim','\not\sim'),           TeXRel('!~','\not\sim'),
  TeXRel('!simeq','\not\simeq'),       TeXRel('!~-','\not\simeq'),
  TeXRel('!cong','\not\cong'),         TeXRel('!~=','\not\cong'),
  TeXRel('!approx','\not\approx'),     TeXRel('!~~','\not\approx'),
  TeXRel('!perp',',\not\perp'),        TeXRel('!_|_','\not\perp'),
  TeXRel('!parallel','\not\parallel'), TeXRel('!||','\not\parallel'),
  TeXRel('!equiv','\not\equiv'),       TeXRel('!-=','\not\equiv'),
  TeXRel('!in','\notin'),
  TeXRel('!subset','\not\subset'),
  TeXRel('!subseteq','\not\subseteq'),
  TeXRel('!sqsubseteq','\not\sqsubseteq'),
  TeXRel('!supset','\not\supset'),
  TeXRel('!supseteq','\not\supseteq'),
  TeXRel('!sqsupseteq','\not\sqsupseteq'),
  TeXRel('!prec','\not\prec'),         TeXRel('!-<','\not\prec'),
  TeXRel('!preceq','\not\preceq'),     TeXRel('!-<=','\not\preceq'),
  TeXRel('!succ','\not\succ'),         TeXRel('!>-','\not\succ'),
  TeXRel('!succeq','\not\succeq'),     TeXRel('!>-=','\not\succeq'),
  TeXRel('!asymp','\not\asymp'),

  TeXBin(':',' :',class=>'Typeset::BOP::colon',precedence=>.3,isColon=>1,formSet=>1),
  TeXBin('::',' ::'),
  TeXUnary('pm','\pm'),
  TeXUnary('mp','\mp'),
  TeXBin('setminus','\setminus'),
  TeXBin('cdot','\cdot'),
  TeXBin('ast','\ast'),
  TeXBin('star','\star'),
  TeXBin('diamond','\diamond'),
  TeXBin('circ','\circ'),    TeXBin('o ','\circ'),
  TeXBin('bullet','\bullet'),
  TeXBin('div','\div'),      TeXBin('-:','\div'),
  TeXBin('cap','\cap'),
  TeXBin('cup','\cup'),
  TeXBin('uplus','\uplus'),  TeXBin('u+ ','\uplus'),
  TeXBin('sqcap','\sqcap'),
  TeXBin('sqcup','\sqcup'),
  TeXBin('triangleleft','\triangleleft'),
  TeXBin('triangleright','\triangleright'),
  TeXBin('wr','\wr'),
  TeXBin('bigcirc','\bigcirc'),
  TeXBin('bigtriangleup','\bigtriangleup'),
  TeXBin('bigtriangledown','\bigtriangledown'),
  TeXBin('vee','\vee'),       TeXBin("\\/",'\vee'),
  TeXBin('wedge','\wedge'),   TeXBin("/\\",'\wedge'),
  TeXBin('oplus','\oplus'),   TeXBin('o+ ','\oplus'),
  TeXBin('ominus','\ominus'), TeXBin('o- ','\ominus'),
  TeXBin('otimes','\otimes'), TeXBin('ox ','\otimes'),
  TeXBin('oslash','\oslash'), TeXBin('o/ ','\oslash'),
  TeXBin('odot','\odot'),     TeXBin('o. ','\odot'),
  TeXBin('amalg','\amalg'),
  TeXBin('times','\times'),

  TeXOp("bin",.63,"left",'and',' and ','\hbox{ and }'),
  TeXOp("bin",.62,"left",'or',' or ','\hbox{ or }'),
  TeXOp("unary",.64,"left",'not',' not ','\hbox{not }'),
  TeXOp("unary",.64,"left",'neg',' neg ','\neg'),

  TeXOp("bin",.61,"left",'if ',' if ','\hbox{ if }'),
  TeXOp("unary",.61,"right",'otherwise',' otherwise','\hbox{otherwise}'),

  TeXUnary('root', "\\root ", class=>'Typeset::UOP::root',precedence=>.65, string=>"root "),
  TeXBin('of ','\of',class=>'Typeset::BOP::of',precedence=>.66),

  TeXBin("quad",'\quad', precedence => .2),
  TeXBin("qquad",'\qquad', precedence => .2),
);

######################################################################

sub TeXGreek {
  my $greek = shift; my $uc = shift;
  push(@_,TeX=>"{\\rm $uc}") if $uc;
  return ($greek => {value => Real(1), TeX=>"\\$greek ", keepName=>1, @_});
}

sub TeXord {
  my $name = shift; my $tex = shift;
  $tex = "\\$name " unless defined $tex; $tex .= ' ' if $tex =~ m/\\[a-zA-Z]+$/;
  return ($name => {value => Real(1), TeX=>$tex, keepName=>1, @_});
}

sub TeXconst {
  my $name = shift; my $tex = shift; $tex .= " " unless $tex =~ m/}$/;
  my $string = shift; $string = $name unless defined $string;
  return ($name => {value => Real(1), TeX=>$tex, string=>$string, keepName=>1, @_});
}

$context{Typeset}->constants->{namePattern} = '.*';
$context{Typeset}->constants->are(
  TeXGreek('alpha'),    TeXGreek('Alpha','A'),
  TeXGreek('beta'),     TeXGreek('Beta','B'),
  TeXGreek('gamma'),    TeXGreek('Gamma'),
  TeXGreek('delta'),    TeXGreek('Delta'),
  TeXGreek('epsilon'),  TeXGreek('Epsilon','E'),   TeXGreek('varepsilon'),
  TeXGreek('zeta'),     TeXGreek('Zeta','Z'),
  TeXGreek('eta'),      TeXGreek('Eta','H'),
  TeXGreek('theta'),    TeXGreek('Theta',),        TeXGreek('vartheta'),
  TeXGreek('iota'),     TeXGreek('Iota','I'),
  TeXGreek('kappa'),    TeXGreek('Kappa','K'),
  TeXGreek('lambda'),   TeXGreek('Lambda'),
  TeXGreek('mu'),       TeXGreek('Mu','M'),
  TeXGreek('nu'),       TeXGreek('Nu','N'),
  TeXGreek('xi'),       TeXGreek('Xi'),
  TeXGreek('omicron'),  TeXGreek('Omicron','O'),
  TeXGreek('pi'),       TeXGreek('Pi'),            TeXGreek('varpi'),
  TeXGreek('rho'),      TeXGreek('Rho','P'),       TeXGreek('varrho'),
  TeXGreek('sigma'),    TeXGreek('Sigma'),         TeXGreek('varsigma'),
  TeXGreek('tau'),      TeXGreek('Tau','T'),
  TeXGreek('upsilon'),  TeXGreek('Upsilon'),
  TeXGreek('phi'),      TeXGreek('Phi'),           TeXGreek('varphi'),
  TeXGreek('chi'),      TeXGreek('Chi','X'),
  TeXGreek('psi'),      TeXGreek('Psi'),
  TeXGreek('omega'),    TeXGreek('Omega'),

  TeXconst('Null','',''),
  TeXconst('RR','{\bf R}','R'),
  TeXconst('QQ','{\bf Q}','Q'),
  TeXconst('CC','{\bf C}','C'),
  TeXconst('NN','{\bf N}','N'),
  TeXconst('ZZ','{\bf Z}','Z'),

  TeXord('aleph'),
  TeXord('hbar'),
  TeXord('imath'),
  TeXord('jmath'),
  TeXord('ell'),
  TeXord('wp'),
  TeXord('emptyset'),
  TeXord('nabla'),       TeXord('grad','\nabla'),
  TeXord('top'),
  TeXord('bot'),
  TeXord('angle'),
  TeXord('triangle'),
  TeXord('backslash'),
  TeXord('forall'),
  TeXord('exists'),
  TeXord('partial'),

  TeXord('ldots','\ldots'),  TeXord('..','\ldots'),
  TeXord('cdots','\cdots'),  TeXord('...','\cdots'),
  TeXord('vdots','\vdots'),
  TeXord('ddots','\ddots'),

  TeXord('inf','\inf'),
  TeXord('liminf','\liminf'),
  TeXord('limsup','\limsup'),
  TeXord('max','\max'),
  TeXord('min','\min'),
  TeXord('lim','\lim'),
  TeXord('sum','\sum'),
  TeXord('prod','\prod'),
  TeXord('coprod','\coprod'),
  TeXord('int','\int'),
# TeXord('iint','\iint'),
# TeXord('iiint','\iiint'),
  TeXord('oint','\oint'),
  TeXord('bigcup','\bigcup'),
  TeXord('bigcap','\bigcap'),
  TeXord('bigsqcup','\bigsqcup'),
  TeXord('bigvee','\bigvee'),
  TeXord('bigwedge','\bigwedge'),
  TeXord('bigodot','\bigodot'),
  TeXord('bigotimes','\bigotimes'),
  TeXord('bigoplus','\bigoplus'),
  TeXord('biguplus','\biguplus'),
);
$context{Typeset}->constants->add(_blank_ => {value => Real(0), hidden => 1, string => "", TeX => ""});

######################################################################

sub TeXBigOp {
  my $name = shift; my $tex = shift;
  return ($name => {class => 'Typeset::Function::bigOp', precedence => .9, TeX => $tex, @_});
}

sub TeXfn {
  my $name = shift;
  return ($name => {class => 'Typeset::Function::'.$name, @_});
}

sub TeXnamedFn {
  my $name = shift;
  return ($name => {class => 'Typeset::Function::named', TeX=>"\\$name", @_});
}

sub TeXaccent {
  my $name = shift;
  return ($name => {class => 'Typeset::Function::accent', TeX=>"\\$name", @_});
}

sub TeXoverunder {
  my $name = shift;
  return ($name => {class => 'Typeset::Function::overunder', TeX=>"\\$name", @_});
}

$context{Typeset}->functions->{namePattern} = qr/.*/;
$context{Typeset}->functions->add(
  TeXBigOp('Lim','\lim', allowArrow => 1, noMax => 1),
  TeXBigOp('Sum','\sum'),
  TeXBigOp('Prod','\prod'),
  TeXBigOp('Coprod','\coprod'),
  TeXBigOp('Int','\int', dx => 1, precedence => 6.5),
# TeXBigOp('IInt','\iint', dx => 1, precedence => 6.5),
# TeXBigOp('IIInt','\iiint', dx => 1, precedence => 6.5),
  TeXBigOp('Oint','\oint', dx => 1, precedence => 6.5),
  TeXBigOp('Cup','\bigcup'),
  TeXBigOp('Cap','\bigcap'),
  TeXBigOp('Sqcup','\bigsqcup'),
  TeXBigOp('Vee','\bigvee'),
  TeXBigOp('Wedge','\bigwedge'),
  TeXBigOp('Odot','\bigodot'),     TeXBigOp('O. ','\bigodot'),
  TeXBigOp('Otimes','\bigotimes'), TeXBigOp('Ox ','\bigotimes'),
  TeXBigOp('Oplus','\bigoplus'),   TeXBigOp('O+ ','\bigoplus'),
  TeXBigOp('Uplus','\biguplus'),   TeXBigOp('U+ ','\biguplus'),

  TeXfn('text'),
  TeXfn('bf'),
  TeXfn('cal'),
  TeXfn('Array'),
  TeXfn('TeX'),
  TeXfn('Fence'),
  TeXfn('Cases'),

  TeXfn('det', TeX=>"\\det"),

  TeXnamedFn('deg'),
  TeXnamedFn('dim'),
  TeXnamedFn('gcd'),
  TeXnamedFn('hom'),
#  TeXnamedFn('inf'),
  TeXnamedFn('ker'),
  TeXnamedFn('lg'),
#  TeXnamedFn('max'),
#  TeXnamedFn('min'),
  TeXnamedFn('Pr'),
#  TeXnamedFn('sup'),

  TeXaccent('hat'),
  TeXaccent('bar'),
  TeXaccent('vec'),
  TeXaccent('dot'),
  TeXaccent('ddot'),

  TeXoverunder('underline'),
  TeXoverunder('overline'),
  TeXoverunder('underbrace'),
  TeXoverunder('overbrace'),
);

######################################################################

$context{Typeset}->parens->set(
  '(' => {type => 'List', removable => 0, formMatrix => 0},
  '[' => {type => 'List', removable => 0},
  '{' => {type => "Set",  removable => 0, emptyOK=>1},
);
$context{Typeset}->parens->add(
  '<[' => {type => "Vector", close => ']>'},
);
$context{Typeset}->parens->remove('<');

$context{Typeset}->lists->set(
  Set    => {class => 'Typeset::List::Set'},
  List   => {class => 'Typeset::List::List'},
  Vector => {class => 'Typeset::List::Vector', TeX_open => "<", TeX_close => ">"},
  AbsoluteValue => {class => 'Typeset::List::AbsoluteValue'},
);
$context{Typeset}->{parser}{List} = 'Typeset::List';

######################################################################

Typeset::addVariables($context{Typeset});

######################################################################

$context{Typeset}->{_initialized} = 1; # now update the patterns
$context{Typeset}->update;

######################################################################

$context{Typeset}->strings->clear();
$context{Typeset}->strings->redefine("infty", using=>"infinity");
$context{Typeset}->strings->set(infty => {string => "infty"});
$context{Typeset}->strings->redefine("infinity");
loadMacros("parserQuotedString.pl");
QuotedString::enable($context{Typeset});

######################################################################

$context{"Typeset-Vector"} = $context{Typeset}->copy;
$context{"Typeset-Vector"}->operators->remove('<','>');
$context{"Typeset-Vector"}->parens->remove('<[');
$context{"Typeset-Vector"}->parens->redefine('<');

######################################################################

Context("Typeset");

######################################################################

1;

