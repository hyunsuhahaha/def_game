extern vec4 sourceRect;
extern vec4 bodyRect;
extern vec2 sourceSize;
extern number cellSize;
extern number phase;
extern number actionRow;
extern number rigKind;
extern Image paletteLut;
extern Image sourceMask;

float bayer(vec2 p) {
    vec2 b=mod(p,4.0);
    return (4.0*(2.0*mod(b.x,2.0)+mod(b.y+b.x,2.0))
        +2.0*floor(b.x/2.0)+mod(floor(b.y/2.0)+floor(b.x/2.0),2.0)+0.5)/16.0-0.5;
}
vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen) {
    vec2 pixel=floor(uv*cellSize)+0.5;
    vec2 q=(pixel-bodyRect.xy)/bodyRect.zw;
    vec2 original=q;
    float cycle=sin(phase*6.2831853+0.22);
    float pulse=sin(phase*3.1415927);
    float upper=1.0-smoothstep(0.55,1.0,q.y);
    if (actionRow<0.5) {
        if (rigKind<1.5) {
            // Opposing fore/hind paw shifts with torso and tail kept coherent.
            float paws=smoothstep(0.67,0.96,q.y);
            float side=q.x<0.5 ? -1.0 : 1.0;
            q.x-=cycle*paws*side*0.018;
            q.y+=max(0.0,cycle*side)*paws*0.018;
            q.y-=sin(phase*12.56637)*upper*0.003;
            if (rigKind<0.5 && q.x<0.45) q.x-=cycle*upper*(0.45-q.x)*0.035;
        } else {
            // Roots stay fixed; cap, cloak, branches and canopy breathe above them.
            q.x-=cycle*upper*0.008;
            q.y-=cycle*upper*0.004;
        }
    } else {
        // One locked identity, a forward wind-up/release/recovery arc.
        q.x-=pulse*upper*0.025;
        q.y+=pulse*upper*0.012;
        if (rigKind>3.5 && q.x>0.68) q.y+=pulse*upper*0.035;
        if (rigKind>1.5 && rigKind<3.5) q.y=0.48+(q.y-0.48)/(1.0+pulse*upper*0.035);
    }
    if (q.x<0.0 || q.y<0.0 || q.x>=1.0 || q.y>=1.0) return vec4(0.0);
    if (Texel(sourceMask,q).r<0.5) return vec4(0.0);
    vec2 source=(sourceRect.xy+q*sourceRect.zw)/sourceSize;
    vec4 sampleColor=Texel(tex,source);
    if (sampleColor.a<0.62) return vec4(0.0);
    // Remove concept-board spore FX; projectiles are their own game layer.
    if (rigKind==2.0 && q.x>0.72 && q.y>0.50 && q.y<0.77
        && sampleColor.r>0.75 && sampleColor.g>0.58 && sampleColor.b<0.30) return vec4(0.0);
    // At the shared board boundary, retain crown leaves, not the previous row's roots.
    if (rigKind==6.0 && q.y<0.055 && sampleColor.g<sampleColor.r*0.58) return vec4(0.0);
    vec3 rgb=sampleColor.rgb;
    float lum=dot(rgb,vec3(0.2126,0.7152,0.0722));
    rgb=mix(vec3(lum),rgb,0.83);
    rgb*=vec3(0.98,0.99,1.0);
    // Fine shared upper-left illumination; no black stroke or broad wash.
    rgb*=1.025-0.045*original.x-0.025*original.y;
    // Eliminate bright chroma fringe pixels without introducing a black outline.
    if (rgb.r>0.72 && rgb.g<0.14 && rgb.b<0.12) rgb=vec3(0.39,0.20,0.12);
    rgb=clamp(rgb+bayer(pixel)/96.0,0.0,1.0);
    vec3 idx=floor(rgb*31.0+0.5);
    vec2 lutUV=vec2((idx.r+0.5)/32.0,(idx.g+idx.b*32.0+0.5)/1024.0);
    return vec4(Texel(paletteLut,lutUV).rgb,1.0)*color;
}
