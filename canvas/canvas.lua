Drawer = require "canvas.drawer"
TouchController = require "canvas.touch_controller"
helper = require "canvas.canvas_helper"
utils = require "modules/utils"

Canvas = Drawer:extend()

CORRRECT_DIR_ANGLE = 30
DESTINATION_TO_POINT_DISTANSE = 30

function Canvas:new(width, height, sprite)
  Drawer.super.new(self, width, height, sprite)

  self.points = nil
  self.current_point = nil
  self.next_point = nil

  self.touch_controller = TouchController(3)

  self.current_touch_pos = vmath.vector3(0,0,0)
  self.is_pressing = false
end


function Canvas:_cube_pos_to_global(x, y)
  local world_pos = go.get_world_position()
  return vmath.vector3(world_pos.x - self.width/2 + x, world_pos.y - self.height/2 + y, 0)
end


function Canvas:clean_points()
  if self.point_views == nil then
    self.point_views = {}
    return
  else
    self.point_views = {} -- TODO remove old points
  end 
end


function Canvas:creat_points()
  self:clean_points()
  for _, point in ipairs(self.points) do
    local id = factory.create("#point_factory", self:_cube_pos_to_global(point.x, point.y), nil)
    table.insert(self.point_views, id)
  end
end


---@param name string
---@param schema table
---@param projection any
function Canvas:start_canvas(name, schema, projection)
  self.points = schema.points
  self:creat_points()
  local point = self:select_random_point()
  self:show_point(point)
  self.current_point = point
end


function Canvas:on_message(message_id, message, sender)
  if message_id == hash("start_canvas") then
    self:start_canvas(message.name, message.poin_scheme, message.projection)
  end
end


function Canvas:update(dt)
  Drawer.super.update(self, dt)
  if not self.is_pressing then
    return
  end
  if self.next_point == nil then
    self:try_select_first_next_point()
  end
  if self.current_point ~= nil and self.next_point ~= nil and self.touch_controller.dir ~= nil then
    is_correct_path = self:is_correct_movement_direction()
    if is_correct_path then
    else
      -- print("GAME OVER")
    end
  end

  if self.next_point ~= nil and self.current_point ~= nil then
    local next_pos = self:_cube_pos_to_global(self.next_point.x, self.next_point.y)
    if vmath.length_sqr(self.current_touch_pos - next_pos) < DESTINATION_TO_POINT_DISTANSE then
      self:set_new_next_point()
    end
  end
end


function Canvas:on_input(action_id, action)
  Drawer.super.on_input(self, action_id, action)
  self.touch_controller:on_input(action_id, action)

  if action_id == hash("touch") then
    if action.released then
      self.is_pressing = false
    elseif action.pressed then
      self.is_pressing = true
    end

    self.current_touch_pos = vmath.vector3(action.x, action.y, 0)
  end
end


function Canvas:select_random_point()
  math.randomseed(os.time())
	local rand_index = math.random(1, utils.len(self.points))
  return self.points[rand_index]
end


function Canvas:show_point(point)
  print("show point: " .. point.x, point.y)
  print("creation pos" .. self:_cube_pos_to_global(point.x, point.y))
  local pos = self:_cube_pos_to_global(point.x, point.y)
  pos.z = 1
  local id = factory.create("#start_point_factory", pos, nil)
  print(id)
end


function Canvas:point_in_touch_dir(pos)
  if self.touch_controller.dir == nil then return false end
  local dir1 = self.touch_controller.dir
  local dir2 = pos - self.current_touch_pos
  local angle = math.abs(utils.angle_between_vector(dir1, dir2))
  -- print("angle " .. angle .. "| dir1" .. dir1)
  if angle < CORRRECT_DIR_ANGLE then
    return true
  end
  return false
end

function Canvas:try_select_first_next_point()
  if self.current_touch_pos == nil or self.current_point == nil or self.touch_controller.dir == nil then
    return
  end

  for _, point in ipairs(self.points) do
    if point then
      if utils.has_value(point.relation, self.current_point.id) then
        local selected = self:point_in_touch_dir(self:_cube_pos_to_global(point.x, point.y))
        if selected then
          self.next_point = point
          self:show_point(self.next_point)
        end
      end
    end
  end
end

function Canvas:set_new_next_point()
  print("set new next point")
  for _, id in ipairs(self.next_point.relation) do
    
    if id ~= self.current_point.id then
      self.current_point = self.next_point
      self.next_point = self:get_point_by_id(id)
      self:show_point(self.next_point)
      print("new point is " .. self.next_point.x)
      break;
    end
  end
end


function Canvas:is_correct_movement_direction()
  local pos = self:_cube_pos_to_global(self.next_point.x, self.next_point.y)
  if self:point_in_touch_dir(pos) then
    return true
  end
  return false
end


---@param id integer
function Canvas:get_point_by_id(id)
  for _, value in ipairs(self.points) do
    if value.id == id then
      return value
    end
  end
  return nil
end

return Canvas
