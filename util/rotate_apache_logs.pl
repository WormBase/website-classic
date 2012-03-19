#!/usr/bin/perl
#this is appropriate for a typical redhat system
#will need to be modified for others

$HOSTNAME=`hostname`;
chomp $HOSTNAME;

$PIDFILE='/var/run/apache2.pid';
$LOGPATH    = '/usr/local/wormbase/logs/legacy';

$MAXCYCLE   = 7;
$GZIP       = '/usr/bin/gzip';

@LOGNAMES =("access.log","error.log");
%ARCHIVE  =("access.log"=>1,
	    "error.log"=>1);

chdir $LOGPATH;  # Change to the log directory
foreach $filename (@LOGNAMES) {
    system "$GZIP -c $filename.$MAXCYCLE >> $filename.gz" 
        if -e "$filename.$MAXCYCLE" and $ARCHIVE{$filename};
    for (my $s=$MAXCYCLE; $s--; $s >= 0 ) {
        $oldname = $s ? "$filename.$s" : $filename;
        $newname = join(".",$filename,$s+1);
        rename $oldname,$newname if -e $oldname;
    }
}
kill 'HUP',`cat $PIDFILE`;

