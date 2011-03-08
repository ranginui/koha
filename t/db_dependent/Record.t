#!/usr/bin/perl
#
# This Koha test module is a stub!  
# Add more tests here!!!

use strict;
use warnings;

use Test::More tests => 10;
use MARC::Record;

BEGIN {
        use_ok('C4::Record');
}

#my ($marc,$to_flavour,$from_flavour,$encoding) = @_;

my @marcarray=marc2marc;
is ($marcarray[0],"Feature not yet implemented\n","error works");

my $marc=new MARC::Record;
my $marcxml=marc2marcxml($marc);
my $testxml=qq(<?xml version="1.0" encoding="UTF-8"?>
<record
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd"
    xmlns="http://www.loc.gov/MARC21/slim">

  <leader>         a              </leader>
</record>
);
is ($marcxml, $testxml, "testing marc2xml");

my $rawmarc=$marc->as_usmarc;
$marcxml=marc2marcxml($rawmarc);
$testxml=qq(<?xml version="1.0" encoding="UTF-8"?>
<record
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd"
    xmlns="http://www.loc.gov/MARC21/slim">

  <leader>00026    a2200025   4500</leader>
</record>
);
is ($marcxml, $testxml, "testing marc2xml");

my $marcconvert=marcxml2marc($marcxml);
is ($marcconvert->as_xml,$marc->as_xml, "testing xml2marc");

my $marcdc=marc2dcxml($marc);
my $test2xml=qq(<?xml version="1.0" encoding="UTF-8"?>
<metadata
  xmlns="http://example.org/myapp/"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://example.org/myapp/ http://example.org/myapp/schema.xsd"
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  xmlns:dcterms="http://purl.org/dc/terms/">
</metadata>);

is ($marcdc, $test2xml, "testing marc2dcxml");

my $marcqualified=marc2dcxml($marc,1);
my $test3xml=qq(<?xml version="1.0" encoding="UTF-8"?>
<metadata
  xmlns="http://example.org/myapp/"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://example.org/myapp/ http://example.org/myapp/schema.xsd"
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  xmlns:dcterms="http://purl.org/dc/terms/">
</metadata>);

is ($marcqualified, $test3xml, "testing marcQualified");

my $mods=marc2modsxml($marc);
my $test4xml=qq(<?xml version="1.0" encoding="UTF-8"?>
<mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.loc.gov/mods/v3" version="3.1" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-1.xsd">
  <typeOfResource/>
  <originInfo>
    <issuance/>
  </originInfo>
  <recordInfo/>
</mods>
);

is ($mods, $test4xml, "testing marc2mosxml");

my $field = MARC::Field->new('245','','','a' => "Harry potter");
$marc->append_fields($field);

#my $endnote=marc2endnote($marc->as_usmarc);
#print $endnote;

my $bibtex=marc2bibtex($marc);
my $test5xml=qq(\@book{,
	title = "Harry potter"
}
);

is ($bibtex, $test5xml, "testing bibtex");

my @entity=C4::Record::_entity_encode("Björn");
is ($entity[0], "Bj&#xC3;&#xB6;rn", "Html umlauts");








