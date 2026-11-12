#include "constants/battle_constants.h"
#include "constants/battle_message_constants.h"
.include "battle_commands.inc"

.data

// Pledges (port addition): a combined Pledge says so right after "X used Y!"
_000:
    PortMove 4, _plain
    PrintAttackMessage
    Wait
    // The two moves have become one! It's a combined move!
    PrintMessage BATTLE_MSG_PLEDGE_COMBINE, TAG_NONE
    Wait
    WaitButtonABTime 30
_plain:
    GoToEffectScript
