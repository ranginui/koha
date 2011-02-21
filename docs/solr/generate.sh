#!/bin/sh

mkdir generated
txt2tags -t dbk -o generated/koha_and_solr.dbk koha_and_solr.t2t 
txt2tags -t doku -o generated/koha_and_solr.doku koha_and_solr.t2t 

txt2tags -t doku -o generated/koha_and_solr.doku koha_and_solr.t2t
txt2tags -t doku -o generated/solr_01_startguide-fri.doku solr_01_startguide-fr.t2t
txt2tags -t doku -o generated/solr_02_advanceduse-fr.doku solr_02_advanceduse-fr.t2t
txt2tags -t doku -o generated/solr_03_techguide-fr.doku solr_03_techguide-fr.t2t
txt2tags -t doku -o generated/solr_03_techguide_01_install-fr.doku  solr_03_techguide_01_install-fr.t2t

txt2tags -t html -o generated/koha_and_solr.html koha_and_solr.t2t
txt2tags -t html -o generated/solr_01_startguide-fr.html solr_01_startguide-fr.t2t
txt2tags -t html -o generated/solr_02_advanceduse-fr.html solr_02_advanceduse-fr.t2t
txt2tags -t html -o generated/solr_03_techguide-fr.html solr_03_techguide-fr.t2t
txt2tags -t html -o generated/solr_03_techguide_01_install-fr.html solr_03_techguide_01_install-fr.t2t

scp generated/*.html descartes:dev/solr/doc/
