# Summary: Makefile for developing Popstar.
# Run "make" or "make help" to get a list of commands in this makefile.
#
# Copyright 2024 California Institute of Technology.
# License: Modified BSD 3-clause – see file "LICENSE" in the project website.
# Website: https://github.com/caltechlibrary/popstar

SHELL=/bin/bash
.ONESHELL:                              # Run all commands in the same shell.
.SHELLFLAGS += -e                       # Exit at the first error.

# This Makefile uses syntax that needs at least GNU Make version 3.82.
# The following test is based on the approach posted by Eldar Abusalimov to
# Stack Overflow in 2012 at https://stackoverflow.com/a/12231321/743730

ifeq ($(filter undefine,$(value .FEATURES)),)
$(error Unsupported version of Make. \
    This Makefile does not work properly with GNU Make $(MAKE_VERSION); \
    it needs GNU Make version 3.82 or later)
endif

# Before we go any further, test if certain programs are available.
# The following is based on the approach posted by Jonathan Ben-Avraham to
# Stack Overflow in 2014 at https://stackoverflow.com/a/25668869

programs_needed = curl git gh jq column jsonlint yamllint markdownlint
TEST := $(foreach p,$(programs_needed),\
	  $(if $(shell which $(p)),_,$(error Cannot find program "$(p)")))

# Set some basic variables. These are quick to set; we set additional ones
# using the dependency named "vars" but only when the others are needed.

name	  := $(strip $(shell jq -r .name codemeta.json))
progname  := $(strip $(shell jq -r '.identifier | ascii_downcase' codemeta.json))
version	  := $(strip $(shell jq -r .version codemeta.json))
repo	  := $(shell git ls-remote --get-url | sed -e 's/.*:\(.*\).git/\1/')
repo_url  := https://github.com/$(repo)
branch	  := $(shell git rev-parse --abbrev-ref HEAD)
rel_notes := .release_notes.md
today	  := $(shell date "+%F")


# Print help if no command is given ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# The help scheme works by looking for lines beginning with "#:" above make
# targets in this file. Originally based on code posted to Stack Overflow on
# 2019-11-28 by Richard Kiefer at https://stackoverflow.com/a/59087509/743730

#: Print a summary of available commands.
help:
	@echo "This is the Makefile for $(bold)$(name)$(norm)."
	@echo "Available commands:"
	@echo
	@grep -B1 -E "^[a-zA-Z0-9_-]+\:([^\=]|$$)" $(MAKEFILE_LIST) \
	| grep -v -- -- \
	| sed 'N;s/\n/###/' \
	| sed -n 's/^#: \(.*\)###\(.*\):.*/$(emph)\2$(norm):###\1/p' \
	| column -t -s '###'

#: Summarize how to do a release using this makefile.
instructions:;
	$(info $(instructions_text))

define instructions_text =
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ Steps for doing a release                                          ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
 1. Run $(emph)make lint$(norm), fix any problems, and commit any changes.
 2. Update the version number in the file codemeta.json.
 3. Update CHANGES.md if needed & commit changes.
 4. Check the output of $(emph)make report$(norm) (ignoring current id & DOI).
 5. Run $(emph)make clean$(norm).
 6. Run $(emph)make release$(norm); after some steps, it will open a file
    in your editor to write GitHub release notes. Copy the notes
    from CHANGES.md. Save the opened file to finish the process.
 7. Wait for the IGA GitHub Action to finish uploading to InvenioRDM
 8. Check that everything looks okay with the GitHub release at
    $(link)$(repo_url)/releases$(norm)
endef


# Gather additional values we sometimes need ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# These variables take longer to compute, and for some actions like "make help"
# they are unnecessary and annoying to wait for.
vars: doi-vars
	$(eval url	:= $(strip $(shell jq -r '.url // empty' codemeta.json)))
	$(eval url	:= $(or $(url),$(repo_url)))
	$(eval license	:= $(strip $(shell jq -r .license codemeta.json)))
	$(eval desc	:= $(strip $(shell jq -r .description codemeta.json)))
	$(eval author	:= \
	  $(strip $(shell jq -r '.author[0].givenName + " " + .author[0].familyName' codemeta.json)))
	$(eval email	:= $(strip $(shell jq -r .author[0].email codemeta.json)))

