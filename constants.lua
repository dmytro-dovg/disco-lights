require "__core__.lualib.util"
local C = {}

---@alias Mode "static"|"spectrum"

C.debug = {
    logging_enabled = true,
    log_in_game = true,
}

---@type string
C.sprite_prefix = "disco-lights"

---@type string
C.selection_tool_name = "disco-lights-tool"

---@type string[]
C.sprite_row_letters = { "t", "m", "b", }

---@type string[]
C.sprite_column_letters = { "l", "m", "r", }

---@type integer[]
C.radii = { 1, 2, 4, 8, 16, }


---@type Mode[]
C.modes = { "static", "spectrum", }

---@type number
C.tiles_per_px = util.by_pixel(1, 1)[1]

--- Spectrum cycle limits and defaults
C.spectrum = {
    phase = { min = 0, max = 359, default = 0, },
    duration = { min = 1, max = 60, default = 5, },
}

C.locale = {
    mode_label = "disco-lights.mode-label",
    radius_label = "disco-lights.radius-label",
    picker_radius = "disco-lights.picker-radius",
    cursor_radius = "disco-lights.cursor-radius",
    cursor_mode = "disco-lights.cursor-mode",
    ---@param mode Mode
    ---@return string
    mode = function (mode)
        return "disco-lights.mode-" .. mode
    end,
}

---@type string[]
C.cursor_label_keys = { C.locale.cursor_radius, C.locale.cursor_mode, }
for _, mode in pairs(C.modes) do
    table.insert(C.cursor_label_keys, C.locale.mode(mode))
end

C.sprites = {
    cursors = {
        [1] = C.sprite_prefix .. "-cursor-box-small",
        [2] = C.sprite_prefix .. "-cursor-box-medium",
        [3] = C.sprite_prefix .. "-cursor-box-large",
    },
    light = function (radius, row, column)
        return C.sprite_prefix .. "-" .. radius .. "-" .. row .. column
    end,
    spectrum_circle = C.sprite_prefix .. "-spectrum_circle",
    circle = C.sprite_prefix .. "-circle",
}

---@type number
C.map_alpha = 0.2

---@type table<string, Color>
C.colors = {
    default_color = { r = 1, g = 0, b = 0, a = 1 },
    default_map_color = { r = 1, g = 0, b = 1, a = C.map_alpha },
}

return C
