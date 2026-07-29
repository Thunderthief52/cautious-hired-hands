# Cautious Hired Hands

`Cautious Hired Hands` is a Playlunky/Overlunky Lua mod for Spelunky 2. It keeps the game's normal Hired Hand AI and adds a last-moment safety filter to its decisions.

## What version 0.5 does

Version 0.5 adds persistent, safety-filtered catch-up behavior:

- When a Hired Hand falls farther behind than the configured **Catch-up distance**, it renews the human player as its AI target instead of settling into an idle or local wandering routine.
- On safe ground, it stops walking away and presses toward the player until it returns to the follow buffer.
- Horizontal and vertical separation both activate catch-up, so quickly climbing or dropping through a level does not make it forget the player.
- A nearby combat target is preserved, and the safe-stomp choice can override catch-up movement, so the Hired Hand can still protect itself while separated.
- Every catch-up step still passes through the lava, trap, and deep-drop filter. The mod does not teleport Hired Hands, force them over dangerous terrain, or interfere when player and companion are on different layers.

The feature is enabled by **Persistent safe follow**. The default **Catch-up distance** is 8 tiles; lower it for a closer companion or raise it to give the player more personal space.

Version 0.4's experimental cargo slot for co-op duplicate equipment remains included:

- An empty-handed Hired Hand can collect a jetpack, hoverpack, powerpack, teleporter backpack, yellow cape, climbing gloves, spring shoes, spike shoes, or paste within about 1.35 tiles.
- The equipment is attached to its hands as inert cargo instead of being worn or added to its powerups, so the Hired Hand does not gain the item effect.
- Normal pickup behavior is skipped for these items, preventing gloves, boots, and paste from disappearing into the Hired Hand's inventory.
- Each Hired Hand carries only one cargo item and keeps whatever it already holds.
- It will not throw carried equipment, steal it from a shop, pick up a burning item, or keep holding equipment that catches fire.
- A burning carried pack is dropped and treated like a live explosive so the Hired Hand attempts to retreat.

The feature is enabled by **Carry spare equipment (experimental)**. Turn that option off if an item appears in the wrong position, disappears during a level transition, or conflicts with another behavior mod.

The larger cargo list has negligible performance cost: the mod still makes one small nearby-item query only while a Hired Hand's hands are empty.

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
2. Put the resulting `CautiousHiredHands` folder in:

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
13. Drop a pack, yellow cape, climbing gloves, either pair of shoes, or paste beside an empty-handed Hired Hand; it should carry the item visibly without equipping or collecting it.
14. Jump and fight after it takes the equipment; the item should stay inert, and the Hired Hand should not throw it during combat.
15. Finish a level while it carries spare equipment; check that the item transfers and returns to its hands in the next level.
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
- Turn off **Carry spare equipment (experimental)** to leave equipment handling entirely to the vanilla game.

## Compatibility target

Written for the current Overlunky/Playlunky Lua API as of July 2026. The mod uses only safe-mode API calls and does not require `meta.unsafe`.
