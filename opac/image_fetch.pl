#!/usr/bin/perl

# Copyright Catalyst IT 2011


use strict; 
use LWP::Simple;
use warnings;
use CGI;


my $cgi = new CGI;
my $image_type = 'jpg';

my $id = $cgi->param('id');
my $type = $cgi->param('type');
my $size = $cgi->param('size');
my $url;

if ($type eq 'amazon'){    
    $url = "http://images.amazon.com/images/P/$id.01.TZZZZZZZ.jpg";
    if ($size eq 'medium'){
	$url =  "http://images.amazon.com/images/P/$id.01.MZZZZZZZ.jpg";
    }	
    elsif ($size eq 'shelfbrowse'){
	$url =  "http://images.amazon.com/images/P/$id.01._AA75_PU_PU-5_.jpg";
    }
}

print $cgi->header("image/$image_type");

# print $cgi->header;
# print $url;
# binmode; 
my $content = get($url);
print $content;