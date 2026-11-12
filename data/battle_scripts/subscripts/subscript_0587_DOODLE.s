#include "constants/battle_constants.h"
#include "constants/battle_message_constants.h"
.include "battle_commands.inc"
.data
// Doodle (port addition): the user and its allies copy the target's Ability
_000:
    Call BATTLE_SUBSCRIPT_ATTACK_MESSAGE_AND_ANIMATION
_loop:
    PortMove 1, _end
    PortMove 2, _loop
    // {0} copied {1}’s {2}!
    PrintMessage 523, TAG_NICKNAME_NICKNAME_ABILITY, BATTLER_CATEGORY_MSG_TEMP, BATTLER_CATEGORY_DEFENDER, BATTLER_CATEGORY_DEFENDER
    Wait
    WaitButtonABTime 30
    GoTo _loop
_end:
    End
