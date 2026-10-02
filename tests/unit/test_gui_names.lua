---@diagnostic disable: undefined-global
--- Jména GUI elementů nesmí kolidovat s vlastnostmi/metodami LuaGuiElement (např. "state"), jinak hra
--- spadne při vytváření panelu. Headless testy GUI netvoří (nejsou hráči), proto kontrola staticky
--- proti oficiální API dokumentaci hry. Bez dokumentace (jiná instalace) se test přeskočí.
local A = require("assert")

--- Cesta k API dokumentaci; jiná instalace hry → proměnná prostředí FACTORIO_API_JSON.
local API_JSON = os.getenv("FACTORIO_API_JSON") or "C:/STEAM/steamapps/common/Factorio/doc-html/runtime-api.json"

--- Načte celý soubor jako text (nebo nil).
local function read(path)
  local file = io.open(path, "rb")
  if not file then return nil end
  local text = file:read("a")
  file:close()
  return text
end

--- Vrátí množinu jmen uvedených v definici třídy LuaGuiElement (vlastnosti, metody, parametry).
local function reserved_names(api)
  local start = api:find('{"name":"LuaGuiElement","order"', 1, true)
  local first = api:find('"abstract":', start, true)
  local next_class = api:find('"abstract":', first + 1, true)
  local set = {}
  for name in api:sub(start, next_class):gmatch('"name":"([%w_]+)"') do set[name] = true end
  return set
end

return {
  { "jména elementů v gui.lua nekolidují s LuaGuiElement", function()
    local api = read(API_JSON)
    if not api then
      print("SKIP test_gui_names: chybí " .. API_JSON)
      return
    end
    local reserved = reserved_names(api)
    A.truthy(reserved["state"] and reserved["caption"], "seznam vlastností LuaGuiElement načten")
    local source = read("Storage_optimizer/scripts/gui.lua")
    for name in source:gmatch('name%s*=%s*"([^"]+)"') do
      A.eq(reserved[name], nil, "jméno elementu '" .. name .. "' koliduje s LuaGuiElement")
    end
  end },
}
