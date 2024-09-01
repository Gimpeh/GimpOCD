local component = require("component")
local event = require("event")
local thread = require("thread")
local gimpHelper = require("gimpHelper")

local y = os.sleep
local me = component.me_interface
local levelMaintainer = {}

-- Configurable sleep duration variables
local yieldDuration = 0    
local shortDuration = 1500    
local medDuration = 5000   
local longDuration = 10000 

----------------------------------------------
--- Level Maintainer Functions and Variables

local levelMaintThreads = {}
local levelMaintVars = {
    lock = {
        [1] = false, 
        [2] = false, 
        [3] = false
    },
    levelMaintainerCpuUsage = 1,
    maxCpu = 1,
    runningCrafts = {},
    [1] = {
        enabled = nil,
        priority = nil,
        minCpu = nil,
        maxCpu = nil,
        canRun = false,
        cpusUsed = 0
    }
}

local function awaitUnlock(num)
    while levelMaintVars.lock[num] do
        print("backend - line 58: levelMaintainer locked")
        y(longDuration)
    end
end

local function lock(num)
    levelMaintVars.lock[num] = true
    y(yieldDuration)  
end

local function unlock(num)
    levelMaintVars.lock[num] = false
    y(shortDuration) 
end

-------------
--- Level Maintainer Crafter Functions

local function isItMyTurn(data)
    local myTurn = true
    for k, v in pairs(levelMaintVars) do
        y(shortDuration) 
        if k ~= "lock" and k ~= "levelMaintainerCpuUsage" then
            y(yieldDuration)
            if v.enabled and v.canRun then
                if v.priority > data.priority then
                    y(yieldDuration)
                    myTurn = false
                    return myTurn
                end
            end
        end
        y(yieldDuration)  
     end
    return myTurn
end

local function getNumActiveCpus()
    local cpus = me.getCpus()
    local cpusInUse = 0
    y(yieldDuration)
    for k, v in ipairs(cpus) do
        if v.isActive() then
            y(yieldDuration)
            cpusInUse = cpusInUse + 1
        end
        y(yieldDuration)
        y(shortDuration)  
    end
    y(shortDuration)  
    return cpus, cpusInUse
end

