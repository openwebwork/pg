

use PGtranslator;

# defines the modules to be used by PGtranslator

# This file is read in processProblem, in welcomeAction and in l2hPrecreateSet

PGtranslator -> evaluate_modules(qw( Exporter
                                     DynaLoader
                                     GD
                                     WWPlot
                                     Fun
                                     Circle
                                     Label
                                     PGrandom
                                     Units
                                     Hermite
								     List
								     Match
								     Select
								     Multiple
                                     AlgParser
                                     AnswerHash
                                     Fraction
                                     VectorField
                                     Complex1
                                     Complex
                                     MatrixReal1
                                     Matrix
                                     Distributions
				     Regression
                                      ) );

PGtranslator -> load_extra_packages(qw( AlgParserWithImplicitExpand
                                        Expr
                                        ExprWithImplicitExpand
                                        AnswerEvaluator
                                      ) );


1;
