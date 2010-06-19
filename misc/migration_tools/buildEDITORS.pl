#!/usr/bin/perl

use strict;
use warnings;

use MARC::Record;
use C4::Context;
use C4::Biblio;
use C4::AuthoritiesMarc;
use Time::HiRes qw(gettimeofday);
use Business::ISBN;
use Getopt::Long;
use YAML;

my ($version, $verbose, $test_parameter, $confirm,$delete);
GetOptions(
    'h' => \$version,
    'd' => \$delete,
    't' => \$test_parameter,
    'v' => \$verbose,
    'c' => \$confirm,
);

if ($version or !$confirm) {
    print <<EOF
small script to recreate a authority table into Koha.
This will parse all your biblios to recreate isbn / editor / collections for the unimarc_210c and unimarc_225a plugins.

Remember those plugins will work only if you have an EDITORS authority type, with
\t200a being the first 2 parts of an ISBN
\t200b being the editor name
\t200c (repeatable) being the series title

parameters :
\t-c : confirmation flag. the script will run only with this flag. Otherwise, it will just show this help screen.
\t-d : delete existing EDITORS before rebuilding them
\t-t : test parameters : run the script but don't create really the EDITORS
EOF
      ;    #'

    exit;
}

my $dbh = C4::Context->dbh;
if ($delete) {
    print "deleting EDITORS\n";
    my $del1 = $dbh->prepare("delete from auth_subfield_table where authid=?");
    my $del2 = $dbh->prepare("delete from auth_word where authid=?");
    my $sth  = $dbh->prepare("select authid from auth_header where authtypecode='EDITORS'");
    $sth->execute;
    while ( my ($authid) = $sth->fetchrow ) {
        $del1->execute($authid);
        $del2->execute($authid);
    }
    $dbh->do("delete from auth_header where authtypecode='EDITORS'");
}

if ($test_parameter) {
    print "TESTING MODE ONLY\n    DOING NOTHING\n===============\n";
}
$| = 1;    # flushes output
my $starttime = gettimeofday;
my $count = 0;
my $editor_from_isbn = {};
my $sth = $dbh->prepare("SELECT biblionumber FROM biblioitems WHERE isbn <> ''" );
$sth->execute;
while (my ($bibid) = $sth->fetchrow) {
    $count++;
    my $record = GetMarcBiblio($bibid);
    my $isbn = $record->field('010');
    next unless $isbn;
    $isbn = $isbn->subfield('a');
    next unless $isbn;
    $isbn = Business::ISBN->new($isbn);
    next unless $isbn; 
    my $isbn_prefix = $isbn->group_code . '-' . $isbn->publisher_code;
    next unless $isbn_prefix;

    print ".";
    my $timeneeded = gettimeofday - $starttime;
    print "$count in $timeneeded s\n" unless $count % 100;
    
    my $name = $record->field('210');
    next unless $name;
    $name = $name->subfield('c');
    next unless $name;
    
    my $collection = $record->field('225');
    next unless $collection;
    $collection = $collection->subfield('a');
    next unless $collection;
    
    my $editor = $editor_from_isbn->{ $isbn_prefix } ||
                 ( $editor_from_isbn->{ $isbn_prefix } = [ $name, {}, ] );
    $editor->[1]->{$collection}++;
}

foreach my $isbn_prefix ( sort keys %$editor_from_isbn ) {
    my $editor = $editor_from_isbn->{$isbn_prefix};
    my @sf = ();
    push @sf, 'a', $isbn_prefix, 'b', $editor->[0];
    foreach my $collection (sort keys %{ $editor->[1] } ) {
        push @sf, 'c', $collection;
    }
    my $authority = MARC::Record->new();
    $authority->append_fields( MARC::Field->new( 200, '', '', @sf ) );
    AddAuthority( $authority, 0, 'EDITORS' ) unless $test_parameter;
    print $authority->as_formatted(), "\n" if $verbose;
}

