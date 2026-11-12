#include "constants/battle_constants.h"
#include "constants/battle_message_constants.h"
.include "battle_commands.inc"
.data
// Ball Fetch (port addition): picks up the Poke Ball from a failed throw (MSG_TEMP)
_000:
    AbilityPopup BATTLER_CATEGORY_MSG_BATTLER_TEMP
    // {0} found a {1}!
    PrintMessage BATTLE_MSG_BALL_FETCH, TAG_NICKNAME_ITEM, BATTLER_CATEGORY_MSG_BATTLER_TEMP, BATTLER_CATEGORY_MSG_BATTLER_TEMP
    Wait
    WaitButtonABTime 30
    End
