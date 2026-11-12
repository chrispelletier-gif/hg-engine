#include "constants/battle_constants.h"
#include "constants/battle_message_constants.h"
.include "battle_commands.inc"
.data
// Pledge side condition (port addition); MSG_TEMP is on the side
_000:
    // A rainbow appeared in the sky on {team}'s side!
    PrintMessage BATTLE_MSG_RAINBOW, TAG_NONE_SIDE, BATTLER_CATEGORY_MSG_TEMP
    Wait
    WaitButtonABTime 30
    End
