BEGIN {
	be_strict(); # an alias for use strict.  This means that all global variable must contain main:: as a prefix.
    
}

package Complex;
*i = *Complex1::i;
@Complex::ISA=qw(Complex1);


1;