package KohaTest::Search::SolrSearch;

use Test::More;
use C4::Search;
use C4::Context;

our $root = C4::Context->config('intranetdir');

#INIT {
    #Test::Class->runtests;
#}	

=head3 add_biblio_from_file

    Add biblios from files into database 
	
    shell commands
    ./stage_biblios_file.pl --file ../t/db_dependent/solr/data/split0000000 
    ./commit_biblios_file.pl --batch-number 3

    named parameters:
        filename: filename in t/db_dependent/solr/data directory

=cut

sub add_biblio_from_file {

    print"\nadd_biblio_from_file\n";
	my ( $filename ) = @_;

    # stage_biblios_file.pl call
    my $staggingCmd = $root."/misc/stage_biblios_file.pl --file ".$root."/t/db_dependent/solr/data/".$filename." --add-items";
    my $output = `$staggingCmd`;

	my $batchNumber;
    if ($output =~ m/Batch number assigned:  (\d+)/) {
	    $batchNumber = $1;
	    print "\ncmd:\n $staggingCmd \noutput:\n $output \n";
	}

    # commit_biblios_file.pl call
	my $commitCmd = $root."/misc/commit_biblios_file.pl --batch-number ".$batchNumber;
    $output = `$commitCmd`;
    $output =~ m/Number of new bibs added:        (\d+)/;
    my $nb_bibs = $1;

	print "\ncmd:\n $commitCmd \noutput:\n $output";

    return ($nb_bibs, $batchNumber);

}

=head3 truncate_tables

  Truncate tables "biblio, biblioitems, items, auth_header" from database
  configured in $KOHA_CONF.

=cut

sub truncate_tables {
    #my $dbh = C4::Context->dbh;
    #$dbh->do ("truncate biblio");
    #$dbh->do ("truncate biblioitems");
    #$dbh->do ("truncate items");
    #$dbh->do ("truncate auth_header");
}

=head3 index_all_datas

    index data with solr
    cd migration_tools/
    ./rebuild_solr.pl -r -t biblio -n 30 && ./rebuild_solr.pl -r -t authority -n 30

=cut

sub index_all_datas {
	my $indexingCmd = '$PERL5LIB/misc/migration_tools/rebuild_solr.pl -r -t biblio && $PERL5LIB/misc/migration_tools/rebuild_solr.pl -r -t authority';
	my $output = `$indexingCmd`;
	print "\ncmd:\n $indexingCmd \noutput:\n $output";
}

sub use_solr_env {
    #C4::Context->set_preference(SolrAPI, "http://localhost:8080/solr/solr");
}

1;
