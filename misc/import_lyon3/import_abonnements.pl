#!/usr/bin/perl

# Copyright 2009 BibLibre SARL
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

# Script to take some borrowers data in a known format and load it into Koha
#
# File format
#
# cardnumber,surname,firstname,title,othernames,initials,streetnumber,streettype,
# address line , address line 2, city, zipcode, email, phone, mobile, fax, work email, work phone,
# alternate streetnumber, alternate streettype, alternate address line 1, alternate city,
# alternate zipcode, alternate email, alternate phone, date of birth, branchcode,
# categorycode, enrollment date, expiry date, noaddress, lost, debarred, contact surname,
# contact firstname, contact title, borrower notes, contact relationship, ethnicity, ethnicity notes
# gender, username, opac note, contact note, password, sort one, sort two
#
# any fields except cardnumber can be blank but the number of fields must match
# dates should be in the format you have set up Koha to expect
# branchcode and categorycode need to be valid

use strict;
use warnings;

use C4::Auth;
use C4::Output;
use C4::Dates qw(format_date_in_iso format_date);
use C4::Context;
use C4::Charset;
use C4::Branch qw(GetBranchName);
use C4::Serials;
use C4::Biblio;
use C4::Search;
use IO::File;
use POSIX;
use Time::HiRes qw(clock) ;
use Text::Iconv;
use YAML;
use Text::CSV_XS;
use JSON::XS;
use Data::Dumper;

use Getopt::Long;
use utf8;
# Text::CSV::Unicode, even in binary mode, fails to parse lines with these diacriticals:
my $debug=$ENV{DEBUG};
# ė
# č

our ( $file_input,$file_output, 
$import_param_id, $operation, $encoding, 
$test, $update, $insert, $add, $limitimport, $limiterrors, 
$matchingpoint, $help, $verbose, $table, $map, $valuemap,$separator, $postprocess,$globalpreprocess,$preprocess,$valuemapfile,$delete);
GetOptions(
    'encoding|enc=s' => \$encoding,
    'output=s'    => \$file_output,
    'input|i=s'    => \$file_input,
    'map=s%'      => \$map,
    'separator|sep=s'      => \$separator,
    'valuemap=s@'      => \$valuemap,
    'valuemapfile=s'      => \$valuemapfile,
    'n=i'        => \$limitimport,
    'errorn=i'   => \$limiterrors,
    'delete|d'          => \$delete,
    'update|u'          => \$update,
    'insert|i'          => \$insert,
    'add|a'          => \$add,
    'test|t'          => \$test,
    'v'          => \$verbose,
    'help|h'     => \$help,
);

$| = 1;
# use encoding 'utf8';    # don't do this

if ($help) {
    print qq(
        Option :
    \t-delete             reset subscription tables
    \t-encoding latin1    defines encoding of the file if necessary
    \t-output   outputfilename      defines output
    \t-input    filename  defines the name of the file you want to import
    \t-paramid  number    defines the import parameters you want to use.
    \t-n        number    number of elements to import
    \t-errorn   number    number of errors before aborting
    \t-h|help             prints this help
    \n\n 
    );
    exit;
}

