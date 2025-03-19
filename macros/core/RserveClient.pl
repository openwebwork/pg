
=head1 NAME

RserveClient.pl - Methods for evaluating R code on an Rserve server

=head1 SYNOPSIS

The basic way to call the R server is as follows:

    loadMacros('RserveClient.pl');

    my @rnorm = rserve_eval("rnorm(15, mean = $m, sd = $sd)");
    rserve_eval(data(stackloss));
    my @coeff = rserve_eval('lm(stack.loss ~ stack.x, stackloss)$coeff');

=head1 DESCRIPTION

The methods in this macro provide access to facilities of the
L<R statistical computing environment|http://www.r-project.org>,
optionally located on another server, by using the
L<Rserve|http://www.rforge.net/Rserve/> protocol.

B<IMPORTANT:> Before this macro can be used, the server administrator will need
to configure the location of the Rserve host by setting
C<< $pg_envir->{specialPGEnvironmentVars}{Rserve}{host} >>. For webwork2 this is
accomplished by adding the following line to F<webwork2/conf/localOverrides.conf>:

    $pg{specialPGEnvironmentVars}{Rserve} = { host => "localhost" };

If using PG directly, then uncomment the C<Rserve:> and following C<host:> lines
in F<pg/conf/pg_config.yml>.

Without this configuration, the methods in this macro will display a warning
about the missing configuration and return.

=head1 METHODS

The methods in this file set up a connection to the R server and pass a string
parameter to R for evaluation.  The result is returned as a Perl object.

=head2 rserve_start

=head2 rserve_finish

Start up and close the current connection to the Rserve server. In normal use,
these functions are not needed because a call to any of the other methods will
handle starting the session if one is not already open, and the session will be
closed when processing of the current problem is complete.

Other than for backward compatibility, the only reason for using these functions
is to start a new clean session within a single problem. This shouldn't be a
common occurrence.

=head2 rserve_eval

    $result = rserve_eval($rexpr);

Evaluates an R expression, given as text string in C<$rexpr>, on the
L<Rserve|http://www.rforge.net/Rserve/> server and returns its result as a Perl
representation of the L<Statistics::R::REXP> object.  Multiple calls within the
same problem share the R session and the object workspace.

=head2 rserve_query

    $result = rserve_query($rexpr);

Evaluates an R expression, given as text string in C<$rexpr>, in a single-use
session on the L<Rserve|http://www.rforge.net/Rserve/> server and returns its
result as a Perl representation of the L<Statistics::R::REXP> object.

This function is different from C<rserve_eval> in that each call is completely
self-enclosed and its R session is discarded after it returns.

=head2 rserve_start_plot

    $remoteFile = rserve_start_plot($imgType, $width, $height);

Opens a new R graphics device to capture subsequent graphics output in a
temporary file on the R server. The C<$imgType>, C<$width>, and C<$height>
arguments are optional. The argument C<$imgType> can be one of 'png', 'jpg', or
'pdf', and is set to 'png' if this argument is omitted. If C<$width> and
C<$height> are unspecified, then the R graphics device's default size will be
used. The name of the remote file is returned.

=head2 rserve_finish_plot

    $localFile = rserve_finish_plot($remoteName);

Closes the R graphics capture to file C<$remoteName>, transfers the file to the
directory specified by C<tempDirectory> in the PG environment, and returns the
name of the local file that can then be used by the C<image> method.

=head2 rserve_get_file

    $localFile = rserve_get_file($remoteName);

Transfer the file C<$remoteName> from the R server to the directory specified by
C<tempDirectory> in the PG environment, and returns the name of the local file
that can then be used by the C<htmlLink> method.

This method used to take an optional second argument that specified the local
file name to save to.  That parameter is deprecated, and is ignored if given.

An example of using this method follows.  It is recommended that the
C<rserve_data_url> method be used instead of using this method since it takes
care of the gory details needed to use this method as seen in the example below.

    ($intercept, $slope) = rserve_eval('coef(lm(log(dist) ~ log(speed), data = cars))');

    ($remoteFile) =
        rserve_eval('filename <- tempfile(fileext = ".csv"); '
            . 'write.csv(cars, filename); '
            . 'filename');
    $url = alias(rserve_get_file($remoteFile));

    BEGIN_PGML
    What is the slope of the linear regression of log-transformed stopping
    distance vs. car speed in the dataset linked below: [_]{$slope}{5}

    Download the [@ htmlLink($url, 'dataset', download => 'dataset.csv') @]*
    file.
    END_PGML

=head2 rserve_plot

    $image = rserve_plot($rCode, $width, $height, $imgType);

This method essentially combines C<rserve_start_plot>, C<rserve_eval>, and
C<rserve_finish_plot> into a single method.  For example, calling

    $image = rserve_plot("curve(dnorm(x, mean = $mean), xlim = c(-4, 4)); 0");

is equivalent to calling

    $remoteImage = rserve_start_plot('png');
    rserve_eval("curve(dnorm(x, mean = $mean), xlim = c(-4, 4)); 0");
    $image = rserve_finish_plot($remoteImage);

The arguments C<$width>, C<$height>, and C<$imgType> are optional. If C<$width>
and C<$height> are unspecified, then the R graphics device's default size will
be used. The argument C<$imgType> can be one of 'png', 'jpg', or 'pdf', and is
set to 'png' if this argument is omitted or is not one of the allowed values.

