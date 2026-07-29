meta = {
    name = "Cautious Hired Hands",
    version = "0.4.0",
    description = [[Adds a safety layer to the normal Hired Hand AI. Hired Hands avoid dangerous drops, lava, traps, explosives, shoplifting, friendly fire, and dangerous collateral throws, and can cautiously carry spare equipment as inert cargo.]],
    author = "Adam & Eli"
}

-- Cautious Hired Hands deliberately keeps the vanilla state machine intact.
-- Immediately before a Hired Hand acts, this mod filters unsafe inputs and may
-- substitute a safer one. This is more compatible with game updates and other
-- character/texture mods than replacing every AI behavior.

register_option_bool(
    "avoid_terrain",
    "Avoid terrain hazards",
    "Stop before lava, spikes, dangerous traps, and drops deeper than the configured limit.",
    true
)
register_option_int(
    "safe_drop",
    "Maximum cautious drop",
    "Largest drop (in tiles) a grounded Hired Hand may deliberately walk into.",
    3,
    1,
    6
)
register_option_bool(
    "prevent_friendly_fire",
    "Prevent friendly fire",
    "Do not attack when a player or another Hired Hand is in the weapon's line of fire.",
    true
)
register_option_bool(
    "prevent_collateral_damage",
    "Prevent collateral damage",
    "Do not throw living creatures or hit loose enemies and objects when they could be knocked into a player.",
    true
)
register_option_bool(
    "prefer_stomps",
    "Prefer safe stomps",
    "Jump on nearby stompable enemies instead of whipping or throwing when the landing approach is safe.",
    true
)
register_option_bool(
    "protect_shops",
    "Protect shops and friendly NPCs",
    "Do not steal shop items or attack near friendly NPCs and altars.",
    true
)
register_option_bool(
    "restrict_dangerous_pickups",
    "Refuse extremely dangerous items",
    "Do not pick up teleporters, plasma cannons, scepters, clone guns, live explosives, cursed pots, or lava pots.",
    true
)
register_option_bool(
    "protect_houyi_bow",
    "Leave Hou Yi's Bow alone",
    "Never pick up the special bow, so a Hired Hand cannot take it away from the player or quest path.",
    true
)
register_option_bool(
    "carry_equipment_packs",
    "Carry spare equipment (experimental)",
    "Let empty-handed Hired Hands carry nearby packs, a yellow cape, climbing gloves, spring or spike shoes, and paste without equipping them.",
    true
)
register_option_bool(
    "dodge_projectiles",
    "Dodge incoming projectiles",
    "Duck under high shots and jump over low shots when there is time and room.",
    true
)
register_option_bool(
    "faster_reactions",
    "Faster reactions",
    "End idle pauses early and look farther ahead for incoming projectiles and nearby stomp opportunities.",
    true
)
register_option_int(
    "minimum_trust",
    "Minimum trust",
    "Raise live Hired Hand trust to this value (0-3). Higher trust makes them follow more reliably and sleep less.",
    2,
    0,
    3
)
register_option_int(
    "leash_distance",
    "Follow distance",
    "When farther away than this many tiles, discourage movement away from the leader.",
    8,
    4,
    20
)
register_option_bool(
    "debug_log",
    "Debug safety decisions",
    "Write occasional safety decisions to the Overlunky/Playlunky console for testing.",
    false
)

local hooked_hired_hands = {}
local last_debug_frame = {}

