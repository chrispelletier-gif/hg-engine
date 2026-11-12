#include "constants/battle_constants.h"
.include "battle_commands.inc"

.data

// Syrup Bomb (port addition): damage, then a volatile on the target (a secondary effect)
_000:
    UpdateVar OPCODE_SET, BSCRIPT_VAR_SIDE_EFFECT_FLAGS_INDIRECT, MOVE_SIDE_EFFECT_TO_DEFENDER|MOVE_SUBSCRIPT_PTR_SYRUP_BOMB
    CalcCrit
    CalcDamage
    End
