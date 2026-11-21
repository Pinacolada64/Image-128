#!/usr/bin/env ruby
# svg2pdf.rb: an SVG as a one-page vector PDF the size of the drawing, for
# the docs' PDFs (lualatex can't read SVG, and rsvg-convert isn't needed).
#
#   tools/svg2pdf.rb in.svg out.pdf
#
# Needs the prawn-svg gem (asciidoctor-pdf brings it).
require 'prawn'
require 'prawn-svg'

src, dst = ARGV
abort "usage: #{$0} in.svg out.pdf" unless src && dst
svg = File.read(src)
w, h = svg[/viewBox="([^"]+)"/, 1].split.map(&:to_f).values_at(2, 3)
Prawn::Document.generate(dst, page_size: [w, h], margin: 0) do |pdf|
  pdf.svg svg, at: [0, h], width: w
end
