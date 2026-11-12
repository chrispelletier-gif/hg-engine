#include "constants/battle_constants.h"
#include "constants/battle_message_constants.h"
.include "battle_commands.inc"

.data

// Aromatic Mist (port addition): ally +1 SpD
_000:
    Call BATTLE_SUBSCRIPT_ATTACK_MESSAGE_AND_ANIMATION
    UpdateVar OPCODE_SET, BSCRIPT_VAR_SIDE_EFFECT_TYPE, SIDE_EFFECT_TYPE_MOVE_EFFECT
    UpdateVar OPCODE_SET, BSCRIPT_VAR_SIDE_EFFECT_PARAM, MOVE_SUBSCRIPT_PTR_SP_DEFENSE_UP_1_STAGE
    Call BATTLE_SUBSCRIPT_UPDATE_STAT_STAGE
    End