# If this software isn't getting archived in InvenioRDM, the next rule will
# leave rdm_id & new_doi undefined. Other rules in this makefile test for that.
.SILENT: doi-vars
doi-vars:
	$(eval rdm_link	:= \
	  $(strip $(shell jq -r '.relatedLink | if type == "array" then .[0] else . end' codemeta.json)))
ifneq ($(rdm_link),null)
	$(eval rdm_url	  := $(shell cut -d'/' -f 1-3 <<< $(rdm_link)))
	$(eval rdm_id	  := $(shell sed -r 's|.*/(.*)$$|\1|' <<< $(rdm_link)))
	$(eval vers_url   := $(rdm_url)/api/records/$(rdm_id)/versions/latest)
	$(eval latest_doi := $(shell curl -L -s $(vers_url) | jq -r .pids.doi.identifier))
endif

#: Print variables set in this Makefile from various sources.
.SILENT: report
report: vars
	echo "$(emph)name$(norm)	 = $(name)"	  | expand -t 21
	echo "$(emph)progname$(norm)	 = $(progname)"   | expand -t 21
	echo "$(emph)desc$(norm)	 = $(desc)"	  | expand -t 21
	echo "$(emph)version$(norm)	 = $(version)"	  | expand -t 21
	echo "$(emph)author$(norm)	 = $(author)"	  | expand -t 21
	echo "$(emph)email$(norm)	 = $(email)"	  | expand -t 21
	echo "$(emph)license$(norm)	 = $(license)"	  | expand -t 21
	echo "$(emph)url$(norm)	 = $(url)"	  | expand -t 21
	echo "$(emph)repo url$(norm)	 = $(repo_url)"   | expand -t 21
	echo "$(emph)branch$(norm)	 = $(branch)"	  | expand -t 21
	echo "$(emph)rdm_id$(norm)	 = $(rdm_id)"	  | expand -t 21
	echo "$(emph)latest_doi$(norm) = $(latest_doi)" | expand -t 21


# make lint & make test ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#: Run code and other files through linters.
lint:
	markdownlint $(shell find . -name '*.md')
	yamllint CITATION.cff $(shell find . -name '*.yml')
	jsonlint -q codemeta.json

#: Run unit tests and coverage tests.
test tests:;
	$(error "There are no tests in this repo yet. They need to be added.")


# make release ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#: Make a release on GitHub.
release: | test-branch confirm-release update-all release-on-github update-doi

test-branch:
ifneq ($(branch),main)
	$(error Current git branch != main. Merge changes into main first!)
endif

confirm-release:
	@read -p "Have you updated the version number? [y/N] " ans && : $${ans:=N} ;\
	if [ $${ans::1} != y ]; then \
	  $(MAKE) --no-print-directory print-version-reminder
	  exit 1
	fi

print-version-reminder:
	@$(info ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓)
	@$(info ┃ First update the version number in codemeta.json. ┃)
	@$(info ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛)

release-on-github: | vars update-all write-release-notes
	$(eval tag := "v$(shell tr -d '()' <<< "$(version)" | tr ' ' '-')")
	gh release create $(tag) -t "Release $(version)" -F $(rel_notes)
	gh release edit $(tag) --latest

update-all: update-meta update-citation commit-updates

# Note that this doesn't replace "version" in codemeta.json, because that's the
# variable from which this makefile gets its version number in the first place.
update-meta:
	@sed -i .bak -e '/"datePublished"/ s|: ".*"|: "$(today)"|' codemeta.json
	@echo codemeta.json updated ✨

update-citation: vars
	@sed -i .bak -e '/^url:/ s|:.*|: $(url)|' CITATION.cff
	@sed -i .bak -e '/^title:/ s|:.*|: $(name)|' CITATION.cff
	@sed -i .bak -e '/^version:/ s|:.*|: $(version)|' CITATION.cff
	@sed -i .bak -e '/^abstract:/ s|:.*|: $(desc)|' CITATION.cff
	@sed -i .bak -e '/^license-url:/ s|:.*|: $(license)|' CITATION.cff
	@sed -i .bak -e '/^date-released:/ s|:.*|: $(today)|' CITATION.cff
	@sed -i .bak -e '/^repository-code:/ s|:.*|: $(repo_url)|' CITATION.cff
	@echo CITATION.cff updated ✨

edited := codemeta.json CITATION.cff

