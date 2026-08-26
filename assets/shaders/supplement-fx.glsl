// Native-grid skill FX. All material/alpha ramps are stepped; no blurred circles.
extern vec2 gridSize;
extern number effectKind;
extern number clock;
extern number progress;
extern number variant;
extern number strength;
extern number boundary;
const float TAU=6.2831853;
float hash(float x){return fract(sin(x*127.1+311.7)*43758.5453);}
float noise(vec2 p){
    vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
    return mix(mix(hash(i.x+i.y*57.0),hash(i.x+1.0+i.y*57.0),f.x),
        mix(hash(i.x+(i.y+1.0)*57.0),hash(i.x+1.0+(i.y+1.0)*57.0),f.x),f.y);
}
vec3 ramp(vec3 low,vec3 high,float v){return mix(low,high,floor(clamp(v,0.0,1.0)*15.0)/15.0);}
vec4 effect(vec4 tint,Image tex,vec2 uv,vec2 screen){
    vec2 pixel=floor(uv*gridSize);
    vec2 q=(pixel+.5)/gridSize*2.0-1.0;
    float r=length(q),a=atan(q.y,q.x),p=clamp(progress,0.0,1.0);
    float grain=(mod(pixel.x,2.0)+2.0*mod(pixel.y,2.0)-1.5)/80.0;
    vec3 rgb=vec3(0.0);float alpha=0.0;
    if(effectKind<1.5){
        // Two braided woody vines, clustered thorns and a tick-synchronised flare.
        float bend=sin(a*11.0+clock*.5)*.026;
        float vine=min(abs(r-(boundary-.22+bend)),abs(r-(boundary-.22-bend)));
        float along=clamp((r-boundary+.25)/.25,0.0,1.0);
        float tooth=abs(fract((a/TAU+.5)*17.0+along*.24)-.5)*2.0;
        float thorn=step(boundary-.25,r)*step(r,boundary)*step(tooth,(1.0-along)*.74);
        float body=max(1.0-step(.033,vine),thorn);
        float facet=clamp(.76-q.y*.17-vine*11.0+grain,0.0,1.0);
        rgb=ramp(vec3(.09,.16,.08),vec3(.63,.78,.29),facet);
        if(thorn>.5)rgb=ramp(vec3(.18,.25,.09),vec3(.93,.93,.53),along*.68+(1.0-tooth)*.26+grain);
        alpha=body*(.58+.42*strength);
        float flare=(1.0-step(.022,abs(r-(boundary-.04-p*.10))))*strength*(1.0-p);
        if(flare>0.0){rgb=ramp(vec3(.28,.53,.15),vec3(.90,1.0,.62),.7+grain);alpha=max(alpha,flare*.7);}
    }else if(effectKind<2.5){
        // A tapered curved vine plus its scything leaf edge. Angle is local +X.
        float head=-.66+p*1.30;
        float curve=head+(1.0-r)*.72+sin(r*8.0-p*3.0)*.045;
        float d=abs(a-curve)*max(r,.09);
        float width=.024+(1.0-r)*.023;
        float vine=step(d,width)*step(.08,r)*step(r,boundary)*step(abs(a),.77);
        float facet=1.0-d/width;
        rgb=ramp(vec3(.09,.18,.08),vec3(.72,.90,.35),facet+grain);
        alpha=vine*(1.0-p*.65);
        float slash=step(head-.40,a)*step(a,head)*step(.50,r)*step(r,boundary)*step(abs(a),.75);
        float edge=1.0-step(.025,abs(r-(boundary-.035)));
        if(slash>0.0 && (edge>.5 || d<.12)){
            rgb=ramp(vec3(.21,.41,.13),vec3(.91,1.0,.67),edge*.85+grain);
            alpha=max(alpha,(edge*.7+.18)*(1.0-p));
        }
        float barb=fract(r*9.0);
        float thornWidth=width+(1.0-barb)*.070;
        float thorns=step(.18,barb)*step(barb,.82)*step(d,thornWidth)*step(abs(a),.75)*step(r,boundary)*step(.22,r);
        if(thorns>.5 && vine<.5){rgb=ramp(vec3(.13,.25,.09),vec3(.66,.85,.30),1.0-d/thornWidth+grain);alpha=max(alpha,(1.0-p)*.85);}
        // Full-cone contact flash is immediate; the moving vine is its follow-through.
        float contact=step(abs(a),.75)*step(r,boundary)*step(.18,r)*max(0.0,1.0-p*4.5);
        if(contact>0.0 && vine<.5 && thorns<.5){rgb=vec3(.63,.83,.36);alpha=max(alpha,contact*.10);}
    }else if(effectKind<3.5){
        // Seed shell burst: bright fracture, leaf petals, soil shards and shock front.
        float edge=.20+.70*sqrt(p);
        float lobes=sin(a*9.0+variant)*.045*(1.0-p);
        float ring=(1.0-step(.055*(1.0-p)+.012,abs(r-edge-lobes)))*step(.28,fract(a*3.1+variant));
        float rays=pow(max(0.0,cos(a*9.0+variant)),9.0)*step(.1,r)*step(r,.93)*step(r,.25+p);
        float cell=floor((a/TAU+.5)*18.0);
        float localAngle=fract((a/TAU+.5)*18.0);
        float taper=1.0-abs(localAngle-.5)*2.0;
        float shard=step(abs(r-(.23+p*(.45+hash(cell)*.32))),(.045+.06*taper)*(1.0-p));
        shard*=step(.23,localAngle)*step(localAngle,.78);
        float core=step(r,(.07+.21*pow(abs(cos(a*5.0)),7.0))*(1.0-p))*max(0.0,1.0-p*3.0);
        float dust=step(r,edge)*step(.12,r)*step(.51,noise(q*14.0+variant))*(1.0-p)*.25;
        alpha=max(max(ring*(1.0-p)*.55,rays*(1.0-p)*.7),max(max(shard,core),dust));
        rgb=ramp(vec3(.32,.19,.08),vec3(.93,.83,.34),ring*.65+rays*.4+grain);
        if(shard>.5){
            rgb=ramp(vec3(.27,.15,.06),vec3(.93,.71,.29),taper*.65+hash(cell)*.3+grain);
            if(mod(cell,3.0)<1.0)rgb=ramp(vec3(.17,.32,.12),vec3(.70,.87,.31),taper*.7+grain);
        }
        if(core>.05)rgb=vec3(1.0,.97,.72);
    }else if(effectKind<4.5){
        // Endpoint-locked zigzag channel. Animated knots cannot move the hit points.
        float u=(q.x+1.0)*.5;
        float knots=u*9.0;
        float tick=floor(clock*22.0);
        float wave=mix(hash(floor(knots)+variant*13.0+tick),hash(floor(knots)+1.0+variant*13.0+tick),fract(knots))-.5;
        float center=wave*.95*sin(u*3.1415927);
        float d=abs(q.y-center);
        float fade=1.0-p;
        alpha=(1.0-step(.14,d))*.40*fade;
        rgb=vec3(.18,.43,.83);
        if(d<.064){rgb=ramp(vec3(.27,.66,.94),vec3(.78,.96,1.0),1.0-d/.064+grain);alpha=.95*fade;}
        if(d<.022){rgb=vec3(.96,1.0,1.0);alpha=fade;}
        float branch=abs(q.y-(center+(u-.5)*1.7));
        if(u>.28 && u<.70 && branch<.025){rgb=vec3(.39,.75,.97);alpha=max(alpha,.5*fade);}
    }else if(effectKind<5.5){
        // Rolling lobes, shaded interiors and motes: a cloud, not a purple disk.
        float field=0.0;
        for(int i=0;i<7;i++){
            float fi=float(i),ang=fi*TAU/7.0+clock*.22;
            vec2 center=vec2(cos(ang),sin(ang))*(.38+.07*sin(clock+fi));
            field=max(field,1.0-length((q-center)/vec2(.44,.40)));
        }
        field=max(field,1.0-length(q/vec2(.59,.55)));
        float n=noise(q*8.0+vec2(clock*.4,-clock*.6));
        float shade=field*.55+(1.0-q.y)*.18+n*.23;
        rgb=ramp(vec3(.19,.11,.29),vec3(.86,.66,.91),shade+grain);
        alpha=step(.03,field)*(.36+floor(clamp(field*.6+n*.22,0.0,1.0)*8.0)/16.0);
        // Discrete scalloped rim and shaded lobes, not a blurred transparent disc.
        if(field>.03 && field<.12){rgb=vec3(.28,.18,.36);alpha=.54;}
        if(field>.14 && field<.20 && q.y<.1){rgb=vec3(.66,.47,.74);alpha=.67;}
        vec2 motes=floor((q+vec2(clock*.06,-clock*.12))*15.0);
        float dotty=step(.973,hash(motes.x+motes.y*73.0+variant));
        if(dotty>.5 && r<.92){rgb=vec3(.76,.94,.40);alpha=.8;}
        if(r>boundary)alpha=0.0;
    }else if(effectKind<6.5){
        // Feather/contact star; high contrast at the exact impact point.
        float rays=pow(abs(cos(a*4.0+variant)),16.0);
        float reach=(.22+.55*(1.0-p))*rays;
        alpha=step(r,reach)*(1.0-p);
        rgb=ramp(vec3(.25,.38,.62),vec3(.90,.97,1.0),1.0-r+grain);
        if(variant>3.0)rgb=ramp(vec3(.47,.33,.08),vec3(1.0,.91,.49),1.0-r+grain);
    }else{
        // Seed germination cracks and short root marks; never a fake damage circle.
        float ray=pow(max(0.0,cos(a*7.0+variant)),20.0);
        float reach=.25+p*.48;
        float mark=step(r,reach)*step(.13,r)*step(abs(sin(a*7.0+variant)),.13);
        alpha=mark*(.30+p*.55);
        rgb=ramp(vec3(.26,.18,.07),vec3(.86,.72,.25),r+grain);
        if(r<.20 && p>.65){rgb=vec3(1.0,.87,.42);alpha=.6+ray*.3;}
    }
    alpha=floor(clamp(alpha,0.0,1.0)*15.0+.5)/15.0;
    return vec4(rgb,alpha)*tint;
}
