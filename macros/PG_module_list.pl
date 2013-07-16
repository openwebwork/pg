

use PGtranslator;

=head1 DESCRIPTION

# defines the modules to be used by PGtranslator

# This file is read in processProblem, in welcomeAction and in l2hPrecreateSet

=cut

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
				     Statistics
				     Regression
                                      ) );

PGtranslator -> load_extra_packages(qw( AlgParserWithImplicitExpand
                                        Expr
                                        ExprWithImplicitExpand
                                        AnswerEvaluator
                                      ) );


1;
