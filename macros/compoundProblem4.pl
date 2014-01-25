#! /usr/bin/perl -w



sub _compoundProblem4_init {};   # don't reload this file

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
	};

	bless $self, $class;
	return $self;
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
	my $section = $sectionObject->{options}->{section};
	main::WARN_MESSAGE("Can't find an object for this section") unless $sectionObject;
	my $options = $sectionObject->{options};
	$options->{iscorrect} = main::PG_restricted_eval($options->{iscorrect});
	$options->{canshow} = main::PG_restricted_eval($options->{canshow});	
    my $iscorrect_class = "";
    if ($options->{iscorrect} == 1) {
            $iscorrect_class = 'iscorrect ';
    } elsif ($options->{iscorrect} == -1 ) {
            $iscorrect_class = 'iswrong ';
    } else {
            $iscorrect_class = 'notanswered ';
    }

    # determine whether the segment can be shown
    my $canshow = (defined($options->{canshow}) and $options->{canshow}==1 ) ?  " ": "display:none;";
    #my $selected = (defined($options->{canshow}) and $options->{canshow}==1 ) ? "deselected":"acc-selected";
    my $canshow_class = (defined($options->{canshow}) and $options->{canshow}==1 ) ?  "isopen ": "isclosed ";
    my $name = $options->{name};
    my $section = $options->{section};
    my $renderedtext = $options->{canshow} ? $sectionObject->{renderedtext} : '' ;
    $sectionObject->{finalversion} = main::MODES(HTML=> qq!<li>
          <h3  id = "section$section" class="$iscorrect_class"  >Section: $name:</h3>
         <div><p> $renderedtext </p></div></li>
      !, TeX=>"\\par{\\bf Section: $name }\\par");
     
     my $action = $options->{canshow} ? "canshow() " : "cannotshow()";
     main::TEXT(main::MODES(TeX=>'', HTML=>qq!<script>\$("#section$section").$action </script>! ));
}

# FIXME -- need a better identifier than 'section' if there are many scaffolds present

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
    my $formatted_solution =   main::EV3(main::solution(@_)) ;
	if ($main::displayMode =~/HTML/ and $main::envir{use_knowls_for_solutions}) {	   
    	return( $main::PAR, main::knowlLink("SOLUTION: ", value =>  main::escapeSolutionHTML($BR .  $formatted_solution. $PAR ),
    	              base64 =>1 ) ) if $formatted_solution
    } else {
		return( "$main::PAR SOLUTION: ".$BR.$formatted_solution.$PAR) if $formatted_solution ;
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
# sub BEGIN_SECTIONS {
# 	TEXT(MODES(HTML=>q!<ul class="acc" id="acc"> !,TeX=>'')); 
# }
# sub END_SECTIONS {
# 	my $section = shift; #section to keep open (starts at 1);
# 	TEXT(MODES( HTML=>q!</ul  !,TeX=>''));
# 	TEXT(MODES(HTML =>$PAR .qq!
# 	<script language="javascript">
# 	var parentAccordion=new TINY.accordion.slider("parentAccordion");
# 	parentAccordion.init("acc","h3",0,-1);
# 	parentAccordion.pr(0,$section-1)
# 	</script>
# 	! , TeX=>''));
# }

package main;
sub Scaffold {
	return Scaffold->new();
}
1;