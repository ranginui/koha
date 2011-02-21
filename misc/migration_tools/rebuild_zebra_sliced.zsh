#!/usr/bin/zsh

# Copyright 2010 BibLibre SARL
# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# Koha is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Koha; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.


INCREMENT=$1
BIBLIOSTART=$2
BIBLIOEND=$3
# this script rebuild the zebra index recursively
# BIBLIOSTART is the record number to BIBLIOSTART on
# BIBLIOEND is the record number to BIBLIOEND on
# increment specify how many records we must try at once
# At the BIBLIOEND of each "chunk", this script checks if the indexing process has been OK
# if it hasn't, the slice is splitted in 10, and the reindexing is called again on each smaller chunk
# if the increment goes to 1, it means we tried to reindex 1 by 1, and the failing indexing concern wrong records

# the logs are stored in a directory called logs/ that must be a subdirectory of reindex.zsh

# at the BIBLIOEND of the script, just type :
#grep -l "previous transaction" `ls rebuild1.*.err`
# the result contains all the biblios that have not been indexed
# WARNING : the numbers are not the biblionumber but the record number, they can be reached by :
# SELECT biblionumber FROM biblio LIMIT YourNumberHere,1;

# EXAMPLE to run the script on a 800 000 biblios database :
# ./reindex.zsh 50000 0 800000
# will reindex the DB, BIBLIOSTARTing with chunks of 50k biblios

#/home/koha/src/misc/migration_tools/rebuild_zebra.pl -r -b -v -x -nosanitize -ofset 1 -min 1
for ((i=$BIBLIOSTART ; i<$BIBLIOEND ; i=i+$INCREMENT)) do
    echo "I = " $i "with increment " $INCREMENT
    ./rebuild_zebra.pl -b -v -x -nosanitize -d /tmp/rebuild -k -ofset $INCREMENT -min $i >logs/rebuild$INCREMENT.$i.log 2>logs/rebuild$INCREMENT.$i.err
    if (($INCREMENT >1 )); then
        if { grep -q "previous transaction" logs/rebuild$INCREMENT.$i.err } ; then
            echo "I must split $i (increment $INCREMENT) because previous transaction didn't reach commit"
            ((subincrement=$INCREMENT/10))
            ((newBIBLIOEND=$i+$INCREMENT))
            $0 $subincrement $i $newBIBLIOEND
        elif { ! grep -q "Records: $INCREMENT" logs/rebuild$INCREMENT.$i.err } ; then
            echo "I must split $i (increment $INCREMENT) because index was uncomplete, less than $INCREMENT records indexed"
            ((subincrement=$INCREMENT/10))
            ((newBIBLIOEND=$i+$INCREMENT))
            $0 $subincrement $i $newBIBLIOEND
        fi
    fi
done


