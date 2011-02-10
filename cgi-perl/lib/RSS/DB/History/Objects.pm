# The signature column here is a time-saver; use it to check
# the current md5 for any object
package DB::History::Objects;
use strict;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('objects');
__PACKAGE__->add_columns(qw/oid name class last_modification_date ace_version signature/);
__PACKAGE__->set_primary_key('oid');
__PACKAGE__->has_many(signatures => 'DB::History::History',
		     { 'foreign.oid' => 'self.oid' });

1;
