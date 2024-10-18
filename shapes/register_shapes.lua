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
    },
    {
        name = "Прямой триугольник",
        path_to_scheme = "/shapes/straight_triangle/scheme.json",
        projection_id = "straight_triangle",
    },
    {
        name = "Ромб",
        path_to_scheme = "/shapes/rhomb/scheme.json",
        projection_id = "rhomb",
    },
    {
        name = "Птичка",
        path_to_scheme = "/shapes/bird/scheme.json",
        projection_id = "bird",
    },
    {
        name = "Странный прямоугольник",
        path_to_scheme = "/shapes/strange_quadrangle/scheme.json",
        projection_id = "strange_quadrangle",
    },
}

function M.get_shapes()
    return shapes
end

return M