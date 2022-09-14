# Structure of the macros directory

This directory now has a subdirectory structure for clarification.

- **answers** answer and evaluator macros
- **capa** any CAPA related macros
- **contexts** context related macros
- **core** macros related to core PG functionality
- **graph** graphing/graphical related macros.
- **math** mathematical related macros
- **parsers** macros that handle parsing
- **ui** macros that affect the UI in the PG problem
- **univ** university or other specific functionality related macros.

## These Have Been Copied

- `OPL/Alfred/Alfredmacros.pl` to `PG/macros/univ`
- `OPL/BrockPhysics/BrockPhysicsMacros.pl` to `PG/macros/univ` (referenced throughout OPL, but blank, should be deleted.)
- `OPL/BrockPhysics/fixedPrecision.pl` to `PG/macros/contexts` (not sure how this is used in problems).
- `OPL/Hope/PGgraphgrid.pl` to `PG/macros/graph`
- `OPL/Hope/VectorListCheckers.pl` to `PG/macros/math`
- `OPL/LaTech/SI_property_tables.pl` to `PG/macros/math`
- `OPL/LaTech/interpMacros.pl` to `PG/macros/math`
- `OPL/Mizzou/MUHelp.pl` to `PG/macros/univ`
- `OPL/TCNJ/Generic.pl` to `PG/macros/answers`
- `OPL/UBC/regrfnsPG.pl` to `PG/macros/math`
- `OPL/UMass-Amherst/algebraMacros.pl` to `PG/macros/math`
- `OPL/WHFreeman/freemanMacros.pl` to `PG/macros/univ`
- `OPL/Michigan/hhAdditionalMacros.pl` to `PG/macros/univ`

### CollegeOfIdaho

- `OPL/CofIdaho_macros.pl` to `PG/macros/univ`
- `OPL/CollegeOfIdaho/contextInequalitiesAllowStrings.pl` to `PG/macros/contexts`
- `OPL/CollegeOfIdaho/contextFunctionAssign.pl` to `PG/macros/contexts`
- `OPL/CollegeOfIdaho/parserUtils.pl` to `PG/macros/parsers`
- `OPL/CollegeOfIdaho/unorderedAnswer.pl` to `PG/macros/answers`

### FortLewis

- `OPL/FortLewis/AnswerFormatHelp.pl` to `PG/macros/answers`
- `OPL/FortLewis/ConditionalHint.pl` to `PG/macros/answers`
- `OPL/FortLewis/LiveGraphicsCylindricalPlot3D.pl` to `PG/macros/graph`
- `OPL/FortLewis/LiveGraphicsParametricCurve3D.pl` to `PG/macros/graph`
- `OPL/FortLewis/LiveGraphicsParametricSurface3D.pl` to `PG/macros/graph`
- `OPL/FortLewis/LiveGraphicsVectorField2D.pl` to `PG/macros/graph`
- `OPL/FortLewis/LiveGraphicsVectorField3D.pl` to `PG/macros/graph`
- `OPL/FortLewis/MatrixUnimodular.pl` to `PG/macros/math`
- `OPL/FortLewis/PeriodicRandomization.pl` to `PG/macros/core`

### NAU

- `OPL/NAU/PGnauBinpacking.pl` to `PG/macros/math`
- `OPL/NAU/PGnauGraphtheory.pl` to `PG/macros/math`
- `OPL/NAU/PGnauGraphCatalog.pl` to `PG/macros/math`
- `OPL/NAU/PGnauScheduling.pl` to `PG/macros/math`
- `OPL/NAU/PGnauSet.pl` to `PG/macros/math`
- `OPL/NAU/PGnauStats.pl` to `PG/macros/math`
- `OPL/NAU/PGnauGraphics.pl` to `PG/macros/graph`

### Union

- `OPL/Union/answerUtils.pl` to `PG/macros/answers`
- `OPL/Union/PGunion.pl` to `PG/macros/univ`
- `OPL/Union/unionImage.pl` to `PG/macros/univ`
- `OPL/Union/unionInclude.pl` to `PG/macros/univ`
- `OPL/Union/unionMacros.pl` to `PG/macros/univ`
- `OPL/Union/unionLists.pl` to `PG/macros/ui`
- `OPL/Union/unionProblem.pl` to `PG/macros/univ`
- `OPL/Union/unionTable.pl` to `PG/macros/ui`
- `OPL/Union/unionUtils.pl` to `PG/macros/univ`
- `OPL/Union/imageChoice.pl` to `PG/macros/graph`
- `OPL/FortLewis/AnswerHelp.pl` to `PG/macros/answers`

### PCC

