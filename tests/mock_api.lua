-- Minimal Overlunky/Playlunky API double for exercising main.lua outside the game.
-- Run with a Lua 5.3+ interpreter from the repository root.

local type_names = {}
local next_type = 100
ENT_TYPE = setmetatable({}, {
    __index = function(table_value, name)
        next_type = next_type + 1
        rawset(table_value, name, next_type)
        type_names[next_type] = name
        return next_type
    end
})

MASK = {PLAYER = 1, MOUNT = 2, MONSTER = 4, ITEM = 8, ACTIVEFLOOR = 128, FLOOR = 256}
INPUTS = {
    JUMP = 1,
    WHIP = 2,
    BOMB = 4,
    ROPE = 8,
    RUN = 16,
    DOOR = 32,
    LEFT = 256,
    RIGHT = 512,
    UP = 1024,
    DOWN = 2048
}
CHAR_STATE = {
    STANDING = 1,
    DUCKING = 5,
    PUSHING = 7,
    JUMPING = 8,
    FALLING = 9,
    STUNNED = 18,
    ENTERING = 19,
    LOADING = 20,
    EXITING = 21,
    DYING = 22
}
ENT_FLAG = {
    CAN_BE_STOMPED = 15,
    FACING_LEFT = 17,
    THROWABLE_OR_KNOCKBACKABLE = 7,
    SHOP_ITEM = 23,
    DEAD = 29
}
SPAWN_TYPE = {ANY = 0}
ON = {PRE_LEVEL_GENERATION = 1, LEVEL = 2, PRE_LOAD_SCREEN = 3, POST_LEVEL_GENERATION = 4}
SCREEN = {LEVEL = 12, TRANSITION = 13, CAMP = 11, DEATH = 14}
state = {screen = SCREEN.LEVEL, screen_next = SCREEN.TRANSITION}

options = {}
players = {}

local spawn_callbacks = {}
local function spawn_callback(entity)
    for _, hook in ipairs(spawn_callbacks) do
        local matches_type = #hook.types == 0
        for _, entity_type in ipairs(hook.types) do
            if entity.type.id == entity_type then
                matches_type = true
                break
            end
        end
        if matches_type and entity.type.search_flags & hook.mask ~= 0 then
            hook.callback(entity)
        end
    end
end
local callbacks = {}
local entities = {}
local scenario = {support = true, lava = false}
local frame = 1

function register_option_bool(name, _, _, value)
    options[name] = value
end

function register_option_int(name, _, _, value)
    options[name] = value
end

