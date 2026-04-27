#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/glibc/Regression/bz587360-digraph-matching-differs-across-archs
#   Description: Test for bz587360 (Pattern matching of digraphs differs across archs)
#   Author: Petr Splichal <psplicha@redhat.com>
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

if rlIsRHEL ">=8" || rlIsCentOS ">=8" || rlIsFedora > 28
then
    AtoZ="abcčČdefghchcHChCHijklmnopqrřŘsšŠtuvwxyzžŽ"
    POSPATTERN="^---čČ--------HC-CH----------řŘ-šŠ-------žŽ$"
    NEGPATTERN="^abc--defgh----ijklmnopqr--s--tuvwxyz--$"
else
    AtoZ="abcdefghchijklmnopqrstuvwxyz"
    POSPATTERN="^--*$"
    NEGPATTERN=$AtoZ
fi
rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm $PACKAGE
        if rlIsRHEL 8 || rlIsCentOS 8 || rlIsFedora > 20
        then
           rlAssertRpm  glibc-langpack-cs
        fi
        rlRun "TmpDir=\`mktemp -d\`" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"
        rlRun "export LANG=cs_CZ.UTF-8"
    rlPhaseEnd

    rlPhaseStartTest
        # positive range
        rlRun "echo $AtoZ | sed 's/[a-z]/-/g' | tee output" \
                0 "Testing positive range"
        rlAssertGrep "$POSPATTERN" "output"

        # negative range
        rlRun "echo $AtoZ | sed 's/[^a-z]/-/g' | tee output" \
                0 "Testing negative range"
        rlAssertGrep "$NEGPATTERN" "output"
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
