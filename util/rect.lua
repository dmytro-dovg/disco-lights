local Rect = {}

---@class Rect
---@field position { x: float, y: float }
---@field size { width: float, height: float }

---@param rect Rect
---@param other Rect
---@return boolean
function Rect.is_in_rect(rect, other)
    return other.position.x <= rect.position.x and
        other.position.x + other.size.width >= rect.position.x + rect.size.width and
        other.position.y <= rect.position.y and
        other.position.y + other.size.height >= rect.position.y + rect.size.height
end

---@param x number
---@param y number
---@param width number
---@param height number
---@return Rect
function Rect.new(x, y, width, height)
    return {
        position = {
            x = x,
            y = y,
        },
        size = {
            width = width,
            height = height
        }
    }
end

---@param box BoundingBox
---@return table
function Rect.from_bounding_box(box)
    return Rect.new(box.left_top.x,
        box.left_top.y,
        box.right_bottom.x - box.left_top.x,
        box.right_bottom.y - box.left_top.y)
end

return Rect
