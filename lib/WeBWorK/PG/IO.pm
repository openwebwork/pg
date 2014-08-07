################################################################################
# WeBWorK mod_perl (c) 2000-2002 WeBWorK Project
# $Id$
################################################################################

package WeBWorK::PG::IO;
use parent qw(Exporter);
use JSON qw(decode_json);
use PGUtil qw(not_null);
=head1 NAME

WeBWorK::PG::IO - Private functions used by WeBWorK::PG::Translator for file IO.

=cut

use strict;
use warnings;

BEGIN {
	our @EXPORT = qw(
		includePGtext
		read_whole_problem_file
		read_whole_file
		convertPath
		getDirDelim
		fileFromPath
		directoryFromPath
		createFile
		createDirectory
		AskSage
	);

	our %SHARE = map { $_ => __PACKAGE__ } @EXPORT;
	my $ww_version = "2.x";  # hack -- only WW2 versions are supported.
	if (defined $ww_version) {
		my $mod;
		for ($ww_version) {
			/^1\./          and $mod = "WeBWorK::PG::IO::WW1";
			/^2\./          and $mod = "WeBWorK::PG::IO::WW2";
			/^Daemon\s*2\./ and $mod = "WeBWorK::PG::IO::Daemon2";
		}
		
		eval "package Main; require $mod; import $mod"; # this is runtime_use
		die $@ if $@;
	} else {
		warn "\$main::VERSION not defined -- not loading version-specific IO functions";
	}
}

=head1 SYNOPSIS

 BEGIN { $main::VERSION = "2.0" }
 use WeBWorK::PG::IO;
 my %functions_to_share = %WeBWorK::PG::IO::SHARE;

=head1 DESCRIPTION

This module defines several functions to be shared with a safe compartment by
the PG translator. It also loads a version-specific module (if found) based on
the value of the C<$main::VERSION> variable.

This module also maintains a hash C<%WeBWorK::PG::IO::SHARE>. The keys of this
hash are the names of functions, and the values are the name of the package that
contains the function.

=head1 FUNCTIONS

=over

=item includePGtext($string_ref, $envir_ref)


This is used in processing some of the sample CAPA files and in creating aliases to redirect calls to duplicate problems so that 
they go to the original problem instead.  It is called by includePGproblem.

It reads and evaluates the string in the same way that the Translator evaluates the string in a PG file.

=cut

sub includePGtext  {
	my $evalString = shift;
	if (ref($evalString) eq 'SCALAR') {
		$evalString = $$evalString;
	}
#	$evalString =~ s/\nBEGIN_TEXT/\nTEXT\(EV3\(<<'END_TEXT'\)\);/g;
#	$evalString =~ s/\\/\\\\/g; # \ can't be used for escapes because of TeX conflict
#	$evalString =~ s/~~/\\/g;   # use ~~ as escape instead, use # for comments
	no strict;
	$evalString = eval( q! &{$main::PREPROCESS_CODE}($evalString) !); 
	# current preprocessing code passed from Translator (see Translator::initialization)
	my $errors = $@;
	eval("package main; $evalString") ;
	$errors .= $@;
	die eval(q! "ERROR in included file:\n$main::envir{probFileName}\n $errors\n$evalString"!) if $errors;
	use strict;
	return "";
}

=item read_whole_problem_file($filePath)

Don't use for huge files. The file name will have .pg appended to it if it
doesn't already end in .pg.  Files may become double spaced.?  Check the join
below. This is used in importing additional .pg files as is done in the sample
problems translated from CAPA. Returns a reference to a string containing the
contents of the file.

=cut

sub read_whole_problem_file {
	my $filePath = shift;
	$filePath =~s/^\s*//; # get rid of initial spaces
	$filePath =~s/\s*$//; # get rid of final spaces
	$filePath = "$filePath.pg" unless $filePath =~ /\.pg$/;
	read_whole_file($filePath);
}

sub read_whole_file {
	my $filePath = shift;
	local (*INPUT);
	open(INPUT, "<$filePath") || die "$0: read_whole_file subroutine: <BR>Can't read file $filePath";
	local($/)=undef;
	my $string = <INPUT>;  # can't append spaces because this causes trouble with <<'EOF'   \nEOF construction
	close(INPUT);
	\$string;
}

