#!/usr/bin/perl -w

################################################################################
# WeBWorK Online Homework Delivery System
# Copyright © 2000-2017 The WeBWorK Project, http://openwebwork.sf.net/
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

standalonePGproblemRenderer.pl

=head1 DESCRIPTION


This module provides functions for rendering html from files outside the normal
context of providing a webwork homework set user  an existing problem set.

It can be used to create a live version of a single problem, one that is not
part of any set, and can facilitate editing these problems outside of the
context of WeBWorK2.  For directories each .pg file under that
directory is rendered.

The results can be displayed in a browser (use -b or -B switches) as was
done with renderProblem.pl, on the command line (Use -h or -H switches) as
was done with renderProblem_rawoutput.pl or summary information about whether the
problem was correctly rendered can be sent to a log file (use -c or C switches).

The capital letter switches, -B, -H, and -C render the question twice.  The first
time returns an answer hash which contains the correct answers. The question is
then resubmitted to the renderer with the correct answers filled in and displayed.

This script behaves similarly to sendXMLRPC.pl but does not require
a credentials file.  It does require a local WeBWorK site on the
same computer.

=cut

=head1    SYNOPSIS

	standalonePGproblemRenderer -vcCbB input.pg

=head1   DETAILS

=head2 credentials file
	No local configuration file is needed for this client.








=cut

=head2 Options

=over 4

=item  -a

	Displays the answer hashes returned by the question on the command line.

=item  -A

	Same as -a but renders the question with the correct answers submitted.

=item  -b

	Display the rendered question in a browser (specified by the DISPLAY_HTML_COMMAND variable).

=item  -B

	Same as -b but renders the question with the correct answers submitted.
	The evaluation of the answer submitted is displayed as well as the correct
	answer.

=item  -h

	Prints to STDOUT the entire object returned by
    the webwork_client xmlrpc request.
    This includes the answer information displayed by -a and -A and much more.

=item  -H

	Same as -h but renders the question with the correct answers submitted

=item	-c

	"check" -- Record success or failure of rendering the question to a log file.

=item	-C

	Same as -c but the question is rendered with the correct answers submitted.
    This succeeds only if the correct answers, as determined from the answer hash, all succeed.

=item	 f=s

	Specify the format used by the browser in displaying the question.
         Choices for s are
         standard
         sticky
         debug
         simple


=item	-v

	Verbose output. Used mostly for debugging.
    In particular it displays explicitly the correct answers
    which are (will be)  submitted to the question.

=item   -e
	Open the source file in an editor.

=item   --tex
	Process question in TeX mode and output to the command line

=item   --pdf
	Process question in TeX mode, convert to PDF and display.

=item

	The single letter options can be "bundled" e.g.  -vcCbB

=item  --list   pg_list
	Read and process a list of .pg files contained in the file C<pg_list>.  C<pg_list>
	consists of a sequence of lines each of which contains the full path to a pg
	file that should be processed. (For example this might be the output from an
	earlier run of sendXMLRPC using the -c flag. )

=item	--pg

	Triggers the printing of the all of the variables available to the PG question.
    The table appears within the question content. Use in conjunction with -b or -B.

=item	--anshash

	Prints the answer hash for each answer in the PG_debug output which appears below
    the question content. Use in conjunction with -b or -B.
    Similar to -a or -A but the output appears in the browser and
    not on the command line.

=item	--ansgrp

	Prints the PGanswergroup for each answer evaluator. The information appears in
    the PG_debug output which follows the question content.  Use in conjunction with -b or -B.
    This contains more information than printing the answer hash. (perhaps too much).

=item   --resource

	Prints the resources used by the question. The information appears in
    the PG_debug output which follows the question content.  Use in conjunction with -b or -B.

=item	--credentials=s

 	Specifies a file s where the  credential information can be found.

=item	--help

       Prints help information.

=item  --log
       Sets path to log file

=back
=cut

use strict;
use warnings;

my $pg_dir;

BEGIN {
	$pg_dir = $ENV{PG_ROOT};
	die "The pg directory must be defined in PG_ROOT" unless (-e $pg_dir);
}

use lib "$pg_dir/lib";

use Carp;
use Time::HiRes qw/time/;
use MIME::Base64 qw( encode_base64 decode_base64);
use Getopt::Long qw[:config no_ignore_case bundling];
use File::Find;
use FileHandle;
use Cwd 'abs_path';
use FormatRenderedProblem;
use Proc::ProcessTable;

use 5.10.0;
$Carp::Verbose = 1;

# the remainder are all in the PG directory
use WeBWorK::PG::ImageGenerator;
use PGUtil qw(pretty_print not_null);
use WeBWorK::PG;
use MockDB::User;
use MockDB::Set;
use MockDB::Problem;
use vars qw($courseName);

use Data::Dumper;

use PGEnvironment;

my $pg_env = new PGEnvironment(course_name => 'staab_course');

#############################################
# Configure displays for local operating system
#############################################

### verbose output when UNIT_TESTS_ON =1;
our $UNIT_TESTS_ON = 0;

#Default display commands.
use constant HTML_DISPLAY_COMMAND => "open -a 'Google Chrome' ";    # (MacOS command)
use constant HASH_DISPLAY_COMMAND => "";                            # display tempoutputfile to STDOUT

