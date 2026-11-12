#include "constants/battle_constants.h"
#include "constants/battle_message_constants.h"
.include "battle_commands.inc"

.data

// Shell Trap (port addition): not hit by a physical move this turn
_000:
    // {0}'s shell trap didn't work!
    PrintMessage BATTLE_MSG_SHELL_TRAP_FAIL, TAG_NICKNAME, BATTLER_CATEGORY_ATTACKER
    Wait
    WaitButtonABTime 30
    End
