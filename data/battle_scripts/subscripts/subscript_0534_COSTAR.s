#include "constants/battle_constants.h"
#include "constants/battle_message_constants.h"
.include "battle_commands.inc"

.data

// Costar: the holder (MSG_BATTLER_TEMP) copied the ally's (SIDE_EFFECT_MON) stat stages in C.
_Start:
    AbilityPopup BATTLER_CATEGORY_MSG_BATTLER_TEMP
    // {0} copied {1}'s stat changes!
    PrintMessage 452, TAG_NICKNAME_NICKNAME, BATTLER_CATEGORY_MSG_BATTLER_TEMP, BATTLER_CATEGORY_SIDE_EFFECT_MON
    Wait
    WaitButtonABTime 30
    End
