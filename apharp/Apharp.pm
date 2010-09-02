package Apharp;

use strict;
use warnings;

use C4::Context;
use C4::Members;
use C4::Members::AttributeTypes;
use C4::Dates qw(format_date_in_iso);
use Data::Dumper;
use Text::CSV;
use LWP::UserAgent;
use YAML;
use C4::Members;
use Mail::Sendmail;
use POSIX;
use DateTime;

our @ISA = qw(Exporter);
our @EXPORT = qw(
    &getBorrowers 
    &get_borrowers_attr
    &getMemberByAppligest 
    &resetTimestamp
    &updateCategorycode
    &updateCard
    &data_to_koha 
    &card_exist 
    &filterhash 
    &extract_extended_attributes
    &delete_useless_fields
    &card_is_invalid
    &insert_borrower
    &category_for 
    &appendtolog );

sub getBorrowers {
    my $new = shift;
    my $dbh = C4::Context->dbh;
    my $query = " SELECT ba1.attribute AS APPLIGEST, ba3.attribute AS ETABLISSEM, borrowers.categorycode
                  FROM borrower_attributes AS ba1, borrower_attributes AS ba2, borrower_attributes AS ba3, borrowers
                  WHERE ba1.borrowernumber = ba2.borrowernumber
                  AND ba2.borrowernumber = ba3.borrowernumber
                  AND ba1.borrowernumber = borrowers.borrowernumber
                  AND ba1.code = 'APPLIGEST'
                  AND ba3.code = 'ETABLISSEM'";

    $query .= " AND ba2.code = 'TIMESTAMP' AND ba2.attribute IS NULL" if $new;
    $query .= " GROUP BY APPLIGEST, ETABLISSEM";
    my $sth = $dbh->prepare($query);
    $sth->execute();
    my $result = $sth->fetchall_arrayref({});
    return $result;
}

sub getMemberByAppligest {
    my ($appligest, $site) = @_;

    my $dbh = C4::Context->dbh;
    my $query = qq{SELECT ba2.borrowernumber FROM borrower_attributes AS ba1, borrower_attributes AS ba2, borrower_attributes AS ba3, borrowers
			WHERE ba1.borrowernumber = ba2.borrowernumber
			AND ba2.borrowernumber = ba3.borrowernumber
			AND ba1.borrowernumber = borrowers.borrowernumber
			AND ba1.code = 'APPLIGEST'
			AND ba3.code = 'ETABLISSEM'
			AND ba1.attribute = ?
			AND ba3.attribute = ? 
			GROUP BY borrowernumber };
    my $sth = $dbh->prepare($query);
    $sth->execute($appligest, $site);
    my $result = $sth->fetchrow_array;
    return $result;
}

sub getMemberByCardnumber {
    my $cardnumber = shift;

    my $dbh = C4::Context->dbh;
    my $query = "SELECT borrowernumber FROM borrowers where cardnumber=?";
    my $sth = $dbh->prepare($query);
    $sth->execute($cardnumber);
    my $result = $sth->fetchrow_array;
    return $result
}

sub resetTimestamp {
    my ($identifier, $by) = @_;
    my $borrowernumber;

    if ($by eq 'borrowernumber') {
	$borrowernumber = $identifier;
    } else {
	$borrowernumber = getMemberByCardnumber($identifier);
    }

    my $dbh = C4::Context->dbh;
    my $query = "UPDATE borrower_attributes SET attribute=NULL WHERE code='TIMESTAMP' AND borrowernumber=?";
    my $sth = $dbh->prepare($query);
    my $res = $sth->execute($borrowernumber);

    if ( $res == 0 ) {
	my $query = "INSERT INTO borrower_attributes (borrowernumber, code, attribute) VALUES ($borrowernumber, 'TIMESTAMP', NULL)";
	my $sth = $dbh->prepare($query);
	my $res = $sth->execute();
    }

}

sub updateCategorycode {
    my ( $categorycode, $cardnumber ) = @_;

    my $dbh = C4::Context->dbh;
    my $query = "UPDATE borrowers SET categorycode=? WHERE cardnumber=?";
    my $sth = $dbh->prepare($query);
    my $res = $sth->execute($categorycode, $cardnumber);
}

sub updateCard {
    my ($borrowernumber, $cardnumber) = @_;
    my $query = "UPDATE borrowers SET cardnumber=? WHERE borrowernumber=?";
    my $dbh = C4::Context->dbh;
    my $sth = $dbh->prepare($query);
    my $res = $sth->execute( $cardnumber, $borrowernumber);
}