### Path to a temporary file for storing the output of sendXMLRPC.pl
my $TEMPOUTPUTDIR = $pg_env->{directories}->{temp_dir};

die "You must make the directory $TEMPOUTPUTDIR writeable " unless -w $TEMPOUTPUTDIR;
my $TEMP_HTML = "$TEMPOUTPUTDIR/temporary_output.html";

### Default path to a temporary file for storing the output
### of standalonePGproblemRenderer.pl
my $LOG_FILE = $pg_env->{environment}->{log}->{output};

### Command for editing the pg source file in the browswer
use constant EDIT_COMMAND => "bbedit";    # for Mac BBedit editor (used as `EDIT_COMMAND() . " $file_path")

### Command for editing and viewing the tex output of the pg question.
use constant TEX_DISPLAY_COMMAND => "open -a 'TeXShop'";

### Command for editing and viewing the tex output of the pg question.
use constant PDF_DISPLAY_COMMAND => "open -a 'Preview'";

### set display mode
use constant DISPLAYMODE => 'MathJax';
use constant PROBLEMSEED => '987654321';

############################################################
# End configure displays for local operating system
############################################################

############################################################
# Read command line options
############################################################

my $display_ans_output1  = '';
my $display_hash_output1 = '';
my $display_html_output1 = '';
my $record_ok1           = '';    # subroutine needs to be constructed
my $display_ans_output2  = '';
my $display_hash_output2 = '';
my $display_html_output2 = '';
my $record_ok2           = '';
my $verbose              = '';
my $credentials_path;
my $format             = 'standard';
my $edit_source_file   = '';
my $display_tex_output = '';
my $display_pdf_output = '';
my $print_answer_hash;
my $print_answer_group;
my $print_pg_hash;
my $print_resource_hash;
my $print_help_message;
my $read_list_from_this_file;
my $path_to_log_file;
GetOptions(
	'a'             => \$display_ans_output1,
	'A'             => \$display_ans_output2,
	'b'             => \$display_html_output1,
	'B'             => \$display_html_output2,
	'h'             => \$display_hash_output1,
	'H'             => \$display_hash_output2,
	'c'             => \$record_ok1,                  # record_problem_ok1 needs to be written
	'C'             => \$record_ok2,
	'v'             => \$verbose,
	'e'             => \$edit_source_file,
	'tex'           => \$display_tex_output,
	'pdf'           => \$display_pdf_output,
	'list=s'        => \$read_list_from_this_file,    # read file containing list of full file paths
	'pg'            => \$print_pg_hash,
	'anshash'       => \$print_answer_hash,
	'ansgrp'        => \$print_answer_group,
	'resource'      => \$print_resource_hash,
	'f=s'           => \$format,
	'credentials=s' => \$credentials_path,
	'help'          => \$print_help_message,
	'log=s'         => \$path_to_log_file,
);

print_help_message() if $print_help_message;

############################################################
# End Read command line options
############################################################

####################################################
# get credentials
####################################################

# no credentials are needed for this client since connects directly to PG
# our %credentials= ();

# credentials file location -- no credentials needed for the standalone version.

#allow credentials to overrride the default displayMode
#and the browser display -- credentials not used in standalonePGproblemRenderer
our $HTML_DISPLAY_COMMAND = HTML_DISPLAY_COMMAND();
our $HASH_DISPLAY_COMMAND = HASH_DISPLAY_COMMAND();
our $DISPLAYMODE          = DISPLAYMODE();
our $TEX_DISPLAY_COMMAND  = TEX_DISPLAY_COMMAND();
our $PDF_DISPLAY_COMMAND  = PDF_DISPLAY_COMMAND();

##################################################
#  END gathering credentials -- No credentials needed for standalone rendering
##################################################

##################################################
# create course environment and create log files
##################################################

# Find the library directories for
# ww_opaque_server, pg and webwork2
# and place them in the search path for modules

#our $seed_ce = create_course_environment();
# my $dbLayout = $seed_ce->{dbLayout};
# our $db = WeBWorK::DB->new($dbLayout);
# FIXME -- can we create minimal local versions of $seed_ce and $db so that no modules from
# webwork2/lib are required? only objects from pg/lib

$path_to_log_file = $path_to_log_file // $LOG_FILE;    #set log file path.

eval {    # attempt to create log file
	local (*FH);
	open(FH, '>>', $path_to_log_file) or die "Can't open file $path_to_log_file for writing";
	close(FH);
};

die "You must first create an output file at $path_to_log_file
     with permissions 777 " unless -w $path_to_log_file;

##################################################
#  set default inputs for the problem
##################################################

############################################
# Build  PG question defaults
############################################

my $default_input = {

};

my $default_form_data = {
	displayMode  => $DISPLAYMODE,
	outputformat => $format // 'standard',
	problemSeed  => PROBLEMSEED(),
};

##################################################
#  end PG question defaults
##################################################

##################################################
#  MAIN SECTION gather and process problem template files
##################################################
my $cg_start = time;    # this is Time::HiRes's time, which gives floating point values

