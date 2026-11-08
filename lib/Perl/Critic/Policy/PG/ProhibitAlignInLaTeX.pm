package Perl::Critic::Policy::PG::ProhibitAlignInLaTeX;
use Mojo::Base 'Perl::Critic::Policy', -signatures;

use Perl::Critic::Utils qw(:severities);

use constant DESCRIPTION => 'There is a \begin{align*}, \begin{align}, \end{align*} '
	. 'or \end{align} in the LaTeX code';
use constant EXPLANATION => 'In order for mathematical content to render correctly, '
	. 'this should be done with \begin{aligned} \end{aligned} instead of the align or '
	. 'align* version.';
use constant SCORE => 10;
sub supported_parameters ($) {return}
sub default_severity ($)     { return $SEVERITY_HIGHEST }
sub default_themes ($)       { return qw(pg) }
sub applies_to ($)           { return qw(PPI::Document) }

sub default_maximum_violations_per_document ($) { return 1; }

sub violates ($self, $element, $document) {
	my $source = $document->{_doc}{untranslatedCode} // '';
	return unless $source =~ /\\(?:begin|end)\{align\*?\}/;

	return $self->violation(DESCRIPTION, { score => SCORE, explanation => EXPLANATION }, $element);
}

1;

__END__

=head1 NAME

Perl::Critic::Policy::PG::ProhibitAlignStarInLaTeX - prohibit the align
or align* environments inside of LaTeX blocks. 

=head1 DESCRIPTION

Using the C<align> or C<align*> environment inside of a LaTeX block generally 
renders correctly in a browser with MathJax, however there will be 
errors in hardcopy output.  These should be replace with 
C<\begin{aligned}> and C<\end{aligned}>.

An example: 

    [```
      \begin{aligned}
      y & = (x-3)(x-4) \\
      & = x^2 -7x +12
      \end{aligned}
    ```]

=cut
