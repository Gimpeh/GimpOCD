-- installer.lua
local component = require("component")
local internet = require("internet")
local fs = require("filesystem")

-- Replace with your actual GitHub repo and branch
local githubUser = "Gimpeh"  -- Replace with your GitHub username
local githubRepo = "GimpOCD"  -- Replace with your GitHub repository name
local branch = "semi-stable"  -- Replace with your branch name (e.g., "main" or "master")
local libPath = "/home/lib"
local files = {
  "GimpOCD.lua",
  "PagedWindow.lua",
  "gimpHelper.lua",
  "machinesManager.lua",
  "metricsDisplays.lua",
  "overlay.lua",
  "widgetsAreUs.lua",
  "hud.lua",
  "itemWindow.lua",
  "configurations.lua",
  "backend.lua",
  "gimp_colors.lua",
  "levelMaintainer.lua",
  "sleepDurations.lua"
}

local function downloadFile(url, path)
  local f = assert(io.open(path, "wb"))
  local result, response = pcall(internet.request, url)

  if result then
    for chunk in response do
      f:write(chunk)
    end
  else
    io.stderr:write("Failed to download " .. url .. "\n")
  end

  f:close()
end

local function install()
  -- Ensure the directory exists
  if not fs.isDirectory(libPath) then
    fs.makeDirectory(libPath)
  end

  if not fs.isDirectory("/usr/bin") then
    fs.makeDirectory("/usr/bin")
  end

  for _, file in ipairs(files) do
    local url = string.format("https://raw.githubusercontent.com/%s/%s/%s/%s", githubUser, githubRepo, branch, file)
    local path = libPath .. "/" .. file  -- Save files to /home/lib
    downloadFile(url, path)
    print("Downloaded " .. file)
  end

  print("Installation complete!")
  print("Run with the command 'GimpOCD.exe' CAPITOL G!!")
  print("\n IMPORTANT: Don't forget to install battery_monitor.lua (preferable on another system)")
  print("The battery widget requires that subsystem")
  print("battery_monitor.lua is contained in the supporting systems folder of the Repo")
end

os.execute("mkdir /home/programData")
os.execute("wget https://raw.githubusercontent.com/Gimpeh/GimpOCD/semi-stable/GimpOCD.exe /usr/bin/GimpOCD.exe")
install()
os.execute("rm d")

