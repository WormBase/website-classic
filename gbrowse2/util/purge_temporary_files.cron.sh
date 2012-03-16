#!/bin/bash

# GBrowse1
cd /usr/local/wormbase/gbrowse1/tmp
find . -type f -atime +4 -print -exec rm -rf {} \;

# GBrowse2
cd /usr/local/wormbase/gbrowse2/tmp
find . -type f -atime +4 -print -exec rm -rf {} \;

