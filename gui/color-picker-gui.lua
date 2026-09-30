
local U = require "util.utilities"
local C = require "constants"

local G = {}

---@class ComponentGui
---@field textfield LuaGuiElement
---@field slider LuaGuiElement

---@class ColorPickerGui
---@field frame LuaGuiElement
---@field close_button LuaGuiElement
---@field static_swatch LuaGuiElement
---@field spectrum_swatch LuaGuiElement
---@field hex_textfield LuaGuiElement
---@field tabbed_pane LuaGuiElement
---@field components { r: ComponentGui, g: ComponentGui, b: ComponentGui, }
---@field spectrum_components { phase: ComponentGui, duration: ComponentGui, }
---@field radius_slider LuaGuiElement
---@field radius_label LuaGuiElement

---@param parent LuaGuiElement
---@param caption LocalisedString
---@param slider_params table
---@param tooltip LocalisedString?
---@return ComponentGui
local function add_component_row(parent, caption, slider_params, tooltip)
    local row = parent.add {
        type = "flow",
        direction = "horizontal",
    }
    row.style.vertical_align = "center"
    row.add {
        type = "label",
        caption = caption,
        tooltip = tooltip,
    }
    local params = { type = "slider", tooltip = tooltip, }
    for key, value in pairs(slider_params) do
        params[key] = value
    end
    local slider = row.add(params)
    slider.style.left_margin = 8
    slider.style.right_margin = 8
    slider.style.horizontally_stretchable = true

    local textfield = row.add {
        type = "textfield",
        numeric = true,
        tooltip = tooltip,
    }
    textfield.style.width = 64
    textfield.style.horizontal_align = "center"
    return { slider = slider, textfield = textfield, }
end

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
        direction = "vertical",
    }

    local radius_flow = contents.add {
        type = "flow",
        direction = "horizontal",
    }
    radius_flow.style.margin = 16
    radius_flow.style.bottom_margin = 8
    radius_flow.style.vertical_align = "center"
    radius_flow.add {
        type = "label",
        caption = { C.locale.picker_radius },
        tooltip = { C.locale.picker_radius_tooltip },
    }
    local radius_slider = radius_flow.add {
        type = "slider",
        minimum_value = 1,
        maximum_value = #C.radii,
        discrete_values = true,
        style = "notched_slider",
        tooltip = { C.locale.picker_radius_tooltip },
    }
    radius_slider.style.left_margin = 8
    radius_slider.style.right_margin = 8
    radius_slider.style.horizontally_stretchable = true

    local radius_label = radius_flow.add {
        type = "label",
    }
    radius_label.style.width = 16
    radius_label.style.horizontal_align = "center"

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
        components[component] = add_component_row(flows.static, { "disco-lights.component-" .. component }, {
            style = slider_styles[component],
            minimum_value = 0,
            maximum_value = 255,
            value = 255,
        })
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
    -- Cycle parameters
    local spectrum_components = {}
    for _, parameter in pairs({ "phase", "duration", }) do
        local limits = C.spectrum[parameter]
        spectrum_components[parameter] = add_component_row(flows.spectrum, { "disco-lights.spectrum-" .. parameter }, {
            minimum_value = limits.min,
            maximum_value = limits.max,
            value = limits.default,
            value_step = 1,
            discrete_values = true,
        }, { "disco-lights.spectrum-" .. parameter .. "-tooltip" })
    end
    local spacer_2 = flows.spectrum.add {
        type = "empty-widget",
    }
    spacer_2.style.vertically_stretchable = true
    -- Color swatch
    local spectrum_swatch = flows.spectrum.add {
        type = "progressbar",
        style = "disco-lights_color_indicator",
        value = 1,
    }
    spectrum_swatch.style.color = {r = 1, g = 1, b = 1}

    return {
        frame = outer,
        close_button = close_button,
        static_swatch = static_swatch,
        spectrum_swatch = spectrum_swatch,
        hex_textfield = hex_textfield,
        tabbed_pane = pane,
        components = components,
        spectrum_components = spectrum_components,
        radius_slider = radius_slider,
        radius_label = radius_label,
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
---@param cycle SpectrumCycle
---@param element LuaGuiElement?
function G.update_spectrum(gui, cycle, element)
    for key, component in pairs(gui.spectrum_components) do
        component.slider.slider_value = cycle[key]
        if component.textfield ~= element or tonumber(component.textfield.text) ~= cycle[key] then
            component.textfield.text = tostring(cycle[key])
        end
    end
end

---@param components table<string, ComponentGui>
---@param element LuaGuiElement
---@return boolean
local function contains_slider(components, element)
    for _, component in pairs(components) do
        if component.slider == element then return true end
    end
    return false
end

---@param components table<string, ComponentGui>
---@param element LuaGuiElement
---@return boolean
local function contains_textfield(components, element)
    for _, component in pairs(components) do
        if component.textfield == element then return true end
    end
    return false
end

---@param gui ColorPickerGui
---@param element LuaGuiElement
---@return boolean
function G.contains_slider(gui, element)
    return contains_slider(gui.components, element)
end

---@param gui ColorPickerGui
---@param element LuaGuiElement
---@return boolean
function G.contains_textfield(gui, element)
    return element == gui.hex_textfield or contains_textfield(gui.components, element)
end

---@param gui ColorPickerGui
---@param element LuaGuiElement
---@return boolean
function G.contains_spectrum_slider(gui, element)
    return contains_slider(gui.spectrum_components, element)
end

---@param gui ColorPickerGui
---@param element LuaGuiElement
---@return boolean
function G.contains_spectrum_textfield(gui, element)
    return contains_textfield(gui.spectrum_components, element)
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
---@return SpectrumCycle
function G.spectrum_from_sliders(gui)
    return {
        phase = gui.spectrum_components.phase.slider.slider_value,
        duration = gui.spectrum_components.duration.slider.slider_value,
    }
end

---@param gui ColorPickerGui
---@return SpectrumCycle
function G.spectrum_from_textfields(gui)
    local cycle = {}
    for key, component in pairs(gui.spectrum_components) do
        local limits = C.spectrum[key]
        cycle[key] = U.clamp(tonumber(component.textfield.text) or limits.min, limits.min, limits.max)
    end
    return cycle
end

---@param gui ColorPickerGui
---@param mode_index integer
function G.select_mode(gui, mode_index)
    gui.tabbed_pane.selected_tab_index = mode_index
end

---@param gui ColorPickerGui
---@param radius_index integer
function G.update_radius(gui, radius_index)
    gui.radius_slider.slider_value = radius_index
    gui.radius_label.caption = tostring(C.radii[radius_index])
end

---@param gui ColorPickerGui
---@return integer
function G.radius_index_from_slider(gui)
    return math.floor(gui.radius_slider.slider_value + 0.5)
end

return G
