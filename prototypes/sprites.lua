local C = require "constants"

local specs = data.raw["utility-sprites"]["default"].cursor_box.multiplayer_selection
for i, spec in ipairs(specs) do
    if not spec.is_whole_box then
        local sprite = table.deepcopy(spec.sprite)
        sprite.type = "sprite"
        sprite.name = "disco-lights-cursor-box-" .. i
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

local function light_sprites(prefix, radius, filename)
    local radius_px = radius / C.tiles_per_px
    local collection = {}

    for _, row in ipairs(light_bands(C.sprite_row_letters, radius_px)) do
        for _, column in ipairs(light_bands(C.sprite_column_letters, radius_px)) do
            table.insert(collection, {
                type = "sprite",
                name = prefix .. "-" .. radius .. "-" .. row.letter .. column.letter,
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
    data.extend(light_sprites(C.light_sprite_prefix, radius, "__disco-lights__/graphics/light_" .. radius .. ".png"))
end
