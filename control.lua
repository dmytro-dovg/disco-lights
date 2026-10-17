local R = rendering
local C = require "constants"
local U = require "util.utilities"
local Rect = require "util.rect"
local ColorPickerGui = require "gui.color-picker-gui"

---@alias SelectionType "select"|"rev-select"|"alt-select"

---@class DiscoLight
---@field render_objects { light_tiles: LuaRenderObject[], corners: LuaRenderObject[], edit_gui: LuaRenderObject[], map_shapes: LuaRenderObject[] }
---@field surface LuaSurface
---@field cycle SpectrumCycle
---@field rect Rect
---@field mode Mode
---@field radius integer

---@class PlayerSettings
---@field radius_index integer
---@field mode_index integer
---@field last_color Color
---@field editing boolean
---@field spectrum SpectrumCycle
---@field gui ColorPickerGui?
---@field translations table<string, string>?
---@field preview_light_id integer?

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

---@param objects LuaRenderObject[]
---@param color Color
local function set_color(objects, color)
    for i = 1, #objects do
        objects[i].color = color
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

---@param player_index integer
---@return PlayerSettings
local function init_player_settings(player_index)
    local player_settings = storage.players[player_index]
    if not player_settings then
        player_settings = {
            radius_index = 1,
            mode_index = 1,
            last_color = C.colors.default_color,
            editing = false,
            spectrum = { phase = C.spectrum.phase.default, duration = C.spectrum.duration.default, },
        }
        storage.players[player_index] = player_settings
    end
    return player_settings
end

---@param player_index integer
---@return PlayerSettings
local function get_or_init_player_settings(player_index)
    return storage.players[player_index] or init_player_settings(player_index)
end

---@param player_index integer
---@return integer
local function current_player_radius(player_index)
    return C.radii[get_or_init_player_settings(player_index).radius_index]
end

---@param player_index integer
---@return Mode
local function current_player_mode(player_index)
    return C.modes[get_or_init_player_settings(player_index).mode_index]
end

---@param player_index integer
---@return Color?
local function current_player_last_color(player_index)
    return get_or_init_player_settings(player_index).last_color
end

---@return integer[]
local function editing_players()
    local list = {}
    for player_index, settings in pairs(storage.players) do
        if settings.editing then
            table.insert(list, player_index)
        end
    end
    return list
end

---@param light DiscoLight
---@param audience integer[]
local function apply_overlay_audience(light, audience)
    local anyone = #audience > 0
    for _, name in pairs({ "corners", "edit_gui", "map_shapes", }) do
        modify_renders(light, name, function (object)
            object.visible = anyone
            object.players = anyone and audience or {}
        end)
    end
end

local function apply_overlay_audience_to_all()
    local audience = editing_players()
    for _, light in pairs(storage.lights) do
        apply_overlay_audience(light, audience)
    end
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

---@param band { letter: string, scale: number }
local function spectrum_band_scale(band)
    if band.letter == "m" then
        return band.scale / C.spectrum_animation.scale
    end
    return band.scale
end

---@param rect Rect
---@return integer left
---@return integer top
---@return integer right
---@return integer bottom
local function light_bounds(rect)
    local left = math.floor(rect.position.x)
    local top = math.floor(rect.position.y)
    local right = math.max(math.ceil(rect.position.x + rect.size.width), left + 1)
    local bottom = math.max(math.ceil(rect.position.y + rect.size.height), top + 1)
    return left, top, right, bottom
end

---@param left integer
---@param top integer
---@param right integer
---@param bottom integer
---@return MapPosition[]
local function corner_locations(left, top, right, bottom)
    return {
        { left, top, },
        { right, top, },
        { right, bottom, },
        { left, bottom, },
    }
end

