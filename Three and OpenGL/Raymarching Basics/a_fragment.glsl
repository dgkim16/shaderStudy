uniform vec2 resolution;
uniform bool normalColor;
uniform vec3 cameraPos;
uniform float u_time;
uniform vec3 spherePos;

in vec4 t_fragPos;


// ---- material ----
// https://www.cl.cam.ac.uk/teaching/1819/FGraphics/1.%20Ray%20Marching%20and%20Signed%20Distance%20Fields.pdf
// https://iquilezles.org/articles/smin/

// scale, rotate, then trasnlate
vec3 ptTransform(vec3 pt) {
    mat4 S = mat4(4.0, 0.0, 0.0, 0.0,
                  0.0, 1.0, 0.0, 0.0,
                  0.0, 0.0, 1.0, 0.0,
                  0.0, 0.0, 0.0, 1.0);
    
    /* 
    Rz(t), rotation on z axis
    vec4(cos(t), sin(t), 0, 0),
    vec4(-sin(t), cos(t), 0, 0),
    vec4(0, 0, 1, 0),
    vec4(0, 0, 0, 1));

    Ry(t), rotation on y axis
    vec4(cos(t), 0, sin(t), 0),
    vec4(0, 1, 0, 0),
    vec4(-sin(t), 0, cos(t), 0),
    vec4(0, 0, 0, 1));

    Rx(t), rotation on x axis
    vec4(1, 0, 0, 0),
    vec4(0, cos(t), -sin(t), 0),
    vec4(0, sin(t), cos(t), 0),
    vec4(0, 0, 0, 1));
    */

    mat4 R = mat4(1.0, 0.0, 0.0, 0.0,
                    0.0, 1.0, 0.0, 0.0,
                    0.0, 0.0, 1.0, 0.0,
                    0.0, 0.0, 0.0, 1.0);

    // translation. alter the last column
    mat4 T = mat4(1.0, 0.0, 0.0, 0.0,
                    0.0, 1.0, 0.0, 0.0,
                    0.0, 0.0, 1.0, 0.0,
                    0.0, 0.0, 0.0, 1.0);

    mat4 M = S * R * T;
    vec3 retPt = (vec4(pt, 1) * inverse(M)).xyz;
    return retPt;
}

float sdfSphere(vec3 p, float r) {
    return length(p) - r;
}


// modular spheres, infinite repetition
float sdfSphereM(vec3 p, float r) {
    float modX = mod(p.x+0.5,1.0)-0.5;
    float modY = mod(p.y+0.5,1.0)-0.5;
    float modZ = mod(p.z+0.5,1.0)-0.5;
    return length(vec3(modX,modY,modZ)) - r;
}

// just a cube
float sdfCube(vec3 p, vec3 dim) {
    vec3 d = abs(p) - dim;
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

// smooth union
float smin(float a, float b, float k) {
    k *= 1.0;
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

float sdf(vec3 p) {
    // ---- single object ----
    // return sdfSphere(p, 0.9);
    // return sdfSphereM(p, 0.25);

    // ---- union min(A,B) -----
    // return min(sdfSphere(p, .5), sdfCube(p + vec3(1,0,0), vec3(0.5)));

    // ---- intersection max(A,B) ----
    // return max(sdfSphere(p, .5), sdfCube(p, vec3(0.5)));
    // return max(sdfSphereM(p, 0.1), sdfCube(p, vec3(3.5)));

    // ---- difference max(-A,B) ----
    //return max(-sdfSphere(p, 0.6), sdfCube(p + vec3(0.2,0,0), vec3(0.5)));

    // ---- smooth union ----
    // return smin(sdfSphere(p - spherePos, 0.5), sdfCube(p, vec3(0.5)), 0.1);

    // ---- transforming sphere ----
    //return sdfSphere(ptTransform(p), 0.5);
    return sminSigm(sdfSphere(ptTransform(p) - spherePos, 0.5), sdfCube(p, vec3(0.5)), 0.1);
}


vec3 normal(vec3 p, float sd) {
    return normalize(vec3(
        sdf(p + vec3(0.001, 0.0, 0.0)) - sd,
        sdf(p + vec3(0.0, 0.001, 0.0)) - sd,
        sdf(p + vec3(0.0, 0.0, 0.001)) - sd
    ));
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
        vec4 color = vec4(0.0, 0.0, 0.0, 1.0);
        if (normalColor == true) {
            vec3 normal = normal(p, dist);
        //gl_FragColor = vec4(normal.x * uv.x, normal.y * uv.y ,0.5,1);
            float nL = normal.x * normal.y * normal.z * 0.5 + 0.5;
            color = vec4(uv.x * nL,uv.y * nL,nL,1);
        }
        else {
            color = vec4(uv.x, uv.y, 0.5, 1.0);
        }
        gl_FragColor = color;
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