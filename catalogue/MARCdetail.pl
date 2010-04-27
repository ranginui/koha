#!/usr/bin/perl

# Copyright 2000-2002 Katipo Communications
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
# You should have received a copy of the GNU General Public License along
# with Koha; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

=head1 NAME

MARCdetail.pl : script to show a biblio in MARC format

=head1 SYNOPSIS


=head1 DESCRIPTION

This script needs a biblionumber as parameter

It shows the biblio in a (nice) MARC format depending on MARC
parameters tables.

The template is in <templates_dir>/catalogue/MARCdetail.tmpl.
this template must be divided into 11 "tabs".

The first 10 tabs present the biblio, the 11th one presents
the items attached to the biblio

=head1 FUNCTIONS

=over 2

=cut

use strict;
#use warnings; FIXME - Bug 2505

use C4::Auth;
use C4::Context;
use C4::Output;
use CGI;
use C4::Koha;
use MARC::Record;
use C4::Biblio;
use C4::Items;
use C4::Acquisition;
use C4::Serials;    #uses getsubscriptionsfrombiblionumber GetSubscriptionsFromBiblionumber
use C4::Search;		# enabled_staff_search_views


my $query        = new CGI;
my $dbh          = C4::Context->dbh;
my $biblionumber = $query->param('biblionumber');
my $frameworkcode = $query->param('frameworkcode');
$frameworkcode = GetFrameworkCode( $biblionumber ) unless ($frameworkcode);
my $popup        =
  $query->param('popup')
  ;    # if set to 1, then don't insert links, it's just to show the biblio
my $subscriptionid = $query->param('subscriptionid');

my $tagslib = &GetMarcStructure(1,$frameworkcode);

my $record = GetMarcBiblio($biblionumber);
my $biblio = GetBiblioData($biblionumber);
# open template
my ( $template, $loggedinuser, $cookie ) = get_template_and_user(
    {
        template_name   => "catalogue/MARCdetail.tmpl",
        query           => $query,
        type            => "intranet",
        authnotrequired => 0,
        flagsrequired   => { catalogue => 1 },
        debug           => 1,
    }
);

#count of item linked
my $itemcount = GetItemsCount($biblionumber);
$template->param( count => $itemcount,
					bibliotitle => $biblio->{title}, );

#Getting the list of all frameworks
my $queryfwk =
  $dbh->prepare("select frameworktext, frameworkcode from biblio_framework");
$queryfwk->execute;
my %select_fwk;
my @select_fwk;
my $curfwk;
push @select_fwk, "Default";
$select_fwk{"Default"} = "Default";

while ( my ( $description, $fwk ) = $queryfwk->fetchrow ) {
    push @select_fwk, $fwk;
    $select_fwk{$fwk} = $description;
}
$curfwk=$frameworkcode;
my $framework=CGI::scrolling_list( -name     => 'Frameworks',
            -id => 'Frameworks',
            -default => $curfwk,
            -OnChange => 'Changefwk(this);',
            -values   => \@select_fwk,
            -labels   => \%select_fwk,
            -size     => 1,
            -multiple => 0 );
$template->param(framework => $framework);
# fill arrays
my @loop_data = ();
my $tag;

