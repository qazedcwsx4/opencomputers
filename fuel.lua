local component = require("component")
local computer = require("computer")
local sides = require("sides")

local interface = component.me_interface
local transposer = component.transposer

function Set (list)
    local set = {}
    for _, l in ipairs(list) do set[l] = true end
    return set
end

local ALLOWED_FLUIDS_SET = Set({ "Benzene", "Naphtha", "Methane Gas", "Phenol", "Toluene", "Refinery Gas" })
local FLUIDS_TO_SIDE = {
    ["Benzene"] = sides.down, -- 5 mb
    ["Naphtha"] = sides.down, -- 5 mb
    ["Methane Gas"] = sides.east, -- 17 mb
    ["Phenol"] = sides.south, -- 6 mb
    ["Toluene"] = sides.down, -- 5 mb
    ["Refinery Gas"] = sides.west -- 11 mb
}

local FLUIDS_TO_SLOT = {
    ["Benzene"] = 0,
    ["Naphtha"] = 1,
    ["Methane Gas"] = 2,
    ["Phenol"] = 3,
    ["Toluene"] = 4,
    ["Refinery Gas"] = 5
}

local COOLDOWN_MINUTES = 5
local MIN_FLUID_VALUE = 1000

--- UTILITY CODE

function get_top_fluid_and_amount()
    local top_fluid
    local amount = MIN_FLUID_VALUE

    for _, fluid in ipairs(interface.getFluidsInNetwork()) do
        if ALLOWED_FLUIDS_SET[fluid.label] and fluid.amount > amount then
            top_fluid = fluid.label
            amount = fluid.amount
        end
    end
    return top_fluid, amount
end


function uptime_after_cooldown()
    local uptime = computer.uptime()
    return uptime + COOLDOWN_MINUTES * 60
end


function push_fluid(fluid)
    transposer.transferFluid(sides.up, FLUIDS_TO_SIDE[fluid], 1000, FLUIDS_TO_SLOT[fluid])
end



--- STATE MACHINE

---@class State
State = {}

function State:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function State:change()
    io.stderr:write("invalid state")
end

function State:output()
end

---@class EmptyState: State
EmptyState = State:new()

function EmptyState:change()
    local fluid, _ = get_top_fluid_and_amount()
    print(fluid)
    if fluid == nil then
        return self
    else
        return CooldownState:new(nil, fluid, uptime_after_cooldown())
    end
end

-- working State
WorkingState = State:new()

function WorkingState:new(o, selected_fluid)
    o = o or State:new(o)
    self.selected_fluid = selected_fluid
    setmetatable(o, self)
    self.__index = self
    return o
end

function WorkingState:change()
    local fluid, _ = get_top_fluid_and_amount()
    if fluid == nil then
        return EmptyState:new()
    elseif fluid == self.selected_fluid then
        return self
    else
        return CooldownState:new(nil, fluid, uptime_after_cooldown())
    end
end

function WorkingState:output()
    push_fluid(self.selected_fluid)
end

-- cooldown State
CooldownState = WorkingState:new()

function CooldownState:new(o, selected_fluid, cooldown_until)
    o = o or WorkingState:new(o, selected_fluid)
    setmetatable(o, self)
    self.cooldown_until = cooldown_until
    self.__index = self
    return o
end

function CooldownState:change()
    if computer.uptime() < self.cooldown_until then
        return self
    else
        return WorkingState.change()
    end
end

local state = EmptyState:new()

while true do
    state = state:change()
    state:output()
    os.sleep(1)
end