local function type_list(names)
    local result = {}
    for _, name in ipairs(names) do
        local entity_type = ENT_TYPE[name]
        if entity_type ~= nil then
            result[#result + 1] = entity_type
        end
    end
    return result
end

local TERRAIN_HAZARDS = type_list({
    "FLOOR_SPIKES",
    "FLOOR_SPIKES_UPSIDEDOWN",
    "FLOOR_JUNGLE_SPEAR_TRAP",
    "FLOOR_BIGSPEAR_TRAP",
    "FLOOR_LION_TRAP",
    "FLOOR_TOTEM_TRAP",
    "FLOOR_ARROW_TRAP",
    "FLOOR_POISONED_ARROW_TRAP",
    "FLOOR_LASER_TRAP",
    "FLOOR_SPARK_TRAP",
    "FLOOR_THORN_VINE",
    "FLOOR_QUICKSAND",
    "FLOOR_TIMED_FORCEFIELD",
    "FLOOR_HORIZONTAL_FORCEFIELD",
    "ACTIVEFLOOR_CRUSH_TRAP",
    "ACTIVEFLOOR_CRUSH_TRAP_LARGE",
    "ACTIVEFLOOR_CRUSHING_ELEVATOR",
    "ACTIVEFLOOR_CHAINED_SPIKEBALL",
    "ACTIVEFLOOR_UNCHAINED_SPIKEBALL",
    "ACTIVEFLOOR_WOODENLOG_TRAP",
    "ACTIVEFLOOR_THINICE",
    "ACTIVEFLOOR_FALLING_PLATFORM",
    "ITEM_LANDMINE",
    "ITEM_SNAP_TRAP",
    "ITEM_SPIKES"
})

local REFUSED_PICKUPS = type_list({
    "ITEM_TELEPORTER",
    "ITEM_TELEPORTER_BACKPACK",
    "ITEM_PLASMACANNON",
    "ITEM_SCEPTER",
    "ITEM_CLONEGUN",
    "ITEM_BOMB",
    "ITEM_PASTEBOMB",
    "ITEM_LANDMINE",
    "ITEM_SNAP_TRAP",
    "ITEM_CURSEDPOT",
    "ITEM_LAVAPOT"
})

local EXPLOSIVE_PACKS = type_list({
    "ITEM_JETPACK",
    "ITEM_HOVERPACK",
    "ITEM_POWERPACK",
    "ITEM_TELEPORTER_BACKPACK"
})

local CARRIABLE_EQUIPMENT = type_list({
    "ITEM_JETPACK",
    "ITEM_HOVERPACK",
    "ITEM_POWERPACK",
    "ITEM_TELEPORTER_BACKPACK",
    "ITEM_CAPE",
    "ITEM_PICKUP_CLIMBINGGLOVES",
    "ITEM_PICKUP_SPRINGSHOES",
    "ITEM_PICKUP_SPIKESHOES",
    "ITEM_PICKUP_PASTE"
})

local RANGED_WEAPONS = type_list({
    "ITEM_WEBGUN",
    "ITEM_SHOTGUN",
    "ITEM_FREEZERAY",
    "ITEM_CROSSBOW",
    "ITEM_HOUYIBOW",
    "ITEM_PLASMACANNON",
    "ITEM_SCEPTER",
    "ITEM_CLONEGUN"
})

local NEVER_USE_WEAPONS = type_list({
    "ITEM_TELEPORTER",
    "ITEM_JETPACK",
    "ITEM_HOVERPACK",
    "ITEM_POWERPACK",
    "ITEM_TELEPORTER_BACKPACK",
    "ITEM_CAPE",
    "ITEM_PICKUP_CLIMBINGGLOVES",
    "ITEM_PICKUP_SPRINGSHOES",
    "ITEM_PICKUP_SPIKESHOES",
    "ITEM_PICKUP_PASTE",
    "ITEM_PLASMACANNON",
    "ITEM_SCEPTER",
    "ITEM_CLONEGUN",
    "ITEM_LAVAPOT",
    "ITEM_CURSEDPOT",
    "ITEM_LANDMINE",
    "ITEM_SNAP_TRAP"
})

local SENSITIVE_OBJECTS = type_list({
    "FLOOR_ALTAR",
    "ACTIVEFLOOR_POWDERKEG",
    "ACTIVEFLOOR_TIMEDPOWDERKEG",
    "ITEM_BOMB",
    "ITEM_PASTEBOMB",
    "ITEM_CURSEDPOT",
    "ITEM_LAVAPOT",
    "ITEM_LANDMINE"
})

local LIVE_BOMBS = type_list({
    "ITEM_BOMB",
    "ITEM_PASTEBOMB"
})

local FRIENDLY_NPCS = type_list({
    "MONS_SHOPKEEPER",
    "MONS_MERCHANT",
    "MONS_YANG",
    "MONS_SISTER_PARSLEY",
    "MONS_SISTER_PARSNIP",
    "MONS_SISTER_PARMESAN",
    "MONS_OLD_HUNTER",
    "MONS_MADAMETUSK",
    "MONS_BODYGUARD",
    "MONS_STORAGEGUY",
    "MONS_PET_DOG",
    "MONS_PET_CAT",
    "MONS_PET_HAMSTER"
})

local PROJECTILES = type_list({
    "ITEM_WOODEN_ARROW",
    "ITEM_METAL_ARROW",
    "ITEM_LIGHT_ARROW",
    "ITEM_BULLET",
    "ITEM_FREEZERAYSHOT",
    "ITEM_PLASMACANNON_SHOT",
    "ITEM_LASERTRAP_SHOT",
    "ITEM_LAMASSU_LASER_SHOT",
    "ITEM_UFO_LASER_SHOT",
    "ITEM_SORCERESS_DAGGER_SHOT",
    "ITEM_TIAMAT_SHOT",
    "ITEM_FIREBALL",
    "ITEM_HUNDUN_FIREBALL",
    "ITEM_ACIDSPIT",
    "ITEM_INKSPIT",
    "ITEM_TOTEM_SPEAR",
    "ITEM_LION_SPEAR",
    "ITEM_JUNGLE_SPEAR_DAMAGING"
})

local function to_set(values)
    local result = {}
    for _, value in ipairs(values) do
        result[value] = true
    end
    return result
end

local REFUSED_PICKUP_SET = to_set(REFUSED_PICKUPS)
local EXPLOSIVE_PACK_SET = to_set(EXPLOSIVE_PACKS)
local CARRIABLE_EQUIPMENT_SET = to_set(CARRIABLE_EQUIPMENT)
local RANGED_WEAPON_SET = to_set(RANGED_WEAPONS)
local NEVER_USE_WEAPON_SET = to_set(NEVER_USE_WEAPONS)
local FRIENDLY_NPC_SET = to_set(FRIENDLY_NPCS)
local HOUYI_BOW_TYPE = ENT_TYPE.ITEM_HOUYIBOW

local function debug_decision(hired_hand, reason)
    if not options.debug_log then
        return
    end

    local frame = get_frame()
    local previous = last_debug_frame[hired_hand.uid] or -1000
    if frame - previous >= 60 then
        last_debug_frame[hired_hand.uid] = frame
        console_print(string.format("Hired Hand %d chose safety: %s", hired_hand.uid, reason))
    end
end

local function get_world_position(entity)
    local position = entity:get_absolute_position()
    return position.x, position.y
end

local function same_layer(a, b)
    return a.layer == b.layer
end

local function nearest_human_leader(hired_hand)
    local current = hired_hand
    local visited = {}

    -- Follow the vanilla companion chain first.
    for _ = 1, 10 do
        if current.linked_companion_parent == nil or current.linked_companion_parent < 0 then
            break
        end
        if visited[current.uid] then
            break
        end
        visited[current.uid] = true

        local parent = get_entity(current.linked_companion_parent)
        if parent == nil then
            break
        end
        if parent.type.id ~= ENT_TYPE.CHAR_HIREDHAND then
            return parent
        end
        current = parent
    end

    -- Fall back to the nearest actual player on the same layer.
    local hx, hy = get_world_position(hired_hand)
    local best = nil
    local best_distance_squared = math.huge
    for _, player in ipairs(players) do
        if player.uid ~= hired_hand.uid and same_layer(hired_hand, player) then
            local px, py = get_world_position(player)
            local dx = px - hx
            local dy = py - hy
            local distance_squared = dx * dx + dy * dy
            if distance_squared < best_distance_squared then
                best = player
                best_distance_squared = distance_squared
            end
        end
    end
    return best
end

local function entities_near(types, x, y, layer, radius)
    if #types == 0 then
        return {}
    end
    return get_entities_at(types, 0, x, y, layer, radius)
end

local function has_terrain_hazard(x, y, layer)
    return #entities_near(TERRAIN_HAZARDS, x, y, layer, 0.58) > 0
end

local function has_lava(x, y, layer)
    local _, lava = get_liquids_at(x, y, layer)
    return lava ~= nil and lava > 0
end

local function has_support_within(x, y, layer, maximum_drop)
    local drop = 0.65
    while drop <= maximum_drop + 0.85 do
        local supports = get_entities_at(
            0,
            MASK.FLOOR + MASK.ACTIVEFLOOR,
            x,
            y - drop,
            layer,
            0.38
        )
        if #supports > 0 then
            return true
        end
        drop = drop + 0.45
    end
    return false
end

local function movement_risk(hired_hand, direction)
    local x, y = get_world_position(hired_hand)
    local probe_x = x + direction * 0.72

    if has_lava(probe_x, y - 0.55, hired_hand.layer)
        or has_lava(probe_x, y - 1.05, hired_hand.layer) then
        return "lava"
    end

    if has_terrain_hazard(probe_x, y - 0.60, hired_hand.layer)
        or has_terrain_hazard(probe_x, y + 0.20, hired_hand.layer) then
        return "trap"
    end

    local grounded = hired_hand.standing_on_uid >= 0
        and (hired_hand.state == CHAR_STATE.STANDING
            or hired_hand.state == CHAR_STATE.DUCKING
            or hired_hand.state == CHAR_STATE.PUSHING)

    if grounded and not has_support_within(probe_x, y, hired_hand.layer, options.safe_drop) then
        return "deep drop"
    end

    return nil
end

local function clear_horizontal(buttons)
    buttons = clr_mask(buttons, INPUTS.LEFT)
    buttons = clr_mask(buttons, INPUTS.RIGHT)
    return buttons
end

local function set_horizontal(buttons, direction)
    buttons = clear_horizontal(buttons)
    if direction < 0 then
        return set_mask(buttons, INPUTS.LEFT)
    end
    return set_mask(buttons, INPUTS.RIGHT)
end

local function desired_horizontal(buttons)
    local left = test_mask(buttons, INPUTS.LEFT)
    local right = test_mask(buttons, INPUTS.RIGHT)
    if left == right then
        return 0
    end
    return left and -1 or 1
end

local function nearby_live_bomb(hired_hand, x, y)
    local closest = nil
    local closest_distance = math.huge
    local explosive_uids = entities_near(LIVE_BOMBS, x, y, hired_hand.layer, 3.1)
    for _, uid in ipairs(entities_near(EXPLOSIVE_PACKS, x, y, hired_hand.layer, 3.1)) do
        explosive_uids[#explosive_uids + 1] = uid
    end

    for _, uid in ipairs(explosive_uids) do
        local bomb = get_entity(uid)
        local dangerous_pack = bomb ~= nil
            and EXPLOSIVE_PACK_SET[bomb.type.id]
            and (bomb.explosion_trigger == true
                or (bomb.explosion_timer ~= nil and bomb.explosion_timer > 0)
                or (bomb.onfire_effect_timer ~= nil and bomb.onfire_effect_timer > 0))
        if bomb ~= nil
            and bomb.overlay ~= hired_hand
            and (not EXPLOSIVE_PACK_SET[bomb.type.id] or dangerous_pack) then
            local bx, by = get_world_position(bomb)
            local dx = x - bx
            local dy = y - by
            local distance_squared = dx * dx + dy * dy
            if distance_squared < closest_distance then
                closest = bomb
                closest_distance = distance_squared
            end
        end
    end
    return closest
end

local function apply_bomb_escape(hired_hand, buttons)
    local x, y = get_world_position(hired_hand)
    local bomb = nearby_live_bomb(hired_hand, x, y)
    if bomb == nil then
        return buttons, false
    end

    local bx = bomb:get_absolute_position().x
    local direction = x < bx and -1 or 1
    if movement_risk(hired_hand, direction) == nil then
        buttons = set_horizontal(buttons, direction)
        buttons = clr_mask(buttons, INPUTS.WHIP)
        buttons = clr_mask(buttons, INPUTS.DOWN)
        debug_decision(hired_hand, "moving away from a live bomb")
        return buttons, true
    end

    buttons = clear_horizontal(buttons)
    buttons = clr_mask(buttons, INPUTS.WHIP)
    debug_decision(hired_hand, "not running into a second hazard while near a bomb")
    return buttons, true
end

local function projectile_response(hired_hand, x, y)
    local scan_radius = options.faster_reactions and 7.5 or 5.5
    local reaction_frames = options.faster_reactions and 50 or 32
    for _, uid in ipairs(entities_near(PROJECTILES, x, y, hired_hand.layer, scan_radius)) do
        local projectile = get_entity(uid)
        if projectile ~= nil and projectile.uid ~= hired_hand.holding_uid then
            local px, py = get_world_position(projectile)
            local velocity = projectile:get_absolute_velocity()
            local dx = x - px
            local horizontal_speed = velocity.x

            if math.abs(horizontal_speed) > 0.04 and dx * horizontal_speed > 0 then
                local frames_until_crossing = math.abs(dx / horizontal_speed)
                local predicted_y = py + velocity.y * frames_until_crossing
                local vertical_difference = predicted_y - y
                if frames_until_crossing <= reaction_frames and math.abs(vertical_difference) <= 0.75 then
                    if vertical_difference > 0.08 then
                        return "duck"
                    end
                    if hired_hand.standing_on_uid >= 0 and hired_hand:can_jump() then
                        return "jump"
                    end
                end
            end
        end
    end
    return nil
end

local function apply_projectile_dodge(hired_hand, buttons)
    if not options.dodge_projectiles then
        return buttons, false
    end

    local x, y = get_world_position(hired_hand)
    local response = projectile_response(hired_hand, x, y)
    if response == "duck" then
        buttons = clear_horizontal(buttons)
        buttons = clr_mask(buttons, INPUTS.JUMP)
        buttons = clr_mask(buttons, INPUTS.WHIP)
        buttons = set_mask(buttons, INPUTS.DOWN)
        debug_decision(hired_hand, "ducking an incoming projectile")
        return buttons, true
    elseif response == "jump" and movement_risk(hired_hand, 1) ~= "lava"
        and movement_risk(hired_hand, -1) ~= "lava" then
        buttons = clear_horizontal(buttons)
        buttons = clr_mask(buttons, INPUTS.DOWN)
        buttons = clr_mask(buttons, INPUTS.WHIP)
        buttons = set_mask(buttons, INPUTS.JUMP)
        debug_decision(hired_hand, "jumping an incoming projectile")
        return buttons, true
    end
    return buttons, false
end

local function protected_characters(hired_hand)
    local result = {}
    local seen = {[hired_hand.uid] = true}

    for _, player in ipairs(players) do
        if not seen[player.uid] then
            seen[player.uid] = true
            result[#result + 1] = player
        end
    end
    for _, uid in ipairs(get_entities_by_type(ENT_TYPE.CHAR_HIREDHAND)) do
        if not seen[uid] then
            local character = get_entity(uid)
            if character ~= nil then
                seen[uid] = true
                result[#result + 1] = character
            end
        end
    end
    return result
end

local function protected_character_in_line(hired_hand, maximum_range, vertical_clearance)
    local hx, hy = get_world_position(hired_hand)
    local facing_left = test_flag(hired_hand.flags, ENT_FLAG.FACING_LEFT)
    local facing_direction = facing_left and -1 or 1

    for _, character in ipairs(protected_characters(hired_hand)) do
        if same_layer(hired_hand, character) then
            local cx, cy = get_world_position(character)
            local forward_distance = (cx - hx) * facing_direction
            if forward_distance > 0
                and forward_distance <= maximum_range
                and math.abs(cy - hy) <= vertical_clearance then
                return true
            end
        end
    end
    return false
end

local function protected_character_near(hired_hand, x, y, radius)
    local radius_squared = radius * radius
    for _, character in ipairs(protected_characters(hired_hand)) do
        if same_layer(hired_hand, character) then
            local cx, cy = get_world_position(character)
            local dx = cx - x
            local dy = cy - y
            if dx * dx + dy * dy <= radius_squared then
                return true
            end
        end
    end
    return false
end

local function held_item(hired_hand)
    if hired_hand.holding_uid < 0 then
        return nil
    end
    return get_entity(hired_hand.holding_uid)
end

local function equipment_is_safe_cargo(equipment)
    if equipment == nil or not CARRIABLE_EQUIPMENT_SET[equipment.type.id] then
        return false
    end
    if test_flag(equipment.flags, ENT_FLAG.SHOP_ITEM) then
        return false
    end
    if equipment.onfire_effect_timer ~= nil and equipment.onfire_effect_timer > 0 then
        return false
    end
    if EXPLOSIVE_PACK_SET[equipment.type.id]
        and (equipment.explosion_trigger == true
            or (equipment.explosion_timer ~= nil and equipment.explosion_timer > 0)) then
        return false
    end
    return true
end

local function carry_equipment_by_hand(hired_hand, equipment)
    if hired_hand.holding_uid >= 0 or not equipment_is_safe_cargo(equipment) then
        return false
    end

    -- Wearables and pickup powerups normally equip or disappear into inventory.
    -- A direct attachment keeps the physical entity inert and hand-carried.
    attach_entity(hired_hand.uid, equipment.uid)
    hired_hand.holding_uid = equipment.uid
    equipment.x = 0.38
    equipment.y = 0.05
    equipment.special_offsetx = 0.38
    equipment.special_offsety = 0.05
    equipment.velocityx = 0
    equipment.velocityy = 0
    debug_decision(hired_hand, "carrying spare equipment without equipping it")
    return true
end

local function convert_worn_equipment_to_cargo(hired_hand)
    if not options.carry_equipment_packs or hired_hand.holding_uid >= 0 then
        return false
    end

    local equipment_uid = worn_backitem(hired_hand.uid)
    if equipment_uid == nil or equipment_uid < 0 then
        return false
    end
    local equipment = get_entity(equipment_uid)
    if equipment == nil or not CARRIABLE_EQUIPMENT_SET[equipment.type.id] then
        return false
    end

    unequip_backitem(hired_hand.uid)
    equipment = get_entity(equipment_uid)
    if equipment ~= nil and carry_equipment_by_hand(hired_hand, equipment) then
        debug_decision(hired_hand, "moving worn equipment into the hands as inert cargo")
        return true
    end
    return false
end

local function try_carry_nearby_equipment(hired_hand)
    if not options.carry_equipment_packs or hired_hand.holding_uid >= 0 then
        return false
    end
    if convert_worn_equipment_to_cargo(hired_hand) then
        return true
    end

    local hx, hy = get_world_position(hired_hand)
    local closest = nil
    local closest_distance_squared = math.huge
    for _, uid in ipairs(entities_near(CARRIABLE_EQUIPMENT, hx, hy, hired_hand.layer, 1.35)) do
        local equipment = get_entity(uid)
        if equipment ~= nil
            and equipment.overlay == nil
            and equipment_is_safe_cargo(equipment) then
            local px, py = get_world_position(equipment)
            local dx = px - hx
            local dy = py - hy
            local distance_squared = dx * dx + dy * dy
            if distance_squared < closest_distance_squared then
                closest = equipment
                closest_distance_squared = distance_squared
            end
        end
    end

    if closest ~= nil then
        return carry_equipment_by_hand(hired_hand, closest)
    end
    return false
end

local function drop_unsafe_carried_equipment(hired_hand)
    local held = held_item(hired_hand)
    if held == nil
        or not CARRIABLE_EQUIPMENT_SET[held.type.id]
        or equipment_is_safe_cargo(held) then
        return false
    end

    drop(hired_hand.uid, held.uid)
    debug_decision(hired_hand, "dropping burning carried equipment")
    return true
end

local function entity_matches_mask(entity, mask)
    return entity ~= nil
        and entity.type ~= nil
        and entity.type.search_flags ~= nil
        and test_mask(entity.type.search_flags, mask)
end

local function held_creature_is_dangerous(hired_hand, held)
    if held == nil or not options.prevent_collateral_damage then
        return false
    end
    if not entity_matches_mask(held, MASK.MONSTER + MASK.MOUNT) then
        return false
    end

    local hx, hy = get_world_position(hired_hand)
    return protected_character_near(hired_hand, hx, hy, 8.0)
end

local function knockable_target_near_player(hired_hand, maximum_range)
    if not options.prevent_collateral_damage then
        return false
    end

    local hx, hy = get_world_position(hired_hand)
    local facing_left = test_flag(hired_hand.flags, ENT_FLAG.FACING_LEFT)
    local facing_direction = facing_left and -1 or 1
    local masks = MASK.MONSTER + MASK.MOUNT + MASK.ITEM
    local scan_x = hx + facing_direction * maximum_range * 0.5
    local scan_radius = maximum_range * 0.5 + 0.8

    for _, uid in ipairs(get_entities_at(0, masks, scan_x, hy, hired_hand.layer, scan_radius)) do
        if uid ~= hired_hand.uid and uid ~= hired_hand.holding_uid then
            local target = get_entity(uid)
            if target ~= nil then
                local tx, ty = get_world_position(target)
                local forward_distance = (tx - hx) * facing_direction
                local is_knockable = entity_matches_mask(target, MASK.MONSTER + MASK.MOUNT)
                    or test_flag(target.flags, ENT_FLAG.THROWABLE_OR_KNOCKBACKABLE)
                if is_knockable
                    and forward_distance > 0
                    and forward_distance <= maximum_range
                    and math.abs(ty - hy) <= 1.75
                    and protected_character_near(hired_hand, tx, ty, 2.75) then
                    return true
                end
            end
        end
    end
    return false
end

local function attack_is_unsafe(hired_hand)
    local held = held_item(hired_hand)
    if held ~= nil and NEVER_USE_WEAPON_SET[held.type.id] then
        return true, "refusing to use an indiscriminate weapon"
    end

    if held_creature_is_dangerous(hired_hand, held) then
        return true, "not throwing a creature anywhere near a protected character"
    end

    local range = 3.0
    local vertical_clearance = 1.15
    if held ~= nil and RANGED_WEAPON_SET[held.type.id] then
        range = 11.0
        vertical_clearance = 1.35
    elseif held ~= nil then
        range = 9.0
        vertical_clearance = 2.0
    end

    if options.prevent_friendly_fire
        and protected_character_in_line(hired_hand, range, vertical_clearance) then
        return true, "friendly character in attack line"
    end

    if knockable_target_near_player(hired_hand, range) then
        return true, "an enemy or loose object could be knocked into a protected character"
    end

    local x, y = get_world_position(hired_hand)
    if options.protect_shops and #entities_near(FRIENDLY_NPCS, x, y, hired_hand.layer, 3.5) > 0 then
        return true, "friendly NPC nearby"
    end
    if #entities_near(SENSITIVE_OBJECTS, x, y, hired_hand.layer, 2.4) > 0 then
        return true, "fragile or explosive object nearby"
    end

    return false, nil
end

local function nearest_stomp_target(hired_hand)
    if not options.prefer_stomps then
        return nil
    end

    local hx, hy = get_world_position(hired_hand)
    local scan_radius = options.faster_reactions and 2.8 or 2.2
    local best = nil
    local best_distance_squared = math.huge
    for _, uid in ipairs(get_entities_at(0, MASK.MONSTER, hx, hy, hired_hand.layer, scan_radius)) do
        local target = get_entity(uid)
        if target ~= nil
            and not FRIENDLY_NPC_SET[target.type.id]
            and not test_flag(target.flags, ENT_FLAG.DEAD)
            and test_flag(target.flags, ENT_FLAG.CAN_BE_STOMPED) then
            local tx, ty = get_world_position(target)
            local dx = tx - hx
            local dy = ty - hy
            local distance_squared = dx * dx + dy * dy
            if dy >= -2.2 and dy <= 0.45 and distance_squared < best_distance_squared then
                best = target
                best_distance_squared = distance_squared
            end
        end
    end
    return best
end

local function apply_stomp_bias(hired_hand, buttons)
    local target = nearest_stomp_target(hired_hand)
    if target == nil then
        return buttons
    end

    local hx, hy = get_world_position(hired_hand)
    local tx, ty = get_world_position(target)
    local dx = tx - hx
    local dy = ty - hy
    local airborne = hired_hand.state == CHAR_STATE.JUMPING
        or hired_hand.state == CHAR_STATE.FALLING

    if airborne and dy < -0.25 and math.abs(dx) <= 0.95 then
        buttons = clr_mask(buttons, INPUTS.WHIP)
        buttons = clr_mask(buttons, INPUTS.DOWN)
        debug_decision(hired_hand, "finishing a safe stomp instead of attacking")
        return buttons
    end

    if hired_hand.standing_on_uid >= 0 and math.abs(dx) >= 0.20 and math.abs(dx) <= 2.1 then
        local direction = dx < 0 and -1 or 1
        if hired_hand:can_jump() and movement_risk(hired_hand, direction) == nil then
            buttons = set_horizontal(buttons, direction)
            buttons = set_mask(buttons, INPUTS.JUMP)
            buttons = clr_mask(buttons, INPUTS.WHIP)
            buttons = clr_mask(buttons, INPUTS.DOWN)
            debug_decision(hired_hand, "choosing a stomp over a riskier attack")
        end
    end
    return buttons
end

local function apply_attack_safety(hired_hand, buttons)
    if not test_mask(buttons, INPUTS.WHIP) then
        return buttons
    end

    local unsafe, reason = attack_is_unsafe(hired_hand)
    if unsafe then
        debug_decision(hired_hand, reason)
        return clr_mask(buttons, INPUTS.WHIP)
    end
    return buttons
end

local function apply_leash(hired_hand, buttons)
    local leader = nearest_human_leader(hired_hand)
    if leader == nil or not same_layer(hired_hand, leader) then
        return buttons
    end

    local hx, hy = get_world_position(hired_hand)
    local lx, ly = get_world_position(leader)
    local dx = lx - hx
    local dy = ly - hy
    if math.abs(dx) <= options.leash_distance or math.abs(dy) > 3.0 then
        return buttons
    end

    local toward_leader = dx < 0 and -1 or 1
    local desired = desired_horizontal(buttons)
    if desired ~= 0 and desired ~= toward_leader then
        buttons = clear_horizontal(buttons)
        debug_decision(hired_hand, "not wandering farther from the leader")
    end

    if hired_hand.standing_on_uid >= 0 and movement_risk(hired_hand, toward_leader) == nil then
        buttons = set_horizontal(buttons, toward_leader)
    end
    return buttons
end

local function apply_terrain_safety(hired_hand, buttons)
    if not options.avoid_terrain then
        return buttons
    end

    local desired = desired_horizontal(buttons)
    if desired == 0 then
        return buttons
    end

    local risk = movement_risk(hired_hand, desired)
    if risk == nil then
        return buttons
    end

    buttons = clear_horizontal(buttons)
    buttons = clr_mask(buttons, INPUTS.JUMP)

    local leader = nearest_human_leader(hired_hand)
    if leader ~= nil and same_layer(hired_hand, leader) then
        local hx = hired_hand:get_absolute_position().x
        local lx = leader:get_absolute_position().x
        local toward_leader = lx < hx and -1 or 1
        if toward_leader ~= desired and movement_risk(hired_hand, toward_leader) == nil then
            buttons = set_horizontal(buttons, toward_leader)
        end
    end

    debug_decision(hired_hand, "avoiding " .. risk)
    return buttons
end

local function cautious_process_input(hired_hand)
    if hired_hand.input == nil or hired_hand.health <= 0 then
        return false
    end
    if hired_hand.stun_timer > 0
        or hired_hand.state == CHAR_STATE.STUNNED
        or hired_hand.state == CHAR_STATE.DYING
        or hired_hand.state == CHAR_STATE.ENTERING
        or hired_hand.state == CHAR_STATE.EXITING
        or hired_hand.state == CHAR_STATE.LOADING then
        return false
    end

    if hired_hand.ai ~= nil and hired_hand.ai.trust < options.minimum_trust then
        hired_hand.ai.trust = options.minimum_trust
    end
    if options.faster_reactions
        and hired_hand.ai ~= nil
        and hired_hand.ai.walk_pause_timer ~= nil
        and hired_hand.ai.walk_pause_timer < 0 then
        hired_hand.ai.walk_pause_timer = 0
    end

    drop_unsafe_carried_equipment(hired_hand)
    try_carry_nearby_equipment(hired_hand)

    local buttons = hired_hand.input.buttons_gameplay
    buttons = apply_attack_safety(hired_hand, buttons)

    local emergency
    buttons, emergency = apply_bomb_escape(hired_hand, buttons)
    if not emergency then
        buttons, emergency = apply_projectile_dodge(hired_hand, buttons)
    end
    if not emergency then
        buttons = apply_stomp_bias(hired_hand, buttons)
        buttons = apply_leash(hired_hand, buttons)
        buttons = apply_terrain_safety(hired_hand, buttons)
    end

    hired_hand.input.buttons_gameplay = buttons
    return false
end

local function cautious_pick_up(hired_hand, item)
    if item == nil then
        return false
    end

    if options.protect_shops and test_flag(item.flags, ENT_FLAG.SHOP_ITEM) then
        debug_decision(hired_hand, "leaving an unpaid shop item alone")
        return true
    end


    if options.protect_houyi_bow and item.type.id == HOUYI_BOW_TYPE then
        debug_decision(hired_hand, "leaving Hou Yi's Bow for the player")
        return true
    end

    if options.carry_equipment_packs and CARRIABLE_EQUIPMENT_SET[item.type.id] then
        if equipment_is_safe_cargo(item) and hired_hand.holding_uid < 0 then
            carry_equipment_by_hand(hired_hand, item)
            return true
        end
        debug_decision(hired_hand, "refusing unsafe spare equipment or keeping the current cargo")
        return true
    end

    if options.restrict_dangerous_pickups and REFUSED_PICKUP_SET[item.type.id] then
        debug_decision(hired_hand, "refusing a dangerous pickup")
        return true
    end
    return false
end


local function cautious_post_pick_up(hired_hand, item)
    if item ~= nil
        and options.carry_equipment_packs
        and CARRIABLE_EQUIPMENT_SET[item.type.id]
        and hired_hand.holding_uid < 0 then
        convert_worn_equipment_to_cargo(hired_hand)
    end
end

local function hook_hired_hand(entity)
    if entity == nil or hooked_hired_hands[entity.uid] then
        return
    end
    hooked_hired_hands[entity.uid] = true
    entity:set_pre_process_input(cautious_process_input)
    entity:set_pre_pick_up(cautious_pick_up)
    entity:set_post_pick_up(cautious_post_pick_up)
end

set_post_entity_spawn(function(entity)
    hook_hired_hand(entity)
end, SPAWN_TYPE.ANY, MASK.PLAYER, ENT_TYPE.CHAR_HIREDHAND)

local function hook_existing_hired_hands()
    for _, uid in ipairs(get_entities_by_type(ENT_TYPE.CHAR_HIREDHAND)) do
        hook_hired_hand(get_entity(uid))
    end
end

set_callback(function()
    hooked_hired_hands = {}
    last_debug_frame = {}
end, ON.PRE_LEVEL_GENERATION)

set_callback(hook_existing_hired_hands, ON.LEVEL)

-- Also supports enabling/reloading the script in the middle of a level.
hook_existing_hired_hands()
