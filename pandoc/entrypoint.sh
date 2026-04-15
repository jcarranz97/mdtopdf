#!/bin/bash
set -e

# Pass shell invocations through unchanged so the container can still be
# used for scripting (e.g. bash -c '...').  Everything else is forwarded to
# make, so variables like DOCS_DIR and DOC_ID can be passed directly:
#   docker run ... image DOCS_DIR=/docs DOC_ID=1234 DOC_MAJOR=1 DOC_MINOR=0
case "$1" in
  bash|sh) exec "$@" ;;
  # -B / --always-make forces a rebuild every time, regardless of file
  # timestamps.  This matters when only Make variables change between runs
  # (e.g. a different DOC_MAJOR/DOC_MINOR) because Make otherwise sees the
  # output PDF is newer than the source files and skips the build.
  *)       exec make -B "$@" ;;
esac
