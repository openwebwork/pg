################################################################################
# WeBWorK mod_perl (c) 2000-2002 WeBWorK Project
# $Id$
################################################################################

package WeBWorK::PG::IO;
use parent qw(Exporter);
use JSON qw(decode_json);
use PGUtil qw(not_null);
use WeBWorK::Utils qw(path_is_subdir);
use WeBWorK::CourseEnvironment;

my $CE = new WeBWorK::CourseEnvironment({
    webwork_dir => $ENV{WEBWORK_ROOT},
					});
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
                path_is_course_subdir
	);

	our @SHARED_FUNCTIONS = qw(
                includePGtext
                read_whole_problem_file
                convertPath
                fileFromPath
                directoryFromPath
                createDirectory
        );

	our %SHARE = map { $_ => __PACKAGE__ } @SHARED_FUNCTIONS;
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


This is used in processing some of the sample CAPA files and 
in creating aliases to redirect calls to duplicate problems so that 
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
	$evalString = $evalString||'';
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
	warn "Can't read file $filePath<br/>" unless -r $filePath;
	return "" unless -r $filePath;
	die "File path $filePath is unsafe." 
	    unless path_is_course_subdir($filePath);
	
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

	die 'Path is unsafe' unless path_is_course_subdir($fileName);

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

=item path_is_course_subdir($path)

Checks to see if the given path is a sub directory of the courses directory

=cut

sub path_is_course_subdir {
    
    return path_is_subdir(shift,$CE->{webwork_courses_dir},1);
}

