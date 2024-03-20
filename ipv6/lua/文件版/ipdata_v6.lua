ipdata = { prefStart = {}, prefEnd = {},v6_num = 0,
    endArr = {}, addrArr = {},
    file = {}, _version = "0.1.2",big_num = {'170141183460469231731687303715884105728', '85070591730234615865843651857942052864', '42535295865117307932921825928971026432', '21267647932558653966460912964485513216', '10633823966279326983230456482242756608', '5316911983139663491615228241121378304', '2658455991569831745807614120560689152', '1329227995784915872903807060280344576', '664613997892457936451903530140172288', '332306998946228968225951765070086144', '166153499473114484112975882535043072', '83076749736557242056487941267521536', '41538374868278621028243970633760768', '20769187434139310514121985316880384', '10384593717069655257060992658440192', '5192296858534827628530496329220096', '2596148429267413814265248164610048', '1298074214633706907132624082305024', '649037107316853453566312041152512', '324518553658426726783156020576256', '162259276829213363391578010288128', '81129638414606681695789005144064', '40564819207303340847894502572032', '20282409603651670423947251286016', '10141204801825835211973625643008', '5070602400912917605986812821504', '2535301200456458802993406410752', '1267650600228229401496703205376', '633825300114114700748351602688', '316912650057057350374175801344', '158456325028528675187087900672', '79228162514264337593543950336', '39614081257132168796771975168', '19807040628566084398385987584', '9903520314283042199192993792', '4951760157141521099596496896', '2475880078570760549798248448', '1237940039285380274899124224', '618970019642690137449562112', '309485009821345068724781056', '154742504910672534362390528', '77371252455336267181195264', '38685626227668133590597632', '19342813113834066795298816', '9671406556917033397649408', '4835703278458516698824704', '2417851639229258349412352', '1208925819614629174706176', '604462909807314587353088', '302231454903657293676544', '151115727451828646838272', '75557863725914323419136', '37778931862957161709568', '18889465931478580854784', '9444732965739290427392', '4722366482869645213696', '2361183241434822606848', '1180591620717411303424', '590295810358705651712', '295147905179352825856', '147573952589676412928', '73786976294838206464', '36893488147419103232', '18446744073709551616', '9223372036854775808', '4611686018427387904', '2305843009213693952', '1152921504606846976', '576460752303423488', '288230376151711744', '144115188075855872', '72057594037927936', '36028797018963968', '18014398509481984', '9007199254740992', '4503599627370496', '2251799813685248', '1125899906842624', '562949953421312', '281474976710656', '140737488355328', '70368744177664', '35184372088832', '17592186044416', '8796093022208', '4398046511104', '2199023255552', '1099511627776', '549755813888', '274877906944', '137438953472', '68719476736', '34359738368', '17179869184', '8589934592', '4294967296', '2147483648', '1073741824', '536870912', '268435456', '134217728', '67108864', '33554432', '16777216', '8388608', '4194304', '2097152', '1048576', '524288', '262144', '131072', '65536', '32768', '16384', '8192', '4096', '2048', '1024', '512', '256', '128', '64', '32', '16', '8', '4', '2', '1'},
    offset_data = nil
}

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
    local num_data = redaFileBytes(ipdata.file, 4, 4)
    ipdata.v6_num = unpackInt4byte(num_data[1], num_data[2], num_data[3], num_data[4])
    sizeData = redaFileBytes(ipdata.file, ipdata.v6_num*12, 8)

    for k = 1, ipdata.v6_num do
        local i = (k-1) * 12
        local preoff = unpackInt4byte(sizeData[i+9], sizeData[i+10], sizeData[i+11], sizeData[i+12])
        ipdata.prefStart[preoff] = unpackInt4byte(sizeData[i+1], sizeData[i+2], sizeData[i+3], sizeData[i+4])
        ipdata.prefEnd[preoff] = unpackInt4byte(sizeData[i+5], sizeData[i+6], sizeData[i+7], sizeData[i+8])
    end

    sizeData = redaFileBytes(ipdata.file, 4, 0)
    local recordSize = unpackInt4byte(sizeData[1], sizeData[2], sizeData[3], sizeData[4])
    local p = ipdata.v6_num*12+4+4
    ipdata.file:seek("set", p)
    ipdata.offset_data = ipdata.file:read(55*recordSize+1)
end

