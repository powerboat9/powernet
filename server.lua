os.loadAPI("powernet/configAPI")
if not fs.exists("powernet/serverData/config") then
    local configWrite = fs.open("powernet/serverData/config", "w")
    configWrite.write("--Config for Server--\n")
    configWrite.write("address = os.getComputerID()\n")
    configWrite.write("fileLocation = \"powernet/server/files/\"\n")
    configWrite.write("down = false --Makes the server unavalible\n")
    configWrite.write("downReason = nil --Gives the reason for being down")
    configWrite.close()
end

local modem = peripheral.find("modem", function(name, obj) return obj.isWireless() end)
if not modem then
    print("Wireless Modem Not Found, Checking For Wired Modem")
    modem = assert(peripheral.find("modem"), "Could Not Find Modem")
    local consent = false
    while true do
        print("Found A Wired Modem. Do You Want To Use It? (y/n)")
        local word = read()
        if word == "y" then
            consent = true
            break
        elseif word == "n" then
            consent = false
            break
        else
            print("Please type \"y\" or \"n\"")
        end
    end
    assert(consent, "Could Not Find Wireless Modem")
end

local configData = configAPI.loadConfig("powernet/serverData/config")

--Functions to get data to display

function interpretRequest(request)
    local file = ""
    local fileArgs = ""
    do
        local seperate = request:find("^[^\\]*?")
        file = request:sub(1, seperate - 1)
        fileArgs = request:sub(seperate + 1)
    end
    local isDynamic = false
    local errorCode = nil
    local isError = false
    fileString = ""
    do
        if configData.down then
            if type(configData.down) == "boolean" then
                local isDown = configData.down
                configData.down = function(request, file, fileArgs)
                    return isDown, (isDown and config.downReason)
                end
            end
            isError, errorCode = configDown.down(request, file, fileArgs)
        else
            local fileData = fs.open(configDown.fileLocation .. shell.resolve(file), "r")
            if fileData then
                fileString = fileData.readAll()
                fileData.close()
            else
                isError, errorCode = true, "Page Not Found"
            end
            if fileString:find("^EXECUTABLE\n") then
                isDynamic = true
                fileString = fileString:sub(12)
            elseif fileString:find("^POWER WEBDATA\n") then
                fileString = fileString:sub(15)
            elseif fileString == "" then
                isError, errorCode = true, "Page Not Found"
            else
                isError, errorCode = true, "Invalid Page"
            end
        end
    end
    if isError then
        fileString = "STATIC\ndisplay:align center\n\n" .. errorCode
        isDynamic = false
    end
    if isDynamic then
        fileString = loadstring(fileString)(request, file, fileArgs)
    end
    return fileString
end

function encrypt(msg, key)
    --not there yet, doesn't encrypt for testing purposes
    return msg
end

function decrypt(msg, key)
    --also doesn't decript yet
    return msg
end

function sendPage(data, clientKey, channel)
    local sendData = encrypt(data, clientKey)
    local transmitTimer = nil
    local timeoutTimer = nil
    while true do
