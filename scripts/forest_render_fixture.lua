-- Headless graphics recorder. No engine/window boot; real World/Player/Art draw calls.
local Fixture={commands={}}
local color,shader,lineWidth={1,1,1,1},nil,1
local currentFont={path="assets/font-korean-regular.ttf",size=14}
local transform,transforms={x=0,y=0,sx=1,sy=1},{}
local function json(v)
    if type(v)=="string" then return string.format("%q",v):gsub("\\\n","\\n") end
    if type(v)=="number" or type(v)=="boolean" then return tostring(v) end
    if type(v)~="table" then return "null" end
    local out={}
    if #v>0 then for _,x in ipairs(v) do out[#out+1]=json(x) end; return "["..table.concat(out,",").."]" end
    for k,x in pairs(v) do out[#out+1]=json(k)..":"..json(x) end
    return "{"..table.concat(out,",").."}"
end
local function emit(value)
    local a=value.args
    -- LÖVE accepts both flat coordinates and one table of coordinates for
    -- line/polygon. UI capture paths use the table form.
    if (value.op=="line" or value.op=="polygon") and #a==1 and type(a[1])=="table" then
        a=a[1];value.args=a
    end
    if value.op=="draw" then
        a[1],a[2]=transform.x+a[1]*transform.sx,transform.y+a[2]*transform.sy
        local sx,sy=a[4] or 1,a[5] or a[4] or 1
        a[3],a[4],a[5]=a[3] or 0,sx*transform.sx,sy*transform.sy
    elseif value.op=="line" or value.op=="polygon" then
        for i=1,#a,2 do a[i],a[i+1]=transform.x+a[i]*transform.sx,transform.y+a[i+1]*transform.sy end
    end
    if value.op=="rectangle" or value.op=="ellipse" or value.op=="text" then
        a[1],a[2]=transform.x+a[1]*transform.sx,transform.y+a[2]*transform.sy
        a[3]=a[3]*transform.sx
        if a[4] then a[4]=a[4]*transform.sy end
        if value.size then value.size=value.size*transform.sy end
        if value.radius then value.radius=value.radius*transform.sx end
    end
    value.color={unpack(color)}; value.lineWidth=lineWidth*transform.sx
    if shader then value.shader=shader.path; value.uniforms={}; for k,v in pairs(shader.values) do value.uniforms[k]=v end end
    Fixture.commands[#Fixture.commands+1]=value
end
local function image(path)
    local file=assert(io.open(path,"rb")); local header=file:read(24); file:close()
    local function int(at) local a,b,c,d=header:byte(at,at+3); return ((a*256+b)*256+c)*256+d end
    local value={path=path,w=int(17),h=int(21),filter="linear"}
    function value:getWidth() return self.w end
    function value:getHeight() return self.h end
    function value:getDimensions() return self.w,self.h end
    function value:setFilter(filter) self.filter=filter end
    function value:setWrap(horizontal,vertical) self.wrapX,self.wrapY=horizontal,vertical end
    return value
end
local graphics={
    push=function() transforms[#transforms+1]={x=transform.x,y=transform.y,sx=transform.sx,sy=transform.sy} end,
    pop=function() transform=table.remove(transforms) end,
    translate=function(x,y) transform.x=transform.x+x*transform.sx;transform.y=transform.y+y*transform.sy end,
    rotate=function() end,
    scale=function(x,y) transform.sx=transform.sx*x;transform.sy=transform.sy*(y or x) end,
    newImage=image,newFont=function(path,size)
        if type(path)=="number" then size,path=path,"assets/font-korean-regular.ttf" end
        return {path=path,size=size,getHeight=function() return size end}
    end,
    newQuad=function(x,y,w,h,tw,th) return {x,y,w,h,tw,th} end,
    newShader=function(path) return {path=path,values={},send=function(self,k,v) self.values[k]=v end} end,
    getShader=function() return shader end,setShader=function(s) shader=s end,
    getColor=function() return unpack(color) end,
    setColor=function(r,g,b,a) color=type(r)=="table" and {r[1],r[2],r[3],r[4] or 1} or {r,g,b,a or 1} end,
    setLineWidth=function(w) lineWidth=w end,
    setLineStyle=function() end,setScissor=function()end,setBlendMode=function(mode) assert(mode=="alpha" or mode=="add") end,
    stencil=function(fn)fn()end,setStencilTest=function()end,
    setFont=function(font) currentFont=font end,
    print=function(value,x,y) emit({op="text",text=tostring(value),file=currentFont.path,size=currentFont.size,args={x,y,0},align="left"}) end,
    printf=function(value,x,y,width,align) emit({op="text",text=tostring(value),file=currentFont.path,size=currentFont.size,args={x,y,width},align=align}) end,
    draw=function(sprite,...)
        local args={...}; local quad
        if type(args[1])=="table" then quad=table.remove(args,1) end
        emit({op="draw",file=sprite.path,filter=sprite.filter,quad=quad or {0,0,sprite.w,sprite.h,sprite.w,sprite.h},args=args})
    end,
    rectangle=function(mode,x,y,w,h,radius) emit({op="rectangle",mode=mode,args={x,y,w,h},radius=radius}) end,
    ellipse=function(mode,x,y,rx,ry) emit({op="ellipse",mode=mode,args={x,y,rx,ry}}) end,
    circle=function(mode,x,y,r) emit({op="ellipse",mode=mode,args={x,y,r,r}}) end,
    polygon=function(mode,...) emit({op="polygon",mode=mode,args={...}}) end,
    line=function(...) emit({op="line",args={...}}) end,
}
love={graphics=graphics,math={random=math.random},timer={getTime=function() return Fixture.time or 0 end}}
function Fixture.save(path)
    local file=assert(io.open(path,"w")); file:write(json(Fixture.commands)); file:close()
end
function Fixture.reset() Fixture.commands={} end
return Fixture
