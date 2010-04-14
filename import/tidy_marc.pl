#!/usr/bin/perl

# Copyright Chris Cormack <chris@catalyst.net.nz>
# Script to dedup marc records and combine items using isbn or issn

# This script is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# This script is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this script; if not, write to the Free Software Foundation, Inc., 59 Temple Place,
# Suite 330, Boston, MA  02111-1307 USA
#   

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

