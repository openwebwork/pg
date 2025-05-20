#!perl

use strict;
use warnings;
use feature 'state';

use Test2::V0 '!E', { E => 'EXISTS' };

use Socket     qw(inet_aton PF_INET SOCK_STREAM sockaddr_in);
use Mojo::File qw(path);

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
do "$ENV{PG_ROOT}/t/build_PG_envir.pl";

use lib "$ENV{PG_ROOT}/lib";

use Rserve;
use Rserve::REXP::Integer;

use lib "$ENV{PG_ROOT}/t/rserve/lib";

use ShortDoubleVector;
use TestCases qw(TEST_CASES);

# Fake configuration if this is disabled (it is by default in pg_config.dist.yml).
$main::Rserve = { host => 'localhost' } unless ref($main::Rserve) eq 'HASH' && $main::Rserve->{host};

my $s;
eval {
	socket($s, PF_INET, SOCK_STREAM, getprotobyname('tcp'))          || die "socket: $!";
	connect($s, sockaddr_in(6311, inet_aton($main::Rserve->{host}))) || die "connect: $!";
	$s->read(my $response, 32);
	$s->close;
	die "Unrecognized server ID" unless substr($response, 0, 12) eq 'Rsrv0103QAP1';
};

if ($@) {
	plan skip_all => "Cannot connect to Rserve server at $main::Rserve->{host}:6311";
}

loadMacros('RserveClient.pl');

sub check_rserve_eval {
	my ($rexp, $expected, $message) = @_;
	my @expected_value = (ref($expected) eq 'ARRAY' ? @{$expected} : $expected);

	subtest 'rserve eval ' . $message => sub {
		# Note: The order of comparisons is switched to ensure ShortDoubleVector's 'eq' overload is used.

		# test the one-time query
		my @result = rserve_query($rexp);
		is(\@expected_value, \@result, $message);

		# test the persistent connection
		@result = rserve_eval($rexp);
		is(\@expected_value, \@result, $message);
	};
	return;
}

# integer vectors
# serialize 1:3, XDR: true
check_rserve_eval('1:3', Rserve::REXP::Integer->new([ 1, 2, 3 ])->to_perl, 'int vector no atts');

# serialize a=1L, b=2L, c=3L, XDR: true
check_rserve_eval(
	'c(a=1L, b=2L, c=3L)',
	Rserve::REXP::Integer->new(
		elements   => [ 1, 2, 3 ],
		attributes => {
			names => Rserve::REXP::Character->new([ 'a', 'b', 'c' ])
		}
	)->to_perl,
	'int vector names att'
);

# double vectors
# serialize 1234.56, XDR: true
check_rserve_eval('1234.56', ShortDoubleVector->new([1234.56])->to_perl, 'double vector no atts');

# serialize foo=1234.56, XDR: true
check_rserve_eval(
	'c(foo=1234.56)',
	ShortDoubleVector->new(
		elements   => [1234.56],
		attributes => {
			names => Rserve::REXP::Character->new(['foo'])
		}
	)->to_perl,
	'double vector names att'
);

# character vectors
# serialize letters[1:3], XDR: true
check_rserve_eval('letters[1:3]', Rserve::REXP::Character->new([ 'a', 'b', 'c' ])->to_perl, 'character vector no atts');

# serialize A='a', B='b', C='c', XDR: true
check_rserve_eval(
	'c(A="a", B="b", C="c")',
	Rserve::REXP::Character->new(
		elements   => [ 'a', 'b', 'c' ],
		attributes => {
			names => Rserve::REXP::Character->new([ 'A', 'B', 'C' ])
		}
	)->to_perl,
	'character vector names att - xdr'
);

# raw vectors
# serialize as.raw(c(1:3, 255, 0), XDR: true
check_rserve_eval('as.raw(c(1,2,3,255, 0))', Rserve::REXP::Raw->new([ 1, 2, 3, 255, 0 ])->to_perl, 'raw vector');