# loop through each tab 0 through 9
for ( my $tabloop = 0 ; $tabloop <= 10 ; $tabloop++ ) {

    # loop through each tag
    my @fields    = $record->fields();
    my @loop_data = ();
    my @subfields_data;

    # deal with leader
    unless ( $tagslib->{'000'}->{'@'}->{tab} ne $tabloop )
    {    #  or ($tagslib->{'000'}->{'@'}->{hidden} =~ /-7|-4|-3|-2|2|3|5|8/ )) {
        my %subfield_data;
        $subfield_data{marc_lib}      = $tagslib->{'000'}->{'@'}->{lib};
        $subfield_data{marc_value}    = $record->leader();
        $subfield_data{marc_subfield} = '@';
        $subfield_data{marc_tag}      = '000';
        push( @subfields_data, \%subfield_data );
        my %tag_data;
        $tag_data{tag} = '000 -' . $tagslib->{'000'}->{lib};
        my @tmp = @subfields_data;
        $tag_data{subfield} = \@tmp;
        push( @loop_data, \%tag_data );
        undef @subfields_data;
    }
    @fields = $record->fields();
    for ( my $x_i = 0 ; $x_i <= $#fields ; $x_i++ ) {

        # if tag <10, there's no subfield, use the "@" trick
        if ( $fields[$x_i]->tag() < 10 ) {
            next
              if (
                $tagslib->{ $fields[$x_i]->tag() }->{'@'}->{tab} ne $tabloop );
            next if ( $tagslib->{ $fields[$x_i]->tag() }->{'@'}->{hidden} =~ /-7|-4|-3|-2|2|3|5|8/);
            my %subfield_data;
            $subfield_data{marc_lib} =
              $tagslib->{ $fields[$x_i]->tag() }->{'@'}->{lib};
            $subfield_data{marc_value}    = $fields[$x_i]->data();
            $subfield_data{marc_subfield} = '@';
            $subfield_data{marc_tag}      = $fields[$x_i]->tag();
            push( @subfields_data, \%subfield_data );
        }
        else {
            my @subf = $fields[$x_i]->subfields;

            # loop through each subfield
            for my $i ( 0 .. $#subf ) {
                $subf[$i][0] = "@" unless $subf[$i][0];
                next
                  if (
                    $tagslib->{ $fields[$x_i]->tag() }->{ $subf[$i][0] }->{tab}
                    ne $tabloop );
                next
                  if ( $tagslib->{ $fields[$x_i]->tag() }->{ $subf[$i][0] }
                    ->{hidden} =~ /-7|-4|-3|-2|2|3|5|8/);
                my %subfield_data;
                $subfield_data{short_desc} = $tagslib->{ $fields[$x_i]->tag() }->{ $subf[$i][0] }->{lib};
                $subfield_data{long_desc} =
                  $tagslib->{ $fields[$x_i]->tag() }->{ $subf[$i][0] }->{lib};
                $subfield_data{link} =
                  $tagslib->{ $fields[$x_i]->tag() }->{ $subf[$i][0] }->{link};

#                 warn "tag : ".$tagslib->{$fields[$x_i]->tag()}." subfield :".$tagslib->{$fields[$x_i]->tag()}->{$subf[$i][0]}."lien koha? : "$subfield_data{link};
                if ( $tagslib->{ $fields[$x_i]->tag() }->{ $subf[$i][0] }
                    ->{isurl} )
                {
                    $subfield_data{marc_value} = $subf[$i][1];
					$subfield_data{is_url} = 1;
                }
                elsif ( $tagslib->{ $fields[$x_i]->tag() }->{ $subf[$i][0] }
                    ->{kohafield} eq "biblioitems.isbn" )
                {

#                    warn " tag : ".$tagslib->{$fields[$x_i]->tag()}." subfield :".$tagslib->{$fields[$x_i]->tag()}->{$subf[$i][0]}. "ISBN : ".$subf[$i][1]."PosttraitementISBN :".DisplayISBN($subf[$i][1]);
                    $subfield_data{marc_value} = $subf[$i][1];
                }
                else {
                    if ( $tagslib->{ $fields[$x_i]->tag() }->{ $subf[$i][0] }
                        ->{authtypecode} )
                    {
                        $subfield_data{authority} = $fields[$x_i]->subfield(9);
                    }
                    $subfield_data{marc_value} =
                      GetAuthorisedValueDesc( $fields[$x_i]->tag(),
                        $subf[$i][0], $subf[$i][1], '', $tagslib) || $subf[$i][1];

                }
                $subfield_data{marc_subfield} = $subf[$i][0];
                $subfield_data{marc_tag}      = $fields[$x_i]->tag();
                push( @subfields_data, \%subfield_data );
            }
        }
        if ( $#subfields_data == 0 ) {
            $subfields_data[0]->{marc_lib}      = '';
#            $subfields_data[0]->{marc_subfield} = '';
        }
        if ( $#subfields_data >= 0) {
            my %tag_data;
            if ( $fields[$x_i]->tag() eq $fields[ $x_i - 1 ]->tag() && (C4::Context->preference('LabelMARCView') eq 'economical')) {
                $tag_data{tag} = "";
            }
            else {
                if ( C4::Context->preference('hide_marc') ) {
                    $tag_data{tag} = $tagslib->{ $fields[$x_i]->tag() }->{lib};
                }
                else {
                    $tag_data{tag} =
                        $fields[$x_i]->tag() 
                      . ' '
                      . C4::Koha::display_marc_indicators($fields[$x_i])
                      . ' - '
                      . $tagslib->{ $fields[$x_i]->tag() }->{lib};
                }
            }
            my @tmp = @subfields_data;
            $tag_data{subfield} = \@tmp;
            push( @loop_data, \%tag_data );
            undef @subfields_data;
        }
    }
    $template->param( $tabloop . "XX" => \@loop_data );
}

