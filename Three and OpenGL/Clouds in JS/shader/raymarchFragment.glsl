uniform vec2 resolution;
uniform vec3 cPos;
uniform vec4 cameraQuaternion;
uniform float fov;

varying vec2 vUv;
varying vec3 wPos;
varying vec3 vPosition;

#define MAX_STEPS 100
#define SURFACE_DIST 0.005
#define MAX_DISTANCE 100.0

vec3 rayMarch(vec3 ro, vec3 rd) {
    float dO = 0.0;
    bool hit = false;
    vec3 color = vec3(0.1,0.1,0.25);
    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + rd.xyz * dO;
        float dS = length(p) - 1.0;
        dO += dS;
        if(ds < minDist) {
            minDist = ds;
        }
        if (dS < SURFACE_DIST) {
            color = vec3(1.0,0,0);
            hit = true;
            break;
        }
        
        if (dO > MAX_DISTANCE) {
            break;
        }
    }
    if(!hit) {
        if(minDist < 0.05) {
            color = vec3(0.1,0.1,0.1);
        }
    }
    return color;
}

void main() {
    float aspect = resolution.x / resolution.y;
    vec3 camOrigin = cPos;
    float fovMult = fov/90.0;
    vec2 screenPos = (gl_FragCoord.xy *2.0 - resolution) / resolution;
    screenPos *= aspect;
    screenPos *= fovMult;
    vec3 ray = vec3(screenPos.xy, -1.0);
    ray = quaternion_rotate(ray, cameraQuaternion);
    ray = normalize(ray);

    vec3 color = rayMarch(camOrigin, ray);
    gl_FragColor = vec4(color, 1.0);
}