--- @class rt.Translation
rt.Translation = {}

--- @brief initialize translation table as immutable
function rt.initialize_translation(x)
    -- recursively replace all tables with proxy tables, such that when they are accessed, only the metatables are invoked
    local _as_immutable = function(t)
        return setmetatable({}, {
            __index = function(_, key)
                local value = t[key]
                if value == nil then
                    rt.warning("In rt.Translation: key `" .. key .. "` does not point to valid text")
                    return "(#" .. key .. ")"
                end
                return value
            end,

            __newindex = function(self, key, new_value)
                rt.error("In rt.Translation: trying to modify text atlas, but it is declared immutable")
            end
        })
    end

    local function _make_immutable(t)
        local to_process = {}
        local n_to_process = 0

        for k, v in pairs(t) do
            if meta.is_table(v) then
                t[k] = _as_immutable(v)
                table.insert(to_process, v)
                n_to_process = n_to_process + 1
            else
                assert(meta.is_string(v) or meta.is_function(v), "In rt.initialize_translation: unrecognized type: `" .. meta.typeof(v) .. "`")
            end
        end

        for i = 1, n_to_process do
            _make_immutable(to_process[i])
        end
        return _as_immutable(t)
    end

   meta.assert_table(x)
   return _make_immutable(x)
end

