# main.pl
# Copyright Biblibre 2008

# Main processing file : checks for messages from ABES in the dedicated mailbox
# and launch processings

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use diagnostics;

use FindBin qw($Bin);
use lib "$Bin/../sudoc/sudoc/src/";
use lib "$Bin/../../";
use Data::Dumper;
use File::Basename;
use YAML;
use Getopt::Long;

use Report;
use Getfiles;
use C4::Branch;
use C4::Biblio;
use C4::Items;
use C4::Charset;
use Dedoublonnage;

# Getting parameters
Getopt::Long::Configure('auto_help');
my $debug=$ENV{DEBUG};
my $nomail = 0;   # Did the user wanted to skip the mail and FTP part ?
my $noimport = 0; # Did the user wanted to skip the import part ?
my $help = 0;
GetOptions ('no-mail' => \$nomail, 'no-import' => \$noimport, 'help|?|h' => \$help);

# Show usage
if ($help == 1) {
	print ("Usage : perl $0 filename\n");
	exit 0;
}

# Getting config
my $conf = YAML::LoadFile(qq($Bin/config_import.yaml));
my $file=$ARGV[0];

# Creating report
my $log = Report->new;

my $commitnum=1000;

	# Deduping
	my $dd;
	
	# Statistics : Number of created, updated, discarded and skipped records
        my $nb_cre = 0;
        my $nb_maj = 0;
        my $nb_rej = 0;
        my $nb_pas = 0;
	my $dbh=C4::Context->dbh;
$dbh->{AutoCommit} = 0;
		


	$dd = Dedoublonnage->new($conf->{'ftp'}->{'localdir'}, $file);
	my $fh = IO::File->new($conf->{'ftp'}->{'localdir'}."/".$file); 
	my $batch = MARC::Batch->new('USMARC', $fh);

	# strict mode off (do not stop when there is an error)
	$batch->strict_off();
	my $branches = GetBranches();

	# Getting the yaml file with auth links
	# FIXME: Only works with uppercase files
	my $yamlfile = $file;
	$yamlfile =~ s/A([0-9]+\.RAW)/C$1.yaml/;
	my $yamlauth = YAML::LoadFile(qq#$Bin/../sudoc/sudoc/src/$yamlfile#);

	
	# For each record
	while ( my $record = $batch->next() ) {
	    #$debug && warn $record->as_formatted;
	    next unless $record;
	    if ($record){
		my ($guessed_charset, $charset_errors);
         	($record, $guessed_charset, $charset_errors) = MarcToUTF8Record($record, C4::Context->preference('marcflavour'));
		SetUTF8Flag($record);

		$record = $dd->_collectionStates( $record);  # Serial collections
		$record = $dd->_serialsFlag( $record);  # Serials flag
		$record = $dd->_autresTraitements( $record); # other processings
#		$debug && warn $record->as_formatted;
		my ($biblionumber,$biblioitemnumber,$itemnumbers_ref, $errors_ref);
                eval { ( $biblionumber, $biblioitemnumber ) = AddBiblio($record, '', { defer_marc_save => 1 }) };
            	eval { ( $itemnumbers_ref, $errors_ref ) = AddItemBatchFromMarc( $record, $biblionumber, $biblioitemnumber, '' ); };
	    	$nb_cre++;
        	$dbh->commit() if (0 == $nb_cre % $commitnum);
	    }
	    else {
		next;
	    }
	}
$dbh->commit();
$dbh->{AutoCommit} = 1;

	$log->all("Nombre de notices créées : $nb_cre");
