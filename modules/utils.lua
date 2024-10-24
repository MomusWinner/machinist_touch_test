local M = {}

function M.tprint (tbl, indent)
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


---@param vector vector3
---@return string
function M.to_string_vector(vector)
  return vector.x .. "; " .. vector.y .. "; " .. vector.z
end


function M.point_within_rectangle_centroid(point_x, point_y, rectangle_x, rectangle_y, rectangle_width, rectangle_height)
  local width_half = rectangle_width / 2
  local height_half = rectangle_height / 2
  if point_x >= (rectangle_x - width_half) and point_x <= (rectangle_x + width_half) then
    if point_y >= (rectangle_y - height_half) and point_y <= (rectangle_y + height_half) then
      return true
    end
  end
  return false
end


function M.has_value(table, target)
  for index, value in ipairs(table) do
    if value == target then return true end
  end
  return false
end


---@param vector1 vector3
---@param vector2 vector3
---@return float angle
function M.angle_between_vector(vector1, vector2)
  local angle = math.deg(math.atan2(vector1.y, vector1.x))  - math.deg(math.atan2(vector2.y, vector2.x))
  angle = math.abs(angle)
  if angle > 180 then
    return 360 - angle
  end
  return angle
end


local start_seed = tonumber(hash_to_hex(hash(os.tmpname())), 16)
math.randomseed( start_seed)
math.random()
math.random()
local seed = os.time() + (os.clock()*1000000) + math.random(0, 65535)
math.randomseed(seed)
math.random()
math.random()

function M.rnd(from, to)
	return math.random(from, to)
end


function M.distance_point_to_segment(p1, p2, p)
  local normalize_segment = vmath.normalize(p2 - p1)
  local point_to_first_segment_p = p - p1
  local dot1 = vmath.dot(point_to_first_segment_p, normalize_segment)

  if dot1 <= 0 then
      return vmath.length(p - p1)
  end
  local c2 = vmath.dot(p2 - p1, normalize_segment)
  if c2 <= dot1 then
      return vmath.length(p - p2)
  end

  local b = dot1 / c2
  local pb = p1 + b * (p2 - p1)

  return vmath.length(p - pb)
end


return M
