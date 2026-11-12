#include "constants/battle_constants.h"
#include "constants/battle_message_constants.h"
.include "battle_commands.inc"
.data
// Revival Blessing (port addition): the user's trainer picks a fainted party Pokemon, which
// comes back with half its max HP. The player picks in the party menu, the AI takes the first.
_000:
    Call BATTLE_SUBSCRIPT_ATTACK_MESSAGE_AND_ANIMATION
    PortMove 5, _picked
    ShowParty
    WaitMonSelection
_picked:
    PortMove 6, _end
    // {0} was revived and is ready to fight again!
    PrintBufferedMessage
    Wait
    WaitButtonABTime 30
_end:
    End
