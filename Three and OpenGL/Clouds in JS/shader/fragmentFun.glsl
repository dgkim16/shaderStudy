uniform float iTime;
uniform vec2 iResolution;

void main() {
    vec2 uv = 2.0 * gl_FragCoord.xy / iResolution.xy;
    uv.x *= iResolution.x / iResolution.y;

    vec3 color = vec3(0.0);
    for( int i = 0; i < 128; i++ ) {
        float pha = sin(float(i) * 546.13 + 1.0) * 0.5 + 0.5;
        float siz = pow(sin(float(i) * 651.74 + 5.0) * 0.5 + 0.5, 4.0);
        float pox = sin(float(i) * 321.55 + 4.1) * iResolution.x / iResolution.y;
        float rad = 0.1 + 0.5 * siz + sin(pha + siz) / 4.0;
        vec2 pos = vec2(pox + sin(iTime / 15.0 + pha + siz), -1.0 - rad + (2.0 + 2.0 * rad) * mod(pha + 0.3 * (iTime / 7.0) * (0.2 + 0.8 * siz), 1.0));
        float dis = length(uv - pos);
        vec3 col = mix(vec3(0.194 * sin(iTime / 6.0) + 0.3, 0.2, 0.3 * pha), vec3(1.1 * sin(iTime / 9.0) + 0.3, 0.2 * pha, 0.4), 0.5 + 0.5 * sin(float(i)));
        float f = length(uv - pos) / rad;
        f = sqrt(clamp(1.0 + (sin(iTime * siz) * 0.5) * f, 0.0, 1.0));
        color += col.zyx * (1.0 - smoothstep(rad * 0.15, rad, dis));
    }

    color *= sqrt(1.5 - 0.5 * length(uv));
    gl_FragColor = vec4(color, 1.0);
}