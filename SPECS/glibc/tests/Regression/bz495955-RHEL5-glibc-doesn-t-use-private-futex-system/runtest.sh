#!/bin/bash
# vim: dict=/usr/share/rhts-library/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/glibc/Regression/bz495955-RHEL5-glibc-doesn-t-use-private-futex-system
#   Description: Test for bz495955 ([RHEL5] glibc doesn't use private futex system)
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
rlPhaseStartSetup
  rlAssertRpm $PACKAGE
  rlRun "gcc -lrt -lpthread priv-mutex.c -o priv-mutex" 0 "Compiling the testcase"
rlPhaseEnd

rlPhaseStartTest
  rlLog "Checking for the default: should be using PRIVATE_PI"
  strace -f ./priv-mutex 2>&1 | grep FUTEX_LOCK_PI_PRIVATE
  rlAssert0 "Checking that FUTEX_LOCK_PI_PRIVATE was in the output" $?

  rlLog "Checking for using PRIVATE_PI when asked for it"
  strace -f ./priv-mutex -p 2>&1 | grep FUTEX_LOCK_PI_PRIVATE
  rlAssert0 "Checking that FUTEX_LOCK_PI_PRIVATE was in the output" $?

  rlLog "Checking for using SHARED_PI when asked for it"
  strace -f ./priv-mutex -s 2>&1 | grep "FUTEX_LOCK_PI,"
  rlAssert0 "Checking that just FUTEX_LOCK_PI was in the output" $?
rlPhaseEnd

rlPhaseStartCleanup
  rlRun "rm -f priv-mutex"
rlPhaseEnd

rlJournalEnd
