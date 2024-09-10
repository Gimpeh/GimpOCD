local component = require("component")
local event = require("event")
local thread = require("thread")
local gimpHelper = require("gimpHelper")
local s = require("serialization")
local sleeps = require("sleepDurations")

local me = component.me_interface
local levelMaintainer = {}

local unlock_timer = false

local verbosity = true
local print = print

if not verbosity then
    print = function()
        return false
    end
end

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
        print("levelMaintainer - line 41: waiting for unlock", tostring(num))
        os.sleep(sleeps.thirty)
    end
end

local function unlock(num)
    levelMaintVars.lock[num] = false
    print("levelMaintainer - line 53: levelMaintainer unlocked", tostring(num))
    os.sleep(sleeps.ten) 
end

local function lock(num)
    unlock_timer = thread.create(function()
        for j = 1, 100 do
            y(200)
            if not levelMaintVars.lock[num] then
                return
            end
        end
        unlock(num)
    end)
    levelMaintVars.lock[num] = true
    unlock_timer:detach()
    unlock_timer:resume()
   os.sleep(sleeps.yield)
end

-------------
--- Level Maintainer Crafter Functions

local function isItMyTurn(data)
    print("levelMaintainer - line 61: Checking if it's my turn")
    local myTurn = true
    for k, v in ipairs(levelMaintVars) do
        print("levelMaintainer - line 64: Checking if it's my turn against", k)
        os.sleep(sleeps.ten)
       os.sleep(sleeps.yield)
        if v.enabled and v.canRun then
            print("levelMaintainer - line 67: Competition Is enabled, can run")
            if v.priority > data.priority then
                print("levelMaintainer - line 69: My priority is lower than another levelMaintainer")
               os.sleep(sleeps.yield)
                myTurn = false
                print("levelMaintainer - line 72: It's not my turn, returning false")
                return myTurn
            end
        end
       os.sleep(sleeps.yield)  
     end
    print("levelMaintainer - line 77: It's my turn, returning true")
    return myTurn
end

local function getNumActiveCpus()
    print("levelMaintainer - line 85: Getting number of active cpus")
    local cpus = me.getCpus()
    local cpusInUse = 0
   os.sleep(sleeps.yield)
    for k, v in ipairs(cpus) do
        print("levelMaintainer - line 89: Checking if cpu is active, CPU: ", k)
        if v.cpu.isBusy() then
           os.sleep(sleeps.yield)
            cpusInUse = cpusInUse + 1
            print("levelMaintainer - line 93: CPU is active, incrementing cpusInUse")
        end
       os.sleep(sleeps.yield)
        os.sleep(sleeps.ten)  
    end
    print("levelMaintainer - line 97: done getting number of active cpus")
    os.sleep(sleeps.ten)  
    print("levelMaintainer - line 99: Returning cpus and cpusInUse")
    return cpus, cpusInUse
end

