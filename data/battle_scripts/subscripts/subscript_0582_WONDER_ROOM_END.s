#include "constants/battle_constants.h"
#include "constants/battle_message_constants.h"
.include "battle_commands.inc"

.data

// Wonder Room wears off (port addition)
_000:
    PrintMessage BATTLE_MSG_WONDER_ROOM_END, TAG_NONE
    Wait
    WaitButtonABTime 30
    End
