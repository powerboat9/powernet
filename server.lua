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

local configData = configAPI.loadConfig("powernet/serverData/config")

--Functions to get data to display

function interpretRequest(request, dontLoadErrorPage)
    local file = ""
    local fileArgs = ""
    do
        local seperate = request:find("^[^\\]*?")
        file = request:sub(1, seperate - 1)
        fileArgs = request:sub(seperate + 1)
    end
    local isDynamic = false
    local errorCode = nil
    fileString = ""
    do
        local errorReport = {}
        if config.down and ((not (type(config.down) == "function")) or config.down(errorReport, request, file, fileArgs)) then
            if type(config.down) == "function" then
                errorCode = tostring(errorReport.error)
            elseif type(config.down) == "table" then
                errorCode = textutils.serialize(config.downReason)
            else
                errorCode = tostring(config.downReason)
            end
        else
            local fileData = fs.open(config.fileLocation .. shell.resolve(file), "r")
            if fileData then
                fileString = fileData.readAll()
            end
            fileData.close()
            if fileString:find("^EXECUTABLE\n") then
                isDynamic = true
                fileString = fileString:sub(12)
            elseif fileString:find("^POWER WEBDATA\n") then
                fileString = fileString:sub(15)
            elseif (fileData == "") or (fileData == nil) then
                errorCode = "Page Not Found"
            else
                errorCode = "Invalid Page"
            end
        end
    end
    if errorCode and (not dontLoadErrorPage) then
        return interpretRequest("
