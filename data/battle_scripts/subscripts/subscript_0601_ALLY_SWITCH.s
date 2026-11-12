#include "constants/battle_constants.h"
#include "constants/battle_message_constants.h"
.include "battle_commands.inc"
.data
// Ally Switch (port addition): the user and its ally (MSG_TEMP) trade places
_000:
    Call BATTLE_SUBSCRIPT_ATTACK_MESSAGE_AND_ANIMATION
    HealthbarSlideOut BATTLER_CATEGORY_ATTACKER
    HealthbarSlideOut BATTLER_CATEGORY_MSG_TEMP
    Wait
    PortMove 2, _end
    // the sprites follow the swapped data (attacker = the user at its new place)
    ChangeForm BATTLER_CATEGORY_ATTACKER
    ChangeForm BATTLER_CATEGORY_MSG_TEMP
    Wait
    HealthbarSlideIn BATTLER_CATEGORY_ATTACKER
    HealthbarSlideIn BATTLER_CATEGORY_MSG_TEMP
    Wait
    // {0} and {1} switched places!
    PrintMessage BATTLE_MSG_ALLY_SWITCH, TAG_NICKNAME_NICKNAME, BATTLER_CATEGORY_ATTACKER, BATTLER_CATEGORY_MSG_TEMP
    Wait
    WaitButtonABTime 30
_end:
    End
