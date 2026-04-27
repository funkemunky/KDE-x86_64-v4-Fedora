# Copyright (c) 2006 Red Hat, Inc. All rights reserved. This copyrighted material 
# is made available to anyone wishing to use, modify, copy, or
# redistribute it subject to the terms and conditions of the GNU General
# Public License v.2.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# Author: David Malcolm

# The toplevel namespace within which the test lives.
TOPLEVEL_NAMESPACE=/tools

# The name of the package under test:
PACKAGE_NAME=glibc

# The path of the test below the package:
RELATIVE_PATH=fallocate_156289

# Version of the Test. Used with make tag.
export TESTVERSION=1.0

# The compiled namespace of the test.
export TEST=$(TOPLEVEL_NAMESPACE)/$(PACKAGE_NAME)/$(RELATIVE_PATH)

.PHONY: all install download clean

BUILT_FILES=fallocate
FILES=$(METADATA) runtest.sh Makefile fallocate.c++

run: $(FILES) build
	./runtest.sh

build: $(BUILT_FILES)
	chmod a+x ./runtest.sh

clean:
	rm -f *~ $(BUILT_FILES)

# You may need to add other taregts e.g. to build executables from source code
# Add them here:
fallocate:
	g++ fallocate.c++ -o fallocate

# Include Common Makefile
include /usr/share/rhts/lib/rhts-make.include

# Generate the testinfo.desc here:
$(METADATA): Makefile
	@touch $(METADATA)
	@echo "Owner:        David Malcolm <dmalcolm@redhat.com>" > $(METADATA)
	@echo "Name:         $(TEST)" >> $(METADATA)
	@echo "Path:         $(TEST_DIR)"	>> $(METADATA)
	@echo "License:      Unknown"	>> $(METADATA)
	@echo "TestVersion:  $(TESTVERSION)"	>> $(METADATA)
	@echo "Description:  Ensure fallocate() extends files by the correct amount">> $(METADATA)
	@echo "TestTime:     3m" >> $(METADATA)
	@echo "Bug:          156289" >> $(METADATA)
	@echo "RunFor:       $(PACKAGE_NAME)" >> $(METADATA)
	@echo "Requires:     $(PACKAGE_NAME)" >> $(METADATA)
	@echo "Requires:     gcc-c++" >> $(METADATA)
	@echo "Type:         Regression" >> $(METADATA)
	@echo "Type:         Standardscompliance" >> $(METADATA)
	@echo "Type:         Tier2" >> $(METADATA)
	rhts-lint $(METADATA)
