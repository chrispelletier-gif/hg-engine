#include "constants/battle_constants.h"
.include "battle_commands.inc"
.data
// Tera Shift (port addition): Terapagos takes its Terastal Form on entry (MSG_TEMP)
_000:
    AbilityPopup BATTLER_CATEGORY_MSG_BATTLER_TEMP
    PortMove 10, _shell
_shell:
    GoToSubscript BATTLE_SUBSCRIPT_FORM_CHANGE
