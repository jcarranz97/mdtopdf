-- chapter-break.lua
-- Inserts a \newpage before every top-level heading except the first.
-- This gives each chapter its own page without requiring --top-level-division=chapter
-- (which needs a document class that supports \chapter{}, e.g. scrreprt or report).
-- Eisvogel hardcodes scrartcl, which only has \section{}, so we use this filter instead.

local first_header = true

function Header(el)
  if el.level == 1 then
    if first_header then
      first_header = false
      return el   -- leave the first chapter heading alone
    end
    -- insert a raw LaTeX \newpage before every subsequent chapter heading
    return {
      pandoc.RawBlock("latex", "\\newpage"),
      el,
    }
  end
end
