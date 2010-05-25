#!/usr/bin/perl
# Re-create statistics from issues and old_issues tables
# (please note that this is not an accurate process)

# If the issue is still in the issues table, we can re-create issues or renewals
# If the issue is already in the old_issues table, we can re-create returns

use strict;
use warnings;
use C4::Context;
use C4::Items;
use Data::Dumper;

my $dbh = C4::Context->dbh;

foreach my $table ('issues', 'old_issues') {

    print "looking for missing statistics from the $table table\n";

    my $query = "SELECT * from $table where itemnumber is not null";

    my $sth = $dbh->prepare($query);
    $sth->execute;
    while (my $hashref = $sth->fetchrow_hashref) {

	my $ctnquery = "SELECT count(*) as cnt FROM statistics WHERE borrowernumber = ? AND itemnumber = ? AND datetime = ?";
	my $substh = $dbh->prepare($ctnquery);
	$substh->execute($hashref->{'borrowernumber'}, $hashref->{'itemnumber'}, $hashref->{'timestamp'});
	my $count = $substh->fetchrow_hashref->{'cnt'};
	if ($count == 0) {
	    my $insert = "INSERT INTO statistics (datetime, branch, value, type, other, itemnumber, itemtype, borrowernumber) 
				 VALUES(?, ?, ?, ?, ?, ?, ?, ?)";
	    $substh = $dbh->prepare($insert);

	    my $type = ($table eq 'old_issues') ? 'return' : ($hashref->{'renewals'} ? 'renew' : 'issue') ;
	    my $item = GetItem($hashref->{'itemnumber'});

	    $substh->execute(
		$hashref->{'timestamp'},
		$hashref->{'branchcode'},
		0,
		$type,
		'',
		$hashref->{'itemnumber'},
		$item->{'itype'},
		$hashref->{'borrowernumber'}
	    );
	    print "timestamp: $hashref->{'timestamp'} branchcode: $hashref->{'branchcode'} type: $type itemnumber: $hashref->{'itemnumber'} itype: $item->{'itype'} borrowernumber: $hashref->{'borrowernumber'}\n";
	}

    }
}
