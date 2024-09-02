--eventually these will need to be set according to a config file
--for now, they are based on 128x acceleration

local sleepDurations = {}

sleepDurations.yield = 0    -- instant
sleepDurations.one = 128  -- a second
sleepDurations.ten = 1280   -- 10 seconds
sleepDurations.thirty = 3840 -- 30 seconds
sleepDurations.sixty = 7680  -- 60 seconds

return sleepDurations