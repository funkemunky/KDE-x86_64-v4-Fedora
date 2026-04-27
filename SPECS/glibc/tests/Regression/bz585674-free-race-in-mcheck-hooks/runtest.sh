#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/glibc/Regression/bz585674-free-race-in-mcheck-hooks
#   Description: Test for bz585674 (free() race in mcheck hooks)
#   Author: Petr Muller <pmuller@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2010 Red Hat, Inc. All rights reserved.
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

# Include rhts environment
. /usr/share/beakerlib/beakerlib.sh || exit 1

PACKAGE="glibc"
TESTPROG="malloc_check"

rlJournalStart

rlPhaseStartSetup
    rlRun "TESTTMPDIR=$(mktemp -d)"
    rlRun "cp ${TESTPROG}.c $TESTTMPDIR"
    rlRun "pushd $TESTTMPDIR"
rlPhaseEnd

rlPhaseStartTest
    rlRun -c "gcc ${TESTPROG}.c -o $TESTPROG -g -fopenmp"
    export MALLOC_CHECK_=3
    for i in `seq 10`
    do
      rlRun -c "./${TESTPROG}" 0 "Testcase attempt $i"
    done
rlPhaseEnd

rlPhaseStartCleanup
    rlRun "popd"
    rlRun "rm -r $TESTTMPDIR"
rlPhaseEnd

rlJournalEnd
