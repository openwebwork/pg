################################################################################
# WeBWorK Online Homework Delivery System
# Copyright © 2000-2007 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader$
# 
# This program is free software; you can redistribute it and/or modify it under
# the terms of either: (a) the GNU General Public License as published by the
# Free Software Foundation; either version 2, or (at your option) any later
# version, or (b) the "Artistic License" which comes with this package.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See either the GNU General Public License or the
# Artistic License for more details.
################################################################################

=head1 NAME

displayMacros.pl - [DEPRECATED] WeBWorK 1.x display macros.

=head1 DESCRIPTION

This file is used with WeBWorK 1.9 and is not used for WeBWorK 2.x.

=cut

use strict;

## $ENV{'PATH'} .= ':/usr/math/bin';

my $debug = 0;
$debug = 1 if $Global::imageDebugMode;
    ## if $debug =1, log, etc. files created by
                  ## latex2html are not deleted

##############################################################
#  File: DisplayMacros.pl
#  This contains the subroutines for creating problem files
##############################################################

################################################################
#  Copyright @1995-1998 by Michael E. Gage, Arnold K. Pizer and
#  WeBWorK at the University of Rochester. All rights reserved.
################################################################


## To add or delete displayModes edit this file

sub displaySelectModeLine_string
                  # called from probSet.pl
                  # displays the option line for selecting display modes
{
   my ($displayMode) =@_ ;
   $displayMode = $Global::htmlModeDefault unless(defined($displayMode));
   # If the system is set up with only one display mode, there is
   # no need to display a choice - use the default
   if(scalar(@{$Global::available_mode_list})<2) {
     return('<input type="hidden" name="Mode" value="'.
          $displayMode .'">');
   }
   my $out = "Display Mode: <BR>";

# A list of the available modes.
	my $mode_list = $Global::available_mode_list;	## ref to a list of available modes
																	## The format is [internal symbol, external name]
# A list of the available modes.
# Format is [internal symbol, external name, ""], where the third
# argument is changed to checked below for the current displayMode
#   my $mode_list = [
#	['HTML', 'text', ""],
#	['HTML_tth', 'formatted-text',""],
#	['HTML_dpng' ,'dvipng',""],
#	['Latex2HTML', 'typeset',""]
#	];

# Make the format [internal symbol, external name, '']
# The third argument is changed to checked below for the current displayMode
	my $j;
	for $j (0..(scalar(@{$mode_list})-1)) {
		push @{$mode_list->[$j]},'';
	}

   if (! defined($displayMode) ) {$displayMode = $Global::htmlModeDefault;}


   my $found = 0;
# Search through all modes to match for displayMode
# If we don't find one, found=0 will trigger warn message below
   for $j (0..(scalar(@{$mode_list})-1)) {
     if($mode_list->[$j]->[0] eq $displayMode) {
        $mode_list->[$j]->[2] = "CHECKED";
        $found=1;
        last;
     }
   }

   for $j (@{$mode_list}) {
     $out .= qq!<INPUT TYPE=RADIO NAME="Mode" VALUE="$j->[0]" $j->[2]>$j->[1]<BR>\n!;
   }
   if(! $found) {
     my $wstr = " Error: displayMacros.pl: sub displaySelectModeLine. Unrecognized mode |$displayMode| .  The acceptable modes are: ";
     for $j (@{$mode_list}) {
       $wstr .= " $j->[0] ";
     }
     warn $wstr;
   }
  $out;
}

sub displaySelectModeLine {
	print displaySelectModeLine_string(@_);
}
##################################################################################################################
# Does the initial processing of the problem.
# Returns an array containing the rendered problem.  	      #
##################################################################################################################

sub createDisplayedProblem  {

   my ($setNumber,$probNum,$psvn,$printlinesref,$rh_flags)= @_;
   my @printlines;


      my $coursel2hDirectory = getCoursel2hDirectory();
      unless(-e $coursel2hDirectory ) {
         	&createDirectory($coursel2hDirectory, $Global::l2h_set_directory_permission,
            $Global::numericalGroupID);
      }

      unless(-e "${coursel2hDirectory}set$setNumber") {
	 		&createDirectory("${coursel2hDirectory}set$setNumber",$Global::l2h_set_directory_permission,
	   		$Global::numericalGroupID);
      }


    my $PROBDIR = convertPath("${coursel2hDirectory}set$setNumber/$probNum-$psvn/");
    my $TMPPROBDIR = convertPath("${coursel2hDirectory}$probNum-$psvn/");

      if (! -e $PROBDIR) {  # no gifs of equations have been created
      		&l2hcreate($setNumber,$probNum,$psvn,$printlinesref);

      }	else {  # determine if the gifs are older than the modifications of the source file
                #&attachProbSetRecord($psvn);
         	my $fileName = &getProblemFileName($probNum,$psvn);
         	$fileName = "${Global::templateDirectory}$fileName";
                  #print "\n\n The filename is $fileName \n\n";
         	my @probDirStat = stat $PROBDIR;
         	my @sourceFileStat = stat $fileName;
                  #print "\n\n The source file age is $sourceFileStat[9] \n\n";
                  #print "\n\n The prob dir age is $probDirStat[9] \n\n";

         	if (($sourceFileStat[9] > $probDirStat[9] ) or
         	                   $rh_flags->{'refreshCachedImages'}) {
         	        ## source file is newer or solutions should be shown recreate the l2h cache
            		rmDirectoryAndFiles($PROBDIR);
            		&l2hcreate($setNumber,$probNum,$psvn,$printlinesref);
         	}


      }
      #the problem has been rendered by Latex2HTML into this file:
#      open(TEXXX, "${PROBDIR}${psvn}output.html") || die "Can't open ${PROBDIR}${psvn}output.html";
      open(TEXXX, "${PROBDIR}${psvn}output.html") or
               warn "ERROR: $0".
               "Can't open the HTML file: \n ${PROBDIR}${psvn}output.html\n(allegedly)".
                "translated by latex2HTML\n at displayMacros.pl, line" . __LINE__ ;

      @printlines = <TEXXX>;
      push(@printlines, "The file ${PROBDIR}${psvn}output.html was empty") unless @printlines;
      #print "PRINTLINES",@printlines;
      close(TEXXX);

   @printlines;
}



