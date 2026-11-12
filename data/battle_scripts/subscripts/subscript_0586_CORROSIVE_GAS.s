#include "constants/battle_constants.h"
#include "constants/battle_message_constants.h"
.include "battle_commands.inc"

.data

// Corrosive Gas (port addition): the message names the item before it goes
_000:
    Call BATTLE_SUBSCRIPT_ATTACK_MESSAGE_AND_ANIMATION
    PrintMessage BATTLE_MSG_CORROSIVE_GAS, TAG_NICKNAME_NICKNAME_ITEM, BATTLER_CATEGORY_ATTACKER, BATTLER_CATEGORY_DEFENDER, BATTLER_CATEGORY_DEFENDER
    Wait
    WaitButtonABTime 30
    PortMove 2, _end
_end:
    End
