extern number hurt;
extern number elite;
extern number plague;
extern number emergenceCutoff;
vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen) {
    // Every enemy atlas is two cells tall. During the giant world-tree rise,
    // hide pixels still below its authored ground line instead of showing the
    // complete billboard sliding upward through the floor.
    float localV=fract(uv.y*2.0);
    if(localV>emergenceCutoff) discard;
    vec4 p=Texel(tex,uv);
    float light=dot(p.rgb,vec3(.3,.59,.11));
    // Preserve species/material identity. Elite warm highlights, not a new model.
    p.rgb=mix(p.rgb,p.rgb*vec3(1.13,.94,.72),elite*step(.28,light)*.65);
    p.rgb=mix(p.rgb,vec3(.35,.54,.2),plague*.18);
    p.rgb=mix(p.rgb,vec3(1.0,.9,.69),hurt*.65);
    return p*color;
}
