# sage.pl
#
#  This macro provides functionality for calling a Sage cell server.
#

sub _sage_init {
   PG_restricted_eval('sub Sage {new sage(@_) }');
} 
# Sage()  is defined as an alias for creating a new sage object. 




package sage;

=head3 Sage cell 

	usage: Sage( SageCode => 'print 1+2; record_answer(3)', 
	             ButtonText => 'Start/Restart the Interactive Cell', 
	             ShowAnswerBlank => # "hidden" (default) or "visible" or 'none'
	             CellServerAddress => 'https://sagecell.sagemath.org'
	            );
	        NAMED_ANS(sageAnswer => Compute('3')->cmp);

The arguments are all optional but usually you will want to supply your own SageCode.

This method of calling sage was designed specially for presenting sage "interacts", applet
like creations in SageMath, although it may be useful for other purposes also. If the answer blank
is hidden then the interact fills in the answer as a result of manipulations on the applet 
performed by the student and the student cannot override the answer. 

To return answers from the sage interact:

The function record_answer(answer_list) called from within the SageCode
creates a NAMED_ANS_RULE or NAMED_HIDDEN_ANS_RULE with 
the values of the answer_list inserted. If ShowAnswerBlank is "hidden" then the HIDDEN answer rule is
used; if ShowAnswerBlank is 'none' then no answer blank is inserted. 

For the current implementation the Sage interact can create only one answer blank. 

When the sage interact creates an answer blank it must be checked by WeBWorK using the construction

C<NAMED_ANS(sageAnswer =E<gt> $correctAnswer-E<gt>cmp)>

where 'sageAnswer' is the SageAnswerName  and   $correctAnswer is a MathObject.

By default the sage created answer blanks are hidden, but it is visible if ShowAnswerBlank is set to 
'visible'. When visible the answer blanks occur within the borders which define the output
of the sage applet.  The answer blanks are 15 spaces long. 
   


=cut 

sub new {
   my $self = shift; my $class = ref($self) || $self;

   my %options = ( 
      SageCode => 'print 1+2;record_answer(3)',
      ButtonText => 'Start/Restart the Interactive Cell',
      CellServer => 'https://sagecell.sagemath.org',
      SageAnswerName => 'sageAnswer',   
      SageAnswerValue => 'ansList',     #  used in early versions, may no longer be needed 
      AutoEvaluateCell => 'true',
      ShowAnswerBlank => 'hidden',  #'hidden','visible','none'
      AnswerReturn => 1,   # (legacy, use ShowAnswerBlank=>'none')
                           # 0 means no answer blank is registered
#     accepted_tos =>'false',   # force author to accept terms of service explicitly
                                # removed because sagecell.sagemath.org no longer requires
                                # acknowledgement of terms of service.
     @_
   );

     
# handle legacy case where AnswerReturn was used
   unless ($options{ShowAnswerBlank} =~ /\S/){
   		if ($options{AnswerReturn} == 0) {
   			$options{ShowAnswerBlank} = 'none';
   		} else {
   			$options{ShowAnswerBlank} = 'hidden';
   		}
   }
 	

   # lets create a new hash for "self"
   $self = bless {%options}, $class;
   
     
   # main::RECORD_ANS_NAME($self->{SageAnswerName}, 345); -- old version of code


   # Create python/sage function "record_answer()" 
   # to print a WeBWorK answer blank from within
   # the sage interact.  The function is different depending on  whether the answer blank exists
   # and whether it is visible.
     
   # (1) $recordAnswerBlank will hold the code defining 'record_answer' which, when called from 
   # within Sage prints a WeBWorK (HIDDEN)_NAMED_ANS_RULE and inserts the answers values.
   # This is the mechanism for returning an answer created by the sage interact. 
   # By default this answer blank is hidden, but it is visible if ShowAnswerBlank is set to 
   # 'visible'. When visible the answer blanks occur within the borders which define the output
   # of the sage applet.  The answer blanks are 15 spaces long. 
   # FIXME: For the current implementation the Sage interact can create only one answer blank. 
   # provisions for giving each answer blank a different label would need to be created.  
   
   	my $recordAnswerBlank='';
   	if ($self->{ShowAnswerBlank} eq 'visible') {
   		$recordAnswerBlank = "Answer: ".main::NAMED_ANS_RULE($self->{SageAnswerName}, 15);
   	} elsif ($self->{ShowAnswerBlank} eq 'hidden') {
 		$recordAnswerBlank = main::NAMED_HIDDEN_ANS_RULE($self->{SageAnswerName},15);
 	} elsif ($self->{ShowAnswerBlank} eq 'none') {
 		$recordAnswerBlank = 'none'; # don't register an answer blank
   	} else {
   		main::WARN_MESSAGE("Option $option{ShowAnswerBlank} is not valid for displaying sage answer rule. ");
   	}	
    # you could add an option to print an ANSWER BOX instead of an ANSWER RULE
    

    #FIXME  -- for some reason the answer blank, printed with pretty_print 
    # floats to the top of the printed Sage block  above print statements.
    # ???? This can be intermittent, which is even more surprising. 
    
    # (2) now determine whether the record_answer() prints an answer blank
    # or is a noop - a dummy operation.
    
    if ($recordAnswerBlank eq 'none') {
		$sage::recordAnswerString = <<EndOfString;
def record_answer(ansVals):
    print('');
EndOfString
	} else {
		$sage::recordAnswerString = <<EndOfString;
def record_answer(ansVals):
    pretty_print(  HtmlFragment('$recordAnswerBlank'%(ansVals,)   ) )
EndOfString
	}
	
## debug code -- uncomment next line -- note that string contains html and must be protected.	
  # main::TEXT( "recordAnswerString is ", main::encode_pg_and_html($sage::recordAnswerString), $BR, main::encode_pg_and_html("recordAnswerBlank is |$recordAnswerBlank|"), $BR );
 
 # typically the sage::recordAnswerString looks like this:
	 # def record_answer(ansVals): pretty_print( HtmlFragment(
	 # '<INPUT TYPE=HIDDEN SIZE=15 NAME="sageAnswer" id ="sageAnswer" VALUE="(1, 1)">
	 # <INPUT TYPE=HIDDEN NAME="previous_sageAnswer" id = "previous_sageAnswer" VALUE="(1, 1)">'
	 # %(ansVals,) ) ) 
 # the next line replaces the first VALUE="(1, 1)" with %s, so that we have: 
  	 # def record_answer(ansVals): pretty_print( HtmlFragment(
	 # '<INPUT TYPE=HIDDEN SIZE=15 NAME="sageAnswer" id ="sageAnswer" value="%s">
	 # <INPUT TYPE=HIDDEN NAME="previous_sageAnswer" id = "previous_sageAnswer" VALUE="(1, 1)">'
	 # %(ansVals,) ) ) 
 # When evaluated in sage (python) %s is replaced by the value of ansVals
 
  $sage::recordAnswerString =~ s/value="[^"]*"/value="%s"/i;
 # this line removes any returns from the output -- this might not be necessary
  $sage::recordAnswerString =~ s/\n/ /g;


   $self->sageCode();
   $self->sagePrint();
   return $self;
}


