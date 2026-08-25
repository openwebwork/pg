package WeBWorK::PG::SafeIOHandle;

=head1 NAME

WeBWorK::PG::SafeIOHandle - A restricted stand-in for IO::Handle, shared into
the safe compartment.

=head1 DESCRIPTION

L<Rserve> blesses its connection socket as an L<IO::Handle> and uses its
C<print>, C<flush>, C<read>, and C<close> methods. If the C<IO::Handle> package
is shared directly, then all of its methods are exposed. In particular the
C<new_from_fd> method is exposed (in addition to other potentially dangerous
methods such as C<new>, C<fdopen>, etc.) which allows a PG problem to wrap and
read from or write to any file descriptor the process happens to have open. So
instead this package is shared aliased as the C<IO::Handle> package (via
C<WWSafe::share_package_as>) exposing only the necessary methods.

=cut

use strict;
use warnings;

use IO::Handle;

BEGIN {
	no strict 'refs';
	*{"WeBWorK::PG::SafeIOHandle::$_"} = \&{"IO::Handle::$_"} for qw(print flush read close);
	use strict 'refs';
}

1;
