#!/usr/bin/perl
# check that mysql is running and if not restart

use strict;
use DBI;

use constant DAEMON_PATH      => '/etc/rc.d/init.d/mysqld';
use constant APACHCTL_PATH    => '/usr/local/apache/bin/apachectl';
use constant DSN              => 'dbi:mysql:elegans';

# For non-init systems
use constant MYSQL_PATH       => '/usr/local/mysql/bin/mysqld_safe';
use constant MYSQL_PATH_ALT   => '/usr/bin/safe_mysqld';

my $db = DBI->connect(DSN,'nobody');
unless ($db) { # can't connect
  warn scalar(localtime),": can't connect to mysql server, restarting\n";
  if (-e DAEMON_PATH) {
    system DAEMON_PATH,'start';
  } else {
    if (-e MYSQL_PATH_ALT) {
      system(MYSQL_PATH_ALT,'--user=mysql &');
    } else {
      system(MYSQL_PATH,'--user=mysql &');
    }
  }
  system APACHECTL_PATH,'restart';
}
