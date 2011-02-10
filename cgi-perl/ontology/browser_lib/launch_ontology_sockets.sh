#!/bin/bash

# This shell script launches socket servers that support 
# browsing of the various ontologies at WormBase

# Usage:
# launch_ontolgy_sockets.sh /path/to/obo/dir /path/to/socket/dir WSVersion

BINDIR=/usr/local/wormbase/cgi-perl/ontology/browser_lib
SOCKET=/usr/local/wormbase/sockets
WSVERS=$1
DBDIR=/usr/local/wormbase/databases/${WSVER}/ontology


# GO
sudo -u nobody ${BINDIR}/browser.initd -o ${DBDIR}/gene_ontology.${WSVERS}.obo \
                        -a ${DBDIR}/${WSVERS}/gene_association.${WSVERS}.wb.ce \
                        -t go \
			-v ${WSVERS} &

# AO
sudo -u nobody ${BINDIR}/browser.initd -o ${DBDIR}/anatomy_ontology.${WSVERS}.obo \
                        -a ${DBDIR}/${WSVERS}/anatomy_association.${WSVERS}.wb \
                        -t ao \
			-v ${WSVERS}


# PO
sudo -u nobody ${BINDIR}/browser.initd -o ${DBDIR}/phenotype_ontology.${WSVERS}.obo \
                        -a ${DBDIR}/${WSVERS}/phenotype_association.${WSVERS}.wb \
                        -t po \
			-v ${WSVERS}

