extern float clock;
vec4 effect(vec4 color, Image image, vec2 uv, vec2 pixel) {
    vec2 world=uv*9.0-4.0;
    vec2 rawUV=vec2(.18,.19)+world*vec2(.54,.54);
    vec2 sampleUV=clamp(1.0-abs(mod(rawUV,2.0)-1.0),vec2(.001),vec2(.999));
    vec4 surface=Texel(image,sampleUV);
    // Only the open water beyond the shoreline moves; land stays registered.
    if(sampleUV.x>.90 && sampleUV.y>.22) {
        float ripple=step(.92,fract(floor(sampleUV.y*941.0)*.13+clock*.22));
        surface.rgb+=vec3(.014,.020,.020)*ripple;
    }
    return surface*color;
}
