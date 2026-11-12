#include "constants/battle_constants.h"
#include "constants/battle_message_constants.h"
.include "battle_commands.inc"

.data

// Wonder Room (port addition)
_000:
    Call BATTLE_SUBSCRIPT_ATTACK_MESSAGE_AND_ANIMATION
    PrintMessage BATTLE_MSG_WONDER_ROOM, TAG_NONE
    Wait
    WaitButtonABTime 30
    End
