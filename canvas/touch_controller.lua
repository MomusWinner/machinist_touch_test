Object = require "modules/classic"
utils = require "modules/utils"

TouchController = Object:extend()


---@param count number
function TouchController:new(count)
    self.index = 1
    self.count = count
    self.inputs = {}
    self.dir = nil
    print("create touch controller")
    for i = 1, self.count do
        self.inputs[i] = nil
    end
end


function TouchController:set_input(released, pressed, world_x, world_y)
    if released then
        self:reset() -- TODO invoked for left and right canvas
    elseif pressed then
        -- some logic
    end
    local pos = camera.screen_to_world(hash("/camera"), vmath.vector3(world_x, world_y,0))

    local new_input = vmath.vector3(pos.x, pos.y, 0)
    if new_input == self.inputs[self:previous_index()] then
        print("same -----------")
        return
    end
    self.inputs[self:next_index()] = new_input
    self.index = self:next_index()

    self:calculate_dir()
end


function TouchController:calculate_dir()
    if not self:is_inited() then
        self.dir = nil
        return
    end

    local new_dir = vmath.vector3(0,0,0)

    local last_index = self:next_index()

    local index = self:next_index(last_index)
    local count = self.count
    local input_dirs = {}
    while count ~= 0 do
        utils.tprint(table)
        table.insert(input_dirs, self.inputs[index] - self.inputs[last_index])
        index = self:previous_index(index)
        count = count - 1
    end

    for _, value in ipairs(input_dirs) do
        new_dir = new_dir + value
    end

    self.dir = vmath.normalize(new_dir)
end


function TouchController:is_inited()
    for i = 1, self.count do
        if self.inputs[i] == nil then
            return false
        end
    end
    return true
end


function TouchController:previous_index(index)
    if index == nil then
        index = self.index
     end
    if index == 1 then
        return self.count
    end
    return index - 1
end


function TouchController:next_index(index)
    if index == nil then
       index = self.index
    end
    if index == self.count then
        return 1
    end
    return index + 1
end


function TouchController:reset()
    for k, _ in pairs(self.inputs) do
        self.inputs[k] = nil
    end
    self.dir = nil
end


return TouchController
