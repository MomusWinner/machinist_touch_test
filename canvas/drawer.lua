Object = require "modules/classic"
helper = require "canvas.canvas_helper"
utils = require "modules/utils"
camera = require "orthographic.camera"

Canvas = Object:extend()

function Canvas:new(texture_width, texture_height, width, height, sprite)
  self.texture_width = texture_width
  self.texture_height = texture_height
  self.sprite = sprite
  self.width = width
  self.height = height
  self:init()
end


function Canvas:init()

    msg.post(".", "acquire_input_focus")
    msg.post("@render:", "clear_color", {color = vmath.vector4(1, 1, 1, 1)})

    -- size of texture when scaled to nearest power of two
    local channels = 4
    -- we have to create table with next fields: buffer, width, height, channels
    self.buffer_info = {
        buffer = buffer.create(self.texture_width * self.texture_height, {{name = hash("rgba"), type = buffer.VALUE_TYPE_UINT64, count = channels}}),
        width = self.texture_width,
        height = self.texture_height,
        channels = channels -- 3 for rgb, 4 for rgba
    }
    self.dirty = true
    self.current_color = vmath.vector4(0, 0, 0, 1)
    self.current_tool = "pencil"

    -- drawing params
    self.prev_pos = nil
    self.resource_path = go.get(self.sprite, "texture0")
    self.header = {
        width = self.texture_width,
        height = self.texture_height,
        type = resource.TEXTURE_TYPE_2D,
        format = resource.TEXTURE_FORMAT_RGBA,
        num_mip_maps = 1
    }
    self.rotation = 0
   
end


function Canvas:update(dt)
  -- update texture if it's dirty (ie we've drawn to it)
  if self.dirty then
    resource.set_texture(self.resource_path, self.header, self.buffer_info.buffer)
    self.dirty = false
  end
  self.rotation = self.rotation + 1
  if self.rotation > 360 then
    self.rotation = 0
  end
end


---@param x float
---@param y float
function Canvas:_position_by_offest(x, y)
    local world_pos = go.get_world_position()
    local x = (x - world_pos.x + self.width/2) * (self.texture_width/ self.width)
    local y = (y - world_pos.y + self.height/2) * (self.texture_width/ self.width)
    return vmath.vector3(x, y, 0)
end


function Canvas:draw_line(x, y)
  local pos = self:_position_by_offest(x, y)

  local length = 1
  local dir = vmath.vector3(0)
  if self.prev_pos ~= nil then
    local new_length = math.ceil(vmath.length(pos - self.prev_pos))
    if new_length ~= 0 then
      -- calculate the length and direction from the previous touch
      -- position to the current position
      length = new_length
      dir = vmath.normalize(pos - self.prev_pos)
    end
  end
 
  if self.prev_pos == pos then
    return false
  end

  self.prev_pos = pos
  -- use current tool from the previous touch position to
  -- the current touch local world_pos = go.get_world_position()position0
  while length > 0 do
    local r, g, b, a = helper.color_vector_to_bytes(self.current_color)
    drawpixels.filled_circle(self.buffer_info, pos.x, pos.y, 15, r, g, b, a, false)
    self.dirty = true
    pos = pos - dir
    length = length - 1
  end
end


---@param pressed bool
---@param released bool
---@param x float 
---@param y float 
function Canvas:_reigster_input(pressed, released, x, y)
  if pressed then self.drawing = true
  elseif released then self.drawing = false end

  if self.drawing == false then
    self.prev_pos = nil
    return
  end

  local world_pos = go.get_world_position()
  local pos = camera.screen_to_world(hash("/camera"), vmath.vector3(x,y,0))

  if utils.point_within_rectangle_centroid(pos.x, pos.y, world_pos.x, world_pos.y, self.width, self.height) then
    self:draw_line(pos.x, pos.y)
  end 
end

function Canvas:on_input(action_id, action)
  if action_id == hash("touch") then
    self:_reigster_input(action.pressed, action.released, action.x, action.y)
  end
  if action_id == hash("multi_touch") then
    for _, touchdata in ipairs(action.touch) do
      self:_reigster_input(touchdata.pressed, touchdata.released, touchdata.x, touchdata.y)
    end
  end
end


function Canvas:final()
  self:clear()
end

function Canvas:clear()
  drawpixels.fill(self.buffer_info, 0, 0, 0, 0)
  resource.set_texture(self.resource_path, self.header, self.buffer_info.buffer)
end


function Canvas:__tostring()
  return "Drawer" .. "width " .. self.width .. ", height " .. self.height
end

return Canvas