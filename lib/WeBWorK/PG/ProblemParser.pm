
package WeBWorK::PG::ProblemParser;

=head1 DESCRIPTION

This package provide functionality to load a PG problem and parse the metadata
in either traditional tag format or YAML style.  After loading, the metadata can
be testing for validity or the correct answers for the problem can be extracted.

=cut

use strict;
use warnings;
use v5.36;
use feature 'try';

use Mojo::File   qw(curfile path);
use Mojo::Loader qw(data_section);
use Mojo::Util   qw(dumper);
use Mojo::JSON   qw(decode_json);
use YAML::XS     qw(Load);

$YAML::XS::ForbidDuplicateKeys = 1;

use lib curfile->dirname;
use WeBWorK::Utils::Tags;

=head2 WeBWorK::PG::ProblemParser

Create a new ProblemParser either as a filepath or a problem source.

If it is passed in via a file path, both the path and the library location  
should be set:

    WeBWorK::PG::ProblemParser->new(
       path => '/path/to/file',
       library_root => '/path/to/library_root'
     )

otherwise pass in the source as in 

    WeBWorK::PG::ProblemParser->new(source => $problem_source)

The PG_ROOT directory needs to be defined.  It can optionally be passed in
with the option C<< pg_root => '/path/to/pg_root' >>. 

=cut

sub new($class, %options) {

	die 'Both the path option and the source can not be used together.'
		if $options{path} && $options{source};

	$options{pg_root} = curfile->dirname->dirname->dirname->dirname unless $options{pg_root};
	die "The pg_root directory: $options{pg_root} is not valid"     unless -d $options{pg_root};

	die 'If the problem path is passed in, then then library_root must be as well'
		if $options{path} && !defined($options{library_root});

	die "Either the 'path' or 'source' must be passed into 'ProblemParser->new'"
		if !defined($options{path}) && !defined($options{source});

	my $self =
		$options{source}
		? { problem_source => $options{source} }
		: { problem_path   => $options{path}, library_root => $options{library_root} };

	$self->{problem_source} = path($self->{problem_path})->slurp if $self->{problem_path};
	$self->{pg_root}        = ref($options{pg_root}) eq 'Mojo::File' ? $options{pg_root} : path($options{pg_root});
	$self                   = bless $self, $class;

	# Check if the metadata in the the __DATA__ block at the bottom of the file.
	if ($self->{problem_source} =~ /__DATA__/) {
		$self->parseMetaDataYAML();
	} else {
		$self->parseTags();
		$self->cleanProblemSource();
	}

	return $self;
}

=head2 parseMetaDataYAML 

Parse the data block at the end of the file. 

=cut

sub parseMetaDataYAML($self) {
	my $metadata;
	try {
		my $yaml_block = $self->{problem_source} =~ s/^(.*__DATA__\r?\n)//msr;
		$metadata = Load($yaml_block);
	} catch ($error) {
		warn "Error parsing YAML metadata: $error";
	};
	$self->{metadata} = $metadata;
}

=head2 parseTags

Use the legacy Tags module to parse the tags.  Additionally, this 
parses the loadMacros. 

=cut

