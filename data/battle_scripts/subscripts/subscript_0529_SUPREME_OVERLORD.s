#include "constants/battle_constants.h"
#include "constants/battle_message_constants.h"
.include "battle_commands.inc"

.data

_000:
    AbilityPopup BATTLER_CATEGORY_MSG_BATTLER_TEMP
    // {0} gained strength from the fallen!
    PrintMessage BATTLE_MSG_SUPREME_OVERLORD, TAG_NICKNAME, BATTLER_CATEGORY_MSG_BATTLER_TEMP
    Wait
    WaitButtonABTime 30
    End