function ipdata.getAddr(row)
    local j = ipdata.v6_num*12+4+4 + (row * 55)
    ipdata.file:seek("set", j + 50)
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
        local offaa = (mid)*55+1
        local data_len = (mid)*55+50
        local endipNum = string.gsub(string.sub(ipdata.offset_data,offaa,data_len), "*", "") 

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
    local ip_str = tranSimIpv6ToFullIpv6(ip)
    local prefix = tonumber(string.sub(ip_str,1,4), 16)
    local low = ipdata.prefStart[prefix]
    local high = ipdata.prefEnd[prefix]
    local ip_2 = ipv6bin(ip_str)


    local intIP = "0"
    for i = 1, string.len(ip_2) do
        if string.sub(ip_2,i,i) == '1' then
            local num1 = ipdata.big_num[i]
            if string.len(num1)>string.len(intIP) then
                intIP = bigNumberAdd(num1, intIP)
            else
                intIP = bigNumberAdd(intIP, num1)
            end
        end
    end

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

function bigNumberAdd(a, b)  
    local result = "" 
    local carry = 0 
    local lenA = #a  
    local lenB = #b  
    local i = 1  
  
    if lenA < lenB then  
        a, b = b, a  
        lenA, lenB = lenB, lenA  
    end  
  
    while i <= lenB do  
        local sum = tonumber(a:sub(lenA - i + 1, lenA - i + 1)) + tonumber(b:sub(lenB - i + 1, lenB - i + 1)) + carry  
        result = tostring(sum % 10) .. result
        carry = math.floor(sum / 10)
        i = i + 1  
    end  
  
    while i <= lenA do  
        local sum = tonumber(a:sub(lenA - i + 1, lenA - i + 1)) + carry  
        result = tostring(sum % 10) .. result  
        carry = math.floor(sum / 10)  
        i = i + 1  
    end  
  
    if carry > 0 then  
        result = tostring(carry) .. result  
    end  
  
    return result  
end  


function ipv6bin(ipstr)
    ipstr = tranSimIpv6ToFullIpv6(ipstr)
    ipstr = ipstr:gsub(":", "")
    local ipbin = ""
    for i = 1, 32, 2 do
        local str_16 = tonumber(string.sub(ipstr,i,i+1), 16)
        local bin = ""
        while str_16>0 do
            bin = tostring(str_16 % 2)..bin
            str_16 = math.floor(str_16/2)
        end
        bin = string.sub("00000000"..bin,-8)
        ipbin = ipbin..bin
    end
    return ipbin
end

function tranSimIpv6ToFullIpv6(simpeIpv6)  
    simpeIpv6 = string.upper(simpeIpv6)
  
    if simpeIpv6 == "::" then  
        return "0000:0000:0000:0000:0000:0000:0000:0000"  
    end  
  
    local arr = {"0000", "0000", "0000", "0000", "0000", "0000", "0000", "0000"}
    if string.sub(simpeIpv6, 1, 2) == "::" then  
        local tmpArr = {}  
        for part in string.gmatch(string.sub(simpeIpv6, 3), "%S+") do  
            table.insert(tmpArr, string.sub("0000"..part,-4))  
        end  
        for i = 1, #tmpArr do  
            arr[i + 8 - #tmpArr] = tmpArr[i]  
        end  
    elseif string.sub(simpeIpv6, -2) == "::" then  
        local tmpArr = {}  
        for part in string.gmatch(string.sub(simpeIpv6, 1, -3), "%S+") do  
            local aaa = string_split(part, ":")
            for j=1,#aaa do
                table.insert(tmpArr, string.sub("0000"..aaa[j],-4))  
            end 
        end  
        for i = 1, #tmpArr do  
            arr[i] = tmpArr[i]  
        end  
    elseif string.find(simpeIpv6, "::") then  
        local tmpArr = string_split(simpeIpv6, "::")  
        local tmpArr0 = string_split(tmpArr[1], ":")  
        for i = 1, #tmpArr0 do  
            arr[i] = string.sub("0000"..tmpArr0[i],-4)
        end  
        local tmpArr1 = string_split(tmpArr[2], ":")  
        for i = 1, #tmpArr1 do  
            arr[i + 8 - #tmpArr1] = string.sub("0000"..tmpArr1[i],-4)
        end  
    else  
        local tmpArr = string_split(simpeIpv6, ":")  
        for i = 1, #tmpArr do  
            arr[i + 8 - #tmpArr] = string.sub("0000"..tmpArr[i],-4)
        end  
    end  
    return table.concat(arr, ":")  
end  

function string_split(str, delimiter)  
    local result = {}  
    for match in (str..delimiter):gmatch("(.-)"..delimiter) do  
        table.insert(result, match)  
    end  
    return result  
end  

return ipdata
