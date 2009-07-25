package Koha::Database::Main::Result::Issue;
use base qw/DBIx::Class/;

use strict;
use warning;

__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('issues');

# __PACKAGE__->add_columns(qw/ /);
__PACKAGE__->set_primary_key('issueid'); # need this

__PACKAGE__->belongs_to('borrower' => 'Koha::Database::Main::Result::Borrower');
__PACKAGE__->belongs_to('Item' => 'Koha::Database::Main::Result::Item');

1;