#include "constants/battle_constants.h"
#include "constants/battle_message_constants.h"
.include "battle_commands.inc"
.data
// Pledge (port addition): waits for the ally's Pledge (MSG_TEMP), which goes next
_000:
    PrintAttackMessage
    Wait
    // {0} is waiting for {1}'s move...
    PrintMessage BATTLE_MSG_PLEDGE_WAIT, TAG_NICKNAME_NICKNAME, BATTLER_CATEGORY_ATTACKER, BATTLER_CATEGORY_MSG_TEMP
    Wait
    WaitButtonABTime 30
    End
