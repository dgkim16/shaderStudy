uniform vec2 resolution;
uniform vec3 cameraPos;
uniform float u_time;

in vec4 t_fragPos;

float sdfSphere(vec3 p, float r) {
    return length(p) - r;
}

float sdfSphereM(vec3 p, float r) {
    float modX = mod(p.x+0.5,1.0)-0.5;
    float modY = mod(p.y+0.5,1.0)-0.5;
    float modZ = mod(p.z+0.5,1.0)-0.5;
    return length(vec3(modX,modY,modZ)) - r;
}

// https://www.cl.cam.ac.uk/teaching/1819/FGraphics/1.%20Ray%20Marching%20and%20Signed%20Distance%20Fields.pdf
float sdfCube(vec3 p, vec3 dim) {
    vec3 d = abs(p) - dim;
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

float sdf(vec3 p) {
    // return sdfSphere(p, 0.9);
    //return sdfSphereM(p, 0.25);
    // union min(A,B)
    //return min(sdfSphere(p, .5), sdfCube(p + vec3(1,0,0), vec3(0.5)));

    // intersection max(A,B)
    // return max(sdfSphere(p, .5), sdfCube(p, vec3(0.5)));
    return max(sdfSphereM(p, 0.1), sdfCube(p, vec3(3.5)));

    // difference max(-A,B)
    //return max(-sdfSphere(p, 0.6), sdfCube(p + vec3(0.2,0,0), vec3(0.5)));
}


void main(void) {
    vec3 fragPos = t_fragPos.xyz;
    vec2 uv = (gl_FragCoord.xy / resolution.xy) *2.0 - 0.5;
    uv.x *= resolution.x / resolution.y;

    float modY = 4.0;
    float floorParam = 0.0;
    

    vec3 dir = normalize(fragPos-cameraPos);
    vec3 p = cameraPos;
    float dist = 0.0;

    for (int i = 0; i < 100; i++) {
        
        //floorParam = (p.x + modY/2.0) / modY;
        //p.x = p.x - modY * floor(floorParam);
        //p.x = mod(p.x + 1.0, 2.0) - 1.0;
        
        //floorParam = (p.y + modY/2.0) / modY;
        //p.y = p.y - modY * floor(floorParam);
        //p.y = mod(p.y + 1.0, 2.0) - 1.0;

        //floorParam = (p.z + modY/2.0) / modY;
        //p.z = p.z - modY * floor(floorParam);
        //p.z = mod(p.z + 1.0, 2.0) - 1.0;

        dist = sdf(p);
        p = p + dir * dist;
        
        if (dist < 0.0001 || dist > 1000.0) {
            break;
        }
    }
    if (dist < 0.0001) {
        gl_FragColor = vec4(uv,0.5,1);
        //gl_FragColor = vec4(p,1);
        return;
    }
    
    else if (dist > 1000.0) {
        discard;    
    }

    else {
        discard;
    
    }


}