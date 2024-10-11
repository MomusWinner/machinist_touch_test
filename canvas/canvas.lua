Drawer = require "canvas.drawer"
TouchController = require "canvas.touch_controller"
helper = require "canvas.canvas_helper"
utils = require "modules/utils"

Canvas = Drawer:extend()

CORRRECT_DIR_ANGLE = 30
DESTINATION_TO_POINT_DISTANSE = 40

GAME_STATES = {
  Init = 1,
  Draw = 2,
  End = 3
}

function Canvas:new(width, height, sprite)
  Drawer.super.new(self, width, height, sprite)
  self.points = nil -- table
  self.current_point = nil -- table
  self.next_point = nil -- table

  self.touch_controller = TouchController(10)

  self.current_touch_pos = vmath.vector3(0,0,0) --vector3
  self.is_pressing = false --bool
  self.start_drawing = false -- bool
  self.state = GAME_STATES.Init
end


---@param name string
---@param schema table
---@param projection string
function Canvas:start_canvas(name, schema, projection)
  self.points = schema.points
  self:creat_points()
  local point = self:select_random_point()
  self:show_point(point)
  print(projection)
  msg.post("#projection", "play_animation", {id = hash(projection)})
  self.current_point = point
  self.state = GAME_STATES.Init
end


function Canvas:on_message(message_id, message, sender)
  if message_id == hash("start_canvas") then
    self:start_canvas(message.name, message.poin_scheme, message.projection)
  end
end


function Canvas:update(dt)
  if self.state == GAME_STATES.Draw then
    Drawer.super.update(self, dt)
    self:process_drawing()
  end
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

  -- TODO need optimization
  if self.current_point ~= nil and self.next_point ~= nil and self.touch_controller.dir ~= nil then
    is_correct_path = self:is_correct_movement_direction()
    if is_correct_path then
      self:set_game_state(GAME_STATES.Draw)
    else
      self:set_game_state(GAME_STATES.End)
    end
  end
end

---@param state integer
function Canvas:set_game_state(state)
  if state == GAME_STATES.Draw then
    msg.post("#bg", "play_animation", {id = hash("draw_background")})
  elseif state == GAME_STATES.End  then
    self.state = GAME_STATES.End
    msg.post("#bg", "play_animation", {id = hash("red_background")})
  end
end


function Canvas:pointer_inside_some_point()
  if self.points == nil then
    return false
  end
  for _, point in ipairs(self.points) do
    if vmath.length(self.current_touch_pos - self:_cube_pos_to_global(point.x, point.y)) < DESTINATION_TO_POINT_DISTANSE then
      print("distance " ..vmath.length(self.current_touch_pos - self:_cube_pos_to_global(point.x, point.y)))
      return true
    end
  end
  return false
end


function Canvas:on_input(action_id, action)
  if self.state == GAME_STATES.Draw then
    Drawer.super.on_input(self, action_id, action)
  end
  local canvas_pos = go.get_world_position()
  if action_id == hash("multi_touch") then
    for _, touchdata in ipairs(action.touch) do
      if utils.point_within_rectangle_centroid(touchdata.x, touchdata.y, canvas_pos.x, canvas_pos.y, self.width, self.height) then
        self:process_input(touchdata)
        break
      end
    end
  end
  if action_id == hash("touch") then
    if utils.point_within_rectangle_centroid(action.x, action.y, canvas_pos.x, canvas_pos.y, self.width, self.height) then
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
  if self.state == GAME_STATES.Init then
    local point_pos = self:_cube_pos_to_global(self.current_point.x, self.current_point.y)
    local touch_in_start_point = utils.point_within_rectangle_centroid(input.x, input.y,
      point_pos.x, point_pos.y, DESTINATION_TO_POINT_DISTANSE * 2, DESTINATION_TO_POINT_DISTANSE * 2)
    if touch_in_start_point then
      self.state = GAME_STATES.Draw
      print("Game state draw")
    else
      print("Game state end")
    end
  end
  self.touch_controller:set_input(input)
  self.current_touch_pos = vmath.vector3(input.x, input.y, 0)
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
    local pos = self:_cube_pos_to_global(point.x, point.y)
    pos.z = 0.9
    local id = factory.create("#point_factory", pos, nil)
    table.insert(self.point_views, id)
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
  local angle = (utils.angle_between_vector(dir1, dir2))
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
      self:show_point(self.next_point)
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
