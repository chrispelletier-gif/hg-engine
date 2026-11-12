#include "constants/battle_constants.h"
#include "constants/battle_message_constants.h"
.include "battle_commands.inc"

.data

_000:
    UpdateVar OPCODE_SET, BSCRIPT_VAR_BATTLER_SPEED_TEMP, 0
    // backup attacker that we use for the message
    UpdateVarFromVar OPCODE_SET, BSCRIPT_VAR_CALC_TEMP, BSCRIPT_VAR_BATTLER_ATTACKER

_loop:
    GetMonBySpeedOrder BSCRIPT_VAR_MSG_BATTLER_TEMP

    CompareMonDataToValue OPCODE_EQU, BATTLER_CATEGORY_MSG_TEMP, BMON_DATA_CUSTAP_FLAG, 1, _printMessage
    CompareMonDataToValue OPCODE_NEQ, BATTLER_CATEGORY_MSG_TEMP, BMON_DATA_QUICK_CLAW_FLAG, 1, _continue
    // Quick Draw (port addition) also sets the Quick Claw flag
    CheckAbility CHECK_OPCODE_HAVE, BATTLER_CATEGORY_MSG_TEMP, ABILITY_QUICK_DRAW, _quickDraw
    GoTo _printMessage

_quickDraw:
    UpdateVarFromVar OPCODE_SET, BSCRIPT_VAR_BATTLER_ATTACKER, BSCRIPT_VAR_MSG_BATTLER_TEMP
    AbilityPopup BATTLER_CATEGORY_ATTACKER
    // {0} can act faster than normal, thanks to its Quick Draw!
    PrintMessage BATTLE_MSG_QUICK_DRAW, TAG_NICKNAME, BATTLER_CATEGORY_ATTACKER
    Wait
    WaitButtonABTime 30
    GoTo _continue

_printMessage:
    PlayBattleAnimation BATTLER_CATEGORY_MSG_TEMP, BATTLE_ANIMATION_HELD_ITEM
    Wait 
    // {0} can act faster than normal, thanks to its {1}!
    UpdateVarFromVar OPCODE_SET, BSCRIPT_VAR_BATTLER_ATTACKER, BSCRIPT_VAR_MSG_BATTLER_TEMP
    PrintMessage 1254, TAG_NICKNAME_ITEM, BATTLER_CATEGORY_ATTACKER, BATTLER_CATEGORY_ATTACKER
    Wait 
    WaitButtonABTime 30
    CompareMonDataToValue OPCODE_EQU, BATTLER_CATEGORY_MSG_TEMP, BMON_DATA_CUSTAP_FLAG, 1, _removeCustapBerry

_continue:
    // restore attacker from what it was
    UpdateVarFromVar OPCODE_SET, BSCRIPT_VAR_BATTLER_ATTACKER, BSCRIPT_VAR_CALC_TEMP
    UpdateVar OPCODE_ADD, BSCRIPT_VAR_BATTLER_SPEED_TEMP, 1
    GoToIfValidMon BSCRIPT_VAR_BATTLER_SPEED_TEMP, _loop
    End

_removeCustapBerry:
    RemoveItem BATTLER_CATEGORY_ATTACKER
    GoTo _continue