###########################################################################################
# Formats and displays the responses to submitted answers to the problem.  Returns a string.   	      #
###########################################################################################

sub display_answers {			# this will be put in displayMacros.pl soon.
	#my	($displayCorrectAnswersQ,$showPartialCorrectAnswers,$rh_answer_results,$rh_problem_result)  = @_;
    my	($rh_answer_results,$rh_problem_result,$rh_flags)  = @_;
    my $displayCorrectAnswersQ = $rh_flags ->{displayCorrectAnswersQ};
    my $showPartialCorrectAnswers = $rh_flags -> {showPartialCorrectAnswers};
    my @answer_entry_order = @{$rh_flags -> {ANSWER_ENTRY_ORDER} };
    my $ANSWER_PREFIX = $rh_flags -> {ANSWER_PREFIX};
	my	$allAnswersCorrectQ = 1;
	my	$printedResponse='';
	###### Print appropriate response to submitted answers
	    my ($i,$answerIsCorrectQ, $normalizedSubmittedAnswer,$normalizedCorrectAnswer,$ans_name,$errors);
	    $i=0;
#	    $printedResponse .= "\n<table border=0 cellpadding=0 cellspacing=0  bgcolor=\"#cccccc\">\n";
# replace above line by next two lines as per Davide Cervone. AKP.
	    $printedResponse .= "\n<table border=0 cellpadding=7 cellspacing=0 bgcolor=\"#cccccc\">\n";
	    $printedResponse .= "<tr><td><table border=0 cellpadding=0 cellspacing=0>\n";
	    foreach my $key ( @answer_entry_order ) {

			$i++;
			$answerIsCorrectQ = $rh_answer_results ->{$key} -> {score};
			$normalizedSubmittedAnswer = $rh_answer_results ->{$key} -> {student_ans};
			$normalizedSubmittedAnswer = '' if ($normalizedSubmittedAnswer =~ /^error:\s+empty/);
			$normalizedCorrectAnswer = $rh_answer_results ->{$key} -> {original_correct_ans};

				##  Handle the case where the answer evaluator does not return original_correct_ans
			if ((!defined $normalizedCorrectAnswer) or (!$normalizedCorrectAnswer =~ /\S/)) {
				$normalizedCorrectAnswer = $rh_answer_results ->{$key} -> {correct_ans};
			}

			$errors = $rh_answer_results ->{$key} -> {ans_message};
			$errors = '' if ($errors eq 'empty');
			#$ans_name = $rh_answer_results ->{$key} -> {ans_name};
			#$ans_name =~ s/$ANSWER_PREFIX//;    # this handles implicitly defined answer names.
			$ans_name = $i;  # just number the answers in order
		    $allAnswersCorrectQ = $allAnswersCorrectQ && $answerIsCorrectQ;
			$printedResponse .= "\n<TR><TD align=left COLSPAN =2><em>Answer $ans_name entered:</em>--&gt; $normalizedSubmittedAnswer &lt;-- ";
		    $printedResponse .=  "<B>Correct. </B></TD></TR>"   if  ($answerIsCorrectQ && $showPartialCorrectAnswers );
		    $printedResponse .=  "<B>Incorrect. </B></TD></TR>" if (!($answerIsCorrectQ) && $showPartialCorrectAnswers);
			$errors =~ s/\n/<BR>/g;  ## convert newlines to <BR> in error messages as per Davide Cervone
            # change 9/2/00 by MEG -- give width in pixels rather than %.
            # Some browsers break with %  widht which is not the standard
			$printedResponse .=  "\n<TR> <TD align=left WIDTH = \"50\" >&nbsp;</TD><TD align=left>$errors</TD></TR>" if ($errors =~ /\w/);

			$printedResponse .= "\n<TR><TD align=left WIDTH = \"50\">&nbsp;</TD>              <TD align=left><em>Correct answer:</em> $normalizedCorrectAnswer</TD></TR>" if ($displayCorrectAnswersQ);

	    }
	    if ($i == 1) {
	        $printedResponse .= "\n<TR><TD align=left COLSPAN =2><B>The above answer is correct.</B><BR>" if ($allAnswersCorrectQ);
	        $printedResponse .= "\n<TR><TD align=left COLSPAN =2><B>The above answer is NOT correct.</B><BR>" if (!($allAnswersCorrectQ));
	    }
	    else {
	        $printedResponse .= "\n<TR><TD align=left COLSPAN =2><B>All of the above answers are correct.</B><BR>" if ($allAnswersCorrectQ);
	        $printedResponse .= "\n<TR><TD align=left COLSPAN =2><B>At least one of the above answers is NOT correct.</B><BR>" if (!($allAnswersCorrectQ));
	    }
        my $percentCorr = int(100*$rh_problem_result->{score} +.5);

	  $printedResponse .="\n<TR><TD align=left COLSPAN =2><B>Your score on this attempt is ${percentCorr}\%.</B><BR>";
#	  $printedResponse .= "\n</table>\n";
# replace above line by next line as per Davide Cervone. AKP.
	  $printedResponse .= "</td></tr>\n</table>\n</table>\n";
#      $printedResponse .="\n problem grader is ".$rh_problem_result->{type}." and the score is ".$rh_problem_result->{score}."<BR>\n";
	  $printedResponse;
}

