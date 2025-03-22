#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0;
use Socket     qw(inet_aton PF_INET SOCK_STREAM sockaddr_in);
use Mojo::File qw(tempfile);

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
do "$ENV{PG_ROOT}/t/build_PG_envir.pl";

use lib "$ENV{PG_ROOT}/lib";

use Rserve;

# Fake configuration if this is disabled (it is by default in pg_config.dist.yml).
$main::Rserve = { host => 'localhost' } unless ref($main::Rserve) eq 'HASH' && $main::Rserve->{host};

my $s;
eval {
	socket($s, PF_INET, SOCK_STREAM, getprotobyname('tcp'))          or die "socket: $!";
	connect($s, sockaddr_in(6311, inet_aton($main::Rserve->{host}))) or die "connect: $!";
	$s->read(my $response, 32);
	$s->close;
	die 'Unrecognized server ID' unless substr($response, 0, 12) eq 'Rsrv0103QAP1';
};

if ($@) {
	plan skip_all => "Cannot connect to Rserve server at $main::Rserve->{host}:6311";
}

my $remote = Rserve->new->eval(
	<<'END'
	local({
		f <- tempfile()
		writeBin(charToRaw("\1\2\3\4\5"), f)
		f
	})
END
)->to_perl->[0];

my $local = $main::PG->surePathToTmpFile($main::PG->getUniqueName('___'));
my $data  = Rserve->new->get_file($remote, $local);

my $expected = "\1\2\3\4\5";
is($data, $expected, 'get_file value');

ok(-e $local, 'html temporary directory file');

my $file_contents = do {
	local $/;
	open(my $in, '<', $local) or die $!;
	my $data = <$in>;
	close $in;
	$data;
};

unlink $local;

is($file_contents, $expected, 'get_file file contents');

$local = tempfile;
like(
	dies { Rserve->new->get_file($remote, $local) },
	qr/Write path $local is unsafe/,
	'cannot save outside html temporary directory'
);

done_testing;