local function shouldRun(data, index)
    y(shortDuration) 
    if data and data.enabled then
        y(yieldDuration)
        if me.getCraftables({label = data.itemStack.label, name = data.itemStack.name, damage = data.itemStack.damage})[1] then
            y(yieldDuration)
            local cpus, cpusInUse = getNumActiveCpus() --80
            y(shortDuration)  
            if data.minCpu <= (#cpus - cpusInUse) then
                y(yieldDuration)
                if levelMaintVars[index].cpusUsed and levelMaintVars[index].cpusUsed < data.maxCpu then
                    local itemInStock = me.getItemsInNetwork({label = data.label, name = data.name, damage = data.damage})[1]
                    y(shortDuration)  
                    if itemInStock and itemInStock.size < data.amount then
                        levelMaintVars[index].canRun = true
                        y(yieldDuration)
                        return true
                    end
                    levelMaintVars[index].canRun = false
                    y(yieldDuration)
                    return false
                end
                levelMaintVars[index].canRun = false
                y(medDuration)  
                return false
            end
            levelMaintVars[index].canRun = false
            y(medDuration)  
            return false
        end
        levelMaintVars[index].canRun = false
        y(yieldDuration)
        return false
    end
    levelMaintVars[index].canRun = false
    y(yieldDuration)
    return false
end

local function computeLevelMaintainerCpuUsage()
    levelMaintVars.levelMaintainerCpuUsage = 0
    for k, v in pairs(levelMaintVars) do
        y(shortDuration)  
        if k ~= "lock" and k ~= "levelMaintainerCpuUsage" then
            if v.cpusUsed then
                y(yieldDuration)
                levelMaintVars.levelMaintainerCpuUsage = levelMaintVars.levelMaintainerCpuUsage + v.cpusUsed
            end
        end
    end
    y(medDuration)
    return
end

local function craftItems(data, index)
    local tbl = {}
    local cpus, cpusInUse = getNumActiveCpus() --80
    y(yieldDuration)
    levelMaintVars[index].cpusUsed = 0
    for i = 1, math.min(data.maxCpu, #cpus - cpusInUse, levelMaintVars.maxCpu - computeLevelMaintainerCpuUsage()) do --135
        y(yieldDuration)
        local obj = me.getCraftables({label = data.itemStack.label, name = data.itemStack.name, damage = data.itemStack.damage})[1].request(data.batch, gimp_globals.prioritize_var_Testing)
        y(shortDuration) 
        if obj then
            print("backend - line 93: Object returned from me_interface.getCraftables")
            table.insert(tbl, obj)
            levelMaintVars[index].cpusUsed = levelMaintVars[index].cpusUsed + 1
            y(yieldDuration)
        else
            print("backend - line 93: No object returned from me_interface.getCraftables")
            y(longDuration) 
            return false, tbl
        end
        y(yieldDuration) 
    end
    y(yieldDuration)
    return true, tbl
end

local function saveRunningCrafts(tbl)
    if tbl and tbl[1] then
        for k, v in pairs(tbl) do
            table.insert(levelMaintVars.runningCrafts, tbl[k])
            y(yieldDuration)
        end
    end
    y(shortDuration)  
end

----------
--- Level Maintainer Thread Functions

local function getLevelMaintainerConfigs(index)
    local data = {}
    local tbl1 = gimpHelper.loadTable("/home/programData/levelMaintainer.data")
    y(shortDuration)  
    local tbl2 = gimpHelper.loadTable("/home/programData/levelMaintainerConfig.data")
    y(yieldDuration) 
    if tbl2 and tbl2[index] and tbl2[index].enabled and tbl2[index].enabled == "true" then
        data.enabled = tbl2[index].enabled == "true"
        data.itemStack = tbl1[index].itemStack
        data.amount = tonumber(tbl1[index].amount)
        data.batch = tonumber(tbl1[index].batch)
        data.alertResources = tbl2[index].alertResources == "true"
        data.alertStalled = tbl2[index].alertStalled == "true"
        y(yieldDuration)
        if tbl2[index].maxCpu and type(tonumber(tbl2[index].maxCpu)) == "number" then
            data.maxCpu = tonumber(tbl2[index].maxCpu)
        else
            data.maxCpu = 1
        end
        if tbl2[index].priority and type(tonumber(tbl2[index].priority)) == "number" then
            data.priority = tonumber(tbl2[index].priority)
        else
            data.priority = 0
        end
        if tbl2[index].minCpu and type(tonumber(tbl2[index].minCpu)) == "number" then
            data.minCpu = tonumber(tbl2[index].minCpu)
        else
            data.minCpu = 1
        end
        y(shortDuration) 
        return data
    else
        data = nil
        y(shortDuration) 
        return data
    end
end

local function killOldThread(index)
    if levelMaintThreads and levelMaintThreads[index] and type(levelMaintThreads[index]) == "thread" and levelMaintThreads[index]:status() ~= "dead" then
        print("backend - line 60: Killing existing levelMaintThread", index)
        levelMaintThreads[index]:suspend()
        y(yieldDuration)
        levelMaintThreads[index]:kill()
        y(shortDuration)  
        levelMaintThreads[index] = nil
        y(yieldDuration) 
    end
end

local function setThreadState(configs, index, thr)
    if configs and configs.enabled then
        levelMaintThreads[index] = thr
        levelMaintVars[index].enabled = true
        levelMaintVars[index].priority = configs.priority  
        levelMaintVars[index].minCpu = configs.minCpu     
        levelMaintVars[index].maxCpu = configs.maxCpu    
        levelMaintThreads[index]:resume()
        y(shortDuration) 
    else
        levelMaintThreads[index] = nil
        levelMaintVars[index].enabled = false
        y(medDuration) 
    end
end

----------------------------------------------
--- Level Maintainer Main Functions

local function runLevelMaintainer(data, index)
    awaitUnlock(1) --41
    lock(1) --48
    y(shortDuration) 
    if not isItMyTurn(data) then  --61
        unlock(1) --53
        y(shortDuration) 
        return 
    end
    local willRun = shouldRun(data, index) --96
    unlock(1) --53
    y(shortDuration) 
    if willRun then
        awaitUnlock(2) --41
        lock(2) --48
        y(yieldDuration)
        local success, tbl = craftItems(data, index) --150
        if not success then 
            event.push("alert_notification", "alertResources") 
        end
        saveRunningCrafts(tbl) --175
        unlock(2) --53
        y(yieldDuration)  
    else
        y(shortDuration) 
        return
    end
    y(medDuration)
end

local function createLevelMaintainerThread(configs, key)
    local data = configs
    local index = key
    local levelMaintThread = thread.create(function()
        while true do
            y(yieldDuration)  
            local success, error = pcall(runLevelMaintainer, data, index) --257
            if not success then 
                print("backend - line 221/196: Error while executing runLevelMaintainer from thread : ", index, " : " .. tostring(error)) 
                y(longDuration) 
            end
        end
    end)
    return levelMaintThread
end

local function setLevelMaintThread(_, index)
    awaitUnlock(3) --41
    lock(3) --48
    y(yieldDuration)
    local configs = getLevelMaintainerConfigs(index) --188
    y(yieldDuration)
    killOldThread(index) --226
    y(yieldDuration)
    local thr = createLevelMaintainerThread(configs, index) --288
    setThreadState(configs, index, thr) --238
    unlock(3) --53
    y(medDuration)  
end

---------------------
--- Level Maintainer Event Listener

local t = event.timer(10000, function()
    for k, v in pairs(levelMaintVars.runningCrafts) do
        y(yieldDuration)
        if v.isDone() or v.isCanceled() then
            levelMaintVars.runningCrafts[k] = nil
            table.remove(levelMaintVars.runningCrafts, k)
        elseif v.hasFailed and v.hasFailed() then
            levelMaintVars.runningCrafts[k] = nil
            table.remove(levelMaintVars.runningCrafts, k)
            print("\n \n levelMaintainer.lua - Line 255 : Craft failed but still added to runningCrafts")
            print("levelMaintainer.lua - Line 255 : It has been removed now \n \n")
        end
        y(yieldDuration)
    end
end, math.huge)

event.listen("add_level_maint_thread", setLevelMaintThread)

return levelMaintainer
