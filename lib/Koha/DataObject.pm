package Koha::DataObject;

=head1 NAME

Koha::DataObject - base class for context dependant data retrieval and storage classes

=cut

use strict;
use warnings;
use Carp;

use base qw(Class::Accessor);

=head1 CONSTRUCTOR

=head2  new( $context, $data )

  $data is optional

=cut

sub new {
    my $class  = shift;
# Input params
    my $context = shift or croak "Context not supplied";
    my $data    = shift;

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


