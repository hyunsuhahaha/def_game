extern vec2 fxGrid;
extern number fxTime;
extern number fxKind; // 0 ember, 1 flame, 2 smoke
extern number strength;
vec4 effect(vec4 color,Image tex,vec2 uv,vec2 screen){
    vec2 grid=floor(uv*fxGrid);
    vec2 p=(grid+.5)/fxGrid;
    float d=(mod(grid.x,2.0)+2.0*mod(grid.y,2.0)-1.5)/64.0;
    float alpha;vec3 rgb;
    if(fxKind<.5){
        vec2 q=(p-.5)*2.0;
        float r=length(q);
        float rays=abs(q.x*q.y)*4.0;
        float shape=exp(-r*5.5)*(1.0-rays*.6);
        alpha=floor(clamp(shape*strength*2.2+d,0.0,1.0)*12.0)/12.0;
        float hot=floor(clamp(1.0-r*2.5,0.0,1.0)*7.0)/7.0;
        rgb=mix(vec3(.82,.21,.025),vec3(1.0,.94,.62),hot);
    }else if(fxKind<1.5){
        float rise=1.0-p.y;
        float center=.5+sin(rise*11.0-fxTime*8.0)*.09*rise;
        float width=(.27*(1.0-rise)+.025)*(1.0+.15*sin(fxTime*12.0));
        float tongue=abs(p.x-center)/width;
        float edge=1.0-tongue+.14*sin(rise*33.0+fxTime*9.0);
        alpha=step(0.0,edge)*smoothstep(0.0,.10,p.y)*smoothstep(0.0,.035,rise)*strength;
        alpha=floor(clamp(alpha+d,0.0,1.0)*12.0)/12.0;
        float core=clamp((1.0-tongue)*.72+(1.0-rise)*.35,0.0,1.0);
        core=floor(core*15.0)/15.0;
        rgb=core<.5?mix(vec3(.55,.09,.015),vec3(1,.39,.035),core*2.0):mix(vec3(1,.39,.035),vec3(1,.94,.55),(core-.5)*2.0);
    }else{
        float rise=1.0-p.y;
        float center=.5+rise*(.13*sin(rise*10.0-fxTime*1.3)+.06*sin(rise*23.0-fxTime*1.9));
        float width=.035+rise*.07;
        float strand=exp(-pow((p.x-center)/width,2.0));
        float veil=exp(-pow((p.x-center-rise*.08)/(width*1.7),2.0));
        alpha=(strand*.51+veil*.12)*pow(1.0-rise,.7)*smoothstep(0.0,.025,rise)*strength;
        alpha=floor(clamp(alpha+d,0.0,1.0)*24.0)/24.0;
        rgb=mix(vec3(.38,.39,.34),vec3(.88,.87,.76),floor(strand*7.0)/7.0);
    }
    if(alpha<=0.0)return vec4(0.0);
    return vec4(rgb,alpha)*color;
}