# $get_borrowers_attr call am123 webservices
sub get_borrowers_attr {
    my @data;
    my $borrowers_category = shift;
    my $ua = LWP::UserAgent->new;
    foreach my $category (@$borrowers_category) {
        if ($category->{"borrowers"}) {
	    print "Récupération des données " . ($category->{'borrower_type'} eq 'pers' ? 'des personnels' : 'des étudiants') . " depuis " . $category->{'univ'} . "\n";
            my $req = HTTP::Request->new(POST => "http://webserv.univ-aix-marseille.fr/koha-ws/lecteurs/$category->{'univ'}/$category->{'borrower_type'}/list.csv");
            $req->content_type('application/x-www-form-urlencoded');
            $req->content("secret=sheldon&idList=" . join(",", @{ $category->{"borrowers"} }));
            my $res = $ua->request($req);
            my $parsed_data = parse_data($res->content, $category->{'univ'}, $category->{'borrower_type'});
	    print scalar(@$parsed_data) . " trouvé(s)\n";
            push @data, $_ foreach @$parsed_data; 
        }       
    }
    return \@data;
}

sub parse_data {
    my ($content, $site, $type) = @_;
    open my $fh, '<', \$content or die "Can't open this flow"; 
    my $csv = Text::CSV->new({ binary => 1, sep_char => '|', eol => $/, quote_char => '"', empty_is_undef => 1 }) or die "Cannot use CSV: ".Text::CSV->error_diag ();

    my $fields = $csv->getline($fh);
    my @borrowers;   
    while (my $row = $csv->getline($fh)) {
        my %data;
        $data{$_} = shift @$row for @$fields;
        $data{"SITE"} = $site;
        $data{"TYPE"} = $type;
        push @borrowers, \%data;
        
    }
    $csv->eof or $csv->error_diag();
    close $fh;
    return \@borrowers;
}

sub data_to_koha {
    my ($data, $new) = @_;
    my $success_update = 0;
    my @errors_update = ();

    print "UPDATING BORROWERS : start update...\n";
    foreach my $fromdata (@$data) {
        
        #load the yaml Config file
        my $configfile = "config/" . lc($fromdata->{"SITE"}) . "_" . $fromdata->{'TYPE'} . ".yaml";
        my $targetdata = transform_data($fromdata, $configfile) or die "no tranformed data"; 

        # Extract extended attributes
        my $patron_attributes = extract_extended_attributes($targetdata) or die "no extended attributes";

        #Add a timestamp attribute in borrower_attributes table. It is used to know if the member must be updated (TIMESTAMP = NULL)
        push @$patron_attributes, {code => "TIMESTAMP", value => C4::Dates->new()->output('iso')};       

        #Get the borrower number
        my ($appligest, $site);
        foreach (@$patron_attributes) {
            $appligest = $_->{"value"} if $_->{"code"} eq "APPLIGEST";
	    $site = $_->{"value"} if $_->{"code"} eq "ETABLISSEM";
        }

        #Get borrowernumber of the current member
        my $borrowernumber;
        unless ( $borrowernumber = getMemberByAppligest($appligest, $site) ) {
            push @errors_update, "Can't get borrowernumber for borrower $appligest";
            next;
        }
        $targetdata->{ 'borrowernumber' } = $borrowernumber;

        $targetdata = delete_useless_fields($targetdata);

	if ($targetdata->{ 'branchcode' } eq '' || $targetdata->{ 'branchcode' } !~ m/^$fromdata->{'SITE'}/) {
	    $targetdata->{ 'branchcode' } = $fromdata->{"SITE"} . 'INC';
	}

        #Save to koha db
        my $success = ModMember(%$targetdata);
        unless ($success) {
            print "UPDATING BORROWERS : Can't update borrower n° " . $targetdata->{'borrowernumber'} . "\n";
            push @errors_update, "The updating of the borrowers (APPLIGEST: $appligest) failed" ;
        } else {
            C4::Members::Attributes::SetBorrowerAttributes( $targetdata->{'borrowernumber'}, $patron_attributes );
            print "UPDATING BORROWERS : Borrower n° " . $targetdata->{'borrowernumber'} . " updated successfully\n";
            $success_update++;
        }
        
    }
    if (@errors_update) {
        my %mail = (
            smtp    => 'smtp.nerim.net',
            To      => 'alex.arnaud@biblibre.com',
            From    => 'alex.arnaud@biblibre.com',
            Subject => 'Borrowers update in koha',
            Message =>  join("\n", @errors_update));
        sendmail(%mail) or print "mail not sent" . $Mail::Sendmail::error; 
    }
    
    print "UPDATING BORROWERS : End update. Success : " . $success_update . ", Failure(s) : " . scalar(@errors_update) . "\n";
}

