#include "constants/battle_constants.h"
#include "constants/battle_message_constants.h"
.include "battle_commands.inc"
.data
// Tera Shell (port addition): a full-HP Terapagos (MSG_TEMP) takes the hit as not very effective
_000:
    PrintAttackMessage
    Wait
    WaitButtonABTime 30
    AbilityPopup BATTLER_CATEGORY_MSG_BATTLER_TEMP
    // {0} made its shell gleam! It's distorting type matchups!
    PrintMessage BATTLE_MSG_TERA_SHELL, TAG_NICKNAME, BATTLER_CATEGORY_MSG_BATTLER_TEMP
    Wait
    WaitButtonABTime 30
    End
