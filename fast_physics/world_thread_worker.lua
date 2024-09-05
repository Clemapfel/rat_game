require "common.common"

worker_to_main, main_to_worker, thread_id = ...

while true do
    --println(thread_id)
    local message = main_to_worker:demand()
end