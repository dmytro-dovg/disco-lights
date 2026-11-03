local C = require "constants"

data:extend({
    {
        type = "bool-setting",
        name = C.drag_preview_setting,
        setting_type = "startup",
        default_value = true,
    },
})
