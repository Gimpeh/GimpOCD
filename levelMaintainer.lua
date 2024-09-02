local component = require("component")
local event = require("event")
local thread = require("thread")
local gimpHelper = require("gimpHelper")
local s = require("serialization")

local y = os.sleep
local me = component.me_interface
local levelMaintainer = {}

-- Configurable sleep duration variables
local yieldDuration = 0    
local shortDuration = 150    
local medDuration = 500   
local longDuration = 1000 

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

local auto_unlock = {
    [1] = nil,
    [2] = nil,
    [3] = nil
}

local function awaitUnlock(num)
    while levelMaintVars.lock[num] do
        print("levelMaintainer - line 41: waiting for unlock", tostring(num))
        y(longDuration)
    end
end

local function lock(num)
    levelMaintVars.lock[num] = true
    if auto_unlock[num] then
        event.cancel(auto_unlock[num])
    end
    auto_unlock[num] = event.timer(20000, function()
        levelMaintVars.lock[num] = false
        print("levelMaintainer - line 48: levelMaintainer lock automatically unlocked", tostring(num))
    end)
    print("levelMaintainer - line 48: levelMaintainer locked", tostring(num))
    y(yieldDuration)  
end

local function unlock(num)
    levelMaintVars.lock[num] = false
    print("levelMaintainer - line 53: levelMaintainer unlocked", tostring(num))
    y(shortDuration) 
end

-------------
--- Level Maintainer Crafter Functions

local function isItMyTurn(data)
    print("levelMaintainer - line 61: Checking if it's my turn")
    local myTurn = true
    for k, v in ipairs(levelMaintVars) do
        print("levelMaintainer - line 64: Checking if it's my turn against", k)
        y(shortDuration)
        y(yieldDuration)
        if v.enabled and v.canRun then
            print("levelMaintainer - line 67: Competition Is enabled, can run")
            if v.priority > data.priority then
                print("levelMaintainer - line 69: My priority is lower than another levelMaintainer")
                y(yieldDuration)
                myTurn = false
                print("levelMaintainer - line 72: It's not my turn, returning false")
                return myTurn
            end
        end
        y(yieldDuration)  
     end
    print("levelMaintainer - line 77: It's my turn, returning true")
    return myTurn
end

local function getNumActiveCpus()
    print("levelMaintainer - line 85: Getting number of active cpus")
    local cpus = me.getCpus()
    local cpusInUse = 0
    y(yieldDuration)
    for k, v in ipairs(cpus) do
        print("levelMaintainer - line 89: Checking if cpu is active, CPU: ", k)
        if v.isActive() then
            y(yieldDuration)
            cpusInUse = cpusInUse + 1
            print("levelMaintainer - line 93: CPU is active, incrementing cpusInUse")
        end
        y(yieldDuration)
        y(shortDuration)  
    end
    print("levelMaintainer - line 97: done getting number of active cpus")
    y(shortDuration)  
    print("levelMaintainer - line 99: Returning cpus and cpusInUse")
    return cpus, cpusInUse
end

