#!/bin/sh
VERSION=$1
ROOT=/usr/local/wormbase/temporary_patches/${VERSION}_patches
EXTERNAL_DATA=/usr/local/wormbase/temporary_patches/external_data

# Current value-added features at CSHL
# motifs, genetic map, genetic intervals on the physical map

mkdir ${ROOT}

# Let's make sure all subsequent paths are correct
cd /usr/local/wormbase/temporary_patches

## place protein motifs onto the Genome Browser
echo "Dumping motifs..."
motifs/translated_to_genome-via_gene.pl \
--filter --acedb \
/usr/local/acedb/elegans_${VERSION} > ${ROOT}/${VERSION}.motifs.gff

# Place genetic map confidence intervals on the genome
echo "Dumping genetic intervals..."
gmap_to_pmap/interpolate_gmap_to_pmap.pl \
--acedb /usr/local/acedb/elegans_${VERSION} \
  > ${ROOT}/${VERSION}.gmap-to-pmap.gff

## Dump out the genetic map
echo "Dumping genetic map..."
/usr/local/wormbase/bin/genetic_map/dump_all_genes.pl \
--acedb /usr/local/acedb/elegans_${VERSION} > ${ROOT}/${VERSION}-genetic_map.gff

# load the genetic map into a new database
echo "Loading new genetic map..."
mysql -u root -pkentwashere -e "create database elegans_gmap_${VERSION}"
mysql -u root -pkentwashere -e "grant all privileges on elegans_gmap_${VERSION}.* to todd@localhost"
/usr/bin/bp_fast_load_gff.pl --create --database elegans_gmap_${VERSION} --user root --pass kentwashere 
${ROOT}/${VERSION}-genetic_map.gff

cd /usr/local/mysql/data
rm elegans_gmap
ln -s elegans_gmap_${VERSION} elegans_gmap

#echo "Loading motifs and genetic intervals..."
bp_load_gff.pl --dsn elegans_${VERSION} --user root --pass kentwashere \
  ${ROOT}/${VERSION}.motifs.gff ${ROOT}/${VERSION}.gmap-to-pmap.gff