rt.Translation = rt.initialize_translation({
    -- mn.InventoryScene
    inventory_scene = {
        heading = "Inventory", -- <b> appened in inventory_scene
        sort_mode_by_id = "Sort by Default",
        sort_mode_by_quantity = "Sort by Quantity",
        sort_mode_by_name = "Sort By Name",
        control_indicator = {
            drop = "Drop",
            shared_list_up_down = "Select",
            deposit_item_f = function(name) return "Deposit" .. name end,
            take_item_f = function(name) return "Take" .. name end,
            equip_item_f = function(name) return "Equip" .. name end
        },
        template_load = "Load Template",
        template_rename = "Rename",
        template_delete = "Delete",
        shared_tab_select = "Select Tab",
        entity_tab_select = "Select Character",
        option_tab_select =  "Go To Options",

        move_node_place_f = function(name) return "Place" .. name end,
        move_node_swap_f = function(name) return "Swap" .. name end,
        move_node_take_f = function(name) return "Take" .. name end,
        move_node_unequip = "Unequip",
        move_node_sort = "Sort",

        equip_node_place_f = function(name) return "Place" .. name end,
        equip_node_swap_f = function(name) return "Swap" .. name end,
        equip_node_take_f = function(name) return "Take" .. name end,
        equip_node_unequip = "Unequip",
        equip_node_sort = "Sort",

        consumable_node_place_f = function(name) return "Place" .. name end,
        consumable_node_swap_f = function(name) return "Swap" .. name end,
        consumable_node_take_f = function(name) return "Take" .. name end,
        consumable_node_unequip = "Unequip",
        consumable_node_sort = "Sort",

        grabbed_object_bottom_right_indicator = "<color=RED_2><o>\u{00D7}</o></color>",

        template_confirm_dialog_f = function(name)
            return "Overwrite current Equipment?",
                "This will return all currently equipped items back to the shared inventory"
        end,

        template_delete_dialog_f = function(name)
            return "Delete Template \"" .. name .. "\" permanently?",
                "This action cannot be undone"
        end,

        template_apply_unsuccessful_dialog_f = function(name)
            return "Some Elements of Template \"" .. name .. "\" could not be applied", ""
        end
    },

    plus_minus = "\u{00B1}",
    infinity = "\u{221E}",

    equips = "Equip",
    consumables = "Consumable",
    moves = "Move",

    -- mn.VerboseInfoPanel.Item
    verbose_info = {
        hp_label = "HP",
        attack_label = "ATK",
        defense_label = "DEF",
        speed_label = "SPD",

        move_n_uses = "# Uses",
        move_priority = "Priority",
        move_power = "Power",
        move_0_power = "   \u{2501}", -- horizontal bar

        status_max_duration = "Max Duration",
        global_status_max_duration = "Max Duration",

        damage_dealt_label = "Damage",
        damage_taken_label = "Damage Taken",
        healing_performed_label = "Healing Done",
        healing_received_label = "Healing",

        template_created_on_f = function(date)
            return "Created: " .. date
        end,
        template_equipment_heading = "Equipment:",
        template_move_heading = "Moves:",

        no_moves = "<color=GRAY>(none)</color>",
        no_equips = "<color=GRAY>(none)</color>",
        no_consumables = "<color=GRAY>(none)</color>",

        entity_move_heading = "Moves:",
        entity_equip_heading = "Equips:",
        entity_consumable_heading = "Consumables:",

        entity_state_label = "State",
        entity_state_alive = "ALIVE",
        entity_state_dead = "DEAD",
        entity_state_knocked_out = "KO",

        move_targets_prefix_label = "Targets",
        move_single_target_no_self_no_ally_no_enemy = "Field",
        move_single_target_no_self_no_ally_yes_enemy = "Enemy",
        move_single_target_no_self_yes_ally_yes_enemy = "Other Ally",
        move_single_target_no_self_yes_ally_yes_enemy = "Other Ally or Enemy",
        move_single_target_yes_self_no_ally_no_enemy = "User",
        move_single_target_yes_self_no_ally_yes_enemy = "User or Enemy",
        move_single_target_yes_self_yes_ally_no_enemy = "Ally",
        move_single_target_yes_self_yes_ally_yes_enemy = "Ally or Enemy",
        move_multi_target_no_self_no_ally_no_enemy = "Field",
        move_multi_target_no_self_no_ally_yes_enemy = "All Enemies",
        move_multi_target_no_self_yes_ally_no_enemy = "All Other Allies",
        move_multi_target_no_self_yes_ally_yes_enemy = "Everyone except User",
        move_multi_target_yes_self_no_ally_no_enemy = "User",
        move_multi_target_yes_self_no_ally_yes_enemy = "User and All Enemies",
        move_multi_target_yes_self_yes_ally_no_enemy = "All Allies",
        move_multi_target_yes_self_yes_ally_yes_enemy = "Everyone",

        objects = {
            hp_title = "Health (<color=HP>HP</color>)",
            hp_description = "When a characters HP reaches 0, they are knocked out. If damaged while knocked out, they die",

            attack_title = "Attack (<color=ATTACK>ATK</color>)",
            attack_description = "For most moves, user's ATK increases damage dealt to the target",

            defense_title = "Defense (<color=DEFENSE>DEF</color>)",
            defense_description = "For most moves, target's DEF decreases damage dealt to target",

            speed_title = "Speed (<color=SPEED>SPD</color>)",
            speed_description = "Along with Move Priority, influences in what order participants act each turn",

            consumables_title = "Consumables \u{25CF}",
            consumables_description = "Consumable Description, TODO",

            equips_title = "Equips \u{2B23}",
            equips_description = "Equip Description, TODO",

            moves_title = "Moves \u{25A0}",
            moves_description = "Move Description, TODO",

            templates_title = "Templates",
            templates_description = "Template Description, TODO",

            options_title = "Options",
            options_description = "Option Description, TODO",

            vsync_title = "Vertical Synchronization",
            vsync_description = "Synchronizes game refresh rate with that of the screen, preventing screen tearing. When 'adaptive', dynamically turns of vsync depending on the frame rate. When `off`, frame rate is no longer capped by the monitor refresh rate.",

            vfx_title = "Background Intensity",
            vfx_description = "Changes brightness of animated backgrounds",

            text_speed_title = "Text Scrolling Speed",
            text_speed_description = "Modifies text scroll speed in battle and during dialog",

            msaa_title = "Multi-sample Anti Aliasing (MSAA)",
            msaa_description = "Reduces artifacting along lines and sharp edges, but decreases performance",

            fullscreen_title = "Fullscreen",
            fullscreen_description = "Whether the window should fill the entire screen",

            resolution_title = "Screen Resolution",
            resolution_description = "Resolution of the window, also sets minimum size.",

            sound_effects_title = "Sound Effect Audio Level",
            sound_effects_description = "Loudness of all sounds except music",

            music_title = "Music Audio Level",
            music_description = "Loudness of music",

            visual_effects_title = "Background Intensity",
            visual_effects_description = "Intensity of background TODO",

            deadzone_title = "Controller Deadzone",
            deadzone_description = "Minimum distance from center the joysticks have to be moved for an input to register",

            keymap_title = "Controls",
            keymap_description = "Remap keyboard / controller controls",

            battle_log_title = "Battle Log",
            battle_log_description = "View past battle messages",

            quicksave_title = "Quick Save",
            quicksave_description = "TODO",
            quicksave_n_turns_passed_prefix_label = "# Turns"
        }
    },

    -- mn.OptionsScene
    options_scene = {
        heading = "<b>Inventory > Settings</b>",

        vsync = "VSync",
        vsync_on = "ON",
        vsync_off = "OFF",
        vsync_adaptive = "ADAPTIVE",

        fullscreen = "Fullscreen",
        fullscreen_on = "YES",
        fullscreen_off = "NO",

        msaa = "MSAA",
        msaa_off = "0",
        msaa_good = "2",
        msaa_better = "4",
        msaa_best = "8",
        msaa_max = "16",

        resolution = "Resolution",
        resolution_1280_720 = "1280x720 (16:9)",
        resolution_1366_768 = "1366x768 (16:9)",
        resolution_1600_900 = "1600x900 (16:9)",
        resolution_1920_1080 = "1920x1080 (16:9)",
        resolution_2560_1440 = "2560x1400 (16:9)",

        resolution_1280_800 = "1280x800 (16:10)",
        resolution_1440_900 = "1440x900 (16:10)",
        resolution_1680_1050 = "1680x1050 (16:10)",
        resolution_1920_1200 = "1920x1200 (16:10)",
        resolution_2560_1600 = "2560x1600 (16:10)",

        resolution_2560_1080 = "2560x1080 (21:9)",
        resolution_native = "Native",

        gamma = "Gamma",
        sfx_level = "Sound Effects",
        music_level = "Music",
        vfx_motion = "Motion Effects",
        vfx_contrast = "Backgrounds",
        deadzone = "Deadzone",
        keymap = "Controls",
        text_speed = "Text Speed",

        control_indicator_a = "Change Value",
        control_indicator_b = "Exit",
        control_indicator_y = "Restore Default",
        control_indicator_left_right = "Change Value",
        control_indicator_keymap_item_select = "Select"
    },

    -- rt.input_button_to_string
    [rt.InputButton.A] = "A",
    [rt.InputButton.B] = "B",
    [rt.InputButton.X] = "X",
    [rt.InputButton.Y] = "Y",
    [rt.InputButton.UP] = "Move Up",
    [rt.InputButton.RIGHT] = "Move Right",
    [rt.InputButton.DOWN] = "Move Down",
    [rt.InputButton.LEFT] = "Move Left",
    [rt.InputButton.L] = "Left Alt",
    [rt.InputButton.R] = "Right Alt",
    [rt.InputButton.START] = "Start",
    [rt.InputButton.SELECT] = "Select",

    -- mn.KeybindingScene
    keybindings_scene = {
        accept = "Accept",
        go_back = "Abort",
        heading_keyboard = "<b>Settings > Controls > Keyboard</b>",
        heading_gamepad = "<b>Settings > Controls > Gamepad</b>",
        restore_defaults = "Restore Defaults",

        control_indicator_a = "Remap",
        control_indicator_all = "Select",
        control_indicator_b = "Abort",

        confirm_load_default_message = "Restore Default Keybindings?",
        confirm_load_default_submessage = "This will override TODO",

        confirm_abort_message = "Are you sure you want to abort?",
        confirm_abort_submessage = "The current keybinding modification will not be applied",

        keybinding_invalid_message = "Invalid Keybinding"
    },

    -- bt.BattleScene / bt.Animation
    battle = {
        consumable_default_description = "(no effect)",
        consumable_default_flavor_text = "(no flavor text)",

        entity_default_description = "(no effect)",
        entity_default_flavor_text = "(no flavor text)",

        equip_default_description = "(no effect)",
        equip_default_flavor_text = "(no flavor text)",

        status_default_description = "(no effect)",
        status_default_flavor_text = "(no flavor text)",

        global_status_default_description = "(no effect)",
        global_status_default_flavor_text = "(no flavor text)",

        move_default_description = "(no effect)",
        move_default_flavor_text = "(no flavor text)",
        
        health_bar_knocked_out_label = "KNOCKED_OUT",
        health_bar_dead_label = "DEAD",
        
        stun_gained_label = "STUNNED",
        turn_start_label = "TURN START",
        turn_end_label = "TURN END",

        hp_up_label = "<color=HP>HP +</color>",
        hp_down_label = "<color=HP>HP -</color>",
        attack_up_label = "<color=ATTACK>ATK +</color>",
        attack_down_label = "<color=ATTACK>ATK -</color>",
        defense_up_label = "<color=DEFENSE>DEF +</color>",
        defense_down_label = "<color=DEFENSE>DEF -</color>",
        speed_up_label = "<color=SPEED>SPD +</color>",
        speed_down_label = "<color=SPEED>SPD -</color>",
        priority_up_label = "<color=SPEED>Priority +</color>",
        priority_down_label = "<color=SPEED>Priority -</color>",

        message = {
            move_gained_pp_f = function(entity, move)
                return entity .. "s " .. move .. " gained PP"
            end,

            move_lost_pp_f = function(entity, move)
                return entity .. "s " .. move .. " lost PP"
            end,


            consumable_removed_f = function(entity, consumable)
                return entity .. " lost " .. consumable
            end,

            consumable_added_f = function(entity, consumable)
                return entity .. " gained " .. consumable
            end,

            consumable_no_space_f = function(entity, consumable)
                return "but " .. entity .. " has no space for " .. consumable
            end,

            consumable_consumed_f = function(entity, consumable)
                return entity .. " consumed " .. consumable
            end,

            object_disabled_f = function(entity, object)
                return entity .. "s " .. object .. " was_disabled"
            end,

            object_no_longer_disabled_f = function(entity, object)
                return entity .. "s " .. object  .. " is no longer disabled"
            end,

            global_status_added_f = function(global_status)
                return global_status .. " is now active"
            end,

            global_status_removed_f = function(global_status)
                return global_status .. " is no longer active"
            end,

            status_added_f = function(entity, status)
                return entity .. " is no afflicted with " .. status
            end,

            status_removed_f = function(entity, status)
                return entity .. " is no longer afflicted with " .. status
            end,

            hp_gained_f = function(entity, value)
                return entity .. " gained <color=HP><mono>" .. value .. "</mono></color> HP"
            end,

            hp_lost_f = function(entity, value)
                return entity .. " lost <color=HP><mono>" .. value .. "</mono></color> HP"
            end,

            killed_f = function(entity)
                return entity .. " was killed"
            end,

            knocked_out_f = function(entity)
                return entity .. " was knocked out"
            end,

            helped_up_f = function(entity)
                return entity .. " is no longer knocked out"
            end,

            swap_f = function(entity_a, entity_b)
                return entity_a .. " and " .. entity_b .. " swapped places"
            end,

            quicksave_created_f = function()
                return "quicksave created"
            end,

            quicksave_loaded_f = function()
                return "quicksave restored"
            end,

            priority_changed_f = function(entity, value)
                return entity .. "s <color=SPEED>Priority</color> is now <mono>" .. value .. "</value>"
            end,

            start_battle_f = function()
                return "start battle"
            end,

            status_applied_f = function(entity, status)
                return entity .. "s " .. status .. " activated"
            end,

            consumable_applied_f = function(entity, consumable)
                return entity .. "s " .. consumable .. " activated"
            end,

            equip_applied_f = function(entity, equip)
                return entity .. "s " .. equip .. " activated"
            end,

            global_status_applied_f = function(status)
                return status .. " activated"
            end,

            enemy_spawned_f = function(entity)
                return entity .. " appeared"
            end,

            ally_spawned_f = function(entity)
                return nil
            end,

            move_used_f = function(entity, move)
                return entity .. " used " .. move
            end
        }
    },

    battle_scene = {
        control_indicator_select_move = "Select Move",
        control_indicator_confirm_move = "Confirm",
        control_indicator_previous_entity = "Go Back",
        control_indicator_next_entity = "Go Next",
        control_indicator_inspect = "Inspect"

    }
})
