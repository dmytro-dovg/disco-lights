local R = rendering
local C = require "constants"
local U = require "util.utilities"
local Rect = require "util.rect"

---@alias SelectionType "select" | "rev-select" | "alt-select" | "alt-rev-select"

---@class DiscoLight
---@field render_objects { light_tiles: LuaRenderObject[], corners: LuaRenderObject[], }
---@field phase float
---@field duration integer
---@field rect Rect
---@field mode Mode

---@class PlayerSettings
---@field radius_index integer
---@field mode_index integer

---@class ModStorage
---@field players table<integer, PlayerSettings>
---@field lights table<integer, DiscoLight>
---@field last_id integer

---@type ModStorage
storage = storage


---@param light DiscoLight
local function destroy_light(light)
    for _, object in pairs(light.render_objects.light_tiles) do
        object.destroy()
    end
    light.render_objects.light_tiles = {}
    for _, object in pairs(light.render_objects.corners) do
        object.destroy()
    end
    light.render_objects.corners = {}
end

local function clear_lights()
    for _, light in pairs(storage.lights) do
        destroy_light(light)
    end
    storage.lights = {}
end

---@param player_index integer
---@return integer
local function current_player_radius(player_index)
    return C.radii[storage.players[player_index] and storage.players[player_index].radius_index or 1]
end

local function sprite_bands(letters, leading, trailing, radius, count)
    return {
        { letter = letters[1], center = leading - radius / 2,  scale = 1 },
        { letter = letters[2], center = leading + count / 2,   scale = count / C.tiles_per_px },
        { letter = letters[3], center = trailing + radius / 2, scale = 1 },
    }
end


---@param player_index integer
---@param rect Rect
---@param surface LuaSurface
---@param color Color
local function draw_light(player_index, rect, surface, color)
    local tiles = {}

    local left = math.floor(rect.position.x)
    local top = math.floor(rect.position.y)
    local right = math.ceil(rect.position.x + rect.size.width)
    right = math.max(right, left + 1)
    local bottom = math.ceil(rect.position.y + rect.size.height)
    bottom = math.max(bottom, top + 1)
    local width = right - left
    local height = bottom - top

    local radius = current_player_radius(player_index)
    if not radius then return end

    local horizontal_count = width
    local vertical_count = height

    local mode = "light"
    local layer = "light-effect"

    for _, row in ipairs(sprite_bands(C.sprite_row_letters, top, bottom, radius, vertical_count)) do
        for _, column in ipairs(sprite_bands(C.sprite_column_letters, left, right, radius, horizontal_count)) do
            if row.scale > 0 and column.scale > 0 then
                table.insert(tiles, R.draw_sprite {
                    sprite = C.light_sprite_prefix .. "-" .. radius .. "-" .. row.letter .. column.letter,
                    surface = surface,
                    x_scale = column.scale,
                    y_scale = row.scale,
                    render_layer = layer,
                    light_mode = mode,
                    target = { column.center, row.center, },
                    tint = color
                })
            end
        end
    end
    local corners = {}
    local corner_locations = {
        [0] = { left, top, },
        [1] = { right, top, },
        [2] = { right, bottom, },
        [3] = { left, bottom, },
    }

    for i = 0, 3, 1 do
        table.insert(corners, R.draw_sprite {
            sprite = (width == 1 or height == 1) and "disco-lights-cursor-box-5" or "disco-lights-cursor-box-6",
            surface = surface,
            target = corner_locations[i],
            light_mode = "glow",
            orientation = i * 0.25,
        })
    end
    ---@type DiscoLight
    local light = {
        mode = C.modes[storage.players[player_index].mode_index],
        render_objects = { light_tiles = tiles, corners = corners },
        rect = Rect.new(left, top, width, height),
        phase = math.random() * 2 * math.pi,
        duration = 60 + math.random() * 10 * 60
    }
    storage.lights[storage.last_id] = light
    storage.last_id = storage.last_id + 1
end