sub filterhash {
    my ($datafilter, $datahash)=@_;
    my $filterstring= '^'.join ('$|^',@$datafilter).'$';
    my %filtered=map{$_ => $datahash->{$_}} grep(/$filterstring/, keys %$datahash);
    return \%filtered;
}

sub mapvalues {
    my ( $valuemapping, $transformedkey, $value) = @_;
    if ( my $v = $valuemapping->{$transformedkey} ) { 
    my $rv;
        ref $v eq "HASH" and $rv = $v->{$value} and return $rv;
#         warn "no key in transformation for $value";
        # eventuellement
        return $value;
    } else {
#         warn "no transformation key for $value";
        return $value;
    }   
}

sub calcExpiryDate{
    my  ($catcode,$dateenrolled)=@_;
    my @date = split /-/,$dateenrolled;
    return sprintf("%04d-%02d-%02d", $date[0]+1,10,30) if ($catcode eq "L" or $catcode eq "M");
    return sprintf("%04d-%02d-%02d", $date[0]+1,12,31) if ($catcode eq "D");
    return sprintf("%04d-%02d-%02d", $date[0]+10,12,31);
}

sub card_exist{
    my $card = shift;
    my $dbh = C4::Context->dbh;
    my $query = qq{select borrowers.borrowernumber FROM borrowers
                WHERE borrowers.cardnumber=?}; #add after: "WHERE timestamp=NULL" to select newly adding borrowers only. And add a university field. e.g. U1|U2|U3;
    my $sth = $dbh->prepare($query);
    $sth->execute($card);
    my $result = $sth->fetchrow_array;
    return $result;
}

sub card_is_invalid {
    my $carddata = shift;
    my @missinglist;

    my $enddate = $carddata->{ENDDATE};
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    my $today = mktime($sec, $min, $hour, $mday, $mon, $year, $wday = 0, $yday = 0, $isdst = 0);

    push @missinglist, {missing => "Etablissement"} unless $carddata->{ETABLISSEM};
    push @missinglist, {missing => "Composante"} unless $carddata->{COMPOSANTE};
    push @missinglist, {missing => "N° Appligest"} unless $carddata->{APPLIGEST};
    push @missinglist, {missing => "Categorycode"} unless $carddata->{categorycode};
    push @missinglist, {missing => "Branchcode"} unless $carddata->{branchcode};

    if ($carddata->{TYPE} eq 'Etudiant') {
        push @missinglist, {missing => "Code étape"} unless $carddata->{CODEETAPE};
    }

    if ($carddata->{ETAT} eq 'false') {
        return "carte inactive";
    } 

    unless ($enddate > $today) {
        return "carte périmée";
    }
    
    if (@missinglist) {
        return "donnée(s) de carte invalide(s) ou manquante(s) :", \@missinglist;
    }

    return 0; 
}

sub transform_data {
    my ($fromdata, $configfile) = @_;
    #print "fromdata : ".  Data::Dumper::Dumper($fromdata) . "\n";
    my $targetdata;    

    #load the yaml Config file
    my ($map,$valuesmapping,$matchingpoint,$preprocess,$postprocess)= YAML::LoadFile($configfile) or die "unable to load $configfile ";
        
    eval $preprocess if ($preprocess);
    die $@ if $@;

    #transform data
    foreach my $key ( keys %$fromdata ) {
        my @mapkeys=((ref($$map{$key}) eq "ARRAY") ? @{$$map{$key}} : ($$map{$key}));
        foreach my $transformedkey (@mapkeys){
            $transformedkey||=$key;
            my $value=$$fromdata{$key};
            #$$targetdata{$transformedkey} = mapvalues( $valuesmapping, $transformedkey, $value) unless ($$targetdata{$transformedkey}); 
	    $$targetdata{$transformedkey} = mapvalues( $valuesmapping, $transformedkey, $value);
	    #PBM avec le statut sur u3_pers.yaml, donc traitement particulier sans le unless puisque $$targetdata{STATUT} existe déja avec la mauvaise valeur
	    #$$targetdata{$transformedkey} = mapvalues( $valuesmapping, $transformedkey, $value) if $transformedkey eq 'STATUT' && $configfile eq 'config/u3_pers.yaml';
            }
        }
    eval $postprocess if ($postprocess);
    die $@ if $@;
    return $targetdata;
}

