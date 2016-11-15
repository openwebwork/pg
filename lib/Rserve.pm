package Rserve;

use strict;
use warnings;

my $rserve_loaded = eval {
    require Statistics::R::IO::Rserve;
    1
};

sub access {
    die 'Statistics::R::IO::Rserve could not be loaded. Have you installed the module?'
        unless $rserve_loaded;
    
    Statistics::R::IO::Rserve->new(@_)
};


## Evaluates an R expression guarding it inside an R `try` function
##
## Returns the result as a REXP if no exceptions were raised, or
## `die`s with the text of the exception message.
sub try_eval {
    my ($rserve, $query) = @_;

    my $result = $rserve->eval("try({ $query }, silent=TRUE)");
    die $result->to_pl->[0] if _inherits($result, 'try-error');
    # die $result->to_pl->[0] if $result->inherits('try-error');

    $result
}


## Returns a REXP's Perl representation, dereferencing it if it's an
## array reference
##
## `REXP::to_pl` returns a string scalar for Symbol, undef for Null,
## and an array reference to contents for all vector types. This
## function is a utility wrapper to make it easy to assign a Vector's
## representation to an array variable, while still working sensibly
## for non-arrays.
sub unref_rexp {
    my $rexp = shift;
    
    my $value = $rexp->to_pl;
    if (ref($value) eq ref([])) {
        @{$value}
    } else {
        $value
    }
}


## Reimplements method C<inherits> of class L<Statistics::R::REXP>
## until I figure out why calling it directly doesn't work in the safe
## compartment
sub _inherits {
    my ($rexp, $class) = @_;

    my $attributes = $rexp->attributes;
    return unless $attributes && $attributes->{'class'};
    
    grep {/^$class$/} @{$attributes->{'class'}->to_pl}
}


1;
