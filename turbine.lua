local component = require("component")
local event = require("event")
local term = require("term")

local battery = component.gt_machine
local fuel_control = component.redstone
local gpu = component.gpu

continue = true

function catchInterrupt()
    local e = event.pull(5, "interrupted")
    if e == "interrupted" then
        print("interrupted")
        setFuel(false)
        continue = false
    end
end

function setFuel(state)
    if state then fuel_control.setOutput(1, 15)
    else fuel_control.setOutput(1, 0) end
end

function getCharge()
    return battery.getEUStored()
end

function getMaxCharge()
    return battery.getEUCapacity()
end

function enableTurbine(percentage)
    return percentage < 80
end

function drawStats(currentCharge, percentage)
    term.clear()
    term.write(string.format("%.2fM   %.1f%%", currentCharge/1000000, percentage))
    term.setCursor(1, 3)
    term.write("TURBINE ")
    if enableTurbine(percentage) then
        term.write(" ONLINE")
    else
        term.write("OFFLINE")
    end
end

gpu.setResolution(15, 3)
while(continue)
do
    local charge = getCharge()
    local percentage = charge/getMaxCharge()*100
    drawStats(charge, percentage)
    setFuel(enableTurbine(percentage))
    catchInterrupt()
end