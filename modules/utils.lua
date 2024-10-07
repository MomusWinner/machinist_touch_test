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

---@param table table
---@return integer
function M.len(table)
  local length = 0

  for _, _ in pairs(table) do length = length + 1 end

  return length
end

return M