package WeBWorK::PG::IMathAS;

=head1 NAME

WeBWorK::PG::IMathAS - Render and score IMathAS questions with the help of an
IMathAS server.

=head1 DESCRIPTION

This module talks server-to-server to an IMathAS installation.  That can be an
installation that is run alongside WeBWorK, or a remote one such as MyOpenMath.
Two stock endpoints of IMathAS are used.  C<embedq2.php> shows and scores a
question, and C<util/ptx.php> gives a question as PreTeXt with its correct
answers and its solution.  No changes to IMathAS are needed.

This module is used by the C<IMathAS.pl> macro (through
C<< $PG->imathasQuestion >> and C<< $PG->imathasStaticQuestion >>) and is not
meant to be called directly from problems.

IMathAS servers are configured in the C<imathas> section of C<pg_config.yml>:

    imathas:
      timeout: 10
      defaultServer: local
      servers:
        local:
          url: http://localhost:8088
          publicURL: /imathas
        myopenmath:
          url: https://www.myopenmath.com
          publicURL: https://www.myopenmath.com

Each server in C<servers> has a name and the two settings shown.
C<defaultServer> is the name of the server that is used when no server is asked
for.  MyOpenMath is in the servers of the default configuration, and the default
server (named C<local>) is not, since most sites do not have an IMathAS server
of their own.  Only use a server that you do not run with the permission of
those that do.

C<url> is the address that the WeBWorK server uses to reach IMathAS.
C<publicURL> is the address that a student's browser uses to load the IMathAS
JavaScript and images.

Requests to IMathAS are not signed, so no account on the IMathAS server is
needed.  Note that for a request that is not signed, IMathAS adds 10000 to the
seed that it is given.

=cut

use strict;
use warnings;
use utf8;

use MIME::Base64 qw(decode_base64url);
use Mojo::JSON   qw(decode_json encode_json);

use WeBWorK::PG::IO;
use WeBWorK::PG::PTXToTeX qw(ptx_to_tex);

# The question number that embedq2.php uses for the one question it shows.
use constant QN => 5;