# list (i.e., generic vector)
# serialize list(1:3, list('a', 'b', 11), 'foo'), XDR: true
check_rserve_eval(
	"list(1:3, list('a', 'b', 11), 'foo')",
	Rserve::REXP::List->new([
		Rserve::REXP::Integer->new([ 1, 2, 3 ]),
		Rserve::REXP::List->new([ Rserve::REXP::Character->new(['a']), Rserve::REXP::Character->new(['b']),
			ShortDoubleVector->new([11]) ]),
		Rserve::REXP::Character->new(['foo'])
	])->to_perl,
	'generic vector no atts'
);

# serialize list(foo=1:3, list('a', 'b', 11), bar='foo'), XDR: true
check_rserve_eval(
	"list(foo=1:3, list('a', 'b', 11), bar='foo')",
	Rserve::REXP::List->new(
		elements => [
			Rserve::REXP::Integer->new([ 1, 2, 3 ]),
			Rserve::REXP::List->new([
				Rserve::REXP::Character->new(['a']), Rserve::REXP::Character->new(['b']),
				ShortDoubleVector->new([11])
			]),
			Rserve::REXP::Character->new(['foo'])
		],
		attributes => {
			names => Rserve::REXP::Character->new([ 'foo', '', 'bar' ])
		}
	)->to_perl,
	'generic vector names att - xdr'
);

# matrix

# serialize matrix(-1:4, 2, 3), XDR: true
check_rserve_eval(
	'matrix(-1:4, 2, 3)',
	Rserve::REXP::Integer->new(
		elements   => [ -1, 0, 1, 2, 3, 4 ],
		attributes => {
			dim => Rserve::REXP::Integer->new([ 2, 3 ]),
		}
	)->to_perl,
	'int matrix no atts'
);

# serialize matrix(-1:4, 2, 3, dimnames=list(c('a', 'b'))), XDR: true
check_rserve_eval(
	"matrix(-1:4, 2, 3, dimnames=list(c('a', 'b')))",
	Rserve::REXP::Integer->new(
		elements   => [ -1, 0, 1, 2, 3, 4 ],
		attributes => {
			dim      => Rserve::REXP::Integer->new([ 2, 3 ]),
			dimnames =>
				Rserve::REXP::List->new([ Rserve::REXP::Character->new([ 'a', 'b' ]), Rserve::REXP::Null->new ]),
		}
	)->to_perl,
	'int matrix rownames'
);

# data frames
# serialize head(cars)
check_rserve_eval(
	'head(cars)',
	Rserve::REXP::List->new(
		elements =>
			[ ShortDoubleVector->new([ 4, 4, 7, 7, 8, 9 ]), ShortDoubleVector->new([ 2, 10, 4, 22, 16, 10 ]), ],
		attributes => {
			names       => Rserve::REXP::Character->new([ 'speed', 'dist' ]),
			class       => Rserve::REXP::Character->new(['data.frame']),
			'row.names' => Rserve::REXP::Integer->new([ 1, 2, 3, 4, 5, 6 ]),
		}
	)->to_perl,
	'the cars data frame'
);

