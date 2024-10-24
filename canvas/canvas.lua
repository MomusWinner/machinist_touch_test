local Object = require "modules/classic"
local utils = require "modules/utils"
local Point = require "canvas.point.point"
local camera = require "orthographic.camera"


---@class Canvas
Canvas = Object:extend()


---@enum canvas_types
Canvas.TYPES = {
  Left = 1,
  Right = 2,
}

---@enum canvas_states
CANVAS_STATES = {
  Init = 1,
  Draw = 2,
  End = 3
}

local CAMERA = hash("/camera")
local DESTINATION_TO_POINT_DISTANCE = 40

local CANVAS_MANAGER = "canvas_manager#canvas_manager"


local function cube_pos_to_global(x, y, width, height)
  local world_pos = go.get_world_position()
  return vmath.vector3(world_pos.x - width/2 + x, world_pos.y - height/2 + y, 0)
end


---@param width integer
---@param height integer
---@param type canvas_types
function Canvas:new(width, height, type)
  msg.post(".", "acquire_input_focus")
  self.width = width                            ---@type integer
  self.height = height                          ---@type integer

  self.type = type                              ---@type canvas_types
  self.points = {}                              ---@type { [string]: Point }
  self.current_point = nil                      ---@type Point?
  self.start_point = nil                        ---@type Point?
  self.current_line = nil                       ---@type string? go id
  self.completed_point_ids = {}                 ---@type integer[]

  self.current_touch_pos = vmath.vector3(0,0,0) ---@type vector3
  self.previous_touch_pos = nil                 ---@type vector3?

  self.is_pressing = false                      ---@type boolean
  self.state = CANVAS_STATES.Init               ---@type canvas_states  

  self.speed = 0                                ---@type number
  self.is_ready = false                         ---@type boolean
  self.first_point_obj = nil                    ---@type string? go id
  self.delete_on_finish_go = {}                 ---@type string[]
end


function Canvas:update(dt)
  if self.state == CANVAS_STATES.Draw then
    if self.current_touch_pos ~= nil then
      if vmath.length(self.current_touch_pos) ~= 0 then
        self:update_line(self.current_touch_pos)
      end
    end

    local point = self:pointer_inside_some_point()
    if point ~= nil then
      if self:is_next_point(point) then
        self:set_current_point(point)
      end
    end

    if self:is_incorrect() then
      msg.post(CANVAS_MANAGER ,"bad_drawing")
    elseif self:is_done() then
      self:set_current_point(self.start_point)
      msg.post(CANVAS_MANAGER ,"complete")
    end
  end
end


function Canvas:final()
  while #self.delete_on_finish_go ~= 0 do
    local d_go = table.remove(self.delete_on_finish_go)
    print(d_go)
    go.delete(d_go, true)
  end
  if self.first_point_obj then
    go.delete(self.first_point_obj, true)
  end
end


function Canvas:on_message(message_id, message, sender)
  if message_id == hash("start_canvas") then        -- start_canvas
    self:start_canvas(message.name, message.point_scheme, message.projection)
  elseif message_id == hash("set_error_state") then -- set_error_state
    self:set_error_state()
  elseif message_id == hash("draw") then            -- draw
    self.state = CANVAS_STATES.Draw
    self:clear_first_point_obj()
  elseif message_id == hash("success_end") then     -- success_end
    msg.post("#bg", "play_animation", {id=hash("green_background")})
    self.state = CANVAS_STATES.End
  end
end


function Canvas:on_input(action_id, action)
  local canvas_pos = go.get_world_position()
  if action_id == hash("multi_touch") then
    for _, touch_data in ipairs(action.touch) do
      local pos = camera.screen_to_world(CAMERA, vmath.vector3(touch_data.x,touch_data.y,0))
      if utils.point_within_rectangle_centroid(pos.x, pos.y, canvas_pos.x, canvas_pos.y, self.width, self.height) then
        self:process_input(touch_data)
        break
      end
    end
  end
  if action_id == hash("touch") then
    local pos = camera.screen_to_world(CAMERA, vmath.vector3(action.x, action.y,0))
    if utils.point_within_rectangle_centroid(pos.x, pos.y, canvas_pos.x, canvas_pos.y, self.width, self.height) then
      self:process_input(action)
    end
  end
end


---@param name string
---@param schema table
---@param projection string
function Canvas:start_canvas(name, schema, projection)
  self:set_points(schema.points)
  self:create_points()
  local start_point = self:select_random_point()
  self:create_first_point_obj(start_point)
  msg.post("#projection", "play_animation", {id = hash(projection)})
  msg.post("#bg", "play_animation", {id = hash("draw_background")})
  self:set_current_point(start_point)
  self.start_point = start_point
  self.state = CANVAS_STATES.Init
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
  local pos = camera.screen_to_world(CAMERA, vmath.vector3(input.x, input.y,0))
  if self.state == CANVAS_STATES.Init then
    local point_pos = self.current_point.pos
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
  self.current_touch_pos = vmath.vector3(pos.x, pos.y, 0)
