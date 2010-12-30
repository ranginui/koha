#!/bin/sh

mkdir generated
txt2tags -t dbk -o generated/koha_and_solr-fr.dbk koha_and_solr-fr.t2t 
txt2tags -t doku -o generated/koha_and_solr-fr.doku koha_and_solr-fr.t2t 
txt2tags -t dbk -o generated/koha_and_solr.dbk koha_and_solr.t2t 
txt2tags -t doku -o generated/koha_and_solr.doku koha_and_solr.t2t 
