Canvas = require "canvas.drawer"
TouchController = require "canvas.touch_controller"
helper = require "canvas.canvas_helper"
utils = require "modules/utils"


Canvas = Canvas:extend()

CAMERA = "/camera"

Canvas.TYPES = {
  Left = 1,
  Right = 2,
}

CANVAS_STATES = {
  Init = 1,
  Draw = 2,
  End = 3
}

local CORRRECT_DIR_ANGLE = 40
local EKSTRA_DIR_ANGLE = 80

local DESTINATION_TO_POINT_DISTANSE = 30
local SAVE_LINE_DISTANCE = 25

local CANVAS_MANAGER = "canvas_manager#canvas_manager"

function Canvas:new(texture_width, texture_height, width, height, sprite, type)
  Canvas.super.new(self, texture_width, texture_height, width, height, sprite)
  self.type = type --Canvas.TYPES
  self.points = nil -- table
  self.current_point = nil -- table
  self.next_point = nil -- table
  self.completed_point_count = 0 -- number

  self.touch_controller = TouchController(6)

  self.current_touch_pos = vmath.vector3(0,0,0) --vector3
  self.previous_touch_pos = nil --vector3|nil
  self.is_pressing = false -- bool
  self.start_drawing = false -- bool
  self.state = CANVAS_STATES.Init
  self.speed = 0 -- float
  self.is_ready = false -- boool

  self.first_point_obj = nil -- string id
end


---@param name string
---@param schema table
---@param projection string
function Canvas:start_canvas(name, schema, projection)
  self.points = schema.points
  self:creat_points()
  local start_point = self:select_random_point()
  self:create_first_point_obj(start_point)
  msg.post("#projection", "play_animation", {id = hash(projection)})
  self.current_point = start_point
  self.state = CANVAS_STATES.Init
end


function Canvas:on_message(message_id, message, sender)
  if message_id == hash("start_canvas") then
    self:start_canvas(message.name, message.poin_scheme, message.projection)
  elseif message_id == hash("set_error_state") then
    self:set_error_state()
  elseif message_id == hash("draw") then
    self.state = CANVAS_STATES.Draw
    self:clear_first_point_obj()
  elseif message_id == hash("success_end") then
    msg.post("#bg", "play_animation", {id=hash("green_background")})
    self.state = CANVAS_STATES.End
  end
end


function Canvas:update(dt)
  if self.state == CANVAS_STATES.Draw then
    self:calculate_speed(dt)
    Canvas.super.update(self, dt)
    self:process_drawing()
  end
end


function Canvas:final()
  Canvas.super.final(self)
end

local function lerpdt(from, to, rate, dt)
	local diff = from - to
	return diff * (1 - rate)^dt + to
end

function Canvas:calculate_speed(dt)
  if self.previous_touch_pos == nil then
    self.speed = 0
  else
    local dist_length = vmath.length(self.current_touch_pos - self.previous_touch_pos)
    self.speed =  lerpdt(self.speed, dist_length/dt, 0.93, dt)
    msg.post(GUI, "update_speed", {speed = self.speed, type = self.type})
  end 
  self.previous_touch_pos = self.current_touch_pos
end


function Canvas:process_drawing()
  if self.next_point == nil then
    self:try_select_first_next_point()
  end

  if self.next_point ~= nil and self.current_point ~= nil then
    local next_pos = self:_cube_pos_to_global(self.next_point.x, self.next_point.y)
    if vmath.length(self.current_touch_pos - next_pos) < DESTINATION_TO_POINT_DISTANSE then
      self:set_new_next_point()
    end
  end

  if self:pointer_inside_some_point() then
    self.touch_controller:reset()
  end


  if self.current_point ~= nil and self.next_point ~= nil and self.touch_controller.dir ~= nil then
    is_correct_dir = self:is_correct_movement_direction()
    is_correct_dist = self:is_correct_distance_from_line()

    local is_correct_draw = false

    if is_correct_dir then
      is_correct_draw = true
    elseif is_correct_dist and self:is_correct_movement_direction(EKSTRA_DIR_ANGLE) then
      is_correct_draw = true
    end

    if is_correct_draw then
      msg.post("#bg", "play_animation", {id = hash("draw_background")})
    else
      msg.post(CANVAS_MANAGER, "bad_drawing")
    end
  end
end


function Canvas:pointer_inside_some_point()
  if self.points == nil then
    return false
  end
  for _, point in ipairs(self.points) do
    if vmath.length(self.current_touch_pos - self:_cube_pos_to_global(point.x, point.y)) < DESTINATION_TO_POINT_DISTANSE then
      return true
    end
  end
  return false
end


