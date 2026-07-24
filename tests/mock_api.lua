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
ON = {PRE_LEVEL_GENERATION = 1, LEVEL = 2}

options = {}
players = {}

local spawn_callback = nil
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

function set_post_entity_spawn(callback)
    spawn_callback = callback
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

function get_entities_by_type(entity_type)
    local result = {}
    for uid, entity in pairs(entities) do
        if entity.type.id == entity_type then
            result[#result + 1] = uid
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
    return {x = self.x, y = self.y}
end

function entity_methods:get_absolute_velocity()
    return {x = self.velocityx or 0, y = self.velocityy or 0}
end

function entity_methods:can_jump()
    return true
end

function entity_methods:set_pre_process_input(callback)
    self.process_input_callback = callback
end

function entity_methods:set_pre_pick_up(callback)
    self.pick_up_callback = callback
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
        ai = {trust = 0, walk_pause_timer = 1},
        velocityx = 0,
        velocityy = 0
    }, {__index = entity_methods})
    entities[uid] = entity
    return entity
end

local function reset_world()
    entities = {}
    players = {}
    scenario.support = true
    scenario.lava = false
    frame = frame + 100
    if callbacks[ON.PRE_LEVEL_GENERATION] ~= nil then
        callbacks[ON.PRE_LEVEL_GENERATION]()
    end
end

local function new_party()
    local leader = new_entity(1, "CHAR_ANA_SPELUNKY", 2, 0)
    local hired_hand = new_entity(2, "CHAR_HIREDHAND", 0, 0)
    hired_hand.linked_companion_parent = leader.uid
    players = {leader}
    spawn_callback(hired_hand)
    return leader, hired_hand
end

local function assert_mask(value, mask, expected, label)
    local actual = test_mask(value, mask)
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

dofile("CautiousHiredHands/main.lua")

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

-- Hou Yi's Bow has its own protection and remains untouched.
local bow = new_entity(5, "ITEM_HOUYIBOW", 0, 0)
options.restrict_dangerous_pickups = false
assert(hired_hand.pick_up_callback(hired_hand, bow) == true, "Hou Yi's Bow pickup was not blocked")
options.restrict_dangerous_pickups = true

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

print("Cautious Hired Hands mock tests: all scenarios passed")
