// Bright dry upland. Broad material bands keep the field readable at crane scale.
extern vec2 worldSize;
extern vec2 terrainOrigin;
extern vec2 terrainSize;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float field(vec2 p){
    vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
    return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
vec4 effect(vec4 tint,Image tex,vec2 uv,vec2 screen){
    vec2 p=floor((terrainOrigin+uv*terrainSize)*2.0)/2.0;
    vec2 n=p/worldSize;
    float broad=field(p/260.0);
    float fine=field(p/92.0)*.50+field(p/29.0)*.22;
    float grain=Texel(tex,fract(p/768.0)).g;
    float dither=(mod(p.x*2.0,2.0)+mod(p.y*2.0,2.0)*2.0-1.5)/72.0;
    float shade=floor(clamp(fine+grain*.28+dither,0.0,1.0)*16.0)/15.0;
    vec3 grass=mix(vec3(.31,.37,.12),vec3(.58,.61,.22),shade);
    grass*=.96+broad*.07;
    float roadA=abs(n.y-(.50+sin(n.x*8.2)*.055));
    float roadB=abs(n.x-(.50+sin(n.y*7.4+1.1)*.040));
    float road=min(roadA/.050,roadB/.035);
    vec3 earth=mix(vec3(.39,.29,.14),vec3(.61,.49,.24),shade);
    grass=mix(earth,grass,smoothstep(.58,1.08,road));
    float limestone=field((p+vec2(170.0,-80.0))/390.0)-field(p/46.0)*.32;
    if(limestone>.69 && road>1.25){
        float stepShade=floor(clamp(shade+.16,0.0,1.0)*10.0)/9.0;
        grass=mix(grass,mix(vec3(.43,.43,.28),vec3(.68,.66,.42),stepShade),.11);
    }
    return vec4(grass,1.0)*tint;
}
