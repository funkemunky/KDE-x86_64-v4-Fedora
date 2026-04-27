#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/glibc/Regression/bz577950-ftell-after-write-causes-glibc-to-flush-buffer
#   Description: Calls ftell after write and verifies that buf is not flushed
#   Author: Arjun Shankar <ashankar@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2013 Red Hat, Inc. All rights reserved.
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
REQUIRES=(gcc glibc glibc-devel strace)

rlJournalStart
    rlPhaseStartSetup
        for p in ${REQUIRES[@]}; do
            rlAssertRpm $p
        done; unset p
        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "cp *.c *.expected $TmpDir"
        rlRun "pushd $TmpDir"
        rlRun "gcc -o tst-write-ftell tst-write-ftell.c"
        rlAssertExists "tst-write-ftell"
        rlRun "gcc -o tst-ftell-with-fdopen tst-ftell-with-fdopen.c"
        rlAssertExists "tst-ftell-with-fdopen"
    rlPhaseEnd

    rlPhaseStartTest
        rlRun "strace ./tst-write-ftell /dev/null 40 0 &> strace.out"
        rlAssertEquals "Do not expect any writes of size 208 bytes" "$(cat strace.out | grep '^write.*208$' | wc -l)" "0"
        rlLog "$(cat strace.out | grep ^write | head)"
        rlRun "strace ./tst-write-ftell /dev/null 40 1 &> strace.out"
        rlAssertEquals "Do not expect any writes of size 208 bytes" "$(cat strace.out | grep '^write.*208$' | wc -l)" "0"
        rlLog "$(cat strace.out | grep ^write | head)"
        for f1 in "" "-f"; do
            for f2 in "" "-o"; do
                rlRun "./tst-ftell-with-fdopen $f1 $f2"
                rlRun "cmp tst-ftell-with-fdopen.out tst-ftell-with-fdopen.expected"
            done
        done
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