# sub delete_useless_fields($member_columns, $member_extended_attributes)
sub delete_useless_fields {
    my $member_columns = shift;

    #Members columns
    my $columnkeys = join("|", C4::Members->columns);
    #my @columnkeys = C4::Members->columns;

    my $filtered_data = { map { /$columnkeys/ ? ( $_ => $member_columns->{$_} ) : () } keys %$member_columns };
    return $filtered_data;
    
}

# sub extract_extended_attributes($data)
sub extract_extended_attributes {
    my $data = shift;
    my @attributes = map $_->{"code"}, C4::Members::AttributeTypes::GetAttributeTypes;

    my $patron_attributes_hash = filterhash(\@attributes,$data);
    my $patron_attributes = [map{{code=>$_,value=>$$patron_attributes_hash{$_}}} keys %$patron_attributes_hash];

    return $patron_attributes;
}

sub insert_borrower {
    #AddMember: cardnumber, surname, firstname, branchcode, categorycode
    #Attributes: COMPOSANTE (=> branchcode), APPLIGEST, ETABLISSEM, CODEETAPE(=> categorycode)
    my $carddata = shift;
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);

    my %borrower;

    #Extended attributes
    my $patron_attributes;
    foreach (qw/COMPOSANTE APPLIGEST ETABLISSEM CODEETAPE/) {
        push @$patron_attributes, {code => $_, value => $carddata->{$_} } unless $_ eq 'CODEETAPE' && $carddata->{categorycode} eq 'P';
    }
    push @$patron_attributes, {code => "TIMESTAMP", value => undef};

    foreach (qw/cardnumber surname firstname categorycode branchcode/) {
        $borrower{$_} = $$carddata{$_};
    }

    $borrower{dateenrolled} ||= C4::Dates->new()->output('iso');
    $borrower{dateexpiry} ||= calcExpiryDate($borrower{categorycode},$borrower{dateenrolled}) if ($borrower{categorycode});

    #On rajoute les 8 zéros au debut de la chaine
    $borrower{cardnumber} =  '00000000' . $borrower{cardnumber};  

    my $borrowernumber = &AddMember(%borrower);
    unless ($borrowernumber) {
        return 0;
    } else {
        C4::Members::Attributes::SetBorrowerAttributes($borrowernumber, $patron_attributes);
        return 1;
    }
   
}

