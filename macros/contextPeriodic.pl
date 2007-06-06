######################################################################
#
#   This file is no longer needed, as these features have been added to the
#   Real and Complex MathObject classes.
#
#	Usage:
#		Context("Numeric");
#		$a = Real("pi/2")->with(period=>pi);
#		$a->cmp         # will match pi/2, 3pi/2 etc.
#
#	Usage:
#		Context("Complex");
#		$z0 = Real("i^i")->with(period=>2pi, logPeriodic=>1);
#		$z0->cmp        # will match exp(i*(ln(1) + Arg(pi/2) + 2k pi))
#
######################################################################
