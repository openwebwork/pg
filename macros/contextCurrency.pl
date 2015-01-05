################################################################################
# WeBWorK Online Homework Delivery System
# Copyright © 2000-2007 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader: pg/macros/contextCurrency.pl,v 1.17 2009/06/25 23:28:44 gage Exp $
# 
# This program is free software; you can redistribute it and/or modify it under
# the terms of either: (a) the GNU General Public License as published by the
# Free Software Foundation; either version 2, or (at your option) any later
# version, or (b) the "Artistic License" which comes with this package.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See either the GNU General Public License or the
# Artistic License for more details.
################################################################################

=head1 NAME

contextCurrency.pl - Context for entering numbers with currency symbols and
commas.

=head1 DESCRIPTION

This file implements a context in which students can enter currency
values that include a currency symbol and commas every three digits.
You can specify what the currency symbol is, as well as what gets
used for commas and decimals.

To use the context, put

	loadMacros("contextCurrency.pl");

at the top of your problem file, and then issue the

	Context("Currency");

command to select the context.  You can set the currency symbol
and the comma or decimal values as in the following examples

	Context()->currency->set(symbol=>'#');
	Context()->currency->set(symbol=>'euro');          # accepts '12 euro'
	Context()->currency->set(comma=>'.',decimal=>','); # accepts '10.000,00'

You can add additional symbols (in case you want to allow
more than one way to write the currency).  For example:

	Context("Currency")->currency->addSymbol("dollars","dollar");

would accept '$12,345.67' or '12.50 dollars' or '1 dollar' as
acceptable values.  Note that if the symbol cantains any
alphabetic characters, it is expected to come at the end of the
number (as in the examples above) and if the symbol has only
non-alphabetic characters, it comes before it.  You can change
this as in these examples:

	Context()->currency->setSymbol(euro=>{associativity=>"left"});
	Context()->currency->setSymbol('#'=>{associativity=>"right"});

You can remove a symbol as follows:

	Context()->currency->removeSymbol('dollar');

To create a currency value, use

	$m = Currency(10.99);

or

	$m1 = Compute('$10.99');
	$m2 = Compute('$10,000.00');

and so on.  Be careful, however, that you do not put dollar signs
inside double quotes, as this refers to variable substitution.
For example,

	$m = Compute("$10.99");

will most likely set $m to the Real value .99 rather than the
monetary value of $10.99, since perl thinks $10 is the name of
a variable, and will substitute that into the string before
processing it.  Since that variable is most likely empty, the
result will be the same as $m = Compute(".99");

You can use monetary values within computations, as in

	$m1 = Compute('$10.00');
	$m2 = 3*$m1;  $m3 = $m2 + .5;
	$m4 = Compute('$10.00 + $2.59');

so that $m2 will be $30.00, $m3 will be $30.50, and $m4 will
be $12.59.  Students can perform computations within their
answers unless you disable the operators and functions as well.

The tolerance for this context is set initially to .005 and the
tolType to 'absolute' so that monetary values will have to match
to the nearest penny.  You can change that on a global basis
using

	Context()->flags->set(tolerance=>.0001,tolType=>"relative");

for example.  You can also change the tolerance on an individual
currency value as follows:

	$m = Compute('$1,250,000.00')->with(tolerance=>.0001,tolType=>'relative');

which would require students to be correct to three significant digits.

The default tolerance of .005 works properly only if your original
monetary values have no more than 2 decimal places.  If you were to do

	$m = Currency(34.125);

for example, then $m would print as $34.12, but neither a student
answer of $34.12 nor of $34.13 would be marked correct.  That is
because neither of these are less than .5 away from the correct answer
of $34.125.  If you create currency values that have more decimal
places than the usual two, you may want to round or truncate them.
Currency objects have two methods for accomplishing this: round() and
truncate(), which produce rounded or truncated copies of the original
Currency object:

	$m = Currency(34.127)->round;    # produces $34.13
	$m = Currency(34.127)->truncate; # produces $34.12

By default, the answer checker for Currency values requires
the student to enter the currency symbol, not just a real number.
You can relax that condition by including the promoteReals=>1
option to the cmp() method of the Currency value.  For example,

	ANS(Compute('$150')->cmp(promoteReals=>1));

would allow the student to enter just 150 rather than $150.

By default, the students may omit the commas, but you can
force them to supply the commas using forceCommas=>1 in
your cmp() call.

	ANS(Compute('$10,000.00')->cmp(forceCommas=>1));

By default, students need not enter decimal digits, so could use
$100 or $1,000. as valid entries.  You can require that the cents
be provided using the forceDecimals=>1 flag.

	ANS(Compute('$10.95')->cmp(forceDecimals=>1));