my (@feedback,$errors,@warnings);
$separator=$separator|| chr(0xfe);
# $test=($test&&!($add||$insert||$update))||1;
# $update=($add||$insert)||1;
my $valuesmapping;
#serial. Le séparateur * distingue les différents fascicules (du plus récent au plus ancien). Le séparateur // distingue 4 zones par fascicule : numéro, date de publication, date prévue ou d'arrivée, statut Koha. Pour les abonnements en cours le premier fascicule de la liste est le prochain attendu. Les différents formats de date de publication d'Advance ont été convertis au format date général de Koha. Les statuts distinguent les fascicules attendus, reçus, manquants etc. La zone LACUNES devient donc inutile.  Tables de conversion des statuts Advance aux statuts Koha  STATUT.KOHA : '1':'Expected':'2':'Arrived':'3':'Late':'4':'Missing':'5':'Claimed':'6':'Not available':'7':'Delete'  STATUT.ADVANCE : '1'='2':'RECU':'3'='5':'RECLAME': '4'='1':'ATTENDU':'11'='3':'EN ATTENTE': '7'='4':'MANQUANT':'15'='4':'EPUISE': '12'='7':'RETIRE':'16'='7':'DISPARU': '18'='4':'PAS PARU':'9'='2':'RELIE'   
#
my $insertserial=C4::Context->dbh->prepare(<<INSERTSERIAL);
INSERT INTO serial (biblionumber,subscriptionid,serialseq,publisheddate,planneddate,status) VALUES(?,?,?,?,?,?);
INSERTSERIAL
#my %status_advance_2_koha=(
#1=>2, # RECU
#3=>5, # RECLAME
#4=>1, # ATTENDU
#11=>3, # EN ATTENTE
#7=>4, # MANQUANT
#15=>4, # EPUISE
#12=>7, # RETIRE
#16=>7, # DISPARU
#18=>4, # PAS PARU
#9=>2 # RELIE'
#);
if ($delete){
   foreach my $table qw(subscription subscriptionhistory serial serialitems){
      C4::Context->dbh->do("TRUNCATE $table");
   }
}
if ($valuemap && !$valuemapfile){
    foreach (@$valuemap) {
        my ($cat,$valfrom,$valto)=split (/\s*,\s*/,$_);
        die "$valuemap is not a valid mapping" unless $valto;
        $valuesmapping->{$cat}->{$valfrom}=$valto;
    };
}
elsif ($valuemapfile){
    ($map,$valuesmapping)= YAML::LoadFile($valuemapfile) or die "unable to load $valuemapfile ";
    $debug && warn Data::Dumper::Dumper ($map),"\n";
    $debug && warn Data::Dumper::Dumper($valuesmapping),"\n";
}
# use Data::Dumper;
# warn Data::Dumper::Dumper(%valuesmapping);
my $table="subscription";
my $columnkeys = C4::Context->dbh->selectall_arrayref(qq/SHOW COLUMNS FROM $table/);

my @column_keys = @$columnkeys;
my $columnkeystpl = [ map { ($_ ne 'subscriptionid' ) ? () : key => $_ } @column_keys ]; # ref. to array of hashrefs.

#my $csv   = Text::CSV_XS->new({binary => 1,sep_char=>$separator});  # binary needed for non-ASCII Unicode
# push @feedback, {feedback=>1, name=>'backend', value=>$csv->backend, backend=>$csv->backend};
my $converter;

# The first 25 errors are enough.  Keeping track of 30,000+ would destroy performance.
$limiterrors = 25 unless ($limiterrors);


my @matchpoints;
$matchingpoint=$matchingpoint||"subscriptionid";

my $startdate=printtime();
my $clock0=clock();

