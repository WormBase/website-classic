#!/bin/bash

GFF3=$1

bp_seqfeature_load.pl --dsn elegans_WS175_gff3  --create --user root --password kentwashere ${GFF3}
