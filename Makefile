# Makefile: the reference docs (*.md) as PDFs, through pandoc and lualatex,
# the way TADA's server/scripts/md_to_pdf.sh does it.
#
#   make docs                   every doc in DOCS, into build/docs/ (one in a
#                               subdirectory under the same: modules/TODO.md as
#                               build/docs/modules/TODO.pdf; docs/ itself is
#                               left out: docs/loop-report.md is
#                               build/docs/loop-report.pdf)
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
# - docs/images/*.svg: made into vector PDFs in build/docs/images/ with
#   tools/svg2pdf.rb (the prawn-svg gem), which tools/svg-to-pdf.lua puts in
#   place of the SVGs (lualatex can't read SVG).

DOCS := PORTING_NOTES.md PROGRAMMING.md DEBUG_TECHNIQUES.md DATA_FILES.md \
	BASIC_VARIABLES.md SYSOP_COMMANDS.md STATUS_LINE.md editor.md \
	modules/TODO.md \
	docs/loop-report.md
OUT := build/docs
PREAMBLE := tools/pdf-preamble.tex

PANDOC := pandoc
PANDOC_FLAGS := -f markdown-tex_math_dollars -t pdf --pdf-engine=lualatex \
	-V geometry:margin=1in -V colorlinks=true --toc -H $(PREAMBLE) \
	--lua-filter tools/svg-to-pdf.lua

# docs/x.md goes to build/docs/x.pdf, not build/docs/docs/x.pdf
PDFS := $(patsubst %.md,$(OUT)/%.pdf,$(patsubst docs/%,%,$(DOCS)))
FIGS := $(patsubst docs/images/%.svg,$(OUT)/images/%.pdf,$(wildcard docs/images/*.svg))

.PHONY: docs clean-docs

docs: $(PDFS)

$(PDFS): $(FIGS)

$(OUT)/images/%.pdf: docs/images/%.svg tools/svg2pdf.rb
	@mkdir -p $(dir $@)
	ruby tools/svg2pdf.rb $< $@

$(OUT)/%.pdf: %.md $(PREAMBLE)
	@mkdir -p $(dir $@)
	@echo "Rendering $< -> $@"
	$(PANDOC) $< $(PANDOC_FLAGS) -o $@

$(OUT)/%.pdf: docs/%.md $(PREAMBLE)
	@mkdir -p $(dir $@)
	@echo "Rendering $< -> $@"
	$(PANDOC) $< $(PANDOC_FLAGS) -o $@

clean-docs:
	rm -f $(PDFS) $(FIGS)
