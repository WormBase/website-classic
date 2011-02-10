#!/bin/sh

# Run this script to unpack downloaded directories
# It needs to be run as sudo in order to correct permissions

# eg.unpack.sh WS126 /home/todd/tarballs/WS126 /usr/local/mysql/data

VERSION=$1
TAR_PATH=$2
MYSQL_PATH=$3

# Acedb
echo "Unpacking Acedb..."
cd /usr/local/acedb
tar -xzf ${TAR_PATH}/elegans_${VERSION}.ace.tgz
touch /usr/local/acedb/elegans_${VERSION}/database/log.wrm
touch /usr/local/acedb/elegans_${VERSION}/database/serverlog.wrm
chmod 666 /usr/local/acedb/elegans_${VERSION}/database/serverlog.wrm
chmod 666 /usr/local/acedb/elegans_${VERSION}/database/log.wrm
chown -R acedb /usr/local/acedb/elegans_${VERSION}
chgrp -R acedb /usr/local/acedb/elegans_${VERSION}
rm elegans
ln -s elegans_${VERSION} elegans


# elegans GFF
echo "Unpacking C. elegans GFF..."
cd ${MYSQL_PATH}
rm -rf elegans.bak
rm -rf elegans_pmap.bak
mv elegans elegans.bak
mv elegans_pmap elegans_pmap.bak
tar -xzf ${TAR_PATH}/elegans_${VERSION}.gff.tgz
chown -R mysql elegans
chgrp -R mysql elegans
chown -R mysql elegans_pmap
chgrp -R mysql elegans_pmap
exit

# Briggsae GFF
echo "Unpacking C. briggsae GFF..."
cd ${MYSQL_PATH}
rm -rf briggsae.bak
mv briggsae briggsae.bak
tar -xzf ${TAR_PATH}/briggsae_${VERSION}.gff.tgz
chown -R mysql briggsae
chgrp -R mysql briggsae

# Blast
echo "Unpacking BLAST and BLAT databases..."
cd /usr/local/wormbase/blast
tar -xzf ${TAR_PATH}/blast.${VERSION}.tgz
rm -rf /usr/local/wormbase/blat/blat.previous
mkdir /usr/local/wormbase/blat/blat.previous
mv /usr/local/wormbase/blat/* /usr/local/wormbase/blat/blat.previous/.
mv blat/* /usr/local/wormbase/blat/.
# Update the symlink
rm -rf blast
ln -s blast_${VERSION} blast
