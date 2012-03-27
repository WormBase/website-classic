# This file stores local-defaults for a
# WormBase installation.  Edit the following values
# as appropriate for your installation.

# Host where acedb is running
$HOST = 'localhost';

# Port on which acedb is listening
$PORT  = 2005;

# Acedb username and password
$USERNAME = '';
$PASSWORD = '';

# Location of the mysql databases
$MYSQL_HOST = 'localhost';
$MYSQL_USER = 'nobody';
$MYSQL_PASS = '';

# turn on extra debugging code
$DEBUG = 0;

# we are the master (definitive) database
$MASTER      = 0;       # 0 = false, 1 = true

# Include a brief description of the mirror site here
# (ie Caltech WormBase Mirror)
#$MIRROR      = 'Development Site';
$MIRROR      = '';

# we are a development site
#$DEVELOPMENT = 1;       # 0 = false, 1 = true
$DEVELOPMENT = 0;       # 0 = false, 1 = true

# (Dynamic) page caching -- not to be confused with precaching. Ugh.
$CACHE = '/usr/local/wormbase/tmp/website/cache';

# The following options control the location and
# lifespan of acedb object caching.
#$cacheroot = '/usr/local/wormbase/cache';
#$cacheexpires = '3 weeks';

# The following directives control where WormBase
# should send its Blast and AQL queries, and where the queries
# should be returned.  Normally, this is the name of the localhost
# but may also be on a remote machine.
#$WORMBASE2BLAST = 'http://dev.wormbase.org';
$WORMBASE2BLAST = 'http://localhost';

# where does the BLAST page go for its xrefs?
#$BLAST2WORMBASE = 'http://dev.wormbase.org';
$BLAST2WORMBASE = 'http://localhost';

# Similarly for AQL queries handled by the aql_query page
$WORMBASE2AQL = 'http://localhost';
$AQL2WORMBASE = 'http://localhost';

# And for WQL queries...
$WORMBASE2WQL = 'http://localhost';
$WQL2WORMBASE = 'http://localhost';

# WormMart
$WORMMART_URL = 'http://www.wormbase.org/biomart/martview';

# Google Maps API related
$GMAP_API_KEY = 'ABQIAAAAGB-Wqdj00NegDlW0aNTPQRT0kmb1hGpfTs2MOyy1b828YonADhTYLcGFlWLAmh79UVtQaartAy14gg';
$GEO_MAP_DB   = 'geo_map';
$GEO_MAP_USER = 'www-data';
$GEO_MAP_PASS = '';

1;
