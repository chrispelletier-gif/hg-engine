#include "constants/battle_constants.h"
#include "constants/battle_message_constants.h"
.include "battle_commands.inc"

.data

// Beak Blast (port addition): start of the turn
_000:
    // {0} started heating up its beak!
    PrintMessage BATTLE_MSG_BEAK_BLAST, TAG_NICKNAME, BATTLER_CATEGORY_MSG_TEMP
    Wait
    WaitButtonABTime 30
    End
