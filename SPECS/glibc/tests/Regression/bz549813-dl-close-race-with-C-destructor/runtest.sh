#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/glibc/Regression/bz549813-dl-close-race-with-C-destructor
#   Description: Test for bz549813 (dl_close() race with C++ destructor)
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
. /usr/share/beakerlib/beakerlib.sh

PACKAGE="glibc"

rlJournalStart

rlPhaseStartSetup
  rlRun "tar xfv C_Only.tar"
  rlRun "pushd C_Only" && rlRun "make it"
rlPhaseEnd

rlPhaseStartTest
  export LD_LIBRARY_PATH=.
  rlLog "Checking that the command does not hang"
  rlRun "rlWatchdog ./c_only 5" && rlRun "./c_only" 0 "Checking that the testcase works correctly"
  unset LD_LIRBARY_PATH
rlPhaseEnd

rlPhaseStartCleanup
  rlLog "Killing possible remnants"
  killall -9 c_only
  rlRun "make clean"
  rlRun "popd"
  rlRun "rm -rf C_Only"
rlPhaseEnd

rlJournalEnd