###########################################################################################
# Previews submitted answers to the problem.  Returns a string.   	      #
###########################################################################################

sub preview_answers {
    my	($rh_answer_results,$rh_problem_result,$rh_flags)  = @_;
    my @answer_entry_order = @{$rh_flags -> {ANSWER_ENTRY_ORDER} };
    my $ANSWER_PREFIX = $rh_flags -> {ANSWER_PREFIX};
    my $printedResponse ='';
	###### Print appropriate response to submitted answers
	    my ($i,$original_student_ans,$normalizedSubmittedAnswer,$errors,$ans_name,$preview_text_string,$preview_latex_string);
        my ($ans_evaluator_type, $value_word, $error_word, $show_value);

	    $i=0;
	    $printedResponse .= "\n<table border=0 cellpadding=0 cellspacing=0  >\n";
	    foreach my $key ( @answer_entry_order ) {
		$i++;
		$ans_name = $rh_answer_results ->{$key} -> {ans_name};
		#$ans_name =~ s/$ANSWER_PREFIX//;    # this handles implicitly defined answer names.	#commented out by DME 6/6/2000
		$original_student_ans = $rh_answer_results ->{$key} -> {original_student_ans};
		$normalizedSubmittedAnswer = $rh_answer_results ->{$key} -> {student_ans};
		$errors = $rh_answer_results ->{$key} -> {ans_message};
		$errors =~ s/\n/<BR>/g;  ## convert newlines to <BR> in error messages as per Davide Cervone
		$preview_text_string ='';
		$preview_text_string = $rh_answer_results ->{$key} -> {preview_text_string}
			if defined $rh_answer_results ->{$key} -> {preview_text_string};
		$preview_latex_string ='';
		$preview_latex_string = $rh_answer_results ->{$key} -> {preview_latex_string}
			if defined $rh_answer_results ->{$key} -> {preview_latex_string};
		$ans_evaluator_type = $rh_answer_results ->{$key} -> {type};
		$value_word = 'value:';
		$show_value = 0;
		$show_value = 1 if ((($ans_evaluator_type =~ /number/) and ($normalizedSubmittedAnswer =~ /\w/)) or ($normalizedSubmittedAnswer =~ /^error/));
		$show_value = 0 if ($normalizedSubmittedAnswer =~ /^error:\s+empty/);
		$value_word = '' if ($normalizedSubmittedAnswer =~ /^error/);
		$error_word = 'error:';
		$error_word = '' if ($errors =~ /^error:/);
		$printedResponse .= "\n<TR><TD align=left>Ans $i </TD>";
		#$printedResponse .= "\n<TD align=left><INPUT TYPE=\"text\" NAME=\"${ANSWER_PREFIX}${ans_name}\"  VALUE=\"$original_student_ans\" SIZE=70></TD></TR>";	#commented out by DME 6/6/2000
		$printedResponse .= "\n<TD align=left><INPUT TYPE=\"text\" NAME=\"${ans_name}\"  VALUE=\"$original_student_ans\" SIZE=70></TD></TR>";
		$printedResponse .= "\n<TR> <TD align=left WIDTH = \"7%\" ></TD><TD align=left>parsed: $preview_text_string</TD></TR>" if ($preview_text_string =~ /\w/);
		$printedResponse .= "\n<TR> <TD align=left WIDTH = \"7%\" ></TD><TD align=left>${value_word} $normalizedSubmittedAnswer</TD></TR>" if $show_value == 1;
		$printedResponse .= "\n<TR> <TD align=left WIDTH = \"7%\" ></TD><TD align=left>${error_word} $errors</TD></TR>" if (($errors =~ /\w/) and ($errors ne 'empty')) ;
		if ($preview_latex_string =~ /\w/) {
			$printedResponse .= "\n<TR> <TD align=left WIDTH = \"7%\" ></TD><TD align=left>";
			$printedResponse .= "\n <APPLET CODE=\"HotEqn.class\" HEIGHT=\"80\" WIDTH=\"500\" ARCHIVE=\"HotEqn.zip\" NAME=\"Equation\" ALIGN=\"middle\" CODEBASE=\"$Global::appletsURL\"> ";
			$printedResponse .= "\n <PARAM NAME=\"equation\" VALUE=\"$preview_latex_string\"></APPLET></TD></TR> ";
		}
		$printedResponse .= "\n<TR Height = 5></TR>";
	    }

	  $printedResponse .= "\n</table>\n";
	  $printedResponse;
}


