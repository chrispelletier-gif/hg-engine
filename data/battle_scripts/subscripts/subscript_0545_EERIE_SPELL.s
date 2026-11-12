#include "constants/battle_constants.h"
#include "constants/ability.h"
.include "battle_commands.inc"

.data

// Eerie Spell (port addition): SIDE_EFFECT_MON (the target) loses 3 PP of its last move.
_000:
    CheckIgnorableAbility CHECK_OPCODE_HAVE, BATTLER_CATEGORY_SIDE_EFFECT_MON, ABILITY_SHIELD_DUST, _end
    TryEerieSpell _end
    // It reduced the PP of {0}'s {1} by {2}!
    PrintMessage 398, TAG_NICKNAME_MOVE_NUMBER, BATTLER_CATEGORY_DEFENDER, BATTLER_CATEGORY_MSG_TEMP, BATTLER_CATEGORY_MSG_TEMP
    Wait
    WaitButtonABTime 30
_end:
    End
