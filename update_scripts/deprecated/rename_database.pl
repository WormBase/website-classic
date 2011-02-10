#!/usr/bin/perl

use strict;
use File::Path 'rmtree';

use constant MYSQL   => '/usr/local/mysql/var';
use constant RESTART => '/etc/rc.d/init.d/mysqld restart';
$ENV{PATH} = '/bin';
$ENV{IFS}  = '';

# rename database in a more-or-less seamless way
my $oldname = shift;
my $newname = shift;

chdir(MYSQL) or die "Can't chdir: $!";
die "$newname does not exist" unless -d $newname;
if (-d "$newname.bak") {
  rmtree("$newname.bak",0,1);
}
rename($newname,"$newname.bak");
rename($oldname,$newname);
system RESTART;
