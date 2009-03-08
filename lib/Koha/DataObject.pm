package Koha::DataObject;

=head1 NAME

Koha::DataObject - base class for context dependant data retrieval and storage classes

=cut

use strict;
use warnings;
use Carp;

use base qw(Class::Accessor);

use constant CACHE_TTL            => undef;
use constant CACHE_POLICY_NEVER   => 'CACHE_NEVER';
use constant CACHE_POLICY_CONTEXT => 'CACHE_CONTEXT_DEPENDANT';
use constant CACHE_POLICY_ALWAYS  => 'CACHE_ALWAYS';
use constant CACHE_POLICY         => CACHE_POLICY_CONTEXT;

=head1 CONSTRUCTOR

=head2  new( $context, $data )

  $data is optional

=cut

sub new {
    my $class = shift;

    # Input params
    my $context = shift or croak "Context not supplied in new";
    my $data = shift;

    my $self = { CONTEXT => $context };
    bless $self, $class;

    $self->set_object_data($data) if $data;

    return $self;
}

=head1 C4::Context PROXY METHODS                                                                                                           
                                                                                                                                               
=head2  get_context() - Returns context object                                                                                                 
                                                                                                                                               
=cut                                                                                                                                           

sub get_context {
    my $self = shift;
    return $self->{CONTEXT};
}

sub get_object_data {
    my $self = shift;
    return $self->{DATA};
}

sub set_object_data {
    my $self = shift;
    $self->{DATA} = shift;
}

sub new_by_primary_key {
    my $class = shift;

    # Input params
    my $context = shift || croak "Context not supplied";

    my $self = new( $class, $context ) or return;

    my $data =
      $self->get_data( $self->CACHE_POLICY, $class, $class->CACHE_TTL,
        '_load_data', @_ )
      or return;
    $self->set_object_data($data);

    return $self;
}

sub get_data {
    my $self        = shift;
    my $policy      = shift or croak "Cache policy not specified";
    my $key_prefix  = shift;
    my $ttl         = shift;
    my $db_load_sub = shift or croak "DB load sub name not specified";

    return ref($db_load_sub) ? $db_load_sub->(@_) : $self->$db_load_sub(@_)
      if $policy eq CACHE_POLICY_NEVER;

    my $get_method =
        $policy eq CACHE_POLICY_CONTEXT ? 'get_data_context_dependant'
      : $policy eq CACHE_POLICY_ALWAYS  ? 'get_data_cached'
      :   die( "Unknown cache policy " . $policy );

    return $self->$get_method( $key_prefix, $ttl, $db_load_sub, @_ );
}

sub _load_data {
    my $self = shift;

    $self->clear_error;
    my $log = $self->log;
    my $dbh = $self->dbh;
    my $data;
    eval {
        $data = $dbh->selectrow_hashref( $self->QUERY, undef, @_ )
          or $log->info( "Cannot load $self from "
              . $self->QUERY . "; "
              . join( "\n", @_ )
              . ";" ), return;
    };
    if ($@) {
        $log->info( "Cannot load $self from "
              . $self->QUERY . "; "
              . join( "\n", @_ )
              . ";" );
        return;
    }

    return $data;
}

sub get_data_cached {
    my $self       = shift;
    my $key_prefix = shift;
    my $ttl        = shift;    # if 0 store for ever
    my $method = shift or croak "Data load method not specified";

    my $context = $self->get_context;

    my $data = $self->get_from_cache( $key_prefix, @_ );
    return $data if $data;

    $data = ref($method) ? $method->(@_) : $self->$method(@_)
      or return;
    $self->store_in_cache( $key_prefix, $ttl, $data, @_ );
    return $data;
}

sub get_data_context_dependant {
    my $self       = shift;
    my $key_prefix = shift;
    my $ttl        = shift;
    my $method     = shift or croak "Data load method not specified";

    my $context = $self->get_context;

    return $self->get_data_cached( $key_prefix, $ttl, $method, @_ )
      if $context->cache_objects;

    return ref($method) ? $method->(@_) : $self->$method(@_);
}

sub get_from_cache {
    my $self = shift;
    my $key_prefix = shift || ref $self;

    my $log   = $self->log;
    my $cache = $self->cache;

    my $key = $self->make_cache_key( $key_prefix, @_ );

    my $data = $cache->get_from_cache($key)
      or $log->info("$key not in cache"),
      return;

    $log->debug("Got $key from cache");
    return $data;
}

1;
