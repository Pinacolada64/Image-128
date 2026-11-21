-- svg-to-pdf.lua: pandoc filter for the docs' PDFs. An image docs/images/x.svg
-- becomes build/docs/images/x.pdf, which the Makefile makes from it with
-- tools/svg2pdf.rb (lualatex can't read SVG). The .md keeps the SVG for GitHub.
function Image(img)
  local name = img.src:match('^docs/images/(.+)%.svg$')
  if name then
    img.src = 'build/docs/images/' .. name .. '.pdf'
  end
  return img
end
