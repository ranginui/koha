package C4::Search::Engine::Solr;

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

use utf8;
use Modern::Perl;

use C4::AuthoritiesMarc;
use C4::Context;
use C4::Biblio;
use C4::Branch;
use C4::Koha;
use C4::AuthoritiesMarc;
use Data::SearchEngine::Solr;
use Data::SearchEngine::Query;
use Data::SearchEngine::Item;
use Data::SearchEngine::Solr::Results;
use Time::Progress;
use Moose;

extends 'Data::SearchEngine::Solr';

=head1 NAME

C4::Search::Engine::Solr - Solr functions

=head1 DESCRIPTION

Contains SimpleSearch and IndexRecord for Solr search engine.

=head1 FUNCTIONS

=cut


sub GetSolrConnection {
    C4::Search::Engine::Solr->new(
        url     => C4::Context->preference("SolrAPI"),
        options => { autocommit => 1 }
    );
}

sub GetRessourceTypes {
    my $dbh = C4::Context->dbh;
    my $sth = $dbh->prepare("SELECT DISTINCT(ressource_type) FROM indexes ORDER BY ressource_type");
    $sth->execute();
    return $sth->fetchall_arrayref({});
}

sub GetIndexes {
    my $dbh = C4::Context->dbh;
    my $sth = $dbh->prepare("SELECT * FROM indexes WHERE ressource_type = ? ORDER BY id");
    $sth->execute(shift);
    return $sth->fetchall_arrayref({});
}

sub GetSortableIndexes {
    my $dbh = C4::Context->dbh;
    my $sth = $dbh->prepare("SELECT * FROM indexes WHERE sortable = 1 AND ressource_type = ? ORDER BY code");
    $sth->execute(shift);
    return $sth->fetchall_arrayref({});
}

sub GetFacetedIndexes {
    my $dbh = C4::Context->dbh;
    my $sth = $dbh->prepare("SELECT `type`, `code` FROM indexes WHERE faceted = 1 AND ressource_type = ? ORDER BY code");
    $sth->execute(shift);

    my @indexes;

    while ( my $row = $sth->fetchrow_hashref() ) {
        # Facets must be in str field (created by indexrecord)
        push @indexes, 'str_'.$row->{code};
    }

    return \@indexes;
}

sub SetIndexes {
    my ($ressource_type, $indexes) = @_;
    my $dbh = C4::Context->dbh;
    my $sth = $dbh->prepare("DELETE FROM indexes WHERE ressource_type = ?");
    $sth->execute($ressource_type);

    my $query  = "INSERT INTO indexes (`code`,`label`,`type`,`faceted`,`ressource_type`,`mandatory`,`sortable`,`plugin`, `rpn_index`, `ccl_index_name`) VALUES (?,?,?,?,?,?,?,?,?,?)";
    my $sth2 = $dbh->prepare($query);
    for ( @$indexes ) {
        $sth2->execute(
	    $_->{'code'},
	    $_->{'label'},
	    $_->{'type'},
	    $_->{'faceted'},
	    $ressource_type,
	    $_->{'mandatory'},
	    $_->{'sortable'},
	    $_->{'plugin'},
        $_->{'rpn_index'},
        $_->{'ccl_index_name'}
	);
    }
}

sub SetMappings {
    my ($ressource_type, $indexes) = @_;
    my $dbh = C4::Context->dbh;
    my $sth = $dbh->prepare("DELETE FROM indexmappings WHERE ressource_type = ?");
    $sth->execute($ressource_type);
    my $query  = "INSERT INTO indexmappings (`field`,`subfield`,`index`,`ressource_type`) VALUES ";
    my $i = 0;
    for ( @$indexes ) {
        $i++;
        $query .= "('".$_->{'field'}."','".$_->{'subfield'}."','".$_->{'index'}."','".$ressource_type."')";
        $query .= "," unless $i eq scalar(@$indexes);
    }
    my $sth2 = $dbh->prepare($query);
    $sth2->execute();
}

