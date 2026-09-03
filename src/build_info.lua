local BuildInfo={VERSION="0.1.0"}

function BuildInfo.isRelease()
    if os.getenv("LAST_HAUL_RELEASE")=="1"then return true end
    return love and love.filesystem and love.filesystem.getInfo and
        love.filesystem.getInfo("release.flag","file")~=nil or false
end

return BuildInfo
