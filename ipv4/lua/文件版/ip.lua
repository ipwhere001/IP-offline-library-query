ipdata = { prefStart = {}, prefEnd = {},
    endArr = {}, addrArr = {},
    file = {}, _version = "0.1.2" }

function unpackInt4byte(a, b, c, d)
    return (a % 256) + (b * 256) + (c * 65536) + (d * 16777216)
end

function fsize(file)
    local current = file:seek()
    local size = file:seek("end")
    file:seek("set", current)
    return size
end

function redaFileBytes(file, length, off)
    file:seek("set", off)
    local str = file:read(length)
    local bytes = {}
    for i = 1, #str do
        table.insert(bytes, string.byte(str, i))
    end
    return bytes
end

function ipdata.LoadFile(path)
    local sizeData = {}

    ipdata.file = io.open(path, "rb")

    for k = 1, 256 do
        local i = k * 8 + 4
        sizeData = redaFileBytes(ipdata.file, 8, i)
        ipdata.prefStart[k] = unpackInt4byte(sizeData[1], sizeData[2], sizeData[3], sizeData[4])
        ipdata.prefEnd[k] = unpackInt4byte(sizeData[5], sizeData[6], sizeData[7], sizeData[8])
    end

    sizeData = redaFileBytes(ipdata.file, 4, 0)
    local recordSize = unpackInt4byte(sizeData[1], sizeData[2], sizeData[3], sizeData[4])

    local allsizeData = redaFileBytes(ipdata.file, recordSize*9+9, 2052)
    for i = 1, recordSize do
        local x = i * 9
		local a = 1 + x
		local b = 2 + x
		local c = 3 + x
		local d = 4 + x
        
		local endipnum2 = unpackInt4byte(allsizeData[a], allsizeData[b], allsizeData[c], allsizeData[d])
		ipdata.endArr[i] = endipnum2
        

    end
end

function ipdata.getAddr(row)
    local j = 2052 + (row * 9)
    ipdata.file:seek("set", j + 4)
    local tempIndexData = ipdata.file:read(5)
    local offset = unpackInt4byte(string.byte(tempIndexData, 1), string.byte(tempIndexData, 2), string.byte(tempIndexData, 3), string.byte(tempIndexData, 4))
    local length = string.byte(tempIndexData, 5)
    ipdata.file:seek("set", offset)
    local tempData = ipdata.file:read(length)
    return tempData
end

function ip2int(ip)
    local o1, o2, o3, o4 = string.match(ip, "(%d+)%.(%d+)%.(%d+)%.(%d+)")
    local num = 2 ^ 24 * o1 + 2 ^ 16 * o2 + 2 ^ 8 * o3 + o4
    return math.floor(num)
end

function ipdata.Search(low, high, k)
    local M = 0
    while low <= high do
        local mid = math.floor((low + high) / 2)
        local endipNum = ipdata.endArr[mid]
        if endipNum == nil then
            break
        end
        if endipNum >= k then
            M = mid
            if mid == 0 then
                break
            end
            high = mid - 1
        else
            low = mid + 1
        end
    end
    return M
end

function ipdata.FindIP(ip)
    local ips = { string.match(ip, "([^.]+).?") }
    local prefix = tonumber(ips[1])

    local low = ipdata.prefStart[prefix]
    local high = ipdata.prefEnd[prefix]
    local intIP = ip2int(ip)

    local cur = 0
    if low == high then
        cur = low
    else
        cur = ipdata.Search(low, high, intIP)
    end

    if cur == 100000000 then
        return "0.0.0.0"
    else
        return ipdata.getAddr(cur)
    end
end

return ipdata
