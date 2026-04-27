#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/glibc/Regression/bz705465-fix-for-handle-overflows-of-temporary-buffer-used
#   Description: Test for bz705465 (fix for handle overflows of temporary buffer used)
#   Author: Miroslav Franc <mfranc@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2011 Red Hat, Inc. All rights reserved.
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

PACKAGES=(glibc gcc)

rlJournalStart
    rlPhaseStartSetup
        for p in "${PACKAGES[@]}"; do
            rlAssertRpm "$p"
        done; unset p
        if rlIsRHEL 5 || rlIsRHEL 6
        then
            rlAssertRpm nss_db
        fi
        rlRun "TmpDir=\`mktemp -d\`" 0 "Creating tmp directory"
        rlRun "cp repr.c $TmpDir"
        rlRun "pushd $TmpDir"
        rlRun "gcc repr.c -lpthread"
        rlAssertExists "a.out"
        for i in one two three four five six seven; do
                rlRun "groupadd $i"
        done; unset i
        rlRun "useradd lotsofgroups -G one,two,three,four,five,six,seven"
        sleep 1
        rlLog "$(id lotsofgroups)"
        rlLog "$(id root)"
        rlFileBackup /etc/nsswitch.conf
        for s in passwd shadow group; do
            sed -i "s/^\($s:\s*\)\(.*\)$/\1db \2/" /etc/nsswitch.conf
        done; unset s
        rlRun "make -f /var/db/Makefile"
    rlPhaseEnd

    rlPhaseStartTest "./a.out should always return all lines identical"
        test "x$(arch)" = "xi686" && ulimit -s 1024 # 32b systems should die!
        for ((i=0;i<30;i++)); do
                rlRun "test \$(./a.out lotsofgroups | sort -u | wc -l) -eq 1" 0\
                "Attempt $i: user lotsofgroups (all lines should be identical)"
                rlRun "test \$(./a.out root | sort -u | wc -l) -eq 1" 0\
                "Attempt $i: user root (all lines should be identical)"
        done; unset i
    rlPhaseEnd

    rlPhaseStartCleanup
        rlFileRestore
        rlRun "rm -f /var/db/*.db"
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
        rlRun "userdel -r lotsofgroups"
        for i in one two three four five six seven; do
                rlRun "groupdel $i"
        done
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
