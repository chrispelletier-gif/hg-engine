#include "constants/battle_constants.h"
.include "battle_commands.inc"

.data

// Alluring Voice (port addition): confuses the target if its stats rose this turn
_000:
    JumpIfStatsNotRaisedThisTurn _end
    Call BATTLE_SUBSCRIPT_CONFUSE
_end:
    End