---@param event any
---@param selection_type SelectionType
local function handle_selection(event, selection_type)
    if event.item ~= "disco-lights-tool" then return end

    U.d(event.player_index, "Selection: %s", selection_type)

    local rect = Rect.from_bounding_box(event.area)

    if selection_type == "select" then -- Add light
        draw_light(event.player_index,
            rect,
            event.surface, C.selection_colors[selection_type])
    elseif selection_type == "rev-select" then -- Remove light
        local to_delete = {}
        for i, light in pairs(storage.lights) do
            if Rect.is_in_rect(light.rect, rect) then
                table.insert(to_delete, i)
            end
        end
        for _, i in pairs(to_delete) do
            destroy_light(storage.lights[i])
            storage.lights[i] = nil
        end
    else
        -- not implemented
    end
end

---@param enabled boolean
local function enable_editting(enabled)
    for _, light in pairs(storage.lights) do
        for _, corner in pairs(light.render_objects.corners) do
            if corner.valid then
                corner.visible = enabled
            end
        end
    end
end

---@param player_index integer
local function update_planner(player_index)
    local player = game.get_player(player_index)
    if not player then return end
    local cursor_stack = player.cursor_stack
    if cursor_stack and cursor_stack.valid_for_read and cursor_stack.name == "disco-lights-tool" then
        enable_editting(true)
        cursor_stack.label = "Radius: " ..
            tostring(current_player_radius(player_index) .. "\nMode: " .. C.modes[storage.players[player_index].mode_index])
    else
        enable_editting(false)
    end
end

--- Events

script.on_init(function()
    storage.lights = {}
    storage.players = {}
    storage.last_id = 1
end)

script.on_event(defines.events.on_player_joined_game, function(event)
    ---@type PlayerSettings
    local player_settings = { radius_index = 1, mode_index = 1 }
    table.insert(storage.players, player_settings)
end)

script.on_event("clear-disco-lights", function(event)
    clear_lights()
end)

script.on_nth_tick(2, function(event)
    for _, light in pairs(storage.lights) do
        if light.mode == "spectrum" then
            local base = event.tick / light.duration
            local c = U.hue_to_rgb((base + (light.phase or 0)) % 1)
            for _, object in pairs(light.render_objects.light_tiles) do
                if object.valid then object.color = c end
            end
        end
    end
end)

-- Inputs

---@param event EventData.CustomInputEvent
---@param setting_name string
---@param delta integer
---@param list any[]
local function cycle_setting_and_update(event, setting_name, delta, list)
    local player_index = event.player_index
    local settings = storage.players[player_index]
    settings[setting_name]= U.cycle_index(settings[setting_name], delta, #list)
    update_planner(player_index)
end

---@param event EventData.CustomInputEvent
script.on_event("disco-lights-tool-size-up", function(event)
    cycle_setting_and_update(event, "radius_index", 1, C.radii)
end)

---@param event EventData.CustomInputEvent
script.on_event("disco-lights-tool-size-down", function(event)
    cycle_setting_and_update(event, "radius_index", -1, C.radii)
end)

---@param event EventData.CustomInputEvent
script.on_event("disco-lights-tool-mode-up", function(event)
    cycle_setting_and_update(event, "mode_index", 1, C.modes)
end)

---@param event EventData.CustomInputEvent
script.on_event("disco-lights-tool-mode-down", function(event)
    cycle_setting_and_update(event, "mode_index", -1, C.modes)
end)

-- Selection

script.on_event(defines.events.on_player_cursor_stack_changed, function(event)
    update_planner(event.player_index)
end)

script.on_event(defines.events.on_player_selected_area, function(event)
    handle_selection(event, "select")
end)

script.on_event(defines.events.on_player_reverse_selected_area, function(event)
    handle_selection(event, "rev-select")
end)

script.on_event(defines.events.on_player_alt_selected_area, function(event)
    handle_selection(event, "alt-select")
end)

script.on_event(defines.events.on_player_alt_reverse_selected_area, function(event)
    handle_selection(event, "alt-rev-select")
end)
