#include "constants/battle_constants.h"
#include "constants/battle_message_constants.h"
.include "battle_commands.inc"
.data
// sea of fire end-of-turn damage (port addition); HP_CALC is set by the engine
_000:
    // {0} is hurt by the sea of fire!
    PrintMessage BATTLE_MSG_SEA_OF_FIRE_HURT, TAG_NICKNAME, BATTLER_CATEGORY_MSG_TEMP
    Wait
    WaitButtonABTime 30
    UpdateVar OPCODE_FLAG_ON, BSCRIPT_VAR_BATTLE_STATUS, BATTLE_STATUS_NO_BLINK
    Call BATTLE_SUBSCRIPT_UPDATE_HP
    TryActivateEmergencyExit BATTLER_CATEGORY_MSG_BATTLER_TEMP, _end
    Call BATTLE_SUBSCRIPT_HANDLE_WIMP_OUT_EMERGENCY_EXIT
_end:
    End
