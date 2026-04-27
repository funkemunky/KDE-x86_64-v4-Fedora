#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/glibc/Regression/bz979363-fputs-should-see-EINTR-and-propagate-it-up
#   Description: Tests fputs EINTR when writing to a blocking, full stream
#   Author: Arjun Shankar <ashankar@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2013 Red Hat, Inc.
#
#   This copyrighted material is made available to anyone wishing
#   to use, modify, copy, or redistribute it subject to the terms
#   and conditions of the GNU General Public License version 2.
#
#   This program is distributed in the hope that it will be
#   useful, but WITHOUT ANY WARRANTY; without even the implied
#   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public
#   License along with this program; if not, write to the Free
#   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
#   Boston, MA 02110-1301, USA.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Include Beaker environment
. /usr/share/beakerlib/beakerlib.sh || exit 1

PACKAGE="glibc"
REQUIRES=(gcc glibc glibc-devel)

rlJournalStart
    rlPhaseStartSetup
        for p in ${REQUIRES[@]}; do
            rlAssertRpm $p
        done; unset p
        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "cp bz970854.c ubz15362.c $TmpDir"
        rlRun "pushd $TmpDir"

        # Create an 80 MB regular file consisting of an ext4 FS
        rlRun "dd if=/dev/zero of=filesystem bs=1M count=80"
        rlAssertExists "filesystem"
        rlRun "mkfs.ext4 -F filesystem"

        # Mount it
        rlRun "mkdir mountpoint"
        rlRun "mount -t ext4 filesystem mountpoint"
        rlRun "df -l $TmpDir/mountpoint | grep $TmpDir/mountpoint"

        # Compile test sources
        rlRun "gcc -D_POSIX_SOURCE -std=c99 -Wall -pedantic -O0 -g3 -o bz970854 bz970854.c"
        rlAssertExists "bz970854"

        rlRun "gcc -Wall -O0 -o ubz15362 ubz15362.c"
        rlAssertExists "ubz15362"
    rlPhaseEnd

    rlPhaseStartTest
        # First Test
        rlRun "./bz970854 > bz970854.out"
        rlAssertExists "bz970854.out"
        rlAssertGrep "child status was 0" "bz970854.out"
        rlAssertGrep "child exit status was: 0" "bz970854.out"
        rlAssertNotGrep "FAIL" "bz970854.out"

        # Second Test (write to 80 MB FS til it is full, expect no FAILs
        rlRun "./ubz15362 mountpoint/foo"
        rlRun "./ubz15362 mountpoint/bar"
        rlRun "./ubz15362 mountpoint/baz"
        rlRun "./ubz15362 mountpoint/zoo"
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "umount mountpoint"
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
