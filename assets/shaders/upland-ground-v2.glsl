extern vec2 worldSize;
extern vec2 terrainOrigin;
extern vec2 terrainSize;
vec4 effect(vec4 color, Image image, vec2 uv, vec2 screen) {
    vec2 p=(terrainOrigin+uv*terrainSize)/worldSize;
    // Fixed authored ground; mirror only the overscan beyond the playfield.
    vec2 sampleUV=clamp(1.0-abs(mod(p,2.0)-1.0),vec2(.001),vec2(.999));
    return Texel(image,sampleUV)*color;
}
