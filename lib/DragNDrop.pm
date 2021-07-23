################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2018 The WeBWorK Project, http://openwebwork.sf.net/
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

# This is a Perl module which simplifies and automates the process of generating
# simple images using TikZ, and converting them into a web-useable format.  Its
# typical usage is via the macro PGtikz.pl and is documented there.

use strict;
use warnings;

# sub _DragNDrop_init {
# 
#   $courseHtmlUrl = $envir{htmlURL};
#   # Load jquery nestable from cdnjs.cloudflare.com
#   ADD_CSS_FILE("https://cdnjs.cloudflare.com/ajax/libs/nestable2/1.6.0/jquery.nestable.min.css", 1);
#   ADD_JS_FILE("https://cdnjs.cloudflare.com/ajax/libs/nestable2/1.6.0/jquery.nestable.min.js", 1);
#   ADD_CSS_FILE("$courseHtmlUrl/js/dragndrop.css", 1);
#   ADD_JS_FILE("$courseHtmlUrl/js/dragndrop.js", 1, { defer => undef });
# 
#   main::PG_restricted_eval("sub DragNDrop {new DragNDrop(\@_)}");
# } 

package DragNDrop;

my $bucket_id = 1;

sub new {    
	my $self = shift; 
    my $class = ref($self) || $self;
    
    my $answer_input_id = shift;
    my $aggregate_list = shift;
    my $default_buckets = shift;
    my %options = (
		AllowNewBuckets => 0,
		@_
	);

    $self = bless {        
        answer_input_id => $answer_input_id,        
        bucket_list => [],
        aggregate_list => $aggregate_list,
        default_buckets => $default_buckets,
        %options,
    }, $class;
            
    return $self;
}

sub addBucket {    
    my $self = shift; 
    
    my $bucket_id = $bucket_id++;
    
    my $indices = shift;
    my $label = shift; 
    my %options = (
		removable => 0,
		@_
	);  
    
    my $bucket = {
        indices => $indices,
        list => [ map { $self->{aggregate_list}->[$_] } @$indices ],
        # container_id => $container_id,
        bucket_id => $bucket_id,
        label => $label,
        removable => $options{removable},
    };
    push(@{$self->{bucket_list}}, $bucket);
    
}

sub toHTML {
    my $self = shift;
    
    my $out = '';
    $out .= "<div class='bucket_pool' data-ans='$self->{answer_input_id}'>";
        
    # default buckets;
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
    
    for (my $i = 0; $i < @{$self->{bucket_list}}; $i++) {
        my $bucket = $self->{bucket_list}->[$i];
        $out .= "<div class='hidden past_answers bucket' data-bucket-id='$bucket->{bucket_id}' data-removable='$bucket->{removable}'>";
        $out .= "<div class='label'>$bucket->{label}</div>"; 
        $out .= "<ol class='answer'>";
        
        for my $index ( @{$bucket->{indices}} ) {
            $out .= "<li data-shuffled-index='".$index."'>".$self->{aggregate_list}->[$index]."</li>";
        }
        $out .= "</ol>";
        $out .= "</div>"; 
    }
    
    $out .= '</div>';
    $out .= "<br clear='all'><div><a class='btn reset_buckets'>reset</a>";    
    if ($self->{AllowNewBuckets} == 1) {
        $out .= "<a class='btn add_bucket' data-ans='".$self->{answer_input_id}."'>add bucket</a></div>";
    }
    
    return $out;
}

# sub ans_rule {
# 	my $self = shift;
#     if ($main::displayMode eq 'TeX') {
#         return "\\begin{itemize}\\item".join("\n\n\\item\n" , @{ $self->{aggregate_list} })."\\end{itemize}";
#     }
#     my $out = $self->toHTML;
#     return main::NAMED_HIDDEN_ANS_RULE($self->{answer_input_id}).$out;    
# }
1;