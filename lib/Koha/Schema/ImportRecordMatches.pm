package Koha::Schema::ImportRecordMatches;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("import_record_matches");
__PACKAGE__->add_columns(
  "import_record_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "candidate_match_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "score",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
);
__PACKAGE__->belongs_to(
  "import_record_id",
  "Koha::Schema::ImportRecords",
  { import_record_id => "import_record_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:0ZWrnoABxQJPimBxJq6Oxg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
