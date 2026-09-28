
local U = require "util.utilities"

local G = {}

---@class ComponentGui
---@field textfield LuaGuiElement
---@field slider LuaGuiElement

---@class ColorPickerGui
---@field frame LuaGuiElement
---@field close_button LuaGuiElement
---@field swatch LuaGuiElement
---@field hex_textfield LuaGuiElement
---@field components { r: ComponentGui, g: ComponentGui, b: ComponentGui, }

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
        caption = "Pick color",
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

    local line_1 = frame.add {
        type = "flow",
        direction = "horizontal",
    }
    line_1.style.vertical_align = "center"

    -- Color swatch
    local swatch = line_1.add {
        type = "progressbar",
        name = "disco_swatch",
        style = "disco-lights_color_indicator",
        value = 1,
    }
    swatch.style.color = {r = 1, g = 1, b = 1}

    local spacer_1 = line_1.add {
        type = "empty-widget",
    }

    spacer_1.style.horizontally_stretchable = true
    line_1.add {
        type = "label",
        caption = "#",
    }

    -- Hex textfield
    local hex_textfield = line_1.add {
        type = "textfield",
        numeric = false,
    }
    hex_textfield.style.width = 64
    hex_textfield.style.horizontal_align = "center"

    -- Sliders
    local components = {}
    local slider_styles = {
        r = "red_slider",
        g = "green_slider",
        b = "blue_slider",
    }
    for _, component in pairs({ 'r', 'g', 'b', }) do
        local flow = frame.add {
            type = "flow",
            direction = "horizontal",
        }
        flow.style.vertical_align = "center"
        flow.add {
            type = "label",
            caption = component:upper()
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

    return {
        frame = outer,
        close_button = close_button,
        swatch = swatch,
        hex_textfield = hex_textfield,
        components = components
    }
end

---@param gui ColorPickerGui
---@param color Color
---@parame element LuaGuiElement?
function G.update(gui, color, element)
    gui.swatch.style.color = color
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
    return U.normalize_color {
        r = gui.components.r.slider.slider_value,
        g = gui.components.g.slider.slider_value,
        b = gui.components.b.slider.slider_value,
    }
end

---@param gui ColorPickerGui
---@return Color
function G.color_from_textfield(gui)
    local r_number = tonumber(gui.components.r.textfield.text) or 0
    local g_number = tonumber(gui.components.g.textfield.text) or 0
    local b_number = tonumber(gui.components.b.textfield.text) or 0

    return U.normalize_color {
        r = r_number <= 255 and r_number or 255,
        g = g_number <= 255 and g_number or 255,
        b = b_number <= 255 and b_number or 255,
    }
end

return G
