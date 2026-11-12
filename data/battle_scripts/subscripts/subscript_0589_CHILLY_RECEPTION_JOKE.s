#include "constants/battle_constants.h"
#include "constants/battle_message_constants.h"
.include "battle_commands.inc"
.data
// Chilly Reception (port addition): start of the turn
_000:
    // {0} is preparing to tell a chillingly bad joke!
    PrintMessage BATTLE_MSG_CHILLY_RECEPTION, TAG_NICKNAME, BATTLER_CATEGORY_MSG_TEMP
    Wait
    WaitButtonABTime 30
    End
