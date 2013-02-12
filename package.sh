#!/bin/bash

DIRNAME="js-1.8.8"
REPONAME="mozilla-esr17"
REPODIR="$HOME/dev/${REPONAME}"
BUILDDIR=$(pwd)

cd "$REPODIR"

hg revert -a
hg st -un | xargs rm


PACKAGEVERSION=188-1.0.0
PACKAGEFULLVERSION="${PACKAGEVERSION}~hg"$(date +%Y%m%d)".esr17."$(hg id -i | cut -c -8)

patch -p1 < $BUILDDIR/moz188-libname-changes.patch
patch -p1 < $BUILDDIR/moz188-fix-version.patch
patch -p1 < $BUILDDIR/bug831552-install-headers.patch
patch -p1 < $BUILDDIR/bug835551-required-defines.patch

cd js/src
autoconf-2.13

cd "$REPODIR"
cd ..

tar Jcf $BUILDDIR/js${PACKAGEVERSION}.tar.xz                                  \
  --exclude='.hg'                                                             \
  --exclude='.git'                                                            \
  --exclude="*.orig"                                                          \
  --exclude="*.rej"                                                           \
  --transform s/${REPONAME}/${DIRNAME}/                                       \
  ${REPONAME}/js/jsd                                                          \
  ${REPONAME}/js/public                                                       \
  ${REPONAME}/js/src                                                          \
  ${REPONAME}/mfbt

cd "$BUILDDIR"

