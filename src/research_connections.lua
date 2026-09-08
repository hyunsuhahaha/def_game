-- Keep ordinary graph edges straight. Only detour edges which would run through
-- an unrelated node; paths are cached in world coordinates, never tied to zoom.
local Connections={}
local clearance=90
local function intersects(a,b,o)
    local lo,hi=0,1
    for axis=1,2 do
        local delta=b[axis]-a[axis]
        local low,high=o[axis]-clearance,o[axis]+clearance
        if math.abs(delta)<1e-8 then
            if a[axis]<=low or a[axis]>=high then return false end
        else
            local t1,t2=(low-a[axis])/delta,(high-a[axis])/delta
            if t1>t2 then t1,t2=t2,t1 end
            lo,hi=math.max(lo,t1),math.min(hi,t2)
            if lo>=hi-1e-8 then return false end
        end
    end
    return true
end
Connections.intersects=intersects
function Connections.new(nodes,position)
    local self={points={},cache={}}
    for _,n in ipairs(nodes)do local x,y=position(n);self.points[#self.points+1]={x,y,id=n.id}end
    return setmetatable(self,{__index=Connections})
end
function Connections:path(from,to)
    local key=from..":"..to
    if self.cache[key]then return self.cache[key]end
    local a,b,obstacles
    obstacles={}
    for _,p in ipairs(self.points)do
        if p.id==from then a=p elseif p.id==to then b=p else obstacles[#obstacles+1]=p end
    end
    assert(a and b,"research edge endpoint missing")
    local function visible(p,q)
        for _,o in ipairs(obstacles)do if intersects(p,q,o)then return false end end
        return true
    end
    if visible(a,b)then self.cache[key]={a,b};return self.cache[key]end
    local vertices={a,b}
    -- Nearby obstacle corners form a visibility graph. Include the full graph
    -- as a fallback so a long dependency can always use an outer corridor.
    for pass=1,2 do
        vertices={a,b}
        for _,o in ipairs(obstacles)do
            if pass==2 or (o[1]>=math.min(a[1],b[1])-400 and o[1]<=math.max(a[1],b[1])+400
                and o[2]>=math.min(a[2],b[2])-400 and o[2]<=math.max(a[2],b[2])+400)then
                for _,dx in ipairs({-92,92})do for _,dy in ipairs({-92,92})do
                    vertices[#vertices+1]={o[1]+dx,o[2]+dy}
                end end
            end
        end
        local distances,previous,visited={[1]=0},{},{}
        while true do
            local current,best=nil,math.huge
            for i=1,#vertices do if not visited[i]and (distances[i]or math.huge)<best then current,best=i,distances[i]end end
            if not current then break end
            if current==2 then
                local path={};local index=2
                while index do table.insert(path,1,vertices[index]);index=previous[index]end
                self.cache[key]=path;return path
            end
            visited[current]=true
            local p=vertices[current]
            for i,q in ipairs(vertices)do if not visited[i]then
                local distance=best+math.sqrt((p[1]-q[1])^2+(p[2]-q[2])^2)
                if distance<(distances[i]or math.huge)and visible(p,q)then distances[i],previous[i]=distance,current end
            end end
        end
    end
    error("No unobstructed research connection: "..key)
end
return Connections
