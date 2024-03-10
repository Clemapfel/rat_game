
moves used: attack (kills), protect, attack (blocked), add status

```
struct MoveSelection {
    user = Entity
    target = Table<Entity>
    move = Move
}

struct Status {
    attack_modifier     = Integer
    defense_modified    = Integer
    speed_modifier      = Integer
    
    attack_factor   = Float
    defense_factor  = Float
    speed_factor    = Float
    
    max_duration        = Integer
    is_field_effect     = Bool
    
    on_gained           = (self, user) -> nil
    on_lost             = (self, user) -> nil
    on_start_of_turn    = (self, user) -> nil
    on_end_of_turn      = (self, user) -> nil
    on_before_action    = (self, user, target, move_selection) -> altered_selection
    on_after_action     = (self, user, target, move_selection) -> nil
    on_damage_taken     = (self, damage_taker, damage_dealer) -> new_damage
    on_damage_dealt     = (self, damage_dealer, damage_taker) -> nil
    on_status_gained    = (self, user, other_status) -> allow_gaining_status
    on_status_lost      = (self, user, other_status) -> nil
    on_knock_out        = (self, user) -> allow_knockout
    on_wake_up          = (self, user -> nil
    on_death            = (self, user) -> allow_death
    on_switch           = (self, user) -> allow_switch
    on_before_consumable = (self, user, consumable) -> allow_consumable
    on_after_consumable  = (self, user, consumable) -> nil
    on_battle_start     = (self, user) -> nil
    on_battle_end       = (self, user) -> nil
    
    id   = String
    name = String
    icon = String or nil
    
    originator   = Entity
    target       = Entity
    
    -- mutable
    duration    = Integer
}

struct Consumable {
    effect  = (self, user) -> nil
}

struct Equippable {
    hp_base_offset = Integer
    attack_offset     = Integer
    defense_offset    = Integer
    speed_offset      = Integern
    
    attack_factor   = Float
    defense_factor  = Float
    speed_factor    = Float
   
    effect = Status
}

struct Move {
    max_n_uses  = Integer
    
    can_target_multiple = Bool
    can_target_self  = Bool
    can_target_enemy = Bool
    can_target_ally  = Bool
    
    priority = Integer
    effect  = (self, user, target) -> nil
}

struct Entity {
    -- immutable
    id      = string
    name    = string
    gender  = Gender
    
    moveset = immutable Table<ID, Move>
    moveset_uses = mutable Table<ID, Integer>
    
    hp_base = Integer
    attack_base = Integer
    defense_base = Integer
    speed_base = Integer
   
    -- mutable
    status = Table<Status>
    
    attack_modifier = StatModifier
    defense_modifier = StatModifier
    speed_modifier = StatModifier
    
    hp_current = Integer
    is_dead = Bool
    is_knocked_out = Bool
}

struct BattleState {
    entities = Table<Entity>
    party = Table<Entity*>
    enemy = Table<Entity*>
    turn_count = Integer
    
    priority_order_reversed = Bool
    
    background   = BackgroundID
    music        = MusicID
}
```

Move: if all can_target_* are false, target 

