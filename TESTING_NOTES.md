# Cautious Hired Hands testing notes

Use this file to record observations from the Windows PC. Exact rooms and short clips are especially helpful because procedural levels make AI bugs hard to reproduce.

## Version 0.7.1 cargo recovery

The regression reproduced a jetpack staying attached after knockdown in 0.7.0. Automated checks now cover release and recovery for all 39 cargo types, along with the existing 48 transition scenarios and automatic-collection checks. The grace is exactly 210 updates (3.5 seconds at 60 Hz), refreshed while stunned. PC results below remain pending.

| Build | Situation | Expected | Actual |
|---|---|---|---|
| 0.7.1 | Knock down an HH carrying a pack, cape, or pickup | Item becomes loose and recoverable by a human | Pending PC test |
| 0.7.1 | Walk onto the item while the HH is still stunned | Human can collect; HH cannot reclaim it | Pending PC test |
| 0.7.1 | Another HH stands beside the dropped item | Leaves it alone during stun and the following 3.5 seconds | Pending PC test |
| 0.7.1 | Leave the dropped item untouched after the HH recovers | Normal cargo pickup resumes after 3.5 seconds | Pending PC test |
| 0.7.1 | Collect dropped cargo, then finish the level | No replacement or duplicate appears | Pending PC test |
| 0.7.1 | Knockdown clears holding pointer but item remains attached | Attachment is removed and item becomes recoverable | Pending PC test |
| 0.7.1 | Carry cargo through an exit without a knockdown | Existing transfer behavior remains intact | Pending PC test |

## Version 0.7 expanded cargo

Automated checks pass for all 39 cargo types, including 48 transition scenarios and automatic collection for every type. These are Lua API simulations; the in-game results below remain pending.

| Build | Situation | Expected | Actual |
|---|---|---|---|
| 0.7.0 | Vlad's Cape beside an empty-handed HH | Hand-carried without being worn; survives exits | Pending PC test |
| 0.7.0 | Spectacles, mitt, compasses, parachute | Cargo without granting their effect | Pending PC test |
| 0.7.0 | Udjat Eye, crowns, Ankh, Tablet, skeleton key | Remain physical pickups through exits | Pending PC test |
| 0.7.0 | Bomb bags/boxes and rope supplies | Cargo without adding bombs or ropes to HH | Pending PC test |
| 0.7.0 | Jelly, turkey, giant food, elixir, clover | Cargo without healing or granting buffs to HH | Pending PC test |
| 0.7.0 | Player bag containing known bomb/rope counts | Same counts when a human collects it after an exit | Pending PC test |
| 0.7.0 | Supplies overlap an HH with occupied hands | Supplies remain loose and unconsumed | Pending PC test |
| 0.7.0 | Human touches hand-carried supplies | Human can collect normally | Pending PC test |
| 0.7.0 | Unpaid supplies, burning cargo, another character's held item | Not taken | Pending PC test |
| 0.7.0 | Ordinary weapon, protected bow, restricted weapon | Existing pickup/protection options still apply | Pending PC test |

## Version 0.6 exit regression

Automated Lua checks pass for the existing safety/follow behaviors and 19 cargo-transition scenarios. The checks reproduced a missing jetpack at an exit before the fix. The in-game results below have not yet been verified on Windows.

| Build | Situation | Expected | Actual |
|---|---|---|---|
| 0.6.0 | HH enters the exit before the player with a jetpack | Same HH holds one jetpack next level; it is not worn | Pending PC test |
| 0.6.0 | Repeat with hoverpack, powerpack, teleporter backpack, and cape | Each item returns in the hands | Pending PC test |
| 0.6.0 | HH takes a spare Kapala, then exits | Physical Kapala returns in hands without granting its effect | Pending PC test |
| 0.6.0 | Repeat with gloves, both shoes, and paste | Pickup remains cargo next level | Pending PC test |
| 0.6.0 | Cross two or more consecutive exits | Exactly one cargo item survives each exit | Pending PC test |
| 0.6.0 | Two HHs carry different items | Each receives its own cargo | Pending PC test |
| 0.6.0 | Drop cargo before the exit, or let its carrier die | No replacement appears | Pending PC test |
| 0.6.0 | Pack starts burning before an exit | It is dropped and not recreated | Pending PC test |
| 0.6.0 | Restart or return to camp | No equipment from the previous run appears | Pending PC test |

## Earlier behavior checklist

| Build | Level/seed | Situation | Expected | Actual | Debug message |
|---|---|---|---|---|---|
| 0.5.0 |  | Sprint away on safe flat ground | Renews pursuit and catches up |  |  |
| 0.5.0 |  | Horizontal plus vertical separation | Keeps navigating toward player |  |  |
| 0.5.0 |  | Catch-up route crosses deep drop | Stops before the drop but retains player target |  |  |
| 0.5.0 |  | Nearby enemy while separated | Handles immediate enemy, then resumes pursuit |  |  |
| 0.5.0 |  | Player and HH on different layers | Leaves transition behavior unchanged |  |  |
| 0.5.0 |  | Pack beside empty-handed HH | Carries it in hands, not on back |  |  |
| 0.5.0 |  | Yellow cape beside HH | Carries it without wearing it |  |  |
| 0.5.0 |  | Gloves/boots/paste beside HH | Carries item without gaining its effect |  |  |
| 0.5.0 |  | Second cargo item | Keeps current cargo and leaves second item |  |  |
| 0.5.0 |  | Combat with carried equipment | Does not throw it |  |  |
| 0.5.0 |  | Equipment carried through exit | Appears in hands next level |  |  |
| 0.5.0 |  | Burning pack | Drops it and retreats |  |  |
| 0.5.0 |  | Shop equipment | Leaves unpaid item alone |  |  |
| 0.5.0 |  | Ledge | Stops before unsafe drop |  |  |
| 0.5.0 |  | Spikes/lava | Stops or turns around |  |  |
| 0.5.0 |  | Player in firing line | Does not attack |  |  |
| 0.5.0 |  | Pet held near player | Does not throw the pet |  |  |
| 0.5.0 |  | Enemy/body near player | Does not knock it toward player |  |  |
| 0.5.0 |  | Basic enemy on safe ground | Prefers a stomp |  |  |
| 0.5.0 |  | Hou Yi's Bow | Leaves the bow alone |  |  |
| 0.5.0 |  | Lit bomb nearby | Moves to safer side |  |  |
| 0.5.0 |  | Incoming arrow | Reacts early and ducks or jumps |  |  |
| 0.5.0 |  | Shop | Does not steal or attack |  |  |

## Useful feedback

- Whether Playlunky loads the script without a console error.
- Which option values were active.
- The Hired Hand's held item and trust level.
- Whether the hazard was in front, behind, above, or below it.
- Whether the Hired Hand was holding a pet, body, rock, or weapon.
- Roughly how many tiles separated the player, Hired Hand, and intended target.
- For follow tests: whether the route was horizontal, vertical, blocked, hazardous, or briefly off-screen.
- For cargo tests: the equipment type, whether it appeared in the hands or became equipped, and what happened after a level exit.
- Any interaction with Eli's political Hired Hand mod.
