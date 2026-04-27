#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/glibc/Regression/bz580498-pthread-rwlock-timedwrlock-rdlock-never-return
#   Description: Test for bz580498 (pthread_rwlock_timedwrlock/rdlock() never return)
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

PACKAGE="glibc"
PACKAGE0="gcc"
SOURCEFILE="pthread_rwlock_timedwrlock.c"

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm $PACKAGE
        rlAssertRpm $PACKAGE0
        rlRun "TmpDir=\`mktemp -d\`" 0 "Creating tmp directory"
        rlRun "cp $SOURCEFILE $TmpDir" 0 "Copying reproducer $SOURCEFILE into $TmpDir"
        rlRun "pushd $TmpDir"
        rlRun "gcc -o pthread_rwlock_timedwrlock_a.out $SOURCEFILE -lpthread"
    rlPhaseEnd

    rlPhaseStartTest
        ./pthread_rwlock_timedwrlock_a.out > log &
        pidaout=$!
        # poor man's watchdog, cannot rely on beakerlib on this one
        sleep 5
        if test -d /proc/$pidaout &&
           test "`cat /proc/$pidaout/cmdline`" = "./pthread_rwlock_timedwrlock_a.out"; then
            rlFail "Fuction should return and errno=ETIMEDOUT (not returning anything, it's spinning instead)"
            kill -9 $pidaout
        elif grep -q 'TIME OUT' log; then
            rlPass "Fuction should return and errno=ETIMEDOUT"
        else
            ReprOut=`cat log`
            rlFail "Fuction should return and errno=ETIMEDOUT ($ReprOut)"
        fi
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
