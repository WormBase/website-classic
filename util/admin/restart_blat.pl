#!/usr/bin/perl
# check that blat servers are running; if not restart

use strict;
use Time::Format qw(%time);

use lib '/usr/local/wormbase/extlib/lib/perl5/site_perl/5.8.8';

our ($HOST, $PORT, $USERNAME, $PASSWORD);
our $ERRORS = 0;

our $BLAT_SERVER_EXECUTABLE = '/usr/local/blat/bin/gfServer';
our $BLAT_CLIENT_EXECUTABLE = '/usr/local/blat/bin/gfClient';

our $BLAT_ROOT_DIR         = '/usr/local/wormbase/databases/[RELEASE]/blat';

our %BLAT_DBS = ('c_elegans'              => { port => 2007, file_glob => "$BLAT_ROOT_DIR/c_elegans/*.nib" },
                 'c_briggsae'             => { port => 2008, file_glob => "$BLAT_ROOT_DIR/c_briggsae/*.nib" },
                 'c_brenneri'             => { port => 2009, file_glob => "$BLAT_ROOT_DIR/c_brenneri/*.nib" },
                 'c_japonica'             => { port => 2010, file_glob => "$BLAT_ROOT_DIR/c_japonica/*.nib" },
                 'c_remanei'              => { port => 2011, file_glob => "$BLAT_ROOT_DIR/c_remanei/*.nib" },
                 'b_malayi'               => { port => 2012, file_glob => "$BLAT_ROOT_DIR/b_malayi/*.nib" },
                 );

require '/usr/local/wormbase/conf/elegans.pm';

use Ace;
use Proc::Simple;

my $ace = Ace->connect(-host => $HOST,
                       -port => $PORT,
                       -user => $USERNAME,
                       -pass => $PASSWORD,
                       ) || logit("FATAL: Cannot connect to Ace!");

my $version = $ace->status->{database}{version};

logit("FATAL: Cannot determine version!") unless $version;

my $hostname = `hostname`;
chomp $hostname;

##########################################
# $version = 'WS170'; # FOR TESTING ONLY #
##########################################

logit("Determined version: $version (HOSTNAME: $hostname)");

my $pids_ref;

# Step 1) Kill all relevant pids
logit("");
logit("Killing all relevant pids ...");

$pids_ref = get_blat_pids();

foreach my $pid (@$pids_ref) {
    logit("Killing pid ($pid) ...");
    system("kill $pid") and logit("ERROR: Command (kill $pid) failed: $!");
    }

# Step 2) Wait
logit("");
logit("Waiting before proceeding to confirm ...");
sleep 20;

# Step 3) Confirm if all relevant pids are down
logit("");
logit("Confirming all relevant pids are down ...");

$pids_ref = get_blat_pids();

my $pid_string = join(', ', @$pids_ref);

if (@$pids_ref > 0) {
    logit("FATAL: Unable to terminate all blat servers, there are $pid_string running, cannot proceed!");
}    

# Step 4) Restart all
logit("");
logit("(Re)starting ...");

foreach my $db (keys %BLAT_DBS) {
    my $port      = $BLAT_DBS{$db}->{port};
    my $file_glob = $BLAT_DBS{$db}->{file_glob};

    $file_glob =~ s/\[RELEASE\]/$version/g;

    my $start_command = qq[$BLAT_SERVER_EXECUTABLE start localhost $port $file_glob > /dev/null &];
    logit("Starting [Command: $start_command] ...");
    system($start_command) and logit("ERROR: Cannot (re)start blat server [Command: $start_command]: $!");
}

# Step 4) Wait
logit("");
logit("Waiting before proceeding to confirm ...");
sleep 60;


# Step 5) Confirm if all relevant pids are running
logit("");
logit("Confirming whether correct number of servers are running ...");

$pids_ref = get_blat_pids();

my $servers_running = @$pids_ref;
my $needed_servers = keys %BLAT_DBS;



if ($servers_running == $needed_servers) {
    logit("Confirmed number of servers running: $servers_running");
}

else {
    logit("FATAL: $servers_running servers running, instead of $needed_servers, cannot proceed!");
}

# Step 6) Report number of errors and exit
logit("");
logit("[Number of errors: $ERRORS]");
$ERRORS ? exit 1 : exit 0;

# [END]

sub get_blat_pids {
    my @blat_pids;
    my @lines =  `ps x | grep gfServer | grep -v grep`;
    my $ps_x_output = "#"x60 . "\n" . join('', @lines) . "#"x60;
 
    foreach my $line (@lines) {
        chomp $line;
        my ($pid, $tty, $stat, $time, $command) = 
            $line =~ /^\s*(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(.*)/;
    
        logit("FATAL: Cannot parse psx (invalid ps x line)!\n$ps_x_output") unless ($pid && $command);

        push @blat_pids, $pid;
    }
    
    return \@blat_pids;
}

sub logit {
    my ($message) = @_;

    $message =~ s/\n+$//;
    
    $ERRORS++ if $message =~ /^ERROR:/;
    
    my $time_stamp = $time{"dd-Mon-yy hh:mm:ss"};    
    
    print "[$time_stamp] $message\n";

    exit 0 if $message =~ /^FATAL:/;
}    

