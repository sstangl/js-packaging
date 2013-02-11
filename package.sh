#!/bin/bash

REPODIR="$HOME/dev/mozilla-esr17"
BUILDDIR=$(pwd)

cd "$REPODIR"

hg revert -a
hg st -un | xargs rm

PACKAGEVERSION=188-1.0.0
PACKAGEFULLVERSION="${PACKAGEVERSION}~hg"$(date +%Y%m%d)".esr17."$(hg id -i | cut -c -8)

patch -p1 < $BUILDDIR/moz188-libname-changes.patch
patch -p1 < $BUILDDIR/moz188-fix-version.patch
patch -p1 < $BUILDDIR/moz188-install-headers.patch

cd js/src
autoconf-2.13

cd "$REPODIR"
cd ..

tar Jcf $BUILDDIR/js${PACKAGEVERSION}.tar.xz --exclude='.hg' --exclude="*.orig" --exclude="*.rej" mozilla-esr17/js/jsd mozilla-esr17/js/public mozilla-esr17/js/src mozilla-esr17/mfbt

cd "$BUILDDIR"
