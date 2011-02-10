#!/bin/sh
FILE=$1
DSN=$2

#bp_seqfeature_load.pl -d ${DSN} -c -u root -p kentwashere -v ${FILE}

# Bio::DB::GFF
bp_fast_load_gff.pl --create --database ${DSN} --user root --pass kentwashere ${FILE}