# The settings for the named server, or for the default server if no name is given.  The name of the server and the
# timeout setting are included with the settings of the server.  This dies if the server is not in the configuration.
sub config {
	my $server = shift;
	my $config = $WeBWorK::PG::IO::pg_envir->{imathas};
	$config = {}                       unless ref $config eq 'HASH';
	$server = $config->{defaultServer} unless defined $server && $server ne '';
	die "No default IMathAS server is set.  Set imathas.defaultServer in pg_config.yml.\n"
		unless defined $server && $server ne '';
	my $settings = ref $config->{servers} eq 'HASH' ? $config->{servers}{$server} : undef;
	die qq{The IMathAS server "$server" is not configured in pg_config.yml.}
		. ($server eq ($config->{defaultServer} // '') ? '  That is the default server.' : '') . "\n"
		unless ref $settings eq 'HASH';
	return { timeout => $config->{timeout}, %$settings, name => $server };
}

# IMathAS gives the result of scoring and the state of a question as JWTs.  This returns the payload of one.
sub jwt_decode {
	my $jwt = shift;
	my (undef, $body) = split /\./, $jwt // '';
	die "Malformed token received from IMathAS.\n" unless defined $body;
	return decode_json(decode_base64url($body));
}

sub url_encode {
	my $string = shift // '';
	utf8::encode($string) if utf8::is_utf8($string);
	$string =~ s/([^A-Za-z0-9\-._~])/sprintf('%%%02X', ord($1))/ge;
	return $string;
}

# Note that this is called from inside the safe compartment, and Perl modules that are used via class methods (such as
# HTTP::Tiny) are not available there.  So curl is used as it is for AskSage in WeBWorK::PG::IO.
sub request {
	my ($config, $path, $query, $form) = @_;
	die qq{The IMathAS server "$config->{name}" is not set up.  }
		. "Set its url in the imathas section of pg_config.yml.\n"
		unless $config->{url};
	die qq{The url of the IMathAS server "$config->{name}" in pg_config.yml is not valid.\n}
		unless $config->{url} =~ m{^https?://[^\s;|&`\$?#]+$};

	my $url = ($config->{url} =~ s{/$}{}r) . "/$path";
	$url .= '?' . join('&', map { url_encode($_) . '=' . url_encode($query->{$_}) } sort keys %$query)
		if $query && %$query;

	my $timeout = ($config->{timeout} // '') =~ /^\d+$/ ? $config->{timeout} : 10;

	# The list form of open is used so that no shell is involved.  A name=content argument for --data-urlencode is
	# always taken literally by curl since the names can not contain an "=" or "@" character.
	my @cmd = (
		WeBWorK::PG::IO::externalCommand('curl') || 'curl',
		'-sS', '--fail', '--max-time', $timeout,
		(map { ('--data-urlencode', "$_=" . ($form->{$_} // '')) } grep {/^[\w\-\[\]]+$/} sort keys %$form), $url
	);

	my $content;
	if (open(my $pipe, '-|', @cmd)) {
		local $/;
		$content = <$pipe>;
		close $pipe;
		die "The request to IMathAS failed (curl exit code " . ($? >> 8) . ").\n" if $?;
	} else {
		die "Unable to execute curl: $!\n";
	}

	return $content // '';
}

# Send a request to embedq2.php, the endpoint of IMathAS that shows and scores a question.
sub post {
	my ($config, $query, $form) = @_;
	my $content = request($config, 'embedq2.php', $query, $form);
	my $data    = eval { decode_json($content) };
	# embedq2.php reports problems (such as "Question not available") as plain text.
	die 'IMathAS said: ' . substr($content =~ s/<[^>]*>//gr, 0, 300) . "\n" unless ref $data eq 'HASH';
	return $data;
}

# The part number of an IMathAS input name, or undef if the name is not one for the question.  The answer box of a
# question with one part is named qn5, and those of a question with several parts are named qn6000, qn6001, and so on.
sub part_of_name {
	my $name = shift;
	return unless $name =~ /^(?:qn|tc|qs)(\d+)/;
	return 0         if $1 == QN;
	return $1 % 1000 if $1 >= (QN + 1) * 1000 && $1 < (QN + 2) * 1000;
	return;
}

=head2 question

    my $result = WeBWorK::PG::IMathAS::question(
        { id => $id, seed => $seed, inputs => $inputs_ref, server => $name });

Renders the IMathAS question with the given numeric id and seed from the named
server (the default server if C<server> is not given).  If C<inputs> contains
responses to the question (form fields named as IMathAS names them), then those
responses are scored.

Returns a reference to a hash with the keys

=over

=item html, jsparams, jsparams_json, errors

The question HTML, the parameters that the IMathAS JavaScript needs to
initialize it (also as a JSON string), and any errors that IMathAS reported.
Addresses in the HTML that are relative to the root of the IMathAS server are
changed to start with the C<publicURL> of the server.  The answer entry tips are
not in the parameters (they are in C<boxes> instead), and neither are the
settings for the answer preview of IMathAS since that is not used.

=item boxes

A reference to an array with one hash for each answer box, in order, with keys
C<name> (the name of the form field), C<part>, C<type> (the IMathAS question
type), C<tip> and C<longtip> (the short and long answer entry tips, undef if
there are none), and when scored also C<score> (from 0 to 1) and
C<student_ans>.  The correct answers are not here.  Those are obtained with
C<static_question>.

=item scored, score

Whether responses were scored, and the total score of the question from 0 to 1.

=item publicURL

The C<publicURL> of the server without a trailing slash.

=back

On failure (for example if the server is not configured, can not be reached, or
does not have the question) the hash only has the key C<error>.

=cut

sub question {
	my $params = shift;
	my $result = eval { _question($params) };
	return $result if $result;
	return { error => $@ || 'Unknown error.' };
}

sub _question {
	my $params = shift;
	my $config = config($params->{server});
	my $qn     = QN;

	die "A numeric IMathAS question id is required.\n" unless ($params->{id} // '') =~ /^\d+$/;

	my %settings = (
		id   => $params->{id},
		seed => ($params->{seed} // 0) % 10000,
		# Mathematics is left as AsciiMath for MathJax to typeset.
		mathdisp => 7,
		# Essay answers are plain text, without the IMathAS rich text editor.
		useed              => 0,
		jssubmit           => 1,
		showscoredonsubmit => 1,
		# WeBWorK decides when to show correctness.
		hidescoremarkers => 1,
		hidescoreval     => 1,
		allowregen       => 0,
		showans          => 0,
		maxtries         => 0,
		showansafter     => 0,
	);

	# The first request renders the question and gives its state.
	my $initial = post($config, \%settings, { ajax => 1 });
	my $disp    = $initial->{disp};
	die "Unexpected response from IMathAS.\n" unless ref $disp eq 'HASH' && defined $initial->{state};

	my $result = { scored => 0, score => 0, errors => [] };

	# Score the responses if there are any.
	my %responses = map { $_ => $params->{inputs}{$_} }
		grep { defined part_of_name($_) && !ref $params->{inputs}{$_} } keys %{ $params->{inputs} // {} };
	my %parts = map { part_of_name($_) => 1 } grep { ($responses{$_} // '') =~ /\S/ && !/-choicemap$/ } keys %responses;

	my ($raw, $student);
	if (%parts) {
		my $scored = post(
			$config, undef,
			{
				%responses,
				state     => $initial->{state},
				toscoreqn => encode_json({ $qn => [ sort { $a <=> $b } keys %parts ] })
			}
		);
		my $outcome = jwt_decode($scored->{jwt});
		my $state   = jwt_decode($outcome->{state});

		$result->{scored} = 1;
		$result->{score}  = $outcome->{score} // 0;
		$raw              = $outcome->{raw};
		$student          = $state->{stuanswers}{ $qn + 1 } // $state->{stuanswers}[ $qn + 1 ]
			if ref $state->{stuanswers};
		push(@{ $result->{errors} }, @{ $outcome->{errors} }) if ref $outcome->{errors} eq 'ARRAY';
		$disp = $scored->{disp}                               if ref $scored->{disp} eq 'HASH';
	}

	$result->{html} = $disp->{html} // '';

	# Addresses in the question that are relative to the root of the IMathAS server need to be changed to addresses that
	# work on the page that the question is put in.
	$result->{publicURL} = ($config->{publicURL} // '') =~ s{/$}{}r;
	$result->{html} =~ s{\b(src|href)\s*=\s*(["'])/(?!/)}{$1=$2$result->{publicURL}/}gi;

	$result->{jsparams} = $disp->{jsparams} // {};
	push(@{ $result->{errors} }, @{ $disp->{errors} }) if ref $disp->{errors} eq 'ARRAY';

	# PHP arrays arrive as JSON arrays or objects depending on their keys, so accept both.
	my $at = sub {
		my ($data, $part) = @_;
		return $data->{$part} if ref $data eq 'HASH';
		return $data->[$part] if ref $data eq 'ARRAY';
		return $part == 0 ? $data : undef;
	};
	my $text = sub {
		my $value = shift;
		return ref $value ? encode_json($value) : $value;
	};

	for my $ref (sort { $a <=> $b } grep {/^\d+$/} keys %{ $result->{jsparams} }) {
		my $part = part_of_name("qn$ref");
		next unless defined $part;
		my $box = {
			name => "qn$ref",
			part => $part,
			type => $result->{jsparams}{$ref}{qtype},
			# The answer entry tips are removed from the parameters for the IMathAS JavaScript since the macro shows
			# them in the way that WeBWorK shows help.
			tip     => delete $result->{jsparams}{$ref}{tip},
			longtip => delete $result->{jsparams}{$ref}{longtip}
		};
		# The answer preview of IMathAS is not used.
		delete $result->{jsparams}{$ref}{preview};
		if ($result->{scored}) {
			my $score = $at->($raw, $part);
			# A question that is scored as a whole only has one raw score.
			$score = $result->{score} if !defined $score && ref $raw && (ref $raw eq 'HASH' ? keys %$raw : @$raw) == 1;
			$box->{score}       = !defined $score || $score < 0 ? 0 : $score > 1 ? 1 : $score;
			$box->{student_ans} = $text->($at->($student, $part)) // '';
		}
		push(@{ $result->{boxes} }, $box);
	}

	# Encode this here so that the macro does not need to encode JSON inside the safe compartment.
	$result->{jsparams_json} = encode_json($result->{jsparams});

	return $result;
}

=head2 static_question

    my $result = WeBWorK::PG::IMathAS::static_question(
        { id => $id, seed => $seed, server => $name });

Gets a version of the IMathAS question for output that is not interactive
(hardcopy and PreTeXt).  This uses the C<util/ptx.php> endpoint of IMathAS,
which gives the question as PreTeXt.  The parameters are as for C<question>
(C<inputs> is not used).

Returns a reference to a hash with the keys

=over

=item ptx

The statement of the question as PreTeXt.  This is as IMathAS gives it, except
that each C<fillin> element is given a C<name> attribute with the name of the
answer that it is for.

=item tex

The statement of the question as LaTeX.  This is converted from the PreTeXt by
L<WeBWorK::PG::PTXToTeX>.  Images are not included.

=item answers

A reference to an array with a hash for each answer of the question, in order,
with keys C<name>, C<correct_ans> (as text), and C<correct_tex> (as LaTeX,
undef if the answer is not entirely mathematics).

=item solution

A reference to a hash with the solution of the question as PreTeXt, LaTeX, and
HTML in the keys C<ptx>, C<tex>, and C<html>.  This is only present if the
question has a solution that its author set to be shown with the answers.

=back

On failure the hash only has the key C<error>.

=cut

sub static_question {
	my $params = shift;
	my $result = eval { _static_question($params) };
	return $result if $result;
	return { error => $@ || 'Unknown error.' };
}

sub _static_question {
	my $params = shift;
	my $config = config($params->{server});

	die "A numeric IMathAS question id is required.\n" unless ($params->{id} // '') =~ /^\d+$/;

	# Use the seed that gives the same version of the question that embedq2.php shows.  It adds 10000 to the seed of a
	# request that is not signed, and ptx.php uses the seed as it is given.
	my $seed = ($params->{seed} // 0) % 10000 + 10000;

	my $content = request($config, 'util/ptx.php', { id => $params->{id}, seed => $seed });
	utf8::decode($content);
	$content =~ s/\x{A0}/ /g;
	my ($statement) = $content =~ m{<statement>\s*(.*?)\s*</statement>}s;
	die 'IMathAS did not give the question' . ($content =~ /\S/ ? ': ' . substr($content, 0, 300) : '.') . "\n"
		unless defined $statement;

	# IMathAS puts each answer in a list item.
	my ($answer) = $content =~ m{<answer>\s*(.*?)\s*</answer>}s;
	my @correct = ($answer // '') =~ m{<li>(.*?)</li>}gs;
	my @correct_tex;
	for (@correct) {
		# An answer that is entirely mathematics is also given as LaTeX.
		my ($tex) = m{^\s*<m>\s*(?:\\displaystyle)?\s*(.*?)\s*</m>\s*$}s;
		s{</p>\s*<p>}{, }g;
		s{<m>\s*(?:\\displaystyle)?\s*(.*?)</m>}{$1}gs;
		s{<[^>]*>}{}g;
		for ($_, $tex // ()) {
			s{\\amp\b}{&}g;
			s{\\lt\b}{<}g;
			s{\\gt\b}{>}g;
			s{&lt;}{<}g;
			s{&gt;}{>}g;
			s{&amp;}{&}g;
			s{^\s+|\s+$}{}g;
		}
		# IMathAS gives infinity as text and not as mathematics for some types of questions.
		$tex = ($1 // '') . '\infty' if !defined $tex && /^(-?)oo$/;
		push(@correct_tex, $tex);
	}

	# Name the answers as embedq2.php names the answer boxes, and name the answer blanks for them.
	my $count = () = $statement =~ /<fillin\b/g;
	$count = @correct if @correct > $count;
	my @names = $count == 1 ? ('qn' . QN) : map { 'qn' . ((QN + 1) * 1000 + $_) } 0 .. $count - 1;
	my $blank = 0;
	$statement =~ s{<fillin\b}{'<fillin name="' . $names[ $blank++ ] . '"'}ge;

	# IMathAS only gives a solution if the author of the question set it to be shown with the answers.
	my ($solution) = $content =~ m{<solution>\s*(.*?)\s*</solution>}s;

	return {
		ptx     => $statement,
		tex     => ptx_to_tex($statement),
		answers => [
			map { { name => $names[$_], correct_ans => $correct[$_], correct_tex => $correct_tex[$_] } }
				0 .. $#names
		],
		defined $solution && $solution =~ /\S/
		? (solution => { ptx => $solution, tex => ptx_to_tex($solution), html => ptx_to_html($solution) })
		: ()
	};
}

# Convert the PreTeXt that IMathAS gives for a solution to HTML.  Mathematics is left as LaTeX in the delimiters that
# MathJax uses.  This only deals with the elements that IMathAS uses.
sub ptx_to_html {
	my $ptx = shift;

	# Mathematics and characters are kept here and put back at the end.
	my @kept;
	my $keep = sub { push(@kept, shift); return "\x{0}$#kept\x{0}" };

	my $math = sub {
		my $tex = shift;
		$tex =~ s/\\amp\b/&amp;/g;
		$tex =~ s/\\lt\b/&lt;/g;
		$tex =~ s/\\gt\b/&gt;/g;
		return $tex;
	};
	$ptx =~ s{<m>(.*?)</m>}{$keep->('\\(' . $math->($1) . '\\)')}gse;
	$ptx =~ s{<me>(.*?)</me>}{$keep->('\\[' . $math->($1) . '\\]')}gse;

	my %characters = (
		percent    => '%',
		ampersand  => '&amp;',
		hash       => '#',
		dollar     => '$',
		underscore => '_',
		lbrace     => '{',
		rbrace     => '}',
		lbracket   => '[',
		rbracket   => ']',
		less       => '&lt;',
		greater    => '&gt;',
		tilde      => '~',
		circumflex => '^',
		backslash  => '\\',
		asterisk   => '*',
		ndash      => '&ndash;',
		mdash      => '&mdash;',
		ellipsis   => '&hellip;',
		nbsp       => '&nbsp;',
		lq         => '&ldquo;',
		rq         => '&rdquo;',
		lsq        => '&lsquo;',
		rsq        => '&rsquo;'
	);
	$ptx =~ s{<(\w+)\s*/>}{defined $characters{$1} ? $keep->($characters{$1}) : "<$1/>"}ge;

	my %same    = map { $_ => 1 } qw(p ul li em i u sup sub b strong);
	my %renamed = (
		tabular => 'table',
		row     => 'tr',
		cell    => 'td',
		alert   => 'strong',
		term    => 'strong',
		c       => 'code',
		var     => 'em'
	);

	my $html = '';
	while ($ptx =~ m{\G(?:<(/?)(\w+)\b([^>]*?)(/?)>|([^<]+))}gs) {
		my ($closing, $element, $attributes, $empty, $text) = ($1, $2, $3, $4, $5);
		if (defined $text) {
			$html .= $text;
		} elsif ($same{$element} || $renamed{$element}) {
			$html .= "<$closing" . ($renamed{$element} // $element) . '>';
		} elsif ($element eq 'ol') {
			my ($marker) = $attributes     =~ /\bmarker="([^"]*)"/;
			my $type     = ($marker // '') =~ /A/ ? ' type="A"' : ($marker // '') =~ /a/ ? ' type="a"' : '';
			$html .= $closing ? '</ol>' : "<ol$type>";
		} elsif ($element eq 'q') {
			$html .= $closing ? '&rdquo;' : '&ldquo;';
		} elsif ($element eq 'br') {
			$html .= '<br>' unless $closing;
		} elsif ($element eq 'fillin') {
			$html .= '____' unless $closing;
		} elsif ($element eq 'image') {
			my ($source) = $attributes =~ /\bsource="([^"]*)"/;
			$html .= qq{<img src="$source" alt="">} if !$closing && defined $source;
		} elsif ($element eq 'url') {
			my ($href) = $attributes =~ /\bhref="([^"]*)"/;
			$html .= $closing ? '</a>' : '<a href="' . ($href // '') . '">';
		}
		# Any other element is left out, but what it contains is kept.
	}

	$html =~ s/\x{0}(\d+)\x{0}/$kept[$1]/g;
	$html =~ s/^\s+|\s+$//g;
	return $html;
}

1;
