local BB = require("ffi/blitbuffer")
local bb10 = require("ffi/bb10")
local ffi = require("ffi")
local C = ffi.C

local framebuffer = {}

--- Splash screen, shown in the window until KOReader's first refresh: the logo
-- (resources/bb10/splash-*.png, made by the port's scripts/make-splash.py) centered
-- on white, or on black in night mode.
local function showSplash(bb)
    local night = G_reader_settings and G_reader_settings:isTrue("night_mode")
    bb:fill(night and BB.COLOR_BLACK or BB.COLOR_WHITE)
    local ok, Png = pcall(require, "ffi/png")
    local decoded, img
    if ok then
        decoded, img = Png.decodeFromFile("resources/bb10/splash-" .. (night and "dark" or "light") .. ".png", 3)
    end
    if decoded then
        -- The window is BGRX: swap red & blue.
        local p = ffi.cast("uint8_t *", img.data)
        for i = 0, img.width * img.height * 3 - 1, 3 do
            p[i], p[i + 2] = p[i + 2], p[i]
        end
        local logo = BB.new(img.width, img.height, BB.TYPE_BBRGB24, img.data)
        bb:blitFrom(logo, math.floor((bb10.width - img.width) / 2), math.floor((bb10.height - img.height) / 2),
                    0, 0, img.width, img.height)
        logo:free()
        C.free(img.data)
    end
    bb10.post()
end

function framebuffer:init()
    bb10.init()
    -- The libscreen window buffer (RGBX8888, i.e., BGRX in memory: see Device.hasBGRFrameBuffer).
    self.window_bb = BB.new(bb10.width, bb10.height, BB.TYPE_BBRGB32, bb10.pixels, bb10.stride, bb10.stride / 4)
    -- We present this shadow buffer to the outside, like on Android:
    -- rotation & night mode are applied when copying it to the window.
    self.bb = BB.new(bb10.width, bb10.height, BB.TYPE_BBRGB32)
    self.bb:fill(BB.COLOR_WHITE)
    if bb10.dpi and not self.dpi then
        self.dpi = bb10.dpi
    end
    showSplash(self.window_bb)
    framebuffer.parent.init(self)
end

function framebuffer:_updateWindow()
    local bb = self.window_bb
    local ext_bb = self.full_bb or self.bb
    -- Clone the shadow buffer's rotation & inverse settings, so that the blit below is a 1:1 copy:
    -- in night mode, the shadow buffer's content is already inverted (like on SDL).
    bb:setInverse(ext_bb:getInverse())
    bb:setRotation(ext_bb:getRotation())
    bb:blitFrom(ext_bb)
    bb10.post()
end

-- The active frame (device/bb10/cover) follows night mode too.
function framebuffer:toggleNightMode()
    framebuffer.parent.toggleNightMode(self)
    if self.onNightModeChanged then
        self.onNightModeChanged(self.night_mode)
    end
end

function framebuffer:refreshFullImp(x, y, w, h) -- luacheck: ignore
    self:_updateWindow()
end

function framebuffer:close()
    if self.window_bb then
        self.window_bb:free()
        self.window_bb = nil
    end
    if self.bb then
        self.bb:free()
        self.bb = nil
    end
    bb10.shutdown()
end

return require("ffi/framebuffer"):extend(framebuffer)
