################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2022 The WeBWorK Project, https://github.com/openwebwork
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

# This creates a User class that is to mimic that on the WeBWorK side from the db.
# PG needs a few of these classes and instead of getting things from the db, which
# it shouldn't have access to, we will use these classes to replicate the same
# features.

package MockDB::User;
use strict;
use warnings;

use base qw/Class::Accessor/;

MockDB::User->mk_accessors(qw/user_id first_name last_name email_address student_id status section
		recitation comment displayMode lis_source_did showOldAnswers useMathView useWirisEditor useMathQuill/);

1;