our @files_and_directories = @ARGV;
# print "files ", join("|", @files_and_directories), "\n";
if ($read_list_from_this_file) {
	# read a datafile containing list of files to be processed
	my $FH = FileHandle->new(" < $read_list_from_this_file");
	while (<$FH>) {
		my $item = $_;
		chomp($item);
		my $file_path = abs_path($item);
		unless (defined $file_path and -f $file_path) {
			warn "skipping $item\n" unless defined $file_path;
			warn "skipping $file_path\n" if defined $file_path;
			next;
		}
		next if $file_path     =~ /^\s*#/;    # comment lines
		next unless $file_path =~ /\.pg$/;
		next if $file_path =~ /\-text\.pg$/;
		next if $file_path =~ /header/i;
		process_pg_file($file_path);
	}
	FileHandle::close($FH);

} else {
	foreach my $item (@files_and_directories) {
		if (-d $item) {                       # if the item is a directory traverse the tree
			my $dir = abs_path($item);
			find(\&wanted, ($dir));
		} elsif (-f $item) {                  # if the item is a file process it.
			my $file_path = abs_path($item);
			next unless $file_path =~ /\.pg$/;
			next if $file_path =~ /\-text\.pg$/;
			next if $file_path =~ /header/i;
			process_pg_file($file_path);
		} else {
			print "$item cannot be found or read\n";
		}
	}
}

sub wanted {
	return '' unless $File::Find::name =~ /\.pg$/;
	return '' if $File::Find::name =~ /\-text\.pg$/;
	return '' if $File::Find::name =~ /header/i;
	eval { process_pg_file($File::Find::name) if -f $File::Find::name; };
	warn "Error in processing $File::Find::name: $@" if $@;
}

##########################################################
#  Subroutines
##########################################################

#######################################################################
# Process the pg file
#######################################################################

sub process_pg_file {
	my $file_path    = shift;
	my $NO_ERRORS    = "";
	my $ALL_CORRECT  = "";
	my $problemSeed1 = 1112;
	my $form_data1   = { %$default_form_data, problemSeed => $problemSeed1 };
	if ($display_tex_output or $display_pdf_output) {
		my $form_data2 = {
			%$form_data1,
			displayMode  => 'tex',
			outputformat => 'tex',
		};
		print "process tex files\n";
		my ($error_flag, $formatter, $error_string) = process_problem($file_path, $default_input, $form_data2);
		display_tex_output($file_path, $formatter) if $display_tex_output;
	}
	my ($error_flag, $formatter, $error_string) = process_problem($file_path, $default_input, $form_data1);
	# extract and display result
	#print "display $file_path\n";
	edit_source_file($file_path)                                         if $edit_source_file;
	display_html_output($file_path, $formatter)                          if $display_html_output1;
	display_hash_output($file_path, $formatter)                          if $display_hash_output1;
	display_ans_output($file_path, $formatter)                           if $display_ans_output1;
	$NO_ERRORS = record_problem_ok1($error_flag, $formatter, $file_path) if $record_ok1;

	unless ($display_html_output2 or $display_hash_output2 or $display_ans_output2 or $record_ok2) {
		print "DONE -- $NO_ERRORS -- \n" if $verbose;
		return;
	}
	#################################################################
	# Extract correct answers
	#################################################################

	my %correct_answers                    = ();
	my $some_correct_answers_not_specified = 0;
	foreach my $ans_id (keys %{ $formatter->return_object->{answers} }) {
		my $ans_obj = $formatter->return_object->{answers}->{$ans_id};
		# the answergrps are in PG_ANSWERS_HASH
		my $answergroup    = $formatter->return_object->{PG_ANSWERS_HASH}->{$ans_id};
		my @response_order = @{ $answergroup->{response}->{response_order} }
			if defined($answergroup->{response}->{response_order});
		@response_order = @response_order // ();    #hack to ensure this is defined.
			# print scalar(@response_order), " first response $response_order[0] $ans_id\n";

		$ans_obj->{type} = $ans_obj->{type} // '';    #make sure it's defined.
		if ($ans_obj->{type} eq 'MultiAnswer') {
			# singleResponse multianswer type
			# an outrageous hack
			print "handling MultiAnswer singleResponse type\n" if $verbose;
			my $ans_str1   = $ans_obj->{correct_ans};
			my @ans_array1 = split(/\s*;\s*/, $ans_str1);
			$correct_answers{$ans_id} = shift @ans_array1;
			my $num_extra_elements = scalar(@ans_array1);
			foreach my $i (1 .. $num_extra_elements) {    # pick up the remaining blanks
				my $response_id = "MuLtIaNsWeR_${ans_id}_${i}";    #MuLtIaNsWeR_AnSwEr0003_1
				$correct_answers{$response_id} = shift @ans_array1;
				#print "\t\t $response_id => $correct_answers{$response_id}\n";
			}
		} elsif ($ans_obj->{type} =~ /checkbox/i) {    #type is probably checkbox_cmp
			my $ans_str = $ans_obj->{correct_ans};     #an unseparated answer string
			$ans_str =~ s/^\s*//;
			$ans_str =~ s/\s*$//;                      #trim white space off ends (probably unnecessary)
			my @temp        = split("", $ans_str);     #split into array of characters
			my $new_ans_str = join("\0", @temp);       # join them in "packed" form separated with nulls
			$correct_answers{$ans_id} = $new_ans_str;
		} elsif (1 == @response_order and $ans_id eq $response_order[0]) {
			# only one response -- not MultiAnswer singleResponse
			# most answers are of this type
			# should we use correct answer or correct value?  -- this seems to vary
			#warn "just one answer blank for this answer evaluator";
			$correct_answers{$ans_id} = ($ans_obj->{correct_ans}) // ($ans_obj->{correct_value});
		} else {    # more than one response
			if ($ans_obj->{type} =~ /Matrix/) {
				#FIXME -- another outrageous hackkkk but it works
				#print "responding to matrix answer with several ans_blanks\n";
				#print "responses", join(" ", %{$answergroup->{response}->{responses}}),"\n";
				#print "correct answer ", $ans_obj->{correct_value}, "\n";
				my $ans_str = ($ans_obj->{correct_ans}) // ($ans_obj->{correct_value});
				$ans_str =~ s/\[//g;
				$ans_str =~ s/\]//g;
				my @ans_array = split(/\s*,\s*/, $ans_str);
				foreach my $response_id (@response_order) {
					$correct_answers{$response_id} = shift @ans_array;
				}
			} else {
				warn "responding to an answer evaluator of type |"
					. $ans_obj->{type}
					. "|  with "
					. scalar(@response_order)
					. " ans_blanks: ", join(" ", @response_order), "\n"
					if $UNIT_TESTS_ON;
				$correct_answers{$ans_id} = ($ans_obj->{correct_ans}) // ($ans_obj->{correct_value}) // '';
			}
		}
		#FIXME  hack to get rid of html protection of < and > for vectors
		$correct_answers{$ans_id} =~ s/&gt;/>/g;
		$correct_answers{$ans_id} =~ s/&lt;/</g;
		$correct_answers{$ans_id} =~ s|<br\s*/>||g;    # some answers have breaks in them for clarity
		if ($correct_answers{$ans_id} eq "No correct answer specified") {
			warn "this question has an answer blank with no correct answer specified";
			$some_correct_answers_not_specified++;
		}

	}    #end loop collecting correct answers.

	say "display the correct answers here" if $verbose;
	display_inputs(%correct_answers)       if $verbose;    # choice of correct answers submitted
		# should this information on what answers are being submitted have an option switch?

	# adjust input and reinitialize form_data
	my $form_data2 = {
		%$default_form_data,
		problemSeed      => $problemSeed1,
		answersSubmitted => 1,
		WWsubmit         => 1,               # grade answers
		WWcorrectAns     => 1,               # show correct answers
		%correct_answers
	};

	my $pg_start = time;                     # this is Time::HiRes's time, which gives floating point values

	($error_flag, $formatter, $error_string) = ();
	($error_flag, $formatter, $error_string) = process_problem($file_path, $default_input, $form_data2);
	my $pg_stop     = time;
	my $pg_duration = $pg_stop - $pg_start;

	display_html_output($file_path, $formatter) if $display_html_output2;
	display_hash_output($file_path, $formatter) if $display_hash_output2;
	display_ans_output($file_path, $formatter)  if $display_ans_output2;
	$ALL_CORRECT =
		record_problem_ok2($error_flag, $formatter, $file_path, $some_correct_answers_not_specified, $pg_duration)
		if $record_ok2;
	print "display the correct answers here";
	display_inputs(%correct_answers) if $verbose;    # choice of correct answers submitted
		# should this information on what answers are being submitted have an option switch?

	print "DONE -- $NO_ERRORS -- $ALL_CORRECT\n" if $verbose;
}

