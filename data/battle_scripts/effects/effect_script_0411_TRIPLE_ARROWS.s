#include "constants/battle_constants.h"
.include "battle_commands.inc"

.data

// Triple Arrows (port addition): high critical ratio; 50% Defense -1 and 30% flinch
_000:
    UpdateVar OPCODE_ADD, BSCRIPT_VAR_CRITICAL_BOOSTS, 1
    UpdateVar OPCODE_SET, BSCRIPT_VAR_SIDE_EFFECT_FLAGS_INDIRECT, MOVE_SIDE_EFFECT_TO_DEFENDER|MOVE_SUBSCRIPT_PTR_TRIPLE_ARROWS
    CalcCrit
    CalcDamage
    End
