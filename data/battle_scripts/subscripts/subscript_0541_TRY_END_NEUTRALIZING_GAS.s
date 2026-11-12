#include "constants/battle_constants.h"
#include "constants/battle_message_constants.h"
.include "battle_commands.inc"

.data

// Neutralizing Gas (port addition): MSG_BATTLER_TEMP is leaving (switch / faint). If it was the
// last holder, the gas wears off and the abilities of the Pokemon on the field start again.
// The caller sets MSG_BATTLER_TEMP again afterwards (the ability scripts change it).
_Start:
    TryEndNeutralizingGas BATTLER_CATEGORY_MSG_BATTLER_TEMP, _skip
    PrintMessage BATTLE_MSG_NEUTRALIZING_GAS_END, TAG_NONE
    Wait
    WaitButtonABTime 30
    Call BATTLE_SUBSCRIPT_SWITCH_IN_ABILITY_CHECK
_skip:
    End
