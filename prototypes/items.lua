data:extend({
    {
        type = "selection-tool",
        name = "disco-lights-tool",
        localised_name = "Disco lights tool",
        icon = "__disco-lights__/graphics/icons/planner.png",
        stack_size = 1,
        hidden = true,
        draw_label_for_cursor_render = true,
        default_label_color = {r = 1, g = 1, b = 1},
        flags = { "only-in-cursor", "not-stackable", "spawnable" },
        select = {
            border_color = { r = 0, g = 0.3, b = 1 },
            cursor_box_type = "entity",
            mode = { "nothing", },
        },
        alt_select = {
            border_color = { r = 1, g = 0.5, b = 0 },
            cursor_box_type = "entity",
            mode = { "nothing", },
        },
    },
})