=item convertPath($path)

Currently a no-op. Returns $path unmodified.

=cut

sub convertPath {
    return wantarray ? @_ : shift;
}

sub getDirDelim {
	return ("/");
}

=item fileFromPath($path)

Uses C<&getDirDelim> to determine the path delimiter.  Returns the last segment
of the path (i.e. the text after the last delimiter).

=cut

sub fileFromPath {
	my $path = shift;
	my $delim = &getDirDelim();
	$path = convertPath($path);
	$path =~ m|([^$delim]+)$|;
	$1;
}

=item directoryFromPath($path)

Uses C<&getDirDelim> to determine the path delimiter.  Returns the initial
segments of the of the path (i.e. the text up to the last delimiter).

=cut
   
sub directoryFromPath {
	my $path = shift;
	my $delim = &getDirDelim();
	$path = convertPath($path);
	$path =~ s|[^$delim]*$||;
	$path;
}

=item createFile($fileName, $permission, $numgid)

Creates a file with the given name, permission bits, and group ID.

=cut

sub createFile {
	my ($fileName, $permission, $numgid) = @_;
	open(TEMPCREATEFILE, ">$fileName")
		or die "Can't open $fileName: $!";
	my @stat = stat TEMPCREATEFILE;
	close(TEMPCREATEFILE);
	
	# if the owner of the file is running this script (e.g. when the file is
	# first created) set the permissions and group correctly
	if ($< == $stat[4]) {
		my $tmp = chmod($permission, $fileName)
			or warn "Can't do chmod($permission, $fileName): $!";
		chown(-1, $numgid, $fileName)
			or warn "Can't do chown($numgid, $fileName): $!";
	}
}

=item createDirectory($dirName, $permission, $numgid)

Creates a directory with the given name, permission bits, and group ID.

=cut

sub createDirectory {
	my ($dirName, $permission, $numgid) = @_;
	$permission = (defined($permission)) ? $permission : '0770';
	# FIXME -- find out where the permission is supposed to be defined
	my $errors = '';
	mkdir($dirName, $permission)
		or $errors .= "Can't do mkdir($dirName, $permission): $!\n".caller(3);
	chmod($permission, $dirName)
		or $errors .= "Can't do chmod($permission, $dirName): $!\n".caller(3);
	unless ($numgid == -1) {
		chown(-1,$numgid,$dirName)
			or $errors .= "Can't do chown(-1,$numgid,$dirName): $!\n".caller(3);
	}
	if ($errors) {
		warn $errors;
		return 0;
	} else {
		return 1;
	}
}
#
# isolate the call to the sage server in case we have to jazz it up
#
sub query_sage_server {
	my ($python, $url, $accepted_tos, $setSeed, $webworkfunc, $debug)=@_;
	my $output = `curl -i -k -sS -L --data-urlencode "accepted_tos=${accepted_tos}" --data-urlencode "user_variables=WEBWORK" --data-urlencode "code=${setSeed}${webworkfunc}$python" $url`;
	my $sagecall = 	qq{
		curl -k -sS -L --data-urlencode "accepted_tos=${accepted_tos}" 
		--data-urlencode "user_variables=WEBWORK" --data-urlencode 
		"code=${setSeed}${webworkfunc}$python" $url
	};
	if ($debug) {
		warn "\n\nSAGE CALL: ", $sagecall, "\n\n";
		warn "\n\nRETURN from sage call \n", $output, "\n\n";	
	}
		# has something been returned?
		# $continue: 	HTTP/1.1 100 (Continue)
		# $header: 		HTTP/1.1 200 OK
		# 				Content-Length: 1625
		# 				Server: TornadoServer/3.1
		# 				Access-Control-Allow-Credentials: true
		# 				Date: Sun, 24 Nov 2013 11:44:33 GMT
		# 				Access-Control-Allow-Origin: *
		# 				Content-Type: application/json; charset=UTF-8
		# $content: Either error message about terms of service or output from sage
	my ($continue, $header, @content) = split("\r\n\r\n",$output);
	my $content = join("\r\n\r\n",@content); # handle case where there were blank lines in the content
	# warn "output list is ", join("|||\n|||",($continue, $header, @content));
	# warn "header is $header    =" , $header =~/200 OK\r\n/;
	my $result;
	if ($header =~/200 OK\r\n/)  { #success 
		$result = $content;
	} else {
		warn "ERROR in contacting sage server. Did you accept the terms of service by 
		      setting {accepted_tos=>'true'} in the askSage options?\n $content\n";
		$result = undef;
	}
	$result;	
}

