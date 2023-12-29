# 2. Mechanics

## 2.1 Entities

## 2.1.x Status Ailments

volatile vs non-volatile

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
    
    Function on_action_taken    // (self, origin, damage) -> void
    Function on_action_dealt    // (self, target, damage) -> void
    Function on_turn_start      // (self) -> void
    Function on_turn_end        // (self) -> void
    
    Function on_equip     // (self) -> void
}
```

Where `on_action_taken` is called anytime the wearer of the equipment takes damage or is otherwise affected by an enemies move, while `on_action_dealt` activates when the wearer does the same to a target.

`on_equp` modifies a non-battle properties of the wearer when it is equipped in the inventory menu. Changes include modifying the number of move / equipment slots, adding / disabling an intrinsic move, applying a non-flat stat buff, etc.

## 2.x AI & Enemy Design
