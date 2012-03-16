




#!/bin/sh

# Once a day, rotate the tmp dir to keep it from growing too large
DATE=`date +%Y-%m-%d`

cd /usr/local/wormbase
mv tmp tmp.${DATE}
mkdir tmp ; chown tharris:wormbase tmp ; chmod 777 tmp
