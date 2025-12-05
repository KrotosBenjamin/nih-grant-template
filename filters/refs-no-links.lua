-- Remove hyperlinks only inside the bibliography (Div id="refs" / class "references"/"cslreferences")
local in_refs = 0

local function is_refs_div(el)
   return el.identifier == "refs"
      or el.classes:includes("references")
      or el.classes:includes("cslreferences")
      or el.classes:includes("csl-bib-body")
end

local function strip_link(l)
   if in_refs > 0 then
      return l.content -- keep visible text, drop target
   end
end

return {
   {
      Div = function(el)
         local enter = is_refs_div(el)
         if enter then in_refs = in_refs + 1 end
         if in_refs > 0 then
            el = pandoc.walk_block(el, { Link = strip_link })
         end
         if enter then in_refs = in_refs - 1 end
         return el
      end,
      Link = strip_link, -- fallback (rarely needed)
   }
}