if ( $file_input && length($file_input) > 0 ) {
    my $handle = IO::File->new( "$file_input", "r");
    unless ( defined $handle ) {
        $debug && warn " no file named :$file_input";
        exit 1;
    }
    my $imported    = 0;
    my $alreadyindb = 0;
    my $overwritten = 0;
    my $invalid     = 0;
    my $matchpoint_attr_type; 
    my $line = <$handle>;
	$line=~s/\r|\n//g;
    $debug && warn $line;
    my @csvcolumns=split /$separator/,$line;
    $debug && warn join " : ",@csvcolumns;
    my $checkuniquevalue="";
    foreach ( sort @csvcolumns ) {
        s/^\s+|\s+$//g;
        push @warnings, { 'key' => $_, 'line' => 0, "duplicate_field" => 1 } if ( $checkuniquevalue eq $_ );
        $checkuniquevalue = $_;
    }

    my $today_iso = C4::Dates->new()->output(C4::Context->preference('dateformat'));
    my @bad_dates;  # I've had a few.
    my $date_re = C4::Dates->new->regexp('syspref');
    my $iso_re = C4::Dates->new->regexp('iso');
    
 LINE: while ( defined( my $line= <$handle> ) ) {
        last if (defined($limitimport) && $. >$limitimport);
		$line=~s/\W$//g;
	my $fromdata;
	@$fromdata{@csvcolumns}=map{ tr#\xfd# #; C4::Charset::char_decode5426($_) }split /\xfe/,$line;
	
        my @missing_criticals;
        my @warningsline;
        ## Now we have initial data as a hash
        ## preprocess if there is one
        do $preprocess if ($preprocess);
        
        ## Convert data into utf8 if required
        if ($converter) {
            foreach my $key ( keys %$fromdata ) {
                my $tmp = $fromdata->{$key};
                $fromdata->{$key} = $converter->convert( $fromdata->{$key} );
                unless ( $tmp && $fromdata->{$key} ) {
                    push @warningsline, { 'key' => $key, "value" => $tmp, "encoding" =>1};
                }
            }
        }
        ## Now we have initial data as a hash well encoded
        ##Maps fromdata with Koha fields
        my $targetdata;
        @$targetdata{qw(manualhistory serialsadditems graceperiod intranetserial opacserialissue)}=qw(1 0 0 5 5);
        foreach my $key ( keys %$fromdata ) {
               my $transformedkey=$map->{$key} ||$key;
               my $value=$fromdata->{$key};
               $targetdata->{$transformedkey} = mapvalues( $valuesmapping, $transformedkey, $value); 
               $targetdata->{$transformedkey} = get_vendor($value) if ($transformedkey eq 'aqbooksellerid');
               if ($transformedkey eq 'biblionumber'){
                 $targetdata->{$transformedkey} = get_biblionumber($value);
		 		 if ( !$targetdata->{$transformedkey} or ref($targetdata->{$transformedkey}) eq "ARRAY"){
					warn "Biblionumber cannot be found for $value :".join(":", @{$targetdata->{$transformedkey}});
		 		 }
	    	   }

               push @warningsline, { 'key' => $key, "value" => $value, "mapping"=>1 } if ($verbose && ! $map->{$key});
               push @warningsline, { 'key' => $key, "value" => $value, "mappingvalue"=>1 } if ($verbose && ! defined($valuemap->{$transformedkey}->{$value}));
               push @warningsline, {'key' => $key, "value" => "", "undefined" => 1 } if ($verbose && (! defined($value) || $value eq "NULL"));
        }
	    $debug && warn Data::Dumper::Dumper($targetdata);
		my @received =split /\*/,$$targetdata{received};
		my @receivedissues=map {my $hash;@$hash{qw(serialseq publisheddate planneddate geac_status)}=split ('//',$_);$hash;}@received;
	    $debug && print map{my %hash=%$_;map{"$_:$hash{$_};"}keys %hash,"\n"}@receivedissues;
	# Popular spreadsheet applications make it difficult to force date outputs to be zero-padded, but we require it.
#        foreach (qw(startdate enddate histstartdate firstacquidate)) {
#            my $tempdate = $targetdata->{$_} or next;
#            $tempdate=~s#[^/]+/\s*##;
#            if ($tempdate =~ /$date_re/) {
#                $targetdata->{$_} = $tempdate;
#            } elsif ($tempdate =~ /$iso_re/) {
#                $targetdata->{$_} = format_date($tempdate);
#            } else {
#                $targetdata->{$_} = '';
#                push @missing_criticals, {key=>$_, value=>$tempdate,bad_date=>1};
#            }
#        }
	    $debug && warn Data::Dumper::Dumper($targetdata);
        my @missing_criticals;
       
        if (@missing_criticals) {
            foreach (@missing_criticals) {
                $_->{subscriptionid} = $targetdata->{subscriptionid} || 'UNDEF';
                $_->{biblionumber}   = $targetdata->{biblionumber} || 'UNDEF';
            }
            $invalid++;
            if ($limiterrors > $errors++){
            	push @feedback, {line=>$., lineraw=>output_information($targetdata),warningsline=>\@missing_criticals,"error"=>1};
            	last LINE;
            } 
            # The first 25 errors are enough.  Keeping track of 30,000+ would destroy performance.
            next LINE;
        }
        
        #Match
        
        my $subscriptionid;
        my $subscription;
        my %status;
        if ($subscriptionid) {
            # borrower exists
            if ($insert) {
                $alreadyindb++;
                %status=('indb' => "$subscriptionid", "rejected" => 1, "warning"=>1);
            }
            elsif($test){
                %status=( "test" => 1, "ok"=>1);
            }
            else {
              $targetdata->{ 'subscriptionid' } = $subscriptionid;
              for my $col ( keys %$subscription) {
  
                  # use values from extant patron unless our csv file includes this column or we provided a default.
                  # FIXME : You cannot update a field with a  perl-evaluated false value using the defaults.
                  unless ( exists( $targetdata->{$col} ) || $subscription->{$col} ) {
                      $targetdata->{$col} = $subscription->{$col} if ( $subscription->{$col} );
                  }
              }
              eval{ModSubscription( 0,@$targetdata{qw(   aqbooksellerid  cost
        aqbudgetid    biblionumber startdate       periodicity
        dow           numberlength weeklength      monthlength
        add1          every1       whenmorethan1   setto1
        lastvalue1    innerloop1   add2            every2
        whenmorethan2 setto2       lastvalue2      innerloop2
        add3          every3       whenmorethan3   setto3
        lastvalue3    innerloop3   numberingmethod status
        opacnote         letter       firstacquidate  irregularity
        numberpattern callnumber   hemisphere      manualhistory
        internalnotes serialsadditems intranetserial opacserialissue graceperiod location enddate subscriptionid)})};
              if ($@) {
                  $invalid++;
                  $errors++;
                  %status=( "update" => 1, "error"=>1);
              } else {
		ModSubscriptionHistory($subscriptionid,@$targetdata{qw(firstacquidate histenddate missing missing opacnote librariannote)});
                $overwritten++;
                %status=( "update" => 1, "ok"=>1);
              }
            }
        } else {

            # FIXME: fixup_cardnumber says to lock table, but the web interface doesn't so this doesn't either.
            # At least this is closer to AddMember than in subscriptions/subscriptionentry.pl
            if ($update) {
                %status=( "update_nodata" => 1, "warning"=>1);
            } 
            elsif($test){
                %status=( "test" => 1, "ok"=>1);
            }
            else {
              if (
                 $subscriptionid = NewSubscription( 0,@$targetdata{qw( branchcode  aqbooksellerid  cost
        aqbudgetid    biblionumber startdate       periodicity
        dow           numberlength weeklength      monthlength
        add1          every1       whenmorethan1   setto1
        lastvalue1    innerloop1   add2            every2
        whenmorethan2 setto2       lastvalue2      innerloop2
        add3          every3       whenmorethan3   setto3
        lastvalue3    innerloop3   numberingmethod status
        opacnote         letter       firstacquidate  irregularity
        numberpattern callnumber   hemisphere      manualhistory
        internalnotes serialsadditems intranetserial opacserialissue graceperiod location enddate)})
                 ) {
		
		 foreach my $hashissue (@receivedissues){
			#received status=2
			$insertserial->execute( 
									$$targetdata{biblionumber},
									$subscriptionid	,
									@$hashissue{qw(serialseq publisheddate planneddate)}
									,$$hashissue{'geac_status'}
#									,($status_advance_2_koha{$$hashissue{'geac_status'}}?
#										$status_advance_2_koha{$$hashissue{'geac_status'}}
#										:$$hashissue{'geac_status'})
									);
#			my $status="received" if ($status_advance_2_koha{$$hashissue{'geac_status'}}==2);
#		   $status="missing" if ($status_advance_2_koha{$$hashissue{'geac_status'}}==4);
			my $status="received" if ($$hashissue{'geac_status'}==2);
		   $status="missing" if ($$hashissue{'geac_status'}==4);
		   $$targetdata{$status."list"}.=$$hashissue{serialseq}.", " if ($status);
		}
		ModSubscriptionHistory($subscriptionid,@$targetdata{qw(firstacquidate histenddate receivedlist missinglist opacnote librariannote)});
#$histstartdate,$enddate,$recievedlist,$missinglist,$opacnote,$librariannote);
                  $imported++;
                  %status=( "insert" => 1, "ok"=>1);
              } else {
                  $invalid++;    # was just "$invalid", I assume incrementing was the point --atz
                  $errors++;
                  %status=( "insert" => 1, "error"=>1);
              }
            }
        }
        push @feedback, { "line" => $., 'lineraw' => output_information($targetdata), warningsline=>\@warningsline, %status };
    }
    my $clock1=clock();
    my $timespent=$clock1-$clock0;
    my $PARAMS={FEEDBACK=>\@feedback,
        "op".($insert?"insert":($update?"update":"add")) => 1,
        "op".($test?"testmode":"") => 1,
        'columns'=>join( $separator, map{"$_"} @csvcolumns ),
        'matchpoints'     => [map{{"value"=>$_} } @matchpoints], #formatting data as a ref to an array of hashrefs for TMPL_LOOPS
        'mappings'        => mapoutput($map),
        'mappingvalues'   => [map{ 
                                mapoutputkeys([$_,mapoutput($valuesmapping->{$_})],["field","values"])
                              } keys %$valuesmapping
                              ],
        'startdate'       => $startdate,
        'enddate'         => printtime(),
        'timespent'       => $timespent,
        'filename'        => $file_input,
        'created'         => $imported,
        'overwritten'     => $overwritten,
        'alreadyindb'     => $alreadyindb,
        'invalid'         => $invalid,
        'total'           => $imported + $alreadyindb + $invalid + $overwritten,
    };
    print Data::Dumper::Dumper($PARAMS);
}



sub mapvalues {
    my ( $valuemapping, $transformedkey, $value) = @_;
    if ( my $v = $valuemapping->{$transformedkey} ) { 
        my $rv;
        ref $v eq "HASH" and $rv = $v->{$value} and return $rv;
#         warn "no key in transformation for $value";
        # eventuellement
        return $value;
    } else {
#         warn "no transformation key for $value";
        return $value;
    }   
}

sub mapoutput {
    my ( $hash_ref) = @_;
    my @output=map{mapoutputkeys([ $_,$hash_ref->{$_}],["valuefrom","valueto"])} keys %$hash_ref;
    return \@output;
}
sub mapoutputkeys {
    my ( $arrayvalue_ref, $keyname_array_ref) = @_;
    my %hash;
    @hash{@$keyname_array_ref}=@$arrayvalue_ref[0..scalar(@$keyname_array_ref-1)];
    return \%hash;
}


sub output_information {
    my ($data) = @_;
    return encode_json($data);
}

sub printtime{
 return strftime("\"%a %b %e  %Y\";\"%Y-%m-%e\";\"%H:%M:%S\"", localtime);
}
sub get_vendor{
  my ($suppliercode)=@_;
  my $query=C4::Context->dbh->prepare(qq(SELECT id from aqbooksellers where name=?));
  $query->execute($suppliercode);
  if (my ($vendorid)=$query->fetchrow){
    return $vendorid;
  }
  return;
}
sub get_biblionumber{
  my ($information)=@_;
  my ( $error, $results, $total_hits ) = SimpleSearch( "ident=\"ADV$information\"", 0, 12, [qw'biblioserver'] );
  #my ( $error, $results, $total_hits ) = SimpleSearch( "sn,ltrn:$information", 0, 12, [qw'biblioserver'] );
   if (defined $error) {
           warn "error: ".$error;
           exit; 
   }
       my $hits = scalar @$results; my @results;
       if ($hits>1){
	       for my $i (0..$hits) {
		   my %resultsloop;
		   warn "$i : ",$results->[$i];
		   my $marcrecord = MARC::File::USMARC::decode($results->[$i]);
		   warn $marcrecord->as_formatted;
		   my $biblio = TransformMarcToKoha(C4::Context->dbh,$marcrecord,"");
		   #build the hash for the template.
		   %resultsloop=%$biblio;
                   $resultsloop{highlight}       = ($i % 2)?(1):(0);
		   push @results, \%resultsloop;
	       }
	  return @results;
       }
       elsif ($hits==0) {
	 warn "no biblionumber for $information";
       } 
       else {
           my %resultsloop;
           my $marcrecord = MARC::File::USMARC::decode($results->[0]);
           my $biblio = TransformMarcToKoha(C4::Context->dbh,$marcrecord,'');
           return $biblio->{'biblionumber'};
        }
       

}
