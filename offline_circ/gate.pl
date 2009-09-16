#!/usr/bin/perl
use CGI;
use XML::Simple;
use C4::Circulation;

my $cgi = CGI->new;
my $xml = $cgi->param('POSTDATA');
my $tree = XMLin($xml);

my $branchcode = $tree->{'branchcode'};
my $apply = $tree->{'apply'} eq 'true';

my @operations = ref($tree->{'operation'}) eq 'ARRAY' ? @{$tree->{'operation'}} : ($tree->{'operation'});

for (@operations) {
	if ($apply) {
		
	} else {
		AddOfflineOperation(
			$branchcode,
			$_->{'timestamp'},
			$_->{'action'},
			$_->{'barcode'},
			$_->{'cardnumber'},
		);
	}
}

print "Content-Type:text/html\n\n"; 
print "1";

