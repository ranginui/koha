package Koha::Database::Main::Result::Borrower;

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('borrowers');

# __PACKAGE__->add_columns(qw/  /);
__PACKAGE__->set_primary_key('borrowernumber');
__PACKAGE__->has_many('issues' => 'Koha::Database::Main::Result::Issue');

1;