#
# isolate the call to the sage server in case we have to jazz it up
#
sub query_sage_server {
	my ($python, $url, $accepted_tos, $setSeed, $webworkfunc, $debug, $curlCommand)=@_;
#	my $sagecall = 	qq{$curlCommand -i -k -sS -L --http1.1 --data-urlencode "accepted_tos=${accepted_tos}"}.
	                qq{ --data-urlencode 'user_expressions={"WEBWORK":"_webwork_safe_json(WEBWORK)"}' --data-urlencode "code=${setSeed}${webworkfunc}$python" $url};
	my $sagecall = 	qq{$curlCommand -i -k -sS -L  --data-urlencode "accepted_tos=${accepted_tos}"}.
	                qq{ --data-urlencode 'user_expressions={"WEBWORK":"_webwork_safe_json(WEBWORK)"}' --data-urlencode "code=${setSeed}${webworkfunc}$python" $url};


    my $output  =`$sagecall`;
	if ($debug) {
	    warn "debug is turned on in IO.pm. ";
		warn "\n\nIO::query_sage_server(): SAGE CALL: ", $sagecall, "\n\n";
		warn "\n\nRETURN from sage call \n", $output, "\n\n";
		warn "\n\n END SAGE CALL";	
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
	# find the header 
	# expecting something like
	# 	HTTP/1.1 100 Continue
	
	#	HTTP/1.1 200 OK
	#	Date: Wed, 20 Sep 2017 14:54:03 GMT
    #   ......
    #   two blank lines 
    #   content
          
	# or   (notice that here there is no continue response)
	#   HTTP/2 200
    #   date: Wed, 20 Sep 2017 16:06:03 GMT
    #   ......
    #   two blank lines 
    #   content

	 my ($continue, $header, @content) = split("\r\n\r\n",$output);
	#my $content = join("\r\n\r\n",@content); # handle case where there were blank lines in the content
	 my @lines = split("\r\n\r\n", $output);
	 $continue=0;  
	 my $header_ok =0;
	 while (@lines) {
	 	my $header_block = shift(@lines);
	 	warn "checking for header:  $header_block" if $debug;
	 	next unless $header_block=~/\S/; #skip empty lines;
	 	next if $header_block=~/HTTP/ and $header_block=~/100/; # skip continue line
	 	if ($header_block=~/200/) { # 200 return is ok
	 		$header_ok=1;
	 		last;
	 	}
	 }
	 my $content = join("|||\n|||",@lines) ;  #headers have been removed. 
	 #warn "output list is ", $content; # join("|||\n|||",($continue, $header, $content));
	 #warn "header_ok is $header_ok";  
	my $result;
	if ($header_ok)  { #success put any extraneous splits back together
		$result = join("\r\n\r\n",@lines);
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
  my $args = shift @_;
  my $url = $args->{url} || 'https://sagecell.sagemath.org/service';
  my $seed = $args->{seed};
  my $accepted_tos = $args->{accepted_tos} || 'false';  # force author to accept terms of service explicitly :-)
  my $debug = $args->{debug} || 0;
  my $setSeed = $seed?"set_random_seed($seed)\n":'';
  my $curlCommand = $args->{curlCommand};
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
END



	my $ret={success=>0};   # we want to export more than one piece of information
	eval {
	    my $output = query_sage_server($python, $url, $accepted_tos, $setSeed, $webworkfunc, $debug , $curlCommand);

		# has something been returned?
		not_null($output) or die "Unable to make a sage call to $url."; 
		warn "IO::askSage: We have some kind of value |$output| returned from sage" if $output and $debug; 
        if ($output =~ /"success":\s*true/ and $debug){
        	warn '"success": true is present in the output';
        }
		my $decoded = decode_json($output);
		not_null($decoded) or die "Unable to decode sage output";
		if ($debug and defined $decoded ) {
			my $warning_string = "decoded contents\n ";
			foreach my $key (keys %$decoded) {$warning_string .= "$key=".$decoded->{$key}.", ";}
			$warning_string .= ' end decoded contents';
			#warn "\n$warning_string" if $debug;
			warn " decoded contents \n", PGUtil::pretty_print($decoded, 'text'), "end decoded contents" if $debug;
		}
		# was there a Sage/python syntax Error
		# is the returned something text from stdout (deprecated)
		# have objects been returned in a WEBWORK variable?
		my $success = 0;
		$success = $decoded->{success} if defined $decoded and $decoded->{success};
		warn "success  is $success"  if $debug;
		# the decoding process seems to change the string "true" to "1" sometimes -- we could enforce this
		$success = 1 if defined $success and $success eq 'true';
		$success = 1 if $decoded->{execute_reply}->{status} eq 'ok';
		warn "now success  is $success because status was ok"  if $debug;
		if ($success) {
			my $WEBWORK_variable_non_empty=0;
			my $sage_WEBWORK_data = $decoded->{execute_reply}{user_expressions}{WEBWORK}{data}{'text/plain'};
			warn "sage_WEBWORK_data $sage_WEBWORK_data" if $debug;
			if (not_null($sage_WEBWORK_data) ) {
				$WEBWORK_variable_non_empty =  #another hack because '{}' is sometimes returned
				      ($sage_WEBWORK_data ne "{}" and $sage_WEBWORK_data ne "'{}'") ? 
				      1:0;
			}  # {} indicates that WEBWORK was not used to pass or return a variable from sage.
			
			warn "WEBWORK variable has content"  if $debug and $WEBWORK_variable_non_empty;
			$sage_WEBWORK_data =~s/^'//;  #FIXME -- for now strip off the surrounding single quotes '.
			$sage_WEBWORK_data =~s/'$//;
			warn "sage_WEBWORK_data: ", PGUtil::pretty_print($sage_WEBWORK_data) if $debug and $WEBWORK_variable_non_empty;

			if ( $WEBWORK_variable_non_empty )  { 
				# have specific WEBWORK variables been defined?
				$ret->{webwork} = decode_json($sage_WEBWORK_data);
				$ret->{success}=1;
				$ret->{stdout} = $decoded->{stdout};		
			} elsif (not_null( $decoded->{stdout} ) ) { # no WEBWORK content, but stdout exists
				                         				# old style text output via stdout (deprecated)
				$ret = $decoded->{stdout};				# only standard out is returned
				warn "no content in WEBWORK variable. Returning stdout", $ret if $debug;
			} else {
				die "Error receiving JSON output from sage: \n$output\n ";
			}
		} elsif ($success == 0 )  { # this might be a syntax error
			$ret->{error_message} = $decoded->{execute_reply}; # this is a hash.  # need a better pretty print method
			warn ( "IO.pm: Perhaps there was syntax error.", join(" ",%{ $decoded->{execute_reply}}));
		} else {
			die "IO.pm: Unknown error in asking Sage to do something: success = $success output = \n$output\n";
		}
		
	}; # end eval{} for trapping errors in sage call
	if ($@) {
		warn "IO.pm: ERROR trapped during JSON call to sage:\n $@ ";
		if ( ref($ret)=~/HASH/ ) {
			$ret->{success}=0;
		} else {
			$ret = undef;
		}
	}
	return $ret;
}

=back

=cut

1;