---@param light DiscoLight
---@param left integer
---@param top integer
---@param right integer
---@param bottom integer
local function layout_light(light, left, top, right, bottom)
    local width = right - left
    local height = bottom - top
    local objects = light.render_objects

    local index = 1
    for _, row in ipairs(sprite_bands(C.sprite_row_letters, top, bottom, light.radius, height)) do
        for _, column in ipairs(sprite_bands(C.sprite_column_letters, left, right, light.radius, width)) do
            local tile = objects.light_tiles[index]
            tile.target = { column.center, row.center, }
            if light.mode == "spectrum" then
                tile.x_scale = spectrum_band_scale(column)
                tile.y_scale = spectrum_band_scale(row)
            else
                tile.x_scale = column.scale
                tile.y_scale = row.scale
            end
            index = index + 1
        end
    end

    local corner_sprite = C.sprites.cursors[math.min(width, height)] or C.sprites.cursors[3]
    local locations = corner_locations(left, top, right, bottom)
    for i, corner in ipairs(objects.corners) do
        corner.sprite = corner_sprite
        corner.target = locations[i]
    end

    local color_circle_radius = 0.5
    local color_circle_target = { left + color_circle_radius, top - 0.25 - color_circle_radius, }
    objects.edit_gui[1].target = color_circle_target
    objects.edit_gui[2].target = color_circle_target
    objects.edit_gui[3].target = { left + 1.2, top - 0.75, }
    objects.edit_gui[4].target = { left + 1.2, top - 0.80, }

    objects.map_shapes[1].left_top = { left, top, }
    objects.map_shapes[1].right_bottom = { right, bottom, }

    light.rect = Rect.new(left, top, width, height)
end

