#!/use/bin/perl

#script to administer Authorities without biblio
#written 20/04/2006 by laurenthdl@alinto.com
# This software is placed under the gnu General Public License, v2 (http://www.gnu.org/licenses/gpl.html)


# Copyright 2000-2002 Katipo Communications
#
# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# Koha is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# Koha; if not, write to the Free Software Foundation, Inc., 59 Temple Place,
# Suite 330, Boston, MA  02111-1307 USA
use strict;

use C4::Context;
use C4::AuthoritiesMarc;
use Getopt::Long;
use warnings;

my ($test,@authtypes);
GetOptions(
	    'aut|authtypecode:s'    => \@authtypes,
	    't'    => \$test,
	  );
						    
my $dbh=C4::Context->dbh;
#take an auth type as parameter
#take an Operation type as parameter
#take a threshold type as parameter
@authtypes||=qw(NC);
my $thresholdmin=0;
my $thresholdmax=0;
my @results;
my $rqselect = $dbh->prepare(qq{SELECT * from auth_header where authtypecode IN (}
                                .join(",",map{$dbh->quote($_)}@authtypes.")");
$rqselect->execute;
while (my $data=$rqselect->fetchrow_hashref){
	my $used =CountUsage($data->{'authid'});
	if ($used>=$thresholdmin and $used<=$thresholdmax){
		push @results,{'authid'=>$data->{'authid'}};
	}
}
my $count=@results;
my $countdeleted=0;
foreach my $auth (@results){
	if ($test){
		print STDOUT $auth->{'authid'}."\n";
	}
	else{
		$countdeleted++ if (DelAuthority($auth->{'authid'}));
	}
}
print STDOUT "\n";
warn "$count authorities answering your criteria, $countdeleted authorities deleted.\n";
