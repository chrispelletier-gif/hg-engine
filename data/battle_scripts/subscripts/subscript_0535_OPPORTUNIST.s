#include "constants/battle_constants.h"
.include "battle_commands.inc"

// Opportunist: BATTLER_CATEGORY_MSG_BATTLER_TEMP copies the stat raises its opponents got
// (collected in C, applied once the move or switch-in is over).

.data

_Start:
    AbilityPopup BATTLER_CATEGORY_MSG_BATTLER_TEMP
    UpdateVarFromVar OPCODE_SET, BSCRIPT_VAR_LAST_BATTLER_ID, BSCRIPT_VAR_BATTLER_ATTACKER
    UpdateVarFromVar OPCODE_SET, BSCRIPT_VAR_BATTLER_ATTACKER, BSCRIPT_VAR_MSG_BATTLER_TEMP

_Loop:
    TryOpportunistBoost _Done
    Call BATTLE_SUBSCRIPT_UPDATE_STAT_STAGE
    GoTo _Loop

_Done:
    UpdateVarFromVar OPCODE_SET, BSCRIPT_VAR_BATTLER_ATTACKER, BSCRIPT_VAR_LAST_BATTLER_ID
    End
