#########################################################################
#
#  Implements the Vector class
#
package Parser::List::Vector;
use strict;
our @ISA = qw(Parser::List);

#
#  The basic List class does nearly everything.
#

#
#  Check that the coordinates are numbers (avoid <i+j+k>)
#
sub _check {
	my $self = shift;
	return if $self->context->flag("allowBadOperands");
	foreach my $x (@{ $self->{coords} }) {
		unless ($x->isNumber) {
			my $type = $x->type;
			$type = (($type =~ m/^[aeiou]/i) ? "an " : "a ") . $type;
			$self->{equation}->Error([ "Coordinates of Vectors must be Numbers, not %s", $type ]);
		}
	}
	$self->{equation}->Error("Coordinates of a Vector must be constant")
		if ($self->context->flag("requireConstantVectors") && !($self->{isConstant}));
}

sub ijk {
	my $self       = shift;
	my $context    = $self->context;
	my $method     = shift || ($context->flag("StringifyAsTeX") ? 'TeX' : 'string');
	my $precedence = shift || 0;
	my @coords     = @{ $self->{coords} };
	$self->Error("Method 'ijk' can only be used on vectors in three-space")
		unless (scalar(@coords) <= 3);
	my @ijk       = ();
	my $constants = $context->{constants};

	foreach my $x ('i', 'j', 'k', '_0') {
		my $v = (split(//, $x))[-1];
		push(@ijk, ($constants->{$x} || { string => $v, TeX => "\\boldsymbol{$v}" })->{$method});
	}
	my $prec   = $context->operators->get('*')->{precedence};
	my $string = '';
	my $n;
	my $term;
	foreach $n (0 .. scalar(@coords) - 1) {
		$term = $coords[$n]->$method($prec);
		if ($term ne '0') {
			$term =~ s/\((-(\d+(\.\d*)?|\.\d+))\)/$1/;
			$term = ''  if $term eq '1';
			$term = '-' if $term eq '-1';
			$term = '+' . $term unless $string eq '' or $term =~ m/^-/;
			$string .= $term . $ijk[$n];
		}
	}
	$string = $ijk[3]             if $string eq '';
	$string = '(' . $string . ')' if $string =~ m/[-+]/ && $precedence > $context->operators->get('+')->{precedence};
	return $string;
}

sub TeX {
	my $self = shift;
	return $self->ijk("TeX", @_)
		if (($self->{ijk} || $self->{equation}{ijk} || $self->{equation}{context}->flag("ijk"))
			&& scalar(@{ $self->{coords} }) <= 3);
	return $self->SUPER::TeX;
}

sub string {
	my $self = shift;
	return $self->ijk("string", @_)
		if (($self->{ijk} || $self->{equation}{ijk} || $self->{equation}{context}->flag("ijk"))
			&& scalar(@{ $self->{coords} }) <= 3);
	return $self->SUPER::string;
}

#########################################################################

1;
