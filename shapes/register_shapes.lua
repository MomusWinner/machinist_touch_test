local M = {}

local shapes = {
    {
        name = "Квадрат",
        path_to_scheme = "/shapes/square/scheme.json",
        projection_id = "square",
    }
}

function M.get_shapes()
    return shapes
end

return M