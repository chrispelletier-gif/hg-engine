#include "constants/battle_constants.h"
#include "constants/battle_message_constants.h"
.include "battle_commands.inc"

.data

// port status moves: the move's own subscript, or "But it failed!"
_000:
    PortMove 0, _fail
    CallFromVar BSCRIPT_VAR_TEMP_DATA
    End
_fail:
    PrintAttackMessage
    Wait
    WaitButtonABTime 30
    Call BATTLE_SUBSCRIPT_BUT_IT_FAILED
    End
