
function ClearScreen(term)
    term.setCursorPos(1,1)
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.gray)
    local w, h = term.getSize()
    local line = {
        string.rep("\x7f", w),
        string.rep("7", w),
        string.rep("f", w),
    }
    for y = 1, h do
        term.setCursorPos(1, y)
        term.blit(line[1], line[2], line[3])
    end
end

function BlitImage(term, lines, x, y, offsetX, offsetY)
    ClearScreen(term)
    local w,h = term.getSize()
    for i = math.max(1,1 + offsetY), math.min(#lines, offsetY + h) do
        BlitLine(term, lines[i], x, y+i-1-offsetY, offsetX)
    end
end

function BlitLine(term, line, x, y, offsetX)
    if offsetX < 0 then
        x = x - offsetX
        offsetX = 0
    end
    term.setCursorPos(x, y)
    term.blit(line[1]:sub(offsetX+1), line[2]:sub(offsetX+1), line[3]:sub(offsetX+1))
end

function NewImage(width, height, color)
    local img = {}
    while #img < height do
        table.insert(img, {
            string.rep(" ", width),
            string.rep(COLORS[colors.black], width),
            string.rep(COLORS[color], width)
        })
    end
    return img
end

function LoadImage(fileName)
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

function SaveImage(fileName, img)
    local f = fs.open(fileName, "wb")
    local width = img[1][1]:len()
    if width < 256 then
        f.write(width)
    else
        f.write(math.floor(width / 256))
        f.write(width % 256)
    end
    for i = 1, #img do
        local line = img[i]
        for b = 1, #line[1] do
            f.write(line[1]:sub(b, b))
            f.write(tonumber("0x" .. line[2]:sub(b, b) .. line[3]:sub(b, b)))
        end
    end
    f.close()
end

function ReplaceChar(str, index, char)
    return str:sub(0, index-1) .. char .. str:sub(index+1)
end

COLORS = {
    [colors.white]="0",
    [colors.orange]="1",
    [colors.magenta]="2",
    [colors.lightBlue]="3",
    [colors.yellow]="4",
    [colors.lime]="5",
    [colors.pink]="6",
    [colors.gray]="7",
    [colors.lightGray]="8",
    [colors.cyan]="9",
    [colors.purple]="a",
    [colors.blue]="b",
    [colors.brown]="c",
    [colors.green]="d",
    [colors.red]="e",
    [colors.black]="f",
}

function SetPixel(img, x, y, char, fg, bg)
    assert(char:len() == 1)
    img[y][1] = ReplaceChar(img[y][1], x, char)
    img[y][2] = ReplaceChar(img[y][2], x, COLORS[fg])
    img[y][3] = ReplaceChar(img[y][3], x, COLORS[bg])
end

local screen = term.current()
local sw,sh = screen.getSize()
local iw,ih = nil, nil
local bg = colors.white
local fg = colors.black
local tool = {"X", " ", " "}
local image = nil
local args = {...}
local fileName = nil
if #args == 1 then
    -- load image
    fileName = args[1]
    image = LoadImage(fileName)
    iw = image[1][1]:len()
    ih = #image
    if image == nil then
        print("Cannot open file")
        return
    end
elseif #args == 3 then
    -- image size
    fileName = args[1]
    iw = tonumber(args[2])
    ih = tonumber(args[3])
    if iw > 65535 then
        print("Max width is 65535")
        return
    elseif iw < 0 or ih < 0 then
        print("Image size must be positive")
        return
    elseif iw == 0 or ih == 0 then
        iw, ih = screen.getSize()
    end
    image = NewImage(iw, ih, bg)
else
    print("usage: imged filename [width height]")
    return
end

screen.setCursorBlink(false)
screen.setCursorPos(1,1)
screen.clear()
BlitImage(screen, image, 1, 1, 0, 0)

function DrawMenu(term)
    term.setCursorPos(1,1)
    term.blit("BG[                ]","00000000000000000000","fff0123456789abcdeff")
    term.setCursorPos(1,2)
    term.blit("FG[                ]","00000000000000000000","fff0123456789abcdeff")
    term.setCursorPos(1,3)
    term.blit("TOOL[" .. tool[1] .. tool[2] .. "]", "00000000", "ffffffff")
    for hi = 0, 15 do
        local line = string.format("[", hi)
        for lo = 0, 15 do
            local letter = string.char(hi * 16 + lo)
            if letter == "\n" then
                letter = " "
            end
            line = line .. letter
        end
        line = line .. "]"
        term.setCursorPos(2,4+hi)
        term.blit(line, "0" .. string.rep(COLORS[fg], 16) .. "0", "f" .. string.rep(COLORS[bg], 16) .. "f")
    end
end

function DoMenu(term, button, x, y)
    if y == 1 then
        -- bg color
        bg = bit.blshift(1, x-4)
    elseif y == 2 then
        -- fg color
        fg = bit.blshift(1, x-4)
    elseif y >= 4 and y <= 19 and x >= 3 and x <= 18 then
        local hi = y - 4
        local lo = x - 3
        tool[button] = string.char(hi * 16 + lo)
    end
    DrawMenu(term)
end

local inMenu = false
local offsetX, offsetY = 0,0

while true do
    local event, p1, p2, p3 = os.pullEvent()
    if event == "mouse_click" or event == "mouse_drag" then
        local button = p1
        local x = p2
        local y = p3
        if inMenu then
            DoMenu(term, button, x, y)
        elseif x + offsetX <= iw and y + offsetY <= ih then
            local pixel = tool[p1] or tool[1]
            SetPixel(image, x + offsetX, y + offsetY, pixel, fg, bg)
            BlitLine(screen, image[y + offsetY], 1, y, offsetX)
        end
    elseif event == "key" then
        if p1 == keys.leftCtrl or p1 == keys.rightCtrl then
            inMenu = true
            DrawMenu(term)
        elseif p1 == keys.left then
            offsetX = math.min(offsetX + 1, math.max(0, iw - sw + 1))
            BlitImage(screen, image, 1, 1, offsetX, offsetY)
        elseif p1 == keys.right then
            offsetX = math.max(offsetX - 1, -1)
            BlitImage(screen, image, 1, 1, offsetX, offsetY)
        elseif p1 == keys.up then
            offsetY = math.min(offsetY + 1, math.max(0, ih - sh + 1))
            BlitImage(screen, image, 1, 1, offsetX, offsetY)
        elseif p1 == keys.down then
            offsetY = math.max(offsetY - 1, -1)
            BlitImage(screen, image, 1, 1, offsetX, offsetY)
        end
    elseif event == "key_up" then
        if p1 == keys.leftCtrl or p1 == keys.rightCtrl then
            inMenu = false
            BlitImage(screen, image, 1, 1, offsetX, offsetY)
        end
    elseif event == "char" then
        if p1 == "q" then
            term.setBackgroundColor(colors.black)
            term.setTextColor(colors.white)
            term.clear()
            term.setCursorPos(1,1)
            print("Thank you for using imged!")
            break
        elseif p1 == "s" then
            SaveImage(fileName, image)
        end
    end
end
