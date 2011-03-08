#!/usr/bin/perl
#
# This Koha test module is a stub!  
# Add more tests here!!!

use strict;
use warnings;

use Test::More tests => 8;

BEGIN {
        use_ok('C4::Output::JSONStream');
}

my $json = new C4::Output::JSONStream;
is($json->output,'{}',"Making sure JSON output is blank just after its created.");
$json->param( issues => [ 'yes!', 'please', 'no' ] );
is($json->output,'{"issues":["yes!","please","no"]}',"Making sure JSON output has added what we told it to.");
$json->param( stuff => ['realia'] );
is($json->output,'{"issues":["yes!","please","no"],"stuff":["realia"]}',"Making sure JSON output has added more params correctly.");
$json->param( stuff => ['fun','love'] );
is($json->output,'{"issues":["yes!","please","no"],"stuff":["fun","love"]}',"Making sure JSON output can obverwrite params.");

eval{$json->param( die )};
ok($@,'Dies');

eval{$json->param( die => ['yes','sure','now'])};
ok(!$@,'Dosent die.');
eval{$json->param( die => ['yes','sure','now'], die2 =>)};
ok($@,'Dies.');
