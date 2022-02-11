#!/usr/bin/env bash

set -e  # Exit on errors

# Initialization phase in startup.sh is complete
# Need to do "|| exit 1" here since "set -e" apparently does not care about tests.
[[ -f ${HTTPD_PREFIX}/logs/httpd.pid ]] || exit 1
