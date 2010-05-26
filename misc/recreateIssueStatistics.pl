#!/usr/bin/perl
# Re-create statistics from issues and old_issues tables

use strict;
use warnings;
use C4::Context;
use C4::Items;
use Data::Dumper;

my $dbh = C4::Context->dbh;

# Issues and renewals can be found in both issues and old_issues tables
foreach my $table ('issues', 'old_issues') {                                                                                                                                                                        
    # Getting issues
    print "looking for missing issues from $table\n";
    my $query = "SELECT borrowernumber, branchcode, itemnumber, issuedate, renewals, lastreneweddate from $table where itemnumber is not null";
    my $sth = $dbh->prepare($query);
    $sth->execute;
    # Looking for missing issues
    while (my $hashref = $sth->fetchrow_hashref) {
	my $ctnquery = "SELECT count(*) as cnt FROM statistics WHERE borrowernumber = ? AND itemnumber = ? AND DATE(datetime) = ? AND type = 'issue'";
	my $substh = $dbh->prepare($ctnquery);
	$substh->execute($hashref->{'borrowernumber'}, $hashref->{'itemnumber'}, $hashref->{'issuedate'});
	my $count = $substh->fetchrow_hashref->{'cnt'};
	if ($count == 0) {
	    # Inserting missing issue
		my $insert = "INSERT INTO statistics (datetime, branch, value, type, other, itemnumber, itemtype, borrowernumber) 
				     VALUES(?, ?, ?, ?, ?, ?, ?, ?)";
		$substh = $dbh->prepare($insert); 
		my $item = GetItem($hashref->{'itemnumber'});

		$substh->execute(
		    $hashref->{'issuedate'},
		    $hashref->{'branchcode'},
		    0,
		    'issue',
		    '',
		    $hashref->{'itemnumber'},
		    $item->{'itype'},
		    $hashref->{'borrowernumber'}
		);
		print "date: $hashref->{'issuedate'} branchcode: $hashref->{'branchcode'} type: issue itemnumber: $hashref->{'itemnumber'} itype: $item->{'itype'} borrowernumber: $hashref->{'borrowernumber'}\n";
	    }

	    # Looking for missing renewals
	    if ($hashref->{'renewals'} && $hashref->{'renewals'} > 0 ) {
		# This is the not-so accurate part :
		# We assume that there are missing renewals, based on the last renewal date
		# Maybe should this be deactivated by default ?
		my $ctnquery = "SELECT count(*) as cnt FROM statistics WHERE borrowernumber = ? AND itemnumber = ? AND DATE(datetime) = ? AND type = 'renew'";
		my $substh = $dbh->prepare($ctnquery);
		$substh->execute($hashref->{'borrowernumber'}, $hashref->{'itemnumber'}, $hashref->{'lastreneweddate'});

		my $missingrenewalscount = $hashref->{'renewals'} - $substh->fetchrow_hashref->{'cnt'};
		print "We assume $missingrenewalscount renewals are missing. Creating them\n" if ($missingrenewalscount > 0);
		for (my $i = 0; $i < $missingrenewalscount; $i++) {

		    # Inserting missing renewals
		    my $insert = "INSERT INTO statistics (datetime, branch, value, type, other, itemnumber, itemtype, borrowernumber) 
				     VALUES(?, ?, ?, ?, ?, ?, ?, ?)";
		    $substh = $dbh->prepare($insert); 
		    my $item = GetItem($hashref->{'itemnumber'});

		    $substh->execute(
			$hashref->{'lastreneweddate'},
			$hashref->{'branchcode'},
			0,
			'renew',
			'',
			$hashref->{'itemnumber'},
			$item->{'itype'},
			$hashref->{'borrowernumber'}
			);
		    print "date: $hashref->{'lastreneweddate'} branchcode: $hashref->{'branchcode'} type: renew itemnumber: $hashref->{'itemnumber'} itype: $item->{'itype'} borrowernumber: $hashref->{'borrowernumber'}\n";

		}

	    }
    }
}

# Getting returns
print "looking for missing returns from old_issues\n";
my $query = "SELECT * from old_issues where itemnumber is not null";
my $sth = $dbh->prepare($query);
$sth->execute;
# Looking for missing returns
while (my $hashref = $sth->fetchrow_hashref) {
    my $ctnquery = "SELECT count(*) as cnt FROM statistics WHERE borrowernumber = ? AND itemnumber = ? AND DATE(datetime) = ? AND type = 'return'";
    my $substh = $dbh->prepare($ctnquery);
    $substh->execute($hashref->{'borrowernumber'}, $hashref->{'itemnumber'}, $hashref->{'returndate'});
    my $count = $substh->fetchrow_hashref->{'cnt'};
    if ($count == 0) {
	# Inserting missing issue
	    my $insert = "INSERT INTO statistics (datetime, branch, value, type, other, itemnumber, itemtype, borrowernumber) 
				 VALUES(?, ?, ?, ?, ?, ?, ?, ?)";
	    $substh = $dbh->prepare($insert); 
	    my $item = GetItem($hashref->{'itemnumber'});

	    $substh->execute(
		$hashref->{'returndate'},
		$hashref->{'branchcode'},
		0,
		'return',
		'',
		$hashref->{'itemnumber'},
		$item->{'itype'},
		$hashref->{'borrowernumber'}
	    );
	    print "date: $hashref->{'returndate'} branchcode: $hashref->{'branchcode'} type: return itemnumber: $hashref->{'itemnumber'} itype: $item->{'itype'} borrowernumber: $hashref->{'borrowernumber'}\n";
	}

}