#######################################################################
# Auxiliary subroutines
#######################################################################

sub process_problem {
	my $file_path = shift;
	my $input     = shift;
	my $form_data = shift;
	# %credentials is global

	say "in process_problem";

	### get source and correct file_path name so that it is relative to templates directory

	my ($adj_file_path, $source) = get_source($file_path);
	#print "find file at $adj_file_path ", length($source), "\n";

	### update inputs
	my $problemSeed = $form_data->{problemSeed};
	die "problem seed not defined in standAlonePGproblemRenderer::process_problem" unless $problemSeed;

	my $displayMode = $form_data->{displayMode};
	my $inputs_ref  = { %$input, %$form_data };
	$inputs_ref->{envir}{fileName}       = $adj_file_path;
	$inputs_ref->{envir}{probFileName}   = $adj_file_path;
	$inputs_ref->{envir}{sourceFilePath} = $adj_file_path;
	$inputs_ref->{envir}{problemSeed}    = $problemSeed;

	$form_data->{showAnsGroupInfo} = $print_answer_group;
	$form_data->{showAnsHashInfo}  = $print_answer_hash;
	$form_data->{showPGInfo}       = $print_pg_hash;
	$form_data->{showResourceInfo} = $print_resource_hash;

	##################################################
	# Process the pg file
	##################################################
	### store the time before we invoke the content generator
	my $cg_start = time;    # this is Time::HiRes's time, which gives floating point values

	############################################
	# Submit through subroutine standaloneRenderer to render problem
	############################################

	our ($return_object, $error_flag, $error_string);
	$error_flag   = 0;
	$error_string = '';

	my $memory_use_start = get_current_process_memory();
	$return_object = standaloneRenderer(\$source, $input, $form_data);    # PGcore object
		# the call to standaloneRenderer destroys $input and $form_data for some reason

	#######################################################################
	# Handle errors
	#######################################################################

	print "\n\n Result of renderProblem \n\n" if $UNIT_TESTS_ON;
	print pretty_print_rh($return_object)     if $UNIT_TESTS_ON;
	if (not defined $return_object) {    #FIXME make sure this is the right error message if site is unavailable
		$error_string = "0\t Could not process $file_path problem file \n";
	} elsif (defined($return_object->{flags}->{error_flag}) and $return_object->{flags}->{error_flag}) {
		$error_string = "0\t $file_path has errors\n";
	} elsif (defined($return_object->{errors}) and $return_object->{errors}) {
		$error_string = "0\t $file_path has syntax errors\n";
	}
	$error_flag = 1 if $return_object->{errors};

##################################################
	# Create FormatRenderedProblems object
##################################################

	#my $encoded_source = encode_base64($source); # create encoding of source_file;
	my $formatter = FormatRenderedProblem->new(
		return_object   => $return_object,
		encoded_source  => encode_base64($source),
		sourceFilePath  => $file_path,
		url             => 'https://hosted2.webwork.rochester.edu',                     # use default hosted2
		form_action_url => 'https://hosted2.webwork.rochester.edu/webwork2/html2xml',
		maketext        => sub { return @_ },
		courseID        => 'daemon_course',
		userID          => 'daemon',
		course_password => 'daemon',
		inputs_ref      => $inputs_ref,
	);
	##################################################
	# log elapsed time
	##################################################
	my $scriptName     = 'standalonePGproblemRenderer';
	my $cg_end         = time;
	my $cg_duration    = $cg_end - $cg_start;
	my $memory_use_end = get_current_process_memory();
	my $memory_use     = $memory_use_end - $memory_use_start;
	# WebworkClient::writeRenderLogEntry(
	# 	"",
	# 	"{script:$scriptName; file:$file_path; "
	# 		. sprintf("duration: %.3f sec;", $cg_duration)
	# 		. sprintf(" memory: %6d bytes;", $memory_use) . "}",
	# 	''
	# );

	#######################################################################
	# End processing of the pg file
	#######################################################################

	return $error_flag, $formatter, $error_string;
}

