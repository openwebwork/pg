package PGML;

######################################################################

my %terminate;  # defined below;
my %initiate;   # defined below;

######################################################################

my $indent = '^\t+';
my $linebreak = '\n+';
my $lineend = "(?:  |(?: +<<| #+) *)\$";
my $linestart = ' *[-+*o] +|(?:---+|===+)(?= *(?:\{.*?\} *)?$)|#+ |(?:\d+|[a-zA-Z])\. +|>> +|:   ';
my $emphasis = ' ?\*+ ?|(?:^|(?<=\t)| )_+(?=[^_\s]|$)|(?<=[^_\s])_+(?: |$)';
#my $chars = '\\\\.|(?:(?<=\])|(?<=\]\*))\n(?:\t+)? *\{|[{}[\]\'"]';  # allows { on next line after ]
my $chars = '\\\\.|[{}[\]\'"]';
my $ansrule = '\[(?:_+|[ox^])\]\*?';
my $open = '\[(?:[!<%@$]|::?|``?|\|+)';
my $close = '(?:[!>%@$]|::?|``?|\|+)\]';

my $linestart = "^(?:$linestart)|(?<=\\t)(?:$linestart)";

my $splitPattern = qr/($indent|$linestart|$open|$ansrule|$close|$lineend|$linebreak|$emphasis|$chars)/m;

sub splitString {
  my $string = shift;
  $string =~ s/\t/    /g;                             # turn tabs into spaces
  $string =~ s!^((?:    )+)!"\t"x(length($1)/4)!gme;  # make initial indent into tabs
  $string =~ s!^(?:\t* +|\t+ *)$!!gm;                 # make blank lines blank
  return split($splitPattern,$string);
}

######################################################################
######################################################################

sub startBlock {
  my ($stack,$type,$indent) = @_;
  $type = "block" unless $type;
  my $block; my $top = topBlock($stack);
  if ($top && $top->{typpe} eq 'block' && $top->{stack} && scalar(@{$top->{stack}}) == 0) {
    $block = $top;
    $block->{type} = $type;
    $block->{indent} = $indent if defined $indent;
  } else {
    $block = {
      type => $type, indent => ($indent || 0),
      stack => [], parseAll => 1,
    };
    push(@{$stack},$block);
  }
  return $block;
}

sub endBlock {
  my $stack = shift; my $cur = shift; my $action = shift || "paragraph ends";
  collapseText($cur);
  popWithError($cur,"'%s' was not closed before $action") if ref($cur->{terminator}) eq 'Regexp' || $cur->{cancelPar};
  my $block = topBlock($stack);
  delete $block->{parseAll}; delete $block->{pendingIndent}; delete $block->{ignoreNL};
}

sub topBlock {shift->[-1] || {}}
sub prevBlock {shift->[-2] || {}}

sub pushBlock {
  my ($cur,$token,$stack,$action,$type,$flags) = @_;
  endBlock($stack,$cur,$action);
  if ($type) {
    $cur = startBlock($stack,$type);
    foreach my $field (keys %{$cur}) {delete $cur->{$field} unless $field eq 'type'}
    $cur->{token} = $token;
  }
  $cur = startBlock($stack);
  if ($flags) {foreach my $flag (keys %$flags) {$cur->{$flag} = $flags->{$flag}}}
  $cur->{token} = $token unless defined $type;
  return $cur;
}

sub pushText {
  my $cur = shift; my $text = shift;
  return if $text eq "";
  delete $cur->{pendingIndent}; delete $cur->{ignoreNL};
  push(@{$cur->{stack}},{type=>"text",phrases=>[]})
    if scalar(@{$cur->{stack}}) == 0 || $cur->{stack}[-1]{type} ne "text" || !$cur->{stack}[-1]{phrases};
  push(@{$cur->{stack}[-1]{phrases}},$text);
}

sub pushItem {
  my ($cur,$token,$item) = @_;
  delete $cur->{pendingIndent}; delete $cur->{ignoreNL};
  collapseText($cur);
  $item = {%$item, stack=>[], prev=>$cur, token=>$token};
  return $item;
}

