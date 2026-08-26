// Authoring shader: 256 x 48 discrete pixels, material-specific shaded ramps.
// Render once into the equipment sprite. No enlarged four-colour atlas fragment.
float grain(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float orderedDither(vec2 p) {
    vec2 b = mod(p, 4.0);
    float lo = 2.0 * mod(b.x, 2.0) + mod(b.y + b.x, 2.0);
    float hi = 2.0 * floor(b.x / 2.0) + mod(floor(b.y / 2.0) + floor(b.x / 2.0), 2.0);
    return (4.0 * lo + hi + 0.5) / 16.0 - 0.5;
}
vec3 ramp(vec3 shadow, vec3 light, float shade, vec2 pixel) {
    float level = floor(clamp(shade + orderedDither(pixel) / 15.0, 0.0, 1.0) * 15.0 + 0.5) / 15.0;
    return mix(shadow, light, level);
}
vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen) {
    vec2 p = floor(uv * vec2(256.0, 48.0));
    float x = p.x;
    float center = 24.0;
    float dy = (p.y - center) / 16.0;
    float radius = 16.0;
    if (x < 10.0) radius *= sqrt(max(0.0, 1.0 - pow((10.0 - x) / 7.0, 2.0)));
    if (x > 244.0) radius *= sqrt(max(0.0, 1.0 - pow((x - 244.0) / 9.0, 2.0)));
    float edge = grain(vec2(x, floor(p.y / 3.0))) > 0.78 ? 1.0 : 0.0;
    if (x < 4.0 || x > 251.0 || abs(p.y - center) > radius - edge) return vec4(0.0);

    // Cylindrical lighting, upper highlight and darker lower rim.
    float roundness = sqrt(max(0.0, 1.0 - dy * dy));
    float light = 0.26 + 0.53 * roundness - 0.22 * dy;
    float noise = grain(p);
    vec3 rgb;
    if (x < 60.0) {
        // Cork: fine pores, warm fibres, dark bottom edge.
        float pores = noise > 0.82 ? -0.22 : (noise < 0.13 ? 0.10 : 0.0);
        rgb = ramp(vec3(0.25,0.115,0.055), vec3(0.98,0.76,0.40), light + pores, p);
    } else if (x < 221.0 + floor(grain(vec2(p.y, 1.0))*3.0)) {
        // Paper: ivory highlight, cool shadow, thin wrap seam and tiny fibres.
        float fibre = noise > 0.90 ? -0.09 : (noise < 0.06 ? 0.05 : 0.0);
        float seam = p.y == 29.0 && mod(x, 13.0) > 1.0 ? -0.10 : 0.0;
        float scorch = smoothstep(212.0,225.0,x) * 0.40;
        rgb = ramp(vec3(0.38,0.36,0.33), vec3(1.0,0.985,0.88), light + fibre + seam - scorch, p);
        if (x == 61.0 || x == 64.0) rgb *= vec3(0.93,0.84,0.65);
    } else {
        // Broken ash flakes and hot cracks; never a rectangular orange endcap.
        vec2 flake = floor(p / vec2(3.0,2.0));
        float ash = grain(flake);
        float heat = smoothstep(229.0,251.0,x);
        bool crack = noise > 0.68 && (ash < 0.55 || x > 246.0);
        rgb = ramp(vec3(0.09,0.085,0.09), vec3(0.80,0.79,0.73), ash * 0.60 + light * 0.30, p);
        if (crack) rgb = ramp(vec3(0.37,0.055,0.025),vec3(1.0,0.74,0.20),heat*.74+noise*.22,p);
    }
    return vec4(rgb,1.0) * color;
}
