
local U = require "util.utilities"
local C = require "constants"

local G = {}

---@class ComponentGui
---@field textfield LuaGuiElement
---@field slider LuaGuiElement

---@class ColorPickerGui
---@field type string
---@field frame LuaGuiElement
---@field close_button LuaGuiElement
---@field static_swatch LuaGuiElement
---@field spectrum_swatch LuaGuiElement
---@field hex_textfield LuaGuiElement
---@field tabbed_pane LuaGuiElement
---@field components { r: ComponentGui, g: ComponentGui, b: ComponentGui, }
---@field cycle SpectrumCycle Drives the swatch preview while the player is in spectrum mode

---@param player_index integer
---@return ColorPickerGui?
function G.new(player_index)
    local player = game.get_player(player_index)
    if not player then return nil end
    local prefix = "disco-lights-"
    local outer = player.gui.screen.add {
        type = "frame",
        name = prefix .. "outer-frame",
        style = "invisible_frame",
        direction = "horizontal",
    }
    outer.auto_center = true

    local frame = outer.add {
        type = "frame",
        direction = "vertical",
    }

    local titlebar = frame.add {
        type = "flow",
        name = "titlebar",
    }
    titlebar.drag_target = outer

    titlebar.add {
        type = "label",
        style = "frame_title",
        caption = { "disco-lights.color-picker-title" },
        ignored_by_interaction = true,
    }

    local title_spacer = titlebar.add {
        type = "empty-widget",
        style = "draggable_space_header",
        ignored_by_interaction = true,
    }
    title_spacer.style.horizontally_stretchable = true
    title_spacer.style.height = 24
    title_spacer.style.right_margin = 8
    title_spacer.style.left_margin = 8


    -- Close button
    local close_button = titlebar.add {
        type = "sprite-button",
        name = prefix .. "close-button",
        style = "frame_action_button",
        sprite = "utility/close",
        tooltip = {"gui.close-instruction"},
    }

    local contents = frame.add {
        type = "frame",
        style = "inside_shallow_frame",
    }

    local pane = contents.add {
        type = "tabbed-pane",
    }

    local flows = {}
    for _, mode in pairs(C.modes) do
        local tab = pane.add {
            type = "tab",
            caption = { C.locale.mode(mode) },
        }
        local flow = pane.add {
            type = "flow",
            direction = "vertical",
        }
        flow.style.left_margin = 8
        flow.style.right_margin = 8
        pane.add_tab(tab, flow)
        flows[mode] = flow
    end

    -- Static

    -- Sliders
    local components = {}
    local slider_styles = {
        r = "red_slider",
        g = "green_slider",
        b = "blue_slider",
    }
    for _, component in pairs({ 'r', 'g', 'b', }) do
        local flow = flows.static.add {
            type = "flow",
            direction = "horizontal",
        }
        flow.style.vertical_align = "center"
        flow.add {
            type = "label",
            caption = { "disco-lights.component-" .. component },
        }
        local slider = flow.add {
            type = "slider",
            name = prefix .. "slider_" .. component,
            style = slider_styles[component],
            minimum_value = 0,
            maximum_value = 255,
            value = 255,
        }
        slider.style.left_margin = 8
        slider.style.right_margin = 8

        local textfield = flow.add {
            type = "textfield",
            numeric = true,
        }
        textfield.style.width = 64
        textfield.style.horizontal_align = "center"
        components[component] = { slider = slider, textfield = textfield, }
    end


    -- Hex color
    local hex_line = flows.static.add {
        type = "flow",
        direction = "horizontal",
    }
    hex_line.style.vertical_align = "center"

    -- Color swatch
    local static_swatch = hex_line.add {
        type = "progressbar",
        style = "disco-lights_color_indicator",
        value = 1,
    }
    static_swatch.style.color = {r = 1, g = 1, b = 1}

    local spacer_1 = hex_line.add {
        type = "empty-widget",
    }

    spacer_1.style.horizontally_stretchable = true
    hex_line.add {
        type = "label",
        caption = { "disco-lights.hex-label" },
    }
    local hex_textfield = hex_line.add {
        type = "textfield",
        numeric = false,
    }
    hex_textfield.style.width = 64
    hex_textfield.style.horizontal_align = "center"

    -- Spectrum
    -- Color swatch
    local spectrum_swatch = flows.spectrum.add {
        type = "progressbar",
        style = "disco-lights_color_indicator",
        value = 1,
    }
    spectrum_swatch.style.color = {r = 1, g = 1, b = 1}
    return {
        type = "color-picker-gui",
        frame = outer,
        close_button = close_button,
        static_swatch = static_swatch,
        spectrum_swatch = spectrum_swatch,
        hex_textfield = hex_textfield,
        tabbed_pane = pane,
        components = components,
        cycle = U.new_spectrum_cycle(),
    }
end

---@param gui ColorPickerGui
---@param color Color
---@parame element LuaGuiElement?
function G.update(gui, color, element)
    gui.static_swatch.style.color = color
    local bytes_color = U.color_to_bytes(color)
    for key, component in pairs(gui.components) do
        component.slider.slider_value = bytes_color[key]
        component.textfield.text = tostring(bytes_color[key])
    end
    if gui.hex_textfield ~= element then
        gui.hex_textfield.text = U.color_to_hex(bytes_color)
    end
end

---@param gui ColorPickerGui
---@param color Color
function G.update_spectrum_swatch(gui, color)
    gui.spectrum_swatch.style.color = color
end

---@param gui ColorPickerGui
---@param element LuaGuiElement
---@return boolean
function G.contains_slider(gui, element)
    for _, component in pairs(gui.components) do
        if component.slider == element then return true end
    end
    return false
end

---@param gui ColorPickerGui
---@param element LuaGuiElement
---@return boolean
function G.contains_textfield(gui, element)
    if element == gui.hex_textfield then return true end
    for _, component in pairs(gui.components) do
        if component.textfield == element then return true end
    end
    return false
end

---@param gui ColorPickerGui
---@return Color
function G.color_from_sliders(gui)
    return U.color_from_bytes(
        gui.components.r.slider.slider_value,
        gui.components.g.slider.slider_value,
        gui.components.b.slider.slider_value
    )
end

---@param gui ColorPickerGui
---@return Color
function G.color_from_textfield(gui)
    return U.color_from_bytes(
        tonumber(gui.components.r.textfield.text) or 0,
        tonumber(gui.components.g.textfield.text) or 0,
        tonumber(gui.components.b.textfield.text) or 0
    )
end

---@param gui ColorPickerGui
---@param mode_index integer
function G.select_mode(gui, mode_index)
    gui.tabbed_pane.selected_tab_index = mode_index
end

return G
