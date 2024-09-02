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

--[[
As part of installer process, ask if user is using the recommended slave system.
If they are, set the sleep durations using this codeblock (and the slave systems ability to actually calculate uptime).
If they are not, set the sleep durations according to a configuration file.
 ]]

--[[

print("setting sleep durations. This can take a couple minutes.")
modem.broadcast(1000, "timer_start")
local _, _, _, _, _, timer_start = event.pull("modem_message")
os.sleep(128)
modem.broadcast(1000, "timer_end")
local _, _, _, _, _, timer_end = event.pull("modem_message")

local time_elapsed = timer_end - timer_start

if time_elapsed >= 128 then
    print("Sleeps set for no Acceleration")
    print("I hope you like waiting...")
    sleepDurations.yield = 0    -- instant
    sleepDurations.one = 1  -- a second
    sleepDurations.ten = 10   -- 10 seconds
    sleepDurations.thirty = 30 -- 30 seconds
    sleepDurations.sixty = 60  -- 60 seconds
end

if time_elapsed <= 128 and time_elapsed >= 64 then
    print("Sleeps set for 2x Acceleration")
    sleepDurations.yield = 0    -- instant
    sleepDurations.one = 2  -- a second
    sleepDurations.ten = 20   -- 10 seconds
    sleepDurations.thirty = 60 -- 30 seconds
    sleepDurations.sixty = 120  -- 60 seconds
end

if time_elapsed <= 64 and time_elapsed >= 32 then
    print("Sleeps set for 4x Acceleration")
    sleepDurations.yield = 0    -- instant
    sleepDurations.one = 4  -- a second
    sleepDurations.ten = 40   -- 10 seconds
    sleepDurations.thirty = 120 -- 30 seconds
    sleepDurations.sixty = 240  -- 60 seconds
end

if time_elapsed <= 32 and time_elapsed >= 16 then
    print("Sleeps set for 8x Acceleration")
    sleepDurations.yield = 0    -- instant
    sleepDurations.one = 8  -- a second
    sleepDurations.ten = 80   -- 10 seconds
    sleepDurations.thirty = 240 -- 30 seconds
    sleepDurations.sixty = 480  -- 60 seconds
end

if time_elapsed <= 16 and time_elapsed >= 8 then
    print("Sleeps set for 16x Acceleration")
    sleepDurations.yield = 0    -- instant
    sleepDurations.one = 16  -- a second
    sleepDurations.ten = 160   -- 10 seconds
    sleepDurations.thirty = 480 -- 30 seconds
    sleepDurations.sixty = 960  -- 60 seconds
end

if time_elapsed <= 8 and time_elapsed >= 4 then
    print("Sleeps set for 32x Acceleration")
    sleepDurations.yield = 0    -- instant
    sleepDurations.one = 32  -- a second
    sleepDurations.ten = 320   -- 10 seconds
    sleepDurations.thirty = 960 -- 30 seconds
    sleepDurations.sixty = 1920  -- 60 seconds
end

if time_elapsed <= 4 and time_elapsed >= 2 then
    print("Sleeps set for 64x Acceleration")
    sleepDurations.yield = 0    -- instant
    sleepDurations.one = 64  -- a second
    sleepDurations.ten = 640   -- 10 seconds
    sleepDurations.thirty = 1920 -- 30 seconds
    sleepDurations.sixty = 3840  -- 60 seconds
end

if time_elapsed <= 2 and time_elapsed >= 1 then
    print("Sleeps set for 128x Acceleration")
    sleepDurations.yield = 0    -- instant
    sleepDurations.one = 128  -- a second
    sleepDurations.ten = 1280   -- 10 seconds
    sleepDurations.thirty = 3840 -- 30 seconds
    sleepDurations.sixty = 7680  -- 60 seconds
end

if time_elapsed <= 1 then
    print("Sleeps set for 256x Acceleration")
    sleepDurations.yield = 0    -- instant
    sleepDurations.one = 256  -- a second
    sleepDurations.ten = 2560   -- 10 seconds
    sleepDurations.thirty = 7680 -- 30 seconds
    sleepDurations.sixty = 15360  -- 60 seconds
end
]]

return sleepDurations