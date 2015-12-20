--Config
if not fs.exists("powernet/server/config") then
    local configWrite = fs.open("powernet/server/config", "w")
    configWrite.write("--Config for Server--\n")
    configWrite.write("address = os.getComputerID()\n")
    configWrite.write("fileLocation = \"powernet/server/files\"\n")
    configWrite.write("down = false --Makes the server unavalible\n")
    configWrite.write("downReason = nil --Gives the reason for being down")
    configWrite.close()
end

os.loadAPI("powernet/server/config")

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
    local error = nil
    do
        local errorReport = {}
        if config.down and ((not (type(config.down) == "function")) or config.down(errorReport, request, file, fileArgs)) then
            if type(config.down) == "function" then
                error = tostring(errorReport.error)
            elseif type(config.down) == "table" then
                error = textutils.serialize(config.downReason)
            else
                error = tostring(config.downReason)
            end
        else
            local fileData = fs.open(file, "r")
            local fileString = fileData.readAll()
            fileData.close()
            if fileString:find("^EXECUTABLE\n") then
                isDynamic
