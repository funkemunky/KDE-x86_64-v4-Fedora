#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/glibc/Regression/bz827362-RHEL6-2-ftell-after-fseek-moves-the-offset-on-a
#   Description: Test for BZ#827362 ([RHEL6.2] ftell after fseek moves the offset on a)
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
. /usr/share/beakerlib/beakerlib.sh

PACKAGES=(glibc gcc)

rlJournalStart
    rlPhaseStartSetup
        for p in "${PACKAGES[@]}"; do
            rlAssertRpm "$p"
        done; unset p
        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "cp test.c fseek-wchar* fw.* output.* $TmpDir"
        rlRun "pushd $TmpDir"
    rlPhaseEnd

    rlPhaseStartTest "reproducer"
        rlRun "gcc -DUTF8 -o test test.c"
        rlRun "./test > log 2>&1"
	rlAssertNotDiffer output.seeking log
	rlLog "$(diff -u output.seeking log)"
	rlAssertNotDiffer output.golden output.txt
	rlLog "$(diff -u output.golden output.txt)"
    rlPhaseEnd

    for o in '-DTESTREAD -DUTF8' '-DUTF8'; do
	    rlPhaseStartTest "another reproducer : $o"
		rlRun "gcc $o -o fseek-wchar fseek-wchar.c"
		rlRun "./fseek-wchar <fw.input >log 2>&1"
		rlAssertNotDiffer log fw.golden
		rlLog "$(diff -u log fw.golden)"
	    rlPhaseEnd

	    rlPhaseStartTest "yet another reproducer : $o"
		rlRun "gcc $o -o fseek-wchar-j fseek-wchar-j.c"
		rlRun "./fseek-wchar-j <fw.input >log 2>&1"
		rlAssertNotDiffer log fw.j.golden
		rlLog "$(diff -u log fw.j.golden)"
	    rlPhaseEnd
    done; unset o

    rlPhaseStartCleanup
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