commit-updates:
	git add $(edited)
	git diff-index --quiet HEAD $(edited) || \
	    git commit -m"chore: update stored version number" $(edited)
	git push -v --all
	git push -v --tags

write-release-notes: | create-notes-template edit-notes-template

create-notes-template:
	@$(info ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓)
	@$(info ┃ For the next few minutes, the Shortcuts app will restart  ┃)
	@$(info ┃ multiple times and dialog boxes will open and close. This ┃)
	@$(info ┃ is a side-effect of the workflow for obtaining the iCloud ┃)
	@$(info ┃ release URLs for the Shortcuts.                           ┃)
	@$(info ┃                                                           ┃)
	@$(info ┃ $(bold)Do not touch your computer until this process finishes.$(norm)   ┃)
	@$(info ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛)
	@cp dev/templates/RELEASE_NOTES_TEMPLATE.md $(rel_notes)
	@for file in src/*.shortcut; do
	  name=$${file#src/}
	  name=$${name%.shortcut}
	  link=`dev/scripts/get-shortcut-link "$${name}"`
	  echo "* [$${name}]($${link})" >> $(rel_notes)
	done

edit-notes-template:
	@$(info ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓)
	@$(info ┃ The iCloud links workflow has finished. Now a template    ┃)
	@$(info ┃ file will be opened in your default text editor. Write    ┃)
	@$(info ┃ release notes in the file, save the file, and close the   ┃)
	@$(info ┃ editor window to complete the release process.            ┃)
	@$(info ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛)
	sleep 2
	$(EDITOR) $(rel_notes)

update-doi: | wait-on-iga
	$(MAKE) post-release

wait-on-iga:
	@$(info ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓)
	@$(info ┃ Wait for the archiving workflow to finish on GitHub. ┃)
	@$(info ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛)
	sleep 2
	$(eval pid := $(shell gh run list --workflow=iga.yml --limit 1 | tail -1 | awk -F $$'\t' '{print $$7}'))
	gh run watch $(pid)

# We only do the following steps if this is software we archive in InvenioRDM.
#
# The DOI badge in README.md uses a URL that gets redirected automatically by
# InvenioRDM to the latest release. However, the DOI in CITATION.cff and the
# field relatedLink in codemeta.json need to point to the release we just made.

post-release: | update-citation-doi update-codemeta-link push-updates

update-citation-doi: vars
	@if [ -n "$(latest_doi)" ]; then
	  sed -i .bak -e '/doi:/ s|doi: .*|doi: $(latest_doi)|' CITATION.cff
	  git add CITATION.cff
	  git diff-index --quiet HEAD CITATION.cff || \
	    git commit -m"chore: update DOI in CITATION.cff" CITATION.cff
	fi

update-codemeta-link: vars
	@if [ -n "$(latest_doi)" ]; then
	  $(eval new_id   := $(shell cut -f'2' -d'/' <<< $(latest_doi)))
	  $(eval new_link := $(rdm_url)/records/$(new_id))
	  @sed -i .bak -e '/"relatedLink"/ s|: ".*"|: "$(new_link)"|' codemeta.json
	  git add codemeta.json
	  git diff-index --quiet HEAD codemeta.json || \
	    git commit -m"chore: update relatedLink in codemeta.json" codemeta.json
	fi

push-updates: vars
	@if [ -n "$(latest_doi)" ]; then
	  git push -v --all
	fi


# Cleanup ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#: Clean this directory of temporary and backup files.
clean: clean-release
	@echo 🧼 Cleaned! 🧽

clean-release:;
	rm -f *.bak $(rel_notes)


# Miscellaneous directives ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#: Print a random joke from https://icanhazdadjoke.com/.
joke:
	@echo "$(shell curl -s https://icanhazdadjoke.com/)"

# Color codes used in messages.
emph := $(shell tput bold; tput setaf 6)
bold := $(shell tput bold; tput setaf 15)
dark := $(shell tput setaf 66)
link := $(shell tput setaf 111)
norm := $(shell tput sgr0)

.PHONY: help vars report release test-branch test tests update-all \
	update-init update-meta update-citation update-example commit-updates \
	release-on-github print-instructions update-doi \
	packages test-pypi pypi clean really-clean completely-clean \
	clean-dist really-clean-dist clean-build really-clean-build \
	clean-release clean-other

.SILENT: clean clean-dist clean-build clean-release clean-other really-clean \
	really-clean-dist really-clean-build completely-clean vars
