#include "constants/battle_constants.h"
#include "constants/battle_message_constants.h"
.include "battle_commands.inc"

.data

// Curious Medicine: the ally's (SIDE_EFFECT_MON) stat stages were already reset in C.
_Start:
    AbilityPopup BATTLER_CATEGORY_MSG_BATTLER_TEMP
    // {0}'s stat changes were removed!
    PrintMessage BATTLE_MSG_CURIOUS_MEDICINE, TAG_NICKNAME, BATTLER_CATEGORY_SIDE_EFFECT_MON
    Wait
    WaitButtonABTime 30
    End