---@param player_index integer
---@param rect Rect
---@param surface LuaSurface
---@param mode Mode
---@param color Color?
---@param radius integer
---@return DiscoLight
---@return integer
local function place_light(player_index, rect, surface, mode, color, radius)
    local tiles = {}

    local left, top, right, bottom = light_bounds(rect)
    local width = right - left
    local height = bottom - top

    local horizontal_count = width
    local vertical_count = height

    local cycle = table.deepcopy(get_or_init_player_settings(player_index).spectrum)
    local tint = color
    if mode == "spectrum" then
        tint = U.spectrum_color(game.tick, cycle)
    end

    local frame_count = C.spectrum_animation.frame_count

    for _, row in ipairs(sprite_bands(C.sprite_row_letters, top, bottom, radius, vertical_count)) do
        for _, column in ipairs(sprite_bands(C.sprite_column_letters, left, right, radius, horizontal_count)) do
            if row.scale > 0 and column.scale > 0 then
                if mode == "spectrum" then
                    table.insert(tiles, R.draw_animation {
                        animation = C.sprites.spectrum_light(radius, row.letter, column.letter),
                        surface = surface,
                        x_scale = spectrum_band_scale(column),
                        y_scale = spectrum_band_scale(row),
                        render_layer = "light-effect",
                        light_mode = "light",
                        target = { column.center, row.center, },
                        animation_speed = frame_count / (cycle.duration * 60),
                        animation_offset = cycle.phase / 360 * frame_count,
                    })
                else
                    table.insert(tiles, R.draw_sprite {
                        sprite = C.sprites.light(radius, row.letter, column.letter),
                        surface = surface,
                        x_scale = column.scale,
                        y_scale = row.scale,
                        render_layer = "light-effect",
                        light_mode = "light",
                        target = { column.center, row.center, },
                        tint = tint
                    })
                end
            end
        end
    end

    ---@type LuaRenderObject[]
    local corners = {}
    local locations = corner_locations(left, top, right, bottom)

    for i = 1, 4 do
        table.insert(corners, R.draw_sprite {
            sprite = C.sprites.cursors[math.min(width, height)] or C.sprites.cursors[3],
            surface = surface,
            target = locations[i],
            render_layer = "selection-box",
            light_mode = "glow",
            orientation = (i - 1) * 0.25,
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

    local mode_label_text = { C.locale.mode_label, { C.locale.mode(current_player_mode(player_index)) } }
    table.insert(edit_gui, R.draw_text {
        text = mode_label_text,
        color = { 1, 1, 1, 1, },
        filled = true,
        vertical_alignment = "bottom",
        render_layer = "selection-box",
        target = { left + 1.2, top - 0.75, },
        surface = surface,
    })
    local radius_label_text = { C.locale.radius_label, current_player_radius(player_index) }
    table.insert(edit_gui, R.draw_text {
        text = radius_label_text,
        color = { 1, 1, 1, 1, },
        filled = true,
        vertical_alignment = "top",
        render_layer = "selection-box",
        target = { left + 1.2, top - 0.80, },
        surface = surface,
    })

    ---@type LuaRenderObject[]
    local map_shapes = {}
    local map_color = tint and { r = tint.r, g = tint.g, b = tint.b, a = C.map_alpha, } or C.colors.default_map_color
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
        mode = current_player_mode(player_index),
        render_objects = { light_tiles = tiles, corners = corners, edit_gui = edit_gui, map_shapes = map_shapes, },
        surface = surface,
        rect = Rect.new(left, top, width, height),
        cycle = cycle,
        radius = radius,
    }
    apply_overlay_audience(light, editing_players())
    storage.lights[storage.last_id] = light
    storage.last_id = storage.last_id + 1
    return light, storage.last_id - 1
end

---@param player_index integer
local function discard_preview(player_index)
    local player_settings = storage.players[player_index]
    if not player_settings or not player_settings.preview_light_id then return end
    local light = storage.lights[player_settings.preview_light_id]
    if light then
        destroy_light(light)
        storage.lights[player_settings.preview_light_id] = nil
    end
    player_settings.preview_light_id = nil
end

---@param event EventData.on_player_selected_area|EventData.on_player_start_selected_area|EventData.on_player_change_selected_area
---@param rect Rect
local function update_preview(event, rect)
    local player_settings = get_or_init_player_settings(event.player_index)
    local light = player_settings.preview_light_id and storage.lights[player_settings.preview_light_id]
    if light and light.surface == event.surface and light.render_objects.light_tiles[1].valid then
        layout_light(light, light_bounds(rect))
        return
    end
    discard_preview(event.player_index)
    local mode = current_player_mode(event.player_index)
    local last_color = current_player_last_color(event.player_index)
    local color = mode == "static" and last_color or nil
    local radius = current_player_radius(event.player_index)
    local _, id = place_light(event.player_index, rect, event.surface, mode, color, radius)
    player_settings.preview_light_id = id
end

---@param event any
---@param selection_stage SelectionStage
local function handle_selection(event, selection_stage)
    if event.item ~= C.selection_tool_name then return end

    local rect = Rect.from_bounding_box(event.area)

    if selection_stage == C.selection_stage.cancel or event.selection_mode ~= defines.selection_mode.select then
        discard_preview(event.player_index)
    end

    if event.selection_mode == defines.selection_mode.select and selection_stage == C.selection_stage.start then -- Add light
        discard_preview(event.player_index)
        update_preview(event, rect)
    elseif event.selection_mode == defines.selection_mode.reverse_select and selection_stage == C.selection_stage.done then -- Remove light
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
    elseif event.selection_mode == defines.selection_mode.alt_select and selection_stage == C.selection_stage.done then -- Open color picker
        local player_settings = get_or_init_player_settings(event.player_index)
        local gui = player_settings.gui
        if gui and not gui.frame.valid then
            gui = nil
        end
        if not gui then
            gui = ColorPickerGui.new(event.player_index)
            player_settings.gui = gui
        end
        if gui then
            ColorPickerGui.update(gui, player_settings.last_color)
            ColorPickerGui.update_spectrum(gui, player_settings.spectrum)
            ColorPickerGui.update_radius(gui, player_settings.radius_index)
            ColorPickerGui.select_mode(gui, player_settings.mode_index)
            local player = game.get_player(event.player_index)
            if player then
                player.opened = gui.frame
            end
        end
    end

    if event.selection_mode == defines.selection_mode.select and selection_stage == C.selection_stage.change then
        update_preview(event, rect)
    end

    if event.selection_mode == defines.selection_mode.select and selection_stage == C.selection_stage.done then
        update_preview(event, rect)
        storage.players[event.player_index].preview_light_id = nil
    end
end

---@param enabled boolean
local function enable_editting(player_index, enabled)
    local player_settings = get_or_init_player_settings(player_index)
    if player_settings.editing == enabled then return end
    player_settings.editing = enabled
    apply_overlay_audience_to_all()
end

---@param player LuaPlayer
local function request_cursor_label_translations(player)
    get_or_init_player_settings(player.index).translations = {}
    for _, key in pairs(C.cursor_label_keys) do
        player.request_translation { key }
    end
end

---@param settings PlayerSettings
---@param key string
---@param fallback string
---@return string
local function translated(settings, key, fallback)
    return settings.translations and settings.translations[key] or fallback
end

---@param player_index integer
local function update_planner(player_index)
    local player = game.get_player(player_index)
    if not player then return end
    local cursor_stack = player.cursor_stack
    if cursor_stack and cursor_stack.valid_for_read and cursor_stack.name == C.selection_tool_name then
        enable_editting(player_index, true)
        local settings = get_or_init_player_settings(player_index)
        if not settings.translations then
            request_cursor_label_translations(player)
        end
        local color = current_player_last_color(player_index) or {r=1, g=1, b=1,}
        local mode = current_player_mode(player_index)
        cursor_stack.label = "[color=" .. color.r .. ",".. color.g .. "," .. color.b .. "]⬤[/color]" ..
            "\n" .. translated(settings, C.locale.cursor_radius, "") .. " " .. current_player_radius(player_index) ..
            "\n" .. translated(settings, C.locale.cursor_mode, "") .. " " .. translated(settings, C.locale.mode(mode), mode)
    else
        enable_editting(player_index, false)
        discard_preview(player_index)
    end
end

script.on_event(defines.events.on_string_translated, function(event)
    local localised = event.localised_string
    if type(localised) ~= "table" or not U.contains(C.cursor_label_keys, localised[1]) then return end
    if not event.translated then return end
    local settings = storage.players[event.player_index]
    if not settings then return end
    settings.translations = settings.translations or {}
    settings.translations[localised[1]] = event.result
    update_planner(event.player_index)
end)

script.on_event(defines.events.on_player_locale_changed, function(event)
    local player = game.get_player(event.player_index)
    if not player then return end
    request_cursor_label_translations(player)
end)

--- Events

---@param player_index integer
local function hide_gui(player_index)
    local player_settings = storage.players[player_index]
    if not player_settings or not player_settings.gui then return end
    local gui = player_settings.gui
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
        init_player_settings(player.index)
    end
end)

