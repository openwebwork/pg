################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2018 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader: webwork2/lib/WeBWorK/Utils/DelayedMailer.pm,v 1.2 2007/08/13 22:59:59 sh002i Exp $
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

package WeBWorK::Utils::DelayedMailer;

use strict;
use warnings;
use Carp;
use Net::SMTP;
use WeBWorK::Utils qw/constituency_hash/;

sub new {
	my ($invocant, %options) = @_;
	my $class = ref $invocant || $invocant;
	my $self = bless {}, $class;

	# messages get queued here. format: hashref, safe arguments to MailMsg
	$$self{msgs} = [];

	# SMTP settings
	$$self{smtp_server} = $options{smtp_server};
	$$self{smtp_sender} = $options{smtp_sender};
	$$self{smtp_timeout} = $options{smtp_timeout};

	# extra headers
	$$self{headers} = $options{headers};

	# recipients are checked against this list before sending
	# these should be bare rfc822 addresses, not "Name <email@addr>"
	$$self{allowed_recipients} = constituency_hash(@{$options{allowed_recipients}});

	# what to do if an illegal recipient is specified
	# "croak" (default), "carp", or "ignore"
	$$self{on_illegal_rcpt} = $options{on_illegal_rcpt};

	return $self;
}

# %msg format:
#   $msg{to}      = either a single address or an arrayref containing multiple addresses
#   $msg{subject} = string subject
#   $msg{msg}     = string body of email (this is what Email::Sender::MailMsg uses)
sub add_message {
	my ($self, %msg) = @_;

	# make sure recipients are allowed
	$msg{to} = $self->_check_recipients($msg{to});

	push @{$$self{msgs}}, \%msg;
}

sub _check_recipients {
	my ($self, $rcpts) = @_;
	my @rcpts = ref $rcpts eq "ARRAY" ? @$rcpts : $rcpts;

	my @legal;
	foreach my $rcpt (@rcpts) {
		my ($base) = $rcpt =~ /<([^<>]*)>\s*$/; # works for addresses generated by Record::User
		$base ||= $rcpt; # if it doesn't match, it's a plain address
		if (exists $$self{allowed_recipients}{$base}) {
			push @legal, $rcpt;
		} else {
			if (not defined $$self{on_illegal_rcpt} or $$self{on_illegal_rcpt} eq "croak") {
				die "can't address message to illegal recipient '$rcpt'";
			} elsif ($$self{on_illegal_rcpt} eq "carp") {
				warn "can't address message to illegal recipient '$rcpt'";
			}
		}
	}

	return \@legal;
}

sub send_messages {
	my ($self) = @_;

	return unless @{$$self{msgs}};

	my $smtp = new Net::SMTP($$self{smtp_server}, Timeout=>$$self{smtp_timeout})
		or die "failed to create Net::SMTP object";

	my @results;
	foreach my $msg (@{$$self{msgs}}) {
		push @results, $self->_send_msg($smtp, $msg);
	}

	return @results;
}

sub _send_msg {
	my ($self, $smtp, $msg) = @_;

	my $sender = $$self{smtp_sender};
	my @recipients = @{$$msg{to}};
	my $message = $self->_format_msg($msg);

	# reduce "Foo <bar@bar>" to "bar@bar"
	foreach my $rcpt (@recipients) {
		my ($base) = $rcpt =~ /<([^<>]*)>\s*$/;
		$rcpt = $base if defined $base;
	}

	my %result;

	$smtp->mail($sender);
	my @good_rcpts = $smtp->recipient(@recipients, {SkipBad=>1});
	if (@good_rcpts) {
		my $data_sent = $smtp->data($message);
		unless ($data_sent) {
			$result{error} = "(Error number not available with Net::SMTP)";
			$result{error_msg} = "Unknown error sending message data to SMTP server";
		}
	} else {
		$result{error} = "(Error number not available with Net::SMTP)";
		$result{error_msg} = "No recipient addresses were accepted by SMTP server";
	}

	# figure out which recipients were rejected
	my %bad_rcpts;
	@bad_rcpts{@recipients} = ();
	delete @bad_rcpts{@good_rcpts};
	my @bad_rcpts = keys %bad_rcpts;
	if (@bad_rcpts) {
		$result{skipped_recipients} =
			{ map { $_ => "(Server message not available with Net::SMTP)" } @bad_rcpts };
	}

	return \%result;
}

sub _format_msg {
	my ($self, $msg) = @_;

	my $from = $$self{smtp_sender};
	my $to = join(", ", @{$$msg{to}});
	my $subject = $$msg{subject};
	my $headers = $$self{headers};
	my $body = $$msg{msg};

	my $formatted_msg = "From: $from\n"
		. "To: $to\n"
		. "Subject: $subject\n";
	if (defined $headers) {
		$formatted_msg .= $headers;
		$formatted_msg .= "\n" unless $formatted_msg =~ /\n$/;
	}
	$formatted_msg .= "\n$body";

	return $formatted_msg;
}

1;