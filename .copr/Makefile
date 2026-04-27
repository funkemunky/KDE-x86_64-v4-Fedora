FEDORA_BRANCH ?= f43
FEDORA_DIST ?= .fc43
FEDORA_NAMESPACE ?= rpms
LOOKASIDE_BASEURL ?= https://src.fedoraproject.org/repo/pkgs
PYTHON ?= python3
REPO_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
SPEC_REF := $(strip $(if $(spec),$(spec),$(COPR_PACKAGE)))

.PHONY: srpm

srpm:
	test -n "$(SPEC_REF)"
	test -n "$(outdir)"
	mkdir -p "$(outdir)"
	cd "$(REPO_ROOT)" && "$(PYTHON)" ci/copr-distgit-make-srpm.py \
		--spec-ref "$(SPEC_REF)" \
		--outdir "$(outdir)" \
		--branch "$(FEDORA_BRANCH)" \
		--dist "$(FEDORA_DIST)" \
		--namespace "$(FEDORA_NAMESPACE)" \
		--lookaside-baseurl "$(LOOKASIDE_BASEURL)"
