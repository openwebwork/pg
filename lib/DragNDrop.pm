use strict;
use warnings;

################################################################
=pod
=head1 NAME
DragNDrop.pm - Drag-And-Drop Module
  
=head1 DESCRIPTION
DragNDrop.pm is a backend Perl module which facilitates the implementation of 
'Drag-And-Drop' in WeBWorK problems. It is meant to be used in tandem with other perl macros
such as draggableProof.pl.

=head1 TERMINOLOGY
An HTML element into or out of which other elements may be dragged will be called a "bucket".
An HTML element which houses a collection of buckets will be called a "bucket pool".

=head1 USAGE
Each macro aiming to implement drag-n-drop features must call at its initialization:
ADD_CSS_FILE("https://cdnjs.cloudflare.com/ajax/libs/nestable2/1.6.0/jquery.nestable.min.css", 1);
ADD_JS_FILE("https://cdnjs.cloudflare.com/ajax/libs/nestable2/1.6.0/jquery.nestable.min.js", 1);
ADD_CSS_FILE("js/apps/DragNDrop/dragndrop.css", 0);
ADD_JS_FILE("js/apps/DragNDrop/dragndrop.js", 0, { defer => undef });

To initialize a bucket pool, do:

my $bucket_pool = new DragNDrop($answer_input_id, $aggregate_list);

$answer_input_id is a unique identifier for the bucket_pool, it is recommended that
it be generated with NEW_HIDDEN_ANS_NAME.

$aggregate_list is a reference to an array of all "statements" intended to be draggable.
e.g. $aggregate_list = ['socrates is a man', 'all men are mortal', 'therefore socrates is mortal']
It is imperative that square brackets be used.

################################################################
OPTIONAL: DragNDrop($answer_input_id, $aggregate_list, AllowNewBuckets => 1);
allows student to create new buckets by clicking on a button.
################################################################

To add a bucket to an existing pool $bucket_pool, do:
$bucket_pool->addBucket($indices);

$indices is the reference to the array of indices corresponding to the statements in $aggregate_list
to be pre-included in the bucket. 
For example, if the $aggregate_list is ['Socrates is a man', 'all men are mortal', 'therefore Socrates is mortal'],
and the bucket consists of  { 'Socrates is a man', 'therefore Socrates is mortal' },
then $indices = (0, 2).

An empty argument, e.g. $bucket_pool->addBucket(), gives an empty bucket.

################################################################
OPTIONAL: $bucket_pool->addBucket($indices, label => 'Barrel')
puts the label 'Barrel' at the top of the bucket.
################################################################

To output the bucket pool to HTML, call:
$bucket_pool->HTML

To output the bucket pool to LaTeX, call:
$bucket_pool->TeX

=head1 EXAMPLES
See draggableProof.pl and draggableSubsets.pl
=cut
################################################################

package DragNDrop;

sub new {    
	my $self = shift; 
    my $class = ref($self) || $self;
    
    my $answer_input_id = shift; # 'id' of html <input> tag corresponding to the answer blank. Must be unique to each pool of DragNDrop buckets
    my $aggregate_list = shift; # array of all statements provided
    my $default_buckets = shift; # instructor-provided default buckets with pre-included statements encoded by the array of corresponding statement indices
    my %options = (
		AllowNewBuckets => 0,
		@_
	);

    $self = bless {        
        answer_input_id => $answer_input_id,        
        bucket_list => [],
        aggregate_list => $aggregate_list,
        default_buckets => $default_buckets,
		bucket_id => 0,
        %options,
    }, $class;
            	
    return $self;
}

sub addBucket {    
    my $self = shift; 
        
    my $indices = shift || [];
    
	my %options = (
	    label => '',
		removable => 0,
		@_
	);
	
	my $bucket_id = $self->{bucket_id}++;
    		
    my $bucket = {
        indices => $indices,
        list => [ map { $self->{aggregate_list}->[$_] } @$indices ],
        bucket_id => $bucket_id,
        label => $label,
        removable => $options{removable},
    };
    push(@{$self->{bucket_list}}, $bucket);
    
}

sub HTML {
    my $self = shift;
    	
    my $out = '';
    $out .= "<div class='bucket_pool' data-ans='$self->{answer_input_id}'>";
        
    # buckets from instructor-defined default settings
    for (my $i = 0; $i < @{ $self->{default_buckets} }; $i++) {
        my $default_bucket = $self->{default_buckets}->[$i];
        $out .= "<div class='hidden default bucket' data-bucket-id='$i' data-removable='$default_bucket->{removable}'>";
        $out .= "<div class='label'>$default_bucket->{label}</div>"; 
        $out .= "<ol class='answer'>";
        for my $j ( @{$default_bucket->{indices}} ) {
            $out .= "<li data-shuffled-index='$j'>$self->{aggregate_list}->[$j]</li>";
        }
        $out .= "</ol></div>";
    }
    
	# buckets from past answers
    for my $bucket ( @{$self->{bucket_list}} ) {
        $out .= "<div class='hidden past_answers bucket' data-bucket-id='$bucket->{bucket_id}' data-removable='$bucket->{removable}'>";
        $out .= "<div class='label'>$bucket->{label}</div>"; 
        $out .= "<ol class='answer'>";
        
        for my $index ( @{$bucket->{indices}} ) {
            $out .= "<li data-shuffled-index='$index'>$self->{aggregate_list}->[$index]</li>";
        }
        $out .= "</ol>";
        $out .= "</div>"; 
    }
    
    $out .= '</div>';
    $out .= "<br clear='all'><div><a class='btn reset_buckets'>reset</a>";    
    if ($self->{AllowNewBuckets} == 1) {
        $out .= "<a class='btn add_bucket' data-ans='$self->{answer_input_id}'>add bucket</a></div>";
    }
    
    return $out;
}

sub TeX {
    my $self = shift;
    	
    my $out = "";
        
    # default buckets;
    for (my $i = 0; $i < @{ $self->{default_buckets} }; $i++) {
		$out .= "\n";
        my $default_bucket = $self->{default_buckets}->[$i];
		if ( @{$default_bucket->{indices}} > 0 ) {
			$out .= "\n\\hrule\n\\begin{itemize}";		
			for my $j ( @{$default_bucket->{indices}} ) {
				$out .= "\n\\item[$j.]\n $self->{aggregate_list}->[$j]";
			}
			$out .= "\n\\end{itemize}";
		}
		$out .= "\n\\hrule\n";
    }
    return $out;
}
1;