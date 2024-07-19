--[[
Move (\u{25A0}) -- rectangle
    Some moves can only be used a limited number of times per battle.

    priority:
        >0: Always goes first
        <0: Always goes last

    is_intrinsic:
        this move is automatically made available at the start of each battle

Equip (\u{2B23} -- hexagon
    May raise certains stats, and / or apply a unique effect at the start of each battle

Consumable (\u{x25CF}) -- circle
    Item that will activate on its own when certain conditions are met.

    max_n_uses:
        Only activates up to *N* times per battle
        \u{221E} Activates an unlimited number of times

Templates
    (this feature is not yet implemented)
--

Health (HP)
    When a characters HP reaches 0, they are knocked out. If damaged while knocked out, they die

Attack (ATK)
    For most moves, user's ATK increases damage dealt to the target

Defense (DEF)
    For most moves, target's DEF decreases damage dealt to target

Speed (SPD)
    Along with Move Priority, influences in what order participants act each turn

]]--