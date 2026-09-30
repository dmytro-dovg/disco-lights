local C = require "constants"

data:extend({
    {
        type = "shortcut",
        name = C.give_tool_name,
        action = "spawn-item",
        item_to_spawn = C.selection_tool_name,
        associated_control_input = C.give_tool_name,
        icon = "__disco-lights__/graphics/shortcut-toolbar/mip/shortcut_x56.png",
        icon_size = 56,
        small_icon = "__disco-lights__/graphics/shortcut-toolbar/mip/shortcut_x24.png",
        small_icon_size = 24,
    },
})
