package KohaTest::Search::MocksForSearch;

use Test::More;
use C4::Search;
use C4::Context;

our $root = C4::Context->config('intranetdir');

=head3 MockGetAuthority

    Mocks C4::AuthoritiesMarc::GetAuthority

    named parameters:
        authid: 3 autorities available:
        1: Author authority
        2: Subject authority
        3: Geographica subject authority

=cut
sub MockGetAuthority {
  my ($authid) = @_;
  if ($authid == 1) { &MockAuthority1Author;}
  elsif ($authid == 2) { &MockAuthority2Subject;}
  elsif ($authid == 3) { &MockAuthority3GeoSubject;}
}

=head3 MockAuthority*

   Return a record similar to an authority sample. These objects can be extended for the needs.

=cut
sub MockAuthority2Subject {
    my $record = MARC::Record->new;
    $record->add_fields('001', " ", " ", '2');
    $record->add_fields('250', " ", " ", a => "Papillon");
    $record->add_fields('450', " ", " ", a => "RejPapillon");
    $record->add_fields('750', " ", " ", a => "ParPapillon");
    return $record;
}

sub MockAuthority3GeoSubject {
    my $record = MARC::Record->new;
    $record->add_fields('001', " ", " ", '3');
    $record->add_fields('215', " ", " ", a => "Europe");
    $record->add_fields('415', " ", " ", a => "RejEurope");
    $record->add_fields('715', " ", " ", a => "ParEurope");
    return $record;
}

sub MockAuthority1Author {
    my $record = MARC::Record->new;
    $record->add_fields('001', " ", " ", '1');
    $record->add_fields('200', " ", " ", a => "Gary",
                                         b => "Romain");
    $record->add_fields('400', " ", " ", a => "Gaa",
                                         b => "Rom");
    $record->add_fields('700', " ", " ", a => "Ajar",
                                         b => "Emilie");
    return $record;
}

=head3 MockMapping*

    Returns each a mapping structure (a $mapping is related to an solr index and configured in ~/solr/indexes.pl

=cut
sub MockMappingAuthor {
  {
     200 => ['f','g'],
     225 => ['g'],
     '7..' => ['*']
  }
}

sub MockMappingSubject {
  {
    600 => ['*'],
    601 => ['*'],
    602 => ['*'],
    603 => ['*'],
    604 => ['*'],
    605 => ['*'],
    606 => ['*']
  }
}

sub MockMappingGeoSubject {
  {
    607 => ['*']
  }
}

=head3 MockBiblio*

   Return a record similar to a biblio sample. This object can be extended for the needs.

=cut
sub MockBiblio {
    my $record = MARC::Record->new;
    $record->add_fields('600', " ", " ", 9 => '2'); #linked to &MockAuthoritySubject
    $record->add_fields('607', " ", " ", 9 => '3'); #linked to &MockAuthorityGeoSubject
    $record->add_fields('700', " ", " ", 9 => '1'); #linked to "Romain Gary" &MockAuthorityAuthor
    return $record;
}

1;
