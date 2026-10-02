-- Headless integrační testy modu Storage_optimizer (spouští tools/run-tests.sh).
local runner = require("runner")

runner.register(require("cases.smoke"))
runner.register(require("cases.prototypes"))
runner.register(require("cases.transfer"))
runner.register(require("cases.settings"))
runner.register(require("cases.persistence"))
runner.register(require("cases.stacks"))

script.on_init(runner.on_init)
script.on_event(defines.events.on_tick, runner.on_tick)
