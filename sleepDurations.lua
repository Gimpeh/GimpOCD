local computer = require("computer")
local component = require("component")
local modem = component.modem
local event = require("event")

modem.open(1000)

local sleepDurations = {}

sleepDurations.yield = 0    -- instant
sleepDurations.one = 128  -- a second
sleepDurations.ten = 1280   -- 10 seconds
sleepDurations.thirty = 3840 -- 30 seconds
sleepDurations.sixty = 7680  -- 60 seconds

return sleepDurations