# serialize head(mtcars)
check_rserve_eval(
	'head(mtcars)',
	Rserve::REXP::List->new(
		elements => [
			ShortDoubleVector->new([ 21.0,  21.0,  22.8,  21.4,  18.7,  18.1 ]),
			ShortDoubleVector->new([ 6,     6,     4,     6,     8,     6 ]),
			ShortDoubleVector->new([ 160,   160,   108,   258,   360,   225 ]),
			ShortDoubleVector->new([ 110,   110,   93,    110,   175,   105 ]),
			ShortDoubleVector->new([ 3.90,  3.90,  3.85,  3.08,  3.15,  2.76 ]),
			ShortDoubleVector->new([ 2.620, 2.875, 2.320, 3.215, 3.440, 3.460 ]),
			ShortDoubleVector->new([ 16.46, 17.02, 18.61, 19.44, 17.02, 20.22 ]),
			ShortDoubleVector->new([ 0,     0,     1,     1,     0,     1 ]),
			ShortDoubleVector->new([ 1,     1,     1,     0,     0,     0 ]),
			ShortDoubleVector->new([ 4,     4,     4,     3,     3,     3 ]),
			ShortDoubleVector->new([ 4,     4,     1,     1,     2,     1 ]),
		],
		attributes => {
			names => Rserve::REXP::Character->new([
				'mpg', 'cyl', 'disp', 'hp', 'drat', 'wt', 'qsec', 'vs', 'am', 'gear', 'carb' ]),
			class       => Rserve::REXP::Character->new(['data.frame']),
			'row.names' => Rserve::REXP::Character->new([
				'Mazda RX4', 'Mazda RX4 Wag', 'Datsun 710', 'Hornet 4 Drive', 'Hornet Sportabout', 'Valiant' ]),
		}
	)->to_perl,
	'the mtcars data frame'
);

# serialize head(iris)
check_rserve_eval(
	'head(iris)',
	Rserve::REXP::List->new(
		elements => [
			ShortDoubleVector->new([ 5.1, 4.9, 4.7, 4.6, 5.0, 5.4 ]),
			ShortDoubleVector->new([ 3.5, 3.0, 3.2, 3.1, 3.6, 3.9 ]),
			ShortDoubleVector->new([ 1.4, 1.4, 1.3, 1.5, 1.4, 1.7 ]),
			ShortDoubleVector->new([ 0.2, 0.2, 0.2, 0.2, 0.2, 0.4 ]),
			Rserve::REXP::Integer->new(
				elements   => [ 1, 1, 1, 1, 1, 1 ],
				attributes => {
					levels => Rserve::REXP::Character->new([ 'setosa', 'versicolor', 'virginica' ]),
					class  => Rserve::REXP::Character->new(['factor'])
				}
			),
		],
		attributes => {
			names => Rserve::REXP::Character->new([
				'Sepal.Length', 'Sepal.Width', 'Petal.Length', 'Petal.Width', 'Species' ]),
			class       => Rserve::REXP::Character->new(['data.frame']),
			'row.names' => Rserve::REXP::Integer->new([ 1, 2, 3, 4, 5, 6 ]),
		}
	)->to_perl,
	'the iris data frame'
);

# Call lm(mpg ~ wt, data = head(mtcars))
check_rserve_eval(
	'lm(mpg ~ wt, data = head(mtcars))$call',
	Rserve::REXP::Language->new(
		elements => [
			Rserve::REXP::Symbol->new('lm'),
			Rserve::REXP::Language->new(
				elements => [
					Rserve::REXP::Symbol->new('~'), Rserve::REXP::Symbol->new('mpg'),
					Rserve::REXP::Symbol->new('wt'),
				]
			),
			Rserve::REXP::Language->new(
				elements => [ Rserve::REXP::Symbol->new('head'), Rserve::REXP::Symbol->new('mtcars'), ]
			),
		],
		attributes => {
			names => Rserve::REXP::Character->new([ '', 'formula', 'data' ])
		}
	)->to_perl,
	'language lm(mpg~wt, head(mtcars))'
);