sub lc_sort {  # this sorts strings with letters and number groups, alternately lexigraphically and numerically
               # (lc stands for library of congress as in QA617.34R45)
    my($left,$right) = @_;
    # format  "abcd345.57def34ABC";
    # string assumed to begin with alpha
    # string is split into alternating alpha and numeric groups
    # numeric groups match [\d\.]+
    # numeric groups assumed to contain at least one digit, ( a period alone will cause and error)
    # alpha groups can contain any characters except digits and the period
    # spaces in alpha groups will cause unexpected behavior
    # sort is not case sensitive
    # _ sorts after alpha characters

    # not case sensitive

    my @a = split( /([\d\.]+)/, $left);

    my @b = split( /([\d\.]+)/, $right);

    my $out = undef;
    my $mode = 0;  # even is lexic and odd is numeric
    my($l,$r);
    while (@a) {
		$l = shift @a;
		$r = shift @b;
		$out = ($mode++ % 2 == 0) ? uc($l) cmp uc($r) : $l <=> $r;  # lexic or numeric compare
		last unless $out==0;   # stop unless $l and $r are different.

    }
   $out;
}

#####################################################################
# Creates an insert which appears on the probSet page.     	        #
#####################################################################
sub createDisplayedInsert
{
   #my ($mode,$setNumber,$fileName,$psvn,$courseName,$printlinesref)= @_;
   my ($setNumber,$fileName,$psvn,$courseName,$printlinesref)= @_;

   my @printlines=@$printlinesref;
   my $PROBDIR;

#   if($mode eq "HTML" || $mode eq 'HTML_tth') {
#   		@printlines = &createProblem2($mode,$fileName,$psvn,$courseName,$sourceref);
#
#   } elsif ($mode eq 'Latex2HTML')  {
     #latex2html processing
      my $coursel2hDirectory = getCoursel2hDirectory();
      unless(-e $coursel2hDirectory ) {
         	&createDirectory($coursel2hDirectory, $Global::l2h_set_directory_permission,
            $Global::numericalGroupID);
      }

      unless(-e "${coursel2hDirectory}set$setNumber") {
	 		&createDirectory("${coursel2hDirectory}set$setNumber",$Global::l2h_set_directory_permission,
	   		$Global::numericalGroupID);
      }

	my $shortFileName = $fileName;
	$shortFileName =~ s|^.*?([^\/]*)$|$1|;
	$shortFileName =~ s|\..*$||;
	$PROBDIR = convertPath("${coursel2hDirectory}set$setNumber/$shortFileName-$psvn/");
	if (! -e $PROBDIR) {
		&l2hcreate($setNumber,$shortFileName,$psvn,$printlinesref);
	} else	{
		#&attachProbSetRecord($psvn);
	        my $fullFileName = "${Global::templateDirectory}$fileName";
	        #print "\n\n The  full filename is $fullFileName \n\n";
	        my @probDirStat = stat $PROBDIR;
	        my @sourceFileStat = stat $fullFileName;
	        #print "\n\n The source file age is $sourceFileStat[9] \n\n";
	        #print "\n\n The prob dir age is $probDirStat[9] \n\n";
	        if ($sourceFileStat[9] > $probDirStat[9] )  { ## source file is newer
	        	rmDirectoryAndFiles($PROBDIR);
	            	&l2hcreate($setNumber,$shortFileName,$psvn,$printlinesref);
	        }
	         #else {&createProblem2($mode, $fileName, $psvn,$courseName,$sourceref);}   ##initialize problem

	}


      open(TEXXX, "${PROBDIR}${psvn}output.html") or
        die "ERROR: $0 Can't open ${PROBDIR}${psvn}output.html";
      @printlines = <TEXXX>;
      close(TEXXX);
#   } else  {
#
#   	  @printlines="createDisplayedProblem: Error:  Mode is not HTML, HTML_tthHTML_tth or Latex2HTML.";
#
#
#   }
   @printlines;
}

##do not need this subroutine anymore
#sub l2hcreateProb {
#   my ($setNumber,$probNum,$psvn,$printlinesref)= @_;
#   #my ($setNumber,$probNum,$psvn,$courseName,$printlinesref)= @_;
#   #my $mode = 'Latex2HTML';
#
#   #my @printlines = &createProblem($mode, $probNum, $psvn, $courseName,$sourceref,$refSubmittedAnswers);
#   #my $printlinesref = \@printlines;
#   my $tmpDirectory = "tmp/l2h/set$setNumber/$probNum-$psvn/";
#   l2hcreate($setNumber,$probNum,$psvn,$printlinesref)
#}