script.on_event(defines.events.on_player_created, function(event)
    init_player_settings(event.player_index)
end)

script.on_event(defines.events.on_player_joined_game, function(event)
    init_player_settings(event.player_index)
    update_planner(event.player_index)
end)

script.on_event(defines.events.on_player_left_game, function(event)
    hide_gui(event.player_index)
    discard_preview(event.player_index)
    local player_settings = storage.players[event.player_index]
    if player_settings then
        player_settings.editing = false
    end
    apply_overlay_audience_to_all()
end)

script.on_event(defines.events.on_player_removed, function(event)
    hide_gui(event.player_index)
    discard_preview(event.player_index)
    storage.players[event.player_index] = nil
    apply_overlay_audience_to_all()
end)

script.on_event(defines.events.on_pre_surface_deleted, function(event)
    local to_delete = {}
    for index, light in pairs(storage.lights) do
        if light.surface.index == event.surface_index then
            destroy_light(light)
            table.insert(to_delete, index)
        end
    end
    for _, index in pairs(to_delete) do
        storage.lights[index] = nil
    end
end)

script.on_configuration_changed(function(event)
    -- Close all open windows
    if not storage.players then return end
    for player_index, settings in pairs(storage.players) do
        hide_gui(player_index)
        -- Invalidate translations
        settings.translations = nil
    end
    apply_overlay_audience_to_all()
end)

script.on_nth_tick(C.spectrum.update_interval, function(event)
    ---@type table<string, { light: Color, map: Color }>
    local colors = {}
    ---@param cycle SpectrumCycle
    local function colors_for(cycle)
        local key = cycle.phase .. ":" .. cycle.duration
        local cached = colors[key]
        if not cached then
            local color = U.spectrum_color(event.tick, cycle)
            cached = {
                light = color,
                map = { r = color.r, g = color.g, b = color.b, a = C.map_alpha, },
            }
            colors[key] = cached
        end
        return cached
    end

    for _, light in pairs(storage.lights) do
        if light.mode == "spectrum" then
            local map_shapes = light.render_objects.map_shapes
            if map_shapes[1].valid then
                set_color(map_shapes, colors_for(light.cycle).map)
            end
        end
    end

    for player_index, player_settings in pairs(storage.players) do
        local gui = player_settings.gui
        if gui and gui.frame.valid and current_player_mode(player_index) == "spectrum" then
            ColorPickerGui.update_spectrum_swatch(gui, colors_for(player_settings.spectrum).light)
        end
    end
end)

-- GUI events

