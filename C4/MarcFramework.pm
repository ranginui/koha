package C4::MarcFramework;

# Copyright 2010 BibLibre SARL
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

use strict;
use warnings;
use C4::Context;
use C4::Koha;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

BEGIN {

    # set the version for version checking
    $VERSION = 3.4.0;
    @ISA     = qw(Exporter);
    @EXPORT  = qw(
      &TagStructureExists
      &SubfieldStructureExists
      &GetExistingFrameworks
      &GetTagStructure
      &ModTagStructure
      &AddTagStructure
      &DelTagStructure
      &DelSubfieldStructure
      &StringSearch
      &DuplicateFramework
    );
}

# check that framework is defined in marc_tag_structure
sub TagStructureExists {
    my $dbh = C4::Context->dbh;
    my $sth = $dbh->prepare("select count(*) from marc_tag_structure where frameworkcode=?");
    $sth->execute( shift );
    my ( $frameworkexist ) = $sth->fetchrow;
    return $frameworkexist;
}

sub SubfieldStructureExists {
    my ( $tagfield, $tagsubfield, $frameworkcode ) = @_;
    my $dbh  = C4::Context->dbh;
    my $sql  = "select tagfield from marc_subfield_structure where tagfield = ? and tagsubfield = ? and frameworkcode = ?";
    my $rows = $dbh->selectall_arrayref( $sql, {}, $tagfield, $tagsubfield, $frameworkcode );
    return @$rows > 0;
}

sub GetExistingFrameworks {
    my $dbh = C4::Context->dbh;
    my $sth = $dbh->prepare("select count(*),marc_tag_structure.frameworkcode,frameworktext from marc_tag_structure,biblio_framework where biblio_framework.frameworkcode=marc_tag_structure.frameworkcode group by marc_tag_structure.frameworkcode");
    $sth->execute;
    my @existingframeworkloop;
    while ( my ( $tot, $thisframeworkcode, $frameworktext ) = $sth->fetchrow ) {
        if ( $tot > 0 ) {
            push @existingframeworkloop,
              { value         => $thisframeworkcode,
                frameworktext => $frameworktext,
              };
        }
    }
    return \@existingframeworkloop;
}

sub GetTagStructure {
    my $dbh = C4::Context->dbh;
    my $sth = $dbh->prepare("select tagfield,liblibrarian,libopac,repeatable,mandatory,authorised_value from marc_tag_structure where tagfield=? and frameworkcode=?");
    $sth->execute( shift, shift );
    return $sth->fetchrow_hashref;
}

sub GetSubfieldStructure {
    my ( $tagfield, $tagsubfield, $frameworkcode ) = @_;
    my $dbh = C4::Context->dbh;

    my $sth;

    if ($tagsubfield eq '*') {
        if ($tagfield !~ /\./) {  # xxx* match
            $sth = $dbh->prepare( "select * from marc_subfield_structure where tagfield=? and frameworkcode=?" );
        } else {
            if (substr($tagfield,1,3) eq '..') { # x..*
                $tagfield = (substr($tagfield,0,1))."__";
            } elsif (substr($tagfield,2,3) eq '.') { # xx.*
                $tagfield = (substr($tagfield,0,2))."_";
            }
            $sth = $dbh->prepare( "select * from marc_subfield_structure where tagfield like ? and frameworkcode=?" );
        }
        $sth->execute( $tagfield,  $frameworkcode );
    } elsif ($tagfield =~ /\./) {
        if (substr($tagfield,1,3) eq '..') { #x..y
            $tagfield = (substr($tagfield,0,1))."__";
        } elsif (substr($tagfield,2,3) eq '.') { # xx.y
            $tagfield = (substr($tagfield,0,2))."_";
        }
        $sth = $dbh->prepare( "select * from marc_subfield_structure where tagfield like ? and tagsubfield=? and frameworkcode=?" );
        $sth->execute( $tagfield, $tagsubfield, $frameworkcode );
    } else { # xxxy
        $sth = $dbh->prepare( "select * from marc_subfield_structure where tagfield=? and tagsubfield=? and frameworkcode=?" );
        $sth->execute( $tagfield, $tagsubfield, $frameworkcode );
    }

    return $sth->fetchrow_hashref;
}

