#include "constants/battle_constants.h"
#include "constants/battle_message_constants.h"
.include "battle_commands.inc"
.data
// Teatime (port addition): every active Pokemon eats its held Berry
_000:
    Call BATTLE_SUBSCRIPT_ATTACK_MESSAGE_AND_ANIMATION
    // It’s teatime! Everyone dug in to their Berries!
    PrintMessage BATTLE_MSG_TEATIME, TAG_NONE
    Wait
    WaitButtonABTime 30
    PortMove 3, _fail
_loop:
    PortMove 1, _end
    PortMove 2, _eaten
    CallFromVar BSCRIPT_VAR_TEMP_DATA
_eaten:
    RemoveItem BATTLER_CATEGORY_MSG_TEMP
    GoTo _loop
_fail:
    Call BATTLE_SUBSCRIPT_BUT_IT_FAILED
_end:
    End
