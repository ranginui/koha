#!/bin/sh

# backup branch_transfers, statistics and issues then truncate them before doing upgrade to 3.0;

mysqldump --opt -uroot -pfizban12 oldkoha statistics > backup/statistics.sql
mysqldump --opt -uroot -pfizban12 oldkoha issues > backup/issues.sql
mysqldump --opt -uroot -pfizban12 oldkoha branchtransfers > backup/branchtransfers.sql
mysqldump --opt -uroot -pfizban12 oldkoha accountlines > backup/accountlines.sql
mysql -uroot -pfizban12 oldkoha < /home/chris/git/koha/import/pre_upgrade.sql