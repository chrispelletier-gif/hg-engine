#include "constants/battle_constants.h"
.include "battle_commands.inc"

.data

// Syrup Bomb end-of-turn Speed drop (port addition); the engine sets the stat-change target
_000:
    UpdateVar OPCODE_SET, BSCRIPT_VAR_SIDE_EFFECT_PARAM, MOVE_SUBSCRIPT_PTR_SPEED_DOWN_1_STAGE
    Call BATTLE_SUBSCRIPT_UPDATE_STAT_STAGE
    End
