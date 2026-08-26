extern number hitFlash;
extern number ragePulse;
vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen) {
    vec4 pixel=Texel(tex,uv);
    // Preserve each species' authored colours: elites have separate artwork.
    pixel.rgb=mix(pixel.rgb,vec3(1.0,0.89,0.67),hitFlash*0.55);
    float ember=step(pixel.g*1.6,pixel.r)*step(0.64,pixel.r);
    pixel.rgb+=vec3(0.06,0.018,0.0)*ember*ragePulse;
    return pixel*color;
}
