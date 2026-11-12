#include "constants/battle_constants.h"
#include "constants/battle_message_constants.h"
.include "battle_commands.inc"

.data

// Purify (port addition): cures the target, then heals the user 1/2
_000:
    Call BATTLE_SUBSCRIPT_ATTACK_MESSAGE_AND_ANIMATION
    Call BATTLE_SUBSCRIPT_PORT_CURE_STATUS
    PortMove 2, _end
    UpdateVar OPCODE_FLAG_ON, BSCRIPT_VAR_BATTLE_STATUS, BATTLE_STATUS_NO_BLINK
    PlayBattleAnimation BATTLER_CATEGORY_MSG_TEMP, BATTLE_ANIMATION_RESTORE_HP
    Wait
    Call BATTLE_SUBSCRIPT_UPDATE_HP
    // {0} regained health!
    PrintMessage 184, TAG_NICKNAME, BATTLER_CATEGORY_MSG_TEMP
    Wait
    WaitButtonABTime 30
_end:
    End
