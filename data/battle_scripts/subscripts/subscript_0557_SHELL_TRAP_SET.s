#include "constants/battle_constants.h"
#include "constants/battle_message_constants.h"
.include "battle_commands.inc"

.data

// Shell Trap (port addition): start of the turn
_000:
    // {0} set a shell trap!
    PrintMessage BATTLE_MSG_SHELL_TRAP_SET, TAG_NICKNAME, BATTLER_CATEGORY_MSG_TEMP
    Wait
    WaitButtonABTime 30
    End
