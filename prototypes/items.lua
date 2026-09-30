local C = require "constants"

data:extend({
    {
        type = "selection-tool",
        name = C.selection_tool_name,
        icon = "__disco-lights__/graphics/icons/planner.png",
        localised_description = { "shortcut-description.give-disco-lights-tool" },
        stack_size = 1,
        draw_label_for_cursor_render = true,
        default_label_color = {r = 1, g = 1, b = 1},
        flags = { "only-in-cursor", "not-stackable", "spawnable" },
        select = {
            border_color = { r = 0, g = 0.3, b = 1 },
            cursor_box_type = "entity",
            mode = { "nothing", },
        },
        alt_select = {
            border_color = { r = 1, g = 0.3, b = 0 },
            cursor_box_type = "entity",
            mode = { "nothing", },
        },
        reverse_select = {
            border_color = { r = 1, g = 0, b = 0.3 },
            cursor_box_type = "entity",
            mode = { "nothing", },
        },
        alt_reverse_select = {
            border_color = { r = 0, g = 0.3, b = 1 },
            cursor_box_type = "entity",
            mode = { "nothing", },
        },
        super_forced_select = {
            border_color = { r = 1, g = 0, b = 1 },
            cursor_box_type = "entity",
            mode = { "nothing", },
        },
    },
})
