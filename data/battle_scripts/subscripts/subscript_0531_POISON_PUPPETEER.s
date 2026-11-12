#include "constants/battle_constants.h"
.include "battle_commands.inc"

// Poison Puppeteer: Pecharunt's move just poisoned BATTLER_CATEGORY_SIDE_EFFECT_MON,
// which also becomes confused. Called after every poisoning in the poison subscripts;
// only move-caused poison from Pecharunt with this ability counts. Failures are silent.

.data

_Start:
    CompareVarToValue OPCODE_FLAG_SET, BSCRIPT_VAR_BATTLE_STATUS, BATTLE_STATUS_SYNCRONIZE, _End
    CompareVarToValue OPCODE_EQU, BSCRIPT_VAR_SIDE_EFFECT_TYPE, SIDE_EFFECT_TYPE_DIRECT, _CheckPuppeteer
    CompareVarToValue OPCODE_EQU, BSCRIPT_VAR_SIDE_EFFECT_TYPE, SIDE_EFFECT_TYPE_INDIRECT, _CheckPuppeteer
    CompareVarToValue OPCODE_NEQ, BSCRIPT_VAR_SIDE_EFFECT_TYPE, SIDE_EFFECT_TYPE_MOVE_EFFECT, _End

_CheckPuppeteer:
    CheckAbility CHECK_OPCODE_NOT_HAVE, BATTLER_CATEGORY_ATTACKER, ABILITY_POISON_PUPPETEER, _End
    CompareMonDataToValue OPCODE_NEQ, BATTLER_CATEGORY_ATTACKER, BMON_DATA_SPECIES, SPECIES_PECHARUNT, _End
    CompareMonDataToValue OPCODE_EQU, BATTLER_CATEGORY_SIDE_EFFECT_MON, BMON_DATA_HP, 0, _End
    CheckAbility CHECK_OPCODE_HAVE, BATTLER_CATEGORY_SIDE_EFFECT_MON, ABILITY_OWN_TEMPO, _End
    CompareMonDataToValue OPCODE_FLAG_SET, BATTLER_CATEGORY_SIDE_EFFECT_MON, BMON_DATA_STATUS2, STATUS2_CONFUSION, _End
    GotoIfGrounded BATTLER_CATEGORY_SIDE_EFFECT_MON, _CheckTerrain
    GoTo _Confuse

_CheckTerrain:
    GotoIfTerrainOverlayIsType MISTY_TERRAIN, _End

_Confuse:
    AbilityPopup BATTLER_CATEGORY_ATTACKER
    PlayBattleAnimation BATTLER_CATEGORY_SIDE_EFFECT_MON, BATTLE_ANIMATION_CONFUSED
    Wait
    Random 3, 2
    UpdateMonDataFromVar OPCODE_FLAG_ON, BATTLER_CATEGORY_SIDE_EFFECT_MON, BMON_DATA_STATUS2, BSCRIPT_VAR_CALC_TEMP
    // {0} became confused!
    PrintMessage 156, TAG_NICKNAME, BATTLER_CATEGORY_SIDE_EFFECT_MON
    Wait
    WaitButtonABTime 30

_End:
    End
