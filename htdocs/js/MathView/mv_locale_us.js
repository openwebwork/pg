// This file has the list of functions to be shown on the viewer, seperated into categories.
// The structure of an element is
//   text: latex string to render text on button
//   autocomp: whether the string should be included in the autocompletion feature
//   tooltip: the tooltip to print when hovering over button
//   latex: the latex code corresponding to the function
//   PG: the PGML code corresponding to the function

const mathView_translator = [
	'Basic',
	'Parenthesis',
	'Trigonometry',
	'Logarithms',
	'Intervals',
	'Others',
	'Version EN ',
	'Equation Editor',
	'Insert',
	'Cancel',
	'Inverse Trig',
	'Exponents',
	'Operations'
];

const mv_categories = [
	{
		text: mathView_translator[0], // 'Basic'
		operators: [
			{
				text: '\\(a + b\\)',
				autocomp: false,
				tooltip: 'addition',
				latex: '{}+{}',
				PG: '+'
			},
			{
				text: '\\(a-b\\)',
				autocomp: false,
				tooltip: 'subtraction',
				latex: '{}-{}',
				PG: '-'
			},
			{
				text: '\\(a\\cdot b\\)',
				autocomp: false,
				tooltip: 'multiplication',
				latex: '{}*{}',
				PG: '*'
			},
			{
				text: '\\(a/b\\)',
				autocomp: false,
				tooltip: 'division',
				latex: '{}/{}',
				PG: '/'
			},
			{
				text: '\\(\\frac{a}{b}\\)',
				autocomp: false,
				tooltip: 'fraction',
				latex: '\\frac{}{}',
				PG: '()/()'
			},
			{
				text: '\\(|a|\\)',
				autocomp: true,
				tooltip: 'absolute value',
				latex: '|{}|',
				PG: 'abs()'
			}
		]
	},
	{
		text: mathView_translator[11], // 'Exponents'
		operators: [
			{
				text: '\\(a^b\\)',
				autocomp: false,
				tooltip: 'exponentiation',
				latex: '{}^{}',
				PG: '^'
			},
			{
				text: '\\(\\sqrt{a}\\)',
				autocomp: true,
				tooltip: 'square root',
				latex: '\\sqrt{}',
				PG: 'sqrt()'
			},
			{
				text: '\\(\\sqrt[b]{a}\\)',
				autocomp: false,
				tooltip: 'bth root',
				latex: '\\sqrt[]{}',
				PG: '^(1/b)'
			},
			{
				text: '\\(e^{a}\\)',
				autocomp: false,
				tooltip: 'exponential',
				latex: 'e^{}',
				PG: 'e^()'
			}
		]
	},
	{
		text: mathView_translator[2], // 'Trigonometry'
		operators: [
			{
				text: '\\(\\sin(a)\\)',
				autocomp: true,
				tooltip: 'sine',
				latex: '\\sin{}',
				PG: 'sin()'
			},
			{
				text: '\\(\\cos(a)\\)',
				autocomp: true,
				tooltip: 'cosine',
				latex: '\\cos{}',
				PG: 'cos()'
			},
			{
				text: '\\(\\tan(a)\\)',
				autocomp: true,
				tooltip: 'tangent',
				latex: '\\tan{}',
				PG: 'tan()'
			},
			{
				text: '\\(\\csc(a)\\)',
				autocomp: true,
				tooltip: 'cosecant ',
				latex: '\\csc{}',
				PG: 'csc()'
			},
			{
				text: '\\(\\sec(a)\\)',
				autocomp: true,
				tooltip: 'secant',
				latex: '\\sec{}',
				PG: 'sec()'
			},
			{
				text: '\\(\\cot(a)\\)',
				autocomp: true,
				tooltip: 'cotangent',
				latex: '\\cot{}',
				PG: 'cot()'
			}
		]
	},
	{
		text: mathView_translator[10], // 'Inverse Trig'
		operators: [
			{
				text: '\\(\\sin^{-1}(a)\\)',
				autocomp: false,
				tooltip: 'inverse sin',
				latex: '\\sin^{-1}{}',
				PG: 'sin^(-1)()'
			},
			{
				text: '\\(\\cos^{-1}(a)\\)',
				autocomp: false,
				tooltip: 'inverse cos',
				latex: '\\cos^{-1}{}',
				PG: 'cos^(-1)()'
			},
			{
				text: '\\(\\tan^{-1}(a)\\)',
				autocomp: false,
				tooltip: 'inverse tan',
				latex: '\\tan^{-1}{}',
				PG: 'tan^(-1)()'
			},
			{
				text: '\\(\\cot^{-1}(a)\\)',
				autocomp: false,
				tooltip: 'inverse cot',
				latex: '\\cot^{-1}{}',
				PG: 'cot^{-1}()'
			},
			{
				text: '\\(\\sec^{-1}(a)\\)',
				autocomp: false,
				tooltip: 'inverse sec',
				latex: '\\sec^{-1}{}',
				PG: 'sec^(-1)()'
			},
			{
				text: '\\(\\csc^{-1}(a)\\)',
				autocomp: false,
				tooltip: 'inverse csc',
				latex: '\\csc^{-1}{}',
				PG: 'csc^(-1)()'
			}
		]
	},
	{
		text: mathView_translator[3], // 'Logarithm'
		operators: [
			{
				text: '\\(\\log(a)\\)',
				tooltip: 'logarithm base 10',
				autocomp: true,
				latex: '\\log{}',
				PG: 'log()'
			},
			{
				text: '\\(\\log_b(a)\\)',
				tooltip: 'logarithm base b',
				latex: '\\log_{}{}',
				PG: 'log()/log()'
			},
			{
				text: '\\(\\ln(a)\\)',
				autocomp: true,
				tooltip: 'natural logarithm',
				latex: '\\ln{}',
				PG: 'ln()'
			},
			{
				text: '\\(\\exp(a)\\)',
				autocomp: true,
				tooltip: 'exponential',
				latex: '\\exp{}',
				PG: 'exp()'
			}
		]
	},
	{
		text: mathView_translator[4], // 'Intervals'
		operators: [
			{
				text: '\\([a,b]\\)',
				tooltip: 'closed interval',
				latex: '\\left[{},{} \\right]',
				PG: '[,]'
			},
			{
				text: '\\((a,b]\\)',
				tooltip: 'half open interval',
				latex: '\\left({},{} \\right]',
				PG: '(,]'
			},
			{
				text: '\\([a,b)\\)',
				tooltip: 'half open interval',
				latex: '\\left[{},{} \\right[',
				PG: '[,)'
			},
			{
				text: '\\((a,b)\\)',
				tooltip: 'open interval',
				latex: '\\left]{},{} \\right[',
				PG: '(,)'
			},
			{
				text: '\\(A\\cup B\\)',
				tooltip: 'union',
				latex: '\\cup',
				PG: 'U'
			}
		]
	},
	{
		text: mathView_translator[5], // 'Other'
		operators: [
			{
				text: '\\(\\infty\\)',
				autocomp: true,
				tooltip: 'infinity',
				latex: '\\infty',
				PG: 'Inf'
			},

			{
				text: '\\(\\pi\\)',
				tooltip: 'Pi',
				latex: '\\pi',
				PG: 'pi'
			},
			{
				text: '\\(e\\)',
				tooltip: 'natural number',
				latex: 'e',
				PG: 'e'
			},
			{
				text: '\\((a)\\)',
				tooltip: 'parentheses',
				latex: '()',
				PG: '()'
			},
			{
				text: '\\([a]\\)',
				tooltip: 'square brackets',
				latex: '[]',
				PG: '[]'
			},
			{
				text: '\\(\\{a\\}\\)',
				tooltip: 'curly brackets',
				latex: '\\left \\{  \\right \\}',
				PG: '{}'
			}
		]
	}
];
