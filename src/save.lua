local util = require("src.util")

local Save = {}

local SAVE_FILE = "mergeables_save.lua"

function Save.save(gameState)
    local data = util.serialize(gameState)
    local content = "return " .. data .. "\n"
    local success, err = love.filesystem.write(SAVE_FILE, content)
    if not success then
        print("Save error: " .. tostring(err))
    end
    return success
end

function Save.load()
    if not love.filesystem.getInfo(SAVE_FILE) then
        return nil
    end
    local content = love.filesystem.read(SAVE_FILE)
    if not content then return nil end

    local state, err = util.deserialize(content)
    if not state then
        print("Load error: " .. tostring(err))
        return nil
    end
    return state
end

function Save.getFileModTime()
    local info = love.filesystem.getInfo(SAVE_FILE)
    return info and info.modtime or nil
end

function Save.exists()
    return love.filesystem.getInfo(SAVE_FILE) ~= nil
end

function Save.delete()
    if Save.exists() then
        love.filesystem.remove(SAVE_FILE)
    end
end

return Save
