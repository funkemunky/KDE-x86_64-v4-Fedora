#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# runtest.sh - bz464146-sp-corruption - Bugzilla(s) 464146
# Author: Petr Muller <pmuller@redhat.com>
# Location: /tools/glibc/Regression/bz464146-sp-corruption/runtest.sh

# Description: Test for bz464144, a stack pointer corruption problem

# Copyright (c) 2008 Red Hat, Inc. All rights reserved. This copyrighted material 
# is made available to anyone wishing to use, modify, copy, or
# redistribute it subject to the terms and conditions of the GNU General
# Public License v.2.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.


# Include Beaker environment
. /usr/share/beakerlib/beakerlib.sh || exit 1

PACKAGE="glibc"
TESTPROG="testit"

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm ${PACKAGE}
        rlRun "TESTTMPDIR=$(mktemp -d)"
        rlRun "cp ${TESTPROG}.c $TESTTMPDIR"
        rlRun "pushd $TESTTMPDIR"

        ARCH=`uname -m`
        if [ "$ARCH" == "ia64" -o "$ARCH" == "aarch64" -o "$ARCH" == "ppc64le" ]
        then
            FLAGS=""
        else
            FLAGS="-m64"
        fi
    rlPhaseEnd

    rlPhaseStartTest Test
        rlRun "gcc $FLAGS ${TESTPROG}.c -o ${TESTPROG} -lpthread"
        rlAssertExists "${TESTPROG}"
        ./${TESTPROG} > log
        RC=$?

        rlAssert0 "Testing for success of the testcases" $RC
        rlAssertNotEquals "Testing for segfault (bug 464146)" $RC 139
        rlAssertEquals "Testing for correct output - output should contain 1 line" `cat log | wc -l` 1
        rlAssertGrep "received \"Hello World\!\"" log
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "popd"
        rlRun "rm -r $TESTTMPDIR"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
