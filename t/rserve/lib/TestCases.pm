package TestCases;

use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK = qw(TEST_CASES);

use ShortDoubleVector;

use Rserve::Parser qw(:all);
use Rserve::ParserState;
use Rserve::REXP::Character;
use Rserve::REXP::Complex;
use Rserve::REXP::Double;
use Rserve::REXP::Integer;
use Rserve::REXP::List;
use Rserve::REXP::Logical;
use Rserve::REXP::Raw;
use Rserve::REXP::Language;
use Rserve::REXP::Expression;
use Rserve::REXP::Symbol;
use Rserve::REXP::Null;
use Rserve::REXP::Unknown;

use Math::Complex qw(cplx);

use constant nan => unpack 'd>', pack 'H*', '7ff8000000000000';
die 'Cannot create a known NaN value'
	unless (1 + nan eq nan) && (nan != nan);

use constant ninf => unpack 'd>', pack 'H*', 'fff0000000000000';
die 'Cannot create a known -Inf value'
	unless (1 + ninf eq ninf) && (ninf == ninf) && (ninf < 0);

use constant TEST_CASES => {
	'empty_char' => {
		desc  => 'empty char vector',
		expr  => 'character()',
		value => Rserve::REXP::Character->new
	},
	'empty_int' => {
		desc  => 'empty int vector',
		expr  => 'integer()',
		value => Rserve::REXP::Integer->new
	},
	'empty_num' => {
		desc  => 'empty double vector',
		expr  => 'numeric()',
		value => ShortDoubleVector->new
	},
	'empty_lgl' => {
		desc  => 'empty logical vector',
		expr  => 'logical()',
		value => Rserve::REXP::Logical->new
	},
	'empty_list' => {
		desc  => 'empty list',
		expr  => 'list()',
		value => Rserve::REXP::List->new
	},
	'empty_raw' => {
		desc  => 'empty raw vector',
		expr  => 'raw()',
		value => Rserve::REXP::Raw->new
	},
	'empty_sym' => {
		desc  => 'empty symbol',
		expr  => 'bquote()',
		value => Rserve::REXP::Symbol->new
	},
	'empty_expr' => {
		desc  => 'empty expr',
		expr  => 'expression()',
		value => Rserve::REXP::Expression->new
	},
	'null' => {
		desc  => 'null',
		expr  => 'NULL',
		value => Rserve::REXP::Null->new
	},
	'char_na' => {
		desc  => 'char vector with NAs',
		expr  => 'c("foo", "", NA, 23)',
		value => Rserve::REXP::Character->new([ 'foo', '', undef, '23' ])
	},
	'num_na' => {
		desc  => 'double vector with NAs',
		expr  => 'c(11.3, NaN, -Inf, NA, 0)',
		value => ShortDoubleVector->new([ 11.3, nan, ninf, undef, 0 ])
	},
	'int_na' => {
		desc  => 'int vector with NAs',
		expr  => 'c(11L, 0L, NA, 0L)',
		value => Rserve::REXP::Integer->new([ 11, 0, undef, 0 ])
	},
	'lgl_na' => {
		desc  => 'logical vector with NAs',
		expr  => 'c(TRUE, FALSE, TRUE, NA)',
		value => Rserve::REXP::Logical->new([ 1, 0, 1, undef ])
	},
	'list_na' => {
		desc  => 'list with NAs',
		expr  => 'list(1, 1L, list("b", list(letters[4:7], NA, c(44.1, NA)), list()))',
		value => Rserve::REXP::List->new([
			ShortDoubleVector->new([1]),
			Rserve::REXP::Integer->new([1]),
			Rserve::REXP::List->new([
				Rserve::REXP::Character->new(['b']),
				Rserve::REXP::List->new([
					Rserve::REXP::Character->new([ 'd', 'e', 'f', 'g' ]),
					Rserve::REXP::Logical->new([undef]),
					ShortDoubleVector->new([ 44.1, undef ])
				]),
				Rserve::REXP::List->new([])
			])
		])
	},
	'list_null' => {
		desc  => 'list with a single NULL',
		expr  => 'list(NULL)',
		value => Rserve::REXP::List->new([ Rserve::REXP::Null->new ])
	},
	'expr_null' => {
		desc  => 'expression(NULL)',
		expr  => 'expression(NULL)',
		value => Rserve::REXP::Expression->new([ Rserve::REXP::Null->new ])
	},
	'expr_int' => {
		desc  => 'expression(42L)',
		expr  => 'expression(42L)',
		value => Rserve::REXP::Expression->new([ Rserve::REXP::Integer->new([42]) ])
	},
	'expr_call' => {
		desc  => 'expression(1+2)',
		expr  => 'expression(1+2)',
		value => Rserve::REXP::Expression->new([
			Rserve::REXP::Language->new([
				Rserve::REXP::Symbol->new('+'), ShortDoubleVector->new([1]), ShortDoubleVector->new([2]) ])
		])
	},
	'expr_many' => {
		desc  => 'expression(u, v, 1+0:9)',
		expr  => 'expression(u, v, 1+0:9)',
		value => Rserve::REXP::Expression->new([
			Rserve::REXP::Symbol->new('u'),
			Rserve::REXP::Symbol->new('v'),
			Rserve::REXP::Language->new([
				Rserve::REXP::Symbol->new('+'),
				ShortDoubleVector->new([1]),
				Rserve::REXP::Language->new([
					Rserve::REXP::Symbol->new(':'), ShortDoubleVector->new([0]), ShortDoubleVector->new([9]) ])
			])
		])
	},
	'empty_cpx' => {
		desc  => 'empty complex vector',
		expr  => 'complex()',
		value => Rserve::REXP::Complex->new
	},
	'cpx_na' => {
		desc  => 'complex vector with NAs',
		expr  => 'c(1, NA_complex_, 3i, 0)',
		value => Rserve::REXP::Complex->new([ 1, undef, cplx(0, 3), 0 ])
	},
	'noatt-cpx' => {
		desc  => 'scalar complex vector',
		expr  => '3+2i',
		value => Rserve::REXP::Complex->new([ cplx(3, 2) ])
	},
	'foo-cpx' => {
		desc  => 'complex vector with a name attribute',
		expr  => 'c(foo=3+2i)',
		value => Rserve::REXP::Complex->new(
			elements   => [ cplx(3, 2) ],
			attributes => {
				names => Rserve::REXP::Character->new(['foo'])
			},
		)
	},
	'cpx-1i' => {
		desc  => 'imaginary-only complex vector',
		expr  => '1i',
		value => Rserve::REXP::Complex->new([ cplx(0, 1) ])
	},
	'cpx-0i' => {
		desc  => 'real-only empty complex vector',
		expr  => '5+0i',
		value => Rserve::REXP::Complex->new([ cplx(5) ])
	},
	'cpx-vector' => {
		desc  => 'simple complex vector',
		expr  => 'complex(real=1:3, imaginary=4:6)',
		value => Rserve::REXP::Complex->new([ cplx(1, 4), cplx(2, 5), cplx(3, 6) ])
	},
	'df_auto_rownames' => {
		desc  => 'automatic compact rownames',
		expr  => 'data.frame(a=1:3, b=c("x", "y", "z"), stringsAsFactors=FALSE)',
		value => Rserve::REXP::List->new(
			elements =>
				[ Rserve::REXP::Integer->new([ 1, 2, 3 ]), Rserve::REXP::Character->new([ 'x', 'y', 'z' ]), ],
			attributes => {
				names       => Rserve::REXP::Character->new([ 'a', 'b' ]),
				class       => Rserve::REXP::Character->new(['data.frame']),
				'row.names' => Rserve::REXP::Integer->new([ 1, 2, 3 ]),
			}
		)
	},
	'df_expl_rownames' => {
		desc  => 'explicit compact rownames',
		expr  => 'data.frame(a=1:3, b=c("x", "y", "z"), stringsAsFactors=FALSE)[1:3,]',
		value => Rserve::REXP::List->new(
			elements =>
				[ Rserve::REXP::Integer->new([ 1, 2, 3 ]), Rserve::REXP::Character->new([ 'x', 'y', 'z' ]), ],
			attributes => {
				names       => Rserve::REXP::Character->new([ 'a', 'b' ]),
				class       => Rserve::REXP::Character->new(['data.frame']),
				'row.names' => Rserve::REXP::Integer->new([ 1, 2, 3 ]),
			}
		)
	}
};

1;
