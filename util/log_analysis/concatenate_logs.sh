#!/bin/sh

# A simple shell script to concatenate logs for each release
# Should be run manually on the live site

RELEASE=$1
YEAR=`date +%Y`

if [ ${RELEASE} ]
then 
  echo "Concatenating logs for ${RELEASE}"
else 
 echo "Usage: concatenate_logs.sh WSXXX (where WSXXX is the current live release)"
 exit 0;
fi
###################################
####### ORIGIN SERVER LOGS ########
###################################
# Move current logs into the archive so that I can work with them
# These are now direct requests to the origin httpd
# We will actually use the squid logs for our analysis
cd /usr/local/wormbase/logs
mv access_log* archive/raw/.
mv error_log* archive/raw/.
cd /usr/local/wormbase/logs/archive/raw

## Access logs (need to move access_log so gzipped archive doesn't obliterate it)
mv access_log access_log.0
gunzip access_log.gz
mv access_log access_log.8
cat access_log.8 access_log.7 access_log.6 access_log.5 access_log.4 access_log.3 access_log.2 \
   access_log.1 access_log.0 > access_log.${RELEASE}.httpd
gzip access_log.${RELEASE}.httpd

# Delete the old logs
rm -rf access_log.0 access_log.1 access_log.2 access_log.3 access_log.4 access_log.5 \
       access_log.6 access_log.7 access_log.8           


##################################
########## SQUID LOGS ############
##################################
# Concatenate the squid logs which truly reflect access stats
# Fetch the current squid logs from fe.wormbase.org
cd /usr/local/wormbase/logs
scp -r fe.wormbase.org:/usr/local/squid/logs squid

sudo chown todd squid/access_log*
cp squid/access_log* archive/raw/.
sudo rm -rf squid

cd /usr/local/wormbase/logs/archive/raw
mv access_log access_log.0
gunzip access_log.gz
mv access_log access_log.8
cat access_log.8 access_log.7 access_log.6 access_log.5 access_log.4 access_log.3 access_log.2 \
   access_log.1 access_log.0 > access_log.${RELEASE}.all_vhosts

/usr/local/wormbase/util/log_analysis/purge_squid_logs.pl access_log.${RELEASE}.all_vhosts > access_log.${RELEASE}

# Compress the logs
gzip access_log.${RELEASE}
gzip access_log.${RELEASE}.all_vhosts

# Concatenate these to the cumulative log
cat access_log.${RELEASE}.gz >> access_log.${YEAR}.cumulative.gz

# Delete the old logs
rm -rf access_log.0 access_log.1 access_log.2 access_log.3 access_log.4 access_log.5 \
       access_log.6 access_log.7 access_log.8  

################################
########## Error logs ##########
################################
cd /usr/local/wormbase/logs/archive/raw
mv error_log error_log.0
gunzip error_log.gz
mv error_log error_log.8
cat error_log.8 error_log.7 error_log.6 error_log.5 error_log.4 error_log.3 error_log.2 \
    error_log.1 error_log.0 > error_log.${RELEASE}
gzip error_log.${RELEASE}

rm -rf error_log.8 error_log.7 error_log.6 error_log.5 error_log.4 error_log.3 error_log.2 \
       error_log.1 error_log.0
