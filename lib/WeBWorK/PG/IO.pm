################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2023 The WeBWorK Project, https://github.com/openwebwork
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

package WeBWorK::PG::IO;
use parent qw(Exporter);

=head1 NAME

WeBWorK::PG::IO - Functions used by C<WeBWorK::PG::Translator> for file IO.

=head1 DESCRIPTION

This module defines several functions to be shared with a safe compartment by
the PG translator.  All exported methods are shared.

=cut

use strict;
use warnings;
use utf8;

use Encode qw(encode decode);
use JSON qw(decode_json);
use File::Spec::Functions qw(canonpath);
use File::Find qw(finddepth);

use PGUtil qw(not_null);
use WeBWorK::PG::Environment;

our @EXPORT_OK = qw(
	includePGtext
	read_whole_problem_file
	read_whole_file
	fileFromPath
	directoryFromPath
);

my $pg_envir = WeBWorK::PG::Environment->new;

=head1 FUNCTIONS

=head2 includePGtext

This is used in processing some of the sample CAPA files and in creating aliases
to redirect calls to duplicate problems so that they go to the original problem
instead.  It is called by includePGproblem.

Usage: C<includePGtext($str)>

Note that the C<$str> parameter may be a string or a reference to a string.

It reads and evaluates the string in the same way that the Translator evaluates
the string in a PG file.

=cut

sub includePGtext {
	my $evalString = shift;
	$evalString = $$evalString if ref($evalString) eq 'SCALAR';

	no strict;

	# Preprocess code (this method is shared to the WWSafe compartment in Translator::initialize)
	$evalString = eval(q!&{$main::PREPROCESS_CODE}($evalString)!) || '';

	my $errors = $@;
	eval("package main; $evalString");
	$errors .= $@;
	die eval(q!"ERROR in included file:\n$main::envir{probFileName}\n$errors\n$evalString"!) if $errors;

	use strict;

	return '';
}

=head2 read_whole_problem_file

Read the contents of a pg file.

Usage: C<read_whole_problem_file($filePath)>

Don't use for huge files. The file name will have .pg appended to it if it
doesn't already end in .pg.  This is used in importing additional .pg files as
is done in the sample problems translated from CAPA. Returns a reference to a
string containing the contents of the file.

=cut

sub read_whole_problem_file {
	my $filePath = shift;
	$filePath =~ s/^\s*|\s$//g;    # get rid of leading and trailing spaces
	$filePath = "$filePath.pg" unless $filePath =~ /\.pg$/;
	return read_whole_file($filePath);
}

=head2 read_whole_file

Read the contents of a file.  Don't use for huge files.

Usage: C<read_whole_file($filePath)>

=cut

sub read_whole_file {
	my $filePath = shift;

	unless (-r $filePath) {
		warn "Can't read file $filePath.";
		return '';
	}
	die "File path $filePath is unsafe." unless path_is_readable_subdir($filePath);

	open(my $INPUT, "<:raw", $filePath) or die "$0: read_whole_file subroutine: Can't read file $filePath";
	local $/ = undef;
	my $string = <$INPUT>;
	close($INPUT);

	my $backup_string = $string;
	unless (utf8::decode($string)) {
		warn "There was an error decoding $filePath as UTF-8, will try to upgrade";
		$string = utf8::upgrade($backup_string);
	}

	return \$string;
}
# <:utf8 is more relaxed on input, <:encoding(UTF-8) would be better, but
# perhaps it's not so horrible to have lax input. encoding(UTF-8) tries to use require
# to import Encode, Encode::Alias::find_encoding and Safe raises an exception.
# haven't figured a way around this yet.

=head2 fileFromPath

Usage: C<fileFromPath($path)>

Returns the last segment of the path (i.e. the text after the last forward
slash).

=cut

sub fileFromPath {
	my $path = shift;
	$path =~ m|([^/]+)$|;
	return $1;
}

=head2 directoryFromPath

Usage: C<directoryFromPath($path)>

Returns the initial segments of the of the path (i.e. the text up to the last
forward slash).

=cut

sub directoryFromPath {
	my $path = shift;
	$path =~ s|[^/]*$||;
	return $path;
}

=head2 createFile

Usage: C<createFile($fileName, $permission, $numgid)>

Creates a file with the given name, permission bits, and group ID.

=cut

sub createFile {
	my ($fileName, $permission, $numgid) = @_;

	die 'Path is unsafe' unless path_is_readable_subdir($fileName);

	open(my $TEMPCREATEFILE, ">:encoding(UTF-8)", $fileName) or die "Can't open $fileName: $!";
	my @stat = stat $TEMPCREATEFILE;
	close($TEMPCREATEFILE);

	# If the owner of the file is running this script (e.g. when the file is
	# first created) set the permissions and group correctly.
	if ($< == $stat[4]) {
		my $tmp = chmod($permission, $fileName)
			or warn "Can't do chmod($permission, $fileName): $!";
		chown(-1, $numgid, $fileName)
			or warn "Can't do chown($numgid, $fileName): $!";
	}

	return;
}

