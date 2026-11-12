#include "constants/battle_constants.h"
.include "battle_commands.inc"

.data

// Upper Hand (port addition): flinches; fails unless the target is about to use a
// priority attack (checked in BattleController_CheckMoveFailures)
_000:
    UpdateVar OPCODE_SET, BSCRIPT_VAR_SIDE_EFFECT_FLAGS_INDIRECT, MOVE_SIDE_EFFECT_TO_DEFENDER|MOVE_SUBSCRIPT_PTR_FLINCH
    CalcCrit
    CalcDamage
    End
