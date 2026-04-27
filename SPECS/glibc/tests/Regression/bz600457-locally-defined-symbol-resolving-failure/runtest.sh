#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/glibc/Regression/bz600457-locally-defined-symbol-resolving-failure
#   Description: Test for bz600457 ([4.8] Unexpected failure of resolving a)
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

rlJournalStart

rlPhaseStartSetup
  rlRun "tar xfz reproducer.tar.gz"
  rlRun "pushd reproducer"
  rlRun "make"
rlPhaseEnd

rlPhaseStartTest
  rlRun "./run.sh &> output.out"
  rlAssertNotDiffer ../golden.out output.out
  if [ "$?" != "0" ]
  then
    rlLog "Difference between outputs:"
    diff -u ../golden.out output.out | while read line
    do
      rlLog "$line"
    done
  fi
rlPhaseEnd

rlPhaseStartCleanup
  rlRun "popd"
  rlRun "rm -rf reproducer"
rlPhaseEnd

rlJournalEnd
