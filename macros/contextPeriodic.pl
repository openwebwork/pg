=head1 NAME

contextPeriodic.pl - [DEPRECATED] Features added to Real and Complex 
MathObjects classes.

=head1 DESCRIPTION

This file is no longer needed, as these features have been added to the
Real and Complex MathObject classes.

=head1 USAGE

    Context("Numeric");
    $a = Real("pi/2")->with(period=>pi);
    $a->cmp         # will match pi/2, 3pi/2 etc.

    Context("Complex");
    $z0 = Real("i^i")->with(period=>2pi, logPeriodic=>1);
    $z0->cmp        # will match exp(i*(ln(1) + Arg(pi/2) + 2k pi))

=cut

1;

