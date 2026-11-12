#include "constants/battle_constants.h"
.include "battle_commands.inc"

.data

// Cud Chew (port addition): at the end of the turn after it ate a Berry, the holder
// (MSG_BATTLER_TEMP) eats it again. TEMP_DATA = the berry's effect subscript (as for Bug Bite).
_Start:
    AbilityPopup BATTLER_CATEGORY_MSG_BATTLER_TEMP
    CompareVarToValue OPCODE_EQU, BSCRIPT_VAR_TEMP_DATA, 0, _end
    CallFromVar BSCRIPT_VAR_TEMP_DATA
_end:
    End
