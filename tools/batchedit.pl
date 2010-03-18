#!/usr/bin/perl


# Copyright 2010 SARL BibLibre
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

use CGI;
use strict;
use C4::Output;
use C4::Auth;
use C4::Branch;
use C4::Koha;
use C4::Biblio;
use C4::Context;
use C4::Debug;
use JSON;

my $input = new CGI;
my $dbh = C4::Context->dbh;

my @biblionumbers = split('/', $input->param('bib_list'));
my $op            = $input->param('op');
my ($template, $loggedinuser, $cookie);

my $frameworkcode="";
my $tagslib = &GetMarcStructure(1,$frameworkcode);

if($input->param('field') and not defined $op){
    ($template, $loggedinuser, $cookie) 
        = get_template_and_user({template_name => "acqui/ajax.tmpl",
                 query => $input,
                 type => "intranet",
                 authnotrequired => 0,
                 flagsrequired => "batchedit",
        });
    
    
    my $tag      = $input->param('field');
    my $subfield = $input->param('subfield');
    
    if($input->param('subfield')){
        my $branches = GetBranchesLoop();
         
        my @authorised_values;
        if ( $tagslib->{$tag}->{$subfield}->{authorised_value} ) {
             if ( $tagslib->{$tag}->{$subfield}->{authorised_value} eq "branches" ) {
                foreach my $thisbranch (@$branches) {
                    push @authorised_values, { 
                            code => $thisbranch->{value},
                            value => $thisbranch->{branchname},
                        };
                    # $value = $thisbranch->{value} if $thisbranch->{selected};
                }
             }elsif ( $tagslib->{$tag}->{$subfield}->{authorised_value} eq "itemtypes" ) {
                 my $sth = $dbh->prepare("SELECT itemtype,description FROM itemtypes ORDER BY description");
                 $sth->execute();
                 while ( my ( $itemtype, $description ) = $sth->fetchrow_array ) {
                    push @authorised_values, { 
                        code => $itemtype,
                        value => $description,
                    };
                 }

            }else {
                  # Getting the fields where the item location is
                  my ($location_field, $location_subfield) = GetMarcFromKohaField('items.location', $frameworkcode);
        
                  # Getting the name of the authorised values' category for item location
                  my $item_location_category = $tagslib->{$location_field}->{$location_subfield}->{'authorised_value'};
        	      # Are we dealing with item location ?
                  my $item_location = ($tagslib->{$tag}->{$subfield}->{authorised_value} eq $item_location_category) ? 1 : 0;
        
                  # If so, we sort by authorised_value, else by libelle
                  my $orderby = $item_location ? 'authorised_value' : 'lib';
        
                  my $authorised_values_sth = $dbh->prepare("SELECT authorised_value,lib FROM authorised_values WHERE category=? ORDER BY $orderby");
        
                  $authorised_values_sth->execute( $tagslib->{$tag}->{$subfield}->{authorised_value});
        
        
                  while ( my ( $value, $lib ) = $authorised_values_sth->fetchrow_array ) {
                    push @authorised_values, {
                        code => $value,
                        value => ($item_location) ? $value . " - " . $lib : $lib,
                    };
        	      	
                  }
            }
        }
      $template->param('return' => to_json(\@authorised_values));
    }else{
        my @modifiablesubf;
        
        foreach my $subfield (sort keys %{$tagslib->{$tag}}) {
            next if subfield_is_koha_internal_p($subfield);
            next if ($tagslib->{$tag}->{$subfield}->{'tab'} eq "10");
            my %subfield_data;    
            $subfield_data{subfield} = $subfield;
            push @modifiablesubf, \%subfield_data;
        }
        $template->param('return' => to_json(\@modifiablesubf));
    }
        

    output_html_with_http_headers $input, $cookie, $template->output;
    exit;
}
elsif(!defined $op) {
    ($template, $loggedinuser, $cookie)
        = get_template_and_user({template_name => "tools/batchedit.tmpl",
                 query => $input,
                 type => "intranet",
                 authnotrequired => 0,
                 flagsrequired => "batchedit",
                 });

    my @modifiablefields;
    
    foreach my $tag (sort keys %{$tagslib}) {
        my %subfield_data;        
        foreach my $subfield (sort keys %{$tagslib->{$tag}}) {
            next if $subfield_data{tag};
            next if subfield_is_koha_internal_p($subfield);
            next if ($tagslib->{$tag}->{$subfield}->{'tab'} eq "10");
            
            $subfield_data{tag}      = $tag;
            
            push @modifiablefields, \%subfield_data;
        }
    }
    
    $template->param( marcfields  => \@modifiablefields,
                      bib_list    => $input->param('bib_list'),
                     );        

}else{
    ($template, $loggedinuser, $cookie)
        = get_template_and_user({template_name => "tools/batchedit.tmpl",
                 query => $input,
                 type => "intranet",
                 authnotrequired => 0,
                 flagsrequired => "batchedit",
                 });
    my @fields    = $input->param('field');
    my @subfields = $input->param('subfield');
    my @actions   = $input->param('action');
    my @condvals   = $input->param('condval');
    my @repvals    = $input->param('repval');

    foreach my $biblionumber ( @biblionumbers ){
        my $record = GetMarcBiblio($biblionumber);
        my $biblio = GetBiblio($biblionumber);
        for(my $i = 0 ; $i < scalar(@fields) ; $i++ ){
            my $field    = $fields[$i];
            my $subfield = $subfields[$i];
            my $action   = $actions[$i];
            my $condval  = $condvals[$i];
            my $repval   = $repvals[$i];

            if($record->field($field)){
                foreach my $rfield( $record->field($field) ){
                    if($rfield->subfield($subfield)){
                        BatchModField($rfield, $subfield, $action, $condval, $repval);
                    }
                }
            }
        }
        ModBiblio($record, $biblionumber, $biblio->{frameworkcode});
    }
    
    $template->param('modsuccess' => 1);
    
}

my @biblioinfos;

for my $biblionumber (@biblionumbers){
    my $biblio = GetBiblio($biblionumber);
    push @biblioinfos, $biblio;
}
$template->param(biblioinfos => \@biblioinfos);
output_html_with_http_headers $input, $cookie, $template->output;
exit;
