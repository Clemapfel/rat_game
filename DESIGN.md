# 2. Mechanics

## 2.1 Entities

## 2.1.x Stats

Each entity has four properties associated with it, called ATK (attack), DEF (defense), SPD (speed), HP (hit points), and a hidden priority stat. At the start of each turn, all entites in the battle are sorted by SPD, descending, then that turns action order is determined. The fastest entity acts first within its priority bracket. If the priority of two entities is the same, the entity with the higher SPD stat acts first. If the priority is different, the entity with the higher priority acts first.

If two entities have the same SPD and priority, the entity whos cleartext-name is lexicographically less than the other acts first.

ATK, DEF and SPD have an associated level, which is one of `(-infinity, -3, -2, -1, 0, +1, +2, +3, +infinity)`. A stats level modifies the actual value that will be used for calculations like so:

| level     | factor   |
|-----------|----------|
| -3        | 1 - 3/4  |
| -2        | 1 - 1/2  |
| -1        | 1 - 1/4  |
| 0         | 1        |
| +1        | 1.25     |
| +2        | 1.5      |
| +3        | 2        |
| +infinity | infinity |
| -infinity | 0        |

Stats may only be modified mid-battle by means of these levels. Outside of battle, an entites stat depends on other properties: the stats base, the stats allocated EV, and equipment modification.

The base level is unique to each entity and cannot be modified by items, equipments, or in-battle effects, it is chosen by the developer. This is the easiest way to modify an entites power level, by choosing higher base stats the entity is strong and faster. 

For party members only, each stat has an associated EV level which is a number in `{0, 1, ..., 15}`. For each point, the entity gets a +10 to its base. For example, for an entity with a base hp of 150, allocated 3 EVs to hp ill increase the base hp to 180. Each entity has a fixed number of EVs, that can be allocated to any stat (up to the maximum). In this way, the player can choose to specialize certain characters into roles they are needed. EVs can be reallocated at all times, therefore rewarding the player with an EV for a specific character essentially buffs that character, making EVs a sought-after reward.

## 2.1.x UI

For each party member, the current and maximum HP, the current SPD stat, the curren

## 2.1.x Status Ailments


An entity can have any number of status ailments while in battle. While afflicted by a status condition, an emblem representing it is shown next to the entities HP bar, or below the enemy sprite if the entity is an enemy. Part of the emble is a numerical symbol, which displays the number of turns left until the status is cured automatically.

The game keeps track of how many turns have passed since the entity was first afflicted with a specific status condition. This number is incremented at the start of each turn, if the number is equal to or exceeds the maximum duration of a status ailment, it is cured automatically. Other than this, status ailments may be cured by items or moves.

### 2.1.1 Knocked Out

Status ailments can have a wide variety of effects, with one special case, the `KNOCKED_OUT` status ailment.

If an entities HP reaches 0, it is knocked out. All other status ailments are cured and for the rest of that turn, the entity is invulnerable to all damage. Starting the next turn, if the entity takes any amount of damage it is killed. If this happens to an enemy, that enemy is removed from the battle permanently. If a party member is killed, the player receives a game over. If all alive enemies are currently knocked out and no enemy has died so far, the battle ends in non-standard way, usually rewarding the player with an achievement or bonus item.

While an entity is knocked out, if it receives any amount of healing the enemey is restored with an HP value equal to the healing amount. 

Outside of battle, an entity cannot have a status ailment and all are healed when a battle ends. This includes `KNOCKED_OUT`: after the battle the entites HP is set to 1.

### 2.1.4 Example Status Conditions

Where the effect text is written for the purposes of being clear to the developer, the actual in-game text will be more brief and less technical.

> ``STUNNED``<br>
> Duraton: 1 Turn<br>
> Target may not act this turn.

> ``BLEEDING``<br>
> Duraton: 5 Turns<br>
> Target takes 1/8 * target.max_hp damage at the end of each turn. If the target is healed by any amount, this status is removed.

> ``POISONED``<br>
> Duraton: Infinite<br>
> Target takes 1/16 * target.max_hp damage at the end of each turn. If the target would be knocked out, this status is cured instead and target.current_hp is set to 1

> ``BURNED``<br>
> Duraton: Infinite<br>
> Reduces DEF by 50%. Target receives 1/16 * target.max_hp damage at the end of each turn. If target would receive the `CHILLED` status, `BURNED` is cured instead.

> ``CHILLED``<br>
> Duraton: Infinite<br>
> SPD is reduced by 50%. If the `CHILLED` status would be added while a target is already chilled, `CHILLED` is cured and the `FROZEN` status will be added. If target would receive the `BURNED` status, `CHILLED`is cured instead.

