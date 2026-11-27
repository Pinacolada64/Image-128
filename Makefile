# Makefile: the reference docs (*.md) as PDFs, through pandoc and lualatex,
# the way TADA's server/scripts/md_to_pdf.sh does it.
#
#   make docs                   every doc in DOCS, into build/docs/ (one in a
#                               subdirectory under the same: modules/TODO.md as
#                               build/docs/modules/TODO.pdf; docs/ itself is
#                               left out: docs/loop-report.md is
#                               build/docs/loop-report.pdf)
#   make build/docs/PORTING_NOTES.pdf   just one
#   make manual                 the reference docs as one book,
#                               build/docs/Image128-Manual.pdf: a title page,
#                               one table of contents, each doc a chapter
#                               (MANUAL, below: the working notes, TODO, the
#                               PR catalog and the loop report, left out)
#   make clean-docs
#
# Needs pandoc, lualatex (TeX Live: fontspec, luaotfload, xcolor, colortbl,
# longtable) and the Symbola font. The ML and the modules are built by
# asm/build.sh, not here.
#
# - $ is literal (pandoc's tex_math_dollars off): BASIC names such as a$ and
#   tt$(kk), and hex such as $0af1, would otherwise start TeX maths.
# - tools/pdf-preamble.tex: Latin Modern with a Symbola fallback, for the
#   characters it lacks (arrows, check marks, box drawing), and light
#   striping on table rows.
# - tools/autowidth.lua: each table's columns as wide as their contents need
#   (pandoc would otherwise share a wide table out by the dashes in its
#   |---|---| line, and break long names and hex mid-word).

DOCS := PORTING_NOTES.md DEBUG_TECHNIQUES.md DATA_FILES.md \
	BASIC_VARIABLES.md SYSOP_COMMANDS.md STATUS_LINE.md editor.md \
	VISUAL_EDITOR.md INSTALLING.md NEW_IN_128.md KNOWN_ISSUES.md PRINT_USING.md \
	modules/TODO.md \
	docs/loop-report.md
OUT := build/docs
# PULL_REQUESTS.md: the catalog of PRs and feature branches
DOCS += PULL_REQUESTS.md
PREAMBLE := tools/pdf-preamble.tex
FILTER := tools/autowidth.lua

PANDOC := pandoc
PANDOC_FLAGS := -f markdown-tex_math_dollars -t pdf --pdf-engine=lualatex \
	-V geometry:margin=1in -V colorlinks=true --toc -H $(PREAMBLE) \
	--lua-filter=$(FILTER)

# docs/x.md goes to build/docs/x.pdf, not build/docs/docs/x.pdf
PDFS := $(patsubst %.md,$(OUT)/%.pdf,$(patsubst docs/%,%,$(DOCS)))

# 11/23/2026: the book. Each doc has one "# " heading, its chapter: what's
# new first, then setting up, the sysop's docs, the programmer's, and the
# editor's notes last.
MANUAL_DOCS := NEW_IN_128.md KNOWN_ISSUES.md INSTALLING.md SYSOP_COMMANDS.md VISUAL_EDITOR.md STATUS_LINE.md DATA_FILES.md PRINT_USING.md \
	BASIC_VARIABLES.md DEBUG_TECHNIQUES.md PORTING_NOTES.md editor.md
MANUAL := $(OUT)/Image128-Manual.pdf
MANUAL_FLAGS := -V documentclass=report --top-level-division=chapter \
	-M title="Image BBS 128" -M subtitle="Reference Manual" \
	-M date="$$(git log -1 --format=%cs 2>/dev/null || date +%F)"

# 11/26/2026: the Programmer's Reference Guide, in AsciiDoc (docs/prg-*.adoc):
# Image BBS 3.0's guide (ImageBBS3 docs/prg-*.adoc) ported to the 128 a
# chapter at a time, with what was PROGRAMMING.md (docs/prg-image128.adoc).
#   make prg     build/docs/Image128-Programmers-Reference.pdf and .html
# Needs asciidoctor and asciidoctor-pdf, the asciidoctor-lists and pygments.rb
# gems, and Python Pygments; tools/pygments has the imagebasic lexer and the
# imagebbs style, found through PYTHONPATH (as in ImageBBS3).
PRG_SRC := $(wildcard docs/prg-*.adoc docs/includes/*.adoc)
PRG_PDF := $(OUT)/Image128-Programmers-Reference.pdf
PRG_HTML := $(OUT)/Image128-Programmers-Reference.html
PRG_FLAGS := -r asciidoctor-lists -a docdate="$$(git log -1 --format=%cs 2>/dev/null || date +%F)"

.PHONY: docs manual prg clean-docs

prg: $(PRG_PDF) $(PRG_HTML)

$(PRG_PDF): $(PRG_SRC) tools/pygments/imagebbs_lexer.py
	@mkdir -p $(dir $@)
	PYTHONPATH=tools/pygments asciidoctor-pdf $(PRG_FLAGS) docs/prg-master.adoc -o $@

$(PRG_HTML): $(PRG_SRC) tools/pygments/imagebbs_lexer.py
	@mkdir -p $(dir $@)
	PYTHONPATH=tools/pygments asciidoctor $(PRG_FLAGS) docs/prg-master.adoc -o $@

manual: $(MANUAL)

$(MANUAL): $(MANUAL_DOCS) $(PREAMBLE) $(FILTER)
	@mkdir -p $(dir $@)
	@echo "Rendering the manual -> $@"
	$(PANDOC) $(MANUAL_DOCS) $(PANDOC_FLAGS) $(MANUAL_FLAGS) -o $@

docs: $(PDFS)

$(OUT)/%.pdf: %.md $(PREAMBLE) $(FILTER)
	@mkdir -p $(dir $@)
	@echo "Rendering $< -> $@"
	$(PANDOC) $< $(PANDOC_FLAGS) -o $@

$(OUT)/%.pdf: docs/%.md $(PREAMBLE) $(FILTER)
	@mkdir -p $(dir $@)
	@echo "Rendering $< -> $@"
	$(PANDOC) $< $(PANDOC_FLAGS) -o $@

clean-docs:
	rm -f $(PDFS) $(MANUAL) $(PRG_PDF) $(PRG_HTML)
