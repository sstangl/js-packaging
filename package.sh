#!/bin/bash

# hg revision against which the patches are intended to apply.
# Don't forget to update README.
HGREV="441b8aa4bc66"

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
find -name *.pyc -delete
rm -rf .pc
PACKAGEVERSION=17.0.0.rc1

QUILT_PATCHES="$BUILDDIR/patches" quilt push -a
if (( $? )); then echo -failed to apply patches; exit 1; fi

cd js/src
if which autoconf-2.13 > /dev/null; then
	autoconf-2.13
else
	autoconf2.13
fi

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
tar rf ${TARFILE} --transform "s#^#${DIRNAME}/#" README
tar rf ${TARFILE} --transform "s#^#${DIRNAME}/#" INSTALL

gzip -f ${TARFILE}
