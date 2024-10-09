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


function TouchController:on_input(action_id, action)
    if action_id == hash("touch") then
        print("on_input")
        if action.released then
            self:clear_inputs() -- TODO invoked for left and right canvas
            self.dir = nil
        elseif action.pressed then
            -- some logic
        end

        local new_input = vmath.vector3(action.x, action.y, 0)
        if new_input == self.inputs[self:previous_index()] then
            return
        end
        self.inputs[self:next_index()] = new_input
        self.index = self:next_index()

        self:calculate_dir()
        if self.dir == nil then
           print("new_dir is null") 
        else
            print("new_dir  " .. self.dir)
        end
    end
end


function TouchController:calculate_dir()
    if not self:is_inited() then
        self.dir = nil
        print("is not inited")
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


function TouchController:clear_inputs()
    for k, _ in pairs(self.inputs) do
        self.inputs[k] = nil
    end
end


return TouchController
