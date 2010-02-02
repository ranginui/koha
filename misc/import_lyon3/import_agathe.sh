#!/bin/zsh
perl import_agathe.pl -file /home/koha/sites/univ_lyon3/Données/export_lyon3_agathe.mrc -filter 9.. -match ident,001 -update  -l agathe.log -t -yamlinput /home/koha/versions/univ_lyon3/misc/sudoc/sudoc/src/$1
