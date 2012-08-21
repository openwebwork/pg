########################################################################### 
#
#  Implements the Formula class.
#
package Value::Essay;
my $pkg = 'Value::Essay';

use strict; no strict "refs";
our @ISA = qw(Parser Value);



sub box {
	loadMacros('PGbasicmacros.pl');   
	essay_box();
}


sub cmp {
    loadMacros('PGbasicmacros.pl');
    essay_cmp();
}
    
