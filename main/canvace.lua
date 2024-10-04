Object = require "modules/classic"

Canvace = Object:extend()

function Canvace:new(width, height, sprite)
  self.sprite = sprite
  self.width = width
  self.height = height
  self:init()
end


function Canvace:init()
    msg.post(".", "acquire_input_focus")
    msg.post("@render:", "clear_color", {color = vmath.vector4(1, 1, 1, 1)})
    -- size of texture when scaled to nearest power of two
    local channels = 4
    -- we have to create table with next fields: buffer, width, height, channels
    self.buffer_info = {
        buffer = buffer.create(self.width * self.height, {{name = hash("rgba"), type = buffer.VALUE_TYPE_UINT8, count = channels}}),
        width = self.width,
        height = self.height,
        channels = channels -- 3 for rgb, 4 for rgba
    }
    self.dirty = true
    self.current_color = vmath.vector4(0, 0, 0, 1)
    self.current_tool = "pencil"

    -- drawing params
    self.prev_pos = nil
    self.resource_path = go.get(self.sprite, "texture0")
    self.header = {
        width = self.width,
        height = self.height,
        type = resource.TEXTURE_TYPE_2D,
        format = resource.TEXTURE_FORMAT_RGBA,
        num_mip_maps = 1
    }
    self.rotation = 0
    drawpixels.line(self.buffer_info, 0, 0, 1000, 1000, 0, 0, 0, 1, true, 10)
end


local function point_within_rectangle_centroid(point_x, point_y, rectangle_x, rectangle_y, rectangle_width, rectangle_height)
  local width_half = rectangle_width / 2
  local height_half = rectangle_height / 2
  if point_x >= (rectangle_x - width_half) and point_x <= (rectangle_x + width_half) then
    if point_y >= (rectangle_y - height_half) and point_y <= (rectangle_y + height_half) then
      return true
    end
  end
  return false
end


function Canvace:update(dt)
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


local function color_vector_to_bytes(color)
  return color.x * 255, color.y * 255, color.z * 255, color.w * 255
end


local function bytes_to_color_vector(r, g, b, a)
  return vmath.vector4(r / 255, g / 255, b / 255, a / 255)
end

---@param vector vector3
---@return unknown
local function to_string_vector(vector)
  return vector.x .. "; " .. vector.y .. "; " .. vector.z
end

function Canvace:draw_line(x, y)
  local world_pos = go.get_world_position()
  local pos = vmath.vector3(x - world_pos.x + self.width/2, y - world_pos.y + self.height/2, 0)

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
    local r, g, b, a = color_vector_to_bytes(self.current_color)
    drawpixels.filled_circle(self.buffer_info, pos.x, pos.y, 10, r, g, b, a, true)
    self.dirty = true
    pos = pos - dir
    length = length - 1
  end
end

function tprint (tbl, indent)
  if not indent then indent = 0 end
  local toprint = string.rep(" ", indent) .. "{\r\n"
  indent = indent + 2
  for k, v in pairs(tbl) do
    toprint = toprint .. string.rep(" ", indent)
    if (type(k) == "number") then
      toprint = toprint .. "[" .. k .. "] = "
    elseif (type(k) == "string") then
      toprint = toprint  .. k ..  "= "
    end
    if (type(v) == "number") then
      toprint = toprint .. v .. ",\r\n"
    elseif (type(v) == "string") then
      toprint = toprint .. "\"" .. v .. "\",\r\n"
    elseif (type(v) == "table") then
      toprint = toprint .. tprint(v, indent + 2) .. ",\r\n"
    else
      toprint = toprint .. "\"" .. tostring(v) .. "\",\r\n"
    end
  end
  toprint = toprint .. string.rep(" ", indent-2) .. "}"
  return toprint
end

---@param pressed bool
---@param released bool
---@param x float 
---@param y float 
function Canvace:_reigster_input(pressed, released, x, y)
  if pressed then self.drawing = true
  elseif released then self.drawing = false end

  if self.drawing == false then
    self.prev_pos = nil
    return
  end

  local world_pos = go.get_world_position()
  if point_within_rectangle_centroid(x, y, world_pos.x, world_pos.y, self.width, self.height) then
    self:draw_line(x, y)
  end 
end

function Canvace:on_input(action_id, action)
  -- if action_id == hash("touch") then
  --   self:_reigster_input(action.pressed, action.released, action.x, action.y)
  --   print("draw")
  -- end
  if action_id == hash("multi_touch") then
    for _, touchdata in ipairs(action.touch) do
      print("draw")
      self:_reigster_input(touchdata.pressed, touchdata.released, touchdata.x, touchdata.y)
    end
  end
end


return Canvace
