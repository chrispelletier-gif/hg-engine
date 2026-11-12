#include "constants/battle_constants.h"
#include "constants/battle_message_constants.h"
.include "battle_commands.inc"
.data
// Sky Drop (port addition): the carried Pokemon (MSG_BATTLER_TEMP) is let down
_000:
    // {0} was freed from the Sky Drop!
    PrintMessage BATTLE_MSG_SKY_DROP_FREED, TAG_NICKNAME, BATTLER_CATEGORY_MSG_BATTLER_TEMP
    Wait
    WaitButtonABTime 30
    End
