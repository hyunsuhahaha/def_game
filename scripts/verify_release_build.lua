package.path="./?.lua;./?/init.lua;"..package.path

local BuildInfo=require("src.build_info")
local originalLove=love
love={filesystem={getInfo=function(path,kind)
    return path=="release.flag"and kind=="file"and{}or nil
end}}
assert(BuildInfo.isRelease(),"release.flag did not enable release mode")
love={filesystem={getInfo=function()return nil end}}
assert(not BuildInfo.isRelease(),"development checkout was detected as release")
love=originalLove

local function source(path)local f=assert(io.open(path,"rb"));local s=f:read("*a");f:close();return s end
local game,conf,pack=source("src/game.lua"),source("conf.lua"),source("scripts/package_windows.ps1")
assert(game:find("if self.releaseBuild then return false end",1,true),"release build can open developer tools")
assert(game:find("not compact and not self.releaseBuild",1,true),"settings still draw developer tools in release")
assert(conf:find("t.console = not BuildInfo.isRelease()",1,true),"release build still opens a console")
assert(pack:find('release.flag',1,true)and pack:find('love.exe',1,true)and pack:find('game.love',1,true),
    "Windows packager is incomplete")
assert(not pack:find("CopyTo",1,true),"packager mutates the LÖVE executable")
print("RELEASE_BUILD_OK version="..BuildInfo.VERSION.." devtools=hidden console=hidden")
