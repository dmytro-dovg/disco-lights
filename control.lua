local R = rendering
local C = require "constants"
local U = require "util.utilities"
local Rect = require "util.rect"
local ColorPickerGui = require "gui.color-picker-gui"

---@alias SelectionType "select"|"rev-select"|"alt-select"|"alt-rev-select"|"super-select"

---@class DiscoLight
---@field render_objects { light_tiles: LuaRenderObject[], corners: LuaRenderObject[], edit_gui: LuaRenderObject[], map_shapes: LuaRenderObject[] }
---@field surface LuaSurface
---@field color Color?
---@field phase float
---@field duration integer
---@field rect Rect
---@field mode Mode

---@class PlayerSettings
---@field radius_index integer
---@field mode_index integer
---@field last_color Color
---@field gui ColorPickerGui?

---@class ModStorage
---@field players table<integer, PlayerSettings>
---@field lights table<integer, DiscoLight>
---@field last_id integer

---@type ModStorage
storage = storage

---@param light DiscoLight
---@param group_name string
---@param transform fun(LuaRendering)
local function modify_renders(light, group_name, transform)
    for _, object in pairs(light.render_objects[group_name]) do
        if object.valid then
            transform(object)
        end
    end
end

---@param light DiscoLight
---@param group_name string Render object group
local function destroy_renders(light, group_name)
    modify_renders(light, group_name, function (object)
        object.destroy()
    end)
    light.render_objects[group_name] = nil
end

---@param light DiscoLight
local function destroy_light(light)
    destroy_renders(light, "light_tiles")
    destroy_renders(light, "corners")
    destroy_renders(light, "edit_gui")
    destroy_renders(light, "map_shapes")
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

---@param player_index integer
---@return Mode
local function current_player_mode(player_index)
    return C.modes[storage.players[player_index] and storage.players[player_index].mode_index or 1]
end

---@param player_index integer
---@return Color?
local function current_player_last_color(player_index)
    return storage.players[player_index].last_color
end

---@param letters string[]
---@param leading number
---@param trailing number
---@param radius number
---@param count number
---@return table
local function sprite_bands(letters, leading, trailing, radius, count)
    return {
        { letter = letters[1], center = leading - radius / 2, scale = 1 },
        { letter = letters[2], center = leading + count / 2, scale = count / C.tiles_per_px },
        { letter = letters[3], center = trailing + radius / 2, scale = 1 },
    }
end