sub parseTags($self) {
	# Extract the Description of the problem.  Note: this is not in the Tags module
	my $description = '';
	if ($self->{problem_source} =~ /DESCRIPTION(.*?)#\s*ENDDESCRIPTION/si) { $description = $1; }

	my @description_lines = split /\n/, $description;
	# Strip leading whitespace, 0 to 2 '#' characters and trailing whitespace.
	$_ =~ s/^\s*#{0,2}\s*|\s+$//g for (@description_lines);
	@description_lines = grep {$_} @description_lines;

	# Extract the macros:
	my $macros_str = '';
	if ($self->{problem_source} =~ /loadMacros\((qw(.))?(.*?)(.)?\)/ms) { $macros_str = $3; }
	my @macros = split /(\s|\s*,\s*)/, $macros_str;

	$_ =~ s/['"]//g for (@macros);
	@macros = grep { $_ =~ /\w+\.pl/ } @macros;
	$self->{macros} = \@macros;

	# Parse the tags using the Tags module.  the Tags module require a file path,
	# so we need to write the problem source to a temporary file.
	my $temp_file;
	if (!defined($self->{problem_path})) {
		my $temp_file = tempfile(DIR => '/tmp');
		$temp_file->spew($self->{problem_source});
		$self->{problem_path} = $temp_file;
	}

	my $tags        = WeBWorK::Utils::Tags->new($self->{problem_path});
	my $author_info = {};
	$author_info->{name}        = $tags->{Author}      if $tags->{Author};
	$author_info->{institution} = $tags->{Institution} if $tags->{Institution};

	my $library_info = {};
	$library_info->{subject} = $tags->{DBsubject} if $tags->{DBsubject};
	$library_info->{chapter} = $tags->{DBchapter} if $tags->{DBchapter};
	$library_info->{section} = $tags->{DBsection} if $tags->{DBsection};

	my $metadata = {
		author       => $author_info,
		library_info => $library_info,
		description  => $description,
		macros       => $self->{macros}
	};

	$metadata->{date}         = formatDate($tags->{Date})                           if $tags->{Date};
	$metadata->{keywords}     = [ map { cleanKeyword($_) } @{ $tags->{keywords} } ] if $tags->{keywords};
	$metadata->{problem_path} = path($self->{problem_path})->to_rel($self->{library_root})->to_string;
	for (qw(Language MLT MLTLeader Static Status)) {
		$metadata->{$_} = $tags->{$_} if $tags->{$_};
	}
	$metadata->{textbook_info} = $tags->{textinfo}  if @{ $tags->{textinfo} } > 0;
	$metadata->{resources}     = $tags->{resources} if @{ $tags->{resources} } > 0;

	$temp_file->delete if $temp_file;
	$self->{metadata} = $metadata;
	return $self;
}

# Change other date formats to YYYY-MM-DD format.

sub formatDate($date) {
	if ($date =~ /(\d{1,2})\/(\d{1,2})\/(\d{4})/s) {    # MM/DD/YYYY
		return "$3-" . ($1 < 10 ? "0$1" : $1) . '-' . ($2 < 10 ? "0$2" : "$2");
	} else {
		return $date;
	}
}

# Clean up keywords which often have extra spaces and quotes.
sub cleanKeyword($keyword) {
	return $keyword =~ s/\s*'(.*)'\s*/$1/r =~ s/"(.*)"/$1/r;
}

# Remove all lines with Tagging information

sub cleanProblemSource($self) {
	my $problem_source = $self->{problem_source};
	# Remove the Description section.
	$problem_source =~ s/#+\s*DESCRIPTION(.*?)#+\s*ENDDESCRIPTION\s*//si;

	# Remove each of the standard tags:
	$problem_source =~ s/^\s*#+\s*$_\(.*?\)//gsim
		for (qw(DBsubject DBchapter DBsection Date Institution Author MLT MLTleader
			Level Language Static MO Status KEYWORDS));

	# Remove each of the numbered tags:
	$problem_source =~ s/^\s*#+\s*$_\d\(.*?\)//gsim for (qw(TitleText AuthorText EditionText Section Problem));
	$self->{problem_source} = $problem_source;
	return $self;
}

=head2 writeToPath

Using the current parsed problem, write the file to a path.  This uses the 
format that the metadata is written as a YAML block at the bottom of the file.

=cut 

sub writeToPath($self, $path) {
	my $yaml          = YAML::XS->new;
	my $metadata_yaml = $yaml->dump($self->{metadata});
	my $source_code   = <<~"END_SOURCE";
  $self->{problem_source}
  __DATA__
  $metadata_yaml
  END_SOURCE
	Mojo::File->new($path)->spew($source_code);
}

# Return the pg_options using mostly default options.
# If %opts is defined, then these will override the default options.

sub pg_options($self, %opts) {
	my $macrosPath = [
		'.',
		map { $self->{pg_root} . "/$_" }
			qw(
			macros macros/answers macros/contexts macros/core macros/graph
			macros/math macros/misc macros/parsers macros/ui macros/deprecated)
	];
	return (
		showHints               => 1,
		showSolutions           => 1,
		processAnswers          => 1,
		isInstructor            => 1,
		forceScaffoldsOpen      => 1,
		answersAvailable        => 1,
		showFeedback            => 1,
		forceShowAttemptResults => 1,
		displayMode             => 'MathJax',
		macrosPath              => $macrosPath,
		language_subroutine     => WeBWorK::PG::Localize::getLoc('en'),
		%opts
	);
}

=head2 extractAllCorrectAnswers.

This extracts the correct answers of the problem and formats the results as a 
hash reference in the format to be passed to C<Translator> for answer checking.  

    $pg_problem->extractAllCorrectAnswers($seed);

=cut 

sub extractAllCorrectAnswers ($self, $seed) {
	my $pg = WeBWorK::PG->new(
		r_source    => \$self->{problem_source},
		problemSeed => $seed
	);

	my @answer_keys = keys %{ $pg->{pgcore}{PG_ANSWERS_HASH} };

	my $correct_answers_hash = {};
	for my $key (@answer_keys) {
		my $correct_answers;
		my $answer_type = $pg->{pgcore}{PG_ANSWERS_HASH}{$key}{ans_eval}{rh_ans}{type};

		if ($answer_type =~ /^Value\s*\(([\w\-]+)\)/) {
			$correct_answers =
				extractCorrectAnswer($key, $pg->{pgcore}{PG_ANSWERS_HASH}{$key}{ans_eval}{rh_ans}{correct_value});
		} elsif ($answer_type =~ /MultiAnswer\((\d+)\)/) {
			$correct_answers = extractCorrectMultiAnswer($pg->{pgcore}{PG_ANSWERS_HASH}{$key}{ans_eval}, $1);
		} elsif ($answer_type eq 'RadioMultiAnswer') {
			$correct_answers = extractCorrectRadioMultiAnswer($pg->{pgcore}{PG_ANSWERS_HASH}{$key}{ans_eval});
		} elsif ($answer_type =~ /_cmp/ || $answer_type eq 'ans_box') {
			return { deprecated => "The answer type: $answer_type is not supported for testing." };
		}
		@{$correct_answers_hash}{ keys %$correct_answers } = values %$correct_answers;
	}
	$pg->free;
	return $correct_answers_hash;
}

# This takes a MathObject (except for MultiAnswer and RadioMultiAnswer)
# and returns the correct value.

sub extractCorrectAnswer($ans_name, $obj) {
	if (grep { ref($obj) =~ /(?:^|::)$_$/ } qw(parserRadioButtons)) {
		return { $ans_name => $obj->{data}[0] };
	} elsif (ref($obj) eq 'Value::Real') {
		return { $ans_name => $obj->{correct_ans} // $obj->{data}[0] };
	} elsif (ref($obj) =~ /CheckboxList/) {
		return { $ans_name => [ map { $_->string } @{ $obj->{data} } ] };
	} elsif (
		grep { ref($obj) =~ /(?:^|::)*$_$/ }
		qw(Real Complex Infinity Formula Fraction PopUp List Interval Union Set Point String
		Percent GraphTool FixedPrecision NumberWithUnit NumberWithUnits FormulaWithUnits
		LinearRelation ImplicitEquation ImplicitPlane FormulaUpToConstant Currency
		DifferenceQuotient DraggableProof DraggableSubsets WordCompletion OneOf)
		)
	{
		# Note: for most types of MathObjects, the string method will returns the
		# correct answer, however for some this is not define (explore more which ones).
		my $str_output;
		try {
			$str_output = $obj->can('string') ? $obj->string : $obj->{string};
		} catch ($e) {
			warn $e;
		};
		return { $ans_name => $str_output };
	} elsif (ref($obj) =~ /Vector/) {
		return $obj->{ColumnVector} ? extractCorrectMatrix($obj) : { $ans_name => $obj->string };
	} elsif (ref($obj) =~ /Matrix/) {
		return extractCorrectMatrix($obj);
	} elsif (ref($obj) eq '') {    # $obj is an number/string.
		return { $ans_name => $obj };
	} else {
		warn 'The object type:' . ref($obj) . ' does not have a defined correct answer extractor.';
		return {};
	}
}

# return the correct answer for a Matrix object.
# Note: This works for a ColumnVector, but haven't tested for a matrix of dimension more that 2.

sub extractCorrectMatrix($obj) {
	my $correct_ans = {};
	for my $i (0 .. $#{ $obj->{data} }) {
		for my $j (0 .. $#{ $obj->{data}[$i]{data} }) {
			my $name = $i == 0 && $j == 0 ? $obj->{ans_name} =~ s/^MaTrIx_//r : $obj->{ans_name} . "_${i}_${j}";
			$correct_ans = { %$correct_ans, %{ extractCorrectAnswer($name, $obj->{data}[$i]{data}[$j]) } };
		}
	}
	return $correct_ans;
}

# return the correct answer for a MultiAnswer object.
sub extractCorrectMultiAnswer($ans_eval, $part) {
	my $multiAnswer;
	for (@{ $ans_eval->{evaluators} }) {
		$multiAnswer = $_->[1] if ref $_->[1] eq 'parser::MultiAnswer';
	}
	return extractCorrectAnswer($multiAnswer->{answerNames}{$part}, $multiAnswer->{data}[$part]);
}

sub extractCorrectRadioMultiAnswer($ans_eval) {
	my $multiAnswer;
	for (@{ $ans_eval->{evaluators} }) {
		$multiAnswer = $_->[1] if ref $_->[1] eq 'parser::RadioMultiAnswer';
	}

	my $correct_choice = $ans_eval->{rh_ans}{correct_choice};
	my $correct_index;
	for (0 .. $#{ $multiAnswer->{values} }) {
		$correct_index = $_ if $multiAnswer->{values}[$_] eq $correct_choice;
	}

	my $answerNames = $multiAnswer->{answerNames};

	# Determine the correct name starting point.
	my $answer_index = scalar(@{ $multiAnswer->{cmp}[ $correct_index - 1 ] });

	my $correct_answers = { $answerNames->{0} => $correct_choice };
	for (1 .. $#{ $multiAnswer->{data}[$correct_index] }) {
		my $obj     = $multiAnswer->{data}[$correct_index][$_];
		my $obj_ans = extractCorrectAnswer($answerNames->{ $_ + $answer_index }, $obj);
		@{$correct_answers}{ keys %$obj_ans } = values %$obj_ans;
	}

	return $correct_answers;
}

=head2 checkDBmetadata 

Check the subject/chapter/section in the metadata for categorizing the problem
against the database. 

=cut

# this uses the file /webwork2/htdocs/DATA/tagging-taxomony.json which may not be
# up to date.  TODO: switch to database look ups.

sub checkDBmetadata($self) {
	my $taxonomy =
		decode_json(
			path($self->{pg_root})->dirname->child('webwork2', 'htdocs', 'DATA', 'tagging-taxonomy.json')->slurp);

	my $errors = {};
	# Check for the subject/chapter/section database tags:
	for (qw(subject chapter section)) {
		$errors->{ $_ . '_missing' } = "The database $_ is missing from the problem."
			unless $self->{metadata}{library_info}{$_};
	}
	return $errors if (keys %$errors);

	my ($subject_index) = grep { $taxonomy->[$_]{name} eq $self->{metadata}{library_info}{subject} } 0 .. $#$taxonomy;

	$errors->{subject_error} =
		'The database subject: ' . $self->{metadata}{library_info}{subject} . ' is not in the taxonomy.'
		unless defined($subject_index);

	return $errors if (keys %$errors);

	my ($chapter_index) =
		grep { $taxonomy->[$subject_index]{subfields}[$_]{name} eq $self->{metadata}{library_info}{chapter} }
		0 .. $#{ $taxonomy->[$subject_index]{subfields} };

	$errors->{chapter_error} =
		'The database chapter: ' . $self->{metadata}{library_info}{chapter} . ' is not in the taxonomy.'
		unless defined($chapter_index);

	my ($section_index) =
		grep {
			$taxonomy->[$subject_index]{subfields}[$chapter_index]{subfields}[$_]{name} eq
			$self->{metadata}{library_info}{section}
		} 0 .. $#{ $taxonomy->[$subject_index]{subfields}[$chapter_index]{subfields} };

	$errors->{section_error} =
		'The database section: ' . $self->{metadata}{library_info}{section} . ' is not in the taxonomy.'
		unless defined($section_index);

	return $errors;

}

1;
