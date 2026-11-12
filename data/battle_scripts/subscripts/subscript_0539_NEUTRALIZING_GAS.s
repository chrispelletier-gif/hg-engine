#include "constants/battle_constants.h"
#include "constants/battle_message_constants.h"
.include "battle_commands.inc"

.data

// Neutralizing Gas (port addition): the holder (MSG_BATTLER_TEMP) entered. Other abilities
// are suppressed in GetBattlerAbility while it is on the field.
_Start:
    AbilityPopup BATTLER_CATEGORY_MSG_BATTLER_TEMP
    PrintMessage BATTLE_MSG_NEUTRALIZING_GAS, TAG_NONE
    Wait
    WaitButtonABTime 30
    End
