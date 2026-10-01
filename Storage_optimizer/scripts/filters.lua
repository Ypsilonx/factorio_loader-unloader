--- Čistá logika filtrů předmětů (bez API Factoria; úrovně kvality se předávají parametrem).
local M = {}

--- Porovnání úrovní kvality podle komparátoru filtru (Factorio připouští obě varianty zápisu).
local COMPARE = {
  ["="] = function(a, b) return a == b end,
  ["!="] = function(a, b) return a ~= b end,
  ["≠"] = function(a, b) return a ~= b end,
  [">"] = function(a, b) return a > b end,
  ["<"] = function(a, b) return a < b end,
  [">="] = function(a, b) return a >= b end,
  ["≥"] = function(a, b) return a >= b end,
  ["<="] = function(a, b) return a <= b end,
  ["≤"] = function(a, b) return a <= b end,
}

--- Odpovídá předmět jednomu filtru?
local function match(filter, name, quality, levels)
  if filter.name ~= name then return false end
  if not filter.quality then return true end
  return COMPARE[filter.comparator or "="](levels[quality], levels[filter.quality])
end

--- Rozhodne, zda předmět projde sadou filtrů. Prázdná sada pustí vše.
--- @param list table[] ItemFilter bez prázdných slotů
--- @param mode string "whitelist" | "blacklist"
--- @param name string jméno předmětu
--- @param quality string jméno kvality
--- @param levels table { [kvalita] = úroveň }
--- @return boolean
function M.passes(list, mode, name, quality, levels)
  if #list == 0 then return true end
  local hit = false
  for _, filter in ipairs(list) do
    if match(filter, name, quality, levels) then
      hit = true
      break
    end
  end
  if mode == "blacklist" then return not hit end
  return hit
end

return M
