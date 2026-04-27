#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/glibc/Regression/bz529997-sem_timedwait-with-invalid-time
#   Description: Test for bz529997 (assembler implementation of sem_timedwait() on)
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
    PRARCH="$(rlGetPrimaryArch)"
    rlLog "Architecture :  $PRARCH"
    rlAssertRpm $PACKAGE
    if rlIsRHEL 5 6
    then
	    rlRun "gcc oldrepr.c -o repro1 -lpthread"
    else
	    rlRun "gcc newrepr.c -o repro1 -lpthread"
    fi
    rlRun "gcc real-reproducer.c -o repro2 -lrt -lpthread"

    # just adding --copy-dt-needed-entries to the linker would work as well
    # rlRun "gcc -Wl,--copy-dt-needed-entries reproducer.c -o repro1 -lrt"
    # rlRun "gcc -Wl,--copy-dt-needed-entries real-reproducer.c -o repro2 -lrt"
    # https://fedoraproject.org/wiki/UnderstandingDSOLinkChange 
  rlPhaseEnd

  rlPhaseStartTest
    rlLog "Running reproducers"
    ./repro1 > repro.out
    ./repro2 > real.out
    rlAssertNotDiffer "golden-repro.out" "repro.out"
    if [ $? -ne 0 ]
    then
      rlLog "The first repro output differs from golden:"
      diff -u "golden-repro.out" "repro.out" | while read line
      do
        rlLog "$line"
      done
    fi

    rlAssertNotDiffer "golden-real.out" "real.out" || 
    if [ $? -ne 0 ]
    then
      rlLog "The second repro output differs from golden:"
      diff -u "golden-real.out" "real.out" | while read line
      do
        rlLog "$line"
      done
    fi
  rlPhaseEnd

  rlPhaseStartCleanup
    rlRun "rm repro1 repro2 real.out repro.out"
  rlPhaseEnd
rlJournalEnd
