local Box = require("ui/components/box")
local Image = setmetatable({}, {__index = Box})
Image.__index = Image

local function BlitLine(term, line, x, y, offsetX, maxWidth)
    if offsetX < 0 then
        x = x - offsetX
        offsetX = 0
    end
    term.setCursorPos(x, y)
    term.blit(line[1]:sub(offsetX+1, offsetX+maxWidth), line[2]:sub(offsetX+1, offsetX+maxWidth), line[3]:sub(offsetX+1, offsetX+maxWidth))
end

local function BlitImage(term, lines, x, y, offsetX, offsetY, w, h)
    for i = math.max(1,1 + offsetY), math.min(#lines, offsetY + h) do
        BlitLine(term, lines[i], x, y+i-1-offsetY, offsetX, w)
    end
end

local function LoadImage(fileName)
    local f = fs.open(fileName, "rb")
    if f == nil then
        return nil
    end
    local width = f.read()
    if width == 0 then
        width = f.read() * 256 + f.read()
    end
    assert(width > 0)
    local img = {}
    while true do
        local line = {"", "", ""}
        for b = 1, width do
            local pixel = f.read()
            if pixel == nil then
                f.close()
                f = nil
                return img
            end
            line[1] = line[1] .. string.char(pixel)
            local color = f.read()
            line[2] = line[2] .. string.format("%x", bit.brshift(color, 4))
            line[3] = line[3] .. string.format("%x", bit.band(color, 0xf))
        end
        assert(line[1]:len() == line[2]:len())
        assert(line[1]:len() == line[3]:len())
        table.insert(img, line)
    end
end

function Image.new(arg)
    local self = setmetatable(Box.new({
        x=arg.x,
        y=arg.y,
        w=arg.w,
        h=arg.h,
        bg=colors.white,
        hidden=arg.hidden
    }), {__index=Image})
    if arg.fileName ~= nil then
        self.image = LoadImage(arg.fileName)
    elseif arg.image ~= nil then
        self.image = arg.image
    end
    return self
end

function Image:draw(term, dx, dy)
    BlitImage(term, self.image, self.x + dx, self.y + dy, 0, 0, self.w, self.h)
end

return Image
