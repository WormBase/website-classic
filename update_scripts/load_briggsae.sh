#!/bin/sh

VERSION=$1

#process_briggsae_gff.pl ${VERSION}
briggsae2gffdb.pl --release ${VERSION} --user root --pass kentwashere
