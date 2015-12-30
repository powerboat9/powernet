function isTypes(item, ...)
    local itemType = type(item)
    for v in ipairs(...) do
        if itemType == v then
            return true
        end
    end
    return false
end

function setTextKeyValue(t, txt, v)
    local branches = {}
    for branch in txt:gmatch("([^%.]+)%.") do
        branches[#branches + 1] = branch
    end
    assert(branches[1], txt .. " is not a valid branch path.")
    local currentBranch = t
    local branchLocation = {}
    while true do
        if not branches[2] then
            break
        end
        local nextBranch = currentBranch[branches[1]]
        if type(nextBranch) == "table" then
            currentBranch = nextBranch
        else
            return false
        end
        table.remove(branches, 1)
    end
    t[branches[1]] = v
end

function textKeyToValue(t, txt)
    local currentT = t
    local branches = {}
    local currentTreeLocation = {}
    --Converts txt into a "path", EX: "right.left.up" into: go "right", "left", "up"
    for branch in txt:gmatch("([^%.]+)%.") do
        branches[#branches + 1] = branch
    end
    while (type(currentT) == "table") and branches[1] do
        currentT = currentT[branches[1]]
        currentTreeLocation:insert(1, branches[1])
        branches:remove(1)
    end
    return currentT, (type(currentT) ~= "table"), currentTreeLocation:concat(".")
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
        if type(k) == "string" then
            local keyValue, ranFully, currentKey = textKeyToValue(sandbox, k)
            --Checks that the branch stopped at is of the right type
            if not isTypes(keyValue, unpack(typesAllowed[currentKey]) then
                local defaultValue, success = textKeyToValue(defaults, currentKey)
                assert(success, "List of default values does not have: " .. currentKey)
                setTextKeyValue(sandbox, currentKey, defaultValue)
            end
        end
    end
end
