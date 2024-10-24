local defsave = require "defsave.defsave"
local utils = require "modules/utils"

local M = {}


---@enum game_status
M.GAME_STATUS = {
    WIN = 1,
    LOSE = 2,
}


defsave.set_appname("machinist_touch_test")
defsave.default_data = require("statistics.default_data")
defsave.load("config")

---@param game_status game_status
function M.update_statistics(game_status)
    if game_status == M.GAME_STATUS.WIN then
        local win = defsave.get("config", "win")
        defsave.set("config", "win", win+1)
    else
        local win = defsave.get("config", "lose")
        defsave.set("config", "lose", win+1)
    end
    defsave.save("config")
end


function M.get_win_statistics()
    return defsave.get("config", "win")
end


function M.get_lose_statistics()
    return defsave.get("config", "lose")
end


return M