#include "constants/battle_constants.h"
.include "battle_commands.inc"

.data

// Burning Jealousy (port addition): burns the target if its stats rose this turn
_000:
    JumpIfStatsNotRaisedThisTurn _end
    Call BATTLE_SUBSCRIPT_BURN
_end:
    End