script.on_event(defines.events.on_gui_click, function(event)
    local player_index = event.player_index
    local gui = get_or_init_player_settings(player_index).gui
    if not gui then return end
    if event.element == gui.close_button then
        hide_gui(player_index)
    end
end)

script.on_event(defines.events.on_gui_closed, function(event)
    local player_settings = get_or_init_player_settings(event.player_index)
    if not player_settings.gui then return end
    local frame = player_settings.gui.frame
    if event.element and frame.valid and event.element == frame then
        hide_gui(event.player_index)
    end
end)

script.on_event(defines.events.on_gui_value_changed, function(event)
    local player_index = event.player_index
    local player_settings = get_or_init_player_settings(player_index)
    local gui = player_settings.gui
    if not gui then return end
    if ColorPickerGui.contains_slider(gui, event.element) then
        local color = ColorPickerGui.color_from_sliders(gui)
        ColorPickerGui.update(gui, color)
        player_settings.last_color = color
        update_planner(player_index)
    elseif ColorPickerGui.contains_spectrum_slider(gui, event.element) then
        local spectrum = ColorPickerGui.spectrum_from_sliders(gui)
        ColorPickerGui.update_spectrum(gui, spectrum)
        player_settings.spectrum = spectrum
    elseif event.element == gui.radius_slider then
        player_settings.radius_index = ColorPickerGui.radius_index_from_slider(gui)
        ColorPickerGui.update_radius(gui, player_settings.radius_index)
        update_planner(player_index)
    end
end)

script.on_event(defines.events.on_gui_text_changed, function (event)
    local player_index = event.player_index
    local player_settings = get_or_init_player_settings(player_index)
    local gui = player_settings.gui
    if not gui then return end
    if ColorPickerGui.contains_textfield(gui, event.element) then
        local color
        if event.element == gui.hex_textfield then
            local satintized_hex = U.sanitize_hex(event.text)
            gui.hex_textfield.text = satintized_hex
            color = U.hex_to_color(satintized_hex)
        else
            color = ColorPickerGui.color_from_textfield(gui)
        end
        ColorPickerGui.update(gui, color, event.element)
        player_settings.last_color = color
        update_planner(player_index)
    elseif ColorPickerGui.contains_spectrum_textfield(gui, event.element) then
        local spectrum = ColorPickerGui.spectrum_from_textfields(gui)
        ColorPickerGui.update_spectrum(gui, spectrum, event.element)
        player_settings.spectrum = spectrum
    end
end)

script.on_event(defines.events.on_gui_selected_tab_changed, function (event)
    local player_index = event.player_index
    local player_settings = get_or_init_player_settings(player_index)
    local gui = player_settings.gui
    if not gui or event.element ~= gui.tabbed_pane then return end
    player_settings.mode_index = event.element.selected_tab_index
    update_planner(player_index)
end)

-- Inputs

---@param event EventData.CustomInputEvent
---@param setting_name string
---@param delta integer
---@param list any[]
local function cycle_setting_and_update(event, setting_name, delta, list)
    local player_index = event.player_index
    local player = game.get_player(player_index)
    if not player then return end
    local cursor_stack = player.cursor_stack
    if cursor_stack and cursor_stack.valid_for_read and cursor_stack.name == C.selection_tool_name then
        local settings = get_or_init_player_settings(player_index)
        settings[setting_name] = U.cycle_index(settings[setting_name], delta, #list)
        update_planner(player_index)
        local gui = settings.gui
        if gui and gui.frame.valid then
            ColorPickerGui.select_mode(gui, settings.mode_index)
            ColorPickerGui.update_radius(gui, settings.radius_index)
        end
    end
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
    handle_selection(event, C.selection_stage.done)
end)

script.on_event(defines.events.on_player_reverse_selected_area, function(event)
    handle_selection(event, C.selection_stage.done)
end)

script.on_event(defines.events.on_player_alt_selected_area, function(event)
    handle_selection(event, C.selection_stage.done)
end)

script.on_event(defines.events.on_player_start_selected_area, function(event)
    handle_selection(event, C.selection_stage.start)
end)

script.on_event(defines.events.on_player_change_selected_area, function(event)
    handle_selection(event, C.selection_stage.change)
end)

script.on_event(defines.events.on_player_cancel_selected_area, function(event)
    handle_selection(event, C.selection_stage.cancel)
end)
