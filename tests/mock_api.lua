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

MASK = {FLOOR = 1, ACTIVEFLOOR = 2, PLAYER = 4}
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
    STUNNED = 18,
    ENTERING = 19,
    LOADING = 20,
    EXITING = 21,
    DYING = 22
}
ENT_FLAG = {FACING_LEFT = 17, SHOP_ITEM = 18}
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
    if entity_types == 0 and mask ~= 0 then
        if scenario.support then
            return {99999}
        end
        return {}
    end

    local result = {}
    for uid, entity in pairs(entities) do
        if requested_type(entity_types, entity) and entity.layer == layer then
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
    local entity = setmetatable({
        uid = uid,
        type = {id = ENT_TYPE[type_name]},
        x = x or 0,
        y = y or 0,
        layer = 0,
        flags = 0,
        health = 4,
        stun_timer = 0,
        state = CHAR_STATE.STANDING,
        standing_on_uid = 99999,
        holding_uid = -1,
        linked_companion_parent = -1,
        input = {buttons_gameplay = 0},
        ai = {trust = 0},
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

-- Trust is raised to the configured minimum.
hired_hand.ai.trust = 0
hired_hand.process_input_callback(hired_hand)
assert(hired_hand.ai.trust == options.minimum_trust, "minimum trust was not applied")

print("Cautious Hired Hands mock tests: 7 passed")
