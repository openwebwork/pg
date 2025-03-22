#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0 '!string';

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
use lib "$ENV{PG_ROOT}/lib";

use Rserve::Parser qw(:all);
use Rserve::ParserState;
use Rserve::QapEncoding qw(:all);

use lib "$ENV{PG_ROOT}/t/rserve/lib";

use ShortDoubleVector;
use TestCases qw(TEST_CASES);

sub check_qap {
	my ($file, $expected, $message) = @_;
	my $filename = $file . '.qap';

	open(my $f, '<', $filename) or die $! . " $filename";
	binmode $f;
	my ($data, $rc) = '';
	while ($rc = read($f, $data, 8192, length $data)) { }
	close $f;
	die $! unless defined $rc;

	subtest 'qap - ' . $message => sub {
		my ($actual, $state) = @{ decode($data) };
		# Note: The order of comparisons is switched to ensure ShortDoubleVector's 'eq' overload is used.
		is($expected, $actual, $message) or diag explain $actual;
		ok($state->eof, $message . ' - parse complete');
	};
	return;
}

sub check_padding {
	my ($data, $expected, $message) = @_;
	subtest 'padding - ' . $message => sub {
		my ($value, $state) = @{ decode($data) };

		is($value, $expected, $message) or diag explain $value;
		ok($state->eof, $message . ' - parse complete');

	};
	return;
}

subtest 'integer vectors' => sub {
	# serialize 1:3, XDR: true
	check_qap('t/rserve/data/noatt-123l', Rserve::REXP::Integer->new([ 1, 2, 3 ]), 'int vector no atts');

	# serialize a=1L, b=2L, c=3L, XDR: true
	check_qap(
		't/rserve/data/abc-123l',
		Rserve::REXP::Integer->new(
			elements   => [ 1, 2, 3 ],
			attributes => {
				names => Rserve::REXP::Character->new([ 'a', 'b', 'c' ])
			}
		),
		'int vector names att'
	);
};

subtest 'double vectors' => sub {
	# serialize 1:3, XDR: true
	check_qap('t/rserve/data/noatt-123456', ShortDoubleVector->new([1234.56]), 'double vector no atts');

	# serialize foo=1234.56, XDR: true
	check_qap(
		't/rserve/data/foo-123456',
		ShortDoubleVector->new(
			elements   => [1234.56],
			attributes => {
				names => Rserve::REXP::Character->new(['foo'])
			}
		),
		'double vector names att'
	);
};

subtest 'character vectors' => sub {
	# serialize letters[1:3], XDR: true
	check_qap(
		't/rserve/data/noatt-abc',
		Rserve::REXP::Character->new([ 'a', 'b', 'c' ]),
		'character vector no atts'
	);
	# serialize A='a', B='b', C='c', XDR: true
	check_qap(
		't/rserve/data/ABC-abc',
		Rserve::REXP::Character->new(
			elements   => [ 'a', 'b', 'c' ],
			attributes => {
				names => Rserve::REXP::Character->new([ 'A', 'B', 'C' ])
			}
		),
		'character vector names att'
	);

	check_padding(
		"\x0a\x0c\0\0\x22\x08\0\0\x61\0\x62\0\x63\0\1\1",
		Rserve::REXP::Character->new([ 'a', 'b', 'c' ]),
		'c("a", "b", "c")'
	);
};

subtest 'raw vectors' => sub {
	# serialize as.raw(c(1:3, 255, 0), XDR: true
	check_qap('t/rserve/data/noatt-raw', Rserve::REXP::Raw->new([ 1, 2, 3, 255, 0 ]), 'raw vector');

	check_padding("\x0a\x0c\0\0\x25\x08\0\0\1\0\0\0\x78\0\0\0", Rserve::REXP::Raw->new([120]), 'charToRaw("x")');

	check_padding(
		"\x0a\x0c\0\0\x25\x08\0\0\3\0\0\0\x66\x6f\x6f\0",
		Rserve::REXP::Raw->new([ 102, 111, 111 ]),
		'charToRaw("foo")'
	);

	check_padding(
		"\x0a\x0c\0\0\x25\x08\0\0\4\0\0\0\x66\x72\x65\x64",
		Rserve::REXP::Raw->new([ 102, 114, 101, 100 ]),
		'charToRaw("fred")'
	);
};

