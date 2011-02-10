#!/usr/bin/perl

use strict;
use Socket;
use constant LOGS => '/usr/local/wormbase/logs/access_log*.gz';

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

unless (@ARGV) {
  @ARGV = sort { -A $b <=> -A $a } <${\LOGS}>;
}  

foreach (@ARGV) {
  $_ = "gunzip -c $_ |" if /\.gz$/;
}
                 
my %HOSTS;

# Purge squid logs of unwanted virtual host entries and squid codes
while (<>) {
  next if ($_ =~ /http\:\/\/www\.wormbook\.org/i);
  next if $_ =~ /http\:\/\/stein\.cshl/i;
  my ($who,$rest) = /^(\S+)(.+)/;
  foreach my $purge (@PURGE) {   
    $rest =~ s/$purge\:.*//;     
  }                             
  print "$who$rest\n"; 
  # print $_;
}