sub display_tex_output {
	my $file_path   = shift;
	my $formatter   = shift;
	my $output_text = $formatter->formatRenderedProblem;
	$file_path =~ s|/$||;             # remove final /
	$file_path =~ m|/?([^/]+)$|;
	my $file_name = $1;
	$file_name =~ s/\.\w+$/\.tex/;    # replace extension with tex
	my $output_file = TEMPOUTPUTDIR() . $file_name;
	local (*FH);
	open(FH, '>', $output_file) or die "Can't open file $output_file for writing";
	print FH $output_text;
	close(FH);
	print "tex result sent to $output_file\n" if $UNIT_TESTS_ON;

	if ($display_pdf_output) {
		print "pdf mode\n";
		my $pdf_file_name = $file_name;
		$pdf_file_name =~ s/\.\w+$/\.pdf/;    # replace extension with pdf
		my $pdf_path = TEMPOUTPUTDIR() . $pdf_file_name;
		print "pdflatex $output_file\n";
		system("pdflatex $output_file");
		print "pdflatex to $pdf_path DONE\n";
		# this is doable but will require changing directories
		# look at the solution done using hardcopy
		system("open -a Preview " . $pdf_path);
	} else {
		system($TEX_DISPLAY_COMMAND. " " . $output_file);
	}
	#	sleep 5;   #wait 5 seconds
	#	unlink($output_file);

}

sub display_html_output {    #display the problem in a browser
	my $file_path   = shift;
	my $formatter   = shift;
	my $output_text = $formatter->formatRenderedProblem;
	$file_path =~ s|/$||;              # remove final /
	$file_path =~ m|/?([^/]+)$|;
	my $file_name = $1;
	$file_name =~ s/\.\w+$/\.html/;    # replace extension with html
	my $output_file = TEMPOUTPUTDIR() . $file_name;
	local (*FH);
	open(FH, '>', $output_file) or die "Can't open file $output_file for writing";
	print FH $output_text;
	close(FH);

	system($HTML_DISPLAY_COMMAND. " " . $output_file);
	sleep 1;                           #wait 1 seconds
	unlink($output_file);
}

sub display_hash_output {    # print the entire hash output to the command line
	my $file_path   = shift;
	my $formatter   = shift;
	my $output_text = $formatter->formatRenderedProblem;
	$file_path =~ s|/$||;             # remove final /
	$file_path =~ m|/?([^/]+)$|;
	my $file_name = $1;
	$file_name =~ s/\.\w+$/\.txt/;    # replace extension with html
	my $output_file  = TEMPOUTPUTDIR() . $file_name;
	my $output_text2 = pretty_print_rh($output_text);
	print STDOUT $output_text2;

	# 	local(*FH);
	# 	open(FH, '>', $output_file) or die "Can't open file $output_file writing";
	# 	print FH $output_text2;
	# 	close(FH);
	#
	# 	system(HASH_DISPLAY_COMMAND().$output_file."; rm $output_file;");
	#sleep 1; #wait 1 seconds
	#unlink($output_file);
}

