#!/usr/bin/perl
# script that rebuild thesaurus from biblio table.

# delete  FROM  `marc_subfield_table`  WHERE tag =  "606" AND subfieldcode = 9;
use strict;
#use warnings; FIXME - Bug 2505

# Koha modules used
use C4::Context;
use C4::Biblio;
use C4::AuthoritiesMarc;
use Time::HiRes qw(gettimeofday);

use Getopt::Long;
my ( $fields, $number,$language) = ('',0);
my ($version, $verbose, $test_parameter, $field,$delete,$subfields);
GetOptions(
    'h' => \$version,
    'd' => \$delete,
    't' => \$test_parameter,
    's:s' => \$fields,
    'v' => \$verbose,
	'l:s' => \$language,
);

if ($version or !$fields) {
	print <<EOF
Small script to recreate the LANG list in authorised values from existing langs in the catalogue.
This script is useful when you migrate your datas with bulkmarcimport.pl as it populates parameters tables that are not modified by bulkmarcimport.

parameters :
\th : this version/help screen
\ts : the field or field list where the lang codes are stored.
\td : delete every entry of LANG category before doing work.
\tl : the language of the language list (fr or en for instance)

The table is populated with iso codes and meaning (in french).
If the complete language name is unknown, the code is used instead and you will be warned by the script

SAMPLES :
 ./buildLANG -d -s "('101a','101b')"
EOF
;#/
exit;
}

my %codesiso;

%codesiso = (
	'eng' => 'english',
	'fre' => 'french'
	);

%codesiso = (
	'mis' => 'diverses',
	'und' => 'inconnue',
	'mul' => 'multilingue',
	'ger' => 'allemand',
	'eng' => 'anglais',
	'afr' => 'afrikaans',
	'akk' => 'akkadien',
	'amh' => 'amharique',
	'ang' => 'anglo-saxon (ca. 450-1100)',
	'arc' => 'aram�en',
	'ara' => 'arabe',
	'arm' => 'arm�nien',
	'baq' => 'basque',
	'ber' => 'berbere',
	'bre' => 'breton',
	'bul' => 'bulgare',
	'cat' => 'catalan',
	'chi' => 'chinois',
	'cop' => 'copte',
	'cro' => 'croate',
	'cze' => 'tch�que',
	'dan' => 'danois',
	'dum' => 'n�erlandais moyen (ca. 1050-1350)',
	'dut' => 'n�erlandais',
	'spa' => 'espagnol',
	'egy' => 'egyptien',
	'esp' => 'esp�ranto',
	'fin' => 'finnois',
	'fra' => 'fran�ais ancien',
	'fre' => 'fran�ais',
	'frm' => 'fran�ais moyen (ca. 1400-1600)',
	'fro' => 'fran�ais ancien (842-ca. 1400)',
	'gmh' => 'allemand, moyen haut (ca. 1050-1500)',
	'got' => 'gothique',
	'grc' => 'grec classique',
	'gre' => 'grec moderne',
	'heb' => 'h�breu',
	'hin' => 'hindi',
	'hun' => 'hongrois',
	'ind' => 'indon�sien',
	'ine' => 'indo-europ�ennes, autres',
	'ita' => 'italien',
	'jap' => 'japonais',
	'jpn' => 'japonais',
	'kor' => 'cor�en',
	'lan' => 'occitan (post 1500)',
	'lat' => 'latin',
	'map' => 'malayo-polyn�siennes, autres',
	'mla' => 'malgache',
	'nic' => 'nig�ro-congolaises, autres',
	'nor' => 'norv�gien',
	'per' => 'persan',
	'pro' => 'provencal ancien (jusqu\'� 1500)',
	'pol' => 'polonais',
	'por' => 'portugais',
	'rom' => 'tzigane',
	'rum' => 'roumain',
	'rus' => 'russe',
	'sam' => 'samaritain',
	'san' => 'sanskrit',
	'scr' => 'serbo-croate',
	'sem' => 's�mitique, autres langues',
	'ser' => 'serbe',
	'sla' => 'slave, autres langues',
	'slo' => 'slov�ne',
	'syr' => 'syriaque',
	'swe' => 'suedois',
	'tib' => 'tib�tain',
	'tur' => 'turc',
	'uga' => 'ougaritique',
	'ukr' => 'ukraine',
	'wel' => 'gallois',
	'yid' => 'yiddish',
	) if $language eq 'fr';

my $dbh = C4::Context->dbh;
if ($delete) {
	print "deleting lang list\n";
	$dbh->do("delete from authorised_values where category='LANG'");
}

if ($test_parameter) {
	print "TESTING MODE ONLY\n    DOING NOTHING\n===============\n";
}
my $starttime = gettimeofday;

my $sth = $dbh->prepare("SELECT DISTINCT subfieldvalue FROM marc_subfield_table WHERE tag + subfieldcode IN $fields order by subfieldvalue");

$sth->execute;
my $i=1;

print "=========================\n";
my $sth2 = $dbh->prepare("insert into authorised_values (category, authorised_value, lib) values (?,?,?)");
while (my ($langue) = $sth->fetchrow) {
	$sth2->execute('LANG',$langue,$langue?$codesiso{$langue}:$langue);
	print "lang : $langue is unknown is iso list\n" unless $codesiso{$langue};
}
print "=========================\n";
