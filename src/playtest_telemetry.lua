local Telemetry={FILE="playtest_runs.csv"}
Telemetry.__index=Telemetry

Telemetry.COLUMNS={
    "timestamp","version","research_pct","owned_ranks","total_ranks","build","unlocked_tier","start_tier","highest_tier",
    "duration_sec","trees_felled","coins","total_spawned","peak_active","tree_allowance","peak_kps",
    "death_reason","avg_fps","min_fps","worst_frame_ms","frames_below_30_pct","key_presses","mouse_presses",
    "dash_presses","axe_swings","cigarettes","fireworks","flame_hit_ticks","bomb_explosions"
}

local function csv(value)
    local text=tostring(value==nil and""or value)
    if text:find('[,\n\r"]')then return'"'..text:gsub('"','""')..'"'end
    return text
end

local function number(value,digits)
    return string.format("%."..(digits or 0).."f",tonumber(value)or 0)
end

local function buildName(mode)
    local traits=mode.permanentTraits or{}
    if (traits.scoreFlameUnlock or 0)>0 then return"flamethrower"end
    if (traits.scoreRocketUnlock or 0)>0 then return"firework"end
    return"cigarette"
end

function Telemetry.new(mode,traits,version)
    local owned,total=0,0
    if traits and traits.scoreProgress then owned,total=traits:scoreProgress()end
    return setmetatable({active=true,mode=mode,version=version or"",owned=owned,total=total,
        unlockedTier=traits and traits.getRegenTier and traits:getRegenTier()or 1,
        researchPct=total>0 and math.floor(owned*100/total+.5)or 0,frames=0,frameTime=0,worstFrame=0,below30=0,
        keyPresses=0,mousePresses=0,dashPresses=0},Telemetry)
end

function Telemetry:frame(dt)
    if not self.active then return end
    dt=math.max(0,tonumber(dt)or 0)
    self.frames,self.frameTime=self.frames+1,self.frameTime+dt
    self.worstFrame=math.max(self.worstFrame,dt)
    if dt>1/30 then self.below30=self.below30+1 end
end

function Telemetry:input(kind,key)
    if not self.active then return end
    if kind=="key"then
        self.keyPresses=self.keyPresses+1
        if key=="space"then self.dashPresses=self.dashPresses+1 end
    elseif kind=="mouse"then self.mousePresses=self.mousePresses+1 end
end

function Telemetry:row(result)
    local mode,a=self.mode,self.mode.actionAudit or{}
    local frameTime=math.max(.000001,self.frameTime)
    return{
        os.date("!%Y-%m-%dT%H:%M:%SZ"),self.version,self.researchPct,self.owned,self.total,buildName(mode),self.unlockedTier,
        result.startingRegenTier,result.highestRegenTier,number(result.elapsed,1),result.trees,result.lumberCoinTotal,
        result.totalTreesSpawned,result.peakActiveTrees,result.treeAllowance,number(result.peakTreesPerSecond,2),
        result.failureReason or(result.victory and"victory"or"unknown"),number(self.frames/frameTime,1),
        number(self.worstFrame>0 and 1/self.worstFrame or 0,1),number(self.worstFrame*1000,1),
        number(self.frames>0 and self.below30*100/self.frames or 0,2),self.keyPresses,self.mousePresses,self.dashPresses,
        a.scoreAxe or 0,a.cigaretteFlick or 0,a.fireworkShot or 0,a.flameTick or 0,a.bombExplosion or 0
    }
end

function Telemetry:finish(result)
    if not self.active then return false end
    self.active=false
    if not love or not love.filesystem or not love.filesystem.append or not love.filesystem.getInfo then return false end
    local exists=love.filesystem.getInfo(Telemetry.FILE,"file")~=nil
    local lines={}
    if not exists then lines[#lines+1]=table.concat(Telemetry.COLUMNS,",")end
    local encoded={};for index,value in ipairs(self:row(result))do encoded[index]=csv(value)end
    lines[#lines+1]=table.concat(encoded,",")
    return love.filesystem.append(Telemetry.FILE,table.concat(lines,"\n").."\n")
end

return Telemetry
