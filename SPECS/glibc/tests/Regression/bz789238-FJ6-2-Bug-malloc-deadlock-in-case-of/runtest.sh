#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/glibc/Regression/bz789238-FJ6-2-Bug-malloc-deadlock-in-case-of
#   Description: Test for bz789238 ([FJ6.2 Bug] malloc() deadlock in case of)
#   Author: Miroslav Franc <mfranc@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2012 Red Hat, Inc. All rights reserved.
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

PACKAGE=glibc
REQUIRES=(glibc gcc glibc-devel coreutils)

# calloc keep trigering OOM killer, disabling for now
# FUNCTIONS=(MALLOC CALLOC VALLOC MEMALIGN)
FUNCTIONS=(MALLOC VALLOC MEMALIGN)
: ${ITERATIONS:=16}
TSTTIMEOUT=900

rlJournalStart
    rlPhaseStartSetup
        for p in "${REQUIRES[@]}"; do
            rlAssertRpm "$p"
        done; unset p
        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "cp mallocstress.c redshirt-process.sh $TmpDir"
        rlRun "pushd $TmpDir"
        for f in "${FUNCTIONS[@]}"; do
            rlRun "gcc -D$f -g -O2 -g -O2 -fno-strict-aliasing -pipe -Wall mallocstress.c  -lm -lpthread -o mallocstress.$f"
        done; unset f
    rlPhaseEnd

    rlPhaseStartTest
        for ((i=0;i<ITERATIONS;++i)); do
            for f in "${FUNCTIONS[@]}"; do
                rlLog "=== $i/$((ITERATIONS-1)) ==="
                rm -f log
                dmesg >dmesg.before

                # Either the program runs to successful completion (RC=0),
                # or gets killed by OOM killer (RC=137 i.e., SIGKILL)

                # The redshirt-process.sh is just a wrapper that sets the
                # process up to have a high chance of being selected by the
                # OOM killer, so that the killer doesn't accidentally kill
                # something important instead, like beaker apparatus
                rlRun "timeout $TSTTIMEOUT env MALLOC_ARENA_MAX=2 ./redshirt-process.sh ./mallocstress.$f >log 2>&1" 0,137

                if [ $? -eq 137 ]; then
                    dmesg >dmesg.after
                    diff dmesg.before dmesg.after | grep '^>' >dmesg.log
                    if grep -i "out of memory" dmesg.log; then
                        rlLogWarning "Killed by OOM killer; but this is NOT a test failure"
                    else
                        rlFail "Received SIGKILL but no corresponding dmesg log"
                    fi
                else
                    rlAssertGrep 'main(): test passed' log || break 2
                fi
            done; unset f
        done; unset i
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
