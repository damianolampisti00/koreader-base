local BB = require("ffi/blitbuffer")
local bb10 = require("ffi/bb10")

local framebuffer = {}

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
    self:_updateWindow()
    framebuffer.parent.init(self)
end

function framebuffer:_updateWindow()
    local bb = self.window_bb
    local ext_bb = self.full_bb or self.bb
    -- Clone the shadow buffer's rotation & inverse settings, so that the blit below is a 1:1 copy.
    bb:setInverse(ext_bb:getInverse())
    bb:setRotation(ext_bb:getRotation())
    if bb:getInverse() == 1 and BB:getUseCBB() then
        -- The CBB ignores the invert flag: apply it now.
        bb:invertblitFrom(ext_bb)
    else
        bb:blitFrom(ext_bb)
    end
    bb10.post()
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
