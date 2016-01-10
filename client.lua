function equalToOr(test, ...)
    for k, v in ipairs(args) do
        if v == test then
            return true
        end
    end
    return false
end

function validColor(c)
    return equalToOr(c, 1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768)
end
