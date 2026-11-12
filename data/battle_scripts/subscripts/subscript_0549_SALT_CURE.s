#include "constants/battle_constants.h"
#include "constants/battle_message_constants.h"
#include "constants/ability.h"
.include "battle_commands.inc"

.data

// Salt Cure (port addition): the target takes 1/8 max HP (1/4 if Water or Steel) each turn
_000:
    CheckIgnorableAbility CHECK_OPCODE_HAVE, BATTLER_CATEGORY_DEFENDER, ABILITY_SHIELD_DUST, _end
    TryStartPortVolatile 0, _end
    // {0} is being salt cured!
    PrintMessage BATTLE_MSG_SALT_CURE_START, TAG_NICKNAME, BATTLER_CATEGORY_DEFENDER
    Wait
    WaitButtonABTime 30
_end:
    End
