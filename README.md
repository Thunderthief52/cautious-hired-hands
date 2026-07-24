# Cautious Hired Hands

`Cautious Hired Hands` is a Playlunky/Overlunky Lua mod for Spelunky 2. It keeps the game's normal Hired Hand AI and adds a last-moment safety filter to its decisions.

## What version 0.1 does

- Stops grounded Hired Hands before lava, spikes, dangerous traps, and overly deep drops.
- Blocks attacks when a player or another Hired Hand is in the weapon's line of fire.
- Avoids attacking near friendly NPCs, altars, bombs, powder kegs, and cursed/lava pots.
- Prevents Hired Hands from stealing shop items.
- Refuses the most indiscriminate pickups, including teleporters, plasma cannons, scepters, clone guns, live explosives, cursed pots, and lava pots.
- Tries to duck or jump when a fast horizontal projectile is about to hit.
- Raises low trust to a configurable minimum and discourages wandering away from the leader.
- Exposes every major behavior as an option in the script settings.

This mod makes Hired Hands more cautious, not invincible. It cannot plan an entire generated level, predict every chain reaction, or rescue a companion that is already falling into danger.

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
6. Finish a level with it; it should transfer normally and continue using the safety layer.

Turn on **Debug safety decisions** in the script options if a choice seems wrong. The console messages will say why an input was blocked. A screenshot/video plus those messages will make tuning much faster.

## Recommended defaults

The shipped settings favor survival over speed. If the Hired Hand hesitates too much:

- Raise **Maximum cautious drop** from 3 to 4.
- Turn off **Protect shops and friendly NPCs** after a shopkeeper has already become hostile.
- Lower **Minimum trust** to 0 to retain the vanilla trust/sleep progression.
- Turn off **Refuse extremely dangerous items** if you intentionally want it to carry a quest item or weapon from that list.

## Compatibility target

Written for the current Overlunky/Playlunky Lua API as of July 2026. The mod uses only safe-mode API calls and does not require `meta.unsafe`.
