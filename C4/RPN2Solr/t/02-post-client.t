#! /usr/bin/perl
use Modern::Perl;
use C4::ImportBatch;

# Execute me when you want to delete data (in biblio + biblioitems) inserted by 02-pre-client.t

my $batch_number = $ARGV[0];

die ("Usage : perl 02-post-client.t BATCH_NUMBER\n") if not $batch_number;

C4::ImportBatch::BatchRevertBibRecords($batch_number);

my $dbh = C4::Context->dbh;
my $sth = $dbh->prepare("DELETE FROM import_batches WHERE import_batch_id=$batch_number");
$sth->execute;
