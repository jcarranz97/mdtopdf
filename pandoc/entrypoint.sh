#!/bin/bash
set -e

# Pass shell invocations through unchanged so the container can still be
# used for scripting (e.g. bash -c '...').  Everything else is forwarded to
# make, so variables like DOCS_DIR and DOC_ID can be passed directly:
#   docker run ... image DOCS_DIR=/docs DOC_ID=1234 DOC_MAJOR=1 DOC_MINOR=0
case "$1" in
  bash|sh) exec "$@" ;;
  *)       exec make "$@" ;;
esac
