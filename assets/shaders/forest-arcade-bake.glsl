// Fixed-model authoring pass: native pixel grid, hard alpha, material ramps.
extern vec2 outputSize;
extern vec2 sourceSize;
extern vec4 sourceRect;
extern vec4 bodyRect;
extern Image paletteLut;
extern number phase;
extern number motion;
extern number actionRow;
extern number chromaKey;
extern number outlinePixels; // Opt-in for new biome assets; legacy builds keep 0.
extern number biomeRig; // Distinct anticipation/contact poses; legacy builds keep 0.
extern number flightRig; // Opt-in wing folding; fixed central body, no whole-body scaling.

bool background(vec4 c) {
    return c.a < 0.7 || (chromaKey > 0.5 && c.r > c.g * 1.8 + 0.18 && c.b > c.g * 1.8 + 0.18);
}
vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen) {
    vec2 p = floor(uv * outputSize) + 0.5;
    vec2 q = (p - bodyRect.xy) / bodyRect.zw;
    vec2 rest = q;
    float upper = 1.0 - smoothstep(0.60, 1.0, q.y);
    float wave = sin(phase * 6.2831853 + 0.22);
    if (flightRig > .5) {
        float wing = smoothstep(.10,.24,abs(q.x-.5));
        float reach = .77 + .23 * wave;
        q.x = .5 + (q.x-.5) / mix(1.0,reach,wing);
        q.y += wing * wave * .045;
    }
    if (motion > 0.5) {
        if (actionRow > 0.5) {
            float attack = sin(phase * 3.1415927);
            q.x -= attack * upper * 0.035;
            q.y += attack * upper * 0.035;
            q.x -= biomeRig * phase * upper * 0.022;
        } else if (motion < 1.5) {
            float side = q.x < 0.5 ? -1.0 : 1.0;
            float paws = smoothstep(0.70, 0.96, q.y);
            q.x -= wave * paws * side * 0.018;
            q.y += max(0.0, wave * side) * paws * 0.024 * (1.0-smoothstep(0.94,1.0,q.y));
            q.x -= wave * upper * 0.006;
        } else {
            q.x -= wave * upper * 0.013;
            q.y -= wave * upper * 0.004;
        }
    }
    // Contact pixels stay on the authored foot plane throughout the rig cycle.
    if (rest.y > 0.98) q = rest;
    if (q.x < 0.0 || q.y < 0.0 || q.x >= 1.0 || q.y >= 1.0) return vec4(0.0);
    vec2 at = (sourceRect.xy + q * sourceRect.zw) / sourceSize;
    vec4 sampleColor = Texel(tex, at);
    if (background(sampleColor)) return vec4(0.0);
    vec3 rgb = sampleColor.rgb;
    // Keep broad model masses; a one-native-pixel rim defines the silhouette.
    vec2 stepUV = sourceRect.zw / bodyRect.zw / sourceSize;
    bool lowerEdge = background(Texel(tex, at + vec2(0.0, stepUV.y)));
    bool upperEdge = background(Texel(tex, at - vec2(0.0, stepUV.y)));
    float lum = dot(rgb, vec3(0.30, 0.59, 0.11));
    rgb = mix(vec3(lum), rgb, 0.91);
    rgb *= 1.03 - 0.055 * q.x - 0.025 * q.y;
    if (lowerEdge) rgb *= 0.82;
    if (upperEdge) rgb *= 1.07;
    if (outlinePixels > 0.5) {
        // An inset ink rim preserves the original alpha/foot plane. The final
        // material LUT keeps the line within each sprite's authored palette.
        bool ink = false;
        for (int i=1; i<=3; i++) {
            if (float(i)>outlinePixels) break;
            vec2 off=stepUV*float(i);
            ink = ink || background(Texel(tex,at+vec2(off.x,0.0)))
                      || background(Texel(tex,at-vec2(off.x,0.0)))
                      || background(Texel(tex,at+vec2(0.0,off.y)))
                      || background(Texel(tex,at-vec2(0.0,off.y)));
        }
        if (ink) rgb *= 0.46;
    }
    // Ordered sub-shade coverage, no random noise or blurred alpha.
    float d = (mod(p.x, 2.0) + 2.0 * mod(p.y, 2.0) - 1.5) / 160.0;
    vec3 index = floor(clamp(rgb + d, 0.0, 1.0) * 31.0 + 0.5);
    vec2 lookup = vec2((index.r + 0.5) / 32.0, (index.g + index.b * 32.0 + 0.5) / 1024.0);
    return vec4(Texel(paletteLut, lookup).rgb, 1.0) * color;
}
