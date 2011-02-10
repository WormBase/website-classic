# An entry in the history table will ONLY be made when the status of the object changes
package DB::History::History;

use strict;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('history');
__PACKAGE__->add_columns(qw/sid oid version date signature notes/);
__PACKAGE__->set_primary_key('sid');
__PACKAGE__->belongs_to(oid => 'DB::History::History');

1;