By default, if the monetary value includes decimals digits, it
must have exactly two.  You can weaken this requirement to allow
any number of decimals by using noExtraDecimals=>0.

	ANS(Compute('$10.23372')->cmp(noExtraDecimals=>0);

If forceDecimals is set to 1 at the same time, then they must
have 2 or more decimals, otherwise any number is OK.

By default, currency values are always formatted to display using
two decimal places, but you can request that if the decimals would be
.00 then they should not be displayed.  This is controlled via the
trimTrailingZeros context flag:

	Context()->flags->set(trimTrailingZeros=>1);

It can also be set on an individual currency value:

	$m = Compute('$50')->with(trimtrailingZeros=>1);

so that this $m will print as $50 rather than $50.00.

=cut

loadMacros("MathObjects.pl");
#loadMacros("problemPreserveAnswers.pl");  # obsolete

sub _contextCurrency_init {Currency::Init()}

package Currency;

#
#  Initialization creates a Currency context object
#  and sets up a Currency() constructor.
#
sub Init {
  my $context = $main::context{Currency} = new Currency::Context();
  $context->{name} = "Currency";

  main::PG_restricted_eval('sub Currency {Value->Package("Currency")->new(@_)}');
}

#
#  Quote characters that are special in regular expressions
#
sub quoteRE {
  my $s = shift;
  $s =~ s/([-\\^\$+*?.\[\](){}])/\\$1/g;
  return $s;
}

#
#  Quote common TeX special characters, and put
#  the result in {\rm ... } if there are alphabetic
#  characters included.
#
sub quoteTeX {
  my $s = shift;
  my $isText = ($s =~ m/[a-z]/i);
  $s =~ s/\\/\\backslash /g;
  $s =~ s/([\#\$%^_&{} ])/\\$1/g;
  $s =~ s/([~\'])/{\\tt\\char\`\\$1}/g;
  $s =~ s/,/{,}/g;
  $s = "{\\rm $s}" if $isText;
  return $s;
}

######################################################################
######################################################################
#
#  The Currency context has an extra "currency" data
#  type (like flags, variables, etc.)
#
#  It also creates some patterns needed for handling
#  currency values, and sets the Parser and Value
#  hashes to activate the Currency objects.
#
#  The tolerance is set to .005 absolute so that
#  answers must be correct to the penny.  You can
#  change this in the context, or for individual
#  currency values.
#
package Currency::Context;
our @ISA = ('Parser::Context');

sub new {
  my $self = shift; my $class = ref($self) || $self;
  my %data = (
    decimal => '.',
    comma => ',',
    symbol => "\$",
    associativity => "left",
    @_,
  );
  my $context = bless Parser::Context->getCopy("Numeric"), $class;
  $context->{_initialized} = 0;
  $context->{_currency} = new Currency::Context::currency($context,%data);
  my $symbol = $context->{currency}{symbol};
  my $associativity = $context->{currency}{associativity};
  my $string = ($symbol =~ m/[a-z]/i ? " $symbol " : $symbol);
  $context->{_currency}{symbol} = $symbol;
  $context->operators->remove($symbol) if $context->operators->get($symbol);
  $context->operators->add(
    $symbol => {precedence => 10, associativity => $associativity, type => "unary",
		string => ($main::displayMode eq 'TeX' ? Currency::quoteTeX($symbol) : $symbol),
                TeX => Currency::quoteTeX($symbol), class => 'Currency::UOP::currency'},
  );
  $context->{parser}{Number} = "Currency::Number";
  $context->{value}{Currency} = "Currency::Currency";
  $context->flags->set(
    tolerance => .005,
    tolType => "absolute",
    promoteReals => 1,
    forceCommas => 0,
    forceDecimals => 0,
    noExtraDecimals => 1,
    trimTrailingZeros => 0,
  );
  $context->{_initialized} = 1;
  $context->update;
  $context->{error}{msg}{"Missing operand after '%s'"} = "There should be a number after '%s'";
  return $context;
}

sub currency {(shift)->{_currency}}   # access to currency data


##################################################
#
#  This is the context data for currency.
#  A special pattern is maintained for the
#  comma form of numbers (using the specified
#  comma and decimal-place characters).
#
#  You specify the currency symbol via
#
#    Context()->currency->set(symbol=>'$');
#    Context()->currency->set(comma=>',',decimal=>'.');
#
#  You can add extra symbols via
#
#    Context()->currency->addSymbol("dollar","dollars");
#
#  If the symbol contains alphabetic characters, it
#  is made to be right-associative (i.e., comes after
#  the number), otherwise it is left-associative (i.e.,
#  before the number).  You can change that for a
#  symbol using
#
#    Context()->currency->setSymbol("Euro"=>{associativity=>"left"});
#
#  Finally, an extra symbol can be removed with
#
#    Context()->currency-removeSymbol("dollar");
#
package Currency::Context::currency;
our @ISA = ("Value::Context::Data");

#
#  Set up the initial data
#
sub init {
  my $self = shift;
  $self->{dataName} = 'currency';
  $self->{name} = 'currency';
  $self->{Name} = 'Currency';
  $self->{namePattern} = qr/[-\w_.]+/;
  $self->{numberPattern} = qr/\d{1,3}(?:,\d\d\d)+(?:\.\d*)?(?=\D|$)/;
  $self->{tokenType} = "num";
  $self->{precedence} = -12;
  $self->{patterns}{$self->{numberPattern}} = [$self->{precedence},$self->{tokenType}];
  $self->{extraSymbols} = [];
}

sub addToken {}       # no tokens are needed (only uses fixed pattern)
sub removeToken {}

#
#  Do the usual set() method, but make sure patterns are
#  updated, since the settings may affect the currency
#  pattern.
#
sub set {
  my $self = shift;
  $self->SUPER::set(@_);
  $self->update;
}

#
#  Create, set and remove extra currency symbols
#
sub addSymbol {
  my $self = shift; my $operators = $self->{context}->operators;
  my $def = $operators->get($self->{symbol});
  foreach my $symbol (@_) {
    my ($string,$associativity) = ($symbol =~ m/[a-z]/i ? (" $symbol ","right") : ($symbol,"left"));
    push @{$self->{extraSymbols}},$symbol;
    $operators->add(
      $symbol => {
        %{$def}, associativity => $associativity,
        string => ($main::displayMode eq 'TeX' ? Currency::quoteTeX($string) : $string),
	TeX => Currency::quoteTeX($string),
      }
    );
  }
}
sub setSymbol {(shift)->{context}->operators->set(@_)}
sub removeSymbol {(shift)->{context}->operators->remove(@_)}

#
#  Update the currency patterns in case the characters have changed,
#  and if the symbol has changed, remove the old operator(s) and
#  create a new one for the given symbol.
#
sub update {
  my $self = shift;
  my $context = $self->{context};
  my $pattern = $context->{pattern};
  my $operators = $context->operators;
  my $data = $context->{$self->{dataName}};
  my ($symbol,$comma,$decimal) = (Currency::quoteRE($data->{symbol}),
				  Currency::quoteRE($data->{comma}),
				  Currency::quoteRE($data->{decimal}));
  delete $self->{patterns}{$self->{numberPattern}};
  $self->{numberPattern} = qr/\d{1,3}(?:$comma\d\d\d)+(?:$decimal\d*)?(?=\D|$)|\d{1,3}$decimal\d*/;
  $self->{patterns}{$self->{numberPattern}} = [$self->{precedence},$self->{tokenType}];
  $pattern->{currencyChars}   = qr/(?:$symbol|$comma)/;
  $pattern->{currencyDecimal} = qr/$decimal/;
  if ($self->{symbol} && $self->{symbol} ne $data->{symbol}) {
    $operators->redefine($data->{symbol},from=>$context,using=>$self->{symbol});
    $operators->remove($self->{symbol});
    foreach $symbol (@{$self->{extraSymbols}}) {$operators->remove($symbol) if $operators->get($symbol)}
    $self->{extraSymbols} = [];
  }
  my $string = ($data->{symbol} =~ m/[^a-z]/i ? $data->{symbol} : " $data->{symbol} ");
  $context->operators->set($data->{symbol}=>{
    associativity => $data->{associativity},
    string => ($main::displayMode eq 'TeX' ? Currency::quoteTeX($string) : $string),
    TeX => Currency::quoteTeX($string),
  });
  $context->update;
}

######################################################################
######################################################################
#
#  When creating Number objects in the Parser, we need to remove the
#  comma (and currency) characters and replace the decimal character
#  with an actual decimal point.
#
package Currency::Number;
our @ISA = ('Parser::Number');

sub new {
  my $self = shift; my $equation = shift;
  my $context = $equation->{context};
  my $pattern = $context->{pattern};
  my $currency = $context->{currency};
  my $value = shift; my $value_string;
  if (ref($value) eq "") {
    $value_string = "$value";
    $value =~ s/$pattern->{currencyChars}//g;   # get rid of currency characters
    $value =~ s/$pattern->{currencyDecimal}/./; # convert decimal to .
  } elsif (Value::classMatch($value,"Currency")) {
    #
    #  Put it back into a Value object, but must unmark it
    #  as a Real temporarily to avoid an infinite loop.
    #
    $value->{isReal} = 0;
    $value = $self->Item("Value")->new($equation,[$value]);
    $value->{value}{isReal} = 1;
    return $value;
  }
  $self = $self->SUPER::new($equation,$value,@_);
  $self->{value_string} = $value_string if defined($value_string);
  return $self;
}

##################################################
#
#  This class implements the currency symbol.
#  It checks that its operand is a numeric constant
#  in the correct format, and produces
#  a Currency object when evaluated.
#
package Currency::UOP::currency;
our @ISA = ('Parser::UOP');

sub _check {
  my $self = shift;
  my $context = $self->context;
  my $decimal = $context->{pattern}{currencyDecimal};
  my $op = $self->{op}; my $value = $op->{value_string};
  $self->Error("'%s' can only be used with numeric constants",$self->{uop})
    unless $op->type eq 'Number' && $op->class eq 'Number';
  $self->{ref} = $op->{ref}; # highlight the number, not the operator
  $self->Error("You should have a '%s' every 3 digits",$context->{currency}{comma})
    if $context->flag("forceCommas") && $value =~ m/\d\d\d\d/;
  $self->Error("Monetary values must have exactly two decimal places")
   if $value && $value =~ m/$decimal\d/ && $value !~ m/$decimal\d\d$/ && $context->flag('noExtraDecimals');
  $self->Error("Monetary values require two decimal places",shift)
    if $context->flag("forceDecimals") && $value !~ m/$decimal\d\d$/;
  $self->{type} = {%{$op->typeRef}};
  $self->{isCurrency} = 1;
}

sub _eval {my $self = shift; Value->Package("Currency")->make($self->context,@_)}

#
#  Use the Currency MathObject to produce the output formats
#
sub string {(shift)->eval->string}
sub TeX    {(shift)->eval->TeX}
sub perl   {(shift)->eval->perl}


######################################################################
######################################################################
#
#  This is the MathObject class for currency objects.
#  It is basically a Real(), but one that stringifies
#  and texifies itself to include the currency symbol
#  and commas every three digits.
#
package Currency::Currency;
our @ISA = ('Value::Real');

#
#  We need to override the new() and make() methods
#  so that the Currency object will be counted as
#  a Value object.  If we aren't promoting Reals,
#  produce an error message.
#
sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $context = (Value::isContext($_[0]) ? shift : $self->context);
  my $x = shift;
  Value::Error("Can't convert %s to a monetary value",lc(Value::showClass($x)))
      if !$self->getFlag("promoteReals",1) && Value::isRealNumber($x) && !Value::classMatch($x,"Currency");
  $x = $x->value if Value::isReal($x);
  $self = bless $self->SUPER::new($context,$x,@_), $class;
  $self->{isReal} = $self->{isValue} = $self->{isCurrency} = 1;
  return $self;
}

sub make {
  my $self = shift; my $class = ref($self) || $self;
  $self = bless $self->SUPER::make(@_), $class;
  $self->{isReal} = $self->{isValue} = $self->{isCurrency} = 1;
  return $self;
}

sub round {
  my $self = shift;
  my $s = ($self->value >= 0 ? "" : "-");
  return $self->make(($s.main::prfmt(CORE::abs($self->value),"%.2f")) + 0);
}

sub truncate {
  my $self = shift;
  my $n = $self->value; $n =~ s/(\.\d\d).*/$1/;
  return $self->make($n+0);
}

#
#  Look up the currency symbols either from the object of the context
#  and format the output as a currency value (use 2 decimals and
#  insert commas every three digits).  Put the currency symbol
#  on the correct end for the associativity and remove leading
#  and trailing spaces.
#
sub format {
  my $self = shift; my $type = shift;
  my $currency = ($self->{currency} || $self->context->{currency});
  my ($symbol,$comma,$decimal) = ($currency->{symbol},$currency->{comma},$currency->{decimal});
  $symbol = $self->context->operators->get($symbol)->{$type} || $symbol;
  $comma = "{$comma}" if $type eq 'TeX';
  my $s = ($self->value >= 0 ? "" : "-");
  my $c = main::prfmt(CORE::abs($self->value),"%.2f");
  $c =~ s/\.00// if $self->getFlag('trimTrailingZeros');
  $c =~ s/\./$decimal/;
  while ($c =~ s/(\d)(\d\d\d(?:\D|$))/$1$comma$2/) {}
  $c = ($currency->{associativity} eq "right" ? $s.$c.$symbol : $s.$symbol.$c);
  $c =~ s/^\s+|\s+$//g;
  return $c;
}

sub string {(shift)->format("string")}
sub TeX    {(shift)->format("TeX")}



#
#  Override the class name to get better error messages
#
sub cmp_class {"a Monetary Value"}

#
#  Add promoteReals option to allow Reals with no dollars
#
sub cmp_defaults {(
  (shift)->SUPER::cmp_defaults,
  promoteReals => 0,
)}

sub typeMatch {
  my $self = shift; my $other = shift; my $ans = shift;
  return $self->SUPER::typeMatch($other,$ans,@_) if $self->getFlag("promoteReals");
  return Value::classMatch($other,'Currency');
}

######################################################################

1;
