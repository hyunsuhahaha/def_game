local SafeSave={}
local MAGIC="safe_save=1\n"
local CHECKSUM="\nsafe_checksum="

local function checksum(text)
    local a,b=1,0
    for index=1,#text do a=(a+text:byte(index))%65521;b=(b+a)%65521 end
    return string.format("%08x",b*65536+a)
end

local function seal(text)
    local payload=tostring(text or""):gsub("\r\n","\n"):gsub("%s+$","")
    return MAGIC..payload..CHECKSUM..checksum(payload).."\n"
end

local function verify(text)
    if type(text)~="string"then return nil,"missing"end
    if text:sub(1,#MAGIC)~=MAGIC then return text,"legacy"end
    local marker=text:find(CHECKSUM,#MAGIC+1,true)
    if not marker then return nil,"corrupt"end
    local payload=text:sub(#MAGIC+1,marker-1)
    local expected=text:sub(marker+#CHECKSUM):match("^([0-9a-fA-F]+)")
    if not expected or checksum(payload)~=expected:lower()then return nil,"corrupt"end
    return payload.."\n","valid"
end

local function read(path)
    local fs=love and love.filesystem
    if not fs or not fs.read then return nil end
    if fs.getInfo and not fs.getInfo(path)then return nil end
    return fs.read(path)
end

function SafeSave.read(path)
    local fs=love and love.filesystem
    if not fs then return nil,"missing"end
    for _,candidate in ipairs({path,path..".bak",path..".tmp"})do
        local payload,state=verify(read(candidate))
        if payload then
            if candidate~=path and fs.write then fs.write(path,seal(payload))end
            return payload,candidate==path and state or"recovered"
        end
    end
    return nil,"corrupt"
end

function SafeSave.write(path,text)
    local fs=love and love.filesystem
    if not fs or not fs.write or not fs.read then return false end
    local staged=seal(text)
    if not fs.write(path..".tmp",staged)then return false end
    local checked=verify(read(path..".tmp"))
    if not checked then return false end
    local current,currentState=verify(read(path))
    if current and currentState~="corrupt"and not fs.write(path..".bak",seal(current))then return false end
    if not fs.write(path,staged)then return false end
    if not verify(read(path))then return false end
    if fs.remove then fs.remove(path..".tmp")end
    return true
end

SafeSave.seal=seal
SafeSave.verify=verify
return SafeSave
