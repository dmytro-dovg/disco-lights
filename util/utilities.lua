local C = require "constants"

local U = {}

---@param hue number
---@return Color
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

---@class SpectrumCycle
---@field phase number
---@field duration number

---@param value number
---@param min number
---@param max number
---@return number
function U.clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

---@param tick integer
---@param cycle SpectrumCycle
---@return Color
function U.spectrum_color(tick, cycle)
    return U.hue_to_rgb((tick / (cycle.duration * 60) + cycle.phase / 360) % 1)
end

---@param color Color
---@return Color
function U.normalize_color(color)
    local r = color.r or color[1] or 0
    local g = color.g or color[2] or 0
    local b = color.b or color[3] or 0
    local a = color.a or color[4]
    if r > 1 or g > 1 or b > 1 or (a and a > 1) then
        r, g, b = r / 255, g / 255, b / 255
        a = a and a / 255
    end
    return {
        r = r,
        g = g,
        b = b,
        a = a or 1
    }
end

---@param value number
---@return integer
function U.clamp_byte(value)
    return math.max(0, math.min(255, math.floor(value + 0.5)))
end

---@param color Color
---@return Color
function U.color_to_bytes(color)
    local n = U.normalize_color(color)
    return {
        r = U.clamp_byte(n.r * 255),
        g = U.clamp_byte(n.g * 255),
        b = U.clamp_byte(n.b * 255)
    }
end

---@param r number
---@param g number
---@param b number
---@return Color
function U.color_from_bytes(r, g, b)
    return {
        r = U.clamp_byte(r) / 255,
        g = U.clamp_byte(g) / 255,
        b = U.clamp_byte(b) / 255,
        a = 1,
    }
end

---@param hex string
---@return Color
function U.hex_to_color(hex)
    local color = U.normalize_color(util.color(hex))
    color.a = 1
    return color
end

---@param color Color
---@return string
function U.color_to_hex(color)
    return string.format("%02X%02X%02X", color.r, color.g, color.b)
end

---@param text string
---@return string
function U.sanitize_hex(text)
    return text:gsub("[^%x]", ""):upper():sub(1, 6)
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
            player_object = game.get_player(player)
        else
            player_object = player
        end
        if not player_object then return end
        player_object.print(message)
    end
end

---@param list any[]
---@param value any
---@return boolean
function U.contains(list, value)
    for _, item in pairs(list) do
        if item == value then return true end
    end
    return false
end

---@param current integer
---@param delta integer
---@param total integer
---@return integer
function U.cycle_index(current, delta, total)
    return (current - 1 + delta) % total + 1
end

return U