end


---@param new_points Point
function Canvas:set_points(new_points)
  for _, point in ipairs(new_points) do
    local world_pos = cube_pos_to_global(point.x, point.y, self.width, self.height)
    local new_point = Point(point.id, vmath.vector3(world_pos.x, world_pos.y, 0), point.relation)
    self.points[point.id] = new_point
  end
end


---@param position vector3
function Canvas:create_line(position)
  position.z = 0.5
  local line = factory.create("#line_factory")
  go.set_position(position, line)
  table.insert(self.delete_on_finish_go, line)
  return line
end


---@param target_position vector3
function Canvas:update_line(target_position)
  local dist2d = function(x1, y1, x2, y2) return ((x2-x1)^2+(y2-y1)^2)^0.5 end
  local angle_of_vector_between_two_points = function(x1,y1, x2,y2) return math.atan2(y2-y1, x2-x1) end

  local position = go.get_world_position(self.current_line)
  local distance = dist2d(position.x, position.y, target_position.x, target_position.y)
  local scale = go.get_scale(self.current_line)
  if distance > 0 then
    scale.x = distance
  end
  go.set_scale(scale, self.current_line)
  local direction = angle_of_vector_between_two_points(position.x, position.y, target_position.x, target_position.y)
  local rotation = vmath.quat_rotation_z(direction)
  go.set_rotation(rotation, self.current_line)
end


function Canvas:is_incorrect()
  local point = self:pointer_inside_some_point()
  if point == nil or point == self.current_point then
    return false
  end
  if not utils.has_value(self.current_point.relation, point.id) then
    return true
  end
  return false
end


---@param new_point Point
function Canvas:set_current_point(new_point)
  if self.current_point ~= nil then
    self:update_line(new_point.pos)
  end
  self.current_point = new_point
  self.current_line = self:create_line(new_point.pos)
  table.insert(self.completed_point_ids, self.current_point.id)
end


function Canvas:calculate_speed(dt)
  local function lerpdt(from, to, rate, dt)
    local diff = from - to
    return diff * (1 - rate)^dt + to
  end

  if self.previous_touch_pos == nil then
    self.speed = 0
  else
    local dist_length = vmath.length(self.current_touch_pos - self.previous_touch_pos)
    self.speed =  lerpdt(self.speed, dist_length/dt, 0.93, dt)
    msg.post(GUI, "update_speed", {speed = self.speed, type = self.type})
  end 
  self.previous_touch_pos = self.current_touch_pos
end


---@param point Point
function Canvas:is_next_point(point)
  for _, id in ipairs(self.completed_point_ids) do
    if point.id == id then
      return false
    end
  end

  for _, id in ipairs(point.relation) do
    if id == self.current_point.id then
      return true
    end
  end
  return false
end


function Canvas:is_done()
  if #self.completed_point_ids == #self.points then
      local point_pos = self.start_point.pos
      local touch_in_start_point = utils.point_within_rectangle_centroid(
        self.current_touch_pos.x, self.current_touch_pos.y,
        point_pos.x, point_pos.y,
        DESTINATION_TO_POINT_DISTANCE * 2, DESTINATION_TO_POINT_DISTANCE * 2)
      return touch_in_start_point
  end
  return false
end


function Canvas:pointer_inside_some_point()
  if self.points == nil then
    return nil
  end
  for _, point in ipairs(self.points) do
    local distance_to_point = self.current_touch_pos - point.pos
    if vmath.length(distance_to_point) < DESTINATION_TO_POINT_DISTANCE then
      return point
    end
  end
  return nil
end


function Canvas:set_error_state()
  self.state = CANVAS_STATES.End
  msg.post("#bg", "play_animation", {id = hash("red_background")})
end


function Canvas:create_points()
  for _, point in ipairs(self.points) do
    local pos = point.pos
    pos.z = 0.9
    local id = factory.create("#point_factory", pos, nil)
    table.insert(self.delete_on_finish_go, id)
  end
end


function Canvas:select_random_point()
	local rand_index = utils.rnd(1, #self.points)
  return self.points[rand_index]
end


---@param point Point
function Canvas:create_first_point_obj(point)
  local pos = point.pos
  pos.z = 1
  self.first_point_obj = factory.create("#start_point_factory", pos, nil)
end


function Canvas:clear_first_point_obj()
  if self.first_point_obj then
    go.delete(self.first_point_obj)
    self.first_point_obj = nil
  end
end


return Canvas
