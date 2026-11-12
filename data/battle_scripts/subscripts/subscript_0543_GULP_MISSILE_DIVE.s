#include "constants/battle_constants.h"
.include "battle_commands.inc"

.data

// Gulp Missile (port addition): Cramorant catches its prey on Dive's charging turn.
_Start:
    Call BATTLE_SUBSCRIPT_GULP_MISSILE_CATCH
    GoToSubscript BATTLE_SUBSCRIPT_DIVE_CHARGE_TURN
    End
