NOTE: You do not need to follow these directions to install wormbase.
These are developers' notes.

This directory contains the Java source files for the LocusDisplay servlet in
Tomcat.

For use:
1. You need jadex.jar, which is the same as one used in the LocusDisplay
applet. jadex.jar should be put into $TOMCAT/lib directory. (Here, $TOMCAT is
the directory for jakarta-tomcat, which is ~www/jakarta-tomcat/ under
wormbase).
2. After compied, two model classes, ServletDisplayModel.class and
LocusDisplayModel.class, should be in $TOMCAT/classes. If you cannot find
this directory, create it.
3. Create a web applicaton in $TOMCAT/webapps with name mapview. The structure
of mapview should be the same as exmples. Actually, just copy examples and
then change it for mapview.
