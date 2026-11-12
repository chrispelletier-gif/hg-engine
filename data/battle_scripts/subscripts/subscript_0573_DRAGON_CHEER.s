#include "constants/battle_constants.h"
#include "constants/battle_message_constants.h"
.include "battle_commands.inc"

.data

// Dragon Cheer (port addition): ally crit stage +1 (+2 if Dragon)
_000:
    Call BATTLE_SUBSCRIPT_ATTACK_MESSAGE_AND_ANIMATION
    PortMove 2, _end
    // {0} is getting pumped!
    PrintMessage 276, TAG_NICKNAME, BATTLER_CATEGORY_SIDE_EFFECT_MON
    Wait
    WaitButtonABTime 30
_end:
    End
