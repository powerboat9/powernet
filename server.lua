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

local clients = {}
local sendingChannels = {}

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

function sendPage(data, clientEncryptKey, myDecryptKey, channel, verificationString, myVerificationString, myChannel)
    local sendData = "Sending " .. myVerificationString .. "\n\n" .. encrypt(data, clientKey)
    local transmitTimer = nil
    local timeoutTimer = nil
    local timedOut = false
    local gotIt = false
    while true do
        transmitTimer = os.startTimer(0.5)
        while true do
            local event, timerOrSide, to, from, msg = os.pullEvent()
            if event == "timer" then
                if timer == timeoutTimer then
                    timedOut = true
                    break
                elseif timer == transmitTimer then
                    break
                end
            elseif (event == "modem_message") and (decrypt(msg, myDecryptKey) == ("Recived " .. myVerificationString .. " " .. verificationString)) then
                gotIt = true
                timedOut = true
            end
        end
        if timedOut then
            break
        end
        modem.transmit(channel, myChannel, sendData)
    end
    if not gotIt then
        print("A Client Timed Out")
    end
end

function initializeClient(clientEncryptKey, clientVerificationString, channel)
    local clientID = 1
    for k, v in ipairs(clients) do
        clientID = clientID + 1
    end
    clients[clientID] = {
        ["encryptKey"] = clientEncryptKey,
        ["verifyKey"] = clientVerificationString,
        ["channel"] = channel
    }
    updateSendingChannels()
end

function updateSendingChannels()
    sendingChannels = {}
    for clientID, clientTable in pairs(clients) do
        local openingChannel = clientTable.channel
        if not sendingChannels[openingChannel] then
            sendingChannels[openingChannel] = true
        end
    end
end

function client()
    local clientID, encryptKey, decryptKey, myID = coroutine.yield()
    while true do
        local term, termReason, clientMSG = coroutine.yield()
        if term then
            modem.transmit({
                ["msg"] = encrypt("close"),
                ["clientID"] = clientID,
                ["data"] = encrypt(textutils.serialize({
                    ["reason"] = termReason or "unknown"
                }))
            })
            break
        end
        local msg = decrypt(clientMSG.msg)
        local data = textutils.unserialize(decrypt(clientMSG))
        if msg == "get_page" then
            modem.transmit({
                ["msg"] = encrypt("sending_page"),
                ["clientID"] = clientID,
                ["data"] = encrypt(textutils.serialize({
                    ["url"] = data.url,
                    ["src"] = interpretRequest(data.url)
                }))
            })
        end
    end
end

function getClient(clientID, encryptKey, decryptKey, myID)
    local newClient = coroutine.create(client)
    coroutine.resume(newClient)
    coroutine.resume(newClient, clientID, encryptKey, decryptKey, myID)
    return newClient
end