---@param player_index integer
---@param rect Rect
---@param surface LuaSurface
---@param mode Mode
---@param color Color?
local function draw_light(player_index, rect, surface, mode, color)
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

    for _, row in ipairs(sprite_bands(C.sprite_row_letters, top, bottom, radius, vertical_count)) do
        for _, column in ipairs(sprite_bands(C.sprite_column_letters, left, right, radius, horizontal_count)) do
            if row.scale > 0 and column.scale > 0 then
                table.insert(tiles, R.draw_sprite {
                    sprite = C.sprites.light(radius, row.letter, column.letter),
                    surface = surface,
                    x_scale = column.scale,
                    y_scale = row.scale,
                    render_layer = "light-effect",
                    light_mode = "light",
                    target = { column.center, row.center, },
                    tint = color
                })
            end
        end
    end

    ---@type LuaRenderObject[]
    local corners = {}
    local corner_locations = {
        [0] = { left, top, },
        [1] = { right, top, },
        [2] = { right, bottom, },
        [3] = { left, bottom, },
    }

    for i = 0, 3, 1 do
        table.insert(corners, R.draw_sprite {
            sprite = C.sprites.cursors[math.min(width, height)] or C.sprites.cursors[3],
            surface = surface,
            target = corner_locations[i],
            render_layer = "selection-box",
            light_mode = "glow",
            orientation = i * 0.25,
        })
    end

    ---@type LuaRenderObject[]
    local edit_gui = {}

    local color_circle_radius = 0.5
    local color_circle_stroke_px = 2.5
    local color_circle_stroke_radius = color_circle_radius - color_circle_stroke_px * C.tiles_per_px / 2
    local color_circle_target = { left + color_circle_radius, top - 0.25 - color_circle_radius, }

    if mode == "static" then
        table.insert(edit_gui, R.draw_sprite {
            sprite = C.sprites.circle,
            tint = color,
            surface = surface,
            target = color_circle_target,
            render_layer = "selection-box",
            light_mode = "glow",
        })
    elseif mode == "spectrum" then
        table.insert(edit_gui, R.draw_animation {
            animation = C.sprites.spectrum_circle,
            render_layer = "selection-box",
            light_mode = "glow",
            target = color_circle_target,
            surface = surface,
        })
    end

    table.insert(edit_gui, R.draw_circle {
        color = { 27, 27, 27, 255, },
        radius = color_circle_stroke_radius ,
        width = color_circle_stroke_px,
        filled = false,
        render_layer = "selection-box",
        target = color_circle_target,
        surface = surface,
    })

    table.insert(edit_gui, R.draw_text {
        text = "Mode: " .. current_player_mode(player_index),
        color = { 1, 1, 1, 1, },
        filled = true,
        vertical_alignment = "bottom",
        render_layer = "selection-box",
        target = { left + 1.2, top - 0.75, },
        surface = surface,
    })
    table.insert(edit_gui, R.draw_text {
        text = "Radius: " .. current_player_radius(player_index) .. " tiles",
        color = { 1, 1, 1, 1, },
        filled = true,
        vertical_alignment = "top",
        render_layer = "selection-box",
        target = { left + 1.2, top - 0.80, },
        surface = surface,
    })

    ---@type LuaRenderObject[]
    local map_shapes = {}
    local map_color = color and { r = color.r, g = color.g, b = color.b, a = C.map_alpha, }  or C.colors.default_map_color
    table.insert(map_shapes, R.draw_rectangle {
        color = map_color,
        filled = true,
        render_layer = "selection-box",
        left_top = { left, top, },
        right_bottom = { right, bottom, },
        render_mode = "chart",
        surface = surface,
    })

    ---@type DiscoLight
    local light = {
        mode = C.modes[storage.players[player_index].mode_index],
        render_objects = { light_tiles = tiles, corners = corners, edit_gui = edit_gui, map_shapes = map_shapes, },
        surface = surface,
        color = color,
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
        local mode = current_player_mode(event.player_index)
        local last_color = current_player_last_color(event.player_index)
        local color = mode == "static" and last_color or nil
        draw_light(event.player_index,
            rect,
            event.surface, current_player_mode(event.player_index), color)
    elseif selection_type == "rev-select" then -- Remove light
        local to_delete = {}
        for i, light in pairs(storage.lights) do
            if light.surface == event.surface and Rect.is_in_rect(light.rect, rect) then
                table.insert(to_delete, i)
            end
        end
        for _, i in pairs(to_delete) do
            destroy_light(storage.lights[i])
            storage.lights[i] = nil
        end
    elseif selection_type == "alt-select" then -- Open color picker
         local player_settings = storage.players[event.player_index]
        local gui = player_settings.gui
        if not gui then
            gui = ColorPickerGui.new(event.player_index)
            player_settings.gui = gui
        end
        if gui then
            ColorPickerGui.update(gui, player_settings.last_color)
        end
    else
        -- not implemented
    end
end

---@param enabled boolean
local function enable_editting(enabled)
    for _, light in pairs(storage.lights) do
        for _, name in pairs({ "corners", "edit_gui", "map_shapes", }) do
            modify_renders(light, name, function (object)
                object.visible = enabled
            end)
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
        local color = current_player_last_color(player_index) or {r=1, g=1, b=1,}
        cursor_stack.label = "[color=" .. color.r .. ",".. color.g .. "," .. color.b .. "]⬤[/color]" ..
            "\nRadius: " .. tostring(current_player_radius(player_index)) ..
            "\nMode: " .. C.modes[storage.players[player_index].mode_index]
    else
        enable_editting(false)
    end
end

--- Events

---@param player_index integer
local function init_player(player_index)
    ---@type PlayerSettings
    local player_settings = { radius_index = 1, mode_index = 1, last_color = C.colors.default_color, }
    storage.players[player_index] = player_settings
end

---@param player_index integer
---@
local function hide_gui(player_index)
    local gui = storage.players[player_index].gui
    if not gui then return end
    if gui.frame.valid then
        gui.frame.destroy()
    end
    storage.players[player_index].gui = nil
end

script.on_init(function()
    storage.lights = {}
    storage.players = {}
    storage.last_id = 1
    for _, player in pairs(game.connected_players) do
        init_player(player.index)
    end
end)

script.on_event(defines.events.on_player_joined_game, function(event)
    init_player(event.player_index)
end)

script.on_event(defines.events.on_player_left_game, function(event)
    hide_gui(event.player_index)
    storage.players[event.player_index] = nil
end)

script.on_configuration_changed(function(event)
    -- Close all open windows
    if not storage.players then return end
    for player_index, _ in pairs(storage.players) do
        hide_gui(player_index)
    end
end)

script.on_event("clear-disco-lights", function(event)
    clear_lights()
end)

script.on_nth_tick(2, function(event)
    for _, light in pairs(storage.lights) do
        if light.mode == "spectrum" then
            local base = event.tick / light.duration
            local color = U.hue_to_rgb((base + (light.phase or 0)) % 1)
            modify_renders(light, "light_tiles", function (object)
                object.color = color
            end)
            color.a = C.map_alpha
            modify_renders(light, "map_shapes", function (object)
                object.color = color
            end)
        end
    end
end)

-- GUI events

script.on_event(defines.events.on_gui_click, function(event)
    local player_index = event.player_index
    local gui = storage.players[player_index].gui
    if not gui then return end
    if event.element == gui.close_button then
        hide_gui(player_index)
    end
end)

script.on_event(defines.events.on_gui_value_changed, function(event)
    local player_index = event.player_index
    local gui = storage.players[player_index].gui
    if not gui then return end
    local color = ColorPickerGui.color_from_sliders(gui)
    ColorPickerGui.update(gui, color)
    storage.players[player_index].last_color = color
    update_planner(player_index)
end)

script.on_event(defines.events.on_gui_text_changed, function (event)
    local player_index = event.player_index
    local gui = storage.players[player_index].gui
    if not gui then return end
    local color
    if event.element == gui.hex_textfield then
        local satintized_hex = U.sanitize_hex(event.text)
        gui.hex_textfield.text = satintized_hex
        color = util.color(satintized_hex)
    else
        color = ColorPickerGui.color_from_textfield(gui)
    end

    ColorPickerGui.update(gui, color, event.element)
    storage.players[player_index].last_color = color
    update_planner(player_index)
    U.d(player_index, "Old: " .. event.element.text .. " New: " .. event.text)
end)

-- Inputs

---@param event EventData.CustomInputEvent
---@param setting_name string
---@param delta integer
---@param list any[]
local function cycle_setting_and_update(event, setting_name, delta, list)
    local player_index = event.player_index
    local settings = storage.players[player_index]
    settings[setting_name] = U.cycle_index(settings[setting_name], delta, #list)
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

script.on_event(defines.events.on_player_super_forced_selected_area, function(event)
    handle_selection(event, "super-select")
end)
