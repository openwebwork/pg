#!/usr/bin/perl

################################################################################
# WeBWorK Online Homework Delivery System
# Copyright © 2000-2007 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader: webwork2/lib/WeBWorK.pm,v 1.104 2010/05/15 18:44:26 gage Exp $
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

use strict;
use warnings;


BEGIN{ die('You need to set the WEBWORK_ROOT environment variable.\n')
	   unless($ENV{WEBWORK_ROOT});}
use lib "$ENV{WEBWORK_ROOT}/lib";
use lib "$ENV{WEBWORK_ROOT}/t";

use WeBWorK::CourseEnvironment;

my $pg_dir;

BEGIN{ 
    my $ce = new WeBWorK::CourseEnvironment({
	webwork_dir => $ENV{WEBWORK_ROOT},
					 });
 
    $pg_dir = $ce->{pg_dir};
}

use constant TESTING_DIR => "${pg_dir}/t/Selenium/Tests";

# After you write your test you should add the number of tests here like
# use Test::More tests => 23

use Test::More tests=>30;
use Test::WWW::Selenium;
use Test::Exception;
use Time::HiRes qw(sleep);
use Selenium::Utilities;


my $sel = Test::WWW::Selenium->new( host => "localhost", 
                                    port => 4444, 
                                    browser => "*firefox", 
                                    browser_url => "http://localhost/" );


# testParseNumberWithUnits
edit_problem($sel,createCourse=>1, createProblem=>1, seed=>1234);
my $PG_FILE;
open($PG_FILE, "<", TESTING_DIR."/parserNumberWithUnit/number.pg") or die $!;
my @pglines = <$PG_FILE>;
close($PG_FILE);
$sel->type('name=problemContents',join('',@pglines));
$sel->click('id=submit_button_id');
$sel->wait_for_page_to_load(30000);
$sel->type_ok("id=AnSwEr0001", "9 m");
$sel->type_ok("id=AnSwEr0002", "pi Spoon");
$sel->type_ok("id=AnSwEr0003", "3 apple");
$sel->type_ok("id=AnSwEr0004", "0.319185 bear");
$sel->click_ok("id=showCorrectAnswers_id");
$sel->click_ok("id=checkAnswers_id");
$sel->wait_for_page_to_load_ok("30000");
$sel->table_is("//div[\@id='output_summary']/table.1.2", "correct");
$sel->table_is("//div[\@id='output_summary']/table.2.2", "correct");
$sel->table_is("//div[\@id='output_summary']/table.3.2", "correct");
$sel->table_is("//div[\@id='output_summary']/table.4.2", "correct");
$sel->table_like("//div[\@id='output_summary']/table.1.3", qr/3 bear/);
$sel->table_like("//div[\@id='output_summary']/table.2.3", qr/3.14159 Spoon/);
$sel->table_like("//div[\@id='output_summary']/table.3.3", qr/3 apples/);
$sel->table_like("//div[\@id='output_summary']/table.4.3", qr/3.14159 ft/);

# testParseFormulaWithUnits
edit_problem($sel,seed=>1234);
open($PG_FILE, "<", TESTING_DIR."/parserNumberWithUnit/formula.pg") or die $!;
@pglines = <$PG_FILE>;
close($PG_FILE);
$sel->type('name=problemContents',join('',@pglines));
$sel->click('id=submit_button_id');
$sel->wait_for_page_to_load(30000);
$sel->type_ok("id=AnSwEr0001", "9x m");
$sel->type_ok("id=AnSwEr0002", "3.14 x Spoon");
$sel->type_ok("id=AnSwEr0003", "3x apple");
$sel->type_ok("id=AnSwEr0004", "0.319185x bear");
$sel->click_ok("id=showCorrectAnswers_id");
$sel->click_ok("id=checkAnswers_id");
$sel->wait_for_page_to_load_ok("30000");
$sel->table_is("//div[\@id='output_summary']/table.1.2", "correct");
$sel->table_is("//div[\@id='output_summary']/table.2.2", "correct");
$sel->table_is("//div[\@id='output_summary']/table.3.2", "correct");
$sel->table_is("//div[\@id='output_summary']/table.4.2", "correct");
$sel->table_like("//div[\@id='output_summary']/table.1.3", qr/3*x bear/);
$sel->table_like("//div[\@id='output_summary']/table.2.3", qr/3.14*x Spoon/);
$sel->table_like("//div[\@id='output_summary']/table.3.3", qr/3*x apples/);
$sel->table_like("//div[\@id='output_summary']/table.4.3", qr/3.14159*x ft/);

delete_course($sel);
