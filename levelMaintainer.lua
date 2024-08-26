local component = require("component")
local event = require("event")
local thread = require("thread")
local gimpHelper = require("gimpHelper")

local me = component.me_interface
local levelMaintainer = {}
local y = os.sleep -- Alias for os.sleep to keep code concise

----------------------------------------------
--- Level Maintainer Functions and Variables

local levelMaintThreads = {}
local levelMaintVars = {
    lock = { [1] = false, [2] = false, [3] = false },
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
        y(10000)
    end
end

local function lock(num)
    levelMaintVars.lock[num] = true
end

local function unlock(num)
    levelMaintVars.lock[num] = false
end

local function isItMyTurn(data)
    local myTurn = true
    for k, v in pairs(levelMaintVars) do
        y(0)
        if k ~= "lock" and k~= "levelMaintainerCpuUsage" then
            if v.enabled and v.canRun then
                if v.priority > data.priority then
                    myTurn = false
                    return myTurn
                end
            end
        end
    end
    y(0)
    return myTurn
end

local function getNumActiveCpus()
    local cpus = me.getCpus()
    local cpusInUse = 0
    for k, v in ipairs(cpus) do
        y(0)
        if v.isActive() then
            cpusInUse = cpusInUse + 1
        end
        y(0)
    end
    return cpus, cpusInUse
end

local function shouldRun(data, index)
    y(0)
    if data and data.enabled then
        y(0) 
        local craftables = me.getCraftables({label = data.itemStack.label, name = data.itemStack.name, damage = data.itemStack.damage})
        if craftables[1] then
            y(0) 
            local cpus, cpusInUse = getNumActiveCpus()
            if data.minCpu <= (#cpus - cpusInUse) then
                if levelMaintVars[index].cpusUsed and levelMaintVars[index].cpusUsed < data.maxCpu then
                    y(0)
                    local itemInStock = me.getItemsInNetwork({label = data.label, name = data.name, damage = data.damage})[1]
                    if itemInStock and itemInStock.size < data.amount then
                        levelMaintVars[index].canRun = true
                        y(10000) 
                        return true
                    end
                    levelMaintVars[index].canRun = false
                    y(15000)
                    return false
                end
            end
        end
    end
    levelMaintVars[index].canRun = false
    y(15000)
    return false
end

local function computeLevelMaintainerCpuUsage()
    y(0) 
    levelMaintVars.levelMaintainerCpuUsage = 0
    for k, v in pairs(levelMaintVars) do
        y(0) 
        if k ~= "lock" and k ~= "levelMaintainerCpuUsage" then
            if v.cpusUsed then
                levelMaintVars.levelMaintainerCpuUsage = levelMaintVars.levelMaintainerCpuUsage + v.cpusUsed
            end
        end
        y(0) 
    end
    return
end

local function craftItems(data, index)
    local tbl = {}
    local cpus, cpusInUse = getNumActiveCpus()
    levelMaintVars[index].cpusUsed = 0
    for i = 1, math.min(data.maxCpu, #cpus - cpusInUse, levelMaintVars.maxCpu - computeLevelMaintainerCpuUsage()) do
        y(0) 
        local obj = me.getCraftables({label = data.itemStack.label, name = data.itemStack.name, damage = data.itemStack.damage})[1].request(data.batch, gimp_globals.prioritize_var_Testing)
        if obj then
            print("backend - line 93: Object returned from me_interface.getCraftables")
            table.insert(tbl, obj)
            levelMaintVars[index].cpusUsed = levelMaintVars[index].cpusUsed + 1
        else
            print("backend - line 93: No object returned from me_interface.getCraftables")
            y(1000) 
            return false, tbl
        end
        y(0) 
    end
    y(5000)
    return true, tbl
end

local function saveRunningCrafts(tbl)
    if tbl and tbl[1] then
        for k, v in pairs(tbl) do
            y(0)
            table.insert(levelMaintVars.runningCrafts, tbl[k])
        end
    end
    y(0)
end

local function runLevelMaintainer(data, index)
    awaitUnlock(1)
    lock(1)
    y(0)
    if not isItMyTurn(data) then 
        y(10000)
        return 
    end
    local willRun = shouldRun(data, index)
    unlock(1)
    y(0) 
    if willRun then
        awaitUnlock(2)
        lock(2)
        y(0) 
        local success, tbl = craftItems(data, index)
        if not success then event.push("alert_notification", "alertResources") end
        saveRunningCrafts(tbl)
        unlock(2)
        y(1000) 
    else
        y(15000)
        return
    end
end

local function createLevelMaintainerThread(configs, key)
    local data = configs
    local index = key
    local levelMaintThread = thread.create(function()
        while true do
            y(0) 
            local success, error = pcall(runLevelMaintainer, data, index)
            if not success then
                print("backend - line 221/196: Error while executing runLevelMaintainer from thread: ", index, " : " .. tostring(error))
            end
            y(5000)
        end
    end)
    return levelMaintThread
end

local function getLevelMaintainerConfigs(index)
    local data = {}
    local tbl1 = gimpHelper.loadTable("/home/programData/levelMaintainer.data")
    local tbl2 = gimpHelper.loadTable("/home/programData/levelMaintainerConfig.data")
    if tbl2 and tbl2[index] and tbl2[index].enabled and tbl2[index].enabled == "true" then
        data.enabled = tbl2[index].enabled == "true"
        data.itemStack = tbl1[index].itemStack
        data.amount = tonumber(tbl1[index].amount)
        data.batch = tonumber(tbl1[index].batch)
        data.alertResources = tbl2[index].alertResources == "true"
        data.alertStalled = tbl2[index].alertStalled == "true"
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
        y(0) 
        return data
    else
        data = nil
        y(0)
        return data
    end
end

local function killOldThread(index)
    if levelMaintThreads and levelMaintThreads[index] and type(levelMaintThreads[index]) == "thread" and levelMaintThreads[index]:status() ~= "dead" then
        print("backend - line 60: Killing existing levelMaintThread", index)
        levelMaintThreads[index]:suspend()
        levelMaintThreads[index]:kill()
        levelMaintThreads[index] = nil
    end
    y(0)
end

local function setThreadState(configs, index, thr)
    if configs and configs.enabled then
        levelMaintThreads[index] = thr
        levelMaintVars[index].enabled = true
        levelMaintVars[index].priority = configs.priority
        levelMaintVars[index].minCpu = configs.minCpu
        levelMaintVars[index].maxCpu = configs.maxCpu
        levelMaintThreads[index]:resume()
    else
        levelMaintThreads[index] = nil
        levelMaintVars[index].enabled = false
    end
    y(0) 
end

local function setLevelMaintThread(_, index)
    awaitUnlock(3)
    lock(3)
    y(0)
    local configs = getLevelMaintainerConfigs(index)
    killOldThread(index)
    local thr = createLevelMaintainerThread(configs, index)
    setThreadState(configs, index, thr)
    unlock(3)
    y(0) 
end

---------------------
--- Level Maintainer Event Listener

local t = event.timer(10000, function()
    for k, v in pairs(levelMaintVars.runningCrafts) do
        y(0) 
        if v.isDone() or v.isCanceled() then
            levelMaintVars.runningCrafts[k] = nil
            table.remove(levelMaintVars.runningCrafts, k)
        elseif v.hasFailed and v.hasFailed() then
            levelMaintVars.runningCrafts[k] = nil
            table.remove(levelMaintVars.runningCrafts, k)
            print("\n \n levelMaintainer.lua - Line 255 : Craft failed but still added to runningCrafts")
            print("levelMaintainer.lua - Line 255 : It has been removed now \n \n")
        end
    end
    y(0) 
end, math.huge)

event.listen("add_level_maint_thread", setLevelMaintThread)

return levelMaintainer