> ``FROZEN``<br>
> Duraton: Infinite<br>
> Target SPD is treated as negative infinity at all times. If target would receive the `BURNED` status, `FROZEN` is cured instead.

> ``BLINDED``<br>
> Duraton: 1 Turn<br>
> Target ATK is treated as 0 at all times.

> ``AT_RISK``<br>
> Duraton: 3 Turns<br>
> If target would be knocked out by any means, it instead immediately dies.

> ``ACCELERATED_STATUS``<br>
> Duraton: Infinite<br>
> At the start of a turn, if the elapsed turn counter of any status ailment is increased, it is instead increased by 2

> ``DECELERATED_STATUS`` <br>
> Duration: 3 Turns
> At the start of any even-numbered turn count (turn 2, 4, ...), elapsed turn counter of any status ailment other than `DELECERATE_STATUS` is not increased.

> ``PARALYZED``<br>
> Duraton: Infinite<br>
> Raises SPD by 50%. Every 2nd turn, after `PARALYZED` is gained, target may not act that turn.

Note that since `PARALYZED` technically has a beneficial effect on the first turn, it may be a good strategy to inflict this status ailment on one of our party members. In a similar way, knocking out one of the party members and immediately healing them that turn is a sneaky way to cure all status ailments, since being knocked out removes all others. This technique is not taught to the player, but is rewarded due to the inherent properties of being knocked out.

### 2.1.5 Status Ailment Implementation

The class representing volatile and non-volatile status conditions has the following gameplay-relevant fields.

```c
class StatusAilment {
    unsigned int max_duration       // maximum duration, may be infinite
    unsigned int elapsed_duration   // current elapsed time
    
    float attack_modifier       // in [0, n], where 1 is no change
    float defense_modifier
    float speed_modifier
    
    Function on_turn_start      // (self) -> void
    Function on_turn_end        // (self) -> void
    
    Function on_action_taken    // (self, action, origin, damage) -> void
    Function on_action_dealt    // (self, action, target, damage) -> void
    
    Function on_status_given    // (self) -> void
    Function on_status_removed  // (self) -> void
}
```

Where `on_status_given` activates when the entity receives this status condition, which can be used to apply permanent effects, `on_status_removed` is called after the current status ailment was removed in any way, including being knocked out.

The `elapsed_duration` is updated automatically at the end of each turn. If `elapsed` is equal to or higher than `max_duration`, the status is removed automatically. 

## 2.2 Moves

## 2.3 Consumables

Consumables are identical to moves in terms of effect and function, with two main differences. Rather than having a fixed number of PP, consumables are consumed when used. An entity may have up to a.

Consumables can be equipped in place of equipment

## 2.4 Equipment

Equipment are equivalent to gear in other games. In the overworld or after a battle, a player may receive a new piece of equipment. Each party members equipment can be changed in the inventory menu. 

When a new equpment is obtained, a small cutscene plays that shows the name of the item and its properties in clear text, see example below. Once the player presses A, they regain control and the item is added to their inventory.

