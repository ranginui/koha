#!/usr/bin/perl
use strict;
#use warnings; FIXME - Bug 2505

use C4::Record;
use C4::Auth;
use C4::Output;
use C4::Biblio;
use CGI;



my $query = new CGI;
my ( $template, $loggedinuser, $cookie ) = get_template_and_user({
                                                                     template_name   => "tools/export.tt",
                                                                     query           => $query,
                                                                     type            => "intranet",
                                                                     authnotrequired => 0,
                                                                     flagsrequired   => { tools => 'export_catalog' },
                                                                     debug           => 1,
                                                                     });

my $op=$query->param("op");
my $format=$query->param("format");
if ($op eq "export") {
	my $biblionumber = $query->param("bib");
		if ($biblionumber){

			my $marc = GetMarcBiblio($biblionumber, 1);

			if ($format =~ /endnote/) {
				$marc = marc2endnote($marc);
				$format = 'endnote';
			}
			elsif ($format =~ /marcxml/) {
				$marc = marc2marcxml($marc);
			}
			elsif ($format=~ /mods/) {
				$marc = marc2modsxml($marc);
			}
			elsif ($format =~ /dc/) {
				my $error;
				($error,$marc) = marc2dcxml($marc,1);
				$format = "dublin-core.xml";
			}
			elsif ($format =~ /marc8/) {
				$marc = changeEncoding($marc,"MARC","MARC21","MARC-8");
				$marc = $marc->as_usmarc();
			}
			elsif ($format =~ /utf8/) {
				C4::Charset::SetUTF8Flag($marc, 1);
				$marc = $marc->as_usmarc();
			}
			print $query->header(
				-type => 'application/octet-stream',
                -attachment=>"bib-$biblionumber.$format");
			print $marc;
		}
}
