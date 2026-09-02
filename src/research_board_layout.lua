local ResearchBoardLayout={}

ResearchBoardLayout.ROOT_ID="fire_score_prewarm"
ResearchBoardLayout.CENTER={x=15000,y=12000}
ResearchBoardLayout.CATEGORIES={
    cigarette={x=15000,y=6000,dx=0,dy=-1,step=500,spread=400},
    axe={x=8000,y=7000,dx=-.82,dy=-.57,step=500,spread=410},
    firework={x=5000,y=12000,dx=-1,dy=0,step=500,spread=420},
    flame={x=8000,y=17500,dx=-.78,dy=.63,step=510,spread=420},
    companions={x=22000,y=7000,dx=.82,dy=-.57,step=500,spread=420},
    facilities={x=25000,y=12000,dx=1,dy=0,step=500,spread=420},
    field={x=22000,y=17500,dx=.78,dy=.63,step=510,spread=420},
}

local function categoryId(store,node)
    local category=store.getResearchCategory and store:getResearchCategory(node)
    return category and category.id or node.researchCategory
end

local function requirements(store,node)
    return store.getRequirements and store:getRequirements(node)or node.requires or{}
end

function ResearchBoardLayout.build(store,nodes)
    local positions={[ResearchBoardLayout.ROOT_ID]={ResearchBoardLayout.CENTER.x,ResearchBoardLayout.CENTER.y}}
    local byId,categoryOf={},{}
    for _,node in ipairs(nodes)do
        byId[node.id]=node
        categoryOf[node.id]=categoryId(store,node)
    end

    local categoryRoots={}
    for id,spec in pairs(ResearchBoardLayout.CATEGORIES)do
        local members={}
        for _,node in ipairs(nodes)do
            if node.id~=ResearchBoardLayout.ROOT_ID and categoryOf[node.id]==id then members[#members+1]=node end
        end
        table.sort(members,function(a,b)
            if(a.researchOrder or 0)~=(b.researchOrder or 0)then return(a.researchOrder or 0)<(b.researchOrder or 0)end
            return a.id<b.id
        end)

        local memo,visiting={},{}
        local function depth(node)
            if memo[node.id]then return memo[node.id]end
            if visiting[node.id]then return 1 end
            visiting[node.id]=true
            local best,hasParent=0,false
            for _,requirement in ipairs(requirements(store,node))do
                local parent=byId[requirement[1]]
                if parent and parent.id~=ResearchBoardLayout.ROOT_ID and categoryOf[parent.id]==id then
                    hasParent=true
                    best=math.max(best,depth(parent))
                end
            end
            visiting[node.id]=nil
            memo[node.id]=(hasParent and best+1 or 1)
            return memo[node.id]
        end

        local levels,maxDepth={},0
        for _,node in ipairs(members)do
            local d=depth(node)
            levels[d]=levels[d]or{}
            levels[d][#levels[d]+1]=node
            maxDepth=math.max(maxDepth,d)
        end
        categoryRoots[id]={}
        for _,node in ipairs(members)do if depth(node)==1 then categoryRoots[id][#categoryRoots[id]+1]=node end end

        local px,py=-spec.dy,spec.dx
        local slotById={}
        for d=1,maxDepth do
            local level=levels[d]or{}
            table.sort(level,function(a,b)
                local function parentCenter(node)
                    local total,count=0,0
                    for _,requirement in ipairs(requirements(store,node))do
                        if slotById[requirement[1]]then total=total+slotById[requirement[1]];count=count+1 end
                    end
                    return count>0 and total/count or 0
                end
                local ac,bc=parentCenter(a),parentCenter(b)
                if ac~=bc then return ac<bc end
                if(a.researchOrder or 0)~=(b.researchOrder or 0)then return(a.researchOrder or 0)<(b.researchOrder or 0)end
                return a.id<b.id
            end)
            local middle=(#level+1)/2
            for index,node in ipairs(level)do
                local along=300+d*spec.step
                local across=(index-middle)*spec.spread
                slotById[node.id]=index-middle
                positions[node.id]={
                    math.floor(spec.x+spec.dx*along+px*across+.5),
                    math.floor(spec.y+spec.dy*along+py*across+.5),
                }
            end
        end
    end
    return{positions=positions,categories=ResearchBoardLayout.CATEGORIES,categoryRoots=categoryRoots,
        center=ResearchBoardLayout.CENTER,rootId=ResearchBoardLayout.ROOT_ID,categoryOf=categoryOf}
end

return ResearchBoardLayout