sub popItem {
  my $cur = shift;
  my $prev = $cur->{prev};
  pushText($prev,$cur->{token});
  push(@{$prev->{stack}},@{$cur->{stack}});
  pushText($prev,$cur->{terminator}) if $cur->{terminator} &&  ref($cur->{terminator}) ne 'Regexp';
  return $prev;
}

sub popWithError {
  my $cur = shift; my $message = shift;
  parseError($cur,$message);
  return popItem($cur);
}

######################################################################

our @warnings = ();
our $warningsFatal = 0;
sub Warning {
  my $warning = join("",@_);
  $warning =~ s/ at line \d+ of \(eval \d+\)//;
  $warning =~ s/ at \(eval \d+\) line \d+//;
  $warning =~ s/, at EOF$//;
  die $warning if $warningsFatal;
  push @warnings,$warning;
}
sub ClearWarnings {@warnings = ()};

sub parseError {
  my $cur = shift; my $message = shift;
  my $name = $cur->{token}; $name =~ s/^\s+|\s+$//g;
  $message = sprintf($message,$name);
  Warning "Error parsing PGML: $message";
}

sub Eval {main::PG_restricted_eval(@_)}

######################################################################
######################################################################

sub parseList {
  my $split = [@_]; my $i = 0;
  my $stack = [];
  my $cur = startBlock($stack); $cur->{ignoreNL} = 1;
  while ($i < scalar(@$split)) {
    pushText($cur,$split->[$i++]);
    my $token = $split->[$i++];
    for ($token) {
      $cur->{terminator} && /^$cur->{terminator}\z/ && do {$cur = parseEnd($cur,$token,$stack); last};
      /^\[[@\$]/  && ($cur->{parseAll} || $cur->{parseSubstitutions}) && do {$cur = parseBegin($cur,$token); last};
      /^\[%/      && ($cur->{parseAll} || $cur->{parseComments})      && do {$cur = parseBegin($cur,$token); last};
      /^\\./      && ($cur->{parseAll} || $cur->{parseSlashes})       && do {$cur = parseSlash($cur,$token); last};
      /^\n\z/     && do {$cur = parseLineBreak($cur,$token); last};
      /^\n\n+\z/  && do {$cur = parseParBreak($cur,$token,$stack); last};
      $cur->{balance} && /^$cur->{balance}/ && do {$cur = parseBegin($cur,$token,substr($token,0,1)); last};
      $cur->{balance} && /$cur->{balance}$/ && do {$cur = parseBegin($cur,$token,substr($token,-1,1)); last};
      $cur->{parseAll} && do {$cur = parseAll($cur,$token,$stack,$split,\$i); last};
      /^[\}\]]\z/ && do {$cur = parseUnbalanced($cur,$token); last};
      pushText($cur,$token);
    }
  }
  endBlock($stack,$cur,"END_PGML");
  my $top = topBlock($stack);
  pop(@$stack) if $top->{type} eq 'block' && scalar(@{$top->{stack}}) == 0;
  return $stack
}

######################################################################

sub parseEnd {
  my ($cur,$token,$stack) = @_;
  my $prev = $cur->{prev}; collapseText($cur);
  foreach my $field ("prev","parseComments","parseSubstitutions","parseSlashes",
                     "parseAll","cancelUnbalanced","cancelNL","cancelPar","balance")
    {delete $cur->{$field}}
  $cur->{terminator} = $token; delete $cur->{pendingIndent}; delete $cur->{ignoreNL};
  if (defined $terminate{$cur->{type}})
    {$prev = &{$terminate{$cur->{type}}}($prev,$cur,$stack)} else {push(@{$prev->{stack}},$cur)}
  return $prev;
}

sub parseBegin {
  my $cur = shift; my $token = shift; my $id = shift || $token;
  return pushItem($cur,$token,$initiate{$id});
}

sub parseBeginBlock {
  my ($cur,$token,$stack,$action,$id) = @_; $id = $token unless defined($id);
  my $top = topBlock($stack); my $indent;
  $indent = $top->{indent} if $top->{pendingIndent};
  $cur = pushBlock($cur,$token,$stack,$action,undef,$initiate{$id});
  $cur->{indent} = $indent if defined $indent;
  return $cur;
}

