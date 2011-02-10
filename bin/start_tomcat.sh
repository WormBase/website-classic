#!/bin/sh

PATH=/bin:/usr/bin:/usr/local/bin:/usr/local/java/bin:/usr/X11/bin

TOMCAT_HOME=/usr/local/apache/jakarta-tomcat
TOMCAT_LOG=/usr/local/wormbase/logs/tomcat.log
export TOMCAT_HOME
XVFB=/usr/X11/bin/Xvfb
FONTPATH="-fp /usr/X11R6/lib/X11/fonts/misc/,/usr/X11R6/lib/X11/fonts/Speedo/,/usr/X11R6/lib/X11/fonts/Type1/"

if [ -x $TOMCAT_HOME/bin/startup.sh -a -x $XVFB ]; then
    Xvfb -nolisten tcp :1 -screen 0 800x600x8 $FONTPATH >/var/log/Xvfb-errors 2>&1 &
    sleep 1;
    DISPLAY=:1
    export DISPLAY
    cd $TOMCAT_HOME/bin
    if [ `whoami` == "root" ]; then
        touch $TOMCAT_LOG
        chown nobody $TOMCAT_LOG
	sudo -u nobody $TOMCAT_HOME/bin/startup.sh >>/usr/local/wormbase/logs/tomcat.log 2>&1
    else
	$TOMCAT_HOME/bin/startup.sh >>$TOMCAT_HOME/logs/tomcat.out
    fi
else
    echo "Couldn't find tomcat and/or Xvfb"
fi