function set_post_entity_spawn(callback, _, mask, ...)
    spawn_callbacks[#spawn_callbacks + 1] = {callback = callback, mask = mask, types = {...}}
end

function set_callback(callback, event)
    callbacks[event] = callback
end

function get_frame()
    return frame
end

function console_print(_) end

function test_mask(flags, mask)
    return flags & mask ~= 0
end

function set_mask(flags, mask)
    return flags | mask
end

function clr_mask(flags, mask)
    return flags & (~mask)
end

function test_flag(flags, bit)
    return flags & (1 << (bit - 1)) ~= 0
end

function get_entity(uid)
    return entities[uid]
end

function attach_entity(overlay_uid, attachee_uid)
    local overlay = entities[overlay_uid]
    local attachee = entities[attachee_uid]
    assert(overlay ~= nil and attachee ~= nil, "attach_entity received an invalid uid")
    local position = attachee:get_absolute_position()
    local overlay_position = overlay:get_absolute_position()
    attachee.overlay = overlay
    attachee.x = position.x - overlay_position.x
    attachee.y = position.y - overlay_position.y
end

function worn_backitem(who_uid)
    local wearer = entities[who_uid]
    return wearer ~= nil and (wearer.worn_backitem_uid or -1) or -1
end

function unequip_backitem(who_uid)
    local wearer = entities[who_uid]
    if wearer == nil or wearer.worn_backitem_uid == nil or wearer.worn_backitem_uid < 0 then
        return
    end
    local pack = entities[wearer.worn_backitem_uid]
    if pack ~= nil then
        local position = pack:get_absolute_position()
        pack.overlay = nil
        pack.x = position.x
        pack.y = position.y
    end
    wearer.worn_backitem_uid = -1
end

function drop(who_uid, what_uid)
    local carrier = entities[who_uid]
    if carrier == nil or carrier.holding_uid ~= what_uid then
        return
    end
    local item = entities[what_uid]
    if item ~= nil then
        local position = item:get_absolute_position()
        item.overlay = nil
        item.x = position.x
        item.y = position.y
    end
    carrier.holding_uid = -1
end

function get_entities_by_type(...)
    local entity_types = {...}
    local result = {}
    for uid, entity in pairs(entities) do
        for _, entity_type in ipairs(entity_types) do
            if entity.type.id == entity_type then
                result[#result + 1] = uid
                break
            end
        end
    end
    return result
end

local function requested_type(entity_types, entity)
    if type(entity_types) ~= "table" then
        return false
    end
    for _, entity_type in ipairs(entity_types) do
        if entity.type.id == entity_type then
            return true
        end
    end
    return false
end

function get_entities_at(entity_types, mask, x, y, layer, radius)
    local floor_mask = MASK.FLOOR | MASK.ACTIVEFLOOR
    if entity_types == 0 and mask & floor_mask ~= 0 then
        if scenario.support then
            return {99999}
        end
        return {}
    end

    local result = {}
    for uid, entity in pairs(entities) do
        local type_matches = requested_type(entity_types, entity)
            or (entity_types == 0 and mask & entity.type.search_flags ~= 0)
        if type_matches and entity.layer == layer then
            local dx = entity.x - x
            local dy = entity.y - y
            if dx * dx + dy * dy <= radius * radius then
                result[#result + 1] = uid
            end
        end
    end
    return result
end

function get_liquids_at(_, _, _)
    return 0, scenario.lava and 1 or 0
end

local entity_methods = {}

function entity_methods:get_absolute_position()
    if self.overlay ~= nil then
        local parent = self.overlay:get_absolute_position()
        return {x = parent.x + self.x, y = parent.y + self.y}
    end
    return {x = self.x, y = self.y}
end

function entity_methods:get_absolute_velocity()
    return {x = self.velocityx or 0, y = self.velocityy or 0}
end

function entity_methods:can_jump()
    return true
end

function entity_methods:detach(check_autokill)
    assert(check_autokill == false, "cargo detach must preserve the item")
    local position = self:get_absolute_position()
    self.overlay = nil
    self.x = position.x
    self.y = position.y
end

function entity_methods:set_pre_process_input(callback)
    self.process_input_callback = callback
end

function entity_methods:set_pre_pick_up(callback)
    self.pick_up_callback = callback
end

function entity_methods:set_post_pick_up(callback)
    self.post_pick_up_callback = callback
end

function entity_methods:set_post_update_state_machine(callback)
    self.post_update_callback = callback
end

function entity_methods:set_pre_on_collision2(callback)
    self.collision_callback = callback
end

function entity_methods:get_metadata()
    return self.metadata or 0
end

function entity_methods:apply_metadata(metadata)
    self.metadata = metadata
end

local function new_entity(uid, type_name, x, y)
    local search_flags = MASK.ITEM
    if type_name:sub(1, 5) == "CHAR_" then
        search_flags = MASK.PLAYER
    elseif type_name:sub(1, 5) == "MONS_" then
        search_flags = MASK.MONSTER
    elseif type_name:sub(1, 6) == "MOUNT_" then
        search_flags = MASK.MOUNT
    end
    local flags = 1 << (ENT_FLAG.THROWABLE_OR_KNOCKBACKABLE - 1)
    if search_flags == MASK.MONSTER then
        flags = flags | (1 << (ENT_FLAG.CAN_BE_STOMPED - 1))
    end
    local entity = setmetatable({
        uid = uid,
        type = {id = ENT_TYPE[type_name], search_flags = search_flags},
        x = x or 0,
        y = y or 0,
        layer = 0,
        flags = flags,
        health = 4,
        stun_timer = 0,
        state = CHAR_STATE.STANDING,
        standing_on_uid = 99999,
        holding_uid = -1,
        linked_companion_parent = -1,
        input = {buttons_gameplay = 0},
        ai = {trust = 0, walk_pause_timer = 1, target = nil, target_uid = -1},
        velocityx = 0,
        velocityy = 0,
        overlay = nil,
        special_offsetx = 0,
        special_offsety = 0,
        explosion_trigger = false,
        explosion_timer = 0,
        onfire_effect_timer = 0,
        worn_backitem_uid = -1
    }, {__index = entity_methods})
    entities[uid] = entity
    spawn_callback(entity)
    return entity
end

local function reset_world()
    entities = {}
    players = {}
    scenario.support = true
    scenario.lava = false
    frame = frame + 100
    state.screen = SCREEN.LEVEL
    state.screen_next = SCREEN.TRANSITION
    if callbacks[ON.PRE_LEVEL_GENERATION] ~= nil then
        callbacks[ON.PRE_LEVEL_GENERATION]()
    end
end

local next_spawn_uid = 1000
local spawned_cargo_count = 0
function spawn_entity(entity_type, x, y, layer, velocityx, velocityy)
    next_spawn_uid = next_spawn_uid + 1
    local entity = new_entity(next_spawn_uid, type_names[entity_type], x, y)
    entity.layer = layer
    entity.velocityx = velocityx
    entity.velocityy = velocityy
    spawned_cargo_count = spawned_cargo_count + 1
    return entity.uid
end

local function new_party(leader_uid, hired_hand_uid)
    local leader = new_entity(leader_uid or 1, "CHAR_ANA_SPELUNKY", 2, 0)
    local hired_hand = new_entity(hired_hand_uid or 2, "CHAR_HIREDHAND", 0, 0)
    hired_hand.linked_companion_parent = leader.uid
    players = {leader}
    spawn_callback(hired_hand)
    return leader, hired_hand
end

local function assert_mask(value, mask, expected, label)
    local actual = test_mask(value, mask)
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

-- Also supports the original workspace layout with CautiousHiredHands/main.lua.
local mod_path = "main.lua"
local mod_file = io.open(mod_path, "r")
if mod_file ~= nil then
    mod_file:close()
else
    mod_path = "CautiousHiredHands/main.lua"
end
local existing_hand = new_entity(10, "CHAR_HIREDHAND", 0, 0)
local existing_pickup = new_entity(11, "ITEM_PICKUP_ANKH", 0.5, 0)
dofile(mod_path)
assert(existing_hand.process_input_callback ~= nil, "existing HH was not hooked on script load")
assert(existing_pickup.collision_callback ~= nil, "existing pickup was not hooked on script load")

-- Friendly-fire prevention.
reset_world()
local leader, hired_hand = new_party()
leader.x = 1
hired_hand.input.buttons_gameplay = INPUTS.WHIP
hired_hand.process_input_callback(hired_hand)
assert_mask(hired_hand.input.buttons_gameplay, INPUTS.WHIP, false, "friendly fire")

-- Safe ground movement remains unchanged.
reset_world()
_, hired_hand = new_party()
hired_hand.input.buttons_gameplay = INPUTS.RIGHT
hired_hand.process_input_callback(hired_hand)
assert_mask(hired_hand.input.buttons_gameplay, INPUTS.RIGHT, true, "safe movement")

-- A deep unsupported drop is rejected.
reset_world()
_, hired_hand = new_party()
scenario.support = false
hired_hand.input.buttons_gameplay = INPUTS.RIGHT | INPUTS.JUMP
hired_hand.process_input_callback(hired_hand)
assert_mask(hired_hand.input.buttons_gameplay, INPUTS.RIGHT, false, "deep drop horizontal")
assert_mask(hired_hand.input.buttons_gameplay, INPUTS.JUMP, false, "deep drop jump")

-- Live bombs trigger movement away when the opposite side is safe.
reset_world()
_, hired_hand = new_party()
new_entity(3, "ITEM_BOMB", 1.5, 0)
hired_hand.process_input_callback(hired_hand)
assert_mask(hired_hand.input.buttons_gameplay, INPUTS.LEFT, true, "bomb escape")

-- High horizontal projectiles trigger a duck.
reset_world()
_, hired_hand = new_party()
local arrow = new_entity(3, "ITEM_WOODEN_ARROW", -2, 0.2)
arrow.velocityx = 0.2
hired_hand.process_input_callback(hired_hand)
assert_mask(hired_hand.input.buttons_gameplay, INPUTS.DOWN, true, "projectile duck")

-- Shop items and extremely dangerous pickups are refused.
reset_world()
_, hired_hand = new_party()
local shop_item = new_entity(3, "ITEM_ROCK", 0, 0)
shop_item.flags = 1 << (ENT_FLAG.SHOP_ITEM - 1)
assert(hired_hand.pick_up_callback(hired_hand, shop_item) == true, "shop pickup was not blocked")
local teleporter = new_entity(4, "ITEM_TELEPORTER", 0, 0)
assert(hired_hand.pick_up_callback(hired_hand, teleporter) == true, "teleporter pickup was not blocked")
local telepack = new_entity(5, "ITEM_TELEPORTER_BACKPACK", 0, 0)
assert(hired_hand.pick_up_callback(hired_hand, telepack) == true, "telepack vanilla pickup was not replaced")
assert(hired_hand.holding_uid == telepack.uid, "telepack was not converted to hand-carried cargo")

-- Hou Yi's Bow has its own protection and remains untouched.
local bow = new_entity(6, "ITEM_HOUYIBOW", 0, 0)
options.restrict_dangerous_pickups = false
assert(hired_hand.pick_up_callback(hired_hand, bow) == true, "Hou Yi's Bow pickup was not blocked")
options.restrict_dangerous_pickups = true

-- Empty-handed Hired Hands carry nearby packs without equipping or throwing them.
reset_world()
leader, hired_hand = new_party()
leader.x = -4
local jetpack = new_entity(3, "ITEM_JETPACK", 0.8, 0)
hired_hand.input.buttons_gameplay = INPUTS.WHIP
hired_hand.process_input_callback(hired_hand)
assert(hired_hand.holding_uid == jetpack.uid, "nearby jetpack was not carried")
assert(jetpack.overlay == hired_hand, "carried jetpack was not attached to the Hired Hand")
assert(worn_backitem(hired_hand.uid) == -1, "carried jetpack was equipped")
assert_mask(hired_hand.input.buttons_gameplay, INPUTS.WHIP, false, "carried jetpack throw")
local second_cargo = new_entity(4, "ITEM_PICKUP_CLIMBINGGLOVES", -0.8, 0)
hired_hand.process_input_callback(hired_hand)
assert(hired_hand.holding_uid == jetpack.uid, "existing cargo was replaced")
assert(second_cargo.overlay == nil, "second cargo item was taken with occupied hands")

-- Duplicate co-op equipment uses the same inert cargo slot without granting it.
for _, equipment_type in ipairs({
    "ITEM_CAPE",
    "ITEM_PICKUP_CLIMBINGGLOVES",
    "ITEM_PICKUP_SPRINGSHOES",
    "ITEM_PICKUP_SPIKESHOES",
    "ITEM_PICKUP_PASTE"
}) do
    reset_world()
    leader, hired_hand = new_party()
    leader.x = -4
    local equipment = new_entity(3, equipment_type, 0.8, 0)
    hired_hand.input.buttons_gameplay = INPUTS.WHIP
    hired_hand.process_input_callback(hired_hand)
    assert(hired_hand.holding_uid == equipment.uid, equipment_type .. " was not carried")
    assert(equipment.overlay == hired_hand, equipment_type .. " was not attached as cargo")
    assert(worn_backitem(hired_hand.uid) == -1, equipment_type .. " was equipped")
    assert_mask(hired_hand.input.buttons_gameplay, INPUTS.WHIP, false, equipment_type .. " throw")
end

-- Unpaid and burning packs are never taken as cargo.
reset_world()
_, hired_hand = new_party()
local shop_jetpack = new_entity(3, "ITEM_JETPACK", 0.6, 0)
shop_jetpack.flags = shop_jetpack.flags | (1 << (ENT_FLAG.SHOP_ITEM - 1))
local burning_hoverpack = new_entity(4, "ITEM_HOVERPACK", -0.6, 0)
burning_hoverpack.explosion_trigger = true
hired_hand.process_input_callback(hired_hand)
assert(hired_hand.holding_uid == -1, "unsafe pack was carried")

-- A pack equipped by vanilla pickup behavior is immediately converted to inert cargo.
reset_world()
_, hired_hand = new_party()
local powerpack = new_entity(3, "ITEM_POWERPACK", 0, 0)
powerpack.overlay = hired_hand
hired_hand.worn_backitem_uid = powerpack.uid
hired_hand.post_pick_up_callback(hired_hand, powerpack)
assert(hired_hand.worn_backitem_uid == -1, "powerpack remained equipped")
assert(hired_hand.holding_uid == powerpack.uid, "equipped powerpack was not moved to the hands")
assert(powerpack.overlay == hired_hand, "converted powerpack was not attached as cargo")

-- A carried pack that catches fire is dropped and treated like a live explosive.
powerpack.explosion_trigger = true
hired_hand.process_input_callback(hired_hand)
assert(hired_hand.holding_uid == -1, "burning powerpack was not dropped")
assert(powerpack.overlay == nil, "burning powerpack remained attached")
assert_mask(hired_hand.input.buttons_gameplay, INPUTS.LEFT, true, "burning pack escape")

-- A carried pet is never thrown while a player is nearby.
reset_world()
leader, hired_hand = new_party()
leader.x = -3
local dog = new_entity(3, "MONS_PET_DOG", 0, 0)
hired_hand.holding_uid = dog.uid
hired_hand.input.buttons_gameplay = INPUTS.WHIP
hired_hand.process_input_callback(hired_hand)
assert_mask(hired_hand.input.buttons_gameplay, INPUTS.WHIP, false, "pet throw near player")

-- An enemy that could be knocked into a nearby player blocks the attack.
reset_world()
leader, hired_hand = new_party()
leader.x = 3.0
leader.y = 2.1
new_entity(3, "MONS_SKELETON", 2.0, 0)
local rock = new_entity(4, "ITEM_ROCK", 0, 0)
hired_hand.holding_uid = rock.uid
hired_hand.input.buttons_gameplay = INPUTS.WHIP
hired_hand.process_input_callback(hired_hand)
assert_mask(hired_hand.input.buttons_gameplay, INPUTS.WHIP, false, "secondary collision near player")

-- A nearby stompable enemy prompts a jump instead of a thrown attack.
reset_world()
leader, hired_hand = new_party()
leader.x = -5
new_entity(3, "MONS_SKELETON", 1.4, -0.2)
hired_hand.input.buttons_gameplay = INPUTS.WHIP
hired_hand.process_input_callback(hired_hand)
assert_mask(hired_hand.input.buttons_gameplay, INPUTS.RIGHT, true, "stomp approach direction")
assert_mask(hired_hand.input.buttons_gameplay, INPUTS.JUMP, true, "stomp jump")
assert_mask(hired_hand.input.buttons_gameplay, INPUTS.WHIP, false, "stomp replaces attack")

-- While descending over an enemy, the Hired Hand commits to the stomp.
reset_world()
leader, hired_hand = new_party()
leader.x = -5
hired_hand.state = CHAR_STATE.FALLING
hired_hand.standing_on_uid = -1
new_entity(3, "MONS_SKELETON", 0.3, -1.0)
hired_hand.input.buttons_gameplay = INPUTS.WHIP | INPUTS.DOWN
hired_hand.process_input_callback(hired_hand)
assert_mask(hired_hand.input.buttons_gameplay, INPUTS.WHIP, false, "airborne stomp attack")
assert_mask(hired_hand.input.buttons_gameplay, INPUTS.DOWN, false, "airborne stomp down input")

-- Faster reactions remove vanilla idle pauses and catch farther projectiles.
reset_world()
_, hired_hand = new_party()
hired_hand.ai.walk_pause_timer = -30
arrow = new_entity(3, "ITEM_WOODEN_ARROW", -6, 0.2)
arrow.velocityx = 0.15
hired_hand.process_input_callback(hired_hand)
assert(hired_hand.ai.walk_pause_timer == 0, "idle pause was not shortened")
assert_mask(hired_hand.input.buttons_gameplay, INPUTS.DOWN, true, "far projectile duck")

-- Trust is raised to the configured minimum.
hired_hand.ai.trust = 0
hired_hand.process_input_callback(hired_hand)
assert(hired_hand.ai.trust == options.minimum_trust, "minimum trust was not applied")

-- A Hired Hand left far behind keeps the player as its target and walks to catch up.
reset_world()
leader, hired_hand = new_party()
leader.x = 12
hired_hand.ai.walk_pause_timer = -20
hired_hand.process_input_callback(hired_hand)
assert(hired_hand.ai.target == leader, "distant leader was not restored as the AI target")
assert(hired_hand.ai.target_uid == leader.uid, "distant leader uid was not restored")
assert(hired_hand.ai.walk_pause_timer == 45, "distant Hired Hand was not kept out of an idle pause")
assert_mask(hired_hand.input.buttons_gameplay, INPUTS.RIGHT, true, "safe catch-up direction")

-- Catch-up never forces a Hired Hand across an unsupported deep drop.
reset_world()
leader, hired_hand = new_party()
leader.x = 12
scenario.support = false
hired_hand.process_input_callback(hired_hand)
assert(hired_hand.ai.target_uid == leader.uid, "leader target was lost at a dangerous gap")
assert_mask(hired_hand.input.buttons_gameplay, INPUTS.RIGHT, false, "catch-up across deep drop")

-- A nearby combat target is preserved even while the leader is far away.
reset_world()
leader, hired_hand = new_party()
leader.x = 12
local nearby_enemy = new_entity(3, "MONS_SKELETON", -2, 0)
hired_hand.ai.target = nearby_enemy
hired_hand.ai.target_uid = nearby_enemy.uid
hired_hand.process_input_callback(hired_hand)
assert(hired_hand.ai.target == nearby_enemy, "nearby combat target was overwritten")
assert(hired_hand.ai.target_uid == nearby_enemy.uid, "nearby combat target uid was overwritten")

-- Nearby leaders do not activate the forced catch-up movement.
reset_world()
leader, hired_hand = new_party()
leader.x = 5
hired_hand.input.buttons_gameplay = INPUTS.LEFT
hired_hand.process_input_callback(hired_hand)
assert(hired_hand.ai.target_uid == -1, "nearby leader unnecessarily replaced the AI target")
assert_mask(hired_hand.input.buttons_gameplay, INPUTS.LEFT, true, "nearby personal-space buffer")

-- Large vertical separation still restores the leader target.
reset_world()
leader, hired_hand = new_party()
leader.x = 2
leader.y = 12
hired_hand.process_input_callback(hired_hand)
assert(hired_hand.ai.target_uid == leader.uid, "vertically separated leader was not restored")

-- Cross-layer leaders are left entirely to the vanilla transition behavior.
reset_world()
leader, hired_hand = new_party()
leader.x = 12
leader.layer = 1
hired_hand.input.buttons_gameplay = INPUTS.LEFT
hired_hand.process_input_callback(hired_hand)
assert(hired_hand.ai.target_uid == -1, "cross-layer leader replaced the AI target")
assert_mask(hired_hand.input.buttons_gameplay, INPUTS.LEFT, true, "cross-layer follow input")

-- Model Overlunky's actual lifecycle: companion user_data follows the party
-- chain, survives the tunnel, and is loaded AFTER spawn hooks but BEFORE
-- POST_LEVEL_GENERATION. Native cargo can be lost, held, or worn on arrival.
local function run_callback(event)
    if callbacks[event] ~= nil then
        callbacks[event]()
    end
end

local function transition_party(companions, native_mode, skip_tunnel, arrival_setup)
    run_callback(ON.PRE_LOAD_SCREEN)
    local saved = {}
    for i, companion in ipairs(companions) do
        saved[i] = companion.user_data
    end
    local before_tunnel = spawned_cargo_count
    if not skip_tunnel then
        reset_world()
        state.screen = SCREEN.TRANSITION
        local tunnel_parent = new_entity(20, "CHAR_ANA_SPELUNKY", 0, 0)
        for i = 1, #companions do
            local companion = new_entity(20 + i, "CHAR_HIREDHAND", i, 0)
            companion.linked_companion_parent = tunnel_parent.uid
            spawn_callback(companion)
            companion.user_data = saved[i]
            if companion.post_update_callback ~= nil then
                companion.post_update_callback(companion)
            end
            tunnel_parent = companion
        end
        run_callback(ON.POST_LEVEL_GENERATION)
        assert(spawned_cargo_count == before_tunnel, "cargo was spawned in the transition tunnel")
    end

    reset_world()
    local new_leader = new_entity(30, "CHAR_ANA_SPELUNKY", 2, 0)
    players = {new_leader}
    local parent = new_leader
    local arrived = {}
    for i, previous in ipairs(companions) do
        local companion = new_entity(30 + i, "CHAR_HIREDHAND", i, 0)
        companion.linked_companion_parent = parent.uid
        spawn_callback(companion)
        companion.user_data = saved[i]
        if native_mode ~= nil then
            local old_item = previous.test_cargo
            local item = new_entity(100 + i, type_names[old_item.type.id], 0, 0)
            item.overlay = companion
            if native_mode == "worn" then
                companion.worn_backitem_uid = item.uid
            else
                companion.holding_uid = item.uid
            end
        end
        arrived[i] = companion
        parent = companion
    end
    if arrival_setup ~= nil then
        arrival_setup(arrived)
    end
    run_callback(ON.POST_LEVEL_GENERATION)
    run_callback(ON.LEVEL)
    return new_leader, arrived
end

local pickup_cargo_types = {
    "ITEM_PICKUP_TORNJOURNALPAGE", "ITEM_PICKUP_JOURNAL", "ITEM_PICKUP_ROPE",
    "ITEM_PICKUP_ROPEPILE", "ITEM_PICKUP_BOMBBAG", "ITEM_PICKUP_BOMBBOX",
    "ITEM_PICKUP_12BAG", "ITEM_PICKUP_24BAG", "ITEM_PICKUP_ROYALJELLY",
    "ITEM_PICKUP_COOKEDTURKEY", "ITEM_PICKUP_GIANTFOOD", "ITEM_PICKUP_ELIXIR",
    "ITEM_PICKUP_CLOVER", "ITEM_PICKUP_SEEDEDRUNSUNLOCKER", "ITEM_PICKUP_SPECTACLES",
    "ITEM_PICKUP_CLIMBINGGLOVES", "ITEM_PICKUP_PITCHERSMITT", "ITEM_PICKUP_SPRINGSHOES",
    "ITEM_PICKUP_SPIKESHOES", "ITEM_PICKUP_PASTE", "ITEM_PICKUP_COMPASS",
    "ITEM_PICKUP_SPECIALCOMPASS", "ITEM_PICKUP_PARACHUTE", "ITEM_PICKUP_UDJATEYE",
    "ITEM_PICKUP_KAPALA", "ITEM_PICKUP_HEDJET", "ITEM_PICKUP_CROWN",
    "ITEM_PICKUP_EGGPLANTCROWN", "ITEM_PICKUP_TRUECROWN", "ITEM_PICKUP_ANKH",
    "ITEM_PICKUP_TABLETOFDESTINY", "ITEM_PICKUP_SKELETON_KEY", "ITEM_PICKUP_PLAYERBAG"
}
local cargo_types = {
    "ITEM_JETPACK", "ITEM_HOVERPACK", "ITEM_POWERPACK", "ITEM_TELEPORTER_BACKPACK",
    "ITEM_CAPE", "ITEM_VLADS_CAPE"
}
for _, pickup_type in ipairs(pickup_cargo_types) do
    cargo_types[#cargo_types + 1] = pickup_type
end
local transition_scenarios = 0
for _, cargo_type in ipairs(cargo_types) do
    reset_world()
    _, hired_hand = new_party()
    local item = new_entity(3, cargo_type, 0.8, 0)
    item.metadata = 37
    if cargo_type == "ITEM_PICKUP_PLAYERBAG" then
        item.bombs = 13
        item.ropes = 7
    end
    hired_hand.process_input_callback(hired_hand)
    assert(hired_hand.holding_uid == item.uid, cargo_type .. " was not taken as inert cargo")
    -- The door can clear holding_uid before the screen changes. Preserve the
    -- last real cargo while entering, without rescuing deliberately dropped items.
    hired_hand.state = CHAR_STATE.ENTERING
    hired_hand.holding_uid = -1
    if hired_hand.post_update_callback ~= nil then
        hired_hand.post_update_callback(hired_hand)
    end
    local _, arrived = transition_party({hired_hand})
    local restored = get_entity(arrived[1].holding_uid)
    assert(restored ~= nil, cargo_type .. " was lost at the exit door")
    assert(restored.type.id == ENT_TYPE[cargo_type], "wrong cargo type after transition")
    assert(restored.overlay == arrived[1], "restored cargo was not attached to its companion")
    assert(restored:get_metadata() == 37, "cargo metadata was lost")
    assert(worn_backitem(arrived[1].uid) == -1, "restored cargo was equipped")
    if cargo_type == "ITEM_PICKUP_PLAYERBAG" then
        assert(restored.bombs == 13 and restored.ropes == 7, "player bag contents were lost")
    end
    local before_repeat = spawned_cargo_count
    run_callback(ON.POST_LEVEL_GENERATION)
    assert(spawned_cargo_count == before_repeat, "repeated restore duplicated cargo")
    local _, next_arrived = transition_party(arrived, nil, true)
    assert(get_entity(next_arrived[1].holding_uid).type.id == ENT_TYPE[cargo_type],
        "cargo was lost on a second, direct level transition")
    transition_scenarios = transition_scenarios + 1
end

-- Automatic overlap collection must become cargo before granting any effect.
-- Human players can still collect these items, and HHs cannot steal attachments.
for _, cargo_type in ipairs(cargo_types) do
    reset_world()
    leader, hired_hand = new_party()
    local item = new_entity(3, cargo_type, 0.5, 0)
    assert(item.collision_callback ~= nil, cargo_type .. " has no automatic collection hook")
    assert(item.collision_callback(item, hired_hand) == true, "HH overlap collected " .. cargo_type)
    assert(hired_hand.holding_uid == item.uid and item.overlay == hired_hand,
        "overlap did not attach " .. cargo_type .. " as cargo")
    assert(item.collision_callback(item, leader) == false, "human collection was blocked")
    local thief = new_entity(4, "CHAR_HIREDHAND", 0.5, 0)
    assert(item.collision_callback(item, thief) == true, "another HH could collect carried cargo")
    assert(item.overlay == hired_hand and thief.holding_uid == -1, "attached cargo was stolen")
    hired_hand.input.buttons_gameplay = INPUTS.WHIP
    hired_hand.process_input_callback(hired_hand)
    assert_mask(hired_hand.input.buttons_gameplay, INPUTS.WHIP, false, cargo_type .. " cargo throw")
end

-- Supplies cannot bypass the cargo limit or shop/fire checks through overlap.
reset_world()
leader, hired_hand = new_party()
local carried_rock = new_entity(3, "ITEM_ROCK", 0, 0)
carried_rock.overlay = hired_hand
hired_hand.holding_uid = carried_rock.uid
local bomb_bag = new_entity(4, "ITEM_PICKUP_BOMBBAG", 0.5, 0)
assert(bomb_bag.collision_callback(bomb_bag, hired_hand) == true, "occupied HH consumed supplies")
assert(hired_hand.holding_uid == carried_rock.uid and bomb_bag.overlay == nil,
    "supply overlap replaced an existing held item")
drop(hired_hand.uid, carried_rock.uid)
bomb_bag.flags = bomb_bag.flags | (1 << (ENT_FLAG.SHOP_ITEM - 1))
assert(bomb_bag.collision_callback(bomb_bag, hired_hand) == true, "unpaid supply overlap was not blocked")
assert(hired_hand.holding_uid == -1, "unpaid supply was attached as cargo")
bomb_bag.flags = bomb_bag.flags & (~(1 << (ENT_FLAG.SHOP_ITEM - 1)))
bomb_bag.onfire_effect_timer = 10
assert(bomb_bag.collision_callback(bomb_bag, hired_hand) == true, "burning supply overlap was not blocked")
assert(hired_hand.holding_uid == -1, "burning supply was attached as cargo")
options.carry_equipment_packs = false
assert(bomb_bag.collision_callback(bomb_bag, hired_hand) == false,
    "disabled cargo handling still blocked vanilla collection")
options.carry_equipment_packs = true

-- Cargo expansion leaves existing combat and quest protection options intact.
reset_world()
_, hired_hand = new_party()
local shotgun = new_entity(3, "ITEM_SHOTGUN", 0.5, 0)
assert(hired_hand.pick_up_callback(hired_hand, shotgun) == false, "ordinary weapon pickup was replaced")
local special_bow = new_entity(4, "ITEM_HOUYIBOW", 0.5, 0)
assert(hired_hand.pick_up_callback(hired_hand, special_bow) == true, "special bow protection was lost")
options.protect_houyi_bow = false
assert(hired_hand.pick_up_callback(hired_hand, special_bow) == false, "special bow option was ignored")
options.protect_houyi_bow = true
local plasma = new_entity(5, "ITEM_PLASMACANNON", 0.5, 0)
assert(hired_hand.pick_up_callback(hired_hand, plasma) == true, "dangerous weapon protection was lost")
options.restrict_dangerous_pickups = false
assert(hired_hand.pick_up_callback(hired_hand, plasma) == false, "dangerous pickup option was ignored")
options.restrict_dangerous_pickups = true
local powerup_effect = new_entity(6, "ITEM_POWERUP_ANKH", 0.5, 0)
assert(powerup_effect.collision_callback == nil, "equipped powerup effect was treated as loose cargo")

-- Reuse native transfers; a pack already worn by the new HH becomes cargo.
for _, mode in ipairs({"held", "worn"}) do
    reset_world()
    _, hired_hand = new_party()
    local item = new_entity(3, "ITEM_JETPACK", 0.8, 0)
    hired_hand.process_input_callback(hired_hand)
    hired_hand.test_cargo = item
    local before = spawned_cargo_count
    local _, arrived = transition_party({hired_hand}, mode)
    assert(arrived[1].holding_uid == 101, "native " .. mode .. " pack was not reused")
    assert(worn_backitem(arrived[1].uid) == -1, "native transferred pack remained worn")
    assert(spawned_cargo_count == before, "native transferred cargo was duplicated")
    transition_scenarios = transition_scenarios + 1
end

-- Different cargo stays with each link in a multi-companion party.
reset_world()
_, hired_hand = new_party()
local first_item = new_entity(3, "ITEM_JETPACK", 0.5, 0)
hired_hand.process_input_callback(hired_hand)
local second_hand = new_entity(4, "CHAR_HIREDHAND", 4, 0)
second_hand.linked_companion_parent = hired_hand.uid
spawn_callback(second_hand)
local second_item = new_entity(5, "ITEM_PICKUP_KAPALA", 4.5, 0)
second_hand.process_input_callback(second_hand)
local _, pair = transition_party({hired_hand, second_hand})
assert(get_entity(pair[1].holding_uid).type.id == first_item.type.id, "first companion got the wrong cargo")
assert(get_entity(pair[2].holding_uid).type.id == second_item.type.id, "second companion got the wrong cargo")
transition_scenarios = transition_scenarios + 1

-- Preserve an unrelated item supplied by another mod and leave cargo nearby.
reset_world()
_, hired_hand = new_party()
local busy_cargo = new_entity(3, "ITEM_HOVERPACK", 0.5, 0)
hired_hand.process_input_callback(hired_hand)
local _, busy_arrived = transition_party({hired_hand}, nil, false, function(arrived)
    local rock = new_entity(200, "ITEM_ROCK", 0, 0)
    rock.overlay = arrived[1]
    arrived[1].holding_uid = rock.uid
    arrived[1].layer = 1
end)
assert(busy_arrived[1].holding_uid == 200, "restoration replaced an unrelated held item")
local loose = get_entities_by_type(ENT_TYPE.ITEM_HOVERPACK)
assert(#loose == 1 and get_entity(loose[1]).overlay == nil, "occupied hands lost the restored cargo")
assert(get_entity(loose[1]).layer == 1, "cargo restored on the wrong layer")
local before_busy_repeat = spawned_cargo_count
run_callback(ON.POST_LEVEL_GENERATION)
assert(spawned_cargo_count == before_busy_repeat, "occupied hands duplicated restored cargo")
transition_scenarios = transition_scenarios + 1

-- Disabling cargo after pickup still preserves the item as a loose pickup.
reset_world()
_, hired_hand = new_party()
local disabled_cargo = new_entity(3, "ITEM_PICKUP_KAPALA", 0.5, 0)
hired_hand.process_input_callback(hired_hand)
options.carry_equipment_packs = false
local _, disabled_arrived = transition_party({hired_hand})
assert(disabled_arrived[1].holding_uid == -1, "disabled cargo handling attached an item")
local loose_kapalas = get_entities_by_type(ENT_TYPE.ITEM_PICKUP_KAPALA)
assert(#loose_kapalas == 1 and get_entity(loose_kapalas[1]).overlay == nil,
    "disabling cargo handling lost the Kapala")
options.carry_equipment_packs = true
transition_scenarios = transition_scenarios + 1

-- Dropping, burning, or dying clears the saved cargo even without input.
for _, reason in ipairs({"drop", "burn", "death"}) do
    reset_world()
    _, hired_hand = new_party()
    local item = new_entity(3, "ITEM_POWERPACK", 0.5, 0)
    hired_hand.process_input_callback(hired_hand)
    if reason == "drop" then
        drop(hired_hand.uid, item.uid)
    elseif reason == "burn" then
        item.explosion_trigger = true
    else
        hired_hand.health = 0
    end
    if hired_hand.post_update_callback ~= nil then
        hired_hand.post_update_callback(hired_hand)
    end
    local before = spawned_cargo_count
    local _, arrived = transition_party({hired_hand})
    assert(arrived[1].holding_uid == -1, reason .. " resurrected old cargo")
    assert(spawned_cargo_count == before, reason .. " duplicated old cargo")
    transition_scenarios = transition_scenarios + 1
end

-- A new party with reused UIDs has no cargo from an earlier run.
reset_world()
_, hired_hand = new_party()
run_callback(ON.POST_LEVEL_GENERATION)
assert(hired_hand.holding_uid == -1, "cargo leaked into a new run")
transition_scenarios = transition_scenarios + 1

-- Knocked-down HHs must release every cargo type, even without input. No HH
-- may take the released item during stun or the 3.5-second recovery grace.
for _, cargo_type in ipairs(cargo_types) do
    reset_world()
    leader, hired_hand = new_party()
    local item = new_entity(3, cargo_type, 0.5, 0)
    hired_hand.process_input_callback(hired_hand)
    local position = item:get_absolute_position()
    hired_hand.stun_timer = 30
    hired_hand.state = CHAR_STATE.STUNNED
    hired_hand.input = nil
    hired_hand.post_update_callback(hired_hand)
    assert(hired_hand.holding_uid == -1 and item.overlay == nil,
        cargo_type .. " was not released on knockdown")
    assert(item.x == position.x and item.y == position.y, "released cargo moved to relative coordinates")
    assert(hired_hand.user_data.equipment_cargo == nil, "released cargo remained in the exit snapshot")
    local other_hand = new_entity(4, "CHAR_HIREDHAND", 0.5, 0)
    item.collision_callback(item, hired_hand)
    hired_hand.pick_up_callback(hired_hand, item)
    item.collision_callback(item, other_hand)
    assert(hired_hand.holding_uid == -1 and other_hand.holding_uid == -1,
        "knockdown cargo was immediately reclaimed")
    assert(item.collision_callback(item, leader) == false, "human collection of dropped cargo was blocked")

    -- Remaining stunned longer than the grace cannot let another HH take it.
    frame = frame + 600
    item.collision_callback(item, other_hand)
    assert(other_hand.holding_uid == -1, "another HH reclaimed cargo while its carrier was still stunned")
    hired_hand.post_update_callback(hired_hand)
    hired_hand.stun_timer = 0
    hired_hand.state = CHAR_STATE.STANDING
    hired_hand.input = {buttons_gameplay = 0}
    frame = frame + 1
    hired_hand.process_input_callback(hired_hand)
    hired_hand.pick_up_callback(hired_hand, item)
    item.collision_callback(item, other_hand)
    assert(hired_hand.holding_uid == -1 and other_hand.holding_uid == -1,
        "post-recovery grace was bypassed by a pickup path")
    frame = frame + 208
    hired_hand.process_input_callback(hired_hand)
    assert(hired_hand.holding_uid == -1, "recovery grace ended before 3.5 seconds")
    frame = frame + 1
    hired_hand.process_input_callback(hired_hand)
    assert(hired_hand.holding_uid == item.uid, "normal pickup did not resume after recovery grace")
end

-- Vanilla may already drop cargo, or clear only its holding pointer, before
-- the mod sees the knockdown. Neither case may leave cargo stuck or reclaimed.
for _, native_drop in ipairs({"dropped", "pointer_only"}) do
    reset_world()
    leader, hired_hand = new_party()
    local item = new_entity(3, "ITEM_JETPACK", 0.5, 0)
    hired_hand.process_input_callback(hired_hand)
    if native_drop == "dropped" then
        drop(hired_hand.uid, item.uid)
    else
        hired_hand.holding_uid = -1
    end
    hired_hand.stun_timer = 30
    local other_hand = new_entity(4, "CHAR_HIREDHAND", 0.5, 0)
    item.collision_callback(item, other_hand)
    assert(other_hand.holding_uid == -1, "native drop was stolen before the carrier's update")
    hired_hand.post_update_callback(hired_hand)
    assert(item.overlay == nil and hired_hand.holding_uid == -1, "native knockdown left cargo attached")
    local before = spawned_cargo_count
    local _, arrived = transition_party({hired_hand})
    assert(arrived[1].holding_uid == -1 and spawned_cargo_count == before,
        "knockdown cargo was recreated at the next exit")
end

-- A human who has already taken dropped cargo keeps ownership.
reset_world()
leader, hired_hand = new_party()
local recovered_item = new_entity(3, "ITEM_PICKUP_KAPALA", 0.5, 0)
hired_hand.process_input_callback(hired_hand)
drop(hired_hand.uid, recovered_item.uid)
attach_entity(leader.uid, recovered_item.uid)
leader.holding_uid = recovered_item.uid
hired_hand.stun_timer = 30
hired_hand.post_update_callback(hired_hand)
assert(recovered_item.overlay == leader and leader.holding_uid == recovered_item.uid,
    "knockdown handling detached a human's recovered item")

-- Even without a stun flag, deliberately dropped cargo is not sucked back up.
reset_world()
_, hired_hand = new_party()
local deliberate_drop = new_entity(3, "ITEM_HOVERPACK", 0.5, 0)
hired_hand.process_input_callback(hired_hand)
drop(hired_hand.uid, deliberate_drop.uid)
hired_hand.post_update_callback(hired_hand)
hired_hand.process_input_callback(hired_hand)
assert(hired_hand.holding_uid == -1 and deliberate_drop.overlay == nil,
    "deliberately dropped cargo was immediately reclaimed")

-- Either knockdown signal is sufficient; ordinary weapons still use vanilla
-- drop behavior instead of the special cargo attachment recovery.
for _, signal in ipairs({"timer", "state", "dying", "dead"}) do
    reset_world()
    _, hired_hand = new_party()
    local item = new_entity(3, "ITEM_PICKUP_ANKH", 0.5, 0)
    if signal == "timer" then
        hired_hand.stun_timer = 1
    elseif signal == "state" then
        hired_hand.state = CHAR_STATE.STUNNED
    elseif signal == "dying" then
        hired_hand.state = CHAR_STATE.DYING
    else
        hired_hand.health = 0
    end
    hired_hand.pick_up_callback(hired_hand, item)
    item.collision_callback(item, hired_hand)
    assert(item.overlay == nil and hired_hand.holding_uid == -1, signal .. " did not block cargo pickup")
end
reset_world()
_, hired_hand = new_party()
local ordinary_weapon = new_entity(3, "ITEM_SHOTGUN", 0.5, 0)
attach_entity(hired_hand.uid, ordinary_weapon.uid)
hired_hand.holding_uid = ordinary_weapon.uid
hired_hand.stun_timer = 30
hired_hand.post_update_callback(hired_hand)
assert(hired_hand.holding_uid == ordinary_weapon.uid, "cargo recovery changed ordinary weapon handling")

print("Cautious Hired Hands mock tests: all scenarios passed (including "
    .. transition_scenarios .. " cargo transition scenarios and "
    .. #cargo_types .. " automatic collection types and " .. #cargo_types .. " knockdown recovery types)")
