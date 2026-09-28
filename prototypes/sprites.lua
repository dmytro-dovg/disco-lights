require "__core__.lualib.util"
local C = require "constants"

local specs = data.raw["utility-sprites"]["default"].cursor_box.multiplayer_selection
-- Indices are consistent with the sprite names we are deep-copying
local cursor_boxes = {
    [4] = C.sprites.cursors[1],
    [5] = C.sprites.cursors[2],
    [6] = C.sprites.cursors[3],
}
for i, name in pairs(cursor_boxes) do
    local spec = specs[i]
    if not spec.is_whole_box then
        ---@type any
        local sprite = table.deepcopy(spec.sprite)
        sprite.type = "sprite"
        sprite.name = name
        data:extend({ sprite })
    end
end


local function light_bands(letters, radius_px)
    return {
        { letter = letters[1], offset = 0, size = radius_px, },
        { letter = letters[2], offset = radius_px, size = 1, },
        { letter = letters[3], offset = radius_px + 1, size = radius_px, },
    }
end

local function light_sprites(radius, filename)
    local radius_px = radius / C.tiles_per_px
    local collection = {}

    for _, row in ipairs(light_bands(C.sprite_row_letters, radius_px)) do
        for _, column in ipairs(light_bands(C.sprite_column_letters, radius_px)) do
            table.insert(collection, {
                type = "sprite",
                name = C.sprites.light(radius, row.letter, column.letter),
                filename = filename,
                priority = "extra-high",
                flags = { "light" },
                width = column.size,
                height = row.size,
                position = { column.offset, row.offset },
            })
        end
    end
    return collection
end

for _, radius in pairs(C.radii) do
    data:extend(light_sprites(radius, "__disco-lights__/graphics/light_" .. radius .. ".png"))
end


data:extend({
    {
        type = "animation",
        name = C.sprites.spectrum_circle,
        size = 32,
        line_length = 16,
        filename = "__disco-lights__/graphics/spectrum_circle.png",
        priority = "extra-high",
        frame_count = 16,
        animation_speed = 0.2,
        lines_per_file = 1,
    },
    {
        type = "sprite",
        name = C.sprites.circle,
        filename = "__disco-lights__/graphics/circle.png",
        priority = "extra-high",
        size = 32,
    }
})
