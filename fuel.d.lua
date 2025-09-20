local shell = require "shell"
local thread = require "thread"

local threads = {}

function start(...)
    local proc = thread.create(shell.execute, "fuel", os.getenv("shell"), ...)
    proc:detach()
    table.insert(threads, proc)
end

function stop()
    for _, proc in ipairs(threads) do
        if proc.status and proc:status() ~= "dead" then
            proc:kill()
        end
    end
end
