#include "constants/battle_constants.h"
#include "constants/battle_message_constants.h"
.include "battle_commands.inc"

.data

// Spectral Thief (port addition): before the hit, the user takes the target's stat raises
_000:
    PrintAttackMessage
    Wait
    WaitButtonABTime 30
    // {0} stole the target's boosted stats!
    PrintMessage BATTLE_MSG_SPECTRAL_THIEF, TAG_NICKNAME, BATTLER_CATEGORY_ATTACKER
    Wait
    WaitButtonABTime 30
_loop:
    TrySpectralThiefStat _done
    Call BATTLE_SUBSCRIPT_UPDATE_STAT_STAGE
    GoTo _loop
_done:
    UpdateVar OPCODE_FLAG_OFF, BSCRIPT_VAR_BATTLE_STATUS, BATTLE_STATUS_MOVE_ANIMATIONS_OFF
    End