sub display_ans_output {    # print the collection of answer hashes to the command line
	my $file_path     = shift;
	my $formatter     = shift;
	my $return_object = $formatter->return_object;
	$file_path =~ s|/$||;             # remove final /
	$file_path =~ m|/?([^/]+)$|;
	my $file_name = $1;
	$file_name =~ s/\.\w+$/\.txt/;    # replace extension with html
	my $output_file = TEMPOUTPUTDIR() . $file_name;
	my $output_text = pretty_print_rh($return_object->{answers});
	print STDOUT $output_text;
	# 	local(*FH);
	# 	open(FH, '>', $output_file) or die "Can't open file $output_file writing";
	# 	print FH $output_text;
	# 	close(FH);
	#
	# 	system(HASH_DISPLAY_COMMAND().$output_file."; rm $output_file;");
	# 	sleep 1; #wait 1 seconds
	# 	unlink($output_file);
}

sub record_problem_ok1 {
	my $error_flag    = shift // '';
	my $formatter     = shift;                       # for formatting
	my $file_path     = shift;
	my $return_string = '';
	my $return_object = $formatter->return_object;
	if (defined($return_object->{flags}->{DEBUG_messages})) {
		my @debug_messages = @{ $return_object->{flags}->{DEBUG_messages} };
		$return_string .= (pop @debug_messages) || '';    #avoid error if array was empty
		if (@debug_messages) {
			$return_string .= join(" ", @debug_messages);
		} else {
			$return_string = "";
		}
	}
	if (defined($return_object->{errors})) {
		$return_string = $return_object->{errors};
	}
	if (defined($return_object->{flags}->{WARNING_messages})) {
		my @warning_messages = @{ $return_object->{flags}->{WARNING_messages} };
		$return_string .= (pop @warning_messages) || '';    #avoid error if array was empty
		$@ = undef;
		if (@warning_messages) {
			$return_string .= join(" ", @warning_messages);
		} else {
			$return_string = "";
		}
	}
	my $SHORT_RETURN_STRING = ($return_string) ? "has errors" : "ok";
	unless ($return_string) {
		$return_string = "1\t $file_path is ok\n";
	} else {
		$return_string = "0\t $file_path has errors\n";
	}

	local (*FH);
	open(FH, '>>', $path_to_log_file) or die "Can't open file $path_to_log_file for writing";
	print FH $return_string;
	close(FH);
	return $SHORT_RETURN_STRING;
}

sub record_problem_ok2 {
	my $error_flag                         = shift // '';
	my $formatter                          = shift;
	my $file_path                          = shift;
	my $some_correct_answers_not_specified = shift;
	my $pg_duration                        = shift;                       #processing time
	my $return_object                      = $formatter->return_object;
	my %scores                             = ();
	my $ALL_CORRECT                        = 0;
	my $all_correct                        = ($error_flag) ? 0 : 1;

	foreach my $ans (keys %{ $return_object->{answers} }) {
		$scores{$ans} =
			$return_object->{answers}->{$ans}->{score};
		$all_correct = $all_correct && $scores{$ans};
	}
	$all_correct = ".5" if $some_correct_answers_not_specified;
	$ALL_CORRECT = ($all_correct == 1) ? 'All answers are correct' : 'Some answers are incorrect';
	local (*FH);
	open(FH, '>>', $path_to_log_file) or die "Can't open file $path_to_log_file for writing";
	print FH "$all_correct $file_path\n";    #  do we need this? compile_errors=$error_flag\n";
	close(FH);
	return $ALL_CORRECT;
}

sub fake_user {
	return new MockDB::User->new({
		user_id       => "Undefined_user",
		first_name    => '',
		last_name     => '',
		email_address => '',
		student_id    => '',
		section       => '',
		recitation    => '',
		comment       => ''
	});
}

sub fake_set {
	return MockDB::Set->new({
		psvn                   => 123,
		set_id                 => 'Undefined_set',
		open_date              => time(),
		due_date               => time(),
		answer_date            => time(),
		visible                => 0,
		enable_reduced_scoring => 0,
		hardcopy_header        => 'defaultHeader'
	});
}

sub fake_problem {
	return MockDB::Problem->new({
		set_id             => 'fake_set_id',
		value              => '',
		max_attempts       => -1,
		showMeAnother      => -1,
		showMeAnotherCount => 0,
		problem_seed       => 1234,
		status             => 0,
		sub_status         => 0,
		attempted          => 2000,
		last_answer        => '',
		num_correct        => 1000,
		num_incorrect      => 1000,
		prCount            => -10
	});
}

###########################################
# standalonePGproblemRenderer
###########################################

