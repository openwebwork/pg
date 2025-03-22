#!/bin/bash

# Start the R server
R_HOME=/usr/lib/R /usr/lib/R/site-library/Rserve/libs/Rserve --no-save > /dev/null 2>&1

exec "$@"
