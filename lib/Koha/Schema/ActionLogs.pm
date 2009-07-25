package Koha::Schema::ActionLogs;

# Copyright 2009 Chris Cormack <chrisc@catalyst.net.nz>                                                                                                                   
#                                                                                                                                                                         
# This file is part of Koha.                                                                                                                                              
#                                                                                                                                                                         
# Koha is free software; you can redistribute it and/or modify it under the                                                                                               
# terms of the GNU General Public License as published by the Free Software                                                                                               
# Foundation; either version 3 of the License, or (at your option) any later                                                                                              
# version.                                                                                                                                                                
#                                                                                                                                                                         
# Koha is distributed in the hope that it will be useful, but WITHOUT ANY                                                                                                 
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR                                                                                           
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.                                                                                             
#                                                                                                                                                                         
# You should have received a copy of the GNU General Public License along with                                                                                            
# Koha; If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("action_logs");
__PACKAGE__->add_columns(
  "action_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "timestamp",
  {
    data_type => "TIMESTAMP",
    default_value => "CURRENT_TIMESTAMP",
    is_nullable => 0,
    size => 14,
  },
  "user",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "module",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "action",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "object",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
  "info",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
);
__PACKAGE__->set_primary_key("action_id");


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-25 19:16:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Isb3MGkmSkB5Axa6n+G9Ng


# You can replace this text with custom content, and it will be preserved on regeneration
1;
