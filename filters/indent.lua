-- filters/indent.lua
-- Usage in qmd: ::: {.indent width=2em} Your paragraph... :::

local function indent_div(el)
  if not el.classes:includes("indent") then return nil end
  local amt = el.attributes["width"] or "2em"

  if FORMAT:match("latex") then
    -- PDF: wrap in adjustwidth
    return {
      pandoc.RawBlock("latex", "\\begin{adjustwidth}{" .. amt .. "}{0pt}"),
      el,
      pandoc.RawBlock("latex", "\\end{adjustwidth}")
    }
  elseif FORMAT:match("html") then
    -- HTML: inline style
    local style = (el.attributes["style"] or "")
    el.attributes["style"] = style .. ";margin-left:" .. amt .. ";"
    return el
  elseif FORMAT:match("docx") then
    -- DOCX: rely on a custom style named 'Indented' with left indent set
    -- (set it once in your reference-docx)
    el.attributes["custom-style"] = el.attributes["custom-style"] or "Indented"
    return el
  end
end

return {
  { Div = indent_div }
}
