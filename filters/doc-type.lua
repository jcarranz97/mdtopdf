-- doc-type.lua — conditional content filter for Pandoc and Quarto
--
-- Filters fenced divs (block level) and inline spans whose type classes do
-- not match DOC_TYPE. Elements with no type class are always kept.
--
-- ── BLOCK-LEVEL (fenced divs) ─────────────────────────────────────────────────
--
--   ::: {.type1}
--   Only included when DOC_TYPE=type1
--   :::
--
--   ::: {.type1 .type2}
--   Included when DOC_TYPE=type1 OR DOC_TYPE=type2
--   :::
--
--   ::: {.not-type1}
--   Shown for type2, type3, … — anything that is not type1 (if/else)
--   :::
--
-- ── INLINE-LEVEL (spans — use inside table cells, headings, paragraphs) ───────
--
--   Same type and not-type classes work inside square-bracket spans:
--
--   text1[ and text2]{.type1}
--     → type1 build: "text1 and text2"
--     → type2 build: "text1"
--
--   text1[ and text2]{.not-type2}
--     → type1 build: "text1 and text2"
--     → type2 build: "text1"
--
--   Primary use-case — same table in two types, different cell content:
--
--     ::: {.type1 .type2}
--     | Setting | Value           |
--     |---------|-----------------|
--     | Mode    | basic[ and advanced]{.type1} |
--     :::
--
-- ── Rules ────────────────────────────────────────────────────────────────────
--   • An element with no type class is always kept unchanged.
--   • Include-classes (.typeN) and exclude-classes (.not-typeN) must not be
--     mixed on the same element; if they are, include-classes take precedence.
--   • If DOC_TYPE is not set, all content is kept (no filtering).
--
-- Usage:
--   export DOC_TYPE=type2
--   pandoc --lua-filter=../filters/doc-type.lua ...

local doc_type = os.getenv("DOC_TYPE")
if doc_type then
  doc_type = doc_type:lower()
end

-- Shared logic: classify classes and decide whether to keep the element.
-- Returns "keep", "remove", or "neutral" (no type classes → leave unchanged).
local function classify(classes)
  local include_types = {}
  local exclude_types = {}

  for _, class in ipairs(classes) do
    local c = class:lower()
    if c:match("^type%d+$") then
      table.insert(include_types, c)
    elseif c:match("^not%-type%d+$") then
      table.insert(exclude_types, c:sub(5))  -- "not-type1" → "type1"
    end
  end

  if #include_types == 0 and #exclude_types == 0 then
    return "neutral"
  end

  if #include_types > 0 then
    for _, t in ipairs(include_types) do
      if t == doc_type then return "keep" end
    end
    return "remove"
  end

  -- Exclude-classes only
  for _, t in ipairs(exclude_types) do
    if t == doc_type then return "remove" end
  end
  return "keep"
end

-- ── Block filter (Div) ────────────────────────────────────────────────────────

function Div(el)
  if not doc_type then return nil end

  local decision = classify(el.classes)
  if decision == "neutral" then return nil end          -- leave unchanged
  if decision == "keep"    then return el.content end   -- unwrap, keep content
  return {}                                             -- remove entirely
end

-- ── Inline filter (Span) ──────────────────────────────────────────────────────

function Span(el)
  if not doc_type then return nil end

  local decision = classify(el.classes)
  if decision == "neutral" then return nil end          -- leave unchanged
  if decision == "keep"    then return el.content end   -- unwrap, keep content
  return {}                                             -- remove entirely
end
