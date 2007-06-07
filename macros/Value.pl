###########################################################################
#
#  Declares functions needed for Value.pm
#

#
#  Constructors for the various types
#
sub String   {Value::String->new(@_)}
sub Real     {Value::Real->new(@_)}
sub Complex  {Value::Complex->new(@_)}
sub Point    {Value::Point->new(@_)}
sub Vector   {Value::Vector->new(@_)}
sub Matrix   {Value::Matrix->new(@_)}
sub List     {Value::List->new(@_)}
sub Interval {Value::Interval->new(@_)}
sub Set      {Value::Set->new(@_)}
sub Union    {Value::Union->new(@_)}

sub ColumnVector {Value::Vector->new(@_)->with(ColumnVector=>1,open=>undef,close=>undef)}

# sub Formula  {Value::Formula->new(@_)}  # in Parser.pl

#
#  Make a point or list a closed interval
#
sub Closed {
  my $x = shift;
  if (Value::isValue($x)) {$x->{open} = '['; $x->{close} = ']'}
  return $x;
}

###########################################################################
#
#  Make it possible to use  1+3*i  in perl rather than  1+3*$i or 1+3*i()
#
#sub i ()  {Value::Complex->i};   #  defined in Parser.pl
#sub pi () {Value::Complex->pi};  #  defined in dangerousMacros.pl

###########################################################################

sub _Value_init {};  # don't let loadMacros load it again

###########################################################################

1;