local function shouldRun(data, index)
    print("levelMaintainer - line 106: Checking if I should run", index)
    y(shortDuration) 
    if data and data.enabled then
        print("levelMaintainer - line 109: Data is enabled")
        y(yieldDuration)
        if me.getCraftables({label = data.itemStack.label, name = data.itemStack.name, damage = data.itemStack.damage})[1] then
            print("levelMaintainer - line 112: Craftables exist")
            y(yieldDuration)
            local cpus, cpusInUse = getNumActiveCpus()
            print("levelMaintainer - line 115: Got number of active cpus and cpu proxies")
            y(shortDuration)  
            if data.minCpu <= (#cpus - cpusInUse) then
                print("levelMaintainer - line 118: MinCpu is less than or equal to available cpus")
                y(yieldDuration)
                if levelMaintVars[index].cpusUsed and levelMaintVars[index].cpusUsed < data.maxCpu then
                    print("levelMaintainer - line 121: Cpus used is less than maxCpu")
                    local itemInStock = me.getItemsInNetwork({label = data.label, name = data.name, damage = data.damage})[1]
                    print("levelMaintainer - line 123: got itemstack", itemInStock.label)
                    y(shortDuration)  
                    if itemInStock and itemInStock.size < data.amount then
                        print("levelMaintainer - line 126: Item in stock is less than target amount")
                        levelMaintVars[index].canRun = true
                        y(yieldDuration)
                        print("levelMaintainer - line 129: shouldrun Returning true")
                        return true
                    else
                    print("levelMaintainer - line 132: Item in stock is greater than or equal to target amount")
                    end
                else
                print("levelMaintainer - line 134: Cpus used is greater than or equal to maxCpu")
                end
            else
            print("levelMaintainer - line 136: MinCpu is greater than available cpus")
            end
        else
        print("levelMaintainer - line 138: No craftables exist")
        end
    end
    print("levelMaintainer - line 134: shouldrun Returning false")
    levelMaintVars[index].canRun = false
    y(yieldDuration)
    return false
end

local function computeLevelMaintainerCpuUsage()
    print("levelMaintainer - line 145: Computing levelMaintainerCpuUsage")
    levelMaintVars.levelMaintainerCpuUsage = 0
    for k, v in ipairs(levelMaintVars) do
        print("levelMaintainer - line 148: Computing levelMaintainerCpuUsage for", k)
        y(shortDuration)  
        if v.cpusUsed then
            print("levelMaintainer - line 151: Adding cpusUsed to levelMaintainerCpuUsage")
            y(yieldDuration)
            levelMaintVars.levelMaintainerCpuUsage = levelMaintVars.levelMaintainerCpuUsage + v.cpusUsed
        else
        print("levelMaintainer - line 154: No cpusUsed for", k)
        end
    end
    y(medDuration)
    print("levelMaintainer - line 157: done computing levelMaintainerCpuUsage")
    return
end

local function craftItems(data, index)
    print("levelMaintainer - line 162: Crafting items")
    local tbl = {}
    local cpus, cpusInUse = getNumActiveCpus()
    print("levelMaintainer - line 165: Got number of active cpus and cpu proxies")
    y(yieldDuration)
    levelMaintVars[index].cpusUsed = 0
    print("levelMaintainer - line 168: Setting cpusUsed to 0 (precalc number)")
    for i = 1, math.min(data.maxCpu, #cpus - cpusInUse, levelMaintVars.maxCpu - computeLevelMaintainerCpuUsage()) do
        print("levelMaintainer - line 171: Initiating craft number: " .. i .. " of same recipe")
        y(yieldDuration)
        local obj = me.getCraftables({label = data.itemStack.label, name = data.itemStack.name})[1].request(data.batch, gimp_globals.prioritize_var_Testing)
        print("levelMaintainer - line 174: Craftables requested")
        y(shortDuration)
        if obj then
            print("levelMaintainer - line 177: Object returned from me_interface.getCraftables")
            table.insert(tbl, obj)
            levelMaintVars[index].cpusUsed = levelMaintVars[index].cpusUsed + 1
            print("levelMaintainer - line 180: cpusUsed incremented")
            y(yieldDuration)
        else
            print("backend - line 93: No object returned from me_interface.getCraftables")
            y(longDuration) 
            return false, tbl
        end
        y(yieldDuration) 
    end
    y(yieldDuration)
    print("levelMaintainer - line 186: Ordering Crafts done")
    return true, tbl
end

local function saveRunningCrafts(tbl)
    print("levelMaintainer - line 191: Saving running crafts")
    if tbl and tbl[1] then
        print("levelMaintainer - line 194: Running crafts exist")
        for k, v in pairs(tbl) do
            print("levelMaintainer - line 196: inserting running craft into levelMaintVars.runningCrafts")
            table.insert(levelMaintVars.runningCrafts, tbl[k])
            y(yieldDuration)
        end
        print("levelMaintainer - line 199: Running crafts saved")
    else
    print("levelMaintainer - line 201: No running crafts to save")
    end
    y(shortDuration)  
end

----------
--- Level Maintainer Thread Functions

local function getLevelMaintainerConfigs(index)
    print("levelMaintainer - line 221: Getting levelMaintainer configs")
    local data = {}
    local tbl1 = gimpHelper.loadTable("/home/programData/levelMaintainer.data")
    print("levelMaintainer - line 224: Loaded levelMaintainer.data")
    y(shortDuration)  
    local tbl2 = gimpHelper.loadTable("/home/programData/levelMaintainerConfig.data")
    print("levelMaintainer - line 227: Loaded levelMaintainerConfig.data")
    y(yieldDuration) 
    print(tbl2[index].enabled)
    if tbl2 and tbl2[index] and tbl2[index].enabled and tbl2[index].enabled == "true" then
        print("levelMaintainer - line 230: Config option enabled is true for index", index)
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
        print("levelMaintainer - line 253: Returning data")
        return data
    else
        print("levelMaintainer - line 256: Config option enabled is false for index", index)
        data = nil
        y(shortDuration) 
        return data
    end
end

local function killOldThread(index)
    if levelMaintThreads and levelMaintThreads[index] and type(levelMaintThreads[index]) == "thread" and levelMaintThreads[index]:status() ~= "dead" then
        print("levelMaintainer - line 266: Killing existing levelMaintThread", index)
        levelMaintThreads[index]:suspend()
        y(yieldDuration)
        levelMaintThreads[index]:kill()
        y(shortDuration)  
        levelMaintThreads[index] = nil
        y(yieldDuration) 
    end
end

local function setThreadState(configs, index, thr)
    print("levelMaintainer - line 276: Setting thread state")
    if configs and configs.enabled then
        print("levelMaintainer - line 279: Configs enabled is true")
        levelMaintThreads[index] = thr
        levelMaintVars[index].enabled = true
        levelMaintVars[index].priority = configs.priority  
        levelMaintVars[index].minCpu = configs.minCpu     
        levelMaintVars[index].maxCpu = configs.maxCpu    
        levelMaintThreads[index]:resume()
        y(shortDuration) 
        print("levelMaintainer - line 286: Thread state set, thread is running")
    else
        print("levelMaintainer - line 288: Configs enabled is false")
        levelMaintThreads[index] = "nil"
        levelMaintVars[index].enabled = false
        y(medDuration) 
        print("levelMaintainer - line 291: Thread state set, thread is not running")
    end
    print("levelMaintainer - line 293: Returning from setThreadState")
end

----------------------------------------------
--- Level Maintainer Main Functions

local function runLevelMaintainer(data, index)
    print("levelMaintainer - line 301: Running levelMaintainer")
    awaitUnlock(1)
    lock(1) 
    y(shortDuration) 
    if not isItMyTurn(data) then  
        unlock(1) 
        y(shortDuration) 
        return 
    end
    local willRun = shouldRun(data, index) 
    unlock(1) 
    y(shortDuration) 
    if willRun then
        awaitUnlock(2) 
        lock(2) 
        y(yieldDuration)
        local success, tbl = craftItems(data, index) 
        if not success then 
            event.push("alert_notification", "alertResources") 
        end
        saveRunningCrafts(tbl) 
        unlock(2) 
        y(yieldDuration)  
    else
        y(shortDuration)
        print("levelMaintainer - line 321: Not running, returning")
        return
    end
    print("levelMaintainer - line 324: Done running levelMaintainer")
    y(medDuration)
end

local function createLevelMaintainerThread(configs, key)
    local data = configs
    local index = key
    local levelMaintThread = thread.create(function()
        while true do
            y(yieldDuration)  
            local success, error = pcall(runLevelMaintainer, data, index)
            if not success then 
                print("backend - line 221/196: Error while executing runLevelMaintainer from thread : ", index, " : " .. tostring(error)) 
                y(longDuration) 
            end
        end
    end)
    return levelMaintThread
end

local function setLevelMaintThread(_, index)
    print("levelMaintainer - line 342: Setting levelMaintThread")
    awaitUnlock(3) 
    lock(3) 
    y(yieldDuration)
    local configs = getLevelMaintainerConfigs(index) 
    print(s.serialize(configs))
    y(yieldDuration)
    killOldThread(index) 
    y(yieldDuration)
    local thr = createLevelMaintainerThread(configs, index) 
    setThreadState(configs, index, thr) 
    unlock(3) 
    y(medDuration)  
    print("levelMaintainer - line 352: Done setting levelMaintThread")
end

---------------------
--- Level Maintainer Event Listener

local t = event.timer(10000, function()
    print("levelMaintainer - line 359: Running levelMaintainer cleanup")
    for k, v in pairs(levelMaintVars.runningCrafts) do
        print("levelMaintainer - line 361: Checking on craft: ", k)
        y(yieldDuration)
        if v.isDone() or v.isCanceled() then
            print("levelMaintainer - line 362: Craft is done or canceled")
            levelMaintVars.runningCrafts[k] = nil
            table.remove(levelMaintVars.runningCrafts, k)
        elseif v.hasFailed and v.hasFailed() then
            levelMaintVars.runningCrafts[k] = nil
            table.remove(levelMaintVars.runningCrafts, k)
            print("\n \n levelMaintainer.lua - Line 255 : Craft failed but still was added to runningCrafts")
            print("levelMaintainer.lua - Line 255 : It has been removed now \n \n")
        end
        print("levelMaintainer - line 367: Done checking on craft: ", k)
        y(yieldDuration)
    end
    print("levelMaintainer - line 370: Done running levelMaintainer cleanup")
end, math.huge)

event.listen("add_level_maint_thread", setLevelMaintThread)

return levelMaintainer
