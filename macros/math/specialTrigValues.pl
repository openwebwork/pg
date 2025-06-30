
=head1 NAME

specialTrigValues.pl - Subroutines for converting numbers that arise in a trigonometry setting into
"nice" expressions like pi/4 and sqrt(3)/2

=head1 DESCRIPTION

C<specialRadical(x)> returns a MathObject Formula in Complex context of the
form "a sqrt(b)/c" that is the closest possible to x, where a is an integer,
and b and c are from specified sets of positive integers. By default, both b
and c come from [1,2,3]. If c is 1, it will be omitted from the expression.
If b is 1, the "sqrt(1)" will be omitted. If a is 1, it will be omitted unless
the whole thing is 1. If a is -1, the "1" will be omitted unless the whole
thing is -1. If x is non-real, this process is applied to the Real and
Imaginary parts separately.

C<specialAngle(x)> returns a MathObject Formula in Numeric context of the form
"a pi/c" that is the closest possible to x, where a is an integer, and c is from
a specified set of positive integers. By default, c comes from [1,2,3,4,6]. If
a equals 0, then this returns Formula('0').

=head2 Options

Both C<specialRadical(x)> and C<specialAngle(x)> can take an optional argument
C<denominators =E<gt> [list of positive integers]>. These will be the
denominators under consideration for finding a closest expression.

C<specialRadical(x)> can take an optional argument C<radicands =E<gt> [list of positive integers]>.
These will be the radicands under consideration for finding a closest
expression.

=cut

sub _specialTrigValues_init { }

loadMacros("MathObjects.pl");

sub specialRadical {
	my ($x, %options) = @_;
	my $radics    = $options{radicands}    ? $options{radicands}    : [ 1, 2, 3 ];
	my $denoms    = $options{denominators} ? $options{denominators} : [ 1, 2, 3 ];
	my $mycontext = Context();
	Context('Complex')->flags->set(reduceConstants => 0, reduceConstantFunctions => 0);
	my $num  = Complex($x);
	my @nums = ($num->Re, $num->Im);
	my @closest;
	my @divc;
	my @sqrtb;
	my @i;
	my @a;

	for my $y (0, 1) {
		$closest[$y] = [ round($nums[$y] / sqrt($radics->[0]) * $denoms->[0]), $radics->[0], $denoms->[0] ];
		for my $b (@$radics) {
			for my $c (@$denoms) {
				$closest[$y] = [ round($nums[$y] / sqrt($b) * $c), $b, $c ]
					if (
						abs($nums[$y] - round($nums[$y] / sqrt($b) * $c) * sqrt($b) / $c) <
						abs($nums[$y] - $closest[$y][0] * sqrt($closest[$y][1]) / $closest[$y][2]));
			}
		}
		$divc[$y]  = $closest[$y][2] == 1 ? '' : "/$closest[$y][2]";
		$sqrtb[$y] = $closest[$y][1] == 1 ? '' : "sqrt($closest[$y][1])";
		$i[$y]     = ($y == 0)            ? '' : 'i';
		$a[$y]     = '';
		if (!$i[$y] && !$sqrtb[$y] || abs($closest[$y][0]) != 1) {
			$a[$y] = $closest[$y][0];
		} elsif ($closest[$y][0] == 1) {
			$a[$y] = '';
		} elsif ($closest[$y][0] == -1) {
			$a[$y] = '-';
		}
	}
	my $return;
	if ($a[1] eq '-') {
		$return = Formula("$a[0] $sqrtb[0] $divc[0] - i $sqrtb[1] $divc[1]");
	} elsif ($a[1] eq '' || $a[1] > 0) {
		$return = Formula("$a[0] $sqrtb[0] $divc[0] + $a[1] i $sqrtb[1] $divc[1]");
	} else {
		$return = Formula("$a[0] $sqrtb[0] $divc[0] - " . -$a[1] . " i $sqrtb[1] $divc[1]") if ($a[1] < 0);
	}
	$return = Formula("$a[1] i $sqrtb[1] $divc[1]") if ($nums[0] == 0);
	$return = Formula("$a[0] $sqrtb[0] $divc[0]")   if ($nums[1] == 0);
	Context($mycontext);
	return $return;
}

sub specialAngle {
	my ($x, %options) = @_;
	my $denoms    = $options{denominators} ? $options{denominators} : [ 1, 2, 3, 4, 6 ];
	my $mycontext = Context();
	Context('Numeric')->flags->set(reduceConstants => 0, reduceConstantFunctions => 0);
	my $num     = Real($x);
	my $y       = $num / pi;
	my $closest = [ round($y * $denoms->[0]), $denoms->[0] ];

	for my $c (@$denoms) {
		$closest = [ round($y * $c), $c ] if (abs($y - round($y * $c) / $c) < abs($y - $closest->[0] / $closest->[1]));
	}
	my $divc = $closest->[1] == 1 ? '' : "/$closest->[1]";
	my $a    = '';
	if ($closest->[0] == 1) {
		$a = '';
	} elsif ($closest->[0] == -1) {
		$a = '-';
	} else {
		$a = $closest->[0];
	}
	my $return = ($a ne '0') ? Formula("$a pi $divc") : Formula('0');
	Context($mycontext);
	return $return;
}

