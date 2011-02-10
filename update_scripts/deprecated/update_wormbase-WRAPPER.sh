#!/bin/sh

# This script fires off the update_wormbase-dev.pl script without having to type the long
# incantation. It should be passed a desired WSXXX version.
#  - Todd

VERSION=$1
CBVERSION=$2

mkdir /usr/local/wormbase/update_scripts/logs/${VERSION}

echo "Updating C. elegans with ${VERSION}..."
update_wormbase-dev.pl -start_new -mirror ${VERSION} \
-status /usr/local/wormbase/update_scripts/logs/${VERSION}/${VERSION}.status \
-config /usr/local/wormbase/update_scripts/update_wormbase-dev.cfg \
-log /usr/local/wormbase/update_scripts/logs/${VERSION}/${VERSION}.log \
-species elegans
echo "Finished updating C. elegans..."

#echo "Updating C. briggsae with ${CBVERSION}..."
#update_wormbase-dev.pl -start_new -release \
#-status /usr/local/wormbase/update_scripts/logs/${VERSION}/${VERSION}.briggsae.status \
#-config /usr/local/wormbase/update_scripts/update_wormbase-dev.cfg \
#-log /usr/local/wormbase/update_scripts/logs/${VERSION}/${VERSION}.briggsae.log \
#-species briggsae
#echo "Finished updating C. briggsae..."
#
#cp /usr/local/wormbase/update_scripts/update_wormbase-dev.cfg2 /usr/local/wormbase/update_scripts/logs/${VERSION}/.
