#include "constants/battle_constants.h"
#include "constants/battle_message_constants.h"
#include "constants/ability.h"
.include "battle_commands.inc"

.data

// Syrup Bomb (port addition): the target's Speed drops at the end of the next 3 turns
_000:
    CheckIgnorableAbility CHECK_OPCODE_HAVE, BATTLER_CATEGORY_DEFENDER, ABILITY_SHIELD_DUST, _end
    TryStartPortVolatile 1, _end
    // {0} got covered in sticky candy syrup!
    PrintMessage BATTLE_MSG_SYRUP_BOMB_START, TAG_NICKNAME, BATTLER_CATEGORY_DEFENDER
    Wait
    WaitButtonABTime 30
_end:
    End