function Canvas:on_input(action_id, action)
  if self.state == CANVAS_STATES.Draw then
    Canvas.super.on_input(self, action_id, action)
  end
  local canvas_pos = go.get_world_position()
  if action_id == hash("multi_touch") then
    for _, touchdata in ipairs(action.touch) do
      local pos = camera.screen_to_world(hash("/camera"), vmath.vector3(touchdata.x,touchdata.y,0))
      if utils.point_within_rectangle_centroid(pos.x, pos.y, canvas_pos.x, canvas_pos.y, self.width, self.height) then
        self:process_input(touchdata)
        break
      end
    end
  end
  if action_id == hash("touch") then
    local pos = camera.screen_to_world(hash("/camera"), vmath.vector3(action.x, action.y,0))
    if utils.point_within_rectangle_centroid(pos.x, pos.y, canvas_pos.x, canvas_pos.y, self.width, self.height) then
      self:process_input(action)
    end
  end
end


function Canvas:process_input(input)
  if input.released then
    self.is_pressing = false
  elseif input.pressed then
    self.is_pressing = true
  end

  if not self.is_pressing and self.state == CANVAS_STATES.Draw then
    msg.post(CANVAS_MANAGER, "raised_finger")
  end
  local pos = camera.screen_to_world(hash("/camera"), vmath.vector3(input.x, input.y,0))
  if self.state == CANVAS_STATES.Init then
    local point_pos = self:_cube_pos_to_global(self.current_point.x, self.current_point.y)
    local touch_in_start_point = utils.point_within_rectangle_centroid(pos.x, pos.y,
      point_pos.x, point_pos.y, 20 * 2, 20 * 2)
    if touch_in_start_point then
      if not self.is_ready then
        msg.post(CANVAS_MANAGER, "ready")
        self.is_ready = true
      end
    elseif self.is_ready then
      msg.post(CANVAS_MANAGER, "not_ready")
      self.is_ready = false
    end
  end
  self.touch_controller:set_input(input.released, input.pressed, pos.x, pos.y)
  self.current_touch_pos = vmath.vector3(pos.x, pos.y, 0)
end


function Canvas:set_error_state()
  self.state = CANVAS_STATES.End
  msg.post("#bg", "play_animation", {id = hash("red_background")})
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
    self.point_views = {}
  end
end


function Canvas:creat_points()
  -- self:clean_points()
  -- for _, point in ipairs(self.points) do
  --   local pos = self:_cube_pos_to_global(point.x, point.y)
  --   pos.z = 0.9
  --   local id = factory.create("#point_factory", pos, nil)
  --   table.insert(self.point_views, id)
  -- end
end


function Canvas:select_random_point()
	local rand_index = utils.rnd(1, #self.points)
  return self.points[rand_index]
end


function Canvas:create_first_point_obj(point)
  local pos = self:_cube_pos_to_global(point.x, point.y)
  pos.z = 1
  self.first_point_obj = factory.create("#start_point_factory", pos, nil)
end


function Canvas:clear_first_point_obj()
  if self.first_point_obj then
    go.delete(self.first_point_obj)
  end
end


function Canvas:point_in_touch_dir(pos, target_angle)
  if self.touch_controller.dir == nil then return false end
  if target_angle == nil then target_angle = CORRRECT_DIR_ANGLE end
  local dir1 = self.touch_controller.dir
  local dir2 = pos - self.current_touch_pos
  local angle = (utils.angle_between_vector(dir1, dir2))
  if angle < target_angle then
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
          self:count_complete_point()
          break;
        end
      end
    end
  end
end


function Canvas:set_new_next_point()
  for _, id in ipairs(self.next_point.relation) do
    if id ~= self.current_point.id then
      self.current_point = self.next_point
      self.next_point = self:get_point_by_id(id)
      self:count_complete_point()
      break;
    end
  end
end


function Canvas:count_complete_point()
  self.completed_point_count = self.completed_point_count + 1
  if self.completed_point_count >= #self.points + 1 then
    msg.post(CANVAS_MANAGER, "complete")
  end
end


function Canvas:is_correct_movement_direction(angle)
  local pos = self:_cube_pos_to_global(self.next_point.x, self.next_point.y)
  if self:point_in_touch_dir(pos, angle) then
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


function Canvas:is_correct_distance_from_line()
  local cur_p = self:_cube_pos_to_global(self.current_point.x, self.current_point.y)
  local next_p = self:_cube_pos_to_global(self.next_point.x, self.next_point.y)
  return SAVE_LINE_DISTANCE > utils.distance_point_to_segment(cur_p, next_p, self.current_touch_pos)
end


return Canvas
