#!/bin/bash

DIRNAME="js-1.8.8"
REPONAME="mozilla-esr17"
REPODIR="$HOME/dev/${REPONAME}"
BUILDDIR=$(pwd)


cd "$REPODIR"

hg revert -a
hg st -un | xargs rm


PACKAGEVERSION=188-0.0.1
PACKAGEFULLVERSION="${PACKAGEVERSION}~hg"$(date +%Y%m%d)".esr17."$(hg id -i | cut -c -8)

patch -p1 < $BUILDDIR/patches/moz188-libname-changes.patch
patch -p1 < $BUILDDIR/patches/moz188-fix-version.patch
patch -p1 < $BUILDDIR/patches/bug831552-install-headers.patch
patch -p1 < $BUILDDIR/patches/bug835551-required-defines.patch
patch -p1 < $BUILDDIR/patches/quell-common-warnings.patch

cd js/src
autoconf-2.13

cd "$REPODIR"
cd ..

# Include files from mozilla repository.
TARFILE="${BUILDDIR}/js${PACKAGEVERSION}.tar"
tar cf ${TARFILE}                                                             \
  --exclude-vcs                                                               \
  --exclude="*.orig"                                                          \
  --exclude="*.rej"                                                           \
  --transform s/${REPONAME}/${DIRNAME}/                                       \
  ${REPONAME}/js/jsd                                                          \
  ${REPONAME}/js/public                                                       \
  ${REPONAME}/js/src                                                          \
  ${REPONAME}/mfbt

cd "$BUILDDIR"

tar rf ${TARFILE} --transform "s#^#${DIRNAME}/#" patches
gzip ${TARFILE}