# now, build item tab !
# the main difference is that datas are in lines and not in columns : thus, we build the <th> first, then the values...
# loop through each tag
# warning : we may have differents number of columns in each row. Thus, we first build a hash, complete it if necessary
# then construct template.
my @fields = $record->fields();
my %witness
  ; #---- stores the list of subfields used at least once, with the "meaning" of the code
my @big_array;
my $norequests = 1;
foreach my $field (@fields) {
    next if ( $field->tag() < 10 );
    my @subf = $field->subfields;
    my %this_row;

    # loop through each subfield
    for my $i ( 0 .. $#subf ) {
        next if ( $tagslib->{ $field->tag() }->{ $subf[$i][0] }->{tab} ne 10 );
        next if ( $tagslib->{ $field->tag() }->{ $subf[$i][0] }->{hidden} =~ /-7|-4|-3|-2|2|3|5|8/);
        $witness{ $subf[$i][0] } =
        $tagslib->{ $field->tag() }->{ $subf[$i][0] }->{lib};
        $this_row{ $subf[$i][0] } = GetAuthorisedValueDesc( $field->tag(),
                        $subf[$i][0], $subf[$i][1], '', $tagslib) || $subf[$i][1];
        $norequests = 0 if $subf[$i][1] ==0 and $tagslib->{ $field->tag() }->{ $subf[$i][0] }->{kohafield} eq 'items.notforloan';
    }
    if (%this_row) {
        push( @big_array, \%this_row );
    }
}

my ($holdingbrtagf,$holdingbrtagsubf) = &GetMarcFromKohaField("items.holdingbranch",$frameworkcode);
@big_array = sort {$a->{$holdingbrtagsubf} cmp $b->{$holdingbrtagsubf}} @big_array;

#fill big_row with missing datas
foreach my $subfield_code ( keys(%witness) ) {
    for ( my $i = 0 ; $i <= $#big_array ; $i++ ) {
        $big_array[$i]{$subfield_code} = "&nbsp;"
          unless ( $big_array[$i]{$subfield_code} );
    }
}

# now, construct template !
my @item_value_loop;
my @header_value_loop;
for ( my $i = 0 ; $i <= $#big_array ; $i++ ) {
    my $items_data;
    foreach my $subfield_code ( keys(%witness) ) {
        $items_data .= "<td>" . $big_array[$i]{$subfield_code} . "</td>";
    }
    my %row_data;
    $row_data{item_value} = $items_data;
    push( @item_value_loop, \%row_data );
}
foreach my $subfield_code ( keys(%witness) ) {
    my %header_value;
    $header_value{header_value} = $witness{$subfield_code};
    push( @header_value_loop, \%header_value );
}

my $subscriptionscount = CountSubscriptionFromBiblionumber($biblionumber);

if ($subscriptionscount) {
    my $subscriptions = GetSubscriptionsFromBiblionumber($biblionumber);
    my $subscriptiontitle = $subscriptions->[0]{'bibliotitle'};
    $template->param(
        subscriptiontitle   => $subscriptiontitle,
        subscriptionsnumber => $subscriptionscount,
    );
}

$template->param (
    norequests              => $norequests, 
    item_loop               => \@item_value_loop,
    item_header_loop        => \@header_value_loop,
    biblionumber            => $biblionumber,
    popup                   => $popup,
    hide_marc               => C4::Context->preference('hide_marc'),
	marcview => 1,
	z3950_search_params		=> C4::Search::z3950_search_args($biblio),
	C4::Search::enabled_staff_search_views,
);

output_html_with_http_headers $query, $cookie, $template->output;
