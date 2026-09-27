local C = require "constants"

local U = {}

function U.hue_to_rgb(hue)
    local i = math.floor(hue * 6)
    local f = hue * 6 - i
    local q, t = 1 - f, f
    i = i % 6
    if i == 0 then
        return { r = 1, g = t, b = 0, }
    elseif i == 1 then
        return { r = q, g = 1, b = 0, }
    elseif i == 2 then
        return { r = 0, g = 1, b = t, }
    elseif i == 3 then
        return { r = 0, g = q, b = 1, }
    elseif i == 4 then
        return { r = t, g = 0, b = 1, }
    else
        return { r = 1, g = 0, b = q, }
    end
end

---@param player number?|LuaPlayer?
---@param msg string
---@vararg any
function U.d(player, msg, ...)
    if not C.debug.logging_enabled then return end
    local message = "[disco-lights]: " .. string.format(msg, ...)
    localised_print(message)
    if C.debug.log_in_game then
        ---@type LuaPlayer?
        local player_object
        if type(player) == "number" then
            player_object = game.get_player(player).print(message)
        else
            player_object = player
        end
        if not player_object then return end
        player_object.print(message)
    end
end

function U.cycle_index(current, delta, total)
    return (current - 1 + delta) % total + 1
end

return U
