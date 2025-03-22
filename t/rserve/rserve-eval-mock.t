#!/usr/bin/env perl

use strict;
use warnings;
use feature 'state';

use Test2::V0;
use Test::MockObject::Extends ();

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
use lib "$ENV{PG_ROOT}/lib";

use Rserve;

use lib "$ENV{PG_ROOT}/t/rserve/lib";

use ShortDoubleVector;
use TestCases qw(TEST_CASES);

sub mock_rserve_response {
	my $filename = shift;
	open(my $f, '<', $filename) or die $! . " $filename";
	binmode $f;
	my ($data, $rc) = '';
	while ($rc = read($f, $data, 8192, length $data)) { }
	close $f;
	die $! unless defined $rc;

	my $response = pack('VVA*', 0x10001, length($data), "\0" x 8) . $data;

	my $mock = Test::MockObject::Extends->new('IO::Socket');
	$mock->mock(print => sub { my ($self, $data) = @_; length($data); });
	$mock->mock(
		read => sub {
			my ($self, undef, $length, $offset) = @_;
			state $pos = 0;

			$_[1] .= substr($response, $pos, $length);
			$pos += $length;    # advance the cursor
			return $length;     # return the amount read
		}
	);
	$mock->set_always('peerhost', 'localhost');
	$mock->set_always('peerport', 6311);
	return $mock;
}

sub parse_rserve_eval {
	my ($file, $expected, $message) = @_;

	my $filename = $file . '.qap';

	subtest 'mock ' . $message => sub {
		my $mock   = mock_rserve_response($filename);
		my $rserve = Rserve->new(fh => $mock, _autoflush => 0);

		# Note: The order of comparisons is switched to ensure ShortDoubleVector's 'eq' overload is used.
		is($expected, $rserve->eval('testing, please ignore'), $message);

		is($mock->next_call, 'peerhost', 'get server name');
		is($mock->next_call, 'peerport', 'get server port');

		my ($request, $args) = $mock->next_call;

		is($request, 'print', 'send request');

		my ($command, $length, $offset, $length_hi) =
			unpack('V4', $args->[1]);
		is($command,     0x03,               'request CMD_eval');
		is($length + 16, length($args->[1]), 'request length');
		is($offset,      0,                  'request offset');
		is($length_hi,   0,                  'request hi-length');

		is($mock->next_call, 'read', 'read response status');
		is($mock->next_call, 'read', 'read response data');
		is($mock->next_call, undef,  'last call');
	};
	return;
}

# integer vectors
# serialize 1:3, XDR: true
parse_rserve_eval('t/rserve/data/noatt-123l', Rserve::REXP::Integer->new([ 1, 2, 3 ]), 'int vector no atts');

# serialize a=1L, b=2L, c=3L, XDR: true
parse_rserve_eval(
	't/rserve/data/abc-123l',
	Rserve::REXP::Integer->new(
		elements   => [ 1, 2, 3 ],
		attributes => {
			names => Rserve::REXP::Character->new([ 'a', 'b', 'c' ])
		}
	),
	'int vector names att'
);

# double vectors
# serialize 1234.56, XDR: true
parse_rserve_eval('t/rserve/data/noatt-123456', ShortDoubleVector->new([1234.56]), 'double vector no atts');

# serialize foo=1234.56, XDR: true
parse_rserve_eval(
	't/rserve/data/foo-123456',
	ShortDoubleVector->new(
		elements   => [1234.56],
		attributes => {
			names => Rserve::REXP::Character->new(['foo'])
		}
	),
	'double vector names att'
);

# character vectors
# serialize letters[1:3], XDR: true
parse_rserve_eval(
	't/rserve/data/noatt-abc',
	Rserve::REXP::Character->new([ 'a', 'b', 'c' ]),
	'character vector no atts'
);

# serialize A='a', B='b', C='c', XDR: true
parse_rserve_eval(
	't/rserve/data/ABC-abc',
	Rserve::REXP::Character->new(
		elements   => [ 'a', 'b', 'c' ],
		attributes => {
			names => Rserve::REXP::Character->new([ 'A', 'B', 'C' ])
		}
	),
	'character vector names att - xdr'
);

# raw vectors
# serialize as.raw(c(1:3, 255, 0), XDR: true
parse_rserve_eval('t/rserve/data/noatt-raw', Rserve::REXP::Raw->new([ 1, 2, 3, 255, 0 ]), 'raw vector');

# list (i.e., generic vector)
# serialize list(1:3, list('a', 'b', 11), 'foo'), XDR: true
parse_rserve_eval(
	't/rserve/data/noatt-list',
	Rserve::REXP::List->new([
		Rserve::REXP::Integer->new([ 1, 2, 3 ]),
		Rserve::REXP::List->new([ Rserve::REXP::Character->new(['a']), Rserve::REXP::Character->new(['b']),
			ShortDoubleVector->new([11]) ]),
		Rserve::REXP::Character->new(['foo'])
	]),
	'generic vector no atts'
);

# serialize list(foo=1:3, list('a', 'b', 11), bar='foo'), XDR: true
parse_rserve_eval(
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
	'generic vector names att - xdr'
);

# matrix

# serialize matrix(-1:4, 2, 3), XDR: true
parse_rserve_eval(
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
parse_rserve_eval(
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

# data frames
# serialize head(cars)
parse_rserve_eval(
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
parse_rserve_eval(
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
parse_rserve_eval(
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

# Call lm(mpg ~ wt, data = head(mtcars))
parse_rserve_eval(
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
parse_rserve_eval(
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
						'Mazda RX4',
						'Mazda RX4 Wag',
						'Datsun 710',
						'Hornet 4 Drive',
						'Hornet Sportabout',
						'Valiant'
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

# Server error
my $error_mock = Test::MockObject::Extends->new('IO::Socket::INET');
$error_mock->mock(print => sub { my ($self, $data) = @_; length($data); });
$error_mock->mock(
	read => sub {
		# args: self, $data, length
		$_[1] = pack('VVA*', 0x10002, 0, "\0" x 8);
		return 0;
	}
);
$error_mock->set_always('peerhost', 'localhost');
$error_mock->set_always('peerport', 6311);
my $rserve = Rserve->new(fh => $error_mock, _autoflush => 0);

like(dies { $rserve->eval('testing, please ignore') }, qr/R server returned an error: 0x10002/, 'server error');

while (my ($name, $value) = each %{ TEST_CASES() }) {
	parse_rserve_eval('t/rserve/data/' . $name, $value->{value}, $value->{desc});
}

done_testing;
