#!/usr/bin/perl -w

# script to tidy up branches

use strict;

use C4::Context;
use C4::Items;
use C4::Circulation;
use C4::Members;
my $dbh = C4::Context->dbh();

my $sql = "SELECT biblionumber,itemnumber,holdingbranch,homebranch FROM items order by itemnumber";
my $sth = $dbh->prepare($sql);
$sth->execute();

my $borrower1 = GetMemberDetails( undef, 'H00000248' );
my $borrower2 = GetMemberDetails( undef, 'H00000022' );
my $borrower3 = GetMemberDetails( undef, 'H00042816' );
my $borrower4 = GetMemberDetails( undef, 'H00000066' );

while ( my $data = $sth->fetchrow_hashref() ) {
#    Issue items
#    FM issue to H00000248 3 months
    # H issue to H00000022 5 years
    # M issue to H00042816 3 months
    # P issue to H00000066 3 months
    warn "$data->{'itemnumber'}\t holding branch is $data->{'holdingbranch'}\t home branch is $data->{'homebranch'}\n";
    if ($data->{'holdingbranch'} eq 'C'){
	ModItem({ 'holdingbranch' => 'L' }, $data->{biblionumber}, $data->{itemnumber});	
    }
    if ($data->{'holdingbranch'} eq 'FM'){
	AddIssue($borrower1,$data->{barcode},'2010-07-26');
	ModItem({ 'holdingbranch' => 'F' }, $data->{biblionumber}, $data->{itemnumber});	
    }
    if ($data->{'holdingbranch'} eq 'FP'){
	ModItem({ 'holdingbranch' => 'F' }, $data->{biblionumber}, $data->{itemnumber});	
    }
    if ($data->{'holdingbranch'} eq 'FS'){
	ModItem({ 'holdingbranch' => 'F' }, $data->{biblionumber}, $data->{itemnumber});	
    }
    if ($data->{'holdingbranch'} eq 'H'){
	AddIssue($borrower2,$data->{barcode},'2014-07-26');
	ModItem({ 'holdingbranch' => 'L' }, $data->{biblionumber}, $data->{itemnumber});	
    }
    if ($data->{'holdingbranch'} eq 'LP'){
	ModItem({ 'holdingbranch' => 'L' }, $data->{biblionumber}, $data->{itemnumber});	
    }
    if ($data->{'holdingbranch'} eq 'M'){
	AddIssue($borrower3,$data->{barcode},'2010-07-26');
	ModItem({ 'holdingbranch' => 'F' }, $data->{biblionumber}, $data->{itemnumber});	
    }
    if ($data->{'holdingbranch'} eq 'P'){
	AddIssue($borrower4,$data->{barcode},'2010-07-26');
	ModItem({ 'holdingbranch' => 'L' }, $data->{biblionumber}, $data->{itemnumber});	
    }
    if ($data->{'holdingbranch'} eq 'SP'){
	ModItem({ 'holdingbranch' => 'S' }, $data->{biblionumber}, $data->{itemnumber});	
    }
    if ($data->{'homebranch'} eq 'C'){
	ModItem({ 'homebranch' => 'L' }, $data->{biblionumber}, $data->{itemnumber});	
    }
    if ($data->{'homebranch'} eq 'FP'){
	ModItem({ 'homebranch' => 'F' }, $data->{biblionumber}, $data->{itemnumber});	
    }    
    if ($data->{'homebranch'} eq 'LP'){
	ModItem({ 'homebranch' => 'L' }, $data->{biblionumber}, $data->{itemnumber});	
    }    
    if ($data->{'homebranch'} eq 'SP'){
	ModItem({ 'homebranch' => 'S' }, $data->{biblionumber}, $data->{itemnumber});	
    }
    if ($data->{'homebranch'} eq 'P'){
	ModItem({ 'homebranch' => 'L' }, $data->{biblionumber}, $data->{itemnumber});	
    }    
    if ($data->{'homebranch'} eq 'H'){
	ModItem({ 'homebranch' => 'L' }, $data->{biblionumber}, $data->{itemnumber});	
    }    
    if ($data->{'homebranch'} eq 'FS'){
	ModItem({ 'homebranch' => 'L' }, $data->{biblionumber}, $data->{itemnumber});	
    }    
}
