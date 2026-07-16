-- filters/section-letters.lua
-- For docx output only: prefix H2 headings with A., B., C., etc.
-- Mirrors the LaTeX \Alph{subsection} numbering in 04-research-strategy.qmd,
-- which Word has no equivalent of — without this, DOCX output silently loses
-- the A./B./C. lettering reviewers expect.
--
-- Enable per-format in a section's YAML:
--   format:
--     docx:
--       filters:
--         - ../../filters/section-letters.lua

local h2_count = 0

-- 1->A ... 26->Z, then 27->AA, 28->AB (spreadsheet-style), so a section with
-- more than 26 H2s degrades sensibly instead of emitting punctuation.
local function letter_for(n)
  local s = ""
  while n > 0 do
    local rem = (n - 1) % 26
    s = string.char(65 + rem) .. s
    n = (n - 1 - rem) / 26
  end
  return s
end

local function label_h2(el)
  if not FORMAT:match("docx") then return nil end
  if el.level ~= 2 then return nil end
  h2_count = h2_count + 1
  table.insert(el.content, 1, pandoc.Str(letter_for(h2_count) .. ". "))
  return el
end

-- Two passes, in order: the reset must land before any Header is seen. Within a
-- single filter table pandoc applies Pandoc last (it's the outermost element),
-- which would reset the counter after the headers had already been numbered.
return {
  { Pandoc = function(doc) h2_count = 0; return doc end },
  { Header = label_h2 },
}
