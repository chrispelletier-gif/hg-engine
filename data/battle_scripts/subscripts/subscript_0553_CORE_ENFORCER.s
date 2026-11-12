#include "constants/battle_constants.h"
.include "battle_commands.inc"

.data

// Core Enforcer (port addition): the engine already set the suppression flag
_000:
    // {0}’s Ability was suppressed!
    PrintMessage 1012, TAG_NICKNAME, BATTLER_CATEGORY_DEFENDER
    Wait
    WaitButtonABTime 30
    End
