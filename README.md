# Cautious Hired Hands

`Cautious Hired Hands` is a Playlunky/Overlunky Lua mod for Spelunky 2. It keeps the game's normal Hired Hand AI and adds a last-moment safety filter to its decisions.

## What version 0.7.1 fixes

Knocking down a Hired Hand now releases its cargo so a human player can recover it. Stunned or dying companions cannot take new cargo through either normal pickup or automatic overlap. After a knockdown, the companion and all other Hired Hands leave the dropped item alone while it is stunned and for **3.5 seconds after recovery**. Ordinary deliberate drops get the same pickup grace.

This also handles cases where the game clears the held-item pointer but leaves the cargo attached. Released cargo is removed from the companion's exit record, so collecting it does not create another copy next level. Normal weapons continue to use their vanilla knockdown/drop behavior.

## Supported cargo in version 0.7

Version 0.7 expands the cargo slot from 10 to **39 item types**, including all 33 `ITEM_PICKUP_*` types in the current API:

| Group | Items carried without using or collecting them |
|---|---|
| Back equipment | Jetpack, hoverpack, powerpack, teleporter backpack, yellow cape, Vlad's Cape |
| Equipment and quest pickups | Spectacles, climbing gloves, pitcher's mitt, spring shoes, spike shoes, paste, compass, special compass, parachute, Udjat Eye, Kapala, Hedjet, crown, eggplant crown, true crown, Ankh, Tablet of Destiny, skeleton key |
| Supplies | Single rope, rope pile, bomb bag, bomb box, 12-bag, 24-bag, player bag |
| Food and temporary buffs | Royal jelly, cooked turkey, giant food, elixir, clover |
| Other pickups | Torn journal page, journal, seeded-run unlocker |

Automatic overlap collection is intercepted as well as normal pickup, so supplies remain physical items for a human player to collect. Player bags retain their bomb and rope counts across exits. Every cargo type is protected against being thrown or activated by the Hired Hand.

The option is now labeled **Carry spare items (experimental)**; its saved setting is unchanged. Normal weapons and other items the vanilla AI already handles keep their existing behavior. The existing dangerous-pickup and Hou Yi's Bow options still apply, and unpaid shop items are left alone. Cargo support covers loose pickups and wearable items, rather than equipped effect entities, shop display placeholders, projectiles, or traps.

Automated checks cover all 39 types through pickup, automatic overlap, and repeated exits, plus shop/fire checks, occupied hands, native transfers, and option behavior. Windows/Playlunky gameplay testing remains pending.

## Exit persistence

Version 0.6 fixes spare equipment disappearing when a Hired Hand enters the end-of-level exit:

- Cargo is recorded on the companion using Overlunky's persistent `Entity.user_data`, including the item's transfer metadata.
- The item returns to the same companion's hands after the next level is generated, even if the exit animation cleared its held-item pointer. The transition tunnel does not erase this record.
- A pack the game already transferred is reused, preventing duplicates. If it arrived on the companion's back, it is moved back into its hands.
- Dropped or burning cargo and dead companions do not produce replacement equipment. Different Hired Hands keep their own cargo, and new runs start without old cargo.
- If another mod fills the companion's hands, or cargo handling is disabled during the transition, the restored equipment is left beside it.
- **Kapalas** join the existing cargo list and remain physical pickups for a player to collect.

The automated Lua scenarios cover all cargo types, repeated exits, the transition tunnel, multiple companions, native transfers, and dropped/burning cargo. A Windows/Playlunky in-game exit test is still required; see `TESTING_NOTES.md`.

## Following and cargo behavior

Version 0.5 adds persistent, safety-filtered catch-up behavior:

- When a Hired Hand falls farther behind than the configured **Catch-up distance**, it renews the human player as its AI target instead of settling into an idle or local wandering routine.
- On safe ground, it stops walking away and presses toward the player until it returns to the follow buffer.
- Horizontal and vertical separation both activate catch-up, so quickly climbing or dropping through a level does not make it forget the player.
- A nearby combat target is preserved, and the safe-stomp choice can override catch-up movement, so the Hired Hand can still protect itself while separated.
- Every catch-up step still passes through the lava, trap, and deep-drop filter. The mod does not teleport Hired Hands, force them over dangerous terrain, or interfere when player and companion are on different layers.

The feature is enabled by **Persistent safe follow**. The default **Catch-up distance** is 8 tiles; lower it for a closer companion or raise it to give the player more personal space.

The experimental cargo slot for co-op duplicate equipment and supplies:

- An empty-handed Hired Hand can take a supported item from the table above within about 1.35 tiles.
- The equipment is attached to its hands as inert cargo instead of being worn or added to its powerups, so the Hired Hand does not gain the item effect.
- Normal pickup and automatic collection are skipped for these items, preventing powerups and supplies from disappearing into the Hired Hand's inventory.
- Each Hired Hand carries only one cargo item and keeps whatever it already holds.
- It will not throw carried equipment, steal it from a shop, pick up a burning item, or keep holding equipment that catches fire.
- A burning carried pack is dropped and treated like a live explosive so the Hired Hand attempts to retreat.

The feature is enabled by **Carry spare items (experimental)**. Turn that option off if an item appears in the wrong position or conflicts with another behavior mod.

The nearby-item scan still runs only while a Hired Hand's hands are empty.

The existing safety layer still:

