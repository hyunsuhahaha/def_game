package.path="./?.lua;./?/init.lua;"..package.path

local files={}
love={filesystem={
    getInfo=function(path)return files[path]and{}or nil end,
    read=function(path)return files[path]end,
    write=function(path,text)files[path]=text;return true end,
    remove=function(path)files[path]=nil;return true end,
}}
local SafeSave=require("src.safe_save")

assert(SafeSave.write("profile.sav","version=1\ncoins=10\n"),"first staged save failed")
assert(files["profile.sav"]:find("safe_checksum=",1,true)and not files["profile.sav.tmp"],"save was not sealed or temp remained")
assert(SafeSave.write("profile.sav","version=1\ncoins=20\n"),"second staged save failed")
files["profile.sav"]=files["profile.sav"]:gsub("coins=20","coins=999")
local restored,state=SafeSave.read("profile.sav")
assert(state=="recovered"and restored:find("coins=10",1,true),"corrupt primary did not recover its backup")

files["legacy.sav"]="version=1\ncoins=7\n"
local legacy,legacyState=SafeSave.read("legacy.sav")
assert(legacyState=="legacy"and legacy:find("coins=7",1,true),"legacy save was rejected")
assert(SafeSave.write("legacy.sav","version=1\ncoins=8\n")and files["legacy.sav.bak"],"legacy save was not upgraded safely")

files["temp.sav"]=SafeSave.seal("version=1\ncoins=1\n"):gsub("coins=1","coins=2")
files["temp.sav.tmp"]=SafeSave.seal("version=1\ncoins=3\n")
local temp,tempState=SafeSave.read("temp.sav")
assert(tempState=="recovered"and temp:find("coins=3",1,true),"valid staged save did not recover")
print("SAFE_SAVE_OK checksum=adler32 backup=previous temp=recovery legacy=compatible")
