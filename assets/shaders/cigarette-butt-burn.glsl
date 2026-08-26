extern number burnProgress;
extern number heat;
extern number emberTime;
vec4 effect(vec4 color,Image tex,vec2 uv,vec2 screen){
    vec2 p=floor(uv*vec2(256.0,64.0));
    vec4 c=Texel(tex,(p+.5)/vec2(256.0,64.0));
    float endX=.982-burnProgress*.18;
    if(uv.x>endX)return vec4(0.0);
    float noise=fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);
    float charStart=.73-burnProgress*.18;
    if(uv.x>charStart){
        float shade=floor((.24+noise*.64)*15.0)/15.0;
        c.rgb=mix(vec3(.09,.075,.06),vec3(.73,.69,.59),shade);
        if(noise>.65&&uv.x>endX-.065){
            float pulse=.6+.4*sin(emberTime*9.0+p.y*.23);
            vec3 hot=mix(vec3(.68,.16,.025),vec3(1,.88,.46),floor(pulse*7.0)/7.0);
            c.rgb=mix(c.rgb,hot,heat);
        }
    }
    if(heat<.01)c.rgb=mix(c.rgb,vec3(dot(c.rgb,vec3(.3,.59,.11))),.6)*.68;
    return c*color;
}
