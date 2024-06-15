package Complex;

use strict;

*i            = *Complex1::i;
@Complex::ISA = qw(Complex1);

1;
