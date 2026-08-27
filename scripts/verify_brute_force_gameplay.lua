package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
love.mouse={isDown=function() return false end,getPosition=function() return 0,0 end}
love.math.random=function(a,b) if b then return a elseif a then return 0 else return .25 end end
local Mode=require("src.clearcut_mode")
local mode=Mode.new();mode.job="miner";mode.levels.brute_force=1;mode.bruteTimer=0
mode.permanentTraits={attackSpeed=1,range=0,area=0,extraTargets=0,treeDamage=0}
local fonts={small=love.graphics.newFont("assets/font-korean-regular.ttf",14),body=love.graphics.newFont("assets/font-korean-regular.ttf",17),heading=love.graphics.newFont("assets/font-korean-bold.ttf",21)}
local game={player={x=300,y=250},fonts=fonts,world={nodes={}},enemies={},setNotice=function(self,text) self.notice=text end}

-- Surface-only activation.
mode.minerBurrow={state="tunnel"};mode:updateBruteForce(.1,game)
assert(#mode.digits==0,"brute force activated underground")
mode.minerBurrow=nil;mode:updateBruteForce(.1,game)
assert(#mode.digits>=26,"not enough rapid password guesses were created")
assert(game.notice:find("비트코인",1,true),"bitcoin wallet concept missing from notice")
for _,d in ipairs(mode.digits) do assert(d.state=="charge" and d.visibleAt<d.launchAt and d.glyph:match("^%d$")) end

mode:updateBruteForce(.2,game)
fixture.reset();mode:drawSupplementSkills(game,.2)
local numbers=0
local walletDraws=0
for _,op in ipairs(fixture.commands) do
    if op.op=="draw" and op.file=="assets/fx/brute-force/brute-force-digits-cartoon-pixel-v2.png" then numbers=numbers+1 end
    if op.op=="draw" and op.file=="assets/fx/brute-force/bitcoin-wallet-cartoon-pixel-v1.png" then walletDraws=walletDraws+1 end
end
assert(numbers>=20,"password numbers do not pop rapidly during charge")
assert(walletDraws==1,"encrypted bitcoin wallet is missing")
local first=mode.digits[1]
assert(first.walletX>game.player.x and first.startX<first.walletX,"number input beam does not travel from mole to forward wallet")

mode:updateBruteForce(.35,game)
local quadrants={false,false,false,false}
for _,d in ipairs(mode.digits) do
    assert(d.state=="fly","numbers did not launch after password crack")
    local q=(d.vx>=0 and 1 or 2)+(d.vy>=0 and 0 or 2);quadrants[q]=true
end
for i=1,4 do assert(quadrants[i],"numbers were not scattered in every direction") end

local ids={}
for _,def in ipairs(mode:upgradePool()) do ids[def.id]=true end
assert(ids.brute_force)
for _,id in ipairs({"ddos_attack","ransomware","zeroday_exploit","port_scan"}) do assert(not ids[id],id.." still appears in skill pool") end
print("BRUTE_FORCE_GAMEPLAY_OK surface_only digits=rapid scatter=360 bitcoin_wallet=true removed_hacks=4")
