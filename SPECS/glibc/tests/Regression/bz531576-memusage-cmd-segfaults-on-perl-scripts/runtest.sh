#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/glibc/Regression/bz531576-memusage-cmd-segfaults-on-perl-scripts
#   Description: Test for bz531576 ([RHEL5] memusage cmd segfaults if run on a perl)
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
    TEMPC=`mktemp`.c
    echo "int main(){ return 0; }" > $TEMPC
    echo "int result() { return 1; }" >> $TEMPC
    for i in `seq 10000`
    do
        echo "int fction$i(){ return result(); }" >> $TEMPC
    done
rlPhaseEnd

rlPhaseStartTest
    if rlIsRHEL ">=8" || rlIsCentOS ">=8" ||  rlIsFedora
    then
        CURPYTHON="python3"
        P3="p3_3.py"
        P4="p4_3.py"
    else
        CURPYTHON="python"
        P3="p3.py"
        P4="p4.py"
    fi

    for testcase in "perl p1.pl" "perl p2.pl" "$CURPYTHON $P3" "$CURPYTHON $P4" "$CURPYTHON -V" "ps" "gcc -O0 $TEMPC -o /dev/null"
    do
      for output in "" "--png=out.png" "--png=out.png -x 800 -y 300" "--data=out.dat"
      do
        for mmap in "" "--mmap"
        do
          rlRun "memusage $output $mmap $testcase"
        done
      done
    done
rlPhaseEnd

rlPhaseStartCleanup
  rlRun "rm -f out.png out.dat $TEMPC"
rlPhaseEnd

rlJournalEnd
