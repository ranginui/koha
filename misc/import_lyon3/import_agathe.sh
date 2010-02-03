#!/bin/zsh
cd /home/koha/versions/univ_lyon3/misc/sudoc/sudoc/src
perl -I. -- ../import_lyon3/import_agathe.pl -file /home/koha/sites/univ_lyon3/Données/export_lyon3_agathe.mrc -filter 9.. -match ident,001 -update  -l ../import_lyon3/agathe.log   -yamlinput /home/koha/versions/univ_lyon3/misc/sudoc/sudoc/src/$1
