#include "constants/battle_constants.h"
#include "constants/battle_message_constants.h"
.include "battle_commands.inc"

.data

// Sky Drop (port addition, Gen 5-7 rules as in Showdown): the first turn takes the target into
// the sky with the user, the second drops it for damage
_000:
    PortMove 8, _drop
    PortMove 9, _lift
_lift:
    CompareVarToValue OPCODE_EQU, BSCRIPT_VAR_TEMP_DATA, 1, _fail
    CompareVarToValue OPCODE_EQU, BSCRIPT_VAR_TEMP_DATA, 2, _heavy
    PrintAttackMessage
    Wait
    WaitButtonABTime 30
    PlayMoveAnimation BATTLER_CATEGORY_ATTACKER
    Wait
    ToggleVanish BATTLER_CATEGORY_ATTACKER, TRUE
    ToggleVanish BATTLER_CATEGORY_DEFENDER, TRUE
    // {0} took {1} into the sky!
    PrintMessage BATTLE_MSG_SKY_DROP_TAKE, TAG_NICKNAME_NICKNAME, BATTLER_CATEGORY_ATTACKER, BATTLER_CATEGORY_DEFENDER
    Wait
    WaitButtonABTime 30
    LockMoveChoice BATTLER_CATEGORY_ATTACKER
    UpdateVar OPCODE_FLAG_ON, BSCRIPT_VAR_BATTLE_STATUS, BATTLE_STATUS_CHARGE_TURN|BATTLE_STATUS_NO_ATTACK_MESSAGE
    UpdateVar OPCODE_FLAG_ON, BSCRIPT_VAR_MOVE_STATUS_FLAGS, MOVE_STATUS_NO_MORE_WORK
    End

_heavy:
    PrintAttackMessage
    Wait
    WaitButtonABTime 30
    // {0} is too heavy to be lifted!
    PrintMessage BATTLE_MSG_SKY_DROP_HEAVY, TAG_NICKNAME, BATTLER_CATEGORY_DEFENDER
    Wait
    WaitButtonABTime 30
    UpdateVar OPCODE_FLAG_ON, BSCRIPT_VAR_MOVE_STATUS_FLAGS, MOVE_STATUS_NO_MORE_WORK
    End

_fail:
    Call BATTLE_SUBSCRIPT_CHARGE_MOVE_CLEANUP
    PrintAttackMessage
    Wait
    WaitButtonABTime 30
    Call BATTLE_SUBSCRIPT_BUT_IT_FAILED
    End

_drop:
    Call BATTLE_SUBSCRIPT_CHARGE_MOVE_CLEANUP
    CompareVarToValue OPCODE_EQU, BSCRIPT_VAR_TEMP_DATA, 1, _fail
    CompareVarToValue OPCODE_EQU, BSCRIPT_VAR_TEMP_DATA, 2, _immune
    GoToEffectScript

_immune:
    GoToSubscript BATTLE_SUBSCRIPT_PORT_NO_EFFECT
