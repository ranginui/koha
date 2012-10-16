#!/usr/bin/perl

# You need to make sure your mappings are correct before trying this
# This will update all borrowers from ldap
# It wont create new, or delete any

use Modern::Perl;

use C4::Context;
use C4::Auth_with_ldap qw(search_method ldap_entry_2_hash);

use Net::LDAP;
use Net::LDAP::Filter;
use Getopt::Long;
use Pod::Usage;

my $matcher;
my $help;
my $man;

GetOptions(
    'help|?' => \$help,
    'man'    => \$man,
    'm'      => \$matcher
) or pod2usage(2);
pod2usage(1) if $help;
pod2usage( -verbose => 2 ) if $man;

my $context = C4::Context->new();

# set up
my $ldap = C4::Context->config("ldapserver")
  or die 'No "ldapserver" in server hash from KOHA_CONF: ' . $ENV{KOHA_CONF};
my $prefhost = $ldap->{hostname} or die ldapserver_error('hostname');
my $base     = $ldap->{base}     or die ldapserver_error('base');
my $ldapname = $ldap->{user};
my $ldappassword = $ldap->{pass};
my %mapping      = %{ $ldap->{mapping} };
my @mapkeys      = keys %mapping;

my $ldapserver = Net::LDAP->new($prefhost);

my $dbh = $context->dbh();
my $sth = $dbh->prepare("SELECT $matcher,borrowernumber FROM borrowers");

$sth->execute();

while ( my $borrower = $sth->fetchrow_hashref() ) {
    my $userid = $borrower->{$matcher};

    # $userid fetch from the db

    if ( $ldap->{'auth_by_bind'} ) {

        # auth by bind
        my $principal_name = $ldap->{'principal_name'};
        if ( $principal_name && $principal_name =~ /\%/ ) {

            # if the user is just a userid add the rest
            $principal_name = sprintf( $principal_name, $userid );
        }
        else {

            # just use the full userid as principal_name
            $principal_name = $userid;
        }
        my $result =
          $ldapserver->bind( $principal_name, password => $password );

    }
    else {

        # auth by username/password or anonymously
        my $result;
        if ( $ldapname && $ldappassword ) {

            # not anonymous;
            $result = $ldapserver->bind( $ldapname, password => $password );
        }
        else {

            # anonymous
            $result = $ldapserver->bind();
        }
    }
    if ( $result->code ) {
        warn "Can not login to ldap";
        next;
    }

    # we made it this far, find the user in ldap
    my $search = search_method( $ldapserver, $userid );
    my $userldapentry = $search->shift_entry;

    my $borrowernumber = $borrower->{'borrowernumber'};
    my %ldapborrower   = ldap_entry_2_hash( $userldapentry, $userid );
    my $cardnumber2    = update_borrower( $borrowernumber, \%ldapborrower );
}

sub update_borrower {
    my ( $borrowernumber, $borrower ) = @_;

    my $query =
        "UPDATE  borrowers\nSET     "
      . join( ',', map { "$_=?" } @keys )
      . "\nWHERE   borrowernumber=? ";
    my $sth = $dbh->prepare($query);
    $sth->execute( ( ( map { $borrower->{$_} } @keys ), $borrowerid ) );
}

=head1 NAME

update_from_ldap.pl - update borrowers information from ldap 

=head1 SYNOPSIS

update_from_ldap.pl -m <column_to_match_on>

 Options:
   -h --help           brief help message
   --man               full documentiontation
   -m      <column>    the column in the borrowers table to match to what userid is mapped to in ldap config

=head1 OPTIONS


=cut
