RESOURCE_PATH = "/home/clem/Workspace/rat_game/"
package.path = package.path .. ";" .. RESOURCE_PATH .. "lua/src/?.lua"
require "common"
require "meta"
require "queue"

println(Queue)
queue = Queue()
queue:push_back("test")
queue:push_front("front")

println(queue)