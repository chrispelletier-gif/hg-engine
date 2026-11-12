#include "constants/battle_constants.h"
.include "battle_commands.inc"

.data

// Triple Arrows (port addition): TryTripleArrows rolls both secondary effects into TEMP_DATA
// (1 = Defense -1, 2 = flinch). Flinch first: it prints nothing, the stat change does.
_000:
    TryTripleArrows
    CompareVarToValue OPCODE_FLAG_NOT, BSCRIPT_VAR_TEMP_DATA, 2, _defense
    Call BATTLE_SUBSCRIPT_FLINCH_MON
_defense:
    CompareVarToValue OPCODE_FLAG_NOT, BSCRIPT_VAR_TEMP_DATA, 1, _end
    UpdateVar OPCODE_SET, BSCRIPT_VAR_SIDE_EFFECT_PARAM, MOVE_SUBSCRIPT_PTR_DEFENSE_DOWN_1_STAGE
    Call BATTLE_SUBSCRIPT_UPDATE_STAT_STAGE
_end:
    End
