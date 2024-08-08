require "love.filesystem"
require "common.common"
require "common.log"

main_to_worker, prefix = ...

while true do
    local data = main_to_worker:demand()

    local file_name = os.date("%y%m%d_%H%M%S") .. ".save"

    local file_save = love.filesystem.newFile(prefix .. "/" .. file_name)

    local serialized = "return " .. serialize(data)
    local success, error = file_save:write()
    if success ~= true then
        rt.warning("In save_file_thread: error when trying to write `" .. file_name .. "`: " .. error)
    end

    file_save:flush()
    file_save:close()



end

