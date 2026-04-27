#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/glibc/Regression/bz916656-fpathconf-for-FIFO-returns-different-value-than-for-directory
#   Description: Tests pathconf and fpathconf on a FIFO and directory
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
        rlRun "cp fpathconf-t.c $TmpDir"
        rlRun "pushd $TmpDir"
        rlRun "gcc -o fpathconf-t fpathconf-t.c"
        rlAssertExists "fpathconf-t"
    rlPhaseEnd

    rlPhaseStartTest
        rlRun "mkfifo fpathconf-t.15"
        rlRun "mkfifo fpathconf-t.16"
        rlRun "./fpathconf-t &> fpathconf-t.out"
        rlAssertEquals "Test should report PASS twice" "$(cat fpathconf-t.out | grep PASS | wc -l)" "2"
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