As with C<rserve_finish_plot>, the file path that is returned that can be used
via the C<[!alt text!]{$image}> PGML construct or by the C<image> method.  For
example,

    BEGIN_PGML
    What is the mean of the normal distribution shown in the figure below: [_]{$mean}{5}

    [!normal distribution!]{$image}{300}
    END_PGML

=head2 rserve_data_url

    $url = rserve_data_url($rDataName);

Creates a temporary CSV file on the R server with the data named by
C<$rDataName>, transfers it to the directory specified by C<tempDirectory> in
the PG environment, and returns a URL that can by used with the C<htmlLink>
method. For example,

    ($intercept, $slope) = rserve_eval('coef(lm(log(dist) ~ log(speed), data = cars))');
    $local_url = rserve_data_url('cars');

    BEGIN_PGML
    What is the slope of the linear regression of log-transformed stopping
    distance vs. car speed in the dataset linked below: [_]{$slope}{5}

    Download the [@ htmlLink($url, 'dataset', download => 'dataset.csv') @]*
    file.
    END_PGML

Note that it is recommended that the C<download> attribute be added so that the
download file name will be the value of that attribute rather than the lengthy
alias name in the C<$url>.

=cut

BEGIN { strict->import; }

my $rserve;    # Statistics::R::IO::Rserve instance

sub _rserve_warn_no_config {
	my @trace      = split /\n/, Value::traceback();
	my ($function) = $trace[0] =~ /^\s*in ([^ ]+) at line \d+ of .*/;
	$main::PG->warning_message("Calling $function is disabled unless Rserve host is configured in the PG environment.");
	return;
}

sub rserve_start {
	unless ($main::Rserve->{host}) { _rserve_warn_no_config; return; }

	$rserve = Rserve::access(server => $main::Rserve->{host}, _usesocket => 1);

	# Keep R's RNG reproducible for this problem
	$rserve->eval("set.seed($main::problemSeed)");

	return;
}

sub rserve_finish {
	$rserve->close() if $rserve;
	undef $rserve;
	return;
}

sub rserve_eval {
	my $query = shift;

	unless ($main::Rserve->{host}) { _rserve_warn_no_config; return; }

	rserve_start unless $rserve;

	my $result = Rserve::try_eval($rserve, $query);
	return Rserve::unref_rexp($result);
}

sub rserve_query {
	my $query = shift;

	unless ($main::Rserve->{host}) { _rserve_warn_no_config; return; }

	$query = "set.seed($main::problemSeed)\n" . $query;
	my $rserve_client = Rserve::access(server => $main::Rserve->{host}, _usesocket => 1);
	my $result        = Rserve::try_eval($rserve_client, $query);
	$rserve_client->close;
	return Rserve::unref_rexp($result);
}

sub rserve_start_plot {
	my $imgType = shift // 'png';
	my $width   = shift // '';
	my $height  = shift // '';

	unless ($main::Rserve->{host}) { _rserve_warn_no_config; return; }

	die "Unsupported image type $imgType" unless $imgType =~ /^(png|pdf|jpg)$/;
	my ($remote_image) = rserve_eval("tempfile(fileext = '.$imgType')");

	rserve_eval(($imgType =~ s/jpg/jpeg/r) . "('$remote_image', width = $width, height = $height)");

	return $remote_image;
}

sub rserve_finish_plot {
	my $remote_image = shift or die 'Missing remote image name';

	unless ($main::Rserve->{host}) { _rserve_warn_no_config; return; }

	rserve_eval('dev.off()');

	return rserve_get_file($remote_image);
}

# This used to take a second $local parameter that specified the name of the file that would be saved in the temp
# directory. That parameter is deprecated and is ignored if given. The problem author should have never been given that
# choice. Furthermore, if the $local parameter was not specified the remote file name was used which changes every time
# the problem is rendered.  That is a problem because it results in a different file being saved into the temporary
# directory every time the problem is rendered.  Instead a unique filename is used that is created via PGresource and
# PGalias (and so is dependent on the problem seed, psvn, problem UUID, etc.).
sub rserve_get_file {
	my $remote = shift or die 'Missing remote file name';

	unless ($main::Rserve->{host}) { _rserve_warn_no_config; return; }

	my $ext      = $remote =~ /\.([^.]*)$/ ? $1 : 'png';
	my $filePath = $main::PG->surePathToTmpFile(
		($ext =~ /^(png|jpg|pdf)$/ ? 'images/' : 'data/') . $main::PG->getUniqueName($ext) . ".$ext");

	$rserve->get_file($remote, $filePath);

	return $filePath;
}

sub rserve_plot {
	my ($rCode, $width, $height, $imgType) = @_;

	unless ($main::Rserve->{host}) { _rserve_warn_no_config; return; }

	$width  //= '';
	$height //= '';
	$imgType = 'png' unless $imgType && $imgType =~ /^(png|pdf|jpg)$/;

	my ($remote_image) = rserve_eval("tempfile(fileext = '.$imgType')");
	rserve_eval(($imgType =~ s/jpg/jpeg/r) . "('$remote_image', width = $width, height = $height)");
	rserve_eval($rCode);
	rserve_eval('dev.off()');

	return rserve_get_file($remote_image);
}

sub rserve_data_url {
	my $rDataName = shift;

	unless ($main::Rserve->{host}) { _rserve_warn_no_config; return; }

	my ($remote_file) =
		rserve_eval(qq{filename <- tempfile(fileext = ".csv"); write.csv($rDataName, filename); filename});
	return main::alias(rserve_get_file($remote_file));
}

1;
