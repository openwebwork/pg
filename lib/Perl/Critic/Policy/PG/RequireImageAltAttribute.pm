package Perl::Critic::Policy::PG::RequireImageAltAttribute;
use Mojo::Base 'Perl::Critic::Policy', -signatures;

use Perl::Critic::Utils qw(:severities :classification :ppi);

use WeBWorK::PG::Critic::Utils qw(parsePGMLBlock parseTextBlock);

use constant DESCRIPTION => 'An image is missing the alt attribute';
use constant EXPLANATION => 'Add an alt attribute that describes the image content.';
use constant SCORE       => 10;

sub supported_parameters ($) {return}
sub default_severity ($)     { return $SEVERITY_HIGHEST }
sub default_themes ($)       { return qw(pg) }
sub applies_to ($)           { return qw(PPI::Token::HereDoc PPI::Token::Word) }

sub hasAltTag ($self, $element) {
	my @args =
		map { $_->[0]->isa('PPI::Token::Quote') ? $_->[0]->string : $_->[0]->content } parse_arg_list($element);
	shift @args;    # Remove the image argument.
	my %args = @args % 2 ? () : @args;
	return $args{alt} || ($args{extra_html_tags} && $args{extra_html_tags} =~ /alt/);
}
use Mojo::Util qw(dumper);

sub violates ($self, $element, $) {
	my @violations;
	if ($element->isa('PPI::Token::Word') && $element eq 'image' && is_function_call($element)) {
		push(@violations, $self->violation(DESCRIPTION, { score => SCORE, explanation => EXPLANATION }, $element))
			unless $self->hasAltTag($element);
	} elsif (
		$element->isa('PPI::Token::HereDoc')
		&& $element->terminator =~ /^END_(PGML|PGML_SOLUTION|PGML_HINT|TEXT|HINT|SOLUTION)?$/
		&& $element->parent
		&& $element->parent->parent
		&& $element->parent->parent->parent
		&& ($element->parent->parent->parent->first_element eq 'PGML::Format2'
			|| $element->parent->parent->parent->first_element eq 'EV3P')
		&& is_function_call($element->parent->parent->parent->first_element)
		&& $element->parent->parent->parent->parent
		&& $element->parent->parent->parent->parent->parent
		&& $element->parent->parent->parent->parent->parent->first_element =~ /^(STATEMENT|HINT|SOLUTION)$/
		&& is_function_call($element->parent->parent->parent->parent->parent->first_element)
		)
	{
		for my $command (
			@{
				(
					$element->terminator =~ /PGML/
					? parsePGMLBlock($element->heredoc)->{commands}
					: parseTextBlock($element->heredoc)->{commands}
				) // []
			}
			)
		{
			for (grep { $_ eq 'image' && is_function_call($_) } @{ $command->find('PPI::Token::Word') || [] }) {
				next if $self->hasAltTag($_);
				push(
					@violations,
					$self->violation(
						DESCRIPTION
							. ' inside the '
							. ($element->terminator =~ s/END/BEGIN/r) . '/'
							. ($element->terminator)
							. ' block',
						{ score => SCORE, explanation => EXPLANATION },
						$element->parent->parent->parent->parent->parent
					)
				);
			}
		}
	}

	return @violations;
}

1;

__END__

=head1 NAME

Perl::Critic::Policy::PG::RequireImageAltAttribute - Images created with the
C<image> method should have the C<alt> attribute set.

=head1 DESCRIPTION

The C<alt> attribute is crucial for accessibility, especially for visually
impaired users who rely on screen readers to understand the content of the
problem. So all images added to a problem should have the C<alt> attribute set.
Note that it can be set to the empty string to indicate that the image is not
essential to the meaning of the problem content. Generally it is better to use
the PGML syntax for images C<[!alternate text!]{$image}> rather than using the
C<image> method.

=cut
