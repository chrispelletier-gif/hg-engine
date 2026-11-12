#include "constants/battle_constants.h"
#include "constants/battle_message_constants.h"
.include "battle_commands.inc"

.data

// No Retreat (port addition): +1 all stats, then the user can't switch out
_000:
    Call BATTLE_SUBSCRIPT_ATTACK_MESSAGE_AND_ANIMATION
    UpdateVar OPCODE_SET, BSCRIPT_VAR_SIDE_EFFECT_TYPE, SIDE_EFFECT_TYPE_MOVE_EFFECT
    Call BATTLE_SUBSCRIPT_BOOST_ALL_STATS
    PortMove 2, _end
    PrintMessage BATTLE_MSG_NO_RETREAT, TAG_NICKNAME, BATTLER_CATEGORY_SIDE_EFFECT_MON
    Wait
    WaitButtonABTime 30
_end:
    End
