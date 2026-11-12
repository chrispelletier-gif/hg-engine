#include "constants/battle_constants.h"
.include "battle_commands.inc"

.data

// Gulp Missile (port addition): Cramorant (MSG_TEMP) caught its prey using Surf / Dive. The
// form (1 Gulping, 2 Gorging) was already set in C.
_Start:
    PlaySound BATTLER_CATEGORY_MSG_TEMP, 1980
    SetMosaic BATTLER_CATEGORY_MSG_TEMP, 8, 1
    Wait
    ChangeForm BATTLER_CATEGORY_MSG_TEMP
    PlaySound BATTLER_CATEGORY_MSG_TEMP, 1984
    SetMosaic BATTLER_CATEGORY_MSG_TEMP, 0, 1
    Wait
    End