local function shouldRun(data, index)
    print("levelMaintainer - line 106: Checking if I should run", index)
    os.sleep(sleeps.ten)
    if data and data.enabled then
        print("levelMaintainer - line 109: Data is enabled")
       os.sleep(sleeps.yield)
        if me.getCraftables({label = data.itemStack.label, name = data.itemStack.name, damage = data.itemStack.damage})[1] then
            print("levelMaintainer - line 112: Craftables exist")
           os.sleep(sleeps.yield)
            local cpus, cpusInUse = getNumActiveCpus()
            print("levelMaintainer - line 115: Got number of active cpus and cpu proxies")
            os.sleep(sleeps.ten)  
            if data.minCpu <= (#cpus - cpusInUse) then
                print("levelMaintainer - line 118: MinCpu is less than or equal to available cpus")
               os.sleep(sleeps.yield)
                if levelMaintVars[index].cpusUsed and levelMaintVars[index].cpusUsed < data.maxCpu then
                    print("levelMaintainer - line 121: Cpus used is less than maxCpu")
                    local itemInStock = me.getItemsInNetwork({label = data.itemStack.label, name = data.itemStack.name, damage = data.itemStack.damage})[1]
                    print("levelMaintainer - line 123: got itemstack", itemInStock.label)
                    os.sleep(sleeps.ten)  
                    if itemInStock and itemInStock.size < data.amount then
                        print("levelMaintainer - line 126: Item in stock is less than target amount")
                        levelMaintVars[index].canRun = true
                       os.sleep(sleeps.yield)
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
   os.sleep(sleeps.yield)
    return false
end

local function computeLevelMaintainerCpuUsage()
    print("levelMaintainer - line 145: Computing levelMaintainerCpuUsage")
    levelMaintVars.levelMaintainerCpuUsage = 0
    for k, v in ipairs(levelMaintVars) do
        print("levelMaintainer - line 148: Computing levelMaintainerCpuUsage for", k)
        os.sleep(sleeps.ten)  
        if v.cpusUsed then
            print("levelMaintainer - line 151: Adding cpusUsed to levelMaintainerCpuUsage")
           os.sleep(sleeps.yield)
            levelMaintVars.levelMaintainerCpuUsage = levelMaintVars.levelMaintainerCpuUsage + v.cpusUsed
        else
        print("levelMaintainer - line 154: No cpusUsed for", k)
        end
    end
    os.sleep(sleeps.ten)
    print("levelMaintainer - line 157: done computing levelMaintainerCpuUsage")
    return levelMaintVars.levelMaintainerCpuUsage
end

local function craftItems(data, index)
    print("levelMaintainer - line 162: Crafting items")
    local tbl = {}
    local cpus, cpusInUse = getNumActiveCpus()
    print("levelMaintainer - line 165: Got number of active cpus and cpu proxies")
   os.sleep(sleeps.yield)
    levelMaintVars[index].cpusUsed = 0
    print("levelMaintainer - line 168: Setting cpusUsed to 0 (precalc number)")
    for i = 1, math.min(data.maxCpu, #cpus - cpusInUse, levelMaintVars.maxCpu - computeLevelMaintainerCpuUsage()) do
        print("levelMaintainer - line 171: Initiating craft number: " .. i .. " of same recipe")
       os.sleep(sleeps.yield)
        local obj = me.getCraftables({label = data.itemStack.label, name = data.itemStack.name})[1].request(data.batch)
        print("levelMaintainer - line 174: Craftables requested")
        os.sleep(sleeps.ten)
        if obj then
            obj.itemLabel = data.itemStack.label
            print("levelMaintainer - line 177: Object returned from me_interface.getCraftables")
            table.insert(tbl, obj)
            if obj.hasFailed and obj.hasFailed() then
                if data.alertResources then
                    event.push("alert_notification", "alertResources", data.itemStack.label)
                end
                return
            end
            levelMaintVars[index].cpusUsed = levelMaintVars[index].cpusUsed + 1
            print("levelMaintainer - line 180: cpusUsed incremented")
           os.sleep(sleeps.yield)
            --[[for key, cpu in ipairs(cpus) do
                if cpu.cpu.finalOutput().label == data.itemStack.label then
                    if not cpu.cpu.activeItems()[1] then
                        event.push("alert_notification", "alertStalled", data.itemStack.label)
                    end
                end
            end]]
        else
            if data.alertResources then
                event.push("alert_notification", "alertResources", data.itemStack.label)
            end
            print("backend - line 93: No object returned from me_interface.getCraftables")
            os.sleep(sleeps.thirty) 
            return false, tbl
        end
       os.sleep(sleeps.yield) 
    end
   os.sleep(sleeps.yield)
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
           os.sleep(sleeps.yield)
        end
        print("levelMaintainer - line 199: Running crafts saved")
    else
    print("levelMaintainer - line 201: No running crafts to save")
    end
    os.sleep(sleeps.ten)  
end

----------
--- Level Maintainer Thread Functions

local function getLevelMaintainerConfigs(index)
    print("levelMaintainer - line 221: Getting levelMaintainer configs")
    local data = {}
    local tbl1 = gimpHelper.loadTable("/home/programData/levelMaintainer.data")
    print("levelMaintainer - line 224: Loaded levelMaintainer.data")
    os.sleep(sleeps.ten)
    local tbl2 = gimpHelper.loadTable("/home/programData/levelMaintainerConfig.data")
    print("levelMaintainer - line 227: Loaded levelMaintainerConfig.data")
   os.sleep(sleeps.yield) 
    print(tbl2[index].enabled)
    if tbl2 and tbl2[index] and tbl2[index].enabled and tbl2[index].enabled == "true" then
        print("levelMaintainer - line 230: Config option enabled is true for index", index)
        data.enabled = tbl2[index].enabled == "true"
        data.itemStack = tbl1[index].itemStack
        data.amount = tonumber(tbl1[index].amount)
        data.batch = tonumber(tbl1[index].batch)
        data.alertResources = tbl2[index].alertResources == "true"
        data.alertStalled = tbl2[index].alertStalled == "true"
       os.sleep(sleeps.yield)
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
        os.sleep(sleeps.ten) 
        print("levelMaintainer - line 253: Returning data")
        return data
    else
        print("levelMaintainer - line 256: Config option enabled is false for index", index)
        data = nil
        os.sleep(sleeps.ten) 
        return data
    end
end

local function killOldThread(index)
    print("levelMaintainer - line 263: attempting to Kill old thread")
    if levelMaintThreads and levelMaintThreads[index] and levelMaintThreads[index] ~= "nil" then
        print("levelMaintainer - line 266: Killing existing levelMaintThread", index)
        levelMaintThreads[index]:suspend()
       os.sleep(sleeps.yield)
        levelMaintThreads[index]:kill()
        os.sleep(sleeps.ten)  
        levelMaintThreads[index] = nil
       os.sleep(sleeps.yield) 
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
        os.sleep(sleeps.ten) 
        print("levelMaintainer - line 286: Thread state set, thread is running")
    else
        print("levelMaintainer - line 288: Configs enabled is false")
        levelMaintThreads[index] = "nil"
        levelMaintVars[index].enabled = false
        os.sleep(sleeps.ten)
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
    os.sleep(sleeps.ten) 
    if not isItMyTurn(data) then  
        unlock(1) 
        os.sleep(sleeps.ten) 
        return 
    end
    local willRun = shouldRun(data, index) 
    unlock(1) 
    os.sleep(sleeps.ten) 
    if willRun then
        awaitUnlock(2) 
        lock(2) 
       os.sleep(sleeps.yield)
        local success, tbl = craftItems(data, index) 
        if not success then 
            event.push("alert_notification", "alertResources") 
        end
        saveRunningCrafts(tbl) 
        unlock(2) 
       os.sleep(sleeps.yield)  
    else
        os.sleep(sleeps.ten)
        print("levelMaintainer - line 321: Not running, returning")
        return
    end
    print("levelMaintainer - line 324: Done running levelMaintainer")
    os.sleep(sleeps.ten)
end

local function createLevelMaintainerThread(configs, key)
    local data = configs
    local index = key
    if data and data.enabled then
        local levelMaintThread = thread.create(function()
            while true do
                os.sleep(sleeps.ten)
                print("levelMaintainer - line 334: Running levelMaintThread")
                runLevelMaintainer(data, index)
            end
        end)
        return levelMaintThread
    else 
        return nil
    end
end

local function setLevelMaintThread(_, index)
    print("levelMaintainer - line 342: Setting levelMaintThread")
    awaitUnlock(3) 
    lock(3) 
   os.sleep(sleeps.yield)
    local configs = getLevelMaintainerConfigs(index) 
    print(s.serialize(configs))
   os.sleep(sleeps.yield)
    killOldThread(index) 
   os.sleep(sleeps.yield)
    local thr = createLevelMaintainerThread(configs, index) 
    setThreadState(configs, index, thr) 
    unlock(3)
    os.sleep(sleeps.ten)
    print("levelMaintainer - line 352: Done setting levelMaintThread")
end

---------------------
--- Level Maintainer Event Listener

local function cleanup()
    while true do
        os.sleep(sleeps.thirty)
        print("levelMaintainer - line 359: Running levelMaintainer cleanup")
        for k, v in ipairs(levelMaintVars.runningCrafts) do
            print("levelMaintainer - line 361: Checking on craft: ", k)
           os.sleep(sleeps.yield)
            if v.isDone() or v.isCanceled() then
                print("levelMaintainer - line 362: Craft is done or canceled")
                table.remove(levelMaintVars.runningCrafts, k)
                levelMaintVars.runningCrafts[k] = nil
            elseif v.hasFailed and v.hasFailed() then
                table.remove(levelMaintVars.runningCrafts, k)
                levelMaintVars.runningCrafts[k] = nil
                print("\n \n levelMaintainer.lua - Line 255 : Craft failed but still was added to runningCrafts")
                print("levelMaintainer.lua - Line 255 : It has been removed now \n \n")
            else
                local cpus = me.getCpus()
                for key, cpu in ipairs(cpus) do
                    if cpu.cpu.finalOutput().label == v.itemLabel then
                        if not cpu.cpu.activeItems()[1] then
                            event.push("alert_notification", "alertStalled", v.itemLabel)
                        end
                    end
                end
            end
            print("levelMaintainer - line 367: Done checking on craft: ", k)
           os.sleep(sleeps.yield)
        end
        print("levelMaintainer - line 370: Done running levelMaintainer cleanup")
    end
end

local cleanup_thread = thread.create(cleanup)
cleanup_thread:detach()
cleanup_thread:resume()

event.listen("configs_updated", function()
    local configs = gimpHelper.loadTable("/home/programData/generalConfigs.data")
    if not configs and configs.maxCpusAllLevelMaintainers then
        return
    end
    levelMaintVars.maxCpu = tonumber(configs.maxCpusAllLevelMaintainers)
end)
event.listen("add_level_maint_thread", setLevelMaintThread)

return levelMaintainer
