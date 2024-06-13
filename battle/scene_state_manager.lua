--[[

]]--

--- @class bt.SceneStateManager
bt.SceneStateManager = meta.new_type("BattleSceneStateManager", function(scene)
    return meta.new(bt.SceneStateManager, {
        _scene = scene,
        _last_state = nil,
        _move_choices = {}, -- Table<bt.Entity, bt.ActionChoice>
        _state_map = {}, -- cf. start_turn
    })
end)

--- @brief
function bt.SceneStateManager:start_turn()
    local scene = self._scene

    -- order enemy by priority
    local order = scene._state:list_entities_in_order()
    local enemies, party = {}, {}
    for entity in values(order) do
        if entity:get_is_enemy() then
            table.insert(enemies, entity)
        else
            table.insert(party, entity)
        end
    end

    -- but party by sprite order
    table.sort(party, function(a, b)
        return scene:get_sprite(a):get_bounds().x < scene:get_sprite(b):get_bounds().x
    end)

    self._move_choices = {}

    -- first: trigger enemy AI
    for enemy in values(enemies) do
        self._move_choices[enemies] = bt.EnemyAI.choose(enemy, scene._state)
    end

    -- turn order state machine
    local move_select = {}
    local inspect = {}

    local simulation = {
        state = bt.SceneState.SIMULATION(scene),
        [rt.InputButton.A] = nil,
        [rt.InputButton.B] = nil,
        [rt.InputButton.X] = nil,
        [rt.InputButton.Y] = nil
    }

    for entity_i = 1, #party do
        local ally = party[entity_i]
        local is_first = entity_i == 1
        local is_last = entity_i == #party

        -- MOVE SELECT
        move_select[entity_i] = {
            state = bt.SceneState.MOVE_SELECT(scene, ally),
            [rt.InputButton.A] = function(self)
                return {
                    -- ENTITY_SELECT (depends on previous state)
                    state = bt.SceneState.ENTITY_SELECT(scene, self.state:get_user(), self.state:get_move()),
                    [rt.InputButton.A] = function(self) return ternary(is_last, simulation, move_select[entity_i + 1]) end,
                    [rt.InputButton.B] = function(self) return move_select[entity_i] end,
                    [rt.InputButton.X] = nil,
                    [rt.InputButton.Y] = nil
                }
            end,
            [rt.InputButton.B] = ternary(is_first, nil, function(self) return move_select[entity_i - 1] end),
            [rt.InputButton.X] = nil,
            [rt.InputButton.Y] = function(self) return inspect[entity_i] end,
        }

        -- INSPECT
        inspect[entity_i] = {
            state = bt.SceneState.INSPECT(scene),
            [rt.InputButton.A] = nil,
            [rt.InputButton.B] = function(self) return move_select[entity_i] end,
            [rt.InputButton.X] = nil,
            [rt.InputButton.Y] = nil
        }
    end

    -- cache nodes to keep references alive
    self._nodes = {simulation}
    for nodes in range(simulation, move_select) do
        for node in values(nodes) do
            table.insert(self._nodes, node)
        end
    end

    self._current_node = move_select[1]
    self._scene:transition(self._current_node.state)
end

--- @brief transition to next state based on button input
function bt.SceneStateManager:handle_button_pressed(button)
    if self._current_node ~= nil then
        local next_f = self._current_node[button]
        if next_f ~= nil then
            self._current_node = next_f(self._current_node)
            self._scene:transition(self._current_node.state)
        end
    end
end

--- @brief transition to next state based on button input
function bt.SceneStateManager:handle_button_released(button)
end