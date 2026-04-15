-- doc-type.lua — conditional content filter for Pandoc and Quarto
--
-- Strips fenced divs whose type classes do not match DOC_TYPE.
-- Divs with no type class are always kept.
--
-- Syntax in .md files:
--
--   ::: {.type1}
--   Only included when DOC_TYPE=type1
--   :::
--
--   ::: {.type1 .type2}
--   Included when DOC_TYPE=type1 OR DOC_TYPE=type2
--   :::
--
-- Usage:
--   export DOC_TYPE=type2
--   pandoc --lua-filter=../filters/doc-type.lua ...
--
-- If DOC_TYPE is not set, all content is kept (no filtering).

local doc_type = os.getenv("DOC_TYPE")
if doc_type then
  doc_type = doc_type:lower()
end

function Div(el)
  -- If DOC_TYPE is not set, pass everything through unchanged
  if not doc_type then
    return nil
  end

  -- Collect classes that look like a document type (typeN)
  local type_classes = {}
  for _, class in ipairs(el.classes) do
    if class:lower():match("^type%d+$") then
      table.insert(type_classes, class:lower())
    end
  end

  -- No type restriction on this div → keep it unchanged
  if #type_classes == 0 then
    return nil
  end

  -- Check whether the current DOC_TYPE is in the allowed list
  for _, t in ipairs(type_classes) do
    if t == doc_type then
      -- Match: unwrap the div and return only its inner content
      return el.content
    end
  end

  -- No match: remove this block entirely
  return {}
end
