#!/usr/bin/perl -w

# script to load patron data to wheelers
# Not upstreamable

# Relies on extra config variables in koha-conf.xml
# <Wheelers_Passive></Wheelers_Passive> 
# <Wheelers_Host>io.wheelers.co</Wheelers_Host>
# <Wheelers_Debug>1</Wheelers_Debug> 
# <Wheelers_Username>Name</Wheelers_Username>
# <Wheelers_Password>XXXX</Wheelers_Password>

use strict;
use POSIX qw(strftime);
use Net::FTP;
use C4::Context;

my $context = C4::Context->new();
my $FTP_HOST = $context->config('Wheelers_Host');
my $FTP_PASSIVE = $context->config('Wheelers_Passive') ? $context->config('Wheelers_Passive') : 1;

my $DEBUG = $context->config('Wheelers_Debug');
my $ftp_user = $context->config('Wheelers_Username') or die "Mo FTP_USERNAME";
my $ftp_pass = $context->config('Wheelers_Password') or die "Mo FTP_PASSWORD";

my $usage = <<EOT;
Usage:
$0 [save_dir]
EOT

my $save_dir = shift @ARGV;

my $t = strftime "%F %T", localtime;

my $patrons = C4::Context->dbh->selectall_arrayref("SELECT cardnumber, password FROM borrowers WHERE cardnumber IS NOT NULL AND password IS NOT NULL");

unless ($patrons->[0]->[1] =~ m/\=\=$/) {
    $_->[1] .= "==" foreach @$patrons;
}

my $out = <<EOF;
# version: 0.01                                           
# mode: partial                                           
# algorithm: md5, case-sensitive, base64                                            
# date: $t
# -- bof -- 
EOF
$out .= join "\t", (
  "Barcode",
  "Name",
  "Email",
  "Gender",
  "DOB",
  "Phone",
  "Mobile",
  "Enabled",
  "Member Since",
  "Expires",
  "Category",
  "Tags",
  "PIN",
  "Salt",
  "Balance",
  "Limit",
  "Notice",
  "Meta 1",
  "Meta 2",
  "Meta 3",
  "Meta 4",
  "Meta 5",
  "EOL\n"
);

$out .= $_->[0] . ("\t" x 11) . $_->[1] . ("\t" x 11) . "EOL\n" foreach @$patrons;

$out .= "# -- eof --";

(my $tf = $t) =~ tr/ /-/;
$tf =~ s/://g;
my $fname = "patrons-$tf.txt";

my $path = ($save_dir || "/tmp") . "/$fname";
open my $fh, ">$path";
print $fh $out;
close $fh;

my $ftp = Net::FTP->new($FTP_HOST, Debug => $DEBUG, Passive => $FTP_PASSIVE)
  or die "Cannot connect to $FTP_HOST";

$ftp->login($ftp_user, $ftp_pass)
  or die "Cannot login as $ftp_user ", $ftp->message;

$ftp->ascii;

$ftp->cwd("/todo")
  or die "Cannot cwd ", $ftp->message;

$ftp->put($path, $fname)
  or die "Cannot login as $ftp_user", $ftp->message;

$ftp->quit;

unlink $path unless $save_dir;
