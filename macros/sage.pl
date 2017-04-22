# sage.pl
#
#  This macro provides functionality for calling a Sage cell server.
#

sub _sage_init {
   PG_restricted_eval('sub Sage {new sage(@_) }');
}

package sage;

##  Options:
##    sage( SageCode (not yet), ButtonText, CellServerAddress)

sub new {
   my $self = shift; my $class = ref($self) || $self;

   my %options = ( 
      SageCode => 'print 1+2',
      ButtonText => 'Start/Restart the Interactive Cell',
      CellServer => 'https://sagecell.sagemath.org',
      SageAnswerName => 'sageAnswer',   #  not used yet
      SageAnswerValue => 'ansList',             #  not used yet
      AutoEvaluateCell => 'true',
      ShowAnswerBlank => 'hidden',
      accepted_tos =>'false',  # force author to accept terms of service explicitly
     @_
   );

   $self = bless {
     %options
   }, $class;

    main::RECORD_ANS_NAME($self->{SageAnswerName}, 345);

   $self->sageCode();
   $self->sagePrint();
   return $self;
}


sub sageCode{
  my $self = shift;
  main::TEXT(main::MODES(TeX=>"", HTML=><<"SAGE_CODE"));

<div id="sagecell">
<script type="text/code">

def record_answer($self->{SageAnswerValue}):
    html('<input type=$self->{ShowAnswerBlank} size=15 name="$self->{SageAnswerName}" id="$self->{SageAnswerName}" value="%s">'%($self->{SageAnswerValue},)   )

$self->{SageCode}

    </script>
</div>

SAGE_CODE
}

sub sagePrint{ 
  my $self = shift;
  main::TEXT(main::MODES(TeX=>"", HTML=><<"SAGE_PRINT"));
    <script src="$self->{CellServer}/static/jquery.min.js"></script>
    <script src="$self->{CellServer}/embedded_sagecell.js"> </script>
    <script>
      \$(function () {
        sagecell.makeSagecell({
           inputLocation:     '#sagecell',
           template:              sagecell.templates.minimal,
           autoeval:               $self->{AutoEvaluateCell}, 
           linked:                   true,        
           evalButtonText:    '$self->{ButtonText}'
         });
       });
    </script>
SAGE_PRINT
}


#### Experimental stuff.

package main;
sub sageCalculatorHeader {
$CellServer = 'https://sagecell.sagemath.org';
main::HEADER_TEXT(main::MODES(TeX=>"", HTML=><<"END_OF_FILE"));
<script src="$CellServer}/static/jquery.min.js"></script>
    <script src="$CellServer/static/embedded_sagecell.js"></script>
    <script>\$(function () {
    // Make the div with id 'mycell' a Sage cell
    sagecell.makeSagecell({inputLocation:  '#mycell',
                           template:       sagecell.templates.minimal,
                           evalButtonText: 'Activate'});
    // Make *any* div with class 'compute' a Sage cell
    sagecell.makeSagecell({inputLocation: 'div.compute',
                           autoeval: 1,
                           evalButtonText: 'Evaluate'});
    });
    </script>
END_OF_FILE

}

sub sageCalculatorPad {
	my $top_test = shift;
	my $initial_contents = shift;
main::TEXT(main::MODES(TeX=>"", HTML=><<"EOF"));

<p>
$top_text
<p>
<div class="compute">
<script type="text/x-sage">

$initial_contents

</script></div>

EOF
	
return $out;	
	
	
}
1;    #required at end of file - a perl thing