- Stops grounded Hired Hands before lava, spikes, dangerous traps, and overly deep drops.
- Blocks attacks when a player or another Hired Hand is in the weapon's widened line of fire.
- Refuses to throw a pet or other living creature while a protected character is nearby.
- Checks secondary knockback: it avoids hitting an enemy, body, or loose object that could then be knocked into the player.
- Favors jumping onto nearby stompable enemies over whipping or throwing at them when the approach is safe.
- Avoids attacking near friendly NPCs, altars, bombs, powder kegs, and cursed/lava pots.
- Prevents Hired Hands from stealing shop items.
- Leaves Hou Yi's Bow alone by default, independently of the other dangerous-item setting.
- Refuses the most indiscriminate pickups, including teleporters, plasma cannons, scepters, clone guns, live explosives, cursed pots, and lava pots.
- Reacts earlier to threats by ending idle pauses, scanning farther for incoming projectiles, and accounting for a projectile's vertical movement.
- Tries to duck or jump when a fast horizontal or diagonal projectile is about to hit.
- Raises low trust to a configurable minimum and persistently follows a distant leader when the immediate route is safe.
- Exposes every major behavior as an option in the script settings.

This mod makes Hired Hands much more cautious, not invincible. It cannot plan an entire generated level, predict every chain reaction, teleport a stranded companion, or rescue one that is already falling into danger. Persistent follow supplies a destination and safe immediate movement; the vanilla AI still has to navigate walls, ladders, doors, and complex vertical routes. The stomp preference only overrides an attack when the enemy is stompable and the immediate approach passes the terrain-safety check. Hand-carried equipment deliberately bypasses the game's normal equipping and powerup-collection paths, so this feature especially needs real-game testing.

## Install on the Windows PC

1. Unzip `CautiousHiredHands.zip`.
2. Put the resulting `CautiousHiredHands` folder in the following location, replacing the old mod folder when updating:

   `Spelunky 2\Mods\Packs\`

3. Open Modlunky 2, go to the Playlunky tab, and refresh the mod list.
4. Enable **Cautious Hired Hands** and launch the game through Playlunky.

The final layout should be:

```text
Spelunky 2\Mods\Packs\CautiousHiredHands\main.lua
```

Lua mods do not work reliably online. Test this in an offline/local run.

## Using it with Eli's political Hired Hand mod

If Eli's mod only changes sprites, names, or sounds, the two should work together. Enable both and put `CautiousHiredHands` later in the Playlunky load order.

If Eli's mod also contains a `main.lua` that changes Hired Hand behavior, keep a copy of it. We can merge the scripts after the first PC test if their hooks conflict.

## First test checklist

For a quick controlled test, spawn or find one Hired Hand and try these situations:

1. Sprint more than 8 tiles away across safe, flat ground; it should renew pursuit and catch up without crowding you.
2. Separate from it horizontally and vertically through a normal route; it should keep trying to navigate toward you.
3. Put a dangerous drop or spikes between you while it is catching up; it should not charge through the hazard.
4. Stand directly in front of a Hired Hand holding a shotgun; it should not fire through you.
5. Lead it toward ordinary spikes or a long ledge; it should stop or turn toward you.
6. Drop a lit bomb nearby; it should move away if one side is safe.
7. Fire an arrow horizontally toward it; it should attempt to duck or jump.
8. Enter a shop; it should leave unpaid items alone and avoid attacking nearby.
9. Put Hou Yi's Bow near it; it should leave the bow alone.
10. Give it a pet while you stand nearby; it should refuse to throw the pet.
11. Put a skeleton or loose body between it and your character, slightly off the direct firing line; it should avoid an attack that could knock the body into you.
12. Let it approach a basic stompable enemy on safe ground; it should usually jump toward the enemy instead of whipping or throwing.
13. Drop a pack, either cape, a powerup, quest pickup, food, or supplies beside an empty-handed Hired Hand; it should carry the item visibly without equipping or collecting it.
14. Jump and fight after it takes the equipment; the item should stay inert, and the Hired Hand should not throw it during combat.
15. Let it enter the exit before you while carrying spare equipment; check that the item returns to its hands in the next level. Repeat with a Kapala and then with two Hired Hands carrying different items, across at least two exits.
16. Finish a level with it; it should transfer normally and continue using the safety layer.

Turn on **Debug safety decisions** in the script options if a choice seems wrong. The console messages will say why an input was blocked. A screenshot/video plus those messages will make tuning much faster.

## Recommended defaults

The shipped settings favor survival over speed. If the Hired Hand hesitates too much:

- Raise **Maximum cautious drop** from 3 to 4.
- Turn off **Protect shops and friendly NPCs** after a shopkeeper has already become hostile.
- Lower **Minimum trust** to 0 to retain the vanilla trust/sleep progression.
- Turn off **Refuse extremely dangerous items** if you intentionally want it to carry a quest item or weapon from that list.
- Turn off **Leave Hou Yi's Bow alone** only if you specifically want a Hired Hand to carry the special bow.
- Turn off **Prevent collateral damage** if the wider throw and knockback exclusion zone feels too restrictive.
- Turn off **Faster reactions** to retain the vanilla idle pauses and the original shorter projectile scan.
- Raise **Catch-up distance** if you want more space, lower it if the Hired Hand still gets left behind, or turn off **Persistent safe follow** to retain vanilla pursuit behavior.
- Turn off **Carry spare items (experimental)** to leave equipment and supply handling entirely to the vanilla game.

## Compatibility target

Checked against the Overlunky/Playlunky Lua API in November 2026. Cargo persistence uses `Entity.user_data`, `ON.PRE_LOAD_SCREEN`, and `ON.POST_LEVEL_GENERATION`; the [API reference](https://spelunky-fyi.github.io/overlunky/#entity) describes when companion data is saved and restored. The mod uses only safe-mode API calls and does not require `meta.unsafe`.

## Automated checks

From the repository root, run `lua tests/mock_api.lua` with Lua 5.3 or newer. The test harness simulates the Overlunky companion-data lifecycle; it does not run Spelunky 2 or validate its rendering and native AI.
