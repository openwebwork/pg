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
use lib "$ENV{WEBWORK_ROOT}/t";

# After you write your test you should add the number of tests here like
# use Test::More tests => 23

use Test::More qw(no_plan);
use Test::WWW::Selenium;
use Test::Exception;
use Time::HiRes qw(sleep);
use Selenium::Utilities;


my $sel = Test::WWW::Selenium->new( host => "localhost", 
                                    port => 4444, 
                                    browser => "*firefox", 
                                    browser_url => "http://localhost/" );


# Create a test course and a problem 
edit_problem($sel,createCourse=>1, createProblem=>1, seed=>1234);

my $PG_FILE;
open($PG_FILE, ">", "number.pg") or die $!;
my @pglines = <$PG_FILE>;
$sel->type('name=problemContents',join('',@pglines));
$sel->click('id=submit_button_id');
$sel->wait_for_page_to_load(30000);
$sel->type_ok("id=AnSwEr0001", "9 m");
$sel->type_ok("id=AnSwEr0002", "pi Spoon");
$sel->type_ok("id=AnSwEr0003", "3 apple");
$sel->type_ok("id=AnSwEr0004", "0.319185 bear");
$sel->click_ok("id=checkAnswers_id");
$sel->wait_for_page_to_load_ok("30000");
$sel->click_ok("id=showCorrectAnswers_id");
$sel->table_is("//div[\@id='output_summary']/table.1.2", "correct");
$sel->table_is("//div[\@id='output_summary']/table.2.2", "correct");
$sel->table_is("//div[\@id='output_summary']/table.3.2", "correct");
$sel->table_is("//div[\@id='output_summary']/table.4.2", "correct");
$sel->table_is("//div[\@id='output_summary']/table.1.3", "3 bear");
$sel->table_is("//div[\@id='output_summary']/table.2.3", "3.14159 Spoon");
$sel->table_is("//div[\@id='output_summary']/table.3.3", "3 apples");
$sel->table_is("//div[\@id='output_summary']/table.4.3", "3.14159 ft");

delete_course($sel);
