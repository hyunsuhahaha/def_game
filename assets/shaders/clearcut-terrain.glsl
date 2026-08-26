// World-anchored native pixel materials, stepped ramps and moving shore bands.
extern vec2 worldSize;
extern vec2 islandRadii;
extern vec2 terrainOrigin;
extern vec2 terrainSize;
extern number biome;
extern number clock;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float field(vec2 p){
    vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
    return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
vec4 effect(vec4 tint,Image tex,vec2 uv,vec2 screen){
    vec2 p=floor((terrainOrigin+uv*terrainSize)*2.0)/2.0;
    float dither=(mod(p.x*2.0,2.0)+mod(p.y*2.0,2.0)*2.0-1.5)/64.0;
    float patch=field(p/95.0)*.65+field(p/23.0)*.25;
    float fine=Texel(tex,fract(p/768.0)).g;
    float shade=floor(clamp(patch*.72+fine*.22+dither,0.0,1.0)*16.0)/15.0;
    vec3 grass=mix(vec3(.18,.26,.105),vec3(.43,.48,.205),shade);
    float shore=1000.0;
    if(biome<1.5){
        shore=min(abs(p.x-(worldSize.x*.32+sin(p.y/240.0)*110.0))-72.0,
                  abs(p.y-(worldSize.y*.65+sin(p.x/340.0)*125.0))-90.0);
        grass=mix(vec3(.12,.24,.17),vec3(.35,.45,.235),shade);
        if(shore<27.0) grass=mix(vec3(.23,.24,.15),vec3(.44,.39,.235),shade);
    }else if(biome<2.5){
        float trail=abs(p.y-worldSize.y*.48-sin(p.x/330.0)*145.0);
        vec3 dirt=mix(vec3(.34,.16,.095),vec3(.67,.365,.19),shade);
        float scrub=step(.52,patch+min(trail/1100.0,.15));
        grass=mix(dirt,mix(vec3(.28,.28,.105),vec3(.53,.47,.19),shade),scrub*.8);
        // Sparse erosion seams, aligned with the red earth's broad terrain forms.
        float seam=abs(sin(p.x*.013+sin(p.y*.009)*2.0));
        if(seam<.021 && patch>.55)grass*=.87;
    }else{
        vec2 q=(p-worldSize*.5)/islandRadii;
        float a=atan(q.y,q.x);
        float dist=length(q)/(1.0+.065*sin(a*3.0+.4)+.035*cos(a*5.0));
        shore=(1.0-dist)*islandRadii.y;
        if(shore<45.0)grass=mix(vec3(.64,.49,.28),vec3(.86,.75,.47),shade);
        else grass=mix(vec3(.20,.31,.13),vec3(.48,.53,.225),shade);
    }
    if(shore<0.0){
        float depth=clamp(-shore/(biome>2.5?170.0:95.0),0.0,1.0);
        depth=floor(depth*16.0+dither)/16.0;
        vec3 shallow=biome>2.5?vec3(.16,.55,.56):vec3(.15,.37,.32);
        vec3 deep=biome>2.5?vec3(.045,.20,.32):vec3(.07,.23,.235);
        vec3 water=mix(shallow,deep,depth);
        float wave=sin(p.y*.085+sin(p.x*.026)*1.8-clock*1.6);
        float streak=step(.94,wave)*step(.38,field(p/48.0));
        water+=streak*.045;
        float band=mod(-shore+clock*9.0,34.0);
        if(shore> -64.0 && band<2.2 && field(p/28.0)>.36)water=mix(water,vec3(.69,.83,.70),.55);
        if(shore> -3.0)water=mix(water,vec3(.68,.79,.59),.58);
        grass=water;
    }
    return vec4(grass,1.0)*tint;
}
