#!/usr/bin/perl

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
# 

use strict;
use CGI;
use C4::Auth;
use C4::Output;
use C4::Context;
use C4::Koha;
use Apharp;
use XML::Simple;
use LWP::Simple;
use IO::File;
use YAML;

my $query = new CGI;
my $cardnumber = $query->param('findborrower');

# Recherche par nom
if ( $cardnumber && substr($cardnumber, 0, 4) ne '0000' ){
	print $query->redirect( "/cgi-bin/koha/circ/circulation.pl?findborrower=$cardnumber" );
	exit;
}

$cardnumber = 0 . $cardnumber if length($cardnumber) == 15;
$cardnumber = 00 . $cardnumber if length($cardnumber) == 14;
$cardnumber =~ s/00000000([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})/00000000$4$3$2$1/i;

#IF $cardnumber
################
###### INTERROGATION_DE_LA_BASE_CARTE($cardnumber) recupere les informations minimales sur le lecteur.
###############


###### VERIFICATION DE LA VALIDITE DE LA CARTE
###### PAS VALIDE :
######### AFFICHAGE DU TEMPLATE AVEC MESSAGE D'ERREUR
###### SINON :
######### VERIFICATION EXISTANCE DU LECTEUR DANS KOHA
######### SI LE LECTEUR EXISTE dans koha :
############ Redirection sur module de circumlation
######### SINON :
############ Enregitrement des infos minimale en bdd avant update pendant la nuit

#ELSE
#### Affichage template de saisie

my ($template, $loggedinuser, $cookie)
= get_template_and_user({   template_name => "apharp/circulation-card.tmpl",
	    			        query => $query,
		    		        type => "intranet",
		    		        authnotrequired => 0,
		    		        flagsrequired => {circulate => "circulate_remaining_permissions"},
		    		        });

my $fa = getframeworkinfo('FA');

if ($cardnumber) {

    my $carddata = get_card_data($cardnumber);
    my ($invalid, $missinglist) = card_is_invalid($carddata);
    unless ($invalid) {
        if (card_exist($cardnumber)) {
	    resetTimestamp($cardnumber, 'cardnumber');
	    updateCategorycode($carddata->{categorycode}, $cardnumber) if $carddata->{categorycode} ne '';
	    updateDateexpiry($carddata->{ENDDATE}, $cardnumber, 'cardnumber');
            print $query->redirect("/cgi-bin/koha/circ/circulation.pl?findborrower=$cardnumber");
	    exit;
        }
        elsif (my $borrowernumber = getMemberByAppligest($carddata->{'APPLIGEST'}, $carddata->{'ETABLISSEM'})) {
	    resetTimestamp($borrowernumber, 'borrowernumber');
	    updateCard($borrowernumber, $cardnumber);
	    updateDateexpiry($carddata->{ENDDATE}, $borrowernumber, 'borrowernumber');
            print $query->redirect("/cgi-bin/koha/circ/circulation.pl?borrowernumber=$borrowernumber");
	    exit;
        }
        else {
            if (insert_borrower($carddata)) {
		    print $query->redirect("/cgi-bin/koha/circ/circulation.pl?findborrower=$cardnumber");
		    exit;
	    }else {
		$template->param( {error => "Cannot add borrowers to koha"} );
	    }
        }
    } elsif ( ($invalid ne 'carte inactive' || $invalid ne 'carte périmée') && card_exist($cardnumber) ) {
	resetTimestamp($cardnumber, 'cardnumber');
	print $query->redirect("/cgi-bin/koha/circ/circulation.pl?findborrower=$cardnumber");
	exit;
    } else {
        $template->param({ cardnumber      => $cardnumber,
                           invalid         => $invalid,
                           missinglist     => $missinglist,
                         });
    }
}



# Checking if there is a Fast Cataloging Framework

$template->param({ fast_cataloging => 1 }) if (defined $fa);

output_html_with_http_headers $query, $cookie, $template->output;


sub get_card_data {
    my $cardnumber = shift;

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    my $schooltyear = 1900 + $year;
    $schooltyear-- if $mon < 8;
    
    #Suppression des 8 zéros au debut de la chaine pour compatibilité avec le webservice.
    $cardnumber =~ s/^0{8}//;
    my $borrower;

    my $doc = get "http://139.124.135.90:8080/axis2/services/SquirelWebServices/getBiblibData?pupi=$cardnumber&year=$schooltyear";
    my $xmlsimple = XML::Simple->new();
    my $data = $xmlsimple->XMLin($doc) if $doc;

    my ($step, $category, $etablissement, $composante, $appligest);

    if (ref $data->{'ns:return'}->{'ax21:registrations'} eq 'ARRAY') {

        #my $configfile = "config/step.yaml";
        #my ($map)= YAML::LoadFile($configfile) or die "unable to load $configfile ";
        my $rightlevel = 0;
        my $steplevel = { "L" => 1, "M" => 2, "D" => 3 };
 
        foreach (@{ $data->{'ns:return'}->{'ax21:registrations'} }) {
            my $tmpcategory = category_for($_->{'ax21:step'}, $_->{'ax21:establishment'}, $cardnumber) || 0;
            if ($steplevel->{$tmpcategory} >= $rightlevel) {
                $rightlevel = $steplevel->{$tmpcategory};
                $step = $_->{'ax21:step'} || '';
                $category = $tmpcategory;
                $etablissement = $_->{'ax21:establishment'} || '';
                $composante = $_->{'ax21:component'} || '';
                $appligest = $_->{'ax21:externalRef'} || '';
            }
        }
    } 

    else {
        my $attr = $data->{'ns:return'}->{'ax21:registrations'};
        $step = $attr->{'ax21:step'} || '';
        $etablissement = $attr->{'ax21:establishment'} || '';
        $category = $data->{'ns:return'}->{'ax21:profilWording'} eq "Etudiant" ? category_for($step, $etablissement, $cardnumber ) : "P";
        $composante = $attr->{'ax21:component'} || '';
        $appligest = $attr->{'ax21:externalRef'} || '';
    }
    
    #Calcul du branchcode
    my $branchcode;
    if ($etablissement) {
	my $configfile = "config/" . lc($etablissement) . "_" . ($data->{'ns:return'}->{'ax21:profilWording'} eq "Etudiant" ? "etud.yaml" : "pers.yaml");
	my @map = YAML::LoadFile($configfile) or die "unable to load $configfile ";
	$branchcode = $map[1]->{branchcode}->{ $composante } || '';
	$branchcode = '' if $branchcode !~ m/^$etablissement/;
	appendtolog("WARN: branchcode par defaut pour la carte n° $cardnumber", "apharp-error-log") unless $branchcode;
    }

    $borrower = { 'firstname'       => $data->{'ns:return'}->{'ax21:firstname'} || '',
                  'surname'         => $data->{'ns:return'}->{'ax21:name'} || '',
                  'TYPE'            => $data->{'ns:return'}->{'ax21:profilWording'} || '',
                  'ETAT'            => $data->{'ns:return'}->{'ax21:status'} || '',
                  'ENDDATE'         => $data->{'ns:return'}->{'ax21:endDate'} || '',
                  'CODEETAPE'       => $step || '',
                  'categorycode'    => $category,
                  'branchcode'      => $branchcode || $etablissement . 'INC',
                  'ETABLISSEM'      => $etablissement,
                  'COMPOSANTE'      => $composante,
                  'APPLIGEST'       => $appligest,
                  'cardnumber'      => $cardnumber,
                };
    
    #print $log Data::Dumper::Dumper($borrower);
    return $borrower;
}
