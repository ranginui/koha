#!/bin/bash

#autorites : fichier en RXXCXX.RAW
#biblios : fichier en RXXAXX.RAW

if (($# < 2)){
    echo "$0 nécessite 2 arguments : le nom du fichier autorités, le nom du fichier biblios à importer"
    echo "$0 fichier/autorites fichiers/biblios";
    exit 1;
}

pushd `dirname $0`/..
cp $1 fichiers/LYON3_IMPORT`date "+%Y%m%d"`R01C001.RAW
cp $2 fichiers/LYON3_IMPORT`date "+%Y%m%d"`R01A001.RAW

cd src
perl autorites.pl

perl -I. -- ../import_lyon3/import_lyon3.pl LYON3_IMPORT`date "+%Y%m%d"`R01A001.RAW
mv fichiers/LYON3_IMPORT* fichiers_traites

perl $PERL5LIB/misc/migration_tools/rebuild_zebra.pl -a -x -reset -nosanitize
perl $PERL5LIB/misc/migration_tools/rebuild_zebra.pl -b -x -reset -nosanitize

