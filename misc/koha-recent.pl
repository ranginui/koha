#!/usr/bin/perl

use strict;
use C4::Context;
use CGI;
use Business::ISBN;
use YAML;
use LWP::Simple;
use Getopt::Long;
use File::Slurp;

my ( $config_file, $sqlNumGet, $sqlNumShow, $layout, $target ) =
  ( undef, 200, 6, 'table', '' );

GetOptions(
    'config=s'      => \$config_file,
    'numtosearch=s' => \$sqlNumGet,
    'numtoshow=s'   => \$sqlNumShow,
    'layout=s'      => \$layout,
    'target=s'      => \$target,
);

die "You need to specify a config file.\n" if !$config_file;

my $config = read_file($config_file);
my $conf   = Load $config;

my $dbh = C4::Context->dbh();

my $isbn;
my $isbn10;
my $amazonImg;

my $sqlQuery = <<EOH;
SELECT biblio.biblionumber AS bnum, biblio.title,biblio.author, biblioitems.isbn 
FROM biblio,items,biblioitems 
WHERE items.biblionumber = biblio.biblionumber AND biblioitems.biblionumber = biblio.biblionumber 
GROUP by biblio.biblionumber 
ORDER by dateaccessioned DESC 
LIMIT $sqlNumGet
EOH

my $uni = $dbh->prepare("set names utf8;");
my $sth = $dbh->prepare($sqlQuery);
$uni->execute();
$sth->execute();

my $query;
if ( $layout eq 'html' ) {
    $query = new CGI;
    print $query->header( -charset => 'utf-8' );
    print $query->start_html( -encoding => 'utf-8' );
}

#print <<CSS;
#<style type="text/css">
#td { font-family: Arial, Verdana; font-size: 12px; }
#p.cover { height: 185px; width: 150px; background: url($conf->{'coverBgUrl'}) no-repeat center; align: center; }
#</style>
#CSS
print '<b> New Titles </b>';
print "\t<table width=\"100%\">\n\t\t";
my $i = 0;
while ( ( my $ref = $sth->fetchrow_hashref() ) && $i < $sqlNumShow ) {
    if ( defined( $ref->{'isbn'} ) ) {
        $ref->{'isbn'} =~ s/\|.*//;
        $isbn = Business::ISBN->new( $ref->{'isbn'} );
        if ($isbn) {
            $isbn = $isbn->as_isbn10;
            if ( !$isbn ) {
                $isbn10    = '';
                $amazonImg = '';
                next;
            }
            $isbn10 = $isbn->isbn;
            $amazonImg =
                '<img src="http://images.amazon.com/images/P/' 
              . $isbn10
              . '.01._THUMBZZZ_PB_PU_PU0_.jpg" alt="" border="0" />';

        }
        else {
            $isbn10    = '';
            $amazonImg = '';
            next;
        }
    }
    else {
        $isbn10    = '';
        $amazonImg = '';
        next;
    }
    if (
        !hasImage(
                "http://images.amazon.com/images/P/" 
              . $isbn10
              . ".01._THUMBZZZ_PB_PU_PU0_.jpg"
        )
      )
    {
        next;
    }

    if ( $i == 0 ) {
        print "<tr>\n";
    }
    if ( $i == 3 ) {
        print "</tr><tr>\n";
    }
    $i++;
    $ref->{'title'} =~ s/\ (:|\/)$//g;

    print <<MAIN
			<td valign="top" align="center" border="0">
				<p class="cover"><a border="0" target="_$target" href="$conf->{'kohaOpacUrl'}/opac-detail.pl?biblionumber=$ref->{'bnum'}">$amazonImg</a></p>
				<br />
				<a border="0" target="_$target" href="$conf->{'kohaOpacUrl'}/opac-detail.pl?biblionumber=$ref->{'bnum'}"><b>$ref->{'title'}</b></a>
				<br />
				$ref->{'author'}
			</td>
MAIN
      ;
}

print "\n\t\t</tr>\n\t</table>\n";

$sth->finish();

# Find all the serials that have been received (status=2) 
my $serials_query=<<EOQ;
SELECT * FROM 
    (SELECT biblio.biblionumber, title, serialseq,publisheddate, status 
    FROM serial,biblio 
    WHERE biblio.biblionumber=serial.biblionumber 
        AND status=2 
        AND publisheddate IS NOT NULL 
    ORDER BY publisheddate DESC) AS serials 
GROUP BY biblionumber 
ORDER BY publisheddate DESC
LIMIT 10
EOQ
#"select biblio.biblionumber,title,max(dateaccessioned) as rec,enumchron from biblio,items where biblio.biblionumber=items.biblionumber and (itype='JOURNAL') and enumchron is not NULL group by biblio.biblionumber,enumchron order by rec desc limit 10;";
if ( $conf->{newJournals} ) {
    print '<b> New Journals </b>
<table width="100%">';

    $sth = $dbh->prepare($serials_query);
    $sth->execute();
    while ( my $row = $sth->fetchrow_hashref() ) {
        print <<MAIN
<tr><td valign="top" align="left" border="0" class="newjournal">
<a href="$conf->{'kohaOpacUrl'}/opac-detail.pl?biblionumber=$row->{'biblionumber'}"><b class="newjournaltitle">$row->{title}</b></a> - <a href="$conf->{'kohaOpacUrl'}/opac-detail.pl?biblionumber=$row->{'biblionumber'}" class="newjournalserialseq">$row->{serialseq}</a>
</td></tr>
MAIN
          ;
    }
    print '</table>';
}

if ( $layout eq 'html' ) {
    print $query->end_html;
}

# Disconnect from the database.
$dbh->disconnect();

sub hasImage {
    my ($URL_in) = @_;
    my $content = head($URL_in);
    if ( $content && ($content->content_type eq "image/jpeg" )) {
        return 1;
    }
    else {
        return 0;
    }
}
