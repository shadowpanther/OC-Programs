local component = require("component")
local event = require("event")
local fs = require("filesystem")
local keyboard = require("keyboard")
local shell = require("shell")
local term = require("term")
local text = require("text")
local unicode = require("unicode")
local sides = require("sides")
local colors=require("colors")

local gpu = component.gpu
local br = component.br_reactor
local rs = component.redstone

local maxTemp = 5500
local maxEnergy = 10000000

local running = true
local hours = 0
local mins = 0

term.clear()
term.setCursorBlink(false)
gpu.setResolution(50, 16)


-------------------------------------------------------------------------------


br.getEnergyPercent = function ()
  return math.floor(1000 * br.getEnergyStored() / maxEnergy) / 10
end


function getKey()
  return (select(4, event.pull("key_down")))
end

local function gotoXY(row, col)
  term.setCursor(col, row)
end

local function printXY(row, col, s)
  gotoXY(row, col)
  print(s)
end

local function printFXY(row, col, s, ...)
  gotoXY(row, col)
  print(s:format(...))
end

local function center(row, msg)
  local mLen = string.len(msg)
  w, h = gpu.getResolution()
  term.setCursor((w - mLen)/2,row)
  print(msg)
end

local function centerF(row, msg, ...)
  local mLen = string.len(msg)
  w, h = gpu.getResolution()
  term.setCursor((w - mLen)/2,row)
  print(msg:format(...))
end

local function warning(row, msg)
  local mLen = string.len(msg)
  w, h = gpu.getResolution()
  term.setCursor((w - mLen)/2,row)
  print(msg)
end


local controlKeyCombos = {
  [keyboard.keys.s]=true,
  [keyboard.keys.w]=true,
  [keyboard.keys.c]=true,
  [keyboard.keys.x]=true
}


local function onKeyDown(key)
  -- if key == keyboard.keys.left then
  --   br.setActive(false)
  -- elseif key == keyboard.keys.right then
  --   br.setActive(true)
  -- elseif key == keyboard.keys.up then
  --   if (rodLevel > 0) then
  --     rodLevel = rodLevel - 10
  --     br.setAllControlRodLevels(rodLevel)
  --   end
  -- elseif key == keyboard.keys.down then
  --   if (rodLevel < 100) then
  --     rodLevel = rodLevel + 10
  --     br.setAllControlRodLevels(rodLevel)
  --   end
  -- elseif key == keyboard.keys.pageDown then
  --   br.doEjectWaste()
  if key == keyboard.keys.q then
    running = false
  end
end


function log (msg)
  local stamp=ft()
  print (stamp..": "..msg)
end


function tableWidth(t)
  local width=0
  for _,v in pairs(t) do
    if #v>width then width=#v end
  end
  return width
end


function ljust(s,w)
  local pad=w-#s
  return s .. string.rep(" ",pad)
end


function rjust(s,w)
  local pad=w-#s
  return string.rep(" ",pad) .. s
end


-------------------------------------------------------------------------------


function display()
  term.clear()
  printXY(1, 1, "Reactor Status")
  printXY(2, 1, os.date())
  local funcs={"Connected","Active","NumberOfControlRods","EnergyStored","EnergyPercent","CasingTemperature","FuelTemperature","FuelAmount","WasteAmount","FuelAmountMax","EnergyProducedLastTick","FuelConsumedLastTick"}
  local units={"","","","RF","%","C","C","mB","mB","mB","RF/t","mB/t"}
  local values={}
  for _,v in pairs(funcs) do
    values[#values+1] = tostring(br["get"..v]())
  end
  local funcW=tableWidth(funcs)
  local valW=tableWidth(values)
  gotoXY(4, 1)
  for i,v in pairs(funcs) do
    print(rjust(v,funcW)..": "..rjust(values[i],valW).." "..units[i])
  end
end


while running do
  local currentEnergy = br.getEnergyStored()
  local currentEnergyPercent = math.floor(100*currentEnergy/maxEnergy)
  local reactorActive = currentEnergyPercent < 100
  local reactorEnergyLastTick = br.getEnergyProducedLastTick()
  display()
  br.setAllControlRodLevels(currentEnergyPercent)
  br.setActive(reactorActive)

  local event, address, arg1, arg2, arg3 = event.pull(1)
  if type(address) == "string" and component.isPrimary(address) then
    if event == "key_down" then
      onKeyDown(arg2)
    end
  end
end

gpu.setResolution(gpu.maxResolution())
term.clear()
term.setCursorBlink(false)