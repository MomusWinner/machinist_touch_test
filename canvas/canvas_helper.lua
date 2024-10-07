local M = {}

function M.color_vector_to_bytes(color)
    return color.x * 255, color.y * 255, color.z * 255, color.w * 255
end


function M.bytes_to_color_vector(r, g, b, a)
    return vmath.vector4(r / 255, g / 255, b / 255, a / 255)
end


return M