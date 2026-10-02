---@diagnostic disable: undefined-global
--- Runner jednotkových testů čisté Lua logiky modu (spouští se z kořene repozitáře: lua tests/unit/run.lua).
package.path = "Storage_optimizer/?.lua;tests/unit/?.lua;" .. package.path

--- Seznam testovacích sad; každá vrací pole { "název", funkce }.
local SUITES = { "test_tiers", "test_filters", "test_locale", "test_graphics", "test_gui_names", "test_wires", "test_icons", "test_gui", "test_research" }

local pass, fail = 0, 0
for _, suite in ipairs(SUITES) do
  for _, case in ipairs(require(suite)) do
    local ok, err = pcall(case[2])
    if ok then
      pass = pass + 1
    else
      fail = fail + 1
      print("FAIL " .. suite .. " :: " .. case[1] .. ": " .. tostring(err))
    end
  end
end
print(string.format("UNIT pass=%d fail=%d", pass, fail))
os.exit(fail == 0 and 0 or 1)