subtest 'logical vectors' => sub {
	check_qap('t/rserve/data/noatt-true', Rserve::REXP::Logical->new([1]), 'logical vector - singleton');

	check_qap('t/rserve/data/noatt-tfftf', Rserve::REXP::Logical->new([ 1, 0, 0, 1, 0 ]), 'logical vector');

	check_qap(
		't/rserve/data/ABCDE-tfftf',
		Rserve::REXP::Logical->new(
			elements   => [ 1, 0, 0, 1, 0 ],
			attributes => {
				names => Rserve::REXP::Character->new([ 'A', 'B', 'C', 'D', 'E' ])
			}
		),
		'logical vector names att'
	);

	check_padding("\x0a\x0c\0\0\x24\x08\0\0\1\0\0\0\1\xff\xff\xff", Rserve::REXP::Logical->new([1]), 'TRUE');

	check_padding(
		"\x0a\x0c\0\0\x24\x08\0\0\4\0\0\0\1\0\0\1",
		Rserve::REXP::Logical->new([ 1, 0, 0, 1 ]),
		'c(TRUE, FALSE, FALSE, TRUE)'
	);
};

subtest 'generic vector (list)' => sub {
	# serialize list(1:3, list('a', 'b', 11), 'foo'), XDR: true
	check_qap(
		't/rserve/data/noatt-list',
		Rserve::REXP::List->new([
			Rserve::REXP::Integer->new([ 1, 2, 3 ]),
			Rserve::REXP::List->new([
				Rserve::REXP::Character->new(['a']), Rserve::REXP::Character->new(['b']),
				ShortDoubleVector->new([11])
			]),
			Rserve::REXP::Character->new(['foo'])
		]),
		'generic vector no atts'
	);

	# serialize list(foo=1:3, list('a', 'b', 11), bar='foo'), XDR: true
	check_qap(
		't/rserve/data/foobar-list',
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
		),
		'generic vector names att'
	);
};

subtest 'symbol' => sub {
	check_padding("\x0a\x08\0\0\x13\4\0\0\x78\0\0\0", Rserve::REXP::Symbol->new('x'), 'as.name("x")');

	check_padding("\x0a\x08\0\0\x13\4\0\0\x66\x6f\x6f\0", Rserve::REXP::Symbol->new('foo'), 'as.name("foo")');

	check_padding(
		"\x0a\x0c\0\0\x13\x08\0\0\x66\x72\x65\x64\0\0\0\0",
		Rserve::REXP::Symbol->new('fred'),
		'as.name("fred")'
	);
};

subtest 'matrix' => sub {
	# serialize matrix(-1:4, 2, 3), XDR: true
	check_qap(
		't/rserve/data/noatt-mat',
		Rserve::REXP::Integer->new(
			elements   => [ -1, 0, 1, 2, 3, 4 ],
			attributes => {
				dim => Rserve::REXP::Integer->new([ 2, 3 ]),
			}
		),
		'int matrix no atts'
	);

	# serialize matrix(-1:4, 2, 3, dimnames=list(c('a', 'b'))), XDR: true
	check_qap(
		't/rserve/data/ab-mat',
		Rserve::REXP::Integer->new(
			elements   => [ -1, 0, 1, 2, 3, 4 ],
			attributes => {
				dim      => Rserve::REXP::Integer->new([ 2, 3 ]),
				dimnames =>
					Rserve::REXP::List->new([ Rserve::REXP::Character->new([ 'a', 'b' ]), Rserve::REXP::Null->new ]),
			}
		),
		'int matrix rownames'
	);
};

subtest 'data frames' => sub {
	# serialize head(cars)
	check_qap(
		't/rserve/data/cars',
		Rserve::REXP::List->new(
			elements =>
				[ ShortDoubleVector->new([ 4, 4, 7, 7, 8, 9 ]), ShortDoubleVector->new([ 2, 10, 4, 22, 16, 10 ]), ],
			attributes => {
				names       => Rserve::REXP::Character->new([ 'speed', 'dist' ]),
				class       => Rserve::REXP::Character->new(['data.frame']),
				'row.names' => Rserve::REXP::Integer->new([ 1, 2, 3, 4, 5, 6 ]),
			}
		),
		'the cars data frame'
	);

	# serialize head(mtcars)
	check_qap(
		't/rserve/data/mtcars',
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
		),
		'the mtcars data frame'
	);

	# serialize head(iris)
	check_qap(
		't/rserve/data/iris',
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
		),
		'the iris data frame'
	);
};

# Call lm(mpg ~ wt, data = head(mtcars))
check_qap(
	't/rserve/data/lang-lm-mpgwt',
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
	'language lm(mpg~wt, head(mtcars))'
);

# serialize lm(mpg ~ wt, data = head(mtcars))
check_qap(
	't/rserve/data/mtcars-lm-mpgwt',
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
	),
	'lm mpg~wt, head(mtcars)'
);

while (my ($name, $value) = each %{ TEST_CASES() }) {
	check_qap('t/rserve/data/' . $name, $value->{value}, $value->{desc});
}

done_testing;