sub GetMappings {
    my $dbh = C4::Context->dbh;
    my $sth = $dbh->prepare("SELECT * FROM indexmappings WHERE ressource_type = ? ORDER BY field, subfield");
    $sth->execute(shift);
    return $sth->fetchall_arrayref({});
}

sub GetIndexLabelFromCode {
    my $dbh = C4::Context->dbh;
    my $sth = $dbh->prepare("SELECT label FROM indexes WHERE code = ?");
    $sth->execute(shift);
    my $result = $sth->fetchrow_hashref;
    return $result->{'label'};
}

sub GetSubfieldsForIndex {
    my $index = shift;
    my $dbh = C4::Context->dbh;
    my $query = "SELECT field, subfield FROM indexmappings WHERE `index` = ?";
    $query .= " ORDER BY field, subfield";
    my $sth = $dbh->prepare($query);
    $sth->execute($index);
    my $arrayref = $sth->fetchall_arrayref({});

    my $subfields;
    for ( @$arrayref ) {
        push @{ $subfields->{ $_->{'field'} } }, $_->{'subfield'};
    }
    return $subfields;
}

sub LoadSearchPlugin {
    my $plugin = shift;
    if ( grep( /^$plugin$/, GetSearchPlugins()) ) {
        eval "require $plugin";

        return do {
            no strict 'refs';
            my $symbol = $plugin. "::ComputeValue";
            \&{"$symbol"};
        };
    }
}

sub GetSearchPlugins {
   use Module::List;
   my $plugins = Module::List::list_modules( "C4::Search::Plugins::", { list_modules => 1 } );
   return keys %$plugins;
}

sub FillSubfieldWithAuthorisedValues {
    my ( $frameworkcode, $fieldcode, $subfieldcode, $value ) = @_;

    my $structure = C4::MarcFramework::GetSubfieldStructure( $fieldcode, $subfieldcode, $frameworkcode );

    given ( $structure->{'authorised_value'} ) {
        when( 'branches' ) {
            return GetBranchName( $value );
        }
        when( 'itemtypes' ) {
            my $itemtype = getitemtypeinfo( $value );
            return $itemtype->{'description'};
        }
        when( '' ) { return $value; }
        default {
            my $tmp = GetAuthorisedValueLib( $structure->{'authorised_value'}, $value );
            return $tmp if $tmp;
        }
    }
    return $value;
}

=head2 SimpleSearch


=cut

sub SimpleSearch {
    my ( $q, $filters, $page, $max_results, $sort) = @_;

    $q           ||= '*:*';
    $filters     ||= {};
    $page        ||= 1;
    $max_results ||= 999999999;
    $sort        ||= 'score desc';

    $sort = "srt_$sort" if $sort =~ /^(str|txt|int|date|ste)_/;

    my $sc = GetSolrConnection;

    $sc->options->{'facet'}          = 'true';
    $sc->options->{'facet.mincount'} = 1;
    $sc->options->{'facet.limit'}    = 10;
    $sc->options->{'facet.field'}    = GetFacetedIndexes($filters->{recordtype});
    $sc->options->{'sort'}           = $sort;

    $sc->options->{'fq'} = [ 
        map { 
            utf8::decode($filters->{$_});
            "$_:".$filters->{$_}
        } keys %$filters 
    ];

    utf8::decode($q);
    my $sq = Data::SearchEngine::Query->new(
        page  => $page,
        count => $max_results,
        query => $q,
    );

    my $result = eval { $sc->search( $sq ) };
    warn $@ if $@;

    return $result if (ref($result) eq "Data::SearchEngine::Solr::Results");
}


