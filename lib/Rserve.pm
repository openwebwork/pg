package Rserve;

use strict;
use warnings;

use Socket       qw(AF_INET inet_aton inet_ntoa PF_INET SOCK_STREAM sockaddr_in unpack_sockaddr_in);
use Scalar::Util qw(blessed looks_like_number);
use Carp         qw(croak);

use Rserve::QapEncoding;

sub new {
	my ($invocant, @args) = @_;
	my $class = ref($invocant) || $invocant;

	my $attributes;

	if (@args == 0) {
		$attributes = {};
	} elsif (@args == 1) {
		if (ref $args[0] eq 'HASH') {
			$attributes = { %{ $args[0] } };
			($attributes->{server}, $attributes->{port}) = _fh_host_port($attributes->{fh}) if $attributes->{fh};
		} elsif (ref $args[0] eq '') {
			my $server = shift @args;
			my $port;
			($server, $port) = split(/:/, $server) if defined $server && $server =~ /:/;
			$attributes = { server => $server, defined $port ? (port => $port) : () };
		} else {
			my $fh = shift @args;
			my ($server, $port) = _fh_host_port($fh);
			$attributes = {
				fh         => $fh,
				server     => $server,
				port       => $port,
				_autoclose => 0,
				_autoflush => ref($fh) eq 'GLOB'
			};
		}
	} elsif (@args % 2) {
		die "The new method for $class expects a hash reference or a key/value list."
			. " You passed an odd number of arguments\n";
	} else {
		$attributes = {@args};
		($attributes->{server}, $attributes->{port}) = _fh_host_port($attributes->{fh}) if $attributes->{fh};
	}

	my $self = bless $attributes, $class;

	$self->{_autoflush} //= 1;

	$self->{server} //= 'localhost';
	die q{Attribute 'server' must be scalar value}
		if exists($self->{server}) && (!defined $self->server || ref($self->server));

	$self->{port} //= 6311;
	die q{Attribute 'port' must be an integer}
		unless looks_like_number($self->port) && (int($self->port) == $self->port);

	$self->{fh} //= $self->_default_fh;
	die q{Attribute 'fh' must be an instance of IO::Handle or an open filehandle}
		if defined $self->fh
		&& !((ref($self->fh) eq 'GLOB' && Scalar::Util::openhandle($self->fh))
			|| (blessed($self->fh) && $self->fh->isa('IO::Handle')));

	return $self;
}

sub fh         { my $self = shift; return $self->{fh}; }
sub server     { my $self = shift; return $self->{server}; }
sub port       { my $self = shift; return $self->{port}; }
sub _autoflush { my $self = shift; return $self->{_autoflush}; }
sub _autoclose { my $self = shift; return $self->{_autoclose}; }

sub _default_fh {
	my $self = shift;

	socket(my $fh, PF_INET, SOCK_STREAM, getprotobyname('tcp'))      or croak "socket: $!";
	connect($fh, sockaddr_in($self->port, inet_aton($self->server))) or croak "connect: $!";
	bless $fh, 'IO::Handle';

	$self->{_autoclose} = 1 unless defined $self->_autoclose;
	my ($response, $rc) = '';
	while ($rc = $fh->read($response, 32 - length $response, length $response)) { }
	croak $! unless defined $rc;

	croak 'Unrecognized server ID' unless substr($response, 0, 12) eq 'Rsrv0103QAP1';
	return $fh;
}

