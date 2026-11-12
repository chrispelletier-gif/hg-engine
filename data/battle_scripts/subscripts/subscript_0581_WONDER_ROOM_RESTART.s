#include "constants/battle_constants.h"
#include "constants/battle_message_constants.h"
.include "battle_commands.inc"

.data

// Wonder Room used while active: it ends (port addition)
_000:
    Call BATTLE_SUBSCRIPT_ATTACK_MESSAGE_AND_ANIMATION
    PrintMessage BATTLE_MSG_WONDER_ROOM_END, TAG_NONE
    Wait
    WaitButtonABTime 30
    End
