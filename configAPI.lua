function isTypes(item, ...)
    local itemType = type(item)
    for v in ipairs(...) do
        if itemType = v then
            return true
        end
    end
end

function textKeyToValue(t, txt)
    local currentT = t
    local branches = {}
    local currentTreeLocation = {}
    for branch in txt:gmatch("([^%.])%.") do
        branches[#branches + 1] = branch
    end
    while (type(currentT) == "table") and branches[1] do
        currentT = currentT[branches[1]]
        currentTreeLocation:insert(1, branches[1])
        branches:remove(1)
    end
    return currentT, (type(currentT) == "table"), currentTreeLocation
end

function loadConfig(file, defaults, typesAllowed)
    if not fs.exists(file) then
        local fileWrite = fs.open(file, "w")
        fileWrite.write(textutils.serialise(defaults))
        fileWrite.close()
        return defaults
    end
    --Had to look at the code for os.loadAPI, therefor this is very simaler
    local sandbox = {}
    setmetatable(sandbox, _G)
    fileFunction, errorTxt = loadfile(file, sandbox)
    if fileFunction then
        local ok, errorTxt = pcall(fileFunction)
        if not ok then
            return false, errorTxt
        end
    else
        return false, errorTxt
    end
    setmetatable(sandbox, {})
    for k, v in pairs(typesAllowed) do
        local keyValue, ranFully, currentKey = textKeyToValue(sandbox, k)
        if not isTypes(keyValue, unpack(v) then
        
end
