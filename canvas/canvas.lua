Drawer = require "canvas.drawer"
helper = require "canvas.canvas_helper"
utils = require "modules/utils"

Canvas = Drawer:extend()

function Canvas:new(width, height, sprite)
  Drawer.super.new(self, width, height, sprite)
end


function Canvas:_cube_pos_to_global(x, y)
  local world_pos = go.get_world_position()
  return vmath.vector3(world_pos.x - self.width/2 + x, world_pos.y - self.height/2 + y, 0)
end


function Canvas:clean_points()
  if self.points == nil then
    self.points = {}
    return
  else
    self.points = {} -- TODO remove old points
  end 
end


function Canvas:creat_points(points)
  self:clean_points()
  for _, point in ipairs(points) do
    print("x: " .. point.x .. " y: " .. point.y)
    local id = factory.create("#point_factory", self:_cube_pos_to_global(point.x, point.y), nil)
    table.insert(self.points, id)
  end
end


---@param name string
---@param schema table
---@param projection any
function Canvas:start_canvas(name, schema, projection)
  print("Start " .. name)
  self:creat_points(schema.points)
end


function Canvas:on_message(message_id, message, sender)
  if message_id == hash("start_canvas") then
    self:start_canvas(message.name, message.poin_scheme, message.projection)
  end
end


function Canvas:update(dt)
  Drawer.super.update(self, dt)
end


function Canvas:on_input(action_id, action)
  Drawer.super.on_input(self, action_id, action)
end


return Canvas
