#! /usr/bin/perl
use Regexp::Grammars::Z3950::RPN;
use Modern::Perl;
use YAML;
use Test::More;

# /!\ /!\ /!\ /!\ /!\ /!\ /!\
# You must execute 02-pre-client.t before and 02-post-client.t when you have finished
# /!\ /!\ /!\ /!\ /!\ /!\ /!\


# Test connection to a z3950 server (localhost:9999)
my $host = 'localhost';
my $port = 9999;

my $tests;
plan tests => $tests;

# Use
BEGIN { $tests += 3 }
use_ok('Regexp::Grammars::Z3950::RPN');
use_ok('Net::Z3950::ZOOM');
use_ok('KohaTest::Search::SolrSearch');

# Connection
BEGIN { $tests += 1 }
my $conn = new ZOOM::Connection($host, $port);
my ($errcode, $errmsg, $addinfo) = $conn->error_x();
is( $errcode, 0, $errmsg);

# Set option
BEGIN { $tests += 2 } # TODO
$conn->option(databaseName => "biblio");
is ($conn->option("databaseName"), "biblio", "set option databaseName=biblio");
$conn->option(preferredRecordSyntax => "usmarc");
is ($conn->option("preferredRecordSyntax"), "usmarc", "set option preferredRecordSyntax=usmarc");

# Search
BEGIN { $tests += 5 }
#my $rs = $conn->search_pqf('@attr 1=1016 ""'); # TODO when grammar match ""
my $rs = $conn->search_pqf('@attr 1=1016 "a"');
is( $rs->size(), 74, "Calcul total hits for biblio" );

$rs = $conn->search_pqf('@attr 1=4 "Anioutka"');
is( $rs->size(), 1, "Calcul hits for title='Anioutka'" );
is( $rs->record(0)->render(), '00793nam0a2200265   4500
010    $a 2226070087 $b br. $d 98 F
035    $a AG-0174-00000160
090    $a 34
091    $a 2
099    $t LIV $c 31/08/2010 $d 31/08/2010
100    $a 19940830d1994    m  y0frey50      ba
200 1  $a Anioutka $e roman $f Roger Bichelberger
700  1 $9 55 $a Bichelberger $b Roger
801  3 $a FR $b BN $c 19991111 $g AFNOR
101 0  $a fre
210    $a Paris $c Albin Michel $d 1994 $e 53-Mayenne $g Impr. Floch
215    $a 228 p. $d 23 cm
676    $9 2 $a R
675    $a 823 $v Ed. 1967
300    $a Bibliogr., 1 p.
801    $b Médiathèque Madame de Sévigné
990    $a LIV $A Livres
995    $f 5360010008 $s Achat $t XROM $m 2010-08-31 $j 0 $9 34 $c VITRE $2 0 $k R-BIC $o 0 $e MAGADU $i 98.00 $r IMP $b VITRE
001 34
999    $9 339835 $a 339834

', "usmarc for title='Anioutka'");

$conn->option(preferredRecordSyntax => "xml");
is ($conn->option("preferredRecordSyntax"), "xml", "set option preferredRecordSyntax=xml");

is( $rs->record(0)->render(), '<?xml version="1.0" encoding="UTF-8"?>
<record
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd"
    xmlns="http://www.loc.gov/MARC21/slim">

  <leader>00793nam0a2200265   4500</leader>
  <datafield tag="010" ind1=" " ind2=" ">
    <subfield code="a">2226070087</subfield>
    <subfield code="b">br.</subfield>
    <subfield code="d">98 F</subfield>
  </datafield>
  <datafield tag="035" ind1=" " ind2=" ">
    <subfield code="a">AG-0174-00000160</subfield>
  </datafield>
  <datafield tag="090" ind1=" " ind2=" ">
    <subfield code="a">34</subfield>
  </datafield>
  <datafield tag="091" ind1=" " ind2=" ">
    <subfield code="a">2</subfield>
  </datafield>
  <datafield tag="099" ind1=" " ind2=" ">
    <subfield code="t">LIV</subfield>
    <subfield code="c">31/08/2010</subfield>
    <subfield code="d">31/08/2010</subfield>
  </datafield>
  <datafield tag="100" ind1=" " ind2=" ">
    <subfield code="a">19940830d1994    m  y0frey50      ba</subfield>
  </datafield>
  <datafield tag="200" ind1="1" ind2=" ">
    <subfield code="a">Anioutka</subfield>
    <subfield code="e">roman</subfield>
    <subfield code="f">Roger Bichelberger</subfield>
  </datafield>
  <datafield tag="700" ind1=" " ind2="1">
    <subfield code="9">55</subfield>
    <subfield code="a">Bichelberger</subfield>
    <subfield code="b">Roger</subfield>
  </datafield>
  <datafield tag="801" ind1=" " ind2="3">
    <subfield code="a">FR</subfield>
    <subfield code="b">BN</subfield>
    <subfield code="c">19991111</subfield>
    <subfield code="g">AFNOR</subfield>
  </datafield>
  <datafield tag="101" ind1="0" ind2=" ">
    <subfield code="a">fre</subfield>
  </datafield>
  <datafield tag="210" ind1=" " ind2=" ">
    <subfield code="a">Paris</subfield>
    <subfield code="c">Albin Michel</subfield>
    <subfield code="d">1994</subfield>
    <subfield code="e">53-Mayenne</subfield>
    <subfield code="g">Impr. Floch</subfield>
  </datafield>
  <datafield tag="215" ind1=" " ind2=" ">
    <subfield code="a">228 p.</subfield>
    <subfield code="d">23 cm</subfield>
  </datafield>
  <datafield tag="676" ind1=" " ind2=" ">
    <subfield code="9">2</subfield>
    <subfield code="a">R</subfield>
  </datafield>
  <datafield tag="675" ind1=" " ind2=" ">
    <subfield code="a">823</subfield>
    <subfield code="v">Ed. 1967</subfield>
  </datafield>
  <datafield tag="300" ind1=" " ind2=" ">
    <subfield code="a">Bibliogr., 1 p.</subfield>
  </datafield>
  <datafield tag="801" ind1=" " ind2=" ">
    <subfield code="b">Médiathèque Madame de Sévigné</subfield>
  </datafield>
  <datafield tag="990" ind1=" " ind2=" ">
    <subfield code="a">LIV</subfield>
    <subfield code="A">Livres</subfield>
  </datafield>
  <datafield tag="995" ind1=" " ind2=" ">
    <subfield code="f">5360010008</subfield>
    <subfield code="s">Achat</subfield>
    <subfield code="t">XROM</subfield>
    <subfield code="m">2010-08-31</subfield>
    <subfield code="j">0</subfield>
    <subfield code="9">34</subfield>
    <subfield code="c">VITRE</subfield>
    <subfield code="2">0</subfield>
    <subfield code="k">R-BIC</subfield>
    <subfield code="o">0</subfield>
    <subfield code="e">MAGADU</subfield>
    <subfield code="i">98.00</subfield>
    <subfield code="r">IMP</subfield>
    <subfield code="b">VITRE</subfield>
  </datafield>
  <controlfield tag="001">34</controlfield>
  <datafield tag="999" ind1=" " ind2=" ">
    <subfield code="9">339835</subfield>
    <subfield code="a">339834</subfield>
  </datafield>
</record>
', "xml for title='Anioutka'");

# authority
BEGIN { $tests += 2 }
$conn->option(databaseName => "authority");
is ($conn->option("databaseName"), "authority", "set option databaseName=authority");
$rs = $conn->search_pqf('@attr 1=1016 "a"');
is( $rs->size(), 0, "Calcul total hits for authority" );