sub IndexRecord {
    my $recordtype = shift;
    my $recordids  = shift;
    my $debug = C4::Context->preference("DebugLevel");

    my $indexes = GetIndexes( $recordtype );
    my $sc      = GetSolrConnection;

    my @recordpush;
    my $g;
    for my $id ( @$recordids ) {
        
        my $record;
        my $frameworkcode;
        my $recordid = "${recordtype}_$id";

        if ( $recordtype eq "authority" ) {
            $record = GetAuthority( $id );
        } elsif ( $recordtype eq "biblio" ) {
            $record = GetMarcBiblio( $id );
            $frameworkcode = GetFrameworkCode( $id );
        }

        next unless ( $record );

        my $solrrecord = Data::SearchEngine::Item->new(
            'id'    => $recordid,
            'score' => 1,
        );

        $solrrecord->set_value( 'recordtype', $recordtype );
        $solrrecord->set_value( 'recordid'  , $id );
        warn $id;

        for my $index ( @$indexes ) {

            my @values;
            my $mapping = GetSubfieldsForIndex( $index->{'code'} );

            if ( $index->{'plugin'} ) {
                my $plugin = $index->{'plugin'};
                $plugin = LoadSearchPlugin( $plugin ) if $plugin;
                @values = &$plugin( $record );
            } else {
                for my $tag ( sort keys %$mapping ) {
                    for my $field ( $record->field( $tag ) ) {
                        if ( $field->is_control_field ) {
                            push @values, $field->data;
                        } else {

                            for my $code ( @{ $mapping->{$tag} } ) {

                                my @sfvals = $code eq '*'
                                           ? map { $_->[1] } $field->subfields
                                           : map { $_      } $field->subfield( $code );

                                for ( @sfvals ) {
                                    $_ = NormalizeDate( $_ ) if $index->{'type'} eq 'date';
                                    $_ = FillSubfieldWithAuthorisedValues( $frameworkcode, $tag, $code, $_ ) if $recordtype eq "biblio";
                                    push @values, $_ if $_;
                                }
                            }
                        }
                    }
                }
            }
            $solrrecord->set_value(       $index->{'type'}."_".$index->{'code'},    \@values);
            $solrrecord->set_value("srt_".$index->{'type'}."_".$index->{'code'}, $values[0]) if $index->{'sortable'} and @values > 0;

            # Add index str for facets if it's not exist
            if ( $index->{'faceted'} and @values > 0 and $index->{'type'} ne 'str' ) {
                $solrrecord->set_value("str_".$index->{'code'}, $values[0]);
            }
        }
        push @recordpush, $solrrecord;

        if ( @recordpush == 5000 ) {
            $debug eq '2' && print "id:".$id." ".`date`;
            if (defined $g) {
              $g->stop;
              $debug eq '2' && print "Building - ".$g->elapsed_str;
            }

            my $p = new Time::Progress;
            $p->restart;

            $sc->add( \@recordpush );
            @recordpush = ();

            $p->stop;
            $debug eq '2' && print "Indexing - ".$p->elapsed_str;

            $g = new Time::Progress;
            $g->restart;
        }
    }
    $sc->add( \@recordpush );
}

    
sub DeleteRecordIndex {
    my ( $recordtype, $id ) = @_;
    my $sc = GetSolrConnection;
    $sc->remove( "${recordtype}_${id}" );
}

#duplicate code with C4::Date::output('iso') ?
sub NormalizeDate {
    given( shift ) {
        when( /^(\d{2}).(\d{2}).(\d{4})$/ ) { return "$3-$2-$1T00:00:00Z" }
        when( /^(\d{4}).(\d{2})$/         ) { return "$1-$2-01T00:00:00Z" }
        when( /^(\d{2}).(\d{4})$/         ) { return "$2-$1-01T00:00:00Z" }
        when( /^(\d{4})$/                 ) { return "$1-01-01T00:00:00Z" }
    }
    return undef;
}

# overide add method in Data::SearchEngine::Solr to not use optimize function!
sub add {
    my ($self, $items, $options) = @_;

    my @docs;
    foreach my $item (@{ $items }) {
        my $doc = WebService::Solr::Document->new;
        $doc->add_fields(id => $item->id);

        foreach my $key ($item->keys) {
            my $val = $item->get_value($key);
            if(ref($val)) {
                foreach my $v (@{ $val }) {
                    $doc->add_fields($key => $v);
                }
            }  else {
                $doc->add_fields($key => $val);
            }
        }
        push(@docs, $doc);
    }

    $self->_solr->add(\@docs, $options);
}


1;
