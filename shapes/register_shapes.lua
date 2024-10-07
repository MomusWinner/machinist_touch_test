local M = {}

local shapes = {
    {
        name = "Квадрат",
        path_to_scheme = "/shapes/square/scheme.json",
        path_to_projection = "/shapes/square/square.png",
    }
}

function M.get_shapes()
    return shapes
end

return M