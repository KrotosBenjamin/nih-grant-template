-- filters/color.lua
-- Usage in qmd:
--   inline : [critical caveat]{color="#B00020"}  or  [our advantage]{color="accent"}
--   block  : ::: {color="#0B4F71"} Your paragraphs... :::
--   header : ## [Approach]{color="accent"}
--
-- Colors are either a named palette entry (below) or an arbitrary CSS-style
-- hex value (#RGB or #RRGGBB). An unrecognized value warns and renders the
-- text uncolored rather than emitting broken markup.
--
-- SINGLE SOURCE OF TRUTH: the PALETTE table is the only place named colors are
-- defined. The Meta handler injects matching \definecolor lines into the LaTeX
-- preamble, so templates/tex/preamble.tex carries no color definitions and the
-- two cannot drift apart.

-- Named palette: name -> 6 uppercase hex digits, no leading '#'.
local PALETTE = {
  accent  = "0B4F71", -- deep blue
  alert   = "B00020", -- red
  muted   = "5A6B76", -- grey
  success = "1B7A3D", -- green
}

-- #RGB or #RRGGBB -> "RRGGBB" (uppercase, no '#'); nil if malformed.
local function normalize_hex(v)
  local h = v:match("^#(%x%x%x%x%x%x)$")
  if h then return h:upper() end
  local r, g, b = v:match("^#(%x)(%x)(%x)$")
  if r then return (r .. r .. g .. g .. b .. b):upper() end
  return nil
end

-- Resolve an attribute value to {kind="named"|"hex", name=?, hex="RRGGBB"}.
local function resolve(v)
  if type(v) ~= "string" then return nil end
  v = v:gsub("^%s+", ""):gsub("%s+$", "")
  if PALETTE[v] then return { kind = "named", name = v, hex = PALETTE[v] } end
  local hex = normalize_hex(v)
  if hex then return { kind = "hex", hex = hex } end
  return nil
end

local function warn_bad(v)
  local names = {}
  for k in pairs(PALETTE) do names[#names + 1] = k end
  table.sort(names)
  io.stderr:write(string.format(
    "[color.lua] WARNING: invalid color=%q; expected #RGB, #RRGGBB, or one of: %s. Text left uncolored.\n",
    tostring(v), table.concat(names, ", ")))
end

-- xcolor needs the HTML model for literal hex, and a bare name for \definecolor'd ones.
local function tex_switch(c) -- declarative form, for wrapping blocks
  if c.kind == "named" then return "\\color{" .. c.name .. "}" end
  return "\\color[HTML]{" .. c.hex .. "}"
end

local function tex_cmd(c) -- command form, for inline spans
  if c.kind == "named" then return "\\textcolor{" .. c.name .. "}{" end
  return "\\textcolor[HTML]{" .. c.hex .. "}{"
end

local function xml_escape(s)
  return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

-- DOCX has no native color, and a reference-doc character style cannot carry an
-- arbitrary one, so we emit a raw run. LIMITATION: a raw run is plain text, so
-- nested bold/italic/links/citations inside a colored span are flattened. Warn
-- rather than dropping the formatting silently.
local function docx_run(c, inlines)
  for _, i in ipairs(inlines) do
    if i.t ~= "Str" and i.t ~= "Space" and i.t ~= "SoftBreak" then
      io.stderr:write(
        "[color.lua] NOTE: docx colored text contains nested formatting; flattening to plain text.\n")
      break
    end
  end
  return pandoc.RawInline("openxml",
    '<w:r><w:rPr><w:color w:val="' .. c.hex .. '"/></w:rPr>' ..
    '<w:t xml:space="preserve">' ..
    xml_escape(pandoc.utils.stringify(pandoc.Span(inlines))) ..
    '</w:t></w:r>')
end

-- Apply a color across a list of inlines, leaving already-colored raw runs
-- alone. Needed because pandoc walks bottom-up: by the time a colored Div sees
-- its paragraphs, any inner span/div has already become a RawInline. Collapsing
-- the whole paragraph through stringify() would erase those (stringify returns
-- "" for raw inlines), silently dropping text from the document.
local function docx_color_inlines(c, inlines)
  local out, buf = pandoc.List(), pandoc.List()
  local function flush()
    if #buf > 0 then
      out:insert(docx_run(c, buf))
      buf = pandoc.List()
    end
  end
  for _, i in ipairs(inlines) do
    if i.t == "RawInline" and i.format == "openxml" then
      flush()
      out:insert(i) -- inner color already applied; keep it verbatim
    else
      buf:insert(i)
    end
  end
  flush()
  return out
end

-- Spans inside Headers are handled here too: pandoc walks into header content,
-- so `## [Approach]{color="accent"}` needs no separate Header handler.
local function color_span(el)
  local raw = el.attributes["color"]
  if not raw then return nil end
  local c = resolve(raw)
  el.attributes["color"] = nil -- consume, so it never reaches the writer
  if not c then warn_bad(raw); return el end

  if FORMAT:match("latex") then
    local out = pandoc.List({ pandoc.RawInline("latex", tex_cmd(c)) })
    out:extend(el.content)
    out:insert(pandoc.RawInline("latex", "}"))
    return out
  elseif FORMAT:match("html") then
    el.attributes["style"] = (el.attributes["style"] or "") .. "color:#" .. c.hex .. ";"
    return el
  elseif FORMAT:match("docx") then
    return docx_run(c, el.content)
  end
end

local function color_div(el)
  local raw = el.attributes["color"]
  if not raw then return nil end
  local c = resolve(raw)
  el.attributes["color"] = nil
  if not c then warn_bad(raw); return el end

  if FORMAT:match("latex") then
    -- A brace group + \color switch, not \textcolor{}{...}: \textcolor takes its
    -- argument as a single restricted box, which breaks across \par. The group
    -- keeps every \par inside it, so paragraph breaks and lists survive.
    return {
      pandoc.RawBlock("latex", "{" .. tex_switch(c)),
      el,
      pandoc.RawBlock("latex", "}")
    }
  elseif FORMAT:match("html") then
    el.attributes["style"] = (el.attributes["style"] or "") .. "color:#" .. c.hex .. ";"
    return el
  elseif FORMAT:match("docx") then
    -- Push the color down into each block. Headers are included so DOCX matches
    -- LaTeX and HTML, where the color applies to everything in the div.
    return pandoc.walk_block(el, {
      Para   = function(p) return pandoc.Para(docx_color_inlines(c, p.content)) end,
      Plain  = function(p) return pandoc.Plain(docx_color_inlines(c, p.content)) end,
      Header = function(h) h.content = docx_color_inlines(c, h.content); return h end,
    })
  end
end

-- Emit \definecolor for the whole palette so PALETTE stays the single source.
--
-- Ordering note: `include-in-header` (preamble.tex) lands BEFORE these
-- definitions. That is fine for the commented-out colored-heading recipe in
-- preamble.tex, because \titleformat only stores {\color{accent}...} and
-- expands it at \section time, long after these lines. It would break only for
-- preamble code that expands a color name immediately (e.g. \colorlet). If you
-- ever need that, move this block statically into preamble.tex and delete this
-- handler — accepting that the palette then lives in two places.
local function inject_palette(m)
  if not FORMAT:match("latex") then return nil end
  local names = {}
  for k in pairs(PALETTE) do names[#names + 1] = k end
  table.sort(names)
  local defs = { "\\usepackage{xcolor}" }
  for _, k in ipairs(names) do
    defs[#defs + 1] = "\\definecolor{" .. k .. "}{HTML}{" .. PALETTE[k] .. "}"
  end

  local blocks = pandoc.List()
  local hi = m["header-includes"]
  if hi then
    if hi.t == "MetaList" then blocks:extend(hi) else blocks:insert(hi) end
  end
  blocks:insert(pandoc.MetaBlocks({ pandoc.RawBlock("latex", table.concat(defs, "\n")) }))
  m["header-includes"] = pandoc.MetaList(blocks)
  return m
end

return {
  { Span = color_span, Div = color_div, Meta = inject_palette }
}
