#!/usr/bin/perl

# This script analyzes a subset of the wormbase error and access logs
# for a given release as a way of creating some basic performance
# benchmarks

use strict;
my $RELEASE = shift;

# 1. Backup all the old logs
my $command=<<END;
mkdir /usr/local/wormbase/logs/$RELEASE-logs
mv /usr/local/wormbase/logs/error_log* /usr/local/wormbase/logs/$RELEASE-logs
mv /usr/local/wormbase/logs/error_log* /usr/local/wormbase/logs/$RELEASE-logs

# Restart the server to generate new logs
sudo /usr/local/apache/bin/apachectl restart
END;

my $result = system($command);


# 2. Calculate the most popular genes (and how they were accessed)




# 3. Calculate and plot the most active pages


# 4. Calculate and plot the accessors


# 5. Plot access statistics versus time



# 6. Calculate statistics on errors (like access/error ratio)