sub category_for {
    my ($step, $etablis, $cardnumber) = @_;

    if ($etablis eq "U1") { # for U1
	my $file = "config/u1_branch_by_step";
        open my $fh,$file or die "$file : $!";
	my $category_map = { map { chomp; my ($key,$value) = split /;/,$_; ( $key => $value ); } <$fh> };

	foreach (keys %$category_map) {
	    return $category_map->{$_} if $step =~ /^$_/i;
	}
	appendtolog("WARN: categorycode par defaut pour la carte n° $cardnumber", "apharp-error-log");
	return "L";
#        if ( $step ~~ do { my $str = join '|', qw/
#            0DA 2L1 2L2 2L3 2LP 3L1 3L2 3L3 3LP 4DI 4DU 4JIGB1 4L1 4L2 4L3 4LB 4LP 5IGC1 5IGC1
#            5IME1 5ISE1 6LP 7DU 7LI 7LP 8L3 A13 A23 A90 A91 A92 A93 A94 A95 C2I CLE IAATC
#            IACAW IAI IAS IDAC1 IDAC2 IDGB1 IDGB2A IDGB2G IDGB2I IDQL1 IDQL2 LA1 LA2 LA3
#        /; qr/^($str)/i } ) { "L" }
#        elsif ( $step ~~ do { my $str = join '|', qw/
#            2AG 2M0 2M1 2MP 2MR 3AG 3M1
#            3MP 3MR 4AG 4JIGB2 4JIGB3 4M1 4MP 4MR 5IGC2 5IGC3 5IGC2 5IGC3 5IME2 5IME3 5ISE2
#            5ISE3 5MP 5MR 7DR 7DS 7M1 7MI 7MP 8M1 8MP A09 A52 A53 FE FS FT MA4 MA6 MA8 UP2
#        /; qr/^($str)/i } ) { "M" }
#        elsif ( $step ~~ do { my $str = join '|', qw/
#            2DO 2HD 2TH 3DO 3HD 3TH
#            4DO 4HD 4TH 5DO AH7 DA
#        /; qr/^($str)/i } ) { "D" }
#	else { "L" }
    } elsif ($etablis eq "U2") { # for U2
	my $file = "config/u2_branch_by_step";
	open my $fh,$file or die "$file : $!";
	my $category_map = { map { chomp; my ($key,$value) = split /;/,$_; ( $key => $value ); } <$fh> };

	if ( my $v = $category_map->{$step} ) { $v }
#	if ( $step ~~ do { my $str = join '|', qw/
#	    ADOMEP ADOMAP ADOMMA ADOME2 ADOME3 ADORU2 ACAOP1 ACAOP2 ACAOP3 ACAOT1 ACAOT2 ACAOT3 ADUTI1 ADUBC1 ADUBJ1
#	    BDUCG BPBANK BPIMEX CDUSS CPSIL DDTCS1 DDTCS2 DDTGI2 DDTGL1 DDTGL2 DDTGP1 DDTGP2 DDTHS1 DDTHS2 DDTIC1
#	    DDTIML DDTIN1 DDTRT1 DDTRT2 DDTTC1 DDTTC2 DP9ACE PD9ATC DP9CDB DPMDB DP9MDE DP9MDL DP9MGC DP9MLO DP9MPA
#	    DP9OGA DP9PII DP9RET DP9SBP DPATC DPATU DPCACE DPCDB DPCMR DPCOGA DPHMT DPMEDB DPMEDE DPMEDL DPMGOC
#	    DPMGOM DPMLO DPMSPA DPPIC DPPII DPPIS DPRET DPRSN DPSBP DPSBP DT9GFC DT9GL2 DT9HS2 DT9IML DT9TC2
#	    DTGAPM DTGASF DTASR DTGEA1 DTGEG1 DTGFI2 DTGGFI DTGRH DUMEA EDUPP1 EPICP EPHAR1 EPHAR2 EPHAR3 FPGDOL
#	    FPGDOM GDOCP2 GDOCD1 GDOCD2 JPIAA KPPMC VDESF1 VDESF2 VDESF3
#	/; qr/^($str)/i } ) { "L" }
#	elsif ( $step ~~ do { my $str = join '|', qw/
#	    ADOME4 ADOME5 ADORU3 ADORU4 ACAOP4 BDUAFI BDUCHP BDURME BDUSCG
#	    BDUSCX BERASM CDUCSI CDUOM1 CDUOM4 DDUGOC DDUGOL EDUMD2 EDUMDO
#	    EPHAR4 EPHUE2 GDOCD3 JIBM1 JIBM2 JIBM3 JIGB1 JIGB2 JIGB3 JIIN3 
#	    JIIRM1 JIIRM2 JIMA1 JIMA2 JIMA3 JIRM3 VDESF4
#	/; qr/^($str)/i } ) { "M" }
	elsif ( $step ~~ do { my $str = join '|', qw/.1.* .2.* .3.*/; qr/^($str)/i } ) { "L"; }
	elsif ( $step ~~ do { my $str = join '|', qw/.4.* .5.*/; qr/^($str)/i } ) { "M"; }        
	elsif ( $step ~~ do { my $str = join '|', qw/.8.* .\D.*/; qr/^($str)/i } ) { "D"; }
	else { 
	    appendtolog("WARN: categorycode par defaut pour la carte n° $cardnumber", "apharp-error-log");
	    return "L"; 
	}
    }
    elsif ($etablis eq "U3") {
	my $file = "config/u3_branch_by_step";
	open my $fh,$file or die "$file : $!";
	my $category_map = { map { chomp; my ($key,$value) = split /;/,$_; ( $key => $value ); } <$fh> };

	if ( my $v = $category_map->{$step} ) { $v }
	else { 
	    appendtolog("WARN: categorycode par defaut pour la carte n° $cardnumber", "apharp-error-log");
	    return "L"; 
	}
    }
        
}

sub appendtolog {
    my ( $message, $logfile ) = @_;

    my $dt   = DateTime->now;
    my $date = $dt->ymd;
    my $time = $dt->hms;
    my $wanted = "$date $time";

    open(WSLOG, ">>log/$logfile") or die "impossible d'ouvrir $logfile : $!";
    print WSLOG "[$wanted]: " . $message ." \n";
    close WSLOG;
}

=head
wget http://search.cpan.org/CPAN/authors/id/G/GA/GAAS/libwww-perl-5.834.tar.gz
perl Makefile.PL --no-programs
make
make test
make install

-----------------------
sudo cpan
install Text::CSV
1.17
=cut
