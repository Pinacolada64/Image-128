# Makefile: the reference docs (*.md) as PDFs, through pandoc and lualatex,
# the way TADA's server/scripts/md_to_pdf.sh does it.
#
#   make docs                   every doc in DOCS, into build/docs/ (modules/TODO.md
#                               as build/docs/modules/TODO.pdf)
#   make build/docs/PORTING_NOTES.pdf   just one
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

DOCS := PORTING_NOTES.md PROGRAMMING.md DEBUG_TECHNIQUES.md \
	BASIC_VARIABLES.md SYSOP_COMMANDS.md editor.md modules/TODO.md
OUT := build/docs
PREAMBLE := tools/pdf-preamble.tex

PANDOC := pandoc
PANDOC_FLAGS := -f markdown-tex_math_dollars -t pdf --pdf-engine=lualatex \
	-V geometry:margin=1in -V colorlinks=true --toc -H $(PREAMBLE)

PDFS := $(patsubst %.md,$(OUT)/%.pdf,$(DOCS))

.PHONY: docs clean-docs

docs: $(PDFS)

$(OUT)/%.pdf: %.md $(PREAMBLE)
	@mkdir -p $(dir $@)
	@echo "Rendering $< -> $@"
	$(PANDOC) $< $(PANDOC_FLAGS) -o $@

clean-docs:
	rm -f $(PDFS)
