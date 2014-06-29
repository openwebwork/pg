#! /usr/bin/perl -w



sub _compoundProblem5_init {};   # don't reload this file

HEADER_TEXT(<<'END_HEADER_TEXT');

<style type="text/css">


.canshow {background:#ff0;}
//.cannotshow {background:#e66; }
.iscorrect {background:lightgreen;}
//.iswrong {background-color:red;}
//.notanswered {}
//.canshow {background-color:#ff0;}
//.isclosed{ {background-color: #000; display:none;}

</style>


<script language="javascript">

$.fn.canshow = function() {
   $(this).addClass("canshow ui-accordion-header ui-helper-reset ui-state-default ui-corner-top ui-corner-bottom")
   .hover(function() { $(this).toggleClass("ui-state-hover"); })
   .prepend('<span class="ui-icon ui-icon-triangle-1-e"></span>')
   .click(function() {
     $(this)
       .toggleClass("ui-accordion-header-active ui-state-active ui-state-default ui-corner-bottom")
       .find("> .ui-icon").toggleClass("ui-icon-triangle-1-e ui-icon-triangle-1-s").end()
       .next().slideToggle();
     return false;
   })
   .next()
     .addClass("ui-accordion-content ui-helper-reset ui-widget-content ui-corner-bottom")
     .hide();
 };
$.fn.cannotshow = function() {
   $(this).addClass("cannotshow ui-accordion-header ui-helper-reset ui-state-default ui-corner-top ui-corner-bottom")
   .hover(function() { $(this).toggleClass("ui-state-hover"); })
   .next()
     .addClass("ui-accordion-content ui-helper-reset ui-widget-content ui-corner-bottom")
     .hide();
 };
$.fn.openSection = function() {
     $(this)
       .toggleClass("ui-accordion-header-active ui-state-active ui-state-default ui-corner-bottom")
       .find("> .ui-icon").toggleClass("ui-icon-triangle-1-e ui-icon-triangle-1-s").end()
       .next().slideToggle();
     return false;
   }
//$("#one").canshow();
//$("#two").canshow();
//$("#three").cannotshow();
//$("#four").cannotshow();
//$("#one").openSection();
</script>
END_HEADER_TEXT

package Scaffold;
@ISA = qw(PGcore);


sub new {
	my $class = shift;
	my $self = {
		scaffold_name => '',
		sections => {},
		answers =>['dummy'], # answers start at 1 so we want dummy items in position 0
		scores  =>[],
		ans_evaluators =>['dummy'],
	};

	bless $self, $class;
	return $self;
}

sub answers {
	my $self = shift;
	push @{$self->{answers}}, @_ if @_;
    $self->{answers};
}
sub scores {
	my $self = shift;
	push @{$self->{scores}}, @_ if @_;
    $self->{scores};
}
sub ans_evaluators {
	my $self = shift;
	push @{$self->{ans_evaluators}}, @_ if @_;
    $self->{ans_evaluators};
}

###########################################
sub DISPLAY_SECTION {
	 my $self= shift;
     my $options = shift;
     unless (ref($options) =~/HASH/) {
     	main::WARN_MESSAGE(" An options hash has to come first ");
     	return;
     }
     my $text_string = shift;
     my $name = $options->{name};
     my $section = $options->{section};
     my $sectionID = "DiSpLaY_SeCtIoN_$section";
     $self->{sections}->{$sectionID}->{options}=$options;
     $self->{sections}->{$sectionID}->{renderedtext}=main::EV3($text_string);
     main::TEXT( "$sectionID " ); #place holder, on a line by itself that will be replaced in process_section
     return "";
}
sub process_section {
    my $self = shift;
	my $sectionObject = shift;
	my $options = $sectionObject->{options};
	my $section = $options->{section};
	my $name = $options->{name};
	main::WARN_MESSAGE("Can't find an object for this section") unless $sectionObject;

	@Scaffold::scores1 = @{$self->scores()} ;
	#main::DEBUG_MESSAGE("scores1 is ", join("|", @Scaffold::scores1));
	#main::DEBUG_MESSAGE("scores1[1] is ", main::PG_restricted_eval('$Scaffold::scores1[2]') );
	# main::DEBUG_MESSAGE(" iscorrect before evaluation ", $options->{iscorrect} );
	$options->{iscorrect} = main::PG_restricted_eval($options->{iscorrect});
	# main::DEBUG_MESSAGE(" iscorrect after evaluation ", $options->{iscorrect} );
	$options->{canshow} = main::PG_restricted_eval($options->{canshow});
    my $iscorrect_class = "";
    if ($options->{iscorrect} == 1) {
            $iscorrect_class = 'iscorrect ';
    } elsif ($options->{iscorrect} == 0 ) {
            $iscorrect_class = 'iswrong ';
    } else {
            $iscorrect_class = 'notanswered ';
    }

    # determine whether the segment can be shown
    my $canshow = (defined($options->{canshow}) and $options->{canshow}==1 ) ?  " ": "display:none;";
    #my $selected = (defined($options->{canshow}) and $options->{canshow}==1 ) ? "deselected":"acc-selected";
    my $canshow_class = (defined($options->{canshow}) and $options->{canshow}==1 ) ?  "isopen ": "isclosed ";
    my $renderedtext = $options->{canshow} ? $sectionObject->{renderedtext} : '' ;
    my $action = $options->{canshow} ? "canshow() " : "cannotshow()";
    my $scriptpreamble = main::MODES(TeX=>'', HTML=>qq!<script>\$("#section$section").$action </script>! );
    $renderedtext = $scriptpreamble . "\n" . $renderedtext ;
    if (main::not_null($self->{sections}->{$section}->{solution} ) ){
    	$renderedtext = $renderedtext . $self->{sections}->{$section}->{solution} 
    }
    $sectionObject->{finalversion} = main::MODES(HTML=> qq!<li>
          <h3  id = "section$section" class="$iscorrect_class"  >Section: $name:</h3>
         <div><p> $renderedtext </p></div></li>
      !, TeX=>"\\par{\\bf Section: $name }\\par $renderedtext\\par");
     
}

# FIXME -- need a better identifier than 'section' if there are many scaffolds present

sub PROCESS_ANSWERS {
	my $self = shift;
	my $ans_hash;
	my @debug_messages=();
	%options = @_;   #allow debug options for example.
	my $DEBUG_ON = 1 if defined $options{debug} and $options{debug}==1;
	my @scores=(-1000);  # the zeroth position must be a dummy because answers count from 1.
	my @ans_evaluators = @{$self->ans_evaluators()};
	# main::DEBUG_MESSAGE("compoundProblem5 evaluators ", join(" ", @ans_evaluators));
	# main::DEBUG_MESSAGE("test ", $ans_evaluators[1]->evaluate(2)->{score} );
	foreach my $j (1..($#ans_evaluators)) {
	  # main::DEBUG_MESSAGE("compoundProblem5 answer $j = ",  $main::inputs_ref->{main::ANS_NUM_TO_NAME($j)});
	  # eval {$ans_hash = $ans_evaluators[$j]->evaluate($main::inputs_ref->{main::ANS_NUM_TO_NAME($j)})};
	  # DEBUG_MESSAGE("Error answerEvaluator $j ", $@) if $@ ;
	  $ans_hash = $ans_evaluators[$j]->evaluate($main::inputs_ref->{main::ANS_NUM_TO_NAME($j)});
	  $scores[$j]   = $ans_hash->{score};
	  push ( @debug_messages, "compoundProblem5  scores $j = $scores[$j]" ) if $DEBUG_ON;

	}
	main::DEBUG_MESSAGE( join("<br/>",@debug_messages)  ) if $DEBUG_ON;
	$self->scores(@scores);
}
sub PROCESS_SECTIONS {
	my $self = shift;
    my $last_correct_section = 0;
	foreach my $line (@{ $main::PG->{OUTPUT_ARRAY} }) {
		if ($line =~/^\s*(DiSpLaY_SeCtIoN_\d+)\s*$/ ) {
		   my $sectionID = $1;
		   my $sectionObject = $self->{sections}->{$sectionID};
		   main::WARN_MESSAGE("Can't find object for section $sectionID") unless $sectionObject;
		   $self->process_section($sectionObject);
		   $last_correct_section++ if $sectionObject->{options}->{iscorrect};
		   $line = $self->{sections}->{$sectionID}->{finalversion};
		}
	}
	$last_correct_section;
}

   
# FIXME   we will make a $cp object that keeps track of the section 

sub SECTION_SOLUTION {
	my $self = shift;
	my $options = shift if ref($_[0]); # get options if any
	my $sectionID = $options->{section};
	main::WARN_MESSAGE("A 'section' number is required for each solution") if main::not_null($options) and not $sectionID;
	my $output='';
    my $formatted_solution =   main::solution(main::EV3(@_));
	if ($main::displayMode =~/HTML/ and $main::envir{use_knowls_for_solutions}) {	   
    	$output =join ( $main::PAR, main::knowlLink(main::SOLUTION_HEADING(),
    	                value =>  main::escapeSolutionHTML($main::BR .  $formatted_solution. $main::PAR ),
    	                base64 =>1 ) ) if $formatted_solution
    } elsif ($main::displayMode=~/TeX/) {
    	$output = join($main::PAR,main::SOLUTION_HEADING(), $formatted_solution,$main::PAR) if $formatted_solution;
    } else {
		$output = ( "$main::PAR SOLUTION: " . $main::BR . $formatted_solution.$main::PAR) if $formatted_solution ;
	}
	if (main::not_null($sectionID)) {
		$self->{sections}->{$sectionID}->{solution}=$output;
	} else {	
		return $output;
	}
}


sub openSections {
	my $self = shift;
	my @array = @_;    #sections to leave open
	my $script_string = '';
	foreach my $s (@array) {
		$script_string .= qq!\$("#section$s").openSection()\n!;		
	}
	main::TEXT(main::MODES(TeX=>'', HTML=>qq!<script> $script_string </script> !));
}

sub ANS {
	my $self = shift;
	my @answer_evaluators = @_;
	$self->ans_evaluators(@answer_evaluators);
	main::ANS(   @answer_evaluators );
}


sub requireCorrect {
   # require correct answers for these questions
    my $self = shift;
	my @indices = @_;
	my @tmp =  map {'$Scaffold::scores1[' . ($_ ) . ']==1'} @indices;
	my $string = "( " . join(" and ", @tmp) . " )";
	# DEBUG_MESSAGE($string);
	$string;
}




package main;
sub Scaffold {
	return Scaffold->new();
}
sub INITIALIZE_SCAFFOLD {
	my $string = shift;
	if (ref($string) ) {
		WARN_MESSAGE("Enter the name of a scaffold object: 
		INITIALIZE_SCAFFOLD('\$scaffold'), not INITIALIZE_SCAFFOLD(\$scaffold)");
		$string = "Scaffold";
	}
	PG_restricted_eval ( <<END_TEXT);
	sub DISPLAY_SECTION {
		$string->DISPLAY_SECTION(\@_);
	}
	sub SECTION_SOLUTION{
		$string->SECTION_SOLUTION(\@_);
	}
	sub SECTION_ANS {
		$string->ANS(\@_);
	}
	sub PROCESS_ANSWERS {
		$string->PROCESS_ANSWERS(\@_);
	}
	sub PROCESS_SECTIONS {
		$string->PROCESS_SECTIONS(\@_)
	}
END_TEXT

	"";   # return nothing
}

1;
