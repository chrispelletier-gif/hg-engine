#include "constants/battle_constants.h"
#include "constants/battle_message_constants.h"
.include "battle_commands.inc"

.data

// Neutralizing Gas (port addition): the last holder left; the switch-in abilities of the
// Pokemon on the field run again after this.
_Start:
    PrintMessage BATTLE_MSG_NEUTRALIZING_GAS_END, TAG_NONE
    Wait
    WaitButtonABTime 30
    End
