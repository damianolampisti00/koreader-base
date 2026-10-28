--[[--
BlackBerry 10 input: translates BPS events (libscreen touch & keyboard, navigator)
into Linux evdev-style events, like `ffi/input_android`.

@module ffi.input_bb10
]]

local bit = require("bit")
local ffi = require("ffi")
local C = ffi.C

local bb10 = require("ffi/bb10")
require("ffi/posix_h")
require("ffi/linux_input_h")

local input = {
    device = nil,
    open = function() end,
    close = function() end,
    closeAll = function() end,
    fakeTapInput = function() end,
    is_ffi = true,
    --- EV_MSC codes for navigator events (handled by the device's `handleMiscEv`).
    MSC_EXIT = 1,
    MSC_WINDOW_STATE = 2, -- value: navigator_window_state_t
    MSC_SWIPE_DOWN = 3,
    MSC_LOW_MEMORY = 4,
    MSC_DEVICE_LOCK = 5,
}

local inputQueue = {}

local function genInputTimeval()
    local timespec = ffi.new("struct timespec")
    C.clock_gettime(C.CLOCK_MONOTONIC, timespec)
    return { sec = tonumber(timespec.tv_sec), usec = math.floor(tonumber(timespec.tv_nsec / 1000)) }
end

local function genEmuEvent(evtype, code, value, timev)
    table.insert(inputQueue, {
        type = tonumber(evtype),
        code = tonumber(code),
        value = tonumber(value),
        time = timev or genInputTimeval(),
    })
end

local iv = ffi.new("int[2]")

local function getEventIv(sev, prop)
    bb10.screen.screen_get_event_property_iv(sev, prop, iv)
    return iv[0], iv[1]
end

local function touchEvent(sev, evtype)
    local slot = getEventIv(sev, C.SCREEN_PROPERTY_TOUCH_ID)
    local x, y = getEventIv(sev, C.SCREEN_PROPERTY_SOURCE_POSITION)
    local timev = genInputTimeval()
    genEmuEvent(C.EV_ABS, C.ABS_MT_SLOT, slot, timev)
    if evtype == C.SCREEN_EVENT_MTOUCH_TOUCH then
        genEmuEvent(C.EV_ABS, C.ABS_MT_TRACKING_ID, slot, timev)
    elseif evtype == C.SCREEN_EVENT_MTOUCH_RELEASE then
        genEmuEvent(C.EV_ABS, C.ABS_MT_TRACKING_ID, -1, timev)
    end
    genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_X, x, timev)
    genEmuEvent(C.EV_ABS, C.ABS_MT_POSITION_Y, y, timev)
    genEmuEvent(C.EV_SYN, C.SYN_REPORT, 0, timev)
end

-- Code sent on key down, by key cap, so that the release matches it.
local pressed = {}

local function isPrintable(sym)
    return sym >= 0x20 and sym < 0x7f
end

local function keyboardEvent(sev)
    local flags = getEventIv(sev, C.SCREEN_PROPERTY_KEY_FLAGS)
    local cap = getEventIv(sev, C.SCREEN_PROPERTY_KEY_CAP)
    local sym = getEventIv(sev, C.SCREEN_PROPERTY_KEY_SYM)
    local cap_valid = bit.band(flags, C.KEY_CAP_VALID) ~= 0
    local sym_valid = bit.band(flags, C.KEY_SYM_VALID) ~= 0
    if not cap_valid then
        return
    end
    if bit.band(flags, C.KEY_DOWN) ~= 0 then
        -- Use the key cap (the unshifted character, or a KEYCODE_*), like SDL keycodes,
        -- except for the symbols typed with Alt on the Q10's keyboard.
        local code = cap
        if sym_valid and isPrintable(sym) and isPrintable(cap) and sym ~= cap
            and not (cap >= 0x61 and cap <= 0x7a and sym == cap - 0x20) then
            code = sym
        end
        local repeated = bit.band(flags, C.KEY_REPEAT) ~= 0
        pressed[cap] = code
        genEmuEvent(C.EV_KEY, code, repeated and 2 or 1)
    else
        genEmuEvent(C.EV_KEY, pressed[cap] or cap, 0)
        pressed[cap] = nil
    end
end

local function screenEvent(event)
    local sev = bb10.bps.screen_event_get_event(event)
    local evtype = getEventIv(sev, C.SCREEN_PROPERTY_TYPE)
    if evtype == C.SCREEN_EVENT_MTOUCH_TOUCH
        or evtype == C.SCREEN_EVENT_MTOUCH_MOVE
        or evtype == C.SCREEN_EVENT_MTOUCH_RELEASE then
        touchEvent(sev, evtype)
    elseif evtype == C.SCREEN_EVENT_KEYBOARD then
        keyboardEvent(sev)
    end
end

local function navigatorEvent(event)
    local code = bb10.bps.bps_event_get_code(event)
    if code == C.NAVIGATOR_EXIT then
        genEmuEvent(C.EV_MSC, input.MSC_EXIT, 0)
    elseif code == C.NAVIGATOR_WINDOW_STATE then
        genEmuEvent(C.EV_MSC, input.MSC_WINDOW_STATE, bb10.bps.navigator_event_get_window_state(event))
    elseif code == C.NAVIGATOR_SWIPE_DOWN then
        genEmuEvent(C.EV_MSC, input.MSC_SWIPE_DOWN, 0)
    elseif code == C.NAVIGATOR_LOW_MEMORY then
        genEmuEvent(C.EV_MSC, input.MSC_LOW_MEMORY, 0)
    elseif code == C.NAVIGATOR_DEVICE_LOCK_STATE then
        genEmuEvent(C.EV_MSC, input.MSC_DEVICE_LOCK, 0)
    elseif code == C.NAVIGATOR_ORIENTATION_CHECK then
        -- Square display: we never rotate along with the device.
        bb10.bps.navigator_orientation_check_response(event, false)
    end
end

-- Side keys, as their sys/keycodes.h KEYCODE_* (see the device's event map).
local button_keycodes = {
    [C.BUTTON_PLUS] = C.KEYCODE_VOLUME_UP,
    [C.BUTTON_MINUS] = C.KEYCODE_VOLUME_DOWN,
    [C.BUTTON_PLAYPAUSE] = C.KEYCODE_PLAY,
}

local function buttonEvent(event)
    local code = button_keycodes[tonumber(bb10.bps.button_event_get_button(event))]
    if code then
        genEmuEvent(C.EV_KEY, code, bb10.bps.bps_event_get_code(event) == C.BUTTON_DOWN and 1 or 0)
    end
end

local event = ffi.new("bps_event_t *[1]")

local function handleEvent()
    local domain = bb10.bps.bps_event_get_domain(event[0])
    if domain == bb10.screen_domain then
        screenEvent(event[0])
    elseif domain == bb10.navigator_domain then
        navigatorEvent(event[0])
    elseif domain == bb10.button_domain then
        buttonEvent(event[0])
    end
end

function input.waitForEvent(sec, usec)
    local timeout = sec and math.floor((sec * 1000000 + usec) / 1000 + 0.5) or -1

    inputQueue = {}

    if bb10.bps.bps_get_event(event, timeout) ~= C.BPS_SUCCESS then
        return
    end
    if event[0] == nil then
        return false, C.ETIME
    end
    handleEvent()
    -- Drain what's already pending.
    while bb10.bps.bps_get_event(event, 0) == C.BPS_SUCCESS and event[0] ~= nil do
        handleEvent()
    end

    if #inputQueue > 0 then
        return true, inputQueue
    else
        return false, C.EINTR
    end
end

return input