# Atomic Actions
```
-- ### mutating

knock_out   Entity -> nil
help_up     Entity -> nil
kill        Entity -> nil
revive      Entity -> nil

add_hp          Entity  UInt -> nil
reduce_hp       Entity  UInt -> nil
set_hp          Entity  Uint -> nil

increase_attack     Entity Modifier -> nil
decrease_attack     Entity Modifier -> nil
reset_attack        Entity -> nil

increase_defense    Entity Modifier -> nil
decrease_defense    Entity Modifier -> nil
reset_defense       Entity -> nil

increase_speed      Entity Modifier -> nil
decrease_speed      Entity Modifier -> nil
reset_speed         Entity -> nil

set_attack_override     Entity Value -> nil
reset_attack_override   Entity -> nil
set_defense_override    Entity Value -> nil
reset_defense_override  Entity -> nil
set_speed_override      Entity Value -> nil
reset_speed_override    Entity -> nil

set_priority    Entity Priority -> nil
reset_priority  Entity Priority -> nil

add_status      Entity  StatusID  -> nil
remove_status   Entity  StatusID  -> nil

get_custom_field Entity FieldID -> Value
add_custom_field Entity FieldID Value -> nil
set_custom_field Entity FieldID Value -> nil

add_field_effect    FieldEffectID -> nil
remove_field_effect FieldEffectID -> nil

set_move_n_uses_override Entity MoveID n_uses -> nil
reset_move_n_uses_override Entity MoveID -> nil
reduce_move_n_uses Entity MoveID Integer -> nil
increase_move_n_uses Entity MoveID Integer -> nil

switch          Entity Entity -> nil
try_escape      nil -> nil

set_priority_order_reversed Bool -> nil

set_ignore_equipment Bool -> nil
set_ignore_stat_modifiers Bool -> nil
set_prevent_consumable Bool -> nil

force_consume_consumable nil -> nil
force_remove_consumable nil -> nil

set_prevent_animation Bool -> nil
set_prevent_messages Bool -> nil

-- ### non-mutating

get_enemies     nil -> Table<Entity>
get_party       nil -> Table<Entity>
get_entities    nil -> Table<Entity>

get_left_of     Entity -> Entity or nil
get_rght_of     Entity -> Entity or nil
get_position    Entity -> Integer

get_in_order            nil -> Table<Entity>
get_party_in_oder       nil -> Table<Entity>
get_enemies_in_order    nil -> Table>Entity>

is_faster_than  faster slower -> Bool

has_status          Entity StatusID -> Bool
get_status          Entity -> Table<StatusID>

has_field_effect    FieldEffectID -> Bool
get_field_effect    nil -> Table<FieldEffectID>

get_hp                  Entity -> Integer
get_hp_base             Entity -> Integer
get_priority            Entity -> Priority

get_attack              Entity -> Integer
get_attack_base         Entity -> Integer
get_attack_modifier     Entity -> Modifier
get_defense             Entity -> Integer
get_defense_base        Entity -> Integer
get_defense_modifier    Entity -> Modifier
get_speed               Entity -> Integer
get_speed_base          Entity -> Integer
get_speed_modifier      Entity -> Modifier

get_attack_override_active  Entity -> Bool
get_defense_override_active Entity -> Bool
get_speed_override_active   Entity -> Bool

get_move_n_uses_override_active Entity MoveID -> Bool

get_is_knocked_out  Entity -> Bool
get_is_dead         Entity -> Bool
get_is_enemy        Entity -> Bool

get_moveset     Entity -> Table<MoveID>
get_has_move    Entity MoveID -> Bool
get_n_uses      Entity MoveID -> Integer 
get_max_n_uses  Entity MoveID -> Integer

get_turn_count          nil -> Integer         number of times a turn has started so far
get_turn_index          Entity -> Integer      number of entites acted before arg

get_name                Entity -> String
get_grammatical_gender  Entity -> Gender

get_history nil -> BattleHistory
get_move    MoveID -> Move

get_priority_order_reversed nil -> Bool
get_ignore_equipment -> Bool

get_prevent_animation  nil -> Bool
get_prevent_message   nil -> Bool
```

# loading 
on hitbox collision: start battle "id: TEST"

```
struct PartyState {
    in_order = Table<UInt, Entity>
    gear = Table<ID, Table<Gear>>
    inventory = Table<ID, Table<Usables>>
    move_uses = Table<ID, Integer>
}

struct EnemyPartyState {
    in_oder = Table<UInt, Entity>
    background = ID
    music = ID
}

struct BattleHistory {
    struct BattleHistoryNode {
        turn_count = Integer
        turn_index = Integer
        
        user = Entity
        targets = Table<Entity>
        move = MoveID
        was_succesfull = Bool
    }
    
    in_order = Table<TurnIndex, EntityIndex, BattleHistoryNode>
}
```

# turn order

## . Resolve Priority

Order all entites by priority / speed

```
struct TurnState {
    entities_in_order = Queue<Entity>
    party_in_order = Queue<Entity>
    enemy_in_order = Queue<Entity>
}
```

## . Apply start-of-turn effects

In order of priority, apply start-of-turn-effects

```
for entity in state.entities do 
    for status in entity.status do
        status:on_start_of_turn(entity)
    end
end
```

## . Move Selection

```

-- in BattleState
move_selection = Queue<MoveSelection>
```

### Enemy 
In order of speed, ask AI to choose a move and target
If move is unselectable, query for another

### Party
In order of speed, ask player to choose a move and target

Queue: ABXY

Party A chose {
    move: ATTACK
    user: A
    target: Y
}

Party B choose {
    move: PROTECT
    user: B
    target: B
}

Enemy X chooses {
    move: ATTACK
    user: X
    target: B
}

Enemy Y chooses {
    move: ADD_STATUS, 
    user: Y,
    target: A
}

Priority Resolution

A = 0
B = +2
X = 0
Y = 0

Battle Phase
Queue: BAXY

B uses Protect
    Animation("PROTECT", B, B)
    add_status(B, "PROTECT")
        animation: status add
        send_message("$B protects itself")

A uses ATTACK
    Animation("ATTACK", A, Y)
    reduce_hp(Y, get_attack(self) * 1)
        animation: loose hp get_hp(Y)
        send_message("$Y took 100 damage")
        knock_out(Y)
            animation: knock out 
            send_message("$Y was knocked out")

X uses ATTACK
    Animation("ATTACK", X, B)
    reduce_hp(Y, get_attack(self) * 1)
    B.status.protect.on_before_damage -> 0
        send_message("$B is protecting itself)
        
Y uses ADD_STATUS
    Animation("ADD_STATUS", Y, A)
    add_status(Y, "status")
        send_message("Y is now statused")

### Atomic Actions


## . Resolve End of Turn

In order of current priority, apply end-of-turn effects

```
for entity in state.entities do
    for status in entity.status do
        status:on_end_of_turn(entity)
    end
end

for status in state.field_status do
    status:on_start_of_turn()
end
```

If one or more party members are dead, game over

```
for entity in state.party do
    if not entity.is_enemy and entity.is_dead then
        state:resolve_game_over()
    end
end
```