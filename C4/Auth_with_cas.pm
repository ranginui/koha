package C4::Auth_with_cas;

# Copyright 2009 BibLibre SARL
#
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

use strict;
use warnings;

use C4::Debug;
use C4::Context;
use Authen::CAS::Client;
use CGI;
use FindBin;


use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $debug);

BEGIN {
	require Exporter;
    $VERSION = 3.07.00.049;	# set the version for version checking
	$debug = $ENV{DEBUG};
	@ISA    = qw(Exporter);
	@EXPORT = qw(check_api_auth_cas checkpw_cas login_cas logout_cas login_cas_url);
}
my $context = C4::Context->new() or die 'C4::Context->new failed';
my $defaultcasserver;
my $casservers;
my $yamlauthfile = "../C4/Auth_cas_servers.yaml";


# If there's a configuration for multiple cas servers, then we get it
if (multipleAuth()) {
    ($defaultcasserver, $casservers) = YAML::LoadFile(qq($FindBin::Bin/$yamlauthfile));
    $defaultcasserver = $defaultcasserver->{'default'};
} else {
# Else, we fall back to casServerUrl syspref
    $defaultcasserver = 'default';
    $casservers = { 'default' => C4::Context->preference('casServerUrl') };
}

# Is there a configuration file for multiple cas servers?
sub multipleAuth {
    return (-e qq($FindBin::Bin/$yamlauthfile));
}

# Returns configured CAS servers' list if multiple authentication is enabled
sub getMultipleAuth {
   return $casservers; 
}

# Logout from CAS
sub logout_cas {
    my ($query) = @_;
    my $uri = C4::Context->preference('OPACBaseURL') . $query->script_name();
    my $casparam = $query->param('cas');
    # FIXME: This should be more generic and handle whatever parameters there might be
    $uri .= "?cas=" . $casparam if (defined $casparam);
    $casparam = $defaultcasserver if (not defined $casparam);
    my $cas = Authen::CAS::Client->new($casservers->{$casparam});
    print $query->redirect( $cas->logout_url($uri));
}

# Login to CAS
sub login_cas {
    my ($query) = @_;
    my $uri = C4::Context->preference('OPACBaseURL') . $query->script_name();
    my $casparam = $query->param('cas');
    # FIXME: This should be more generic and handle whatever parameters there might be
    $uri .= "?cas=" . $casparam if (defined $casparam);
    $casparam = $defaultcasserver if (not defined $casparam);
    my $cas = Authen::CAS::Client->new($casservers->{$casparam});
    print $query->redirect( $cas->login_url($uri));
}

# Returns CAS login URL with callback to the requesting URL
sub login_cas_url {

    my ($query, $key) = @_;
    my $uri = C4::Context->preference('OPACBaseURL') . $query->url( -absolute => 1, -query => 1 );
    my $casparam = $query->param('cas');
    $casparam = $defaultcasserver if (not defined $casparam);
    $casparam = $key if (defined $key);
    my $cas = Authen::CAS::Client->new($casservers->{$casparam});
    return $cas->login_url($uri);
}

# Checks for password correctness
# In our case : is there a ticket, is it valid and does it match one of our users ?
sub checkpw_cas {
    $debug and warn "checkpw_cas";
    my ($dbh, $ticket, $query) = @_;
    my $retnumber;
    my $uri = C4::Context->preference('OPACBaseURL') . $query->script_name();
    my $casparam = $query->param('cas');
    # FIXME: This should be more generic and handle whatever parameters there might be
    $uri .= "?cas=" . $casparam if (defined $casparam);
    $casparam = $defaultcasserver if (not defined $casparam);
    my $cas = Authen::CAS::Client->new($casservers->{$casparam});

    # If we got a ticket
    if ($ticket) {
        $debug and warn "Got ticket : $ticket";

        # We try to validate it
        my $val = $cas->service_validate($uri, $ticket );

        # If it's valid
        if ( $val->is_success() ) {

            my $userid = $val->user();
            $debug and warn "User CAS authenticated as: $userid";

            # Does it match one of our users ?
            my $sth = $dbh->prepare("select cardnumber from borrowers where userid=?");
            $sth->execute($userid);
            if ( $sth->rows ) {
                $retnumber = $sth->fetchrow;
                return ( 1, $retnumber, $userid );
            }
            $sth = $dbh->prepare("select userid from borrowers where cardnumber=?");
            $sth->execute($userid);
            if ( $sth->rows ) {
                $retnumber = $sth->fetchrow;
                return ( 1, $retnumber, $userid );
            }

            # If we reach this point, then the user is a valid CAS user, but not a Koha user
            $debug and warn "User $userid is not a valid Koha user";

        } else {
            $debug and warn "Problem when validating ticket : $ticket";
            $debug and warn "Authen::CAS::Client::Response::Error: " . $val->error() if $val->is_error();
            $debug and warn "Authen::CAS::Client::Response::Failure: " . $val->message() if $val->is_failure();
            $debug and warn Data::Dumper::Dumper($@) if $val->is_error() or $val->is_failure();
            return 0;
        }
    }
    return 0;
}

# Proxy CAS auth
sub check_api_auth_cas {
    $debug and warn "check_api_auth_cas";
    my ($dbh, $PT, $query) = @_;
    my $retnumber;
    my $url = C4::Context->preference('OPACBaseURL') . $query->script_name();

    my $casparam = $query->param('cas');
    $casparam = $defaultcasserver if (not defined $casparam);
    my $cas = Authen::CAS::Client->new($casservers->{$casparam});

    # If we have a Proxy Ticket
    if ($PT) {
        my $r = $cas->proxy_validate( $url, $PT );

        # If the PT is valid
        if ( $r->is_success ) {

            # We've got a username !
            $debug and warn "User authenticated as: ", $r->user, "\n";
            $debug and warn "Proxied through:\n";
            $debug and warn "  $_\n" for $r->proxies;

            my $userid = $r->user;

            # Does it match one of our users ?
            my $sth = $dbh->prepare("select cardnumber from borrowers where userid=?");
            $sth->execute($userid);
            if ( $sth->rows ) {
                $retnumber = $sth->fetchrow;
                return ( 1, $retnumber, $userid );
            }
            $sth = $dbh->prepare("select userid from borrowers where cardnumber=?");
            return $r->user;
            $sth->execute($userid);
            if ( $sth->rows ) {
                $retnumber = $sth->fetchrow;
                return ( 1, $retnumber, $userid );
            }

            # If we reach this point, then the user is a valid CAS user, but not a Koha user
            $debug and warn "User $userid is not a valid Koha user";

        } else {
            $debug and warn "Proxy Ticket authentication failed";
            return 0;
        }
    }
    return 0;
}


1;
__END__

=head1 NAME

C4::Auth - Authenticates Koha users

=head1 SYNOPSIS

  use C4::Auth_with_cas;

=cut

=head1 SEE ALSO

CGI(3)

Authen::CAS::Client

=cut