use constant {
	CMD_login    => 0x001,    # "name\npwd" : -
	CMD_voidEval => 0x002,    # string : -
	CMD_eval     => 0x003,    # string | encoded SEXP : encoded SEXP
	CMD_shutdown => 0x004,    # [admin-pwd] : -

	# security/encryption - all since 1.7-0
	CMD_switch     => 0x005,         # string (protocol) : -
	CMD_keyReq     => 0x006,         # string (request) : bytestream (key)
	CMD_secLogin   => 0x007,         # bytestream (encrypted auth) : -
	CMD_OCcall     => 0x00f,         # SEXP : SEXP -- it is the only command supported in object-capability mode and it
									 # requires that the SEXP is a language construct with OC reference in the first
									 # position
	CMD_OCinit     => 0x434f7352,    # SEXP -- 'RsOC' - command sent from the server in OC mode with the packet of
									 # initial capabilities. file I/O routines. server may answer
	CMD_openFile   => 0x010,         # fn : -
	CMD_createFile => 0x011,         # fn : -
	CMD_closeFile  => 0x012,         # - : -
	CMD_readFile   => 0x013,         # [int size] : data... ; if size not present, server is free to choose any
									 # value - usually it uses the size of its static buffer
	CMD_writeFile  => 0x014,         # data : -
	CMD_removeFile => 0x015,         # fn : -

	# object manipulation
	CMD_setSEXP    => 0x020,         # string(name), REXP : -
	CMD_assignSEXP => 0x021,         # string(name), REXP : - ; same as setSEXP except that the name is parsed

	# session management (since 0.4-0)
	CMD_detachSession    => 0x030,    # : session key
	CMD_detachedVoidEval => 0x031,    # string : session key; doesn't
	CMD_attachSession    => 0x032,    # session key : -

	# control commands (since 0.6-0) - passed on to the master process */
	# Note: currently all control commands are asychronous, i.e. RESP_OK indicates that the command was enqueued in the
	# master pipe, but there is no guarantee that it will be processed. Moreover non-forked connections (e.g. the
	# default debug setup) don't process any control commands until the current client connection is closed so the
	# connection issuing the control command will never see its result.
	CMD_ctrl         => 0x40,    # -- not a command - just a constant --
	CMD_ctrlEval     => 0x42,    # string : -
	CMD_ctrlSource   => 0x45,    # string : -
	CMD_ctrlShutdown => 0x44,    # - : -

	# 'internal' commands (since 0.1-9)
	CMD_setBufferSize => 0x081,    # [int sendBufSize] this commad allow clients to request bigger buffer sizes if
								   # large data is to be transported from Rserve to the client. (incoming buffer is
								   # resized automatically)
	CMD_setEncoding   => 0x082,    # string (one of "native","latin1","utf8") : -; since 0.5-3

	# special commands - the payload of packages with this mask does not contain defined parameters
	CMD_SPECIAL_MASK => 0xf0,
	CMD_serEval      => 0xf5,      # serialized eval - the packets are raw serialized data without data header
	CMD_serAssign    => 0xf6,      # serialized assign - serialized list with [[1]]=name, [[2]]=value
	CMD_serEEval     => 0xf7,      # serialized expression eval - like serEval with one additional evaluation round
};

