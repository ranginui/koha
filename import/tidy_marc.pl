#!/usr/bin/perl

use MARC::File::USMARC;
use MARC::File::XML;
use MARC::Record;
use MARC::Batch;
use MARC::Charset;
use strict;

binmode( STDOUT, ":utf8" );
my $input_marc_file = ('./opusrecord.dat');
my $fh              = IO::File->new($input_marc_file);

my $batch = MARC::Batch->new( 'USMARC', $fh );
$batch->warnings_off();
$batch->strict_off();
open( MARCOUT, '> /tmp/record.dat' ) or die "\nFail- open marcoutput: $!";

my $oldrecord;
my $oldtitle;
my $oldisbn;
my $oldissn;

RECORD: while () {
    my $record;
    eval { $record = $batch->next() };
    if ($@) {
        print "Bad MARC record: skipped\n";
        next RECORD;
    }
    last unless ($record);
#    if ( !$oldrecord ) {
#        $oldrecord = $record;
#    }

    my $title;
    my $isbn;
    my $issn;

    if ($record) {
        my $f245 = $record->field('245');
        if ($f245) {
            $title = $f245->subfield('a');
        }
        my $f020 = $record->field('020');
        if ($f020) {
            $isbn = $f020->subfield('a');
        }
        my $f022 = $record->field('022');
        if ($f022) {
            $issn = $f022->subfield('a');
        }
        if ( $oldtitle eq $title && $oldisbn eq $isbn && $oldissn eq $issn ) {
             print "Matching $oldtitle $title \n";
             my $f952 = $record->field('952');
             if ($f952){
               print "appending fields \n";
               $oldrecord->append_fields($f952) if $oldrecord;
             }
        }
        else {
            print MARCOUT $oldrecord->as_usmarc() if $oldrecord;
            $oldrecord = $record;
            $oldtitle='';
            $oldisbn='';
            $oldissn='';
            my $f245 = $record->field('245');
            if ($f245) {
                $oldtitle = $f245->subfield('a');
            }
            my $f020 = $record->field('020');
            if ($f020) {
                $oldisbn = $f020->subfield('a');
            }
            my $f022 = $record->field('022');
            if ($f022) {
                $oldissn = $f022->subfield('a');
            }
        }
    }
    

}

