#include "constants/battle_constants.h"
#include "constants/ability.h"
.include "battle_commands.inc"

.data

// Beak Blast (port addition): a contact move burned its attacker (the side-effect mon; the
// engine checked it has no status). Showdown trySetStatus('brn') from the Beak Blast user:
// Fire types, Water Veil & co., Leaf Guard in sun, Flower Veil, Safeguard and Misty Terrain
// stop it silently.
_000:
    CompareMonDataToValue OPCODE_EQU, BATTLER_CATEGORY_SIDE_EFFECT_MON, BMON_DATA_TYPE_1, TYPE_FIRE, _end
    CompareMonDataToValue OPCODE_EQU, BATTLER_CATEGORY_SIDE_EFFECT_MON, BMON_DATA_TYPE_2, TYPE_FIRE, _end
    GoToIfThirdType BATTLER_CATEGORY_SIDE_EFFECT_MON, TYPE_FIRE, _end
    CheckAbility CHECK_OPCODE_HAVE, BATTLER_CATEGORY_SIDE_EFFECT_MON, ABILITY_WATER_VEIL, _end
    CheckAbility CHECK_OPCODE_HAVE, BATTLER_CATEGORY_SIDE_EFFECT_MON, ABILITY_WATER_BUBBLE, _end
    CheckAbility CHECK_OPCODE_HAVE, BATTLER_CATEGORY_SIDE_EFFECT_MON, ABILITY_COMATOSE, _end
    CheckAbility CHECK_OPCODE_HAVE, BATTLER_CATEGORY_SIDE_EFFECT_MON, ABILITY_THERMAL_EXCHANGE, _end
    CheckAbility CHECK_OPCODE_HAVE, BATTLER_CATEGORY_SIDE_EFFECT_MON, ABILITY_PURIFYING_SALT, _end
    CheckIgnoreWeather _flowerVeil
    CompareVarToValue OPCODE_FLAG_NOT, BSCRIPT_VAR_FIELD_CONDITION, FIELD_CONDITION_SUN_ALL, _flowerVeil
    CheckAbility CHECK_OPCODE_HAVE, BATTLER_CATEGORY_SIDE_EFFECT_MON, ABILITY_LEAF_GUARD, _end
_flowerVeil:
    CheckAbility CHECK_OPCODE_HAVE, BATTLER_CATEGORY_SIDE_EFFECT_MON, ABILITY_FLOWER_VEIL, _grassCheck
    CheckIgnorableAbility CHECK_OPCODE_HAVE, BATTLER_RELATIVE_ALLY|BATTLER_CATEGORY_SIDE_EFFECT_MON, ABILITY_FLOWER_VEIL, _grassCheck
    GoTo _safeguard
_grassCheck:
    CompareMonDataToValue OPCODE_EQU, BATTLER_CATEGORY_SIDE_EFFECT_MON, BMON_DATA_TYPE_1, TYPE_GRASS, _end
    CompareMonDataToValue OPCODE_EQU, BATTLER_CATEGORY_SIDE_EFFECT_MON, BMON_DATA_TYPE_2, TYPE_GRASS, _end
    GoToIfThirdType BATTLER_CATEGORY_SIDE_EFFECT_MON, TYPE_GRASS, _end
_safeguard:
    CompareVarToValue OPCODE_FLAG_SET, BSCRIPT_VAR_SIDE_CONDITION_STAT_CHANGE, SIDE_CONDITION_SAFEGUARD, _end
    GotoIfGrounded BATTLER_CATEGORY_SIDE_EFFECT_MON, _misty
    GoTo _burn
_misty:
    GotoIfTerrainOverlayIsType MISTY_TERRAIN, _end
_burn:
    PlayBattleAnimation BATTLER_CATEGORY_SIDE_EFFECT_MON, BATTLE_ANIMATION_BURNED
    Wait
    UpdateMonData OPCODE_FLAG_ON, BATTLER_CATEGORY_SIDE_EFFECT_MON, BMON_DATA_STATUS, STATUS_BURN
    // {0} was burned!
    PrintMessage 85, TAG_NICKNAME, BATTLER_CATEGORY_SIDE_EFFECT_MON
    Wait
    SetHealthbarStatus BATTLER_CATEGORY_SIDE_EFFECT_MON, BATTLE_ANIMATION_BURNED
    WaitButtonABTime 30
    // Synchronize on the burned attacker passes the burn back (as an ability effect)
    UpdateVar OPCODE_SET, BSCRIPT_VAR_SIDE_EFFECT_TYPE, SIDE_EFFECT_TYPE_ABILITY
    UpdateVar OPCODE_FLAG_ON, BSCRIPT_VAR_BATTLE_STATUS, BATTLE_STATUS_SYNCRONIZE
    TrySynchronizeStatus _berry
    CallFromVar BSCRIPT_VAR_TEMP_DATA
_berry:
    UpdateVar OPCODE_FLAG_OFF, BSCRIPT_VAR_BATTLE_STATUS, BATTLE_STATUS_SYNCRONIZE
    TryEatBerry BATTLER_CATEGORY_ATTACKER, HELD_ITEM_USE_REMOVE_CONDITION, _end
    CallFromVar BSCRIPT_VAR_TEMP_DATA
_end:
    End