sub standaloneRenderer {
	print "entering standaloneRenderer\n\n";
	my $problemFile = shift // '';
	my $input       = shift // '';
	my $form_data   = shift // '';
	my %args        = @_;

	my $key = '3211234567654321';

	my $user          = $input->{user}               || fake_user();
	my $set           = $input->{'this_set'}         || fake_set();
	my $problem_seed  = $form_data->{'problem_seed'} || 0;             #$r->param('problem_seed') || 0;
	my $showHints     = $input->{showHints}          || 0;
	my $showSolutions = $input->{showSolutions}      || 0;
	my $problemNumber = $input->{'problem_number'}   || 1;
	my $displayMode   = $form_data->{displayMode} // $pg_env->{renderer}->{displayMode};

	my $translationOptions = {
		displayMode       => $displayMode,
		showHints         => $showHints,
		showSolutions     => $showSolutions,
		refreshMath2img   => 1,
		processAnswers    => 1,
		QUIZ_PREFIX       => '',
		use_site_prefix   => $pg_env->{environment}->{server_root_url},
		use_opaque_prefix => 1,
	};
	$translationOptions->{permissionLevel} = 20;
	my $extras = {};    # Check what this is used for.

	# Create template of problem then add source text or a path to the source file
	# local $seed_ce->{pg}{specialPGEnvironmentVars}{problemPreamble} = {TeX=>'',HTML=>''};
	# local $seed_ce->{pg}{specialPGEnvironmentVars}{problemPostamble} = {TeX=>'',HTML=>''};
	my $problem = fake_problem();
	$problem->{value} = -1;
	if (ref $problemFile) {    #in this case the actual source is passed
		$problem->source_file('');
		$translationOptions->{r_source} = $problemFile;
		# print "source is already read\n";
		# a text string containing the problem
	} else {
		$problem->source_file($problemFile);
		# a path to the problem (relative to the course template directory?)
	}

	#FIXME temporary hack
	$set->set_id('this set')  unless $set->set_id();
	$problem->problem_id('1') unless $problem->problem_id();

	my $pg = new WeBWorK::PG(
		$pg_env,
		$user,
		$key,
		$set,
		$problem,
		123,    # PSVN (practically unused in PG)  only used as an identifier
		$form_data,
		$translationOptions,
		$extras,
	);
	# new version of output:
	my $warning_messages = '';    # for now -- set up warning trap later
	my ($internal_debug_messages, $pgwarning_messages, $pgdebug_messages);
	if (ref($pg->{pgcore})) {
		$internal_debug_messages = $pg->{pgcore}->get_internal_debug_messages;
		$pgwarning_messages      = $pg->{pgcore}->get_warning_messages();
		$pgdebug_messages        = $pg->{pgcore}->get_debug_messages();
	} else {
		$internal_debug_messages = ['Error in obtaining debug messages from PGcore'];
	}

	my $out2 = {
		text             => $pg->{body_text},
		header_text      => $pg->{head_text},
		answers          => $pg->{answers},
		errors           => $pg->{errors},
		WARNINGS         => encode_base64("WARNINGS\n" . $warning_messages . "\n<br/>More<br/>\n" . $pg->{warnings}),
		PG_ANSWERS_HASH  => $pg->{pgcore}->{PG_ANSWERS_HASH},
		problem_result   => $pg->{result},
		problem_state    => $pg->{state},
		flags            => $pg->{flags},
		warning_messages => $pgwarning_messages,
		debug_messages   => $pgdebug_messages,
		internal_debug_messages => $internal_debug_messages,
	};
	print "\n pg answers ", join(" ", %{ $pg->{answers} }) if $UNIT_TESTS_ON;
	$pg->free;
	$out2;
}

##################################################
# utilities
##################################################

sub display_inputs {
	my %correct_answers = @_;
	foreach my $key (sort keys %correct_answers) {
		say "$key => $correct_answers{$key}";
	}
}

sub edit_source_file {
	my $file_path = shift;
	system(EDIT_COMMAND() . " $file_path");
}

#######################################################################
# Auxiliary subroutines
#######################################################################
####################################################################################
# Check process memory
####################################################################################

sub get_current_process_memory {
	state $pt = Proc::ProcessTable->new;
	my %info = map { $_->pid => $_ } @{ $pt->table };
	return $info{$$}->rss;
}

####################################################################################
# Write logs -- to replace subroutine from WebworkClient
# this is for when we try to reduce the dependence on WebworkClient
####################################################################################

sub writeRenderLogEntry($$$) {
	my ($function, $details, $beginEnd) = @_;
	$beginEnd = ($beginEnd eq "begin") ? ">" : ($beginEnd eq "end") ? "<" : "-";
#	WeBWorK::Utils::writeLog(, "render_timing", "$$ ".time." $beginEnd $function [$details]");
#	WebworkClient::writeRenderLogEntry("", "{script:$scriptName; file:$file_path; ". sprintf("duration: %.3f sec;", $cg_duration)." url: $credentials{site_url}; }",'');

}

####################################################################################
# format output  to replace subroutine from WebworkClient
####################################################################################

# to be written

##################################################
# Get problem template source and adjust file_path name
##################################################

sub get_source {
	my $file_path = shift;
	my $source;
	die "Unable to read file $file_path \n" unless -r $file_path;
	eval {    #File::Slurp would be faster (see perl monks)
		local $/ = undef;
		open(FH, '<', $file_path) or die "Couldn't open file $file_path: $!";
		$source = <FH>;    #slurp  input
		close FH;
	};
	die "Something is wrong with the contents of $file_path\n" if $@;
	### adjust file_path so that it is relative to the rendering course directory
	#$file_path =~ s|/opt/webwork/libraries/NationalProblemLibrary|Library|;
	$file_path =~ s|^.*?/webwork-open-problem-library/OpenProblemLibrary|Library|;
	print "file_path changed to $file_path\n" if $UNIT_TESTS_ON;
	print $source                             if $UNIT_TESTS_ON;
	return $file_path, $source;
}

sub pretty_print_rh {
	shift if UNIVERSAL::isa($_[0] => __PACKAGE__);
	my $rh     = shift;
	my $indent = shift || 0;
	my $out    = "";
	my $type   = ref($rh);

	if (defined($type) and $type) {
		$out .= " type = $type; ";
	} elsif (!defined($rh)) {
		$out .= " type = UNDEFINED; ";
	}
	return $out . " " unless defined($rh);

	if (ref($rh) =~ /HASH/) {
		$out .= "{\n";
		$indent++;
		foreach my $key (sort keys %{$rh}) {
			$out .= "  " x $indent . "$key => " . pretty_print_rh($rh->{$key}, $indent) . "\n";
		}
		$indent--;
		$out .= "\n" . "  " x $indent . "}\n";

	} elsif (ref($rh) =~ /ARRAY/ or "$rh" =~ /ARRAY/) {
		$out .= " ( ";
		foreach my $elem (@{$rh}) {
			$out .= pretty_print_rh($elem, $indent);

		}
		$out .= " ) \n";
	} elsif (ref($rh) =~ /SCALAR/) {
		$out .= "scalar reference " . ${$rh};
	} elsif (ref($rh) =~ /Base64/) {
		$out .= "base64 reference " . $$rh;
	} else {
		$out .= $rh;
	}

	return $out . " ";
}

############################################
# Help message
############################################

sub print_help_message {
	print <<'EOT';
NAME
    webwork2/clients/sendXMLRPC.pl

DESCRIPTION
    This script will take a list of files or directories and send it to a
    WeBWorK daemon webservice to have it rendered. For directories each .pg
    file under that directory is rendered.

    The results can be displayed in a browser (use -b or -B switches) as was
    done with renderProblem.pl, on the command line (Use -h or -H switches)
    as was done with renderProblem_rawoutput.pl or summary information about
    whether the problem was correctly rendered can be sent to a log file
    (use -c or C switches).

    The capital letter switches, -B, -H, and -C render the question twice.
    The first time returns an answer hash which contains the correct
    answers. The question is then resubmitted to the renderer with the
    correct answers filled in and displayed.

    IMPORTANT: Remember to configure the local output file and display
    command near the top of this script. !!!!!!!!

    IMPORTANT: Create a valid credentials file.

SYNOPSIS
            sendXMLRPC -vcCbB input.pg

DETAILS
  credentials file
        These locations are searched, in order,  for the credentials file.
        ("$ENV{HOME}/.ww_credentials", "$ENV{HOME}/ww_session_credentials", 'ww_credentials')

        Place a credential file containing the following information at one of the locations above
        or create a file with this information and specify it with the --credentials option.

            %credentials = (
                            userID                 => "my login name for the webwork course",
                            course_password        => "my password ",
                            courseID               => "the name of the webwork course",
                  XML_URL                  => "url of rendering site
                  XML_PASSWORD          => "site password" # preliminary access to site
                  $FORM_ACTION_URL      =  'http://localhost:80/webwork2/html2xml'; #action url for form
            );

  Options
    -a
                Displays the answer hashes returned by the question on the command line.

    -A
                Same as -a but renders the question with the correct answers submitted.

    -b
                Display the rendered question in a browser (specified by the DISPLAY_HTML_COMMAND variable).

    -B
                Same as -b but renders the question with the correct answers submitted.

    -h
                Prints to STDOUT the entire object returned by
                   the webwork_client xmlrpc request.
                   This includes the answer information displayed by -a and -A and much more.

    -H
                Same as -h but renders the question with the correct answers submitted

    -c
                "check" -- Record success or failure of rendering the question to a log file.

    -C
                Same as -c but the question is rendered with the correct answers submitted.
                 This succeeds only if the correct answers, as determined from the answer hash, all succeed.

    f=s
                Specify the format used by the browser in displaying the question.
                 Choices for s are
                 standard
                 sticky
                 debug
                 simple

    -v
                Verbose output. Used mostly for debugging.
                 In particular it displays explicitly the correct answers which are (will be)  submitted to the question.

    -e
				Open the source file in an editor.


                The single letter options can be "bundled" e.g.  -vcCbB

   	--tex
				Process question in TeX mode and output to the command line

	--list   pg_list
				Read and process a list of .pg files contained in the file C<pg_list>.  C<pg_list>
				consists of a sequence of lines each of which contains the full path to a pg
				file that should be processed. (For example this might be the output from an
				earlier run of sendXMLRPC using the -c flag. )

    --pg
                Triggers the printing of the all of the variables available to the PG question.
                The table appears within the question content. Use in conjunction with -b or -B.

    --anshash
                Prints the answer hash for each answer in the PG_debug output which appears below
                the question content. Use in conjunction with -b or -B.
                Similar to -a or -A but the output appears in the browser and
                not on the command line.

    --ansgrp
                Prints the PGanswergroup for each answer evaluator. The information appears in
                the PG_debug output which follows the question content.  Use in conjunction with -b or -B.
                This contains more information than printing the answer hash. (perhaps too much).

	--resource

	Prints the resources used by the question. The information appears in
    the PG_debug output which follows the question content.  Use in conjunction with -b or -B.

    --credentials=s
                Specifies a file s where the  credential information can be found.

	--help
		   Prints help information.

	--log
		   Sets path to log file


EOT
}

1;
