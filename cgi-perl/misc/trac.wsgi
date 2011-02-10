import os

os.environ['TRAC_ENV'] = '/usr/local/wormbase/trac'
os.environ['PYTHON_EGG_CACHE'] = '/usr/local/wormbase/trac/eggs'

import trac.web.main
application = trac.web.main.dispatch_request
