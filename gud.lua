local internet = require("internet")
local computer = require("computer")

local CONFIG_PATH = "/etc/rc.cfg"
local GITHUB_PATH = "https://raw.githubusercontent.com/qazedcwsx4/opencomputers/refs/heads/master/"
local TEMPLATES_GH_SUBPATH = "templates/"
local DAEMON_GH_SUBPATH = "daemons/"
local DAEMON_SYSTEM_PATH = "/etc/rc.d/"


local function usage()
    print("Usage: gud <config>")
end

-- Get a file from the repo and return it as string
local function get_file(filename)
    local handle = internet.request(GITHUB_PATH .. filename)
    local result = ""
    for chunk in handle do result = result..chunk end
    return result
end

local function update_config(config)
    local config_file = io.open(CONFIG_PATH)
    config_file:write(config)
    config_file:close()
end

local function download_daemon(daemon_name)
    local daemon_string = get_file(DAEMON_GH_SUBPATH .. daemon_name .. ".lua")
    local daemon_path = DAEMON_SYSTEM_PATH .. daemon_name .. ".lua"
    config_file = io.open(daemon_path)
    config_file:write(daemon_string)
    config_file:close()
end

local function download_enabled(enabled_list)
    for _, daemon in ipairs(enabled_list) do
        download_daemon(daemon)
    end
end


-- main
local args = {...}
if #args == 0 then
    usage()
    return 1
end

local config_name = args[1]
local config_str = get_file(TEMPLATES_GH_SUBPATH .. config_name)

-- expect `enabled` list
local config = load(config_str)
download_enabled(config.enabled)
update_config(config_str)

-- restart computer
computer.shutdown(true)