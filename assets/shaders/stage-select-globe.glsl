extern number globeYaw;
extern number globePitch;

vec4 effect(vec4 tint, Image worldMap, vec2 uv, vec2 screenCoords) {
    vec2 p = (uv - vec2(0.5)) * 2.0;
    float rr = dot(p, p);
    if (rr > 1.0) return vec4(0.0);

    vec3 camera = vec3(p.x, -p.y, sqrt(max(0.0, 1.0 - rr)));
    float cp = cos(globePitch), sp = sin(globePitch);
    vec3 unpitched = vec3(camera.x, cp * camera.y + sp * camera.z, -sp * camera.y + cp * camera.z);
    float cy = cos(globeYaw), sy = sin(globeYaw);
    vec3 world = vec3(cy * unpitched.x + sy * unpitched.z, unpitched.y, -sy * unpitched.x + cy * unpitched.z);

    float lon = atan(world.x, world.z) / 6.28318530718 + 0.5;
    float lat = 0.5 - asin(clamp(world.y, -1.0, 1.0)) / 3.14159265359;
    vec4 base = Texel(worldMap, vec2(fract(lon), clamp(lat, 0.002, 0.998)));

    vec3 lightDir = normalize(vec3(-0.48, 0.62, 0.72));
    float diffuse = clamp(dot(camera, lightDir), 0.0, 1.0);
    diffuse = floor(diffuse * 7.0 + 0.5) / 7.0;
    float rim = pow(1.0 - camera.z, 3.0);
    float scan = mod(floor(screenCoords.y) + floor(screenCoords.x * 0.25), 4.0) < 1.0 ? 0.018 : 0.0;
    vec3 night = vec3(0.018, 0.055, 0.062);
    vec3 lit = mix(night, base.rgb, 0.43 + diffuse * 0.68);
    lit += vec3(0.06, 0.18, 0.17) * rim + scan;
    return vec4(lit, 1.0) * tint;
}