# serialize lm(mpg ~ wt, data = head(mtcars))
check_rserve_eval(
	'lm(mpg ~ wt, data = head(mtcars))',
	Rserve::REXP::List->new(
		elements => [
			# coefficients
			ShortDoubleVector->new(
				elements   => [ 30.3002034730204, -3.27948805566774 ],
				attributes => {
					names => Rserve::REXP::Character->new([ '(Intercept)', 'wt' ])
				}
			),
			# residuals
			ShortDoubleVector->new(
				elements => [
					-0.707944767170941, 0.128324687024322, 0.108208816128727, 1.64335062595135,
					-0.318764561523408, -0.853174800410051
				],
				attributes => {
					names => Rserve::REXP::Character->new([
						"Mazda RX4",
						"Mazda RX4 Wag",
						"Datsun 710",
						"Hornet 4 Drive",
						"Hornet Sportabout",
						"Valiant"
					])
				}
			),
			# effects
			ShortDoubleVector->new(
				elements => [
					-50.2145397270552,  -3.39713386075597, 0.13375416348722, 1.95527848390874,
					0.0651588996571721, -0.462851730054076
				],
				attributes => {
					names => Rserve::REXP::Character->new([ '(Intercept)', 'wt', '', '', '', '' ])
				}
			),
			# rank
			Rserve::REXP::Integer->new([2]),
			# fitted.values
			ShortDoubleVector->new(
				elements => [
					21.7079447671709, 20.8716753129757, 22.6917911838713, 19.7566493740486,
					19.0187645615234, 18.9531748004101
				],
				attributes => {
					names => Rserve::REXP::Character->new([
						"Mazda RX4",
						"Mazda RX4 Wag",
						"Datsun 710",
						"Hornet 4 Drive",
						"Hornet Sportabout",
						"Valiant"
					])
				}
			),
			# assign
			Rserve::REXP::Integer->new([ 0, 1 ]),
			# qr
			Rserve::REXP::List->new(
				elements => [
					# qr
					ShortDoubleVector->new(
						elements => [
							-2.44948974278318,  0.408248290463863,  0.408248290463863, 0.408248290463863,
							0.408248290463863,  0.408248290463863, -7.31989184801706,  1.03587322261623,
							0.542107126002057, -0.321898217952644, -0.539106265315558, -0.558413647303373
						],
						attributes => {
							dim      => Rserve::REXP::Integer->new([ 6, 2 ]),
							dimnames => Rserve::REXP::List->new([
								Rserve::REXP::Character->new([
									"Mazda RX4",
									"Mazda RX4 Wag",
									"Datsun 710",
									"Hornet 4 Drive",
									"Hornet Sportabout",
									"Valiant"
								]),
								Rserve::REXP::Character->new([ '(Intercept)', 'wt' ])
							]),
							assign => Rserve::REXP::Integer->new([ 0, 1 ]),
						}
					),
					# qraux
					ShortDoubleVector->new([ 1.40824829046386, 1.0063272758402 ]),
					# pivot
					Rserve::REXP::Integer->new([ 1, 2 ]),
					# tol
					ShortDoubleVector->new([1E-7]),
					# rank
					Rserve::REXP::Integer->new([2]),
				],
				attributes => {
					names => Rserve::REXP::Character->new([ "qr", "qraux", "pivot", "tol", "rank" ]),
					class => Rserve::REXP::Character->new(['qr'])
				}
			),
			# df.residual
			Rserve::REXP::Integer->new([4]),
			# xlevels
			Rserve::REXP::List->new(
				elements   => [],
				attributes => {
					names => Rserve::REXP::Character->new([])
				}
			),
			# call
			Rserve::REXP::Language->new(
				elements => [
					Rserve::REXP::Symbol->new('lm'),
					Rserve::REXP::Language->new(
						elements => [
							Rserve::REXP::Symbol->new('~'), Rserve::REXP::Symbol->new('mpg'),
							Rserve::REXP::Symbol->new('wt'),
						]
					),
					Rserve::REXP::Language->new(
						elements => [ Rserve::REXP::Symbol->new('head'), Rserve::REXP::Symbol->new('mtcars'), ]
					),
				],
				attributes => {
					names => Rserve::REXP::Character->new([ '', 'formula', 'data' ])
				}
			),
			# terms
			Rserve::REXP::Language->new(
				elements => [
					Rserve::REXP::Symbol->new('~'), Rserve::REXP::Symbol->new('mpg'),
					Rserve::REXP::Symbol->new('wt'),
				],
				attributes => {
					variables => Rserve::REXP::Language->new(
						elements => [
							Rserve::REXP::Symbol->new('list'), Rserve::REXP::Symbol->new('mpg'),
							Rserve::REXP::Symbol->new('wt'),
						]
					),
					factors => Rserve::REXP::Integer->new(
						elements   => [ 0, 1 ],
						attributes => {
							dim      => Rserve::REXP::Integer->new([ 2, 1 ]),
							dimnames => Rserve::REXP::List->new([
								Rserve::REXP::Character->new([ 'mpg', 'wt' ]),
								Rserve::REXP::Character->new(['wt']),
							]),
						}
					),
					'term.labels'  => Rserve::REXP::Character->new(['wt']),
					order          => Rserve::REXP::Integer->new([1]),
					intercept      => Rserve::REXP::Integer->new([1]),
					response       => Rserve::REXP::Integer->new([1]),
					class          => Rserve::REXP::Character->new([ 'terms', 'formula' ]),
					'.Environment' => Rserve::REXP::Unknown->new(sexptype => 4),
					predvars       => Rserve::REXP::Language->new(
						elements => [
							Rserve::REXP::Symbol->new('list'), Rserve::REXP::Symbol->new('mpg'),
							Rserve::REXP::Symbol->new('wt'),
						]
					),
					dataClasses => Rserve::REXP::Character->new(
						elements   => [ 'numeric', 'numeric' ],
						attributes => {
							names => Rserve::REXP::Character->new([ 'mpg', 'wt' ])
						}
					),
				}
			),
			# model
			Rserve::REXP::List->new(
				elements => [
					ShortDoubleVector->new([ 21.0, 21.0,  22.8, 21.4,  18.7, 18.1 ]),
					ShortDoubleVector->new([ 2.62, 2.875, 2.32, 3.215, 3.44, 3.46 ]),
				],
				attributes => {
					names       => Rserve::REXP::Character->new([ 'mpg', 'wt' ]),
					'row.names' => Rserve::REXP::Character->new([
						'Mazda RX4',
						'Mazda RX4 Wag',
						'Datsun 710',
						'Hornet 4 Drive',
						'Hornet Sportabout',
						'Valiant'
					]),
					class => Rserve::REXP::Character->new(['data.frame']),
					terms => Rserve::REXP::Language->new(
						elements => [
							Rserve::REXP::Symbol->new('~'), Rserve::REXP::Symbol->new('mpg'),
							Rserve::REXP::Symbol->new('wt'),
						],
						attributes => {
							variables => Rserve::REXP::Language->new(
								elements => [
									Rserve::REXP::Symbol->new('list'), Rserve::REXP::Symbol->new('mpg'),
									Rserve::REXP::Symbol->new('wt'),
								]
							),
							factors => Rserve::REXP::Integer->new(
								elements   => [ 0, 1 ],
								attributes => {
									dim      => Rserve::REXP::Integer->new([ 2, 1 ]),
									dimnames => Rserve::REXP::List->new([
										Rserve::REXP::Character->new([ 'mpg', 'wt' ]),
										Rserve::REXP::Character->new(['wt']),
									]),
								}
							),
							'term.labels'  => Rserve::REXP::Character->new(['wt']),
							order          => Rserve::REXP::Integer->new([1]),
							intercept      => Rserve::REXP::Integer->new([1]),
							response       => Rserve::REXP::Integer->new([1]),
							class          => Rserve::REXP::Character->new([ 'terms', 'formula' ]),
							'.Environment' => Rserve::REXP::Unknown->new(sexptype => 4),
							predvars       => Rserve::REXP::Language->new(
								elements => [
									Rserve::REXP::Symbol->new('list'), Rserve::REXP::Symbol->new('mpg'),
									Rserve::REXP::Symbol->new('wt'),
								]
							),
							dataClasses => Rserve::REXP::Character->new(
								elements   => [ 'numeric', 'numeric' ],
								attributes => {
									names => Rserve::REXP::Character->new([ 'mpg', 'wt' ])
								}
							),
						}
					),
				}
			),
		],
		attributes => {
			names => Rserve::REXP::Character->new([
				'coefficients', 'residuals',   'effects', 'rank', 'fitted.values', 'assign',
				'qr',           'df.residual', 'xlevels', 'call', 'terms',         'model',
			]),
			class => Rserve::REXP::Character->new(['lm'])
		}
	)->to_perl,
	'lm mpg~wt, head(mtcars)'
);

