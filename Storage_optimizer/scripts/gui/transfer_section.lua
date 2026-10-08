--- Spodní část hlavního okna (místo nativního „Přepsat velikost štosu“): velikost stacku, počet stacků
--- posuvníkem a polem a přepínač „Přesouvat i zbytky“. Řízení signálem je v panelu „Připojení obvodu“.
local registry = require("scripts.registry")
local common = require("scripts.gui.common")

local M = {}

--- Šířka popisku řádku v pixelech (zarovnání polí pod sebou). Laditelná hodnota.
M.LABEL_WIDTH = 160

--- Přidá řádek s popiskem pevné šířky (pole se pak zarovnají pod sebou).
local function add_row(body, name, caption, tooltip)
  local row = body.add({ type = "flow", name = name, direction = "horizontal" })
  row.style.vertical_align = "center"
  local label = row.add({ type = "label", caption = caption, tooltip = tooltip })
  label.style.width = M.LABEL_WIDTH
  return row
end

--- Přidá na konec řádku číselné pole.
local function add_field(row, tooltip, action)
  row.add({ type = "textfield", name = "so_field", numeric = true, allow_decimal = false, allow_negative = false,
            style = "slider_value_textfield", tooltip = tooltip, tags = { so = action } })
end

--- Postaví část do těla okna.
--- @param max_stacks integer limit počtu stacků tieru (rozsah posuvníku)
function M.build(body, max_stacks)
  common.add_line(body)
  local batch_hint = { "storage-optimizer-gui.batch-hint" }
  local batch = add_row(body, "so_batch", { "storage-optimizer-gui.batch" }, batch_hint)
  batch.add({ type = "empty-widget" }).style.horizontally_stretchable = true
  add_field(batch, batch_hint, "batch")

  local stacks_hint = { "storage-optimizer-gui.stacks-hint", max_stacks }
  local stacks = add_row(body, "so_stacks", { "storage-optimizer-gui.stacks" }, stacks_hint)
  local slider = stacks.add({ type = "slider", name = "so_slider", minimum_value = 1, maximum_value = max_stacks,
                              value = 1, value_step = 1, discrete_values = true, style = "notched_slider",
                              tags = { so = "stacks_slider" } })
  slider.style.horizontally_stretchable = true
  add_field(stacks, stacks_hint, "stacks")

  common.add_line(body)
  body.add({ type = "checkbox", name = "so_leftovers", state = false, caption = { "storage-optimizer-gui.leftovers" },
             tooltip = { "storage-optimizer-gui.leftovers-tooltip" }, tags = { so = "leftovers" } })
end

--- Zobrazí ruční počet stacků v posuvníku i poli.
local function show_stacks(body, mover)
  local stacks = mover.stacks or 1
  body.so_stacks.so_slider.slider_value = stacks
  body.so_stacks.so_field.text = tostring(stacks)
end

--- Naplní editovatelné prvky z nastavení (jen při otevření – rozepsaný text se pak nepřepisuje).
function M.fill(body, mover)
  body.so_batch.so_field.text = mover.batch and tostring(mover.batch) or ""
  show_stacks(body, mover)
  body.so_leftovers.state = mover.leftovers == true
end

--- Obnoví zešednutí polí řízených signálem (nastavuje se v panelu „Připojení obvodu“).
function M.refresh(body, mover)
  local entity = mover.entity
  local wired = common.wired(entity)
  local behavior = entity.get_control_behavior()
  body.so_batch.so_field.enabled = not (wired and behavior and behavior.circuit_set_stack_size)
  local stacks_circuit = wired and mover.stacks_circuit == true
  body.so_stacks.so_field.enabled = not stacks_circuit
  body.so_stacks.so_slider.enabled = not stacks_circuit
end

--- Obsluha událostí podle tagu `so`.
M.handlers = {
  --- Velikost stacku: prázdné, 0 nebo nečíslo = podle materiálu.
  batch = function(event, mover)
    mover.batch = registry.clean_batch(event.element.text)
  end,
  --- Počet stacků z pole (omezený limitem tieru); posuvník se srovná.
  stacks = function(event, mover)
    mover.stacks = registry.clean_stacks(mover.entity.name, event.element.text)
    event.element.parent.so_slider.slider_value = mover.stacks or 1
  end,
  --- Počet stacků z posuvníku; pole se srovná.
  stacks_slider = function(event, mover)
    mover.stacks = registry.clean_stacks(mover.entity.name, event.element.slider_value)
    event.element.parent.so_field.text = tostring(mover.stacks or 1)
  end,
  --- Přesouvat i zbytky (neúplný přesun, když zdroj nemá celou dávku nebo cíl nemá místo).
  leftovers = function(event, mover)
    mover.leftovers = event.element.state or nil
  end,
}


return M