# Extracts host address and port from the given socket handle (either
# as an object or a "classic" socket)
sub _fh_host_port {
	my $fh = shift;
	if (ref($fh) eq 'GLOB') {
		my ($port, $host) = unpack_sockaddr_in(getpeername($fh)) or return;
		my $name = gethostbyaddr($host, AF_INET);
		return ($name // inet_ntoa($host), $port);
	} elsif (blessed($fh) && $fh->isa('IO::Socket')) {
		return ($fh->peerhost, $fh->peerport);
	}
	return;
}

sub eval {
	my ($self, $expr) = @_;

	# Encode $expr as DT_STRING
	my $parameter = pack('VZ*', ((length($expr) + 1) << 8) + 4, $expr);

	my $data = $self->_send_command(CMD_eval, $parameter);

	my ($value, $state) = @{ Rserve::QapEncoding::decode($data) };
	croak 'Could not parse Rserve value'                 unless $state;
	croak 'Unread data remaining in the Rserve response' unless $state->eof;

	return $value;
}

# Evaluates an R expression guarding it inside an R `try` function. Returns the result as a REXP if no exceptions were
# raised, or `die`s with the text of the exception message.
sub try_eval {
	my ($self, $query) = @_;

	my $result = $self->eval("try({ $query }, silent = TRUE)");
	die $result->to_perl->[0] if $result->inherits('try-error');

	return $result;
}

sub get_file {
	my ($self, $remote, $local) = @_;

	my $data = pack 'C*',
		@{ $self->eval("readBin('$remote', what = 'raw', n = file.info('$remote')[['size']])")->to_perl };

	WeBWorK::PG::IO::saveDataToFile($data, $local) if $local;

	return $data;
}

use constant {
	CMD_RESP => 0x10000,    # all responses have this flag set
	CMD_OOB  => 0x20000,    # out-of-band data - i.e. unsolicited messages
};

use constant {
	RESP_OK  => (CMD_RESP | 0x0001),    # command succeeded; returned
										# parameters depend on the command issued
	RESP_ERR => (CMD_RESP | 0x0002),    # command failed, check stats code
										# attached string may describe the error
	OOB_SEND => (CMD_OOB | 0x1000),     # OOB send - unsolicited SEXP sent from the R instance to the
										# client. 12 LSB are reserved for application-specific code
	OOB_MSG  => (CMD_OOB | 0x2000),     # OOB message - unsolicited message sent from the R instance to the client
										# requiring a response. 12 LSB are reserved for application-specific code
};

# Sends a request to Rserve and receives the response, checking for any errors.
# Returns the data portion of the server response
sub _send_command {
	my ($self, $command, $parameters) = @_;
	$parameters ||= '';

	# request is (byte order is low-endian):
	# - command (4 bytes)
	# - length of the message (low 32 bits)
	# - offset of the data part (normally 0)
	# - high 32 bits of the length of the message (0 if < 4GB)
	$self->fh->print(pack('V4', $command, length($parameters), 0, 0) . $parameters);
	$self->fh->flush if $self->_autoflush;

	my $response = $self->_receive_response(16);
	# Of the next four long-ints:
	# - the first one is status and should be 65537 (bytes \1, \0, \1, \0)
	# - the second one is length
	# - the third and fourth are ??
	my ($status, $length) = unpack VV => substr($response, 0, 8);
	if ($status & CMD_RESP) {
		croak 'R server returned an error: ' . sprintf("0x%X", $status) unless $status == RESP_OK;
	} elsif ($status & CMD_OOB) {
		croak 'OOB messages are not supported yet';
	} else {
		croak "Unrecognized response type: $status";
	}

	return $self->_receive_response($length);
}

sub _receive_response {
	my ($self, $length) = @_;

	my ($response, $offset, $rc) = ('', 0);
	while ($rc = $self->fh->read($response, $length - $offset, $offset)) {
		$offset += $rc;
		last if $length == $offset;
	}
	croak $! unless defined $rc;
	return $response;
}

sub close {
	my $self = shift;
	$self->fh->close if $self->fh;
	return;
}

sub DESTROY {
	my $self = shift;
	$self->close if $self->_autoclose;
	return;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Rserve - Supply object methods for Rserve communication

=head1 SYNOPSIS

    use Rserve;

    my $rserve = Rserve->new('someserver');
    my $var = $rserve->eval('1 + 1');
    print $var->to_perl;
    $rserve->close;

=head1 DESCRIPTION

C<Rserve> provides an object-oriented interface to communicate with the
L<Rserve|http://www.rforge.net/Rserve/> binary R server.

This allows Perl programs to access all facilities of R without the need to have
a local install of R or link to an R library.

=head1 METHODS

=head2 CONSTRUCTOR

=over

=item Rserve->new($server)

The single-argument constructor can be invoked with a scalar containing the host
name of the Rserve server. The method will immediately open a socket connection
to the server and perform the initial steps prescribed by the protocol. The
method will raise an exception if the connection cannot be established or if the
remote host does not appear to run the correct version of Rserve.

=item Rserv->new($handle)

The single-argument constructor can be invoked with an instance of L<IO::Handle>
containing the connection to the Rserve server, which becomes the 'fh'
attribute. The caller is responsible for ensuring that the connection is
established and ready for submitting client requests.

=item Rserve->new(ATTRIBUTE_HASH_OR_HASH_REF)

The constructor's arguments can also be given as a hash or hash reference,
specifying values of the object attributes. The caller passing the handle is
responsible for ensuring that the connection is established and ready for
submitting client requests.

=item new

The no-argument constructor uses the default server name 'localhost' and port
6311 and immediately opens a socket connection to the server, performing the
initial steps prescribed by the protocol. The method will raise an exception if
the connection cannot be established or if the remote host does not appear to
run the correct version of Rserve.

=back

=head2 ACCESSORS

=head3 server

Name of the Rserve server.

=head3 port

Port of the Rserve server.

=head3 fh

A connection handle (stored as a reference to the L<IO::Handle>) to
the Rserve server.

=head2 METHODS

=head3 eval

    $rserve->eval($rexpr)

Evaluates the R expression, given as text string in C<$rexpr>, on an
L<Rserve|http://www.rforge.net/Rserve/> server and returns its result
as a L<Rserve::REXP> object.

=head3 try_eval

    $rserve->try_eval($rexpr)

This is the same as C<eval> except that C<$rexpr> is guarded by the R C<try>
function.  The result is returned as an REXP if no exceptions are raised.

=head3 get_file

    $rserve->get_file($remote_file_name)

Transfers a file named C<$remote_file_name> from the Rserve server to the local
machine. Returns the contents of the file as a scalar.

=head3 close

Closes the object's filehandle. This method is automatically invoked when the
object is destroyed if the connection was opened by the constructor, but not if
it was passed in as a pre-opened handle.

=cut
