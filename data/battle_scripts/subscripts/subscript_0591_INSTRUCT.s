#include "constants/battle_constants.h"
#include "constants/battle_message_constants.h"
.include "battle_commands.inc"
.data
// Instruct (port addition): the target repeats its last move right after this one
_000:
    Call BATTLE_SUBSCRIPT_ATTACK_MESSAGE_AND_ANIMATION
    // {0} used the move instructed by {1}!
    PrintMessage BATTLE_MSG_INSTRUCT, TAG_NICKNAME_NICKNAME, BATTLER_CATEGORY_DEFENDER, BATTLER_CATEGORY_ATTACKER
    Wait
    WaitButtonABTime 30
    End
