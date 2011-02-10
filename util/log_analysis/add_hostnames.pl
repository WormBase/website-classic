#!/usr/bin/perl

use strict;
use Socket;
use constant LOGS => '/usr/local/wormbase/logs/access_log*.gz';

unless (@ARGV) {
  @ARGV = sort { -A $b <=> -A $a } <${\LOGS}>;
}

# PURGE Squid cache codes
my @PURGE = ( qw/TCP_HIT
		 TCP_MISS
		 TCP_REFRESH_HIT
		 TCP_REF_FAIL_HIT
		 TCP_REFRESH_MISS
		 TCP_CLIENT_REFRESH_MISS
		 TCP_IMS_HIT
		 TCP_SWAPFAIL_MISS
		 TCP_NEGATIVE_HIT
		 TCP_MEM_HIT
		 TCP_DENIED
		 TCP_OFFLINE_HIT
		 UDP_HIT
		 UDP_MISS
		 UDP_DENIED
		 UDP_INVALID
		 UDP_MISS_NOFETCH
		 NONE
		 ERR_
		 TCP_CLIENT_REFRESH
		 TCP_SWAPFAIL
		 TCP_SWAPFAIL_MISS.
		 TCP_IMS_MISS
		 UDP_HIT_OBJ
		 UDP_RELOADING/
		);

my %PURGE = map { $_ => 1 } @PURGE;

foreach (@ARGV) {
  $_ = "gunzip -c $_ |" if /\.gz$/;
}

my %HOSTS;

while (<>) {
  chomp;
  my ($who,$rest) = /^(\S+)(.+)/;
  my $hostname = lookup($who);
  foreach my $purge (@PURGE) {
    $rest =~ s/$purge\:.*//;
  }
  print $hostname,$rest,"\n";
}

sub lookup {
  my $ip_addr = shift;

  return $HOSTS{$ip_addr} if exists $HOSTS{$ip_addr};
  my $host;
  eval {
    local $SIG{ALRM} = sub { die "timed out" };
    alarm(2);
    $host = gethostbyaddr(scalar(inet_aton($ip_addr)),AF_INET);
  };
  alarm(0);
  return $HOSTS{$ip_addr}=(lc($host) || $ip_addr);
}
