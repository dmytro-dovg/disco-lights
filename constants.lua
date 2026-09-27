require "__core__.lualib.util"
local C = {}

---@alias Mode "static"|"spectrum"

C.debug = {
    logging_enabled = true,
    log_in_game = true,
}

---@type string[]
C.sprite_row_letters = { "t", "m", "b", }

---@type string[]
C.sprite_column_letters = { "l", "m", "r", }

---@type integer[]
C.radii = { 1, 2, 4, 8, 16, }

---@type string
C.sprite_prefix = "disco-light"

---@type Mode[]
C.modes = { "static", "spectrum", }

---@type number
C.tiles_per_px = util.by_pixel(1, 1)[1]

---@type table<SelectionType, number[]>
C.selection_colors = {
    ["select"] = { 1, 0, 0, 1 },
    ["alt-select"] = { 0, 1, 0, 1 },
    ["rev-select"] = { 0, 0, 1, 1 },
    ["rev-alt-select"] = { 0, 0.5, 1, 1 },
    ["super-select"] = { 1, 0, 1, 1 },
}

C.sprites = {
    cursors = {
        [1] = C.sprite_prefix .. "-cursor-box-small",
        [2] = C.sprite_prefix .. "-cursor-box-medium",
        [3] = C.sprite_prefix .. "-cursor-box-large",
    },
    light = function (radius, row, column)
        return C.sprite_prefix .. "-" .. radius .. "-" .. row .. column
    end,
    spectrum_circle = C.sprite_prefix .. "spectrum_circle",
    circle = C.sprite_prefix .. "circle",
}

---@type number
C.map_alpha = 0.2

---@type table<string, Color>
C.colors = {
    default_color = { r = 1, g = 0, b = 0, a = 1 },
    default_map_color = { r = 1, g = 0, b = 1, a = C.map_alpha },
}

return C
