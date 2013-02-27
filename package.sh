#!/bin/bash

# hg revision against which the patches are intended to apply.
HGREV="323e068142c4"

DIRNAME="mozjs17"
REPODIR="$HOME/dev/mozilla-esr17"
BUILDDIR=$(pwd)


cd "$REPODIR"

CURHG=`hg log -r tip | head -n 1 | cut -d ' ' -f 4 | cut -d ':' -f 2`
if [ "${CURHG}" != "${HGREV}" ]; then
	echo "-repository at unexpected revision (got ${CURHG}, expected ${HGREV})."
	exit 1
fi

hg revert -a
hg st -un | xargs rm
rm -rf .pc
PACKAGEVERSION=17-1.0.0.rc0

QUILT_PATCHES="$BUILDDIR/patches" quilt push -a
if (( $? )); then echo -failed to apply patches; exit 1; fi

cd js/src
[ autoconf-2.13 ] || autoconf2.13

cd "$REPODIR"

# Include files from mozilla repository.
TARFILE="${BUILDDIR}/mozjs${PACKAGEVERSION}.tar"
tar cf ${TARFILE}                                                             \
  --exclude-vcs                                                               \
  --exclude="*.orig"                                                          \
  --exclude="*.rej"                                                           \
  --transform "s#^#${DIRNAME}/#"                                              \
  js/jsd                                                                      \
  js/public                                                                   \
  js/src                                                                      \
  mfbt

cd "$BUILDDIR"

tar rf ${TARFILE} --transform "s#^#${DIRNAME}/#" patches
tar rf ${TARFILE} --transform "s#^#${DIRNAME}/#" LICENSE

gzip -f ${TARFILE}
