#!/bin/sh

# load old site into db
# dump and build records scp records
# issues needs 2 selects one for currently on loan
# select * from issues into outfile where returndate is null into outfile '/tmp/issues';
# select * from issues into outfile where returndate is not null into outfile '/tmp/issues';
# truncate issues;
# backup statistics, truncate
# backup branch_transfers, truncate
# truncate biblioitems, items, biblio, marc_* (records already created above)
# upgrade to 3.0, switch site to use it, upgrade using web interface
# export needed tables, load into new koha

mysqldump --no-create-info -c -uroot -pfizban12 oldkoha aqbasket aqbookfund aqbooksellers aqbudget aqorderbreakdown aqorderdelivery aqorders > data/orders.sql
mysqldump --opt -uroot -pfizban12 oldkoha accountlines > data/accounts.sql
mysqldump --no-create-info -c -uroot -pfizban12 oldkoha borrowers > data/borrowers.sql
mysqldump --opt -uroot -pfizban12 oldkoha ethnicity > data/ethnicity.sql
mysqldump --opt -uroot -pfizban12 oldkoha reserveconstraints reserves > data/reserves.sql
mysqldump --opt -uroot -pfizban12 oldkoha shelfcontents > data/shelfcontents.sql
mysqldump --opt -uroot -pfizban12 oldkoha statistics > data/statistics.sql