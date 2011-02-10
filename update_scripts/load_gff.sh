#!/bin/sh

# A wrapper around the ace2gffdb.pl (and hence process_gff.pl and bulk_load_gff.pl) script

# Usage: load_gff.sh WSXXX

VERSION=$1

/usr/local/wormbase/update_scripts/ace2gffdb.pl -release ${VERSION} \
-acedb /usr/local/acedb/elegans_${VERSION} \
-fasta /usr/local/ftp/pub/wormbase/acedb/${VERSION}/CHROMOSOMES \
-gff /usr/local/ftp/pub/wormbase/acedb/${VERSION}/CHROMOSOMES \
-load elegans_${VERSION} -live elegans_${VERSION} -user root -pass kentwashere \
-output /usr/local/ftp/pub/wormbase/genomes/elegans/genome_feature_tables/GFF2/elegans${VERSION}.gff \
-dna_output /usr/local/ftp/pub/wormbase/genomes/elegans/sequences/dna/elegans.${VERSION}.dna.fa \
&>  /usr/local/wormbase/update_scripts/logs/rebuilding_gff_for_${VERSION}.log


#/usr/local/wormbase/update_scripts/pmap2gff.pl -release ${VERSION} \
#-acedb /usr/local/acedb/elegans_${VERSION} \
#-load elegans_pmap_${VERSION} -live elegans_pmap_${VERSION} -user root -pass kentwashere \
#-output /usr/local/ftp/pub/wormbase/genomes/elegans/genome_feature_tables/GFF2/elegans_pmap${VERSION}.gff \
#&>  /usr/local/wormbase/update_scripts/logs/rebuilding_pmap_gff_for_${VERSION}.log

#/usr/local/wormbase/update_scripts/ace2gffdb.pl -release ${VERSION} \
#-acedb /usr/local/acedb/elegans_${VERSION} \
#-fasta /usr/local/ftp/pub/wormbase/acedb/${VERSION}/CHROMOSOMES \
#-gff /usr/local/ftp/pub/wormbase/acedb/${VERSION}/CHROMOSOMES \
#-dna_output /usr/local/ftp/pub/wormbase/genomes/elegans/sequences/dna/elegans${VERSION}.gff
#-load elegans_load -live elegans --user root --pass kentwashere