sub parseSlash {
  my $cur = shift; my $token = shift;
  pushText($cur,substr($token,1));
  return $cur;
}

sub parseLineBreak {
  my $cur = shift; my $token = shift;
  if ($cur->{ignoreNL}) {delete $cur->{ignoreNL}; return $cur}
  $cur = popWithError($cur,"%s was not closed before line break") if $cur->{cancelNL};
  pushText($cur,$token); $cur->{ignoreNL} = 1;
  return $cur;
}

sub parseParBreak {
  my ($cur,$token,$stack) = @_;
  return pushBlock($cur,$token,$stack,"paragraph break","par",{ignoreNL=>1});
}

sub parseUnbalanced {
  my ($cur,$token) = @_;
  $cur = popWithError($cur,"parenthesis mismatch: %s terminated by $token") if $cur->{cancelUnbalanced};
  pushText($cur,$token);
  return $cur;
}

sub parseAll {
  my ($cur,$token,$stack,$split,$i) = @_;
  return parseBegin($cur,$token) if (substr($token,0,1) eq "[" && $initiate{$token});
  for ($token) {
    /\t/        && do {return parseIndent($cur,$token,$stack)};
    /\d+\. /    && do {return parseBullet($cur,$token,$stack,"numeric")};
    /[a-z]\. /i && do {return parseBullet($cur,$token,$stack,"alpha")};
    /[-+o] /    && do {return parseBullet($cur,$token,$stack,"bullet")};
    /\{/        && do {return parseBrace($cur,$token,$stack)};
    /\[\|/      && do {return parseVerbatim($cur,$token)};
    /\[./       && do {return parseAnswer($cur,$token)};
    /_/         && do {return parseEmphasis($cur,$token,$stack)};
    /\*/        && do {return parseStar($cur,$token,$stack)};
    /#/         && do {return parseHeading($cur,$token,$stack)};
    /-|=/       && do {return parseRule($cur,$token,$stack)};
    /^  $/      && do {return parseBreak($cur,$token)};
    / <</       && do {return parseCenter($cur,$token,$stack)};
    />> /       && do {return parseBeginBlock($cur,$token,$stack,"start of aligned text",">> ")};
    /:   /      && do {return parseBeginBlock($cur,$token,$stack,"start of preformatted text")};
    pushText($cur,$token);
  }
  return $cur;
}

sub parseIndent {
  my ($cur,$token,$stack) = @_;
  my $indent = length($token);
  my $block = topBlock($stack);
  if (scalar(@{$block->{stack}}) == 0) {
    $block->{indent} = $indent;
  } elsif ($indent != $block->{indent}) {
    $cur = pushBlock($cur,$token,$stack,"indentation change",undef,{indent=>$indent})
  }
  $cur->{pendingIndent} = 1;
  return $cur;
}

sub parseBullet {
  my ($cur,$token,$stack,$type) = @_;
  $cur = parseBeginBlock($cur,$token,$stack,"start of list item","bullet");
  $cur->{bullet} = $type; $cur->{indent}++;
  return $cur;
}

sub parseStar {
  my ($cur,$token,$stack) = @_;
  if ($token =~ m/\*( *)/ && scalar(@{$cur->{stack}}) && $cur->{stack}[-1]{allowStar}) {
    $cur->{stack}[-1]{hasStar} = 1;
    pushText($cur,$1) if $1 ne "";
    return $cur;
  }
  return parseBullet($cur,$token,$stack,"bullet")
    if $token =~ m/\* +/ && ($cur->{ignoreNL} || $cur->{pendingIndent});
  return parseEmphasis($cur,$token,$stack)
}

sub parseEmphasis {
  my ($cur,$token,$stack) = @_;
  my $stars = $token; $stars =~ s/ //g;
  if (length($stars) <= 3) {
    if ($cur->{type} eq 'emphasis') {
      return parseEnd($cur,$token,$stack)
	if $stars eq $cur->{stars} && $token =~ m/^\S/;
    } elsif ($token !~ m/ $/) {
      $cur = parseBegin($cur,$token,'*');
      $cur->{stars} = $stars;
      return $cur;
    }
  }
  pushText($cur,$token);
  return $cur;
}

sub parseBrace {
  my ($cur,$token,$stack) = @_;
  my $top = topBlock($stack); my $prev = prevBlock($stack);
  if (scalar(@{$cur->{stack}}) && $cur->{stack}[-1]{options}) {
    $cur = parseBegin($cur,$token,' {');
  } elsif ($prev->{type} eq 'rule' && $top->{ignoreNL}) {
    pop(@$stack);
    $cur = {%{$initiate{' {'}},stack=>[],token=>$token,type=>'boptions'};
    push(@$tack,$cur);
  } else {pushText($cur,$token)}
  return $cur;
}

sub parseRule {
  my ($cur,$token,$stack) = @_;
  $cur = pushBlock($cur,$token,$stack,"horizontal rule","rule",{ignoreNL=>1});
  my $prev = prevBlock($stack);
  $prev->{options} = ["width","size"];
  return $cur;
}

sub parseBreak {
  my ($cur,$token) = @_;
  delete $cur->{pendingIndent};
  push(@{$cur->{stack}},{type=>"break",token=>$token});
  return $cur;
}

sub parseVerbatim {
  my ($cur,$token) = @_;
  my $bars = "\\".join("\\",split('',substr($token,1)));
  $cur = parseBegin($cur,$token,' [|');
  $cur->{terminator} = qr/$bars\]/;
  return $cur;
}

sub parseAnswer {
  my ($cur,$token) = @_;
  collapseText($cur);
  my @options = (); push(@options,hasStar=>1) if ($token =~ s/\*$//);
  push(@{$cur->{stack}},{
    type=>"answer",
    options=>["answer","width","name","array"],
    token=>$token,
    @options,
  });
  return $cur;
}

sub parseHeading {
  my ($cur,$token,$stack) = @_;
  if ($token =~ m/^ /) {
    my $block = topBlock($stack);
    if ($block->{type} eq 'heading') {
      my $stars = $token; $stars =~ s/[^\#]//g;
      if ($cur->{n} == length($stars)) {
	$block->{terminator} = $token;
	push(@{$cur->{stack}},{type=>"break"}) if $token =~ m/  $/;
	$cur = pushBlock($cur,$token,$stack,"end of heading",undef,{ignoreNL=>1});
	delete $cur->{token};
      } else {pushText($cur,$token)}
    } else {pushText($cur,$token)}
  } else {
    my $stars = $token; $stars =~ s/[^\#]//g;
    $cur = parseBeginBlock($cur,$token,$stack,"start of heading","# ");
    $cur->{n} = length($stars);
  }
  return $cur;
}

sub parseCenter {
  my ($cur,$token,$stack) = @_;
  my $block = topBlock($stack);
  if ($block->{align} eq 'right') {
    $block->{align} = 'center';
    $block->{terminator} = $token;
    push(@{$cur->{stack}},{type=>"break"}) if $token =~ m/  $/;
    $cur = pushBlock($cur,$token,$stack,"end of centered text",undef,{ignoreNL=>1});
  } else {pushText($cur,$token)}
  return $cur;
}

######################################################################
######################################################################

sub terminateComment {
  my ($prev,$cur) = @_;
  return $prev;
}

sub terminatePre {
  my ($prev,$cur,$stack) = @_;
  terminateGetString($prev,$cur);
  return startBlock($stack);
}

sub terminateBlockOptions {
  my ($prev,$cur,$stack) = @_;
  terminateGetString($prev,$cur); pop(@$tack);
  applyOptions(topBlock($stack),$cur->{text});
  $cur = startBlock($stack);
  $cur->{ignoreNL} = 1;
  return $cur;
}

sub terminateOptions {
  my ($prev,$cur,$stack) = @_;
  applyOptions($prev->{stack}[-1],stackString($cur));
  return $prev;
}

sub applyOptions {
  my $cur = shift; my $options = shift;
  if ($options =~ m/^[a-z_][a-z0-9_]*=>/i) {
    my %allowed = (map {$_ => 1} (@{$cur->{options}}));
    my ($options,$error) = Eval("{$options}");
    $options={},Warning "Error evaluating options: $error" if $error;
    foreach my $option (keys %{$options}) {
      if ($allowed{$option}) {$cur->{$option} = $options->{$option}}
        else {Warning "Error: unknown option '$option'"}
    }
  } else {
    foreach my $option (@{$cur->{options}}) {
      if (!defined($cur->{$option})) {
	if (!ref($options)) {
	  my ($value,$error) = Eval($options);
	  $options = $value unless $error; ### should give warning? only evaluate some answers?
	}
	$cur->{$option} = $options;
	return;
      }
    }
    Warning "Error: extra option '$options'";
  }
}

sub terminateBalance {
  my ($prev,$cur) = @_;
  pushText($prev,$cur->{token}.stackString($cur).$cur->{terminator});
  return $prev;
}

sub terminateGetString {
  my ($prev,$cur) = @_;
  $cur->{text} = stackString($cur);
  delete $cur->{stack};
  push(@{$prev->{stack}},$cur);
  return $prev;
}

######################################################################

sub stackString {
  my $cur = shift;
  my @strings = ();
  foreach my $item (@{$cur->{stack}}) {
    for ($item->{type}) {
      /text/     && do {push(@strings,replaceText($item)); last};
      /variable/ && do {push(@strings,replaceVariable($item,$cur)); last};
      /command/  && do {push(@strings,replaceCommand($item)); last};
      Warning "Warning: unexpected type '$item->{type}' in stackString\n";
    }
  }
  return $strings[0] if scalar(@strings) == 1;
  return join('',@strings);
}

sub replaceText {
  my $item = shift;
  return $item->{text} if defined $item->{text};
  return join('',@{$item->{phrases}});
}

sub replaceVariable {
  my $item = shift; my $cur = shift;
  my $var = "\$main::" . $item->{text};
  ### check $var for whether it looks like a variable reference
  my ($result,$error) = Eval($var);
  Warning "Error evaluating variable \$$item->{text}: $error" if $error;
  if ($cur->{type} eq 'math' && Value::isValue($result)) {
    if ($cur->{parsed}) {$result = $result->string} else {$result = '{'.$result->TeX.'}'}
  }
  return $result;
}

sub replaceCommand {
  my $item = shift;
  my $cmd = $item->{text};
  my ($result,$error) = Eval($cmd);
  Warning "Error evaluating command: $error" if $error;
  return $result;
}

sub collapseText {
  my $cur = shift;
  return unless $cur->{stack} && scalar(@{$cur->{stack}}) && $cur->{stack}[-1]{type} eq 'text';
  $cur->{stack}[-1]{text} = join('',@{$cur->{stack}[-1]{phrases}});
  delete $cur->{stack}[-1]{phrases};
}

######################################################################

%terminate = (
  comment  => \&terminateComment,
  pre      => \&terminatePre,
  boptions => \&terminateBlockOptions,
  balance  => \&terminateBalance,
  variable => \&terminateGetString,
  command  => \&terminateGetString,
  math     => \&terminateGetString,
  image    => \&terminateGetString,
  link     => \&terminateGetString,
  verbatim => \&terminateGetString,
  options  => \&terminateOptions,
);

my $balanceAll = qr/[\{\[\'\"]/;

%initiate = (
  "[:"   => {type=>'math', parseComments=>1, parseSubstitutions=>1, terminator=>qr/:\]/, parsed=>1,
	      options=>["context","reduced"]},
  "[::"  => {type=>'math', parseComments=>1, parseSubstitutions=>1, terminator=>qr/::\]/, parsed=>1, display=>1,
	      options=>["context","reduced"]},
  "[`"   => {type=>'math', parseComments=>1, parseSubstitutions=>1, terminator=>qr/\`\]/},
  "[``"  => {type=>'math', parseComments=>1, parseSubstitutions=>1, terminator=>qr/\`\`\]/, display=>1},
  "[!"   => {type=>'image', parseComments=>1, parseSubstitutions=>1, terminator=>qr/!\]/, cancelNL=>1,
              options=>["title"]},
  "[<"   => {type=>'link', parseComments=>1, parseSubstitutions=>1, terminator=>qr/>\]/, cancelNL=>1,
              options->["text","title"]},
  "[%"   => {type=>'comment', parseComments=>1, terminator=>qr/%\]/},
  "[\@"  => {type=>'command', parseComments=>1, parseSubstitutions=>1, terminator=>qr/@\]/,
               balance=>qr/[\'\"]/, allowStar=>1},
  "[\$"  => {type=>'variable', parseComments=>1, parseSubstitutions=>1, terminator=>qr/\$?\]/,
	       balance=>$balanceAll, cancelUnbalanced=>1, cancelNL=>1, allowStar=>1},
  ' [|'  => {type=>'verbatim', cancelNL=>1, allowStar=>1},
  " {"   => {type=>'options', parseComments=>1, parseSubstitutions=>1, terminator=>qr/\}/,
	       balance=>$balanceAll, cancelUnbalanced=>1},
  "{"    => {type=>'balance', parseComments=>1, parseSubstitutions=>1, terminator=>qr/\}/,
	       balance=>$balanceAll, cancelUnbalanced=>1},
  "["    => {type=>'balance', parseComments=>1, parseSubstitutions=>1, terminator=>qr/\]/,
	       balance=>$balanceAll, cancelUnbalanced=>1},
  "'"    => {type=>'balance', terminator=>qr/\'/},
  '"'    => {type=>'balance', terminator=>qr/\"/},
  ":   " => {type=>'pre', terminator=>qr/\n+/},
  ">> "  => {type=>'block', parseAll=>1, align=>"right"},
  "# "   => {type=>'heading', parseAll=>1},
  "bullet" => {type=>'bullet', parseAll=>1},
  "*"    => {type=>"emphasis", parseAll=>1, cancelPar=>1},
);

######################################################################
######################################################################

sub htmlString {
  my $stack = shift;
  my @strings = (); my $string;
  my $indents = [];
  foreach my $i (0..scalar(@$stack)-1) {
    my $item = $stack->[$i];
    push(@strings,htmlIndent($item,$indents)) if defined $item->{indent};
    next if $item->{processed};
    for ($item->{type}) {
      /block/   && do {push(@strings,htmlBlock($stack,$i)); last};
      /par/     && do {push(@strings,htmlPar($item)); last};
      /bullet/  && do {push(@strings,htmlBullet($stack,$i)); last};
      /heading/ && do {push(@strings,htmlHeading($stack,$i)); last};
      /rule/    && do {push(@strings,htmlRule($item)); last};
      /pre/     && do {push(@strings,htmlPre($stack,$i)); last};
      Warning "Warning: unknown block type: $item->{type}\n";
    }
  }
  while (scalar(@$indents)) {push(@strings,htmlStopIndent(pop(@$indents)))}
  return join('',@strings);
}

my $block = {type => "block"};
sub htmlIndent {
  my $item = shift; my $indents = shift;
  my $string;
  if ($item->{indent} > scalar(@$indents)) {
    while ($item->{indent}-1 > scalar(@$indents)) {$string .= htmlStartIndent($block); push(@$indents,$block)}
    $string .= htmlStartIndent($item); push(@$indents,$item);
    return $string;
  }
  while ($item->{indent} < scalar(@$indents)) {$string .= htmlStopIndent(pop(@$indents))}
  if (scalar(@$indents) && $item->{type} eq 'bullet' && $indents->[-1]{type} ne 'bullet') {
    $string = htmlStopIndent(pop(@$indents)).htmlStartIndent($item);
    push(@$indents,$item);
  }
  return $string;
}

sub htmlStartIndent {
  my $item = shift;
  return "<blockquote>\n" unless $item->{type} eq 'bullet';
  $item->{isFirst} = 1;
  return "<ul>\n" if $item->{bullet} eq 'bullet';
  return "<ol>\n" if $item->{bullet} eq 'numeric';
  return '<ol type="a">'."\n";
}

sub htmlStopIndent {
  my $item = shift;
  return "</blockquote>\n" unless $item->{type} eq 'bullet';
  return "</li>\n</ul>\n" if $item->{bullet} eq 'bullet';
  return "</li>\n</ol>\n";
}

sub htmlBlock {
  my $stack = shift; my $i = shift; my $item = $stack->[$i];
  my $html = htmlStack($item);
  return $html unless $item->{align};
  my $next = $stack->[$i+1] || {};
  $item->{isContinued} = $next->{isContinuation} = 1
    if $next->{type} eq 'block' &&
       $next->{indent} == $item->{indent} &&
       $next->{align} eq $item->{align};
  return ($item->{isContinuation} ? "" : '<div align="'.$item->{align}.'">'."\n").
         htmlStack($item).
         ($item->{isContinued} ? "\n" : "\n</div>\n");
}

sub htmlBreak {"<br />\n"}

sub htmlPar {
  my $item = shift;
  my $end = ($item->{endLI} ? "</li>" : "");
  return $end."\n<p>\n"
};

sub htmlBullet {
  my $stack = shift; my $i = shift; my $item = $stack->[$i];
  while (++$i < scalar(@$stack)) {
    if ($stack->[$i]{type} eq 'bullet' && $stack->[$i]{indent} == $item->{indent}) {
      $stack->[$i-1]{endLI} = $stack->[$i]{isFirst} = 1	if $stack->[$i-1]{type} eq 'par';
      last;
    }
    if (defined $stack->[$i]{indent} && $stack->[$i]{indent} < $item->{indent}) {
      $stack->[$i-1]{indent} = $stack->[$i]{indent} if $stack->[$i-1]{type} eq 'par';
      last;
    }
  }
  $stack->[-1]{indent} = 0 if $i == scalar(@$stack) && $stack->[-1]{type} eq 'par';
  my $end = ($item->{isFirst} ? "" : "</li>\n");
  return "$end<li>".htmlStack($item);
}

sub htmlHeading {
  my $stack = shift; my $i = shift; my $item = $stack->[$i];
  my $n = $item->{n}; my $next = $stack->[$i+1] || {};
  $item->{isContinued} = $next->{isContinuation} = 1
    if $next->{type} eq 'heading' &&
       $next->{indent} == $item->{indent} &&
       $next->{n} == $n;
  return ($item->{isContinuation} ? "\n" : "<h$n>").
         htmlStack($item).
	 ($item->{isContinued} ? "" : "</h$n>\n");
}

sub htmlRule {
  my $item = shift; my $width = ""; my $size = "";
  $width = ' width="'.$item->{width}.'"' if defined $item->{width};
  $size = ' size="'.$item->{size}.'"' if defined $item->{size};
  return "\n<hr$width$size />\n";
}

sub htmlPre {
  my $stack = shift; my $i = shift; my $item = $stack->[$i];
  my $next = $stack->[$i+1] || {};
  $item->{isContinued} = $next->{isContinuation} = 1
    if $next->{type} eq 'pre' && $next->{indent} == $item->{indent};
  return ($item->{isContinuation} ? "\n" : "\n<pre><code>").
         htmlEscape($item->{text}).
	 ($item->{isContinued} ? "" : "</code></pre>\n");
}

sub htmlMath {
  my $item = shift; my $math = $item->{text};
  if ($item->{parsed}) {
    my $context = $main::context{Typeset};
    if ($item->{context}) {
      if (Value::isContext($item->{context})) {$context = $item->{context}}
      else {$context = Parser::Context->getCopy(undef,$item->{context})}
    }
    $context->clearError;
    my $obj = Parser::Formula($context,$math);
    if ($context->{error}{flag}) {
      Warning "Error parsing mathematics: $context->{error}{message}";
      return "(math error)";
    }
    $math = $obj->TeX;
  }
  $math = "\\displaystyle{$math}" if $item->{display};
  return main::math_ev3($math);
}

sub htmlEmphasis {
  my $item = shift;
  my ($begin,$end) = @{(['<i>','</i>'],['<b>','</b>'],['<i><b>','</b></i>'])[length($item->{stars})-1]};
  my ($bspace,$espace) = ($item->{token},$item->{terminator});
  $bspace =~ s/\S//g; $espace =~ s/\S//g;
  return $bspace.$begin.stackString($item).$end.$espace;
}

sub htmlAnswer {
  my $item = shift;
  my $ans = $item->{answer};
  $item->{width} = length($item->{token})-2 if (!defined($item->{width}));
  if (defined($ans)) {
    if (ref($ans) =~ /CODE|AnswerEvaluator/) {
      if ($item->{name}) {
	main::NAMED_ANS($item->{name} => $ans);
	return main::NAMED_ANS_RULE($item->{name},$item->{width});
      } else {
	main::ANS($ans);
	return main::ans_rule($item->{width});
      }
    }
    unless (Value::isValue($ans)) {
      $ans = Parser::Formula($item->{answer});
      if (defined($ans)) {
	$ans = $ans->eval if $ans->isConstant;
	$ans->{correct_ans} = "$item->{answer}";
	$item->{answer} = $ans; $cmp = $ans->cmp;
      } else {
	Warning "Error parsing answer: ".Value->context->{error}{message};
	$ans = main::String("");  ### use something else?
      }
    }
    my @options = ($item->{width});
    my $method = ($item->{hasStar} ? "ans_array" : "ans_rule");
    if ($item->{name}) {
      unshift(@options,$item->{name});
      $method = "named_".$method;
    }
    main::ANS($ans->cmp) unless ref($ans) eq 'MultiAnswer' && $ans->{part} > 1;
    if ($item->{hasStar}) {
      my $HTML = $ans->$method(@options);
      $HTML =~ s!\\!\\\\!g;
      return main::EV3($HTML);
    } else {return $ans->$method(@options)}
  } else {
    return main::ans_rule($item->{width});
  }
}

sub htmlVerbatim {
  my $item = shift;
  my $text = htmlEscape($item->{text});
  $text = "<code>$text</code>" if $item->{hasStar};
  return $text;
}

sub htmlCommand {
  my $item = shift;
  my $text = replaceCommand($item);
  $text = htmlEscape($text) unless $item->{hasStar};
  return $text;
}

sub htmlVariable {
  my ($item,$cur) = @_;
  my $text = replaceVariable($item,$cur);
  $text = htmlEscape($text) unless $item->{hasStar};
  return $text;
}

sub htmlStack {
  my $cur = shift;
  my @strings = ();
  foreach my $item (@{$cur->{stack}}) {
    for ($item->{type}) {
      /text/     && do {push(@strings,htmlEscape(replaceText($item))); last};
      /variable/ && do {push(@strings,htmlVariable($item,$cur)); last};
      /command/  && do {push(@strings,htmlCommand($item)); last};
      /math/     && do {push(@strings,htmlMath($item)); last};
      /emphasis/ && do {push(@strings,htmlEmphasis($item)); last};
      /break/    && do {push(@strings,htmlBreak($item)); last};
      /verbatim/ && do {push(@strings,htmlVerbatim($item)); last};
      /answer/   && do {push(@strings,htmlAnswer($item)); last};
      Warning "Warning: unexpected type '$item->{type}' in htmlStack\n";
    }
  }
  return join('',@strings);
}

sub htmlEscape {
  my $string = shift;
  $string =~ s/&/\&amp;/g;
  $string =~ s/</&lt;/g;
  $string =~ s/>/&gt;/g;
  $string =~ s/"/&quot;/g;
  return $string;
}

######################################################################
######################################################################

sub Format {
  die "TeX mode not yet implemented" if $main::displayMode eq 'TeX';
  ClearWarnings;
  my $html = htmlString(parseList(splitString(shift)));
  warn join('',@warnings)."\n" if scalar(@warnings);
  return $html;
}

######################################################################


1;
