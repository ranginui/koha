#!/usr/bin/perl -w

use strict;
use POSIX qw(strftime);
use Net::FTP;
use C4::Context;

my $FTP_HOST = "io.wheelers.co";
my $FTP_PASSIVE = 1;

my $DEBUG = $ENV{FTP_DEBUG};
my $ftp_user = $ENV{FTP_USERNAME} or die "Mo FTP_USERNAME env";
my $ftp_pass = $ENV{FTP_PASSWORD} or die "Mo FTP_PASSWORD env";

my $usage = <<EOT;
Usage:
$0 [save_dir]
EOT

my $save_dir = shift @ARGV;

my $t = strftime "%FT%T", localtime;

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
  "Expires Category",
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

$out .= $_->[0] . ("\t" x 11) . $_->[1] . ("\t" x 10) . "EOL\n" foreach @$patrons;

$out .= "# -- eof --";

my $fname = "patrons.$t.txt";

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