=head2 createDirectory

Usage: C<createDirectory($dirName, $permission, $numgid)>

Creates a directory with the given name, permission bits, and group ID.

=cut

sub createDirectory {
	my ($dirName, $permission, $numgid) = @_;

	$permission //= oct(770);

	my $errors = '';
	mkdir($dirName, $permission)
		or $errors .= "Can't do mkdir($dirName, $permission): $!\n" . caller(3);
	chmod($permission, $dirName)
		or $errors .= "Can't do chmod($permission, $dirName): $!\n" . caller(3);
	unless ($numgid == -1) {
		chown(-1, $numgid, $dirName)
			or $errors .= "Can't do chown(-1,$numgid,$dirName): $!\n" . caller(3);
	}

	if ($errors) {
		warn $errors;
		return 0;
	} else {
		return 1;
	}
}

=head2 remove_tree

Usage: C<remove_tree($dir)>

Remove a directory and its contents.

=cut

sub remove_tree {
	my $dir = shift;

	finddepth sub {
		if (!-l && -d _) {
			rmdir($File::Find::name) or warn "Unable to remove directory $File::Find::name: $!";
		} else {
			unlink($File::Find::name) or warn "Unable to delete file $File::Find::name: $!";
		}
	}, $dir;
}

# This is needed for the subroutine below.  It is copied from WeBWorK::Utils.
# Note: if a place for common code is ever created this should go there.

sub path_is_subdir {
	my ($path, $dir, $allow_relative) = @_;

	unless ($path =~ /^\//) {
		if ($allow_relative) {
			$path = "$dir/$path";
		} else {
			return 0;
		}
	}

	$path = canonpath($path);
	$path .= "/" unless $path =~ m|/$|;
	return 0 if $path =~ m#(^\.\.$|^\.\./|/\.\./|/\.\.$)#;

	$dir = canonpath($dir);
	$dir .= "/" unless $dir =~ m|/$|;
	return 0 unless $path =~ m|^$dir|;

	return 1;
}

=head2 path_is_readable_subdir

Usage: C<path_is_readable_subdir($path)>

Checks to see if the given path is a sub directory of the directory the caller
says we are allowed to read from.

=cut

sub path_is_readable_subdir {
	return path_is_subdir(shift, $pg_envir->{directories}{permitted_read_dir}, 1);
}

=head2 pg_tmp_dir

Returns the temporary directory set in the WeBWorK::PG::Environment.

=cut

sub pg_tmp_dir {
	return $pg_envir->{directories}{tmp};
}

=head2 externalCommand

Usage: C<externalCommand($command)>

Returns the path to a requested external command that is defined in the
C<WeBWorK::PG::Environment>.

=cut

sub externalCommand {
	my $cmd = shift;
	return $pg_envir->{externalPrograms}{$cmd};
}

# Isolate the call to the sage server in case we have to jazz it up.
sub query_sage_server {
	my ($python, $url, $accepted_tos, $setSeed, $webworkfunc, $debug, $curlCommand) = @_;
	my $sagecall =
		qq{$curlCommand -i -k -sS -L }
		. qq{--data-urlencode "accepted_tos=${accepted_tos}" }
		. qq{--data-urlencode 'user_expressions={"WEBWORK":"_webwork_safe_json(WEBWORK)"}' }
		. qq{--data-urlencode "code=${setSeed}${webworkfunc}$python" $url};

	my $output = `$sagecall`;
	if ($debug) {
		warn "debug is turned on in IO.pm. ";
		warn "\n\nIO::query_sage_server(): SAGE CALL: ", $sagecall, "\n\n";
		warn "\n\nRETURN from sage call \n",             $output,   "\n\n";
		warn "\n\n END SAGE CALL";
	}

	# Has something been returned?
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

	my ($continue, $header, @content) = split("\r\n\r\n", $output);
	my @lines = split("\r\n\r\n", $output);
	$continue = 0;
	my $header_ok = 0;
	while (@lines) {
		my $header_block = shift(@lines);
		warn "checking for header:  $header_block" if $debug;
		next unless $header_block =~ /\S/;                # skip empty lines;
		next if ($header_block =~ m!HTTP[ 12/.]+100!);    # skip continue line
		if ($header_block =~ m!HTTP[ 12/.]+200!) {        # 200 return is ok
			$header_ok = 1;
			last;
		}
	}
	my $content = join("|||\n|||", @lines);               # headers have been removed.
	my $result;
	if ($header_ok) {
		# Success! Put any extraneous splits back together.
		$result = join("\r\n\r\n", @lines);
	} else {
		warn "ERROR in contacting sage server. Did you accept the terms of service by "
			. "setting { accepted_tos => 'true' } in the askSage options?\n$content\n";
		$result = undef;
	}

	return $result;
}

