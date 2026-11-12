#include "constants/battle_constants.h"
#include "constants/battle_message_constants.h"
.include "battle_commands.inc"

.data

// Aroma Veil (port addition): a move that would infatuate, Disable, Encore, Heal Block,
// Taunt or Torment the holder or its ally fails. ABILITY_MON = holder, MSG_BATTLER_TEMP = target.
_Start:
    PrintAttackMessage
    Wait
    WaitButtonABTime 30
    AbilityPopup BATTLER_CATEGORY_ABILITY_MON
    // {0} is protected by an aromatic veil!
    PrintMessage BATTLE_MSG_AROMA_VEIL, TAG_NICKNAME, BATTLER_CATEGORY_MSG_BATTLER_TEMP
    Wait
    WaitButtonABTime 30
    End
