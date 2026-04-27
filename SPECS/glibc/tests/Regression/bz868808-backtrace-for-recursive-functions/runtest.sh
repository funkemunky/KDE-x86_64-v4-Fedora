#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/glibc/Regression/bz868808-backtrace-for-recursive-functions
#   Description: Calls and verifies result of 'backtrace' while performing recursion.
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

PACKAGES=(glibc glibc-devel gcc)

rlJournalStart
    rlPhaseStartSetup
        for p in "${PACKAGES[@]}"; do
            rlAssertRpm "$p"
        done; unset p
        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "cp bt-tst.c $TmpDir"
        rlRun "pushd $TmpDir"
        rlRun "gcc -O0 -rdynamic bt-tst.c -o bt-tst"
        rlAssertExists "bt-tst"
    rlPhaseEnd

    rlPhaseStartTest
        rlRun "./bt-tst 10 > bt-tst.out"

        OUTPUT_LC="$(cat bt-tst.out | wc -l)"
        rlAssertGreaterOrEqual "At least 13 entries in the backtrace" $OUTPUT_LC 13

        function checkBackTrace {
            BT_STACK_ENTRY="$(cat bt-tst.out | tail -n $(($OUTPUT_LC -$1)) | head -n1)"
            if [[ $BT_STACK_ENTRY == *"./bt-tst($2"* ]]
            then
              rlPass "Expect '$2' @ $1 positions below top-of-stack:  \"$BT_STACK_ENTRY\""
            else
              rlFail "Expect '$2' @ $1 positions below top-of-stack:  \"$BT_STACK_ENTRY\""
            fi
        }

        # Check each line of the backtrace, right down to `main':
        checkBackTrace 0 last
        checkBackTrace 1 ")"
        for i in {2..11}
        do
            checkBackTrace $i recursive
        done
        checkBackTrace 12 main
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
