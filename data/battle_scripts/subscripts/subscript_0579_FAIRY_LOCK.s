#include "constants/battle_constants.h"
#include "constants/battle_message_constants.h"
.include "battle_commands.inc"

.data

// Fairy Lock (port addition)
_000:
    Call BATTLE_SUBSCRIPT_ATTACK_MESSAGE_AND_ANIMATION
    PrintMessage BATTLE_MSG_FAIRY_LOCK, TAG_NONE
    Wait
    WaitButtonABTime 30
    End