while (my ($name, $value) = each %{ TEST_CASES() }) {
	# If the expected value is wrapped in 'RexpOrUnknown', it will be XT_UNKNOWN over Rserve
	my $expected = $value->{value}->isa('RexpOrUnknown') ? undef : $value->{value}->to_perl;

	check_rserve_eval($value->{expr}, $expected, $value->{desc});
}

subtest 'R runtime errors' => sub {
	like(
		dies { rserve_eval('1+"a"') },
		qr/Error in 1 \+ "a" : non-numeric argument to binary operator/,
		'rserve_eval'
	);

	like(
		dies { rserve_query('1+"a"') },
		qr/Error in 1 \+ "a" : non-numeric argument to binary operator/,
		'rserve_query'
	);
};

subtest 'Rserve plot' => sub {
	my $remote = rserve_start_plot();
	rserve_eval('plot(1)');
	my $local = rserve_finish_plot($remote);
	ok(-e $local, 'plot file');
	my $png_contents = path($local)->slurp;
	ok($png_contents =~ qr/^.PNG\r\n.*IHDR\0\0\x01\xE0\0\0\x01\xE0/s, 'default figure dimensions (480x480)')
		or diag('True file type: ' . `file $local`);
	unlink $local;

	$remote = rserve_start_plot('png', 800, 732);
	rserve_eval('plot(1)');
	$local = rserve_finish_plot($remote);
	ok(-e $local, 'plot file');
	$png_contents = path($local)->slurp;
	ok($png_contents =~ qr/^.PNG\r\n.*IHDR\0\0\x03\x20\0\0\x02\xDC/s, 'custom figure dimensions')
		or diag('True file type: ' . `file $local`);
	unlink $local;

	$local = rserve_plot('plot(1)');
	ok(-e $local, 'plot file');
	$png_contents = path($local)->slurp;
	ok($png_contents =~ qr/^.PNG\r\n.*IHDR\0\0\x01\xE0\0\0\x01\xE0/s, 'default figure dimensions (480x480)')
		or diag('True file type: ' . `file $local`);
	unlink $local;

	$local = rserve_plot('plot(1)', 800, 732);
	ok(-e $local, 'plot file');
	$png_contents = path($local)->slurp;
	ok($png_contents =~ qr/^.PNG\r\n.*IHDR\0\0\x03\x20\0\0\x02\xDC/s, 'custom figure dimensions')
		or diag('True file type: ' . `file $local`);
	unlink $local;
};

subtest 'remote files' => sub {
	my $remote = (rserve_eval("file.path(system.file(package='base'), 'DESCRIPTION')"))[0];
	my $local  = rserve_get_file($remote);
	ok(-e $local, 'rserve get file');
	unlink $local;

	rserve_eval('coef(lm(log(dist) ~ log(speed), data = cars))');
	my $url = rserve_data_url('cars');
	$local =
		$url =~ s|$WeBWorK::PG::IO::pg_envir->{URLs}{tempURL}|$WeBWorK::PG::IO::pg_envir->{directories}{html_temp}|r;
	ok(-e $local, 'rserve data url file');
	unlink $local;
	is($url, $main::PG->{PG_alias}{resource_list}{$local}{uri}, 'alias for url in resource list');
};

subtest 'missing configuration' => sub {
	undef $main::Rserve;
	$main::PG->{WARNING_messages} = [];

	rserve_query('pi');

	is(
		$main::PG->{WARNING_messages},
		['Calling main::rserve_query is disabled unless Rserve host is configured in the PG environment.'],
		'missing configuration message'
	);
};

done_testing;
