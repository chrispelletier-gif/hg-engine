#include "constants/battle_constants.h"
#include "constants/battle_message_constants.h"
.include "battle_commands.inc"

.data

// Jungle Healing / Lunar Blessing: user and allies heal 1/4 and are cured (port addition)
_000:
    Call BATTLE_SUBSCRIPT_ATTACK_MESSAGE_AND_ANIMATION
_loop:
    PortMove 1, _end
    PortMove 2, _cure
    UpdateVar OPCODE_FLAG_ON, BSCRIPT_VAR_BATTLE_STATUS, BATTLE_STATUS_NO_BLINK
    PlayBattleAnimation BATTLER_CATEGORY_MSG_TEMP, BATTLE_ANIMATION_RESTORE_HP
    Wait
    Call BATTLE_SUBSCRIPT_UPDATE_HP
    // {0} regained health!
    PrintMessage 184, TAG_NICKNAME, BATTLER_CATEGORY_MSG_TEMP
    Wait
    WaitButtonABTime 30
_cure:
    Call BATTLE_SUBSCRIPT_PORT_CURE_STATUS
    GoTo _loop
_end:
    End
