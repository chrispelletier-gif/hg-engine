#include "constants/battle_constants.h"
.include "battle_commands.inc"

.data

// Eerie Spell (port addition): the target's last move loses 3 PP (secondary effect)
_000:
    UpdateVar OPCODE_SET, BSCRIPT_VAR_SIDE_EFFECT_FLAGS_INDIRECT, MOVE_SIDE_EFFECT_TO_DEFENDER|MOVE_SUBSCRIPT_PTR_EERIE_SPELL
    CalcCrit
    CalcDamage
    End
