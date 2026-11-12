#include "constants/battle_constants.h"
#include "constants/battle_message_constants.h"
.include "battle_commands.inc"
.data
// Instruct (port addition): the instructed move (queued like a Dancer move)
_000:
    UpdateVar OPCODE_FLAG_OFF, BSCRIPT_VAR_BATTLE_STATUS, BATTLE_STATUS_MOVE_ANIMATIONS_OFF|BATTLE_STATUS_NO_ATTACK_MESSAGE
    GoBackToBeforeMove
    End
