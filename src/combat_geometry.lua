-- Shared combat footprints. Rendering may use a perspective ground pass or an
-- upright billboard, but gameplay always compares the same authored world
-- envelope plus the visible target body radius.
local Geometry={PLAYER_RADIUS=18}

function Geometry.targetRadius(target,override)
    if override then return override end
    if not target then return 0 end
    if target.combatRadius then return target.combatRadius end
    local def=target.def
    return def and (def.hitRadius or def.radius) or 0
end

function Geometry.circleOverlapsTarget(x,y,radius,target,override)
    local body=Geometry.targetRadius(target,override)
    local dx,dy=target.x-x,target.y-y
    local reach=radius+body
    return dx*dx+dy*dy<=reach*reach
end

function Geometry.segmentDistanceSquared(px,py,ax,ay,bx,by)
    local vx,vy=bx-ax,by-ay;local length2=vx*vx+vy*vy
    if length2<=.000001 then return (px-ax)^2+(py-ay)^2 end
    local u=math.max(0,math.min(1,((px-ax)*vx+(py-ay)*vy)/length2))
    return (px-(ax+vx*u))^2+(py-(ay+vy*u))^2
end

function Geometry.sweptCircleOverlapsTarget(ax,ay,bx,by,radius,target,override)
    local reach=radius+Geometry.targetRadius(target,override)
    return Geometry.segmentDistanceSquared(target.x,target.y,ax,ay,bx,by)<=reach*reach
end

function Geometry.ellipseOverlapsTarget(x,y,radiusX,radiusY,target,override)
    local body=Geometry.targetRadius(target,override)
    local rx,ry=radiusX+body,radiusY+body
    local dx,dy=target.x-x,target.y-y
    return dx*dx/(rx*rx)+dy*dy/(ry*ry)<=1
end

function Geometry.coneOverlapsTarget(x,y,angle,range,halfAngle,target,override)
    local dx,dy=target.x-x,target.y-y;local distance=math.sqrt(dx*dx+dy*dy)
    local body=Geometry.targetRadius(target,override)
    if distance>range+body then return false end
    if distance<=body then return true end
    local targetAngle=math.atan2 and math.atan2(dy,dx) or math.atan(dy,dx)
    local difference=math.abs((targetAngle-angle+math.pi)%(math.pi*2)-math.pi)
    return difference<=halfAngle+math.asin(math.min(1,body/distance))
end

return Geometry
