-- simplest package manager

local function findNth(str, pattern, n)
    local from = 0
    local to = 0
    while n > 0 do
        from, to = string.find(str, pattern, to+1)
        n = n - 1
    end
    return from, to
end

local function addBranch(url, branch)
  local from, to = findNth(url, "/", 5)
  if from == nil then
    return nil
  end
  return string.sub(url, 1, from) .. branch .. string.sub(url, to, string.len(url))
end

local function httpGet(url)
    local request=http.get(url)
    if request == nil then
        return nil
    end
    local content=request.readAll()
    request.close()
    return content
end

PKG_PATH="pkg"

local function checkDir()
    if not fs.exists(PKG_PATH) then
        fs.makeDir(PKG_PATH)
    end
    if not fs.isDir(PKG_PATH) then
        error(PKG_PATH .. " is not a directory")
    end
    if fs.isReadOnly(PKG_PATH) then
        error(PKG_PATH .. " is read-only")
    end
end


local function readFile(path)
    local fp = fs.open(path, "r")
    local data = fp.readAll()
    fp.close()
    return data
end

local function writeFile(path, data)
    local fp = fs.open(path, "w")
    fp.write(data)
    fp.close()
    return true
end

local function getLocalPkg(name)
    local path = PKG_PATH .. "/" .. name
    if not fs.exists(path) then
        return nil
    end
    return textutils.unserialise(readFile(path))
end

local function validatePkg(pkg)
    if type(pkg) ~= "table" or type(pkg.name) ~= "string" or type(pkg.version) ~= "string" then
        error("malformed package")
    end
    if (type(pkg.dst) == "string" and string.sub(pkg.dst, string.len(pkg.dst)) ~= "/") and pkg.dst ~= nil then
        error("invalid destination directory")
    end
end

local function pkgUrl(name)
    if string.sub(name, 1, 8) ~= "https://" then
        -- assume github
        return "https://raw.githubusercontent.com/" .. name
    else
        return name
    end
end

local function getRemotePkg(name)
    local baseUrl=pkgUrl(name)
    local rawPkg = httpGet(baseUrl .. "/pkg")
    if rawPkg == nil and string.sub(baseUrl, 1, 34) == "https://raw.githubusercontent.com/" then
        baseUrl = addBranch(baseUrl, "main")
        if baseUrl ~= nil then
            rawPkg = httpGet(baseUrl .. "/pkg")
        end
    end
    if rawPkg == nil or rawPkg == "" then
        error("package " .. name .. " not found")
    end
    local pkg=textutils.unserialise(rawPkg)
    validatePkg(pkg)
    pkg.baseUrl = baseUrl
    pkg.dst = pkg.dst or ""
    return pkg
end

local function canInstall(pkg)
    -- check files
    local overwrite = false
    for i = 1, #pkg.files do
        local path = pkg.dst .. pkg.files[i]
        if fs.exists(path) then
            print("! " .. path)
            overwrite = true
        end
    end
    return not overwrite
end

local function install(pkg)
    local files = {}
    print("Downloading " .. pkg.name .. " " .. pkg.version)
    for i = 1, #pkg.files do
        local file = pkg.files[i]
        local url = pkg.baseUrl .. "/" .. file
        files[file] = httpGet(url)
    end
    -- install
    print("Installing...")
    writeFile(PKG_PATH .. "/" .. pkg.name, textutils.serialise(pkg))
    for i = 1, #pkg.files do
        local file = pkg.files[i]
        local path = pkg.dst .. file
        if writeFile(path, files[file]) then
            print("+ " .. path)
        end
    end
    return true
end

local function uninstall(pkg)
    print("Uninstalling " .. pkg.name .. " " .. pkg.version)
    for i = 1, #pkg.files do
        local path = pkg.dst .. pkg.files[i]
        if fs.exists(path) then
            print("- " .. path)
            fs.delete(path)
        else
            print("? " .. path)
        end
    end
    fs.delete(PKG_PATH .. "/" .. pkg.name)
end

local function listPackages()
    local items = fs.list(PKG_PATH)
    if #items == 0 then
        print("No packages installed")
        return
    end
    print("Installed packages: ")
    for i = 1, #items do
        local pkg = getLocalPkg(items[i])
        if pkg == nil then
            print("invalid package: " .. items[i])
        else
            print(pkg.name .. " " .. pkg.version)
        end
    end
end

local function help()
    print("usage:")
    print("  pkg install <package>")
    print("  pkg uninstall <package>")
    print("  pkg list")
end

local commands={
    install=function(args)
        if #args ~= 1 then
            return help()
        end
        local pkgId = args[1]
        checkDir()
        local pkg = getRemotePkg(pkgId)
        local localPkg = getLocalPkg(pkg.name)
        if localPkg ~= nil then
            uninstall(localPkg)
        end
        if canInstall(pkg) then
            install(pkg)
        else
            print("Cannot install " .. pkg.name)
        end
    end,
    uninstall=function(args)
        local name = args[1]
        local pkg = getLocalPkg(name)
        if pkg == nil then
            print(pkg .. " is not installed")
        else
            uninstall(pkg)
        end
    end,
    list=listPackages,
    help=help
}

local args={...}
local command=table.remove(args, 1)
if commands[command] ~= nil then
    commands[command](args)
else
    commands.help()
end
