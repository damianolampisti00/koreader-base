--[[--
BlackBerry 10 (QNX 8) platform glue, shared by `ffi/framebuffer_bb10` & `ffi/input_bb10`:
one libscreen application context with a single software-rendered window, and the BPS
event loop (screen, navigator & battery events).

@module ffi.bb10
]]

local bit = require("bit")
local ffi = require("ffi")
local C = ffi.C

require("ffi/bb10_h")

local bb10 = {
    screen = ffi.load("libscreen.so.1"),
    bps = ffi.load("libbps.so.3"),
}

local function check(ret, what)
    if ret ~= 0 then
        error(string.format("%s failed: %s", what, ffi.string(C.strerror(ffi.errno()))))
    end
end

local function setWindowIv(prop, ...)
    local values = ffi.new("int[?]", select("#", ...), ...)
    check(bb10.screen.screen_set_window_property_iv(bb10.win, prop, values), "screen_set_window_property_iv")
end

local function getWindowIv(prop, n)
    local values = ffi.new("int[?]", n or 1)
    check(bb10.screen.screen_get_window_property_iv(bb10.win, prop, values), "screen_get_window_property_iv")
    return values
end

function bb10.init()
    if bb10.ctx then
        return
    end
    local S = bb10.screen

    local ctx = ffi.new("screen_context_t[1]")
    check(S.screen_create_context(ctx, C.SCREEN_APPLICATION_CONTEXT), "screen_create_context")
    bb10.ctx = ctx[0]

    local win = ffi.new("screen_window_t[1]")
    check(S.screen_create_window(win, bb10.ctx), "screen_create_window")
    bb10.win = win[0]

    setWindowIv(C.SCREEN_PROPERTY_USAGE, bit.bor(C.SCREEN_USAGE_NATIVE, C.SCREEN_USAGE_WRITE))
    setWindowIv(C.SCREEN_PROPERTY_FORMAT, C.SCREEN_FORMAT_RGBX8888)
    -- A new window covers the whole display.
    local size = getWindowIv(C.SCREEN_PROPERTY_SIZE, 2)
    bb10.width, bb10.height = size[0], size[1]
    setWindowIv(C.SCREEN_PROPERTY_BUFFER_SIZE, bb10.width, bb10.height)
    bb10.setKeepAwake(true)

    -- A single buffer: we only ever post our own (complete) shadow copy.
    check(S.screen_create_window_buffers(bb10.win, 1), "screen_create_window_buffers")
    local buf = ffi.new("screen_buffer_t[1]")
    check(S.screen_get_window_property_pv(bb10.win, C.SCREEN_PROPERTY_RENDER_BUFFERS, ffi.cast("void **", buf)),
          "screen_get_window_property_pv(RENDER_BUFFERS)")
    bb10.buffer = buf[0]
    local ptr = ffi.new("void *[1]")
    check(S.screen_get_buffer_property_pv(bb10.buffer, C.SCREEN_PROPERTY_POINTER, ptr),
          "screen_get_buffer_property_pv(POINTER)")
    bb10.pixels = ptr[0]
    local stride = ffi.new("int[1]")
    check(S.screen_get_buffer_property_iv(bb10.buffer, C.SCREEN_PROPERTY_STRIDE, stride),
          "screen_get_buffer_property_iv(STRIDE)")
    bb10.stride = stride[0]

    local disp = ffi.new("screen_display_t[1]")
    if S.screen_get_window_property_pv(bb10.win, C.SCREEN_PROPERTY_DISPLAY, ffi.cast("void **", disp)) == 0 then
        local dpi = ffi.new("int[1]")
        if S.screen_get_display_property_iv(disp[0], C.SCREEN_PROPERTY_DPI, dpi) == 0 and dpi[0] > 0 then
            bb10.dpi = dpi[0]
        end
    end

    local B = bb10.bps
    if B.bps_initialize() ~= C.BPS_SUCCESS then
        error("bps_initialize failed")
    end
    B.screen_request_events(bb10.ctx)
    B.navigator_request_events(0)
    -- The Q10's display is square: never let the navigator rotate us.
    B.navigator_rotation_lock(true)
    bb10.screen_domain = B.screen_get_domain()
    bb10.navigator_domain = B.navigator_get_domain()
end

function bb10.setKeepAwake(keep_awake)
    setWindowIv(C.SCREEN_PROPERTY_IDLE_MODE, keep_awake and C.SCREEN_IDLE_MODE_KEEP_AWAKE or C.SCREEN_IDLE_MODE_NORMAL)
end

--- Show the window buffer's content, `x, y, w, h` being the dirty rectangle.
function bb10.post(x, y, w, h)
    local rect = ffi.new("int[4]", x or 0, y or 0, w or bb10.width, h or bb10.height)
    bb10.screen.screen_post_window(bb10.win, bb10.buffer, 1, rect, 0)
end

--- Battery state of charge (percent, or nil) and whether a charger is connected.
function bb10.getBatteryInfo()
    local info = ffi.new("battery_info_t *[1]")
    if bb10.bps.battery_get_info(info) ~= C.BPS_SUCCESS then
        return
    end
    local capacity = bb10.bps.battery_info_get_state_of_charge(info[0])
    local charging = bb10.bps.battery_info_get_system_charging_state(info[0])
    local plugged = bb10.bps.battery_info_is_charger_ready(info[0])
    bb10.bps.battery_free_info(info)
    return capacity >= 0 and capacity or nil, charging ~= C.BATTERY_CHARGING_NOT_CHARGING and charging ~= C.BATTERY_CHARGING_DONE_CHARGING, plugged
end

function bb10.openLink(uri)
    return bb10.bps.navigator_invoke(uri, nil) == C.BPS_SUCCESS
end

function bb10.shutdown()
    if not bb10.ctx then
        return
    end
    bb10.bps.screen_stop_events(bb10.ctx)
    bb10.bps.navigator_stop_events(0)
    bb10.bps.bps_shutdown()
    bb10.screen.screen_destroy_window(bb10.win)
    bb10.screen.screen_destroy_context(bb10.ctx)
    bb10.ctx, bb10.win, bb10.buffer, bb10.pixels = nil, nil, nil, nil
end

return bb10
