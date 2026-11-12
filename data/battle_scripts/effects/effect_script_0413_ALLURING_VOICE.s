#include "constants/battle_constants.h"
.include "battle_commands.inc"

.data

// Alluring Voice (port addition): the secondary effect only hits a target whose stats rose this turn
_000:
    UpdateVar OPCODE_SET, BSCRIPT_VAR_SIDE_EFFECT_FLAGS_INDIRECT, MOVE_SIDE_EFFECT_TO_DEFENDER|MOVE_SUBSCRIPT_PTR_ALLURING_VOICE
    CalcCrit
    CalcDamage
    End
