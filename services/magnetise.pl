#!/usr/bin/perl

#use CGI;
use YAML qw/LoadFile Dump/;
use IO::Socket::INET;
use Socket qw(:DEFAULT :crlf);
use FindBin qw/$Bin/;
use warnings;
use strict;
my $configfile=$ENV{CONFIG_MAGNETISE}||qq($Bin/etc/magnetise.yaml);
my $ip     = $ARGV[0];
my $op     = $ARGV[1];
my $config = LoadFile($configfile);
my $socket = new IO::Socket::INET(PeerAddr => $ip,
    				PeerPort => $config->{'port'},
#    				LocalPort => $config->{'port'},
                    Reuse=>1,
                    ReuseAddr=>1,
#                    ReusePort=>1,
				    Proto	 => "tcp",
#                    Listen => 5
                	);
die "Could not create socket: $!\n" unless $socket; 
$socket->autoflush(1);
print $socket $config->{'message'}->{$op}; 
$socket->flush();
close($socket);
