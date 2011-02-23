#!/usr/bin/perl
use Modern::Perl;
use Test::More;
use ZOOM;
my $host=$ARGV[0]||'flaubert.biblibre.com';
my $port=$ARGV[1]||9998;
my $nbservers=15;
my @z;
my @r;
my $ev;
print "Synchronous connections\n";
my $conn = new ZOOM::Connection($host, $port,
                                         databaseName => "biblio");
            $conn->option(preferredRecordSyntax => "usmarc");
for my $i (1..1000){
        eval{
            my $rs = $conn->search_pqf($i);
            my $n = $rs->size();
            ok($n>0,"Search $i returns $n results");
            print $rs->record(0)->render();
        };
        if ($@) {
            print "Error ", $@->code(), ": ", $@->message(), "\n";
        }
}

print "Asynchronous connections\n";
for my $i (1..$nbservers) {
    warn $i;
    $z[$i-1] = new ZOOM::Connection("$host:$port/biblio",0, # "$host:$port/biblio", 0,
                                     async => 1, # asynchronous mode
                                     count => 1, # piggyback retrieval count
                                     preferredRecordSyntax => "usmarc");
    $r[$i-1] = $z[$i-1]->search_pqf("$i");
}

while ((my $i = ZOOM::event(\@z)) != 0) {
            print("connection ", $i-1, ": ", ZOOM::event_str($ev), "\n");
            $ev = $z[$i-1]->last_event();
            if ($ev == ZOOM::Event::ZEND) {
                my $size = $r[$i-1]->size();
                print "connection ", $i-1, ": $size hits\n";
                ok($size>0,"search return $size results");
                print $r[$i-1]->record(0)->render()
                    if $size > 0;
            }
}
done_testing();