# Notice that python is white space sensitive so the code
# needs to be left justified when inserted to 
# avoid indentation errors.  
# 

sub sageCode{
  my $self = shift;
  main::TEXT(main::MODES(TeX=>"", HTML=><<"SAGE_CODE"));
<div id="sagecell">
	<script type="text/code">

from sage.misc.html import HtmlFragment
$sage::recordAnswerString
$self->{SageCode}


    </script>
</div>

SAGE_CODE
}

sub sagePrint{ 
  my $self = shift;
  main::TEXT(main::MODES(TeX=>"", HTML=><<"SAGE_PRINT"));
    <script>var jqSave = \$.noConflict(true);</script>
    <script src="$self->{CellServer}/embedded_sagecell.js"> </script>
    <script>
      jqSave(function () {
        sagecell.makeSagecell({
           inputLocation:     '#sagecell',
           template:              sagecell.templates.minimal,
           autoeval:               $self->{AutoEvaluateCell}, 
           linked:                   true,        
           evalButtonText:    '$self->{ButtonText}'
         });
       });
       \$ = jQuery = jqSave;
    </script>
SAGE_PRINT
}


=head3 sageCalculatorPad code.


This is a simple interface for embedding a sage calculation cell in any problem. 
Details for this can be found at
L<https://sagecell.sagemath.org/static/about.html?v=98b56535a5f3e54e272938b62c79287c>
and for more detail:
L<https://github.com/sagemath/sagecell/blob/master/doc/embedding.rst>.

The latter reference provides information for embedding a customized sageCell with more 
options than are provided by sageCalculatorPad()

=cut

=head3 Sample sageCalculatorPad

	sageCalculatorHeader();  # set up javaScript needed for the sageCalculatorPad
	                         

	Context()->texStrings;
	TEXT(
	   sageCalculatorPad( "Use this calculator pad to make calculations",  
	q!                                                                          
	data = [1, 3, 4, 1, 7, 4, 2, 3, 2, 4, 2, 5, 4, 1, 3, 3, 2]
	n = len(data); print "Number of data values =",n
	s = sum(data); print "          Sum of data = ",s
	s2 = sum((x^2 for x in data)); print "       Sum of squares = ",s2
	s3 = sum((x^3 for x in data)); print "         Sum of cubes = ",s3
	s4 = sum((x^4 for x in data)); print "        Sum of forths = ",s4;print
	mu = mean(data); print "             The mean =",mu
	var = variance(data); print "  The sample variance = ",var
	!
	   )
	);

=cut

package main;
sub sageCalculatorHeader {
$CellServer = 'https://sagecell.sagemath.org';
main::HEADER_TEXT(main::MODES(TeX=>"", HTML=><<"END_OF_FILE"));
    <script>var jqSave = \$.noConflict(true);</script>
    <script src="$CellServer/static/embedded_sagecell.js"></script>
    <script>jqSave(function () {
    // Make *any* div with class 'sage-compute' a Sage cell
    sagecell.makeSagecell({inputLocation: 'div.sage-compute',
                           autoeval: 1,
                           hide: ["permalink"],
                           evalButtonText: 'Evaluate'});
    \$ = jQuery = jqSave;
    });
    </script>
END_OF_FILE

}

sub sageCalculatorPad {
	my $top_text = shift;
	my $initial_contents = shift;
main::TEXT(main::MODES(TeX=>"SageCell: $top_text", HTML=><<"EOF"));

<p>
$top_text
<p>
<div class="sage-compute">
<script type="text/x-sage">

$initial_contents

</script></div>

EOF
	
return $out;	
	
	
}
1;    #required at end of file - a perl thing
