extern number smokeTime;
extern number smokeFacing;
vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen) {
    // Fine, fixed pixel grid: curled strands, not a column of large square puffs.
    vec2 grid = floor(uv * vec2(192.0,384.0));
    vec2 p = (grid+0.5)/vec2(192.0,384.0);
    float age = 1.0-p.y;
    float center = 0.5 + age*(0.16*sin(age*10.0-smokeTime*1.2)
        + 0.09*sin(age*22.0-smokeTime*1.8)) + age*0.06*smokeFacing;
    float width = 0.025 + age*0.045;
    float strand = exp(-pow((p.x-center)/width,2.0));
    float veil = exp(-pow((p.x-center-age*0.07)/(width*1.8),2.0));
    float alpha = (strand*0.29+veil*0.09)*pow(1.0-age,0.7)*smoothstep(0.0,0.035,age);
    float dither = mod(grid.x+grid.y*3.0,4.0)/4.0-0.5;
    alpha = floor(clamp(alpha+dither/32.0,0.0,1.0)*32.0)/32.0;
    if (alpha<=0.0) return vec4(0.0);
    float shade=floor(strand*5.0)/5.0;
    return vec4(mix(vec3(0.49,0.51,0.48),vec3(0.82,0.83,0.78),shade),alpha)*color;
}
