#!/bin/bash
# vim: dict=/usr/share/rhts-library/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/glibc/Regression/bz503723-fopen-mode-x-ignored-in-some-cases
#   Description: Test for bz503723 (fopen mode 'x' ignored in some cases)
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
  if rlIsRHEL ">=8" || rlIsFedora
  then
	  rlRun -c "cp expected.py3 expected.py"
  else
	  rlRun -c "cp expected.py2 expected.py"
  fi
  rlAssertExists "expected.py"
  rlRun "gcc fopen.c -o fopen"
rlPhaseEnd

rlPhaseStartTest "Testing modes on existing file"
  rlLog "Trying all variants of modes in open"
  rlRun "touch ababab" 0 "Creating a test file"
  for mode in  "r" "r+" "w" "w+" "a" "a+"
  do
    for f in "" "c"
    do
      for s in "" "m"
      do
        for t in "" "x"
        do 
          golden="`./expected.py ex $mode$f$s$t | tr --squeeze ' '`"
          for variant in "$mode$f$s$t" "$mode$f$t$s" "$mode$s$f$t" "$mode$s$t$f" "$mode$t$f$s" "$mode$t$s$f"
          do
            try="`strace -e open,openat ./fopen ababab $variant 2>&1 | grep ababab | tr --squeeze ' ' | perl -pe 's/openat\(AT_FDCWD, /open\(/'`"
            echo $try
            rlAssertEquals "Checking mode [$variant] is identical to golden [$mode$f$s$t]" "$golden" "$try"
          done
        done
      done
    done
  done
rlPhaseEnd

rlPhaseStartTest "Testing modes on nonexisting file"
  rlLog "Trying all variants of modes in open"
 
  for mode in  "r" "r+" "w" "w+" "a" "a+"
  do
    for f in "" "c"
    do
      for s in "" "m"
      do
        for t in "" "x"
        do
          golden="`./expected.py nex $mode$f$s$t | tr --squeeze ' '`"
          for variant in "$mode$f$s$t" "$mode$f$t$s" "$mode$s$f$t" "$mode$s$t$f" "$mode$t$f$s" "$mode$t$s$f"
          do
            rlRun "rm -f ababab"
            try="`strace -e open,openat ./fopen ababab $variant 2>&1 | grep ababab | tr --squeeze ' ' | perl -pe 's/openat\(AT_FDCWD, /open\(/'`"
            echo $try
            rlAssertEquals "Checking mode [$variant] is identical to golden [$mode$f$s$t]" "$golden" "$try"
          done
        done
      done
    done
  done
rlPhaseEnd

rlPhaseStartCleanup
  rlRun "rm -f fopen"
  rlRun "rm -f ababab"
  rlRun "rm expected.py"
rlPhaseEnd
rlJournalEnd
