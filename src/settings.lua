local Settings={}

local DEFAULTS={screenShake=true,viewPitch=.76,musicVolume=.98,sfxVolume=.80}

local function clamp(value,default)
    value=tonumber(value)
    if not value then return default end
    return math.max(0,math.min(1,value))
end

function Settings.decode(text,fullscreen)
    local data={fullscreen=fullscreen==true}
    for key,value in pairs(DEFAULTS)do data[key]=value end
    for key,value in tostring(text or ""):gmatch("([%w_]+)=([^\r\n]+)")do
        if key=="screenShake"then data.screenShake=value=="true"
        elseif key=="viewPitch"then data.viewPitch=clamp(value,DEFAULTS.viewPitch)
        elseif key=="musicVolume"then data.musicVolume=clamp(value,DEFAULTS.musicVolume)
        elseif key=="sfxVolume"then data.sfxVolume=clamp(value,DEFAULTS.sfxVolume)end
    end
    return data
end

function Settings.load(memoryOnly,fullscreen)
    local self=setmetatable({file="last_haul_settings_v1.txt",memoryOnly=memoryOnly==true},{__index=Settings})
    local text
    if not self.memoryOnly and love.filesystem and love.filesystem.getInfo and
        love.filesystem.getInfo(self.file)then text=love.filesystem.read(self.file)end
    self.data=Settings.decode(text,fullscreen)
    return self
end

function Settings:save()
    if self.memoryOnly or not love.filesystem or not love.filesystem.write then return true end
    local d=self.data
    local text=table.concat({
        "screenShake="..tostring(d.screenShake),
        string.format("viewPitch=%.4f",d.viewPitch),
        string.format("musicVolume=%.4f",d.musicVolume),
        string.format("sfxVolume=%.4f",d.sfxVolume),
    },"\n").."\n"
    return love.filesystem.write(self.file,text)
end

return Settings
