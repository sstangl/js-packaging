#!/bin/bash

# hg revision against which the patches are intended to apply.
HGREV="9968e83f2959"

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

PACKAGEVERSION=17-0.0.1

function apply {
	echo +Applying ${1}
	patch -p1 < ${BUILDDIR}/patches/${1}
	if (( $? )); then echo -failed to apply ${1}; exit 1; fi
}

apply bug838915-JS_STANDALONE.patch # approval-mozilla-esr17?
apply bug835551-required-defines.patch # Landed on m-c, needs green try run + landing on esr17
apply bug831552-install-headers.patch # approval-mozilla-esr17?

apply bug809430-add-symbol-versions.patch # r+, needs landing on m-i. Unneeded?

# Bug 812265 requires updating to use JS_STANDALONE.
apply bug812265-bump-JS_VERSION.patch # r+, carrying rebased version, needs landing on esr17
apply bug812265-fix-version.patch # Tag-along patch to JS_VERSION bump.
apply bug812265-REAL_LIBRARY.patch # Unreviewed.
apply bug812265-versioned-MOZ_JS_LIBS.patch # Unreviewed.
apply bug812265-setup-versioning.patch # Needs work. Rebased locally over 831552.
apply bug784262-backport-_TARGET-rule.patch # Landed on m-c; part of 812265 for esr17. Should be part of setup-versioning patch.
apply bug812265-versioned-static.patch #Unreviewed. Should be part of setup-versioning patch.
#apply UNKNOWN-fix-pkgconfig-file.patch # oops this was merged locally into 'setup-versioning'

apply quell-common-warnings.patch # Could be landed, but we can carry it separately.

cd js/src
autoconf-2.13

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
