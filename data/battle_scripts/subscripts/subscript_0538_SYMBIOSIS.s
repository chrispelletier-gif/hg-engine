#include "constants/battle_constants.h"
.include "battle_commands.inc"

.data

// Symbiosis (port addition): the item was already passed in C (PortHge_TrySymbiosis), which
// set ABILITY_MON = holder and the buffered message "{holder} shared its {item} with {ally}!".
_Start:
    AbilityPopup BATTLER_CATEGORY_ABILITY_MON
    PrintBufferedMessage
    Wait
    WaitButtonABTime 30
    End
