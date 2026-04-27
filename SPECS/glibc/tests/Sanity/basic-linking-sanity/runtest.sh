#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/glibc/Sanity/basic-linking-sanity
#   Description: Test contains few testcases linking to various glibc libraries. Testing if testcases can be successfuly linked and run
#   Author: Petr Muller <pmuller@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2009 Red Hat, Inc. All rights reserved.
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

rlJournalStart
  rlPhaseStartTest "Compiling"
    rlRun "gcc lc.c -lc -o lc -fno-builtin" 0 "Testing for -lc linkage"
    rlRun "gcc lm.c -lm -o lm -fno-builtin" 0 "Testing for -lm linkage"
    rlRun "gcc lrt.c -lrt -o lrt -fno-builtin" 0 "Testing for -lrt linkage"
    rlRun "gcc lpthread.c -lpthread -o lpthread -fno-builtin" 0 "Testing for -lpthread linkage"
  rlPhaseEnd

  rlPhaseStartTest
    rlRun "./lc" 0 "Running lc testcase"
    rlRun "./lm" 0 "Running lm testcase"
    rlRun "./lrt" 0 "Running lrt testcase"
    rlRun "./lpthread" 0 "Running lpthread testcase"

    rlAssertNotDiffer "lc.out" "lc.golden"
    rlAssertNotDiffer "lm.out" "lm.golden"
    rlAssertNotDiffer "lrt.out" "lrt.golden"
    rlAssertNotDiffer "lpthread.out" "lpthread.golden"
  rlPhaseEnd

  rlPhaseStartCleanup
    rlBundleLogs "outputs" *.out
    rlRun "rm lc lc.out lm lm.out lrt lrt.out lpthread lpthread.out"
  rlPhaseEnd
rlJournalEnd