- `OPL/PCC/contextFiniteSolutionSets.pl` to `PG/macros/contexts`
- `OPL/PCC/contextForm.pl` to `PG/macros/contexts`
- `OPL/PCC/contextLimitedRadicalComplex.pl` to `PG/macros/contexts`
- `OPL/PCC/contextRationalExponent.pl` to `PG/macros/contexts`
- `OPL/PCC/contextRestrictedDomains.pl` to `PG/macros/contexts`
- `OPL/PCC/PCCfactor.pl` to `PG/macros/math`
- `OPL/PCC/PCCgraphMacros.pl` to `PG/macros/graph`
- `OPL/PCC/PCCmacros.pl` to `PG/macros/univ`
- `OPL/PCC/pccTables.pl` to `PG/macros/ui`
- `OPL/PCC/SolveLinearEquationPCC.pl` to `PG/macros/math`
- `OPL/PCC/SystemsOfLinearEquationsProblemPCC.pl` to `PG/macros/math`

## Not moved

- `OPL/Hope/MatrixCheckers.pl` (already in PG/math)
- `OPL/Hope/MatrixReduce.pl` (already in PG/math)
- `OPL/Hope/MatrixUnits.pl` (already in PG/math)
- `OPL/MC/draggableProof.pl` (already in PG/math)
- `OPL/UBC/RserveClient.pl` (already in PG/core)
- `OPL/UW-Stout/*.pl` (no problems in OPL/Contrib)
- `OPL/UniSiegen/logicMacros.pl` (no problems in OPL/Contrib)
u

### CollegeOfIdaho

- `OPL/CollegeOfIdaho/allPlotMacros.pl` (no problems in OPL/Contrib)
- `OPL/CollegeOfIdaho/answerUtils.pl` (used newer Union version instead)
- `OPL/CollegeOfIdaho/choiceUtils.pl` (used Union version instead)
- `OPL/CollegeOfIdaho/compositionAnswer.pl` (not used in OPL/Contrib)
- `OPL/CollegeOfIdaho/compoundProblem.pl` (already version in PG/core)
- `OPL/CollegeOfIdaho/courseHeaders.pl` (not used in OPL/Contrib)
- `OPL/CollegeOfIdaho/Differentiation.pl` (not used in OPL/Contrib)
- `OPL/CollegeOfIdaho/DifferentiationDefs.pl` (not used in OPL/Contrib)
- `OPL/CollegeOfIdaho/diffquotientAnswer.pl` (not used in OPL/Contrib)
- `OPL/CollegeOfIdaho/ev3p.pl` (not used in OPL/Contrib)
- `OPL/CollegeOfIdaho/imageChoice.pl` (used Union version -- identical)
- `OPL/CollegeOfIdaho/infiniteAnswer.pl` (not used in OPL/Contrib)
- `OPL/CollegeOfIdaho/integerAnswer.pl` (not used in OPL/Contrib)
- `OPL/CollegeOfIdaho/intervalAnswer.pl` (not used in OPL/Contrib)
- `OPL/CollegeOfIdaho/lineAnswer.pl` (not used in OPL/Contrib)
- `OPL/CollegeOfIdaho/listAnswer.pl` (not used in OPL/Contrib)
- `OPL/CollegeOfIdaho/parallelAnswer.pl` (not used in OPL/Contrib)
- `OPL/CollegeOfIdaho/parserImplicitEquation.pl` (already in PG/parsers)
- `OPL/CollegeOfIdaho/parserTables.pl` (not used in OPL/Contrib)
- `OPL/CollegeOfIdaho/PGstandard.pl` (already in PG/core)
- `OPL/CollegeOfIdaho/PGunion.pl` (use union version)
- `OPL/CollegeOfIdaho/piecewiseFunctions.pl` (not used in OPL/Contrib)
- `OPL/CollegeOfIdaho/planeAnswer.pl` (not used in OPL/Contrib)
- `OPL/CollegeOfIdaho/pointAnswer.pl` (not used in OPL/Contrib)
- `OPL/CollegeOfIdaho/unionAnswer.pl` (not used in OPL/Contrib)
- `OPL/CollegeOfIdaho/variableAnswer.pl` (not used in OPL/Contrib)
- `OPL/CollegeOfIdaho/vectorAnswer.pl` (not used in OPL/Contrib)
- `OPL/CollegeOfIdaho/vectorUtils.pl` (not used in OPL/Contrib)
- `OPL/CollegeOfIdaho/weightedGrader.pl` (already in PG/core/weightedGrader)

### FortLewis

- `OPL/FortLewis/JavaView.pl` (not in OPL/Contrib)
- `OPL/FortLewis/JavaViewRectangularPlot3D.pl` (not in OPL/Contrib)

### PCC

- `OPL/PCC/contextAssignmentForm.pl` (no problems in OPL/Contrib)
- `OPL/PCC/contextInequalitySetBuilder.pl` (newer copy in `PG/macros/contexts`)
- `OPL/PCC/contextLimitedFactor.pl` (newer copy in `PG/macros/contexts`)
- `OPL/PCC/contextLimitedRadical.pl` (newer copy in `PG/macros/contexts`)
- `OPL/PCC/contextPercent.pl` (newer copy in `PG/macros/contexts`)
- `OPL/PCC/parserRoot.pl` (newer copy in `PG/macros/parsers`)

### Union

- `OPL/Union/answerUtils.pl` (not used in OPL/Contrib)
- `OPL/Union/courseHeaders.pl` (not used in OPL/Contrib)
- `OPL/Union/piecewiseFunctions.pl` (not used in OPL/Contrib)
- `OPL/Union/unorderedAnswer.pl` (used CollegeOfIdaho version, newer)

