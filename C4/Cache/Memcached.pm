package C4::Cache::Memcached;

use strict;
use warnings;
use Carp;

use Cache::Memcached;

use base qw(C4::Cache);

sub _cache_handle {
    my $class  = shift;
    my $params = shift;

    my @servers = split /,/, $params->{'cache_servers'};

    return Cache::Memcached->new(
        servers   => \@servers,
        namespace => $params->{'namespace'} || 'KOHA',
    );
}

sub set_in_cache {
    my ( $self, $key, $value, $expiry ) = @_;
    croak "No key" unless $key;

    if ( defined $expiry ) {
        return $self->cache->set( $key, $value, $expiry );
    }
    else {
        return $self->cache->set( $key, $value );
    }
}

sub get_from_cache {
    my ( $self, $key ) = @_;
    croak "No key" unless $key;
    return $self->cache->get($key);
}

sub clear_from_cache {
    my ( $self, $key ) = @_;
    croak "No key" unless $key;
    return $self->cache->delete($key);
}

sub flush_all {
    my $self = shift;
    return $self->cache->flush_all;
}

1;
__END__                                                                         
                                                                                  
=head1 NAME                                                                     
                                                                                
  C4::Cache::Memcached - memcached subclass of C4::Cache                
                                                                                  
=cut