![](https://interfaceingame.com/wp-content/uploads/the-binding-of-isaac-afterbirth/the-binding-of-isaac-afterbirth-new-item.jpg)

*(source: Binding of Isaac)*

### 2.4.1 Effects of Equipment Types

An entity has a fixed number of equipment slots, in which it can equip items of a special type: equipment. Equipment comes in four kinds, 

+ **rings** are small jewelry worn by humans or any non-human with an appendage the size of a human finger
+ **weapons** are things like swords, knifes, slingshots, etc. Only equippable by adult humans 
+ **clothing** are wearable such as shirts, scarfs, hats, armor, etc.
+ **special** are an equipment type that can only be worn by a certain character

Equpment of any kind can have any effect, though things like clothing or armor is more likely to increase defense, while weapons will increase damage output. Special-type items will usually modify a property of a character itself, see below.

Equipments have the following properties:

+ `hp_increase`: Positive Integer, increase maximum HP of the equipped character
+ `attack_increase`: Possibly negative integer, increases ATK by a flat amount
+ `defense_increase`: see above, but for DEF
+ `speed_increase`: see above, but for SPD

Additionally, equipment can have more free-form, passive effects. Passive effects are effects available as long as the character is not knocked out or dead, similar to a non-volatile status condition. Examples including regenerating 1/16th of user.max_hp at the end of each turn, or lowering an enemies attack whenever they damage the wearer.

### 2.4.2 Equipment Slots

The number and type of equipment slots depends on the entity and should have an in-lore explanation, for example a spider enemy may be able to wear 8 rings, one on each leg, but should be unable to wield a weapon or wear human clothing. A small girl should be unable to wear an adults coat, etc.

The equipment slot and type distribution for all playable characters is as follows:

| Character | # Weapons | # Clothing | # Trinkets | Special Slot?                                                                    |
|-----------|-----------|------------|------------|----------------------------------------------------------------------------------|
| `$MC`     | 2 | 1          | 2          | no                                                                               |
| `$RAT`    | 0 | 0          | 4          | **Mouse-sized Item** [1]: Determines `$RAT`s intrinsic move                      |
| `$GIRL`     | 0 | 1          | 1          | **Backpack**: Determines number consumable slots in inventory                    |
| `$PROF`     | 1 | 1          | 2          | **Glasses**: modifies the effect of the `ANALYZE` intrinsic move                 |
| `$SCOUT`    | 1 | 1          | 2          | no                                                                               |
| `$WILDCARD` | 2 | 1          | 2          | **Feathered Hat**: Prevents wearer from selecting the `PROTECT` intrinsic action |

[1] Such as "mouse-sized collar", "mouses-size sock", "mouse-sized piece of cheese"

While any piece of equipment of a certain type can be equipped to any entity with a matching slot, the slot distribution and special item allow the developer to steer characters into a certain type of build, for example, since weapons will usually aid in offensive tasks, `$MC` and `$WILDCARD` are naturally more likely to be the damage dealers, while $GIRL is both defensless and weaponless, but her backpack allows her to be useful and more flexible than others in combat by stock-piling various kinds of consumables, which would occupy valuable consumable slots on other characters.

Lastly, `$RAT` has the greatest build variety, as 4 trinket slots (on for each leg), as well as being able to choose the intrinsic move allows it to fullfill any role.

Enemies being able to wear equipment, while rare, gives valuable opportunity for gamedesign purposes in the case when equipment has active or passive abilities. For example a somewhat complicated piece of equipment with an active effect could first be put onto an enemy. The player fights the enemy and will naturally trigger the equipments ability. After the fight is won, the player will loot the new piece of equipment and will have been seamlessly taught how it works and if it is worth using. 

### 2.4.3 Equipment Examples

The following is a list of equipment demonstrating the type of effects that are available. Note that the effect text given here is not intended for players, in-game a more appropriate and shortened version will be used.

> ``ULTRALIGHT_BOOTS`` (Clothing)<br>
> -25 DEF | + 50 SPD<br>
> No additional effect

> ``BALL_AND_CHAIN`` (Trinket) <br>
> SPD is treated as negative infinity at all times.

> ``NOVELTY_SODA_HAT`` (Clothing)<br>
> (no stat buffs)<br>
> Restores 1/16th at the end of the turn during for first 5 turns of the battle

> ``LONG_NIGHT_KNIFE`` (Weapon)<br>
> ATK: +50<br>
> Causes the target to be affected with `BLEED` status condition if the user selected the `STRIKE` intrinsic move

>``ASSAULT_VEST`` (Clothing)<br>
> (no stat buffs)<br>
> User starts the battle with +3 DEF. If a move does not deal damage, it may not be selected. Excludes intrinsic moves.

>``FEATHERED_HEAD`` (Special)<br>
> (no stat buffs)<br>
> Can only be equipped to `$WILDCARD`. At the end of each turn, raises users ATK by one level. User may not choose the `PROTECT` intrinsic move

> ``MOUSE_SIZED_CHEESE`` (Special)<br>
> (no stat buffs)<br>
> Can only be equipped to `$RAT`. The first time the `STRIKE` intrinsic move is selected during a battle, it instead restores HP equal to 0.5 * user.max_hp.  

> ``VARIFOCAL_GLASSES`` (Special)<br>
> (no stat buffs) <br>
> Can only be equipped to `$PROF`. The `ANALYZE` intrinsic move now reveals the enemies health bar and PP count for any move used in battle so far.

### 2.4.4 Equipment Implementation

The equipment class has the following gameplay-relevant properties:

```c
class Equipment {
    unsigned int hp_modifier
    int attack_modifier
    int defense_modifier
    int speed_modifier
    
    Function on_action_taken    // (self, action, origin, damage) -> void
    Function on_action_dealt    // (self, action, target, damage) -> void
    Function on_turn_start      // (self) -> void
    Function on_turn_end        // (self) -> void
    
    Function on_equip           // (self) -> void
}
```

Where `on_action_taken` is called anytime the wearer of the equipment takes damage or is otherwise affected by an enemies move, while `on_action_dealt` activates when the wearer does the same to a target.

`on_equip` modifies a non-battle properties of the wearer when it is equipped in the inventory menu. Changes include modifying the number of move / equipment slots, adding / disabling an intrinsic move, applying a non-flat stat buff, etc.

## 2.x AI & Enemy Design
