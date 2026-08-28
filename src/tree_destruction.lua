local TreeDestruction={}

function TreeDestruction.damageStage(hp,maxHp)
    if not maxHp or maxHp<=0 then return 0 end
    local lost=1-math.max(0,hp or maxHp)/maxHp
    return lost>=.72 and 3 or lost>=.38 and 2 or lost>0 and 1 or 0
end

function TreeDestruction.fallProfile(maxHp)
    maxHp=maxHp or 5
    if maxHp<=4 then return {duration=.20,reach=132,breakScale=.24} end
    if maxHp>=9 then return {duration=.64,reach=106,breakScale=.34} end
    return {duration=.44,reach=116,breakScale=.30}
end

return TreeDestruction
