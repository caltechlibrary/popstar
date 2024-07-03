# @file    Makefile
# @brief   Makefile for building docs using Sphinx and MyST
# @created 2021-01-25
# @license Please see the file named LICENSE in the project directory
# @website https://github.com/caltechlibrary/popstar

# Before we go any further, test if certain programs are available.
# The following is based on the approach posted by Jonathan Ben-Avraham to
# Stack Overflow in 2014 at https://stackoverflow.com/a/25668869

PROGRAMS_NEEDED = sphinx-build pip
TEST := $(foreach p,$(PROGRAMS_NEEDED),\
	  $(if $(shell which $(p)),_,$(error Cannot find program "$(p)")))


# Gather values that we need ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# You can set the following variables from the command line, and also from
# the environment for the first two.

SPHINXOPTS  ?=
SPHINXBUILD ?= sphinx-build
SPHINXAUTO   = sphinx-autobuild
SRCDIR	     = .
BUILDDIR     = _build


# Actions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Put it first so that "make" without argument is like "make help".
help:
	@echo "Available commands:"
	@echo "  auto	to watch source directory & rebuild docs if files change" |\
	  expand -t 14
	@$(SPHINXBUILD) -M help "$(SRCDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O) |\
	  egrep -v '^Sphinx|Please' | sort | expand -t 20

check-python-requirements:
ifneq ($(filter Location:,$(shell pip show pygments)),Location:)
	$(error One or more Python dependencies are not installed \
	        – has "pip -r requirements.txt" been run?)
endif

auto autobuild live livehtml: check-python-requirements
	@$(SPHINXAUTO) "$(SRCDIR)" "$(BUILDDIR)"/html $(SPHINXOPTS) $(O)

# Catch-all target: route all unknown targets to Sphinx using the new
# "make mode" option.  $(O) is meant as a shortcut for $(SPHINXOPTS).
%: Makefile check-python-requirements
	@$(SPHINXBUILD) -M $@ "$(SRCDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)


# Cleanup and miscellaneous directives ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.PHONY: help auto autobuild livehtml Makefile check-python-requirements
