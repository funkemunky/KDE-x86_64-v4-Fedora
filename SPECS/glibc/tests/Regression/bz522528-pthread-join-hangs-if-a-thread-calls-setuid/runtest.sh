#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/glibc/Regression/bz522528-pthread-join-hangs-if-a-thread-calls-setuid
#   Description: Test for bz522528 (pthread_join() hangs if a thread calls setuid())
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
TESTPROG="reproducer"

rlJournalStart

rlPhaseStartSetup
    rlRun "TESTTMPDIR=$(mktemp -d)"
    rlRun "cp ${TESTPROG}.c $TESTTMPDIR"
    rlRun "pushd $TESTTMPDIR"

    PRARCH=$(rlGetPrimaryArch)
    if [[ $PRARCH =~ ia64 || $PRARCH =~ armv7 || $PRARCH =~ i.86 || $PRARCH =~ aarch64 ]]
    then
        rlRun -c "gcc ${TESTPROG}.c -o $TESTPROG -lpthread"
    else
        rlRun -c "gcc ${TESTPROG}.c -o $TESTPROG -lpthread -m64"
    fi

    if [[ $PRARCH =~ s390x ]]
    then
        sleeptime=60
    else
        sleeptime=10
    fi
rlPhaseEnd

rlPhaseStartTest
  rlLog "Running the testcase 20 times"
  export FAILURES=0
  for i in `seq 20`
  do
    rlLog "Running the reproducer: try $i"
    ./${TESTPROG} &
    PID=$!
    sleep $sleeptime
    NAME=`ps -p $PID -o comm=`

    [ "$NAME" != "`basename ${TESTPROG}`" ]
    RESULT=$?
    rlAssert0 "Testing if the program is running" $RESULT

    if [ "$RESULT" != "0" ]
    then
      rlLog "Killing the stray process"
      kill -9 $PID

      rlLog "The program is still running"
      FAILURES=$((FAILURES+1))
    fi
  done
  rlAssert0 "Checking that no process had to be killed" $FAILURES
rlPhaseEnd

rlPhaseStartCleanup
    rlLog "Killing all reproducers, just to be sure"
    killall ${TESTPROG}
    rlRun "popd"
    rlRun "rm -r $TESTTMPDIR"
rlPhaseEnd

rlJournalEnd
