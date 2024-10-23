local Object = require "modules/classic"


local Point = Object:extend() ---@class Point


---@param id integer
---@param position vector3
---@param relation integer[] list of id
function Point:new(id, position, relation)
    self.id = id
    self.pos = position
    self.relation = relation
end


return Point