#do not use this subroutine anymore
#sub l2hcreateInsert {
#   my ($setNumber,$shortFileName,$psvn,$printlinesref)= @_;
#   #my $mode = 'Latex2HTML';
#   #my @printlines = &createProblem2($mode, $fileName, $psvn,$courseName,$sourceref);
#   #my $printlinesref = \@printlines;
#   #my $shortFileName = $fileName;
#   #$shortFileName =~ s|^.*?([^\/]*)$|$1|;
#   #my $tmpDirectory = "tmp/l2h/set$setNumber/$shortFileName-$psvn/";
#   l2hcreate($setNumber,$shortFileName,$psvn,$printlinesref)
#}

sub l2hcreate {     ## for latex2HTML 96.1 and 98.1
   my ($setNumber,$probNum,$psvn,$printlinesref) = @_;

   # warn "l2hcreate is being executed displaymacros.pl line ".__LINE__;

   my $PROBDIR = convertPath(&getCoursel2hDirectory."set$setNumber/$probNum-$psvn/");
   my $TMPPROBDIR = convertPath(&getCoursel2hDirectory."$probNum-$psvn/");
   my $PROBURL = &getCoursel2hURL."set$setNumber/$probNum-$psvn/";

   &createDirectory($TMPPROBDIR,$Global::l2h_prob_directory_permission,$Global::numericalGroupID)
     unless(-e "$TMPPROBDIR");

   open(OUTTEXFILE, ">$TMPPROBDIR${psvn}output.tex") or die "Can't open temporary file $TMPPROBDIR${psvn}output.tex";

   print OUTTEXFILE &texInput($Global::TEX_PROB_PREAMBLE);
   print OUTTEXFILE &texInput($Global::TEX_PROB_HEADER);
   print OUTTEXFILE @$printlinesref;
   print OUTTEXFILE &texInput($Global::TEX_PROB_FOOTER);
   close(OUTTEXFILE);

   ## Give this temporary file permission 666 in case the process dies before it it deleted 60 lines further down
   chmod(0666, "$TMPPROBDIR${psvn}output.tex");

                  ##  system("/usr/math/bin/latex2html -init_file ${Global::mainDirectory}latex2html.init -dir $PROBDIR -prefix $psvn ${htmlDirectory}tmp/l2h/${psvn}output.tex > ${htmlDirectory}tmp/l2h/${psvn}l2h.log");
   my $latex2HTML_result = &makeL2H($TMPPROBDIR, $psvn) ;
   warn( "LaTeX2HTML failed. Returned with status: $latex2HTML_result\n" ) if $latex2HTML_result ;

   ##Get rid of all unwanted stuff in html document created by latex2html
   unless(-e "${TMPPROBDIR}${psvn}output.html") {
        warn "Can't rename ${TMPPROBDIR}${psvn}output.html";
        return (0);  ### there was a failure in latex2html processing
                     ### we just give a warning so that so that l2hPrecreateSet.pl can continue
   }

   rename("${TMPPROBDIR}${psvn}output.html","${TMPPROBDIR}${psvn}output.html.org") or
     warn "Can't rename ${TMPPROBDIR}${psvn}output.html at ". __LINE__;
   open(TEXORG, "${TMPPROBDIR}${psvn}output.html.org") or
     warn "Can't open ${TMPPROBDIR}${psvn}output.html.org";
   my @l2hOutputArray;




   BLK: {  # This is protection to make absolutely sure that the line separater is set properly.
           # It's still a mystery as to where this becomes defined to be something else.
	   local($/);
	   $/ = "\n";
	   @l2hOutputArray = <TEXORG>;


   }

   close(TEXORG);
   open(TEXNEW, ">${TMPPROBDIR}${psvn}output.html") or
     die "Can't open ${TMPPROBDIR}${psvn}output.html";


    foreach (@l2hOutputArray) {
        if($_ =~ /^<META/) {next;}
        if($_ =~ /^<!DOCTYPE HTML PUBLIC/) {next;}
        if($_ =~ /^<HTML>/) {next;}
        if($_ =~ /^<HEAD>/) {next;}
        if($_ =~ /^<TITLE>/) {next;}
        if($_ =~ /^<LINK REL/) {next;}
        if($_ =~ /^<\/HEAD>/) {next;}
        if($_ =~ /^<BODY/) {next;}
        if($_ =~ /^<\/BODY>/) {next;}
        if($_ =~ /^<\/HTML>/) {next;}
        if($_ =~ /^<BR> <HR>/) {next;}

        print TEXNEW ;
    }


    close(TEXNEW);

         ## Now do global multiline changes on whole file

    open(TEXNEW, "${TMPPROBDIR}${psvn}output.html") or
     die "Can't open ${TMPPROBDIR}${psvn}output.html";
    @l2hOutputArray = <TEXNEW>;
    close(TEXNEW);
    my $l2hOutputString = join('',@l2hOutputArray);

               ## make gif images created by latex2html locatable by server
               ## NOTE: $htmlURL is defined in webworkCourse.ph . Often this will
               ## will be a link appearing in a public_html_docs directory.
               ## The $htmlURL, any links, and the next line must be coordinated.

    $l2hOutputString =~ s|${psvn}img|${PROBURL}${psvn}img|g;

                 ## remove multiline comments
    $l2hOutputString =~ s|<!--.*?-->\n||sg;

    open(TEXNEW, ">${TMPPROBDIR}${psvn}output.html") or
     die "Can't open ${TMPPROBDIR}${psvn}output.html";
    print TEXNEW $l2hOutputString;
    close(TEXNEW);

               ## remove unneeded files

    unless ($debug) {unlink("${TMPPROBDIR}${psvn}output.html.org");}
    unless ($debug) {unlink(<${TMPPROBDIR}*images.*>);}
    unless ($debug) {unlink(<${TMPPROBDIR}.*.db>);}
    unless ($debug) {unlink(<${TMPPROBDIR}*.db>);}
    unless ($debug) {unlink(<${TMPPROBDIR}IMG_PARAMS.*>);}
    unless ($debug) {unlink(<${TMPPROBDIR}*.pl>);}
    unless ($debug) {unlink(<${TMPPROBDIR}*.css>);}
    unless ($debug) {unlink("${TMPPROBDIR}index.html");}
    unless ($debug) {unlink("${TMPPROBDIR}${psvn}output.tex");}
    unless ($debug) {unlink("${TMPPROBDIR}${psvn}l2h.log");}
    unless ($debug) {
        my @allfiles = ();
        opendir( DIRHANDLE, "$TMPPROBDIR") || warn qq/Can't read directory $TMPPROBDIR $!/;
        @allfiles = map "$TMPPROBDIR$_", grep( /^l2h/, readdir DIRHANDLE);
        closedir(DIRHANDLE);
        my $l2hTempDir = $allfiles[0];
        if (defined $l2hTempDir)  {
            unlink(<$l2hTempDir/*>);
            rmdir ($l2hTempDir);
        }
    }

               ## change permission and group on remaining files
    chmod($Global::l2h_data_permission, glob("${TMPPROBDIR}*"));
    chown(-1,$Global::numericalGroupID,glob("${TMPPROBDIR}*"));

    ## Now that all the processing has been done, rename the $TMPPROBDIR TO $PROBDIR

     rename("$TMPPROBDIR","$PROBDIR") or
    warn "Can't rename the temporary problem directory:\n $TMPPROBDIR to $PROBDIR\n at displayMacros.pl , line: " . __LINE__ ;

}


#########################################################################################################
##Subroutine that makes answers sticky in l2h mode														#
#																										#
# INPUT:		$rh_submittedAnswers	Reference to a hash containing the answers submitted			#
# 				$ra_printLines			Reference to an array containing the (HTML) text to be output	#
# 				$rh_flags				Reference to a hash containing flags; specifically a			#
# 											reference to an array containing the answer field labels	#
# 																										#
# OUTPUT:		@printLines				An array containing the (modified) text to be output			#
# 																										#
# OVERVIEW:		l2h_sticky_answers is given HTML text, a list of submitted answers, and a list of		#
# 				answer field labels. Its job is to retain the user's answers between submissions		#
# 				when in typeset mode (this is handled elsewhere in the text modes). Basically, its		#
# 				job is to act as a "filter" for the HTML text, replacing the answer fields that have	#
# 				been reset with fields containing the previously entered answers, returning the			#
# 				modified text. A brief high-level overview of the algorithm follows:					#
# 																										#
# ALGORITHM:	The references are first dereferenced. The incoming text is first joined into			#
# 				one string. It is then split up again, but not by line. Rather, the text is split		#
# 				such that each array entry is either text which can be ignored, or a single				#
# 				<INPUT...> tag. Each entry is then processed. If it is an <INPUT> tag, then it			#
# 				must be checked for the presence of each answer field label for which a value was		#
#				submitted (there are many <INPUT> fields which are not answer fields, so we can't		#
#				assume that consecutive	<INPUT> fields correspond to consecutive answer labels).		#
#				If a label is found, the blank value space is replaced with the appropriate				#
#				submitted answer (note that we can assume that there is a one-to-one correspondence		#
#				between answer labels and submitted answers; this is guaranteed by the specs). Radio	#
#				buttons and checkboxes are handled specially; see below. The modified text is then		#
#				added to the output string, which is split on a placeholder such that the output		#
#				array has the same number of entries as the input array (this is not required, but		#
#				might avoid some subtle bug in the future).												#
# 																										#
# NOTE:			The specifications seem to require that the input text array consist of one				#
# 				field for each line of text. However, it appears that the input is actually one			#
# 				field, with newline characters separating lines. This function should accept			#
# 				either form of input, although the "correct" form of one field per line has not			#
# 				been tested. It is possible that, if input is received in this form AND the				#
# 				newline characters have been truncated, the output could be garbled.					#
#																										#
#																			--David Etlinger 6/7/2000	#
#																										#
# ADDED:		Added a few lines of code to properly handle radio buttons. Checkboxes still need		#
#				to be implemented.																		#
#																			--David Etlinger 6/14/2000	#
#																										#
# ADDED:		Added code to handle checkboxes. This is complicated because the submitted checkboxes	#
#				are originally stored as a single string with "\0" as a delimiter. If the input type	#
#				is determined to be checkboxes, the string is first split into an array. A hash key		#
#				in a special checkbox array is then made to point to the array. This is done because	#
#				there might be more than one checkbox set in a single question. Each time an input line	#
#				of type checkbox appears, the next value in this array is popped into a temp variable.	#
#				If it is determined that the line being processed corresponds to this value, the line	#
#				is processed (made "sticky"); otherwise, the value is pushed back on the array. The		#
#				fact that the number of checked cehckboxes is known but the total number of checkboxes	#
#				is not means that a given line of input type checkbox might or might not correspond		#
#				to the next value in the checkbox array. (I hope this explanation is clear enough!)		#
#																			--David Etlinger 6/28/2000	#
#########################################################################################################

sub l2h_sticky_answers {
	my ( $rh_submittedAnswers, $ra_printLines, $rh_flags ) = @_;

	#warn ("rh_submittedAnswers = \@rh_submittedAnswers");
	#warn ("ra_printLines = \@{ra_printLines}");
	#warn ("rh_flags = \@{rh_flags}");

	my %submittedAnswers = %{$rh_submittedAnswers};
	my @printLines = @{$ra_printLines};
	my @answerLabels = @{$rh_flags -> {ANSWER_ENTRY_ORDER}};

	my $line;					# holds the text of each line
	my $label;					# holds each answer label
	my $counter = 0;			# holds the index of the current answer
	my $output;					# holds the text the subroutine returns

	my $answer_value;

	my %checkboxAns;			# holder for the checkbox multi-part answers
	my $nextCheckboxAns;		# temp holder for the next checkbox answer to be processed

	my $placeholder = "\x253";	# unused hex character to join text lines with

	#first, convert the array of text lines to one string...
	my $text = join( "$placeholder", @printLines );

	#then, split it such that a line consists of either text
	#or a single <INPUT> tag (case insensitive; note also that
	#whitespace within the <INPUT> tag is accounted for).
	#	NOTE -- the regular expression searches for "<", then any
	#	amount of whitespace, then "INPUT", then any number of
	#	characters that aren't ">", then ">". I think that instead of
	#	searching for characters that aren't ">", I could have instead
	#	searched to match a minimal number of characters (using ?), and
	#	then ">". I don't know regular expressions well enough to tell
	#	if this might lead to some subtle difference.
	my @textLines = split( m|(<\s*INPUT[^>]*>)|is, $text );
	#my @textLines = split( m|(<\s*INPUT.*?>)|is, $text );

	foreach $line ( @textLines ) {
		if( $line =~ m|<\s*INPUT|i ) {
			foreach $label ( @answerLabels ) {
			    next unless exists( $submittedAnswers{$label} );  # skip if no answer was submitted.
				if( $line =~ m|NAME\s*=\s*"$label"|i ) {
					if( $line =~ m|TYPE\s*=\s*RADIO|i ) {			#handle radio buttons
						$line =~ s|VALUE\s*=\s*"$submittedAnswers{$label}"|VALUE = "$submittedAnswers{$label}" CHECKED|i;
					}
					elsif( $line =~ m|TYPE\s*=\s*CHECKBOX|i ) {
						#make the hash key point to an anonymous array
						$checkboxAns{$label} = [ split( "\0", $submittedAnswers{$label} ) ] if not exists( $checkboxAns{$label} );
						if( defined $checkboxAns{$label}[0] ) {
							$nextCheckboxAns = shift @{$checkboxAns{$label}};
							if( $line !~ s|VALUE\s*=\s*"$nextCheckboxAns"|VALUE = "$nextCheckboxAns" CHECKED|i ) {
								unshift( @{$checkboxAns{$label}}, $nextCheckboxAns );		#put the unused answer back on the list
							}
						}
					}
					else {
						 # we'll assume this is something else, like one or more fields.
						 # if it's several fields, we need to take only one answer at a time
						 # \0 are used to delimeter between entries.
						 if ($submittedAnswers{$label} =~ /\0/ ) {
    							my @answers = split("\0", $submittedAnswers{$label});
    							$answer_value = shift(@answers);  # use up the first answer
    							$submittedAnswers{$label}=join "\0", @answers;  # store the rest
    							$answer_value= '' unless defined($answer_value);

						  }
						  else {
						  $answer_value = $submittedAnswers{$label};
						}

						$line =~ s|VALUE\s*=\s*""|VALUE = "$answer_value"|i;
					}
				}
			}
		}									#end if test for "<INPUT"

		$output .= $line;
	}										#end foreach

	@printLines = split( m|$placeholder|, $output );
	return @printLines;
}											#end l2h_sticky_answers()

## This is the old system (but newer than the one below).
## It has been replaced for two reasons:
## 1) It is complicated and difficult to understand or modify
## 2) It does not work for several situations that rarely come up,
##    but must be handled properly. Specifically, it doesn't handle
##    text with more than one <INPUT> tag on a given line very well.
##    there are probably other problems, but that is the biggest.
##																--DME 6/7/2000
# 		# the following doubly nested loop iterates over each line,
# 		# and for each line searches for each answer label. Technically,
# 		# it might have been faster to join each entry in @printlines
# 		# into one string, search on that, and split it back up, but I
# 		# felt that the slight theoretical speed gain was not worth the
# 		# added complexity.
# 		warn "answerLabels = @answerLabels";	#DEBUG
# 		foreach $line ( @printLines ) {
# 			warn "Line is $line";		#DEBUG
# 			foreach $label ( @answerLabels ) {
# 				if( $line =~ m|<INPUT TYPE=TEXT.*NAME="$label| ) {
# 					while ($line =~ /VALUE = ""/) {
# 						# Put trailing space in displayed answer so that while loop will
# 						# always end.  We are using the form of the s/// operator which
# 						# evaluates its right hand side
# 						$line =~ s|NAME="$label" VALUE = ""|
# 							$counter++;
# 							$submittedAnswers[$counter]=" " unless defined ($submittedAnswers[$counter])
# 								&& not $submittedAnswers[$counter] =~ /^\s*$/;
# 							qq{ NAME="$label" VALUE = "$submittedAnswers[$counter]" } |e;
# 						# This insures that in VALUE = "$submittedAnswers[$counter]"
# 						# the quantity $submittedAnswers[$counter]
# 						# is never empty. This is required in order to terminate the loop.
# 					}								#end while
# 					push( @output, $line );
# 				}									#end if
# 				else {
# 					push( @output, $line );
# 				}
# 			}										#end foreach over @answerLabels
# 		}											#end foreach over @printLines
#
# 		@printLines = @output;
# 	}												#end outer if
#
# 	return @printLines;
# }													#end l2h_sticky_answers()

##subroutine that makes answers sticky in l2h mode
# this is an old version of this routine, which assumes (incorrectly)
# that answer labels begin with "AnSwEr". I've left it here just in case...
# DME 6/6/2000
#sub l2h_sticky_answers {
#	my ($refSubmittedAnswers, $refprintlines)=@_;
#	my @printlines=@$refprintlines;
#	if ((@{$refSubmittedAnswers}!=0)) {
#		my $line;
#		my @output=();
#		foreach $line (@printlines) 	{
#			if  ($line =~ m|<INPUT TYPE=TEXT.*NAME="AnSwEr|)	{
#				#print "<P>line doesn't exists<P>\n" unless defined($line);
#				while ($line =~ /VALUE = ""/) {
#					## Put trailing space in displayed answer so that while loop will
#					## always end.  We are using the form of the s/// operator which evaluates its right hand side
#					$line =~ s|NAME="AnSwEr(\d*)" VALUE = ""|
#						my $tttemp = $1;
#						${$refSubmittedAnswers}[$tttemp-1]=" " unless defined (${$refSubmittedAnswers}[$tttemp-1])
#							&&  not ${$refSubmittedAnswers}[$tttemp-1] =~ /^\s*$/;
#
#						qq{ NAME="AnSwEr$tttemp" VALUE = "${$refSubmittedAnswers}[$tttemp-1]" } |e;
#					# This insures that in VALUE = "${$refSubmittedAnswers}[$tttemp-1]" the quantity ${$refSubmittedAnswers}[$tttemp-1]
#					# is never empty.  This is required in order to terminate the loop.
#				}
#				push(@output, $line);
#			}
#			else {
#				push(@output, $line);
#			}
#		}
#
#		@printlines = @output;
#	}
#
#	@printlines;
#}

##subroutine that updates current keys in the l2h mode

# sub l2h_update_keys {
#         my ($sessionKey, $refprintlines)= @_;
#         my @printlines=@$refprintlines;
#         my $line;
#         my @output=();
# 	#my $sessionKey = $main::sessionKey;
# 	warn "hi lines = ",join("",@printlines);
#    	foreach $line (@printlines) 	{
# 		if  ($line =~ m|^\s*<A(.*?)\&key=[^&]*&user|)	{  #<A.*&key=.*?&user
# 			#grab the session key from the CGI input or make it blank
# 			$line =~ s|^\s*<A(.*?)&key=[^&]*&user|<A$1&key=$sessionKey&user|;
# 			warn "line = $line<BR>";
# 			push(@output, $line);
# 		}else{
# 			push(@output, $line);
# 		}
#
#         }
#         @printlines;
#
# }


sub makeL2H {
	my ($TMPPROBDIR,$psvn) =@_;
	$ENV{PATH} .= "$Global::extendedPath";
	if($Global::externalLaTeX2HTMLVersion eq "98.1p1") {
		system("$Global::externalLaTeX2HTMLPath -no_math -init_file $Global::externalLaTeX2HTMLInit -dir $TMPPROBDIR -prefix $psvn $TMPPROBDIR${psvn}output.tex > $TMPPROBDIR${psvn}l2h.log 2>&1");
	} elsif($Global::externalLaTeX2HTMLVersion eq "96.1") {
		system("$Global::externalLaTeX2HTMLPath -init_file $Global::externalLaTeX2HTMLInit -dir $TMPPROBDIR -prefix $psvn $TMPPROBDIR${psvn}output.tex > $TMPPROBDIR${psvn}l2h.log");
	} else {
		die "Unknown LaTeX2HTML version: \$Global::externalLaTeX2HTMLVersion = $Global::externalLaTeX2HTMLVersion";
	}
}

1;
