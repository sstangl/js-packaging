#!/bin/bash

DIRNAME="mozjs17"
REPONAME="mozilla-esr17"
REPODIR="$HOME/dev/${REPONAME}"
BUILDDIR=$(pwd)


cd "$REPODIR"

hg revert -a
hg st -un | xargs rm

PACKAGEVERSION=17-0.0.1
PACKAGEFULLVERSION="${PACKAGEVERSION}~hg"$(date +%Y%m%d)".esr17."$(hg id -i | cut -c -8)

function apply {
	echo +Applying ${1}
	patch -p1 < ${BUILDDIR}/patches/${1}
	if (( $? )); then echo -failed to apply ${1}; exit 1; fi
}

apply bug838915-JS_STANDALONE.patch # Landed on m-c, might need landing on esr17
apply bug835551-required-defines.patch # Landed on m-i, needs landing on esr17
apply bug831552-install-headers.patch # Landed on m-i, needs landing on esr17

apply bug809430-add-symbol-versions.patch # r+, needs landing on m-i. Unneeded?

apply bug812265-bump-JS_VERSION.patch # r+, carrying rebased version, needs landing on esr17
apply bug812265-fix-version.patch # Tag-along patch to JS_VERSION bump.
apply bug812265-REAL_LIBRARY.patch # Unreviewed.
apply bug812265-versioned-MOZ_JS_LIBS.patch # Unreviewed.
apply bug812265-setup-versioning.patch # Needs work. Rebased locally over 831552.
apply bug784262-backport-_TARGET-rule.patch # Landed on m-c; part of 812265 for esr17. Should be part of setup-versioning patch.

#apply UNKNOWN-fix-pkgconfig-file.patch # oops this was merged locally into 'setup-versioning'

apply quell-common-warnings.patch # Could be landed, but we can carry it separately.

cd js/src
autoconf-2.13

cd "$REPODIR"
cd ..

# Include files from mozilla repository.
TARFILE="${BUILDDIR}/mozjs${PACKAGEVERSION}.tar"
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
gzip -f ${TARFILE}
