package C4::External::Electre;

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

use strict;
use warnings;

use SOAP::Lite;
use Data::Dumper;
use MIME::Base64;
use Encode;
# use utf8;
use MARC::Record;
use MARC::File::USMARC;
use MARC::File::XML;
use C4::Biblio;
use C4::Koha;
use XML::LibXML;
use XML::LibXSLT;

use vars qw($VERSION @ISA @EXPORT);

BEGIN {

    # set the version for version checking
    $VERSION = 3.0.5;
    @ISA     = qw(Exporter);
    @EXPORT  = qw(
      &GetElectreSessionToken
      &InitElectreSearch
      &GetElectreImage
      &GetElectreQuatriemeXml
      &GetElectreTdm
    );
}

=head1 NAME

C4::Electre - ws electre functions

=head1 DESCRIPTION

Electre.pm contains functions to get biblio informations from the electre's web service

=cut
my $sessionToken='';

sub GetElectreSessionToken {
	if($sessionToken eq '')
	{
		my $login = SOAP::Lite->service("http://www.electre.com/webservice/login.asmx?wsdl");
		$login->soapversion('1.2');
		$login->ns('http://www.w3.org/2003/05/soap-envelope', 'soap12');
		my %result = $login->loginUser(C4::Context->preference("ElectreLogin"), C4::Context->preference("ElectrePassw"));
		$sessionToken = $result{'loginUserResult'};
	}
	return $sessionToken;
}

sub InitElectreSearch{
	my $sessionToken=GetElectreSessionToken();
	my $search = SOAP::Lite->service("http://www.electre.com/webservice/search.asmx?wsdl");
	$search->soapversion('1.2');
	$search->ns('http://www.w3.org/2003/05/soap-envelope', 'soap12');
	return $search;
}

sub InitEanFromBiblionumber{
	my $biblionumber = shift;
	my $ean;
	my $record = GetMarcBiblio($biblionumber);
	if ( !$record ) {return '0';}
	my $ean_10a;
	if ( C4::Context->preference("marcflavour") eq "UNIMARC" ) {
		if ( !$record->field('010')) {return '0';}
		if ( !$record->field('010')->subfield("a")) {return '0';}
		$ean_10a=$record->field('010')->subfield("a");
	}
	else{
		if ( !$record->field('020')) {return '0';}
		if ( !$record->field('020')->subfield("a") ) {return '0';}
		$ean_10a=$record->field('020')->subfield("a");
	}
	$ean_10a=~s/\D//g;
	#warn Data::Dumper::Dumper $ean_10a;
	if($ean_10a=~m/^[\d]{13}$/){
		$ean=$ean_10a;
	}
	elsif(($ean_10a=~m/^[\d]{10}$/) or ($ean_10a=~m/^[\d]{9}$/)){
		my $eancalc="978".$ean_10a;
		my @eant=split('',$eancalc);
		my $c13 = ((10-(($eant[0]+3*$eant[1]+$eant[2]+3*$eant[3]+$eant[4]+3*$eant[5]+$eant[6]+3*$eant[7]+$eant[8]+3*$eant[9]+$eant[10]+3*$eant[11])%10))%10);
		$ean=substr($eancalc,0,12) .$c13;
		#warn Data::Dumper::Dumper $c13;
	}
	else{
		return '0';
	}
	#warn Data::Dumper::Dumper $ean;
	return $ean;
}

sub GetElectreImage{
	my ($biblionumber,$initboolscaled) = @_;
	my $ean = InitEanFromBiblionumber($biblionumber);
	if($ean eq '0'){return '0';}
	my $boolscaled;
	if ($initboolscaled and (($initboolscaled eq "true") or ($initboolscaled eq "false")))
	{
		$boolscaled=$initboolscaled;
	}
	else
	{
		if(C4::Context->preference("OpacElectreScaledImage")){$boolscaled="true";}else{$boolscaled="false";}
	}
	my $sessionToken=GetElectreSessionToken();
	my $search=InitElectreSearch();
	my %result_getImage=$search->getImage($sessionToken, $ean, $boolscaled);
	return encode_base64 $result_getImage{'getImageResult'};
}

sub GetElectreQuatriemeXml{
	my $biblionumber = shift;
	my $ean = InitEanFromBiblionumber($biblionumber);
	if($ean eq '0'){return '0';}
	my $sessionToken=GetElectreSessionToken();
	my $search=InitElectreSearch();
	my %result_getQuatriemeXml = $search->getQuatriemeXml($sessionToken, $ean);
	return encode('utf8', $result_getQuatriemeXml{'getQuatriemeXmlResult'});
}

sub GetElectreTdm{
	my $biblionumber = shift;
	my $ean = InitEanFromBiblionumber($biblionumber);
	if($ean eq '0'){return '0';}
	my $sessionToken=GetElectreSessionToken();
	my $search=InitElectreSearch();
	my %result_getTdmXml = $search->getTdmXml($sessionToken, $ean);
	my $xslt = XML::LibXSLT->new();
	if ($result_getTdmXml{'getTdmXmlResult'})
	{
		my $source = XML::LibXML->load_xml(string => encode('utf8', $result_getTdmXml{'getTdmXmlResult'}));
		my $style_doc = XML::LibXML->load_xml(location=>'../koha-tmpl/opac-tmpl/prog/en/xslt/ElectreTdm.xsl', no_cdata=>1);
		my $stylesheet = $xslt->parse_stylesheet($style_doc);
		my $results = $stylesheet->transform($source);
		return $stylesheet->output_as_bytes($results);
	}
	else
	{
		return 0;
	}
}

1;

__END__

=head1 AUTHOR

Stephane Delaune delaune.stephane@gmail.com

=cut
