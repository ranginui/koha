#!/usr/bin/perl

use strict;
use C4::Context;
use CGI;

my $cgi = new CGI;
my $dbh = C4::Context->dbh();
my $ccode = $cgi->param('ccode');

my $query = "SELECT items.cn_sort, items.itemcallnumber
  FROM items
      LEFT JOIN biblioitems on
  (items.biblioitemnumber=biblioitems.biblioitemnumber)
      LEFT JOIN biblio on (biblioitems.biblionumber=biblio.biblionumber)
  WHERE items.ccode=?";

my $sth = $dbh->prepare($query);
$sth->execute($ccode);
my $rows = $sth->fetchall_arrayref({});

my @sorted  = sort lccn_sort @$rows;

foreach my $number (@sorted) {
    print $number->{'itemcallnumber'};
}

sub lccn_sort {
    my @lccna = _split_lccn($a->{'items.itemcallnumber'});
    my @lccnb = _split_lccn($b->{'items.itemcallnumber'});
         $lccna[0] cmp $lccnb[0]
      || $lccna[1] <=> $lccnb[1]
      || $lccna[2] cmp $lccnb[2]
      || $lccna[3] <=> $lccnb[3]
      || $lccna[4] cmp $lccnb[4];
}

sub _split_lccn {
    my ($lccn) = @_;
    $_ = $lccn;

    # lccn examples: 'HE8700.7 .P6T44 1983', 'BS2545.E8 H39 1996';
    my (@parts) =
m/                                                                                                        
        ^([a-zA-Z]+)      # HE          # BS
        (\d+(?:\.\d)*)    # 8700.7      # 2545
        \s*
        (\.*\D+)    # .P       #  E
        (\d*)       #  6       #  8
        \s*
        (.*)              # T44 1983    # H39 1996   # everything else (except any bracketing spaces)
        \s*
        /x;
    unless ( scalar @parts ) {
        warn sprintf( 'regexp failed to match string: %s', $_ );
        push @parts, $_;    # if no match, just push the whole string.
    }
    push @parts, split /\s+/,
      pop @parts
      ;    # split the last piece into an arbitrary number of pieces at spaces

    #    $debug and warn "split_lccn array: ", join(" | ", @parts), "\n";
    return @parts;
}