sub ModTagStructure {
    my $dbh = C4::Context->dbh;
    my ( $liblibrarian, $libopac, $repeatable, $mandatory, $authorised_value, $frameworkcode, $tagfield ) = @_;
    my $sth = $dbh->prepare( "UPDATE marc_tag_structure SET liblibrarian=? ,libopac=? ,repeatable=? ,mandatory=? ,authorised_value=? WHERE frameworkcode=? AND tagfield=?" );
    $sth->execute( $liblibrarian, $libopac, $repeatable, $mandatory, $authorised_value, $frameworkcode, $tagfield );
}

sub AddTagStructure {
    my $dbh = C4::Context->dbh;
    my ( $tagfield, $liblibrarian, $libopac, $repeatable, $mandatory, $authorised_value, $frameworkcode ) = @_;
    my $sth = $dbh->prepare( "INSERT INTO marc_tag_structure (tagfield,liblibrarian,libopac,repeatable,mandatory,authorised_value,frameworkcode) values (?,?,?,?,?,?,?)" );
    $sth->execute( $tagfield, $liblibrarian, $libopac, $repeatable, $mandatory, $authorised_value, $frameworkcode );
}

sub DelTagStructure {
    my $dbh = C4::Context->dbh;
    my $sth = $dbh->prepare("DELETE FROM marc_tag_structure WHERE tagfield=? AND frameworkcode=?");
    $sth->execute( shift, shift );
}

sub DelSubfieldStructure {
    my $dbh = C4::Context->dbh;
    my $sth = $dbh->prepare("DELETE FROM marc_subfield_structure WHERE tagfield=? AND frameworkcode=?");
    $sth->execute( shift, shift );
}

#
# the sub used for searches
#
sub SearchTag {
    my ( $searchstring, $frameworkcode ) = @_;
    my $sth = C4::Context->dbh->prepare( "
    SELECT tagfield,liblibrarian,libopac,repeatable,mandatory,authorised_value
     FROM  marc_tag_structure
     WHERE (tagfield >= ? and frameworkcode=?)
    ORDER BY tagfield
    " );
    $sth->execute( $searchstring, $frameworkcode );
    my $results = $sth->fetchall_arrayref( {} );
    return ( scalar(@$results), $results );
}

#
# the sub used to duplicate a framework from an existing one in MARC parameters tables.
#
sub DuplicateFramework {
    my ( $newframeworkcode, $oldframeworkcode ) = @_;
    my $dbh = C4::Context->dbh;
    my $sth = $dbh->prepare("select tagfield,liblibrarian,libopac,repeatable,mandatory,authorised_value from marc_tag_structure where frameworkcode=?");
    $sth->execute($oldframeworkcode);
    my $sth_insert =
      $dbh->prepare("insert into marc_tag_structure (tagfield, liblibrarian, libopac, repeatable, mandatory, authorised_value, frameworkcode) values (?,?,?,?,?,?,?)");
    while ( my ( $tagfield, $liblibrarian, $libopac, $repeatable, $mandatory, $authorised_value ) = $sth->fetchrow ) {
        $sth_insert->execute( $tagfield, $liblibrarian, $libopac, $repeatable, $mandatory, $authorised_value, $newframeworkcode );
    }

    $sth = $dbh->prepare(
"select frameworkcode,tagfield,tagsubfield,liblibrarian,libopac,repeatable,mandatory,kohafield,tab,authorised_value,authtypecode,value_builder,seealso,hidden from marc_subfield_structure where frameworkcode=?"
    );
    $sth->execute($oldframeworkcode);
    $sth_insert = $dbh->prepare(
"insert into marc_subfield_structure (frameworkcode,tagfield,tagsubfield,liblibrarian,libopac,repeatable,mandatory,kohafield,tab,authorised_value,authtypecode,value_builder,seealso,hidden) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?)"
    );
    while (
        my ($frameworkcode, $tagfield, $tagsubfield,      $liblibrarian,       $libopac,       $repeatable, $mandatory,
            $kohafield,     $tab,      $authorised_value, $thesaurus_category, $value_builder, $seealso,    $hidden
        )
        = $sth->fetchrow
      ) {
        $sth_insert->execute(
            $newframeworkcode, $tagfield, $tagsubfield,      $liblibrarian,       $libopac,       $repeatable, $mandatory,
            $kohafield,        $tab,      $authorised_value, $thesaurus_category, $value_builder, $seealso,    $hidden
        );
    }
}

1;

=head1 AUTHOR

Koha Developement team <info@koha.org>

Jean-André Santoni <jeanandre.santoni@biblibre.com>

=cut
