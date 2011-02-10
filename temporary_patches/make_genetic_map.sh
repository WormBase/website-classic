#!/bin/sh
VERSION=$1
ROOT=/usr/local/wormbase/temporary_patches/${VERSION}_patches

mkdir ${ROOT}

# Dump out the genetic map
#echo "Dumping genetic map..."
/usr/local/wormbase/bin/genetic_map/dump_all_genes.pl \
--acedb /usr/local/acedb/elegans_${VERSION} > ${ROOT}/${VERSION}-genetic_map.gff

# load the genetic map into a new database
echo "Loading new genetic map..."
mysql -u root -pkentwashere -e "create database elegans_gmap_${VERSION}"
mysql -u root -pkentwashere -e "grant all privileges on elegans_gmap_${VERSION}.* to todd@localhost"
/usr/bin/bp_fast_load_gff.pl --create --database elegans_gmap_${VERSION} \
--user root --pass kentwashere ${ROOT}/${VERSION}-genetic_map.gff
cd /usr/local/mysql/data
rm elegans_gmap
ln -s elegans_gmap_${VERSION} elegans_gmap
