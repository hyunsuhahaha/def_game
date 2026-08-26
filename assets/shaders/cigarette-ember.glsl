extern number emberTime;
vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen) {
    vec4 pixel = Texel(tex, uv);
    float hot = smoothstep(0.87,0.99,uv.x) * step(pixel.g * 1.45,pixel.r);
    float pulse = 0.72 + 0.28 * sin(emberTime * 5.0 + floor(uv.y*48.0)*0.17);
    pixel.rgb += vec3(0.12,0.035,0.006) * hot * pulse;
    // Retain fine discrete shade steps even while the ember breathes.
    pixel.rgb = floor(clamp(pixel.rgb,0.0,1.0)*63.0+0.5)/63.0;
    return pixel * color;
}
