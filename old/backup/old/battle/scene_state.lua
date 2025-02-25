rt.settings.battle.scene_state = {
    control_indicator_command_prefix = "<color=SELECTION><b>",
    control_indicator_command_postfix = "</b></color>"
}

--- @class bt.SceneState
bt.SceneState = meta.new_abstract_type("BattleSceneState", rt.SceneState)
