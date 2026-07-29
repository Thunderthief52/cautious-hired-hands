# Cautious Hired Hands testing notes

Use this file to record observations from the Windows PC. Exact rooms and short clips are especially helpful because procedural levels make AI bugs hard to reproduce.

| Build | Level/seed | Situation | Expected | Actual | Debug message |
|---|---|---|---|---|---|
| 0.3.0 |  | Pack beside empty-handed HH | Carries it in hands, not on back |  |  |
| 0.3.0 |  | Jumping with carried pack | Pack remains inert |  |  |
| 0.3.0 |  | Combat with carried pack | Does not throw it |  |  |
| 0.3.0 |  | Pack carried through exit | Appears in hands next level |  |  |
| 0.3.0 |  | Burning pack | Drops it and retreats |  |  |
| 0.3.0 |  | Shop pack | Leaves unpaid pack alone |  |  |
| 0.3.0 |  | Ledge | Stops before unsafe drop |  |  |
| 0.3.0 |  | Spikes/lava | Stops or turns around |  |  |
| 0.3.0 |  | Player in firing line | Does not attack |  |  |
| 0.3.0 |  | Pet held near player | Does not throw the pet |  |  |
| 0.3.0 |  | Enemy/body near player | Does not knock it toward player |  |  |
| 0.3.0 |  | Basic enemy on safe ground | Prefers a stomp |  |  |
| 0.3.0 |  | Hou Yi's Bow | Leaves the bow alone |  |  |
| 0.3.0 |  | Lit bomb nearby | Moves to safer side |  |  |
| 0.3.0 |  | Incoming arrow | Reacts early and ducks or jumps |  |  |
| 0.3.0 |  | Shop | Does not steal or attack |  |  |

## Useful feedback

- Whether Playlunky loads the script without a console error.
- Which option values were active.
- The Hired Hand's held item and trust level.
- Whether the hazard was in front, behind, above, or below it.
- Whether the Hired Hand was holding a pet, body, rock, or weapon.
- Roughly how many tiles separated the player, Hired Hand, and intended target.
- For pack tests: the pack type, whether it appeared in the hands or on the back, and what happened after a level exit.
- Any interaction with Eli's political Hired Hand mod.