sub AskSage {
#
# to send values back in a hash, add them to the python WEBWORK dictionary
#
  chomp(my $python = shift);
  my ($args) = @_;
  my $url = $args->{url} || 'https://sagecell.sagemath.org/service';
  my $seed = $args->{seed};
  my $accepted_tos = $args->{accepted_tos} || 'false';  # force author to accept terms of service explicitly :-)
  my $debug = $args->{debug} || 0;
  my $setSeed = $seed?"set_random_seed($seed)\n":'';
  my $webworkfunc = <<END;
WEBWORK={}
def _webwork_safe_json(o):
    import json
    def default(o):
        try:
            if isinstance(o,sage.rings.integer.Integer):
                json_obj = int(o)
            elif isinstance(o,(sage.rings.real_mpfr.RealLiteral, sage.rings.real_mpfr.RealNumber)):
                json_obj = float(o)
            elif sage.modules.free_module_element.is_FreeModuleElement(o):
                json_obj = list(o)
            elif sage.matrix.matrix.is_Matrix(o):
                json_obj = [list(i) for i in o.rows()]
            elif isinstance(o, SageObject):
                json_obj = repr(o)
            else:
                raise TypeError
        except TypeError:
            pass
        else:
            return json_obj
        # Let the base class default method raise the TypeError
        return json.JSONEncoder.default(self, o)
    return json.dumps(o, default=default)
get_ipython().display_formatter.formatters['application/json'].for_type(dict,_webwork_safe_json)
END



	my $ret={success=>0};   # we want to export more than one piece of information
	eval {
	    my $output = query_sage_server($python, $url, $accepted_tos, $setSeed, $webworkfunc, $debug );

		# has something been returned?
		not_null($output) or die "Unable to make a sage call to $url."; 
		# warn "We have some kind of value |$output| returned from sage" if $output; #remove this
		
		my $decoded = decode_json($output);
		# was there a Sage/python syntax Error
		# is the returned something text from stdout (deprecated)
		# have objects been returned in a WEBWORK variable?
		# warn "test condition = ", $decoded->{user_variables}{WEBWORK}{data}{'application/json'} ne "{}";
		if ($decoded->{success} eq 'true') {
		    my $WEBWORK_variable_non_empty=0;
			if (not_null($decoded->{user_variables}{WEBWORK}{data}{'application/json'}) ) {
				$WEBWORK_variable_non_empty = $decoded->{user_variables}{WEBWORK}{data}{'application/json'} ne "{}";
			}  # {} indicates that WEBWORK was not used to pass or return a variable from sage.

			if ( $WEBWORK_variable_non_empty )  { 
				# have specific WEBWORK variables been defined?
				$ret->{webwork} = decode_json($decoded->{user_variables}{WEBWORK}{data}{'application/json'});
				$ret->{success}=1;
				$ret->{stdout} = $decoded->{stdout};		
			} elsif (not_null( $decoded->{stdout} ) ) { # no WEBWORK content, but stdout exists
                                                           # old style text output via stdout (deprecated)
				$ret = $decoded->{stdout};                 # only standard out is returned
			} else {
				die "Error receiving JSON output from sage: \n$output\n ";
			}
		} elsif ($decoded->{success} eq 'false' )  { # this might be a syntax error
			$ret->{error_message} = $decoded->{execute_reply}; # this is a hash.
			warn "Perhaps there was syntax error.", join(" ",%{ $decoded->{execute_reply}});
		} else {
			die "Unknown error in asking Sage to do something: \n$output\n";
		}
		
	}; # end eval{} for trapping errors in sage call
	if ($@) {
		warn "IO.pm: ERROR trapped during JSON call to sage:\n $@ ";
		if ( ref($ret)=~/HASH/ ) {
			$ret->{success}=0;
		} else {

		}
	}
	return $ret;
}

=back

=cut

1;
