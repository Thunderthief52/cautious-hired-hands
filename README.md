# Cautious Hired Hands

`Cautious Hired Hands` is a Playlunky/Overlunky Lua mod for Spelunky 2. It keeps the game's normal Hired Hand AI and adds a last-moment safety filter to its decisions.

## What version 0.2 does

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
- Raises low trust to a configurable minimum and discourages wandering away from the leader.
- Exposes every major behavior as an option in the script settings.

This mod makes Hired Hands much more cautious, not invincible. It cannot plan an entire generated level, predict every chain reaction, or rescue a companion that is already falling into danger. The stomp preference only overrides an attack when the enemy is stompable and the immediate approach passes the terrain-safety check.

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

1. Stand directly in front of a Hired Hand holding a shotgun; it should not fire through you.
2. Lead it toward ordinary spikes or a long ledge; it should stop or turn toward you.
3. Drop a lit bomb nearby; it should move away if one side is safe.
4. Fire an arrow horizontally toward it; it should attempt to duck or jump.
5. Enter a shop; it should leave unpaid items alone and avoid attacking nearby.
6. Put Hou Yi's Bow near it; it should leave the bow alone.
7. Give it a pet while you stand nearby; it should refuse to throw the pet.
8. Put a skeleton or loose body between it and your character, slightly off the direct firing line; it should avoid an attack that could knock the body into you.
9. Let it approach a basic stompable enemy on safe ground; it should usually jump toward the enemy instead of whipping or throwing.
10. Finish a level with it; it should transfer normally and continue using the safety layer.

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

## Compatibility target

Written for the current Overlunky/Playlunky Lua API as of July 2026. The mod uses only safe-mode API calls and does not require `meta.unsafe`.
