This file will describe the setting, plot, and gameplay of `rat_game` (working-title), an earthbound-like that means a lot to me. 

# Gameplay

`rat_game` is what I call an "earthbound-like", which is a subset o jRPGs that are based on [Earthboun](https://en.wikipedia.org/wiki/EarthBound). Other earthound-likes include LISA and Undertale.

In `rat_game`, there are three main modes of play: **overworld**, **battles** and the **inventory screen**.

In the overworld, the player controls the entire party, walking around talking to NPCs, interacting with overworld objects to get more information of them (for example, interacting with the sprite of a broken window, the game will present a textbox "it's borken, it seems like it was smashed from the outside, then used to climb in". This is a diagetic way to present more information about the games wordl which may not be able to conveyed using pixel art alone. One part of the overworld experience is exploration, `rat_game`s levels are open-world, but they do allow the player to walk around non-linearly, exploring differents parts of the level at different times. In the overworld, some sprites will be highlighting with a glittering effect. Interacting with an object of this type will reward the player with an item, which are split into 3 categories: orbs, consumables, and equipment. 

Orbs and Consumables are actions that can be selected in **battle**, `rat_game`s main mode of play. A battle represents an alteraction between the players party, which may have any number of player controlled characters, up to a maximum of 6, along with any number of enemies. Battles are similar to how they are in Pokémon, each entity can select from either a list of moves or a list of consumable items, unique to each entity. Moves have a limited number of uses called [PP](https://bulbapedia.bulbagarden.net/wiki/PP). If a move is used in battle, it will loose one PP. If all PP are depleted, the move cannot be used. PPs are refilled at savepoints, which are objects in the overworld that, when interacted with, safe the progress and restore all PP. Each effect can only be gained once, once a safe point was used, backtracking to it will have no point. The player furthermore cannot elect to not save at a savepoint, the moment it enters the player screen, the savepoint will activate. This is to avoid players "saving" the savepoint for later, which would introduce a high-risk dynamic in which a player may choose to go on less prepared hoping that in the future, their PP recovery will make a harder battle easier.


There are two other types of actions, **intrinsic** actions and consumables. Consumables work exactly like moves, except that they do not have PP, instead the have a number of uses. Choosing it in battle will consume one use, if no uses are left the consumable will vanish from the players inventory permanently, hence their names. Intrinsic moves are exactly like moves, except that they have infinite PP. The player can choose them at any point in battle, and can choose the over and over. Unlike moves and consumables, intrinsic moves are character-specific, for example each character will have a "basic strike" intrinsic move that deals damage with no other effect, but only one character, $PROF, has an intrinsic move that reveals more information about the enemy, that is usually hidden.

Each enemy has the exact same amount of stats and moves as a player, though their specific moveset and stats may differ. Each entity has the following properties:

+ `max_hp` : maximum number of hitpoins
+ `hp` : current number of hitpoints
+ `attack` : attack stat, this will be used to calculate damage numbers when the entity uses a move
+ `defense` : defense stat, this will be used to calcaulte the damage an entity takes when attacked
+ `speed` : speed stat, this will govern when an entity can take its turn. At the start of each turn, the order is updated depending on the speed and priority state of the entity 
+ `priority` : This is value in [-1, 0, 1]. Enemies in a higher priority bracket will always act before an entity in a lower priority bracket. Only if their priority is the same, will the `spd` stat be used to determine turn order. All entities have a priority of 0  at the start, though certain moves or consumables can change this temporarily
+ `attack_level`: Value in [Negative Infinity, -3, -2, -1, 0, +1, +2, +3, Infinity], will be used to calculate an entities final attack
+ `defense_level`: see above, modifies entity defense
+ `speed_level`: see above, modifiies entity speed
+ `moveset`: list of available moves, each of which have a PP counter specific to that entity
+ `consumables`: list of available consumables, each of which has a entity-specific number of uses
+ `intrinsics` : list of intrinsics move, these are specific to each entity and cannot be unequiped
+ `equipment` : each entity has a number of equipment slots in which it can equip one equipment each. Equipment usually give buffs to an entites stats such as hp or priority, but may also give adittional passive effect
+ `status` : list of status ailments, each status ailment has a number of effects that will trigger once per turn, or be applied to the entity as long as it is afflicted with that status. For example, the "stun" status ailment makes it so an entity cannot move that turn. Status ailments will either afflict an entity until the end of battle, or, if it has a limited number of turns such as "stun", will be automatically removed after that turn count has passed

All enemies will have a set moveset, consumables, intrinsics, max_hp, atk, def, and spd. All other can be dynamically changed during battle, as the result of moves, equipment, or other effects.

For entities that are in the party, the player can choose many of their properties. With the exclusion of intrinsic moves, which cannot be changed, the player can change the following properties of each party member

+ `moveset`: each party member has a set number of slots that any move can be equipped to. The moves are a finite quantity, so if you have 2 copies of a move, you can either equip it on two different characters, or equip them to the same character in two slots, effectively doubling its PP
+ `consumables` : similar to the moveset, each party member has a fixed number of consumables. Note that this is not the number of types of consumables, rather the sum of the number of uses of each consumable of that character
+ `equipment`: as outlined above, the player can choose to equip certain equipments to each character. Each equipment is one of several types, and only certain party members can equip certain types of equipments. For example. $RAT can equip up to a maximum of four rings, one on each leg, but may not wear a coat. $GIRL can wear that coat, but cannot wear a sword, as she is too weak to hold it.

Lastly, as the player progress through the story, they will gain [EV](https://bulbapedia.bulbagarden.net/wiki/Effort_values). These can be allocated, where at most 25 EV can be allocated per party member, and each stat (`hp`, `atk`, `def`, `spd`) can be allocated at most 10 EV at a time.

The last mode of play, the player inventory, is where they player builds their party. By allocating moves, consumables, EVs, and equipment, the player can drastically choose how each character behaves in battle. Because many actions (moves / consumables) or equipment may interact during battle, the player is incensitivized to come up with valuable combinations. For example, they may choose equip the "freeze" move, which freezes and enemy in place but does not deal damage to one of the characters specialized for support, while equipping the "break & thaw" move to a character geared for dealing damage, with the move dealing bonus damage to frozen enemies. In battle, during the same turn, they can have the support character freeze an enemy, then immediately after have the damaging character break that freeze, dealing massive damage. In this way, the player is incentivized to carefuly plan an entire team and load, as opposed to just picking the best moves on every character. This is extremely similar to how competitive pokémon teambuilding works, the player chooses from a vast array of options, and distributes these among their many characters to be used in battle together. 

In the inventory screen, the player can save a "loadout", which is a set moveset, consumables, EV and equipment allocation for each character. Then, at any point, they load or save a loadout, making switching between different teams easier.

While enemies hold the same number of variables as a players party and they are just as capable of producing devastating combinations, their choice of equipment, moveset, consumables is out of the player control and is chosen by the developer. This allows for a smooth difficulty curve, in which player will enter a battle and have to use the best strategy currently available to them, to beat the number of enemies.  

Because of the PP system where PP cannot be restored after a savepoint has been used once, the player is incentivized to switch out their loadout for big boss battles, or time.

Give then 6-or-less partymembers vs any number of enemies, enemy AI is quite complex. While pokemon only has 2v2 battles, the variable number of enemies introducing unique challenges, such as enemies that spawn mid-battle, and story-induced variation in party size.

When an entites HP reaches 0, it gains a new special status ailment being "knocked out" (KO). An entity that becomes KO will loose all other status ailments, will become invinicible for the rest of the turn, and, on subsequent turns, will be unable to act at all, though it's turn will happen at the regular time dependeing on its speed and priority, but it will be unable to act. If an entity takes any amount of damager will KO'd, it will permanently die. For enemies, this will mean that the enemies is out of the fight for good. For players, this will mean a game over. Because entites are protected from dieing the same turn they are KO'd, it's impossible for a situation to happen where a player does not have a chance to react to a party member getting KO'd. Because only one party member dieing means a game over, the player is incensitivized do prioritize staying alive over maximizing dps. This also has roleplaying purposes, if, inside the world of the story, a player gets KO'd and enters battle, an additional challenge is posed in which the player has to protected the KO'd party member. If an entity is KO'd and it gets healed by any amount, the KO'd status will revert, it's hp become equal to the amount healed, and it will be able to act on its turn again. Entites may be KO'd the same turn they are brought back from being KO'd, so players should take care to do this at the correct time.

`rat_game` discourages the jRPG trope of "healer", where the job of one party member is to exclusively heal the others, keeping their HP topped off without contributing much else to the battle. This is achieved through 3 core tennants of move design. A move that can heal can only:
+ Heal an entremely low amount (such as 2 HP), making it only useful for reverting KOs
+ Heal only the user itself, (similar to how most pokemon healing moves work), meaning it cannot be used to heal others or revert KO's
+ Be a consumable. The only action that restores a significant amount of HP to another party member will be consumable, allowing developers to tweak available healing through rarity of consumables, as opposed to player build

With the healing design, what may not have been clear is that each action (move / consumable / intrinsic), can only target certain other entites. This is governed by two properties, whether the move is single-target or multi-target, and whether the move can target oneself, and/or another party member, and/or another enemy.

For example, a move that is single-target and can targets self or an enemy may not be used on other party members
A move that is multi-target and cannot target self and cannot target enemies but can target party members will only apply to all party members except the user of the move
A move that cannot target anything is called a "field" move, it will affect the field itself, such as summoning a sandstorm.

All moves and mechanics in battle shall be exclusively deterministic, meaning there is no randomness involved in any part of the process. If a move does 123 damage, it will always do 123 damage (assuming the users attack and targets defense are the same). At all points the player should be sure that choosing an action will have an effect that he is able to predict with 100% certainty. The only variance in battle is introduce in the enemy AI. Which move to choose and which entity to target may be influenced by randomness, though with enemies with more sophisitcated AIs, choosing the optimal move and target will more often be preferred over just randomly clicking anything at all.

`rat_game`s battle system was designed to be extremely deep, extremely complex, yet streamlined. The player only has to be aware of 4 stats (attack, defense, speed, priority), and for each it is obvious what its effect in battle will be. Barring some rare move that may use the users defense or the targets speed to calculate damage, more attack will aways mean more damage, more defense will mean taking less damager, higher speed will mean going first, or, if the priority is not equal, higher priority will instead decide this.

Secondly, moves and consumables were delibirately designed as generic as possible, meaning any and all effects could happen from a move. In competitive pokemon, the format played in real-life tournaments with actual prizes and titles on the line, most moves from insie the games are useless. Only a limited subset of them have any competitive utilitiy, indeed, some moves have only a competitive utilitiy, while being basically useless in-game. `rat_game` aims to have its set of moves and consumables be 100% non-redundant. A move collected in the early part of the story should be viable until th every end, and it is better to have 50 interesting moves that combo well with all other 50 moves, than going the pokemon route and having 1000 different attacks, only 50 of which will be used in serious competitive play.

### Example Intrinic Moves

A non-exhaustive list of intrinsic moves, and their hosts:

| id      | User                 | Effect                                                                                                                                                                                     |
|---------|----------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| STRIKE  | All except $WILDCARD | Deal 1 * user.attack to target ally or enemy or self                                                                                                                                       |
| PROTECT | All except $GIRL     | Single target ally or self will not take any damage or be afflicted by status ailments this turn, stat alterations still apply. A target my not be protected two turns in a row            |
| ANALYZE | $PROF                | Reveal single enemies HP bar (without showing absolute values), as well as the list of used moves along with the remaining PP, and the list of used consumables, along with number of uses |
| WISH  | $GIRL | Target ally (not self) will have 2 * $GIRL.hp restored after 2 turns                                                                                                                       |
| HELP_UP | $MC and $SCOUT  | Target single ally that is KO'd, if the target would be killed this turn, it is not. At the end of the turn, reset target to 25% target.hp                                                 |
| WAR_DANCE | $RAT | Raise attack by 1, speed by 1, lower defense by 2. If defense is lowered past -3, set to negative infinity                                                                                 |
| GORE  | $WILDCARD | Deal 1 * user.attack to target enemy, same as STRIKE, except if the enemy is KO'd by this attack, it instead dies immediately                                                              |

### Example Status Ailments

A non-exhaustive list of status ailments

| id      | last for                            | effect                                                                                                                                  |
|---------|-------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------|
| STUNNED | 1 Turn                              | Entity may not move this turn                                                                                                           |
| CHILLED | Until Removed                       | Speed is always treated as 0                                                                                                            |
| FROZEN  | Becomes CHILLED after taking damage | Speed is always treated as 0, Priority is always treated as -1                                                                          |
| BURNED  | Until Removed  | Defense level is always treated as -2                                                                                                   |
| POISONED | Until Removed | Loose 1/16th of user.max_hp at the end of each turn. Does not KO'd                                                                      |
| AT_RISK | Until Removed | If target would be KO'd, it immedaitely dies instead                                                                                    |
| ASLEEP | 3 Turns, removed after taking damage | Target may not move this turn                                                                                                           |
| BLINDED | Until Removed | Attack level is always treated as -1                                                                                                    |
| PROTECTED | 1 Turn | If the target would take damage, instead takes 0 damage, if the target would gain a status ailment, it does not                         |

Recall that, when an entity is KO'd, it's status ailments are reset. In this way, a player may choose to KO'd their own party member, then immediately revivie them in order to restore their status. This is why `STRIKE` can target enemies or allies, but is, of course, impossible with $WIDLCARDs GORE, which has story relevance.


### Example Field Effects 

A non-exhaustive list of field effects, these apply to all entites at all times

| ID          | last for     | effect                                                                                                                              |
|-------------|--------------|-------------------------------------------------------------------------------------------------------------------------------------|
| BLIZZARD    | Whole Battle | At the end of a turn, if an entity is not currently BURNED, afflict it with CHILLED. If an entity is CHILLD, afflict it with FROZEN |
| SANDSTORM   | Whole Battle | At the end of a turn, afflict all entities with BLINDED                                                                             |
| VIRAL_STORM | 3 Turns      | All healing instead damages a target for the same amount. This cannot cause a target that is KO'd to dei                            |
| HAIL        | Whole Battle | Dealt 1/16th of entites max hp as damage, this cannot cause the target to die                                                       |
| TRICK_ROOM  | 5 turns      | Reverse the order of actions, meaning the entity with the lower priority or lowest speed if same priority, moves first              |
| MIRROR_ROOM | 1 turn       | Swap the attack and defense of all entities |
| HAZE        | 3 turns      | While active, attack, defense, and speed levels are not factored into calculation (though they still persist) |
 | PREMONITION | 3 turns      | All moves performed by entites with +1 or high priority will fail |

### Example Moves

| ID                   | Mode   | Targets                    | PP                                    | Effect                                                                                                                                                      |
|----------------------|--------|----------------------------|---------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------|
| FIRE_BALL            | SINGLE | all enemies                | 3                                     | If target has taken damage this turn afflict BURNED, then deal 3 * user.attack damage                                                                       |
| STAT_SWAP            | SINGLE | single enemy               | 2                                     | Swap target.attack_level with user.attack_level, target.defense_level with user.defense_level                                                               |
| OUTRUN               | SINGLE | self                       | 2                                     | Swap user.speed_level with user.attack_level                                                                                                                |
| HAMSTER_FOR_THE_EYES | SINGLE | single enemy               | 5                                     | arget loose -1 attack per turn. If this move is used 3 turns in a row, attack is instead set to negative infinity                                           |
| HEAL_WAVE            | MULTI  | all allies and all enemies | 1                                     | Heal target of target.max_Hp                                                                                                                                |
| INVERSION            | SINGLE | self                       | 5                                     | Swap all attack, defense, and speed debuffs with buffs, buffs with debuffs                                                                                  |
| TOUGH_LOVE           | SINGLE | self or ally or enemy | 3                                     | Deal 1.5 * user.attack damage, then heal for 2 * user.attack                                                                                                |
| SIDE_SWIPE_SNIPE     | MULTIE | all enemies | 5                                     | For n-th target, if n <= 4 do (4 - n) * user.attack_damage, f if n 4 heal for (n - 4) * user.attack_damage                                                |
| ARROY_OF_DEATH | SINGLE | single enemy | Deals 1 damage, then afflicts AT_RISK |
| ECHO | SINGLE | singl ally | 1                                     | If user acts after target, will perform same attack as target without consuming PP                                                                          |                               | 
 | JUGULAR | SINGLE | single enemey | 5                                     | Deal 1 damage to enemy. If this kills the enemey because it was KO'd, user may choose a new target to attack with JUGULAR this same turn, if it has PP left | 

##### Example Combos: SIDE_SWIPE_SNIPE

SIDE_SWIPE_LIPE: Example: Targeting 7 enemies:

| enemey n | damage or heal                    |
|----------|-----------------------------------|
| 1        | damages (4 - 1) = 3 * user.attack |
| 2        | damages (4 - 2) = 2 * user.attack |
| 3        | damages (4 - 1) = 1 * user.attack |
| 4        | 0 |
| 5        | heals (5 - 4) = 1 * user.attack   |
| 6        | heals (6 - 4) = 2 * user.attack   |
| 7        | heals (7 - 4) = 3 * user.attack   |
| 8        | heals (8 - 4) = 4 * user.attack   |
| ...      | heals (n - 4) user.attack         |
| 12       | heals (12 - 4) = 8 * user.attack  |

For exactly 3 mobs, this attack is amazing, but imagine a boss who are usually in the middle spawn 6 mobss right of it, those will all get healed massively. If your party has 6 members, the player may elect to target their own party, protecting the first three such that the 5th and 6th member will get healing


##### Example Combo: HEALWAVE x VIRAL_STORM

If VIRAL_STORM is active, an entity being heald equal to it's max HP will instead deal that as damage, meaning it will kill every entity in play, even bosses. To avoid KO'ing your own party and loosing, if at least one of them protects you win the fight, if all of them except the HEAL_WAVE use protects, you wipe all enemies with multiple people still standing.

##### Example Comboe: WAR_DANCE x INVERSION

Set $RATs defense to negative infinity using WAR_DANCE repeadetly, then use INVERSION with $RAT, setting its attack and speed to -3 but your DEFENSE to postive infinity, which means $RAT will always take 0 damage, and any subsequent WAR_DANCE will raise attack but never lower defense



### Example Consumables

| ID                | Mode   | Effect                                                                                     |
|-------------------|--------|--------------------------------------------------------------------------------------------|
| MOLOTOV_SHOTGLASS | SINGLE | Dead 3 * target.defense damage, afflicts BURNED                                            |
| BLOOD_VIAL        | SINGLE | Deal 25% user.max_hp damage to user, heal target for 50% user.max_hp                       |  
| LEECH_ON_A_LEASH  | SINGLE | Afflict target enemy with LEECH: Heals user for 1/8th * target.max_hp every turn           |
| THROWING_SPEAR    | SINGLE | Deal 200 damage to single target                                                           |
| THROWING_SHIELD   | SINGLE | Afflict target with PROTECTED, unlike PROTECT move, can be used two turns in a row         |
| CALTROPS          | MULTI  | All enemies that move before user this turn take 1 * user.attack damage, lasts 3 turns     |
| GLUE_BOMB         | SINGLE | Lasts 1 turn: All entites that move after target (or self) will get -1 speed before acting |
| LIT_FUSE | SINGLE | Afflicts: READY_TO_ROCKET: Gain +1 speed at the start of each turn. If Speed would become +4, immediately KO'd at the start of the turn


In the examples in this sectino, not how there is no move that can just heal someone. Healing always comes at some downside, some minor like `BLOOD_VIAL`, but most of the times to actual heal someone who isn't KO'd, you will have to pull of at least a 2-person combo.



# Settings

`rat_game` is set world that has been overttaken by a hivemind. The hivemind works like this: if any person is within radius of another person already in the network, then that person will be either be overtaken instantly, or, if they have a specific genetic feature, they will instead start to hallucinate and enter a nightmare world. If they die in the world they get overtaken, if they make it they are immune for a few days until the hivemind can try again.

When the hivemind which I'll call "the source" (working title) started taking over the world instead of risking people not being overtaken it simply had people already in the network kill those with genetic resistance, it basically committed a holocaust  and systemically slaughtered all people with that feature. After this all of humanity started advancing scientifically crazy fast, because if humans don't bicker, never misunderstand each other and always work in perfect harmony, the human race advances exponentially faster than usual.

During the holocaust some amount of "resistant" escaped, they formed small groups hiding out in old buildings such as hospitals or schools. Their number is in the thousands at most, so the source doesn't much care about them. If they are spotted by entities part of the hivemind, they are killed on sight, just like the would be during the original takeover.

The largest of the resisant settlements is called "Sanctuary", it is a shanty town that has basic facilities like a bar or hospital, and it has some farm land around it, even though it is hidden deep in an incredibly dense forest. This location brings safety and piece to its inhabitants, three of which are notable to `rat_game`s story, the hostess of the bar and her daughter, as well as one of the "scouts", transient people trailing the land around sanctuary trying to detect potential hivemind militias or other danger.

While mostly ignoring the few survivers, the source has create a mega lab that sits on top of a hole which was drilled to deep into the earth that it can tab the earths molten core for energy. Around the lab the source built and entire mega city with billions of citizens, they all work for the lab but they are only taken over while there, when they leave the building the source tabs out and they have free will again. None of them knew why or how the city was built but within the city they act as regular people.

The city has multiple districts, for example one that is just for eating, one is a redlight district, one district you can enter and under no punishment you can do whatever you want to anyone else. The only oversight is that if you get mortally wounded you will get picked up by doctors and "repaired". Another district is red light district which one giant vertical building build into the earth, so it only has one story and all levels are below that. You have to take an elevator down. The more morally reprehensible the sex-realted thing is the deeper it is in the earth. The party characters will have to go to the deepest levels.

The reason for this is that the labl is in the center of the city is well protected so when our party are trying to break into it, they realize the best way would be to get onto the bottom of the pit, which is where the well was drilled towards the earth core, then climb up the drill to infiltrate the lab from below. At the very bottom there is a mini-society of people who aren't immune but they are not currently overtaken. The reason is that they are outside the radius of any other overtaken person, so a mini-society was built using all the trash that is dumped form the city into the giant hole.

When reaching the lab, the party realizes it's purpose and marvels at what many billion people working in perfect accord can accomplish in such little time. 

<details>
  <summary>This section contains major spoilers for `rat_game`, do not read this if you plan on playing the game</summary>
    Inside the lab they realize that the source has been working on creating another hivemind, one to whom no human, regardless of genetics, can stand up to, and one that can not only control humans, but all mammals, and eventually all animals at all. The party realizes that if it manages to do this, there is no way to stop it anymore, so they hurry towards the center.

At the central control room of the lab they find the actual "source", the origin and first node of the hivemind, and it's controller. The party confronts the entity and enters an elaborate final-boss-fight. The party wins and the origin lies slain on the floor. But nothing happens. Killing the origin does not disable the hivemind, every node is exactly as important as any other, it is a truly distributed system. The only way to actually kill the hivemind as an entity is to kill literally every being that could be susceptible to it. There is no saving the world, and the entire effort was pointless from the start, yet they still tried. 
</details>

# Characters & Plot

The main character "$MC" (the actual name of characters is chosen by the play, so this script will refer to them by their in-code variable name) is the player-controlled character. They are ambigously gendered and, bevore the takeover, owned a rat "$RAT", which they brought everywhere with them. After the prologue, $MC and $RAT will wake up from a coma, which was of amibigiousl length. The entire hivemind takeover has taken place during this time, so from the perspective of $MC they were attacked, knocked out, and woke up in a completely new world. One feature of this world is that $RAT can now talk. While the $MCs personalitiy is chosen through dialogue choices by the player, $RAT tends to me pragmatic, cunning, snippy, and fiercly loyal and fearless. It will be the main partner of $MC and voice of the script, especially for the first part of the games plot. While the player controls $MC in the overworld, during battle the player will control all party members. $MC and $RAT are the core party, with other characters joining and leaving as the story progresses.

$RAT and $MC make their way out of the hopsital $MC was kept in. $RAT notes that someone had to have cared for whim, usually when someone is in a coma they need daily care to fead them, turn the around to avoid bedsores, bathe them, etc. $RAT said that a group of 5, a mother, her daughter, one of the scouts and two brothers were the one that cared for $MC. All of them had to leave $MC and flee, as a hivemind militia was spotted approaching the hospital $MC woke up in. $RAT stayed behind, though neither $MC nor $RAT blame the others for fleeing.

At the current moment, the hivemind militia group enters the hospital, and $RAT and $MC have to fight their way out. The militia is made up of one little person with two incredibly huge dogs, and four soldiers. One of these soldiers wears a hat with a feather, he will become a central character eventually, but for now he is just another goon. During the fight, the little guy and his two dogs flee, while all four left-behind soldiers are killed in combat. $RAT and $MC make their way to the settlement they hope to find the group that cared for $MC in. After they left, one of the four soldiers, the one with the feather, wakes up, clearly wounded but not dead. He realizes his 3 companions are actually dead, and weeps over one person specifically, it seems they were very close. After a long time, the soldier with the feather gets up and goes into the same direction $MC and $RAT went in. His name is $WILDCARD.

$MC and $RAT find more militia roaming about, and they slowly realize the concept of the hivemind. They do not currently know how it works, but they clearly see that something has happened to the world. The party happens upon a small town which has a giant swimming pool hall, one of those where it's a rectangular pool meant for competitive swimming and diving. 

Entering the pool building, they realize that it is being used as the barracks of the militias, the mens changing area and most of the food court has been completely remodeled to be used as a makeshift militia base. The party fights their way through the mens changing area until they make it to the central hall, the one with the giant, uniformly deep swimming pool. In front is the little guy and his two dogs, behind him, the entire swimmings pool volume is filled with nothing but bodies. Intentionally evoking scenes from the real-world holocaust, this area was clearly just a dumping ground for all the fallen, and the sheer quantity of them shocks both the party and the player. A boss-fight ensues in which the guy and his two dogs actually fall this, the dog guy has been shown as cowardly, yet it is also clear that he was the leader of the militia. 

Making their way outside the pool building through the womens changing area, the party realizes that these rooms were used for food-storage and as an abattoir, for humans as well as farm animals for the militia. In one of the rooms they find a torture chamber, and in that chamber a man, clearly wounded but not fatally, strung up by chains. The party asks why he's here and the man responds that they tried to get out of him where "sanctuary" is, but the didn't give it to them. Realizing that $RAT and $MC are friendly, the tortured man is freed and joins the party. He is known as $SCOUT, a scout of the resitant settlement. The militia was trying to make him crack so he would reveal the location of his friends. This information was important enough that they kept him alive, but did not hold back on how much pain the could inflict on him. For now $SCOUT is weakened, but will eventually become a viable asset in battle.

The party, $RAT, $MC, and $SCOUT decide to head to "sanctuary", the largest resistant settlement. With the militias chief commander and most of his men dead, traveling there holds less of a risk now. To get to sanctuary, they travel through the dense forests, which will be important later.

Arriving at sanctuary, $SCOUT immediately runs of saying he wants to let his wife know that he is safe. Ad $RAT and $MC explore the settlement, they realize that, while it is basically a shanty town, people are in good spirites. There is enough food for everyone, and it seems like the life they are living is fullfilling to them. There are regular festivals, a small shrine has been built, and some of the people were medical doctors before the takeover. By plundering medical supplies from left-behind hospitals and pharmacies, the quality of life of sanctuary citizens is actually quite high.

The center of the town is a bar, call "$WIFEs Place" (where $WIFE is a variable name that is the name of its owner). The place seems like the very heart of sanctuary, it's completely packed and everyone seem to know everybody else. Tracking down $SCOUT, they find him in one of the back room, being patched up a woman. Nearby is a small girl, about 12 years old. She wants to help but her mother tells her it's okay, that she, $WIFE, can handle it. $SCOUT remarks that even though he is not her biological fater, if $GIRL ever wants to, $SCOUT is happy to adopt her.

Spending the night at "$WIFEs Place", $MC, who unlike $RAT, has only been concious for a few days, learns about the state of the world, the face the hivemind has taken over, that there are resistant people, though it is not clear to $WIFE what makes a person resistant, and how the hivemind has build a mega city not that far away from sanctuary. $SCOUT smartly notes that now that the militias command and men were killed, it is obvious that the hivemind will launch a counter attack against whatever killed them. $WIFE aggrees, and tells $SCOUT to contact $PROF, a lone scientist living in a secret underground lab. He, like all people in sanctuary, is also resistant, and has been trying to understand both resistance and the hiveminds mechanics. $SCOUT agrees to seek $PROF, and $RAT and $MC join him. $GIRL naively asks if she can come too, but she is immediately shut down by both $WIFE and $SCOUT, yet rat quips "I don't know she could be useful". $GIRL runs off crying, and the party, $SCOUT, $RAT, and $MC prepare for leaving. They will start walking in the evenning, such that they enter the forest under cover of night.

On their way to $PROF, $SCOUT remarks that the sun is abuot to come up, so they should start making a somewhat hidden camp to spend the day. After it is set up, scout offers food to both $RAT and $MC, the former of which is especially happy to get a small piece of cheese. The party hears a grumbling from one of the bushes, and as $SCOUT approaches, weapon ready, he finds $GIRL, exhausted and clearly hungry. It is clear she has been following the party all along, in the dark her trailing the party wasn't noticed. $RAT against remarks how not being detected by $SCOUT despite his experience is remarkable for such a young girl. It is clear that $RATs comment, both now and back at "$WIFEs Place", had given $GIRL a false confidence. The party decides that it would be too dangerous to send $GIRL back home alone, so she will have to travel with them to $PROF.

Finally out of the dense forest, they enter a savannah-like biom, in which there is what looks like an old colonial house, completely delapated. $SCOUT enters unperturber, and pushing a slab of stone aside, revealing a in-perfect-condition metal door. He pushes a button next to it, after which a camera drone enters the ruin and scans the party. $SCOUT explains who he is, and the door opens automatically.

Below the ruin is an entire underground lab, it has multiple rooms, all of which the party travels to without spotting $PROF. The first room is an entrance area, it holds many supplies and survival equipment. It's clear $PROF would be able to stay underground for months if not years. The second room gives $RAT pause, it is a wall full of plexglass boxes, inside each is what is clearly a labrat. More disturbingly, on the other side of a room is a similarly plexglass box, except much larger. Inside sleeps what looks like a small women. As rat tries to interact with her, she snarls and hits the box like a wild animal. $SCOUT ushers everyone into the next room, where $PROF is expecting them.

$PROF is an older guy with white hair and a ponytail. He's incredibly smart, but in a way that comes off as arrogant. Someone who corrects other people unprompted, not for the sake of the truth but to feel superior. The party aggrees to spend the night in the underground lab, in which $PROF, who clearly had a pre-existant realtionship with $SCOUT, explains the exact mechanics of the source:. The source is a network of consciousness, each "node" is one humans brain. To be able to connect to the network, a node has to be within 30m of another node, who has to be within 30m of another node, etc. Only when one human is connected this way, are they overtaken. The moment they move out of that range, they regain free will. $RAT asks what it means to be resistant, and $PROF explains that it is linked to a genetic trait, a specific gene which is mutated in only about 0.01% of the population. For someone without this mutation, the moment they enter the 30m range of the network they essentially loose conciousness, and become and extension of the hivemind. While their body still works as a humans would, needed sleep, food, warmth, their mind is like a CPU core in a computer, it's processing power is shared and it shares a conciousness. 

$PROF explains that for those with the resistance mutation, the take over process, instead of immediately working, will instead trigger a kind of hallucinogenic trance, in which, from the perspective of the person being overtaken, they will enter a nightmare world that strongly dependes on each person. $SCOUT interjects, explaining how while he was being tortured, they specifically abused this fact, making sure anytime they got another try at taking him over they would make him experience afflicting incredible pain onto.., $SCOUT pauses and looks at $GIRL, then remains silent as $PROF chuckles. $RAT remarks that he never experienced the nightmare world, to which $PROF responds that only humans do. $MC then interjects, saying they also have never experienced it, to which $PROF pauses, then responds "me neither". The conversation is cut short by a firealarm blaring. Prof rushes into the opposite direction of the labs exit, then comes back with weapons and some gear for everyone. They all rush out to find the ruin is not under attack, but the dense forest that protected sanctuary is completely set ablaze. $GIRL and $SCOUT tell everyone to rush back, to try to save sanctuary from this forest fire. $PROF remarks under his breath that this is clearly not a natural catastrophy, but $SCOUT interprets this as him not caring about damage to nature, when in reality $PROF was pointing out that the fire was most likely started by humans.

The party travels through the burning forest, rushing towards sanctuary as fast as they can. As they travel, the player will recognize specific places from when he traveled through them in the opposite direction, except now they are completely lit on fire, while a thick smoke cloud blocks out all sunlight.

As the party reaches sanctuary, it is clear that it has been attacked. Some of the buildings are burning, and a few of the guards had been killed. The party rushes towards "$WIFEs Place", with $GIRL acting espacially panicked and irrational, stroming into the building with no regards to her safety, or who could be inside. As the party enters

<details>
  <summary>This section contains a description of sexual assault, reader discretion is advised</summary>
    They see another man, in the same commander outfit the small dog guy was in, except this new guy is enormous, both in size and weight. When the party enters the room, he is facing away from them, towards a wall. $GIRL scrams her mothers name, and tries to rush towards where the big guy is standing, but $SCOUT janks her hair and pulls her behind them. The big guy slowly turns around, laughing, he zips up his pants and walks menacingly towards the party. As he approaches, the body of $WIFT behind him is revealed, mostly naked and bleeding profusely from her genital region. 
</details>

$WIFEs neck is broken and she is clearly dead. The huge guy, clearly her killer, attacks the party resulting in another boss fight.

While the party is victorious, $GIRL who has been somewhat useful in battle up to this point, can be selected during the battle and she can be told to perform usual offensive actions, but when it is actually her turn she freezes, sobs, or is otherwise unable to attack or protect herself. She can still be targeted by the boss, so the party is forced to protect her, even though she has up until now been nothing but valuable asset battle.

With the boss slain and the raid ended, $SCOUT travels through what remains of sanctuary, among the ashes he finds nothing but bodies, all of them were killed on sight. "This is just like during the takeover", he sobs. $GIRL becomes unconsolable at this comment, and $RAT tries to comfort her. $GIRL has not spoken a word since she entered the room with her mothers body, and during any section mentioning $GIRL from here on, she will not talk, only emote with noises or facial expressions.

$SCOUT and $PROF resolve that there is nothing they can do, all they can is get revenge. $PROF instructs the party about "The Lab", which is where all of the manpower of the hivemind is focused on. It moves billions of people into "The Lab", for a purpose unknown to prof. The party, now $RAT, $MC, $PROF, $SCOUT and $GIRL, elect to travel there.

The party walks through the same exact forest they traveled through twice now, one when it was green and beautiful, once while it was ablaze, and now while it is nothing but ashes. The smoke has cleared at this point and there are barealy any embers left. They not moose and deer, bruned alive and stuck in a pose of agony among the soft ashes of what was their home.

As the party approaches "The Lab", they see a group of militia putting up what looks like a professionally made sign, like those on highways notifying drivers of the next exit. The original name of the location has been removed, instead it now says "Neo Sanctuary". $SCOUT immediately charges towards the militia, and the party is forced to engage them. After the fight, $PROF scolds $SCOUT for acting reckless, "we can't attack everything on sight, that will be suicide eventually". $SCOUT agrees, at which point $RAT asks him why he attacked then. "They renamed it to mock use, *Neo* Sanctuary. They know we are coming, and the want us to know that they know". $PROF agrees, at which point $RAT asks why a hivemind that has taken over an entire planet and enslaved billions of people would care about a small group of 5. $MC guesses that it was because they killed two commanders and their militias, but $PROF laughs at this remark. "It's because it's funny to it". "To whom?", "The source, the origin of the hivemind. If all my research has taught me one thing, then it's that the source has a destinct personality, and it loves messing with people". $SCOUT scoffs at this, calling the "source" nothing but an anonymous hivemind, it acts like a force of nature, and should be treated as such.

As the party closes in on Neo Sanctuary, its layout becomes clear.

