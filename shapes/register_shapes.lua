local M = {}

local shapes = {
    {
        name = "Квадрат",
        path_to_scheme = "/shapes/square/scheme.json",
        projection_id = "square",
    },
    {
        name = "Треугольник",
        path_to_scheme = "/shapes/triangle/scheme.json",
        projection_id = "triangle",
    }
}

function M.get_shapes()
    return shapes
end

return M