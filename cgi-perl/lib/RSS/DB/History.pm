package DB::History;

use strict;
use base qw/DBIx::Class::Schema/;

__PACKAGE__->load_classes(qw/Objects History/);

1;




