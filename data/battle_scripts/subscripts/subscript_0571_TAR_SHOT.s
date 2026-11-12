#include "constants/battle_constants.h"
#include "constants/battle_message_constants.h"
.include "battle_commands.inc"

.data

// Tar Shot (port addition): -1 Speed, then Fire weakness
_000:
    Call BATTLE_SUBSCRIPT_ATTACK_MESSAGE_AND_ANIMATION
    UpdateVar OPCODE_SET, BSCRIPT_VAR_SIDE_EFFECT_TYPE, SIDE_EFFECT_TYPE_MOVE_EFFECT
    UpdateVar OPCODE_SET, BSCRIPT_VAR_SIDE_EFFECT_PARAM, MOVE_SUBSCRIPT_PTR_SPEED_DOWN_1_STAGE
    Call BATTLE_SUBSCRIPT_UPDATE_STAT_STAGE
    PortMove 2, _end
    PrintMessage BATTLE_MSG_TAR_SHOT, TAG_NICKNAME, BATTLER_CATEGORY_SIDE_EFFECT_MON
    Wait
    WaitButtonABTime 30
_end:
    End