=head2 AskSage

Usage: C<AskSage($python, $args)>

Executes a sage cell server query via curl and returns the result.

=cut

sub AskSage {
	my ($python, $args) = @_;
	chomp($python);

	# To send values back in a hash, add them to the python WEBWORK dictionary.
	my $url          = $args->{url} || 'https://sagecell.sagemath.org/service';
	my $seed         = $args->{seed};
	my $accepted_tos = $args->{accepted_tos} || 'false';    # Force author to accept terms of service explicitly.
	my $debug        = $args->{debug}        || 0;
	my $setSeed      = $seed ? "set_random_seed($seed)\n" : '';
	my $curlCommand  = $args->{curlCommand};

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

	my $ret = { success => 0 };    # We want to export more than one piece of information.
	eval {
		my $output = query_sage_server($python, $url, $accepted_tos, $setSeed, $webworkfunc, $debug, $curlCommand);

		# has something been returned?
		not_null($output) or die "Unable to make a sage call to $url.";
		warn "IO::askSage: We have some kind of value |$output| returned from sage" if $output and $debug;
		if ($output =~ /"success":\s*true/ and $debug) {
			warn '"success": true is present in the output';
		}
		my $decoded = decode_json($output);
		not_null($decoded) or die "Unable to decode sage output";
		if ($debug and defined $decoded) {
			my $warning_string = "decoded contents\n ";
			foreach my $key (keys %$decoded) { $warning_string .= "$key=" . $decoded->{$key} . ", "; }
			$warning_string .= ' end decoded contents';
			warn " decoded contents \n", PGUtil::pretty_print($decoded, 'text'), "end decoded contents" if $debug;
		}
		# Was there a Sage/python syntax error?
		# Is the returned something text from stdout? (deprecated)
		# Have objects been returned in a WEBWORK variable?
		my $success = 0;
		$success = $decoded->{success} if defined $decoded and $decoded->{success};
		warn "success  is $success" if $debug;
		# The decoding process seems to change the string "true" to "1" sometimes -- we could enforce this
		$success = 1 if defined $success and $success eq 'true';
		$success = 1 if $decoded->{execute_reply}->{status} eq 'ok';
		warn "now success  is $success because status was ok" if $debug;
		if ($success) {
			my $WEBWORK_variable_non_empty = 0;
			my $sage_WEBWORK_data          = $decoded->{execute_reply}{user_expressions}{WEBWORK}{data}{'text/plain'};
			warn "sage_WEBWORK_data $sage_WEBWORK_data" if $debug;
			if (not_null($sage_WEBWORK_data)) {
				$WEBWORK_variable_non_empty =    # another hack because '{}' is sometimes returned
					($sage_WEBWORK_data ne "{}" and $sage_WEBWORK_data ne "'{}'") ? 1 : 0;
			}    # {} indicates that WEBWORK was not used to pass or return a variable from sage.

			warn "WEBWORK variable has content" if $debug and $WEBWORK_variable_non_empty;
			$sage_WEBWORK_data =~ s/^'//;    # FIXME: For now strip off the surrounding single quotes.
			$sage_WEBWORK_data =~ s/'$//;
			warn "sage_WEBWORK_data: ", PGUtil::pretty_print($sage_WEBWORK_data)
				if $debug and $WEBWORK_variable_non_empty;

			if ($WEBWORK_variable_non_empty) {
				# Have specific WEBWORK variables been defined?
				$ret->{webwork} = decode_json($sage_WEBWORK_data);
				$ret->{success} = 1;
				$ret->{stdout}  = $decoded->{stdout};
			} elsif (not_null($decoded->{stdout})) {
				# No WEBWORK content, but stdout exists.
				# Old style text output via stdout (deprecated)
				$ret = $decoded->{stdout};    # only standard out is returned
				warn "no content in WEBWORK variable. Returning stdout", $ret if $debug;
			} else {
				die "Error receiving JSON output from sage: \n$output\n ";
			}
		} elsif ($success == 0) {
			# This might be a syntax error.
			$ret->{error_message} = $decoded->{execute_reply};    # This is a hash.  Need a better pretty print method.
			warn("IO.pm: Perhaps there was syntax error.", join(" ", %{ $decoded->{execute_reply} }));
		} else {
			die "IO.pm: Unknown error in asking Sage to do something: success = $success output = \n$output\n";
		}

	};    # end eval{} for trapping errors in sage call

	if ($@) {
		warn "IO.pm: ERROR trapped during JSON call to sage:\n $@ ";
		if (ref($ret) =~ /HASH/) {
			$ret->{success} = 0;
		} else {
			$ret = undef;
		}
	}

	return $ret;
}

1;