## problems to check

- `Library/UVA-Stew5e/setUVA-Stew5e-C03S01-DerivPolyExps/3-1-37_mo.pg`
- `Library/UCSB/Stewart5_3_7/Stewart5_3_7_39.pg`
- `Library/MC/PreAlgebra/setPreAlgebraC03S03/MeanMedianMode01.pg`
- `Contrib/AlfredUniv/anton8e/chapter10/10.5/prob9.pg`
- `Contrib/BrockPhysics/College_Physics_Urone/15.Thermodynamics/Carnots_Perfect_Heat_Engine_The_Second_Law_of_Thermodynamics_Restated/NU_U17-15-04-007.pg`
- `Library/CollegeOfIdaho/setAlgebra_04_03_AbsoluteValue/43IntAlg_33_AbsValGraph.pg` (error)
- `Library/CollegeOfIdaho/setAlgebra_04_03_AbsoluteValue/43IntAlg_34_AbsValGraph.pg` (error)
- `Library/FortLewis/Authoring/Templates/DiffCalcMV/Graph3DCylindrical1/Graph3DCylindrical1.pg` (nothing is viewed)
- `Library/FortLewis/Calc3/18-2-Line-integrals-parametrized/HGM5-18-2-19-Line-integrals-parametrized/HGM5-18-2-19-Line-integrals-parametrized.pg` (missing png file)
- `Library/LaTech/opes_Thermodynamics/J/J-01-Brayton01.pg` (gives a warning)
- `Contrib/Mizzou/Algebra/eqns_abs_value/abs_val_eqn_10.pg` (missing fracListChecker.pl macro)
- `Library/UMass-Amherst/Abstract-Algebra/PS-Permutations/Permutations2.pg` (warnings due to alegebraMacros.pl)
- `Contrib/PCC/BasicAlgebra/Factoring/factoring220.pg` (warnings about PCCfactor.pl)
- `Contrib/PCC/BasicAlgebra/SolveLinearEquations/LiteralEquation60.pg` (warnings about SolveLinearEquationPCC.pl)
- `Contrib/PCC/BasicAlgebra/SystemsOfLinearEquations/SystemOfEquations20.pg` (warnings about SystemsOfLinearEquationsProblemPCC.pl)
- `Library/PCC/BasicAlgebra/ComplexNumber/complexSolutions15.pg` (warnings about contextLimitedRadicalComplex.pl)
- `Contrib/CUNY/CityTech/CollegeAlgebra_Trig/RationalExponents/combine-rational-exponents-multiply.pg` (warning about contextRationalExponent.pl)
- `Contrib/PCC/CollegeAlgebra/FunctionBasics/FunctionTables20.pg` (warnings about PCCmacros.pl)
- `Library/Union/setMVfunctions/system-f2.pg` (warning about uninitialized value)

## Todo

- remove `BrockPhysicsMacros.pl` doesn't do anything.
- remove `parserUtils.pl` and refactor the two problems that depend on it.
- remove `answers/PGmiscevaluators.pl` (not used in OPL/Contrib)
- remove `answers/PGstringevaluators.pl` (not used in OPL/Contrib)
- remove `answers/PGtextevaluators.pl` (used in only 1 problems in OPL/Contrib)
- remove `answers/answerDiscussion.pl` (not used in OPL/Contrib)
- remove `contextAlternativeDecimal.pl` (not used in OPL/Contrib)
- only place `answerUtils.pl` is used is inside `unorderedAnswer.pl` (combine?  refactor?)
- none of the LiveGraphics is working. Search for `LiveGraphics*.pl`
- What is the `fracListChecker.pl` macro?  In a number of `Contrib/Mizzou` problems.

## Info

This PR does a few related things.

1. Adds some directory structure to the `PG_ROOT/macros` directory.
2. Moves needed macros from the OPL macros directory into the PG_ROOT directories.
3. Updates the `t/load_macros.t` test to recursively search the `PG_ROOT/macros` directory
  for macros instead of the assumed old directory structure.

Also for testing, the following homework set was used.  This set contains at least one problem for every macro.

A number of issues arose while doing this.

- there are a number of errors in the OPL macros that were not being shown (they are in the apache logs).  These are to be fixed in this PR.
- The following macros are obsolete: algebraMacros, PGstringevaluators.pl, ....
  This is because the functionality appears in other macros and there are redefined
  subroutine errors upon loads.  Problems with these macros need to be adjusted in the
  OPL.  A forthcoming PR to the webwork-problem-libraries branch will contain the deletion of the macros as well as updates to the problems.  Note: the timing of this will be important so existing OPLs will still function.

Lastly, to keep the size of this discussion box reasonable, all of the changes are
documented in `PG_ROOT/macros/README.md`. Clearly these can be added to this discussion
or some other way of documenting all of these change.  Because this involved moving
files from one repository to another, git will not track specific changes, just additions and deletions.

This is based on PR ?? because of the update to the testing infrastructure makes it
much easier to do testing with this PR.
