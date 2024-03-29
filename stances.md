# Stances
+ Attack (A)
+ Defense (D)
+ Speed (S)
+ Heal (H)
+ Buff (B)
+ Omni (O)
+ None (X)



|   | A | D | S | H | B | O | X |
|---|---|--|--|--|--|---|---|
| A | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| D | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| S | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| H | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| B | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| O | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| X | 1 | 1 | 1 | 1 | 1 | 1 | 1 |

# Fatigue

For each turn a stance is active, fatigue will reduce the multiplier:

| Turn | Multiplier |
|------|------------|
| `0` | `1x` |
| `1` | `0.75x` |
| `2` | `0.5x` |
| `3` | `0.25x` |
| `4` | `0x` |
| `5+` | `0x` |

Stance Fatigue is displayed for the player as a segmented bar, with all segments there is no damage reduction, each turn a segment is lost

# STAB

Each move has exactly one stance alignment. If a moves type matched the current stance of the entity, it's effectiveness will be boosted:
