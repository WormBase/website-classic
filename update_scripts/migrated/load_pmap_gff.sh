#!/bin/sh

VERSION=$1


/usr/local/wormbase/update_scripts/pmap2gff.pl -release ${VERSION} -acedb /usr/local/acedb/elegans_${VERSION} \
    -load elegans_pmap_${VERSION} -live elegans_pmap_${VERSION} -user todd -pass kentwashere \
    -output /usr/local/ftp/pub/wormbase/genomes/elegans/genome_feature_tables/GFF2/elegans_pmap${VERSION}.gff
