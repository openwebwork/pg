################################################################################
# WeBWorK mod-perl (c) 2000-2002 WeBWorK Project
# $Id$
################################################################################

package WeBWorK::PG::IO::WW1;
use base qw(Exporter);

=head1 NAME

WeBWorK::PG::IO::WW1 - Private functions used by WeBWorK::PG::Translator for
file IO under WeBWorK 1.x.

=cut

use strict;
use warnings;
use Net::SMTP;

BEGIN {
	our @EXPORT = qw(
		send_mail_to
		surePathToTmpFile
	);
	
	$WeBWorK::PG::IO::SHARE{$_} = __PACKAGE__ foreach @EXPORT;
}

=head1 FUNCTIONS

=over

=item send_mail_to($user_address,'subject'=>$subject,'body'=>$body)

Returns true if the address is ok, otherwise a fatal error is signaled using
die.

Sends $body to the address specified by $user_address provided that the address
appears in C<@{$Global::PG_environment{'ALLOW_MAIL_TO'}}>.

This subroutine is likely to be fragile and to require tweaking when installed
in a new environment. It uses the C<Net::SMTP> module.

=cut

sub send_mail_to {
	my $user_address = shift;   # user must be an instructor
	my %options = @_;
	
	my $subject = '';
	$subject = $options{'subject'} if defined($options{'subject'});
	
	my $msg_body = '';
	$msg_body =$options{'body'} if defined($options{'body'});
	
	my @mail_to_allowed_list = ();
	@mail_to_allowed_list = @{ $options{'ALLOW_MAIL_TO'} } if defined($options{'ALLOW_MAIL_TO'});
	my $out;
	
	# check whether user is an instructor
	my $mailing_allowed_flag = 0;
	
	while (@mail_to_allowed_list) {
		if ($user_address eq shift @mail_to_allowed_list ) {
			$mailing_allowed_flag =1;
			last;
		}
	}
	
	my $REMOTE_HOST = (defined( $ENV{'REMOTE_HOST'} ) ) ? $ENV{'REMOTE_HOST'}: 'unknown host';
	my $REMOTE_ADDR = (defined( $ENV{'REMOTE_ADDR'}) ) ? $ENV{'REMOTE_ADDR'}: 'unknown address';
	
	if ($mailing_allowed_flag) {
		## mail header text:
		my $email_msg ="To:  $user_address\n"
			. "X-Remote-Host:  $REMOTE_HOST($REMOTE_ADDR)\n"
			. "Subject: $subject\n\n"
			. $msg_body;
		my $smtp = Net::SMTP->new($Global::smtpServer, Timeout=>10)
			or warn "Couldn't contact SMTP server.";
		$smtp->mail($Global::webmaster);
		
		if ( $smtp->recipient($user_address)) {  # this one's okay, keep going
			$smtp->data( $email_msg)
				or warn("Unknown problem sending message data to SMTP server.");
		} else {			# we have a problem a problem with this address
			$smtp->reset;
			warn "SMTP server doesn't like this address: <$user_address>.";
		}
		$smtp->quit;
    } else {
		die "There has been an error in creating this problem.\n"
			. "Please notify your instructor.\n\n"
			. "Mail is not permitted to address $user_address.\n"
			. "Permitted addresses are specified in the courseWeBWorK.ph file.";
		$out = 0;
	}
	
	return $out;
}

=item surePathToTmpFile($path)

Calls C<&main::surePathToTmpFile>.

=cut

sub surePathToTmpFile {
	return main::surePathToTmpFile();
}

=back

=cut

1;
