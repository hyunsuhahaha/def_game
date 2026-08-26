// Native 256x64 discarded cigarette: cork, shortened paper, char and broken ash.
float grain(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
vec3 ramp(vec3 a,vec3 b,float light,vec2 p){
    float d=(mod(p.x,2.0)+mod(p.y,2.0)*2.0-1.5)/60.0;
    return mix(a,b,floor(clamp(light+d,0.0,1.0)*15.0+.5)/15.0);
}
vec4 effect(vec4 color,Image tex,vec2 uv,vec2 screen){
    vec2 p=floor(uv*vec2(256.0,64.0));
    float dy=(p.y-32.0)/22.0;
    float radius=22.0;
    if(p.x<16.0)radius*=sqrt(max(0.0,1.0-pow((16.0-p.x)/12.0,2.0)));
    if(p.x>237.0)radius*=sqrt(max(0.0,1.0-pow((p.x-237.0)/15.0,2.0)));
    float ragged=p.x>192.0?floor(grain(floor(p/3.0))*4.0):0.0;
    if(p.x<5.0||p.x>250.0||abs(p.y-32.0)>radius-ragged)return vec4(0.0);
    float light=.25+.58*sqrt(max(0.0,1.0-dy*dy))-.20*dy;
    float n=grain(p);
    vec3 rgb;
    if(p.x<98.0){
        float pore=n>.81?-.23:(n<.12?.08:0.0);
        rgb=ramp(vec3(.24,.11,.045),vec3(.98,.76,.43),light+pore,p);
        if(p.x>94.0)rgb*=.85;
    }else if(p.x<193.0+floor(grain(vec2(p.y,0))*5.0)){
        float seam=p.y==38.0&&mod(p.x,15.0)>2.0?-.13:0.0;
        float scorch=smoothstep(165.0,195.0,p.x)*.53;
        rgb=ramp(vec3(.34,.31,.26),vec3(1.0,.98,.86),light+seam-scorch+(n>.9?-.1:0.0),p);
    }else{
        float flake=grain(floor(p/vec2(4.0,3.0)));
        rgb=ramp(vec3(.07,.065,.06),vec3(.79,.78,.71),flake*.65+light*.25,p);
        if(n>.7&&flake<.6)rgb=ramp(vec3(.34,.05,.015),vec3(1.0,.79,.27),.25+(p.x-192.0)/80.0,p);
    }
    return vec4(rgb,1.0)*color;
}
