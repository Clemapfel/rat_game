
moves used: attack (kills), protect, attack (blocked), add status

```
struct Status {
    attack_modifier     = Float
    defense_modified    = Float 
    speed_modifier      = Float
    
    on_start_of_turn    = (self, user) -> nil
    on_gained           = (self, user) -> nil
    on_lost             = (self, user) -> nil
    on_damage_taken     = (self, damage_taker, damage_dealer) -> new_damage
    on_damage_dealt     = (self, damage_dealer, damage_taker) -> new_damage
    on_status_gained    = (self, user, other_status) -> nil
    on_status_lost      = (self, user, other_status) -> nil
    on_end_of_turn      = (self, user) -> nil
}

struct Entity {
    -- immutable
    id      = string
    name    = string
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
}
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
```

```
struct EnemyPartyState {
    in_oder = Table<UInt, Entity>
    background = ID
    music = ID
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
struct MoveSelection {
    user = Entity
    target = Table<Entity>
    move = Move
}

-- in BattleState
move_selection = Queue<MoveSelection>
```

### Enemy 
In order of speed, ask AI to choose a move and target
If move is unselectable, query for another

### Party
In order of speed, ask player to choose a move and target

## . Simulation

## . Resolve End of Turn

In order of current priority, apply end-of-turn effects

```
for entity in state.entities do
    for status in entity.status do
        status:on_end_of_turn(entity)
    end
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

