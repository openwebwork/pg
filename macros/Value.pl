###########################################################################
#
#  Declares functions needed for Value.pm
#

#
#  Constructors for the various types
#
sub Complex  {Value::Complex->new(@_)}
sub Point    {Value::Point->new(@_)}
sub Vector   {Value::Vector->new(@_)}
sub Matrix   {Value::Matrix->new(@_)}
sub List     {Value::List->new(@_)}
sub Interval {Value::Interval->new(@_)}
sub Union    {Value::Union->new(@_)}

# sub Formula  {Value::Formula->new(@_)}
# 
# #
# #  Parse a formula and evaluate it
# #
# sub Compute {
#   my $formula = Formula(shift);
#   return $formula->eval(@_);
# }  

###########################################################################
#
#  Make it possible to use  1+3*i  in perl rather than  1+3*$i or 1+3*i()
#
#sub i ()  {Value::Complex->i};   #  defined in Parser.pl
#sub pi () {Value::Complex->pi};  #  defined in dangerousMacros.pl

###########################################################################

1;
