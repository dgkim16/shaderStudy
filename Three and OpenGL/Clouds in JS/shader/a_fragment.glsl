uniform vec2 resolution;
uniform bool normalColor;
uniform bool isCloud;
uniform vec3 cameraPos;
uniform float u_time;
uniform vec3 spherePos;
uniform vec3 lightPos;

in vec4 t_fragPos;
#define PI 3.1415926535897932384626433832795


/* ------------------- Perlin Noise -----------------------
https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83
I need to put this in a separate file and include it in the shader.
But I don't know how to do that outside of Unity.

float rand(vec2 c){
	return fract(sin(dot(c.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float noise(vec2 p, float freq ){
	float unit = resolution.x/freq;
	vec2 ij = floor(p/unit);
	vec2 xy = mod(p,unit)/unit;
	//xy = 3.*xy*xy-2.*xy*xy*xy;
	xy = .5*(1.-cos(PI*xy));
	float a = rand((ij+vec2(0.,0.)));
	float b = rand((ij+vec2(1.,0.)));
	float c = rand((ij+vec2(0.,1.)));
	float d = rand((ij+vec2(1.,1.)));
	float x1 = mix(a, b, xy.x);
	float x2 = mix(c, d, xy.x);
	return mix(x1, x2, xy.y);
}

float pNoise(vec2 p, int res){
	float persistance = .5;
	float n = 0.;
	float normK = 0.;
	float f = 4.;
	float amp = 1.;
	int iCount = 0;
	for (int i = 0; i<50; i++){
		n+=amp*noise(p, f);
		f*=2.;
		normK+=amp;
		amp*=persistance;
		if (iCount == res) break;
		iCount++;
	}
	float nf = n/normK;
	return nf*nf*nf*nf;
}
*/
//	Classic Perlin 3D Noise 
//	by Stefan Gustavson
//
vec4 permute(vec4 x){return mod(((x*34.0)+1.0)*x, 289.0);}
vec4 taylorInvSqrt(vec4 r){return 1.79284291400159 - 0.85373472095314 * r;}
vec3 fade(vec3 t) {return t*t*t*(t*(t*6.0-15.0)+10.0);}
float cnoise(vec3 P){
    vec3 Pi0 = floor(P); // Integer part for indexing
    vec3 Pi1 = Pi0 + vec3(1.0); // Integer part + 1
    Pi0 = mod(Pi0, 289.0);
    Pi1 = mod(Pi1, 289.0);
    vec3 Pf0 = fract(P); // Fractional part for interpolation
    vec3 Pf1 = Pf0 - vec3(1.0); // Fractional part - 1.0
    vec4 ix = vec4(Pi0.x, Pi1.x, Pi0.x, Pi1.x);
    vec4 iy = vec4(Pi0.yy, Pi1.yy);
    vec4 iz0 = Pi0.zzzz;
    vec4 iz1 = Pi1.zzzz;

    vec4 ixy = permute(permute(ix) + iy);
    vec4 ixy0 = permute(ixy + iz0);
    vec4 ixy1 = permute(ixy + iz1);

    vec4 gx0 = ixy0 / 7.0;
    vec4 gy0 = fract(floor(gx0) / 7.0) - 0.5;
    gx0 = fract(gx0);
    vec4 gz0 = vec4(0.5) - abs(gx0) - abs(gy0);
    vec4 sz0 = step(gz0, vec4(0.0));
    gx0 -= sz0 * (step(0.0, gx0) - 0.5);
    gy0 -= sz0 * (step(0.0, gy0) - 0.5);

    vec4 gx1 = ixy1 / 7.0;
    vec4 gy1 = fract(floor(gx1) / 7.0) - 0.5;
    gx1 = fract(gx1);
    vec4 gz1 = vec4(0.5) - abs(gx1) - abs(gy1);
    vec4 sz1 = step(gz1, vec4(0.0));
    gx1 -= sz1 * (step(0.0, gx1) - 0.5);
    gy1 -= sz1 * (step(0.0, gy1) - 0.5);

    vec3 g000 = vec3(gx0.x,gy0.x,gz0.x);
    vec3 g100 = vec3(gx0.y,gy0.y,gz0.y);
    vec3 g010 = vec3(gx0.z,gy0.z,gz0.z);
    vec3 g110 = vec3(gx0.w,gy0.w,gz0.w);
    vec3 g001 = vec3(gx1.x,gy1.x,gz1.x);
    vec3 g101 = vec3(gx1.y,gy1.y,gz1.y);
    vec3 g011 = vec3(gx1.z,gy1.z,gz1.z);
    vec3 g111 = vec3(gx1.w,gy1.w,gz1.w);

    vec4 norm0 = taylorInvSqrt(vec4(dot(g000, g000), dot(g010, g010), dot(g100, g100), dot(g110, g110)));
    g000 *= norm0.x;
    g010 *= norm0.y;
    g100 *= norm0.z;
    g110 *= norm0.w;
    vec4 norm1 = taylorInvSqrt(vec4(dot(g001, g001), dot(g011, g011), dot(g101, g101), dot(g111, g111)));
    g001 *= norm1.x;
    g011 *= norm1.y;
    g101 *= norm1.z;
    g111 *= norm1.w;

    float n000 = dot(g000, Pf0);
    float n100 = dot(g100, vec3(Pf1.x, Pf0.yz));
    float n010 = dot(g010, vec3(Pf0.x, Pf1.y, Pf0.z));
    float n110 = dot(g110, vec3(Pf1.xy, Pf0.z));
    float n001 = dot(g001, vec3(Pf0.xy, Pf1.z));
    float n101 = dot(g101, vec3(Pf1.x, Pf0.y, Pf1.z));
    float n011 = dot(g011, vec3(Pf0.x, Pf1.yz));
    float n111 = dot(g111, Pf1);

    vec3 fade_xyz = fade(Pf0);
    vec4 n_z = mix(vec4(n000, n100, n010, n110), vec4(n001, n101, n011, n111), fade_xyz.z);
    vec2 n_yz = mix(n_z.xy, n_z.zw, fade_xyz.y);
    float n_xyz = mix(n_yz.x, n_yz.y, fade_xyz.x); 
    return 2.2 * n_xyz;
}


// ----------------------- SDF functions -----------------------
// ---- material ----
// https://www.cl.cam.ac.uk/teaching/1819/FGraphics/1.%20Ray%20Marching%20and%20Signed%20Distance%20Fields.pdf
// https://iquilezles.org/articles/smin/
// https://www.youtube.com/watch?v=oAS74MscuLY&list=PL3POsQzaCw53iK_EhOYR39h1J9Lvg-m-g&index=7

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
    //return sdfSphere(p, 0.9);
    //return sdfSphereM(p, 0.25);
    //return sdfCube(p, vec3(1));

    // ---- union min(A,B) -----
    // return min(sdfSphere(p, .5), sdfCube(p + vec3(1,0,0), vec3(0.5)));

    // ---- intersection max(A,B) ----
    // return max(sdfSphere(p, .5), sdfCube(p, vec3(0.5)));
    // return max(sdfSphereM(p, 0.1), sdfCube(p, vec3(3.5)));

    // ---- difference max(-A,B) ----
    //return max(-sdfSphere(p, 0.6), sdfCube(p + vec3(0.2,0,0), vec3(0.5)));

    // ---- smooth union ----
    return smin(sdfSphere(p - spherePos, 0.5), sdfCube(p, vec3(0.5)), 0.1);

    // ---- transforming sphere ----
    //return sdfSphere(ptTransform(p), 0.5);
    //return smin(sdfSphere(ptTransform(p) - spherePos, 0.5), sdfCube(p, vec3(0.5)), 0.1);
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

    if (!isCloud) {
        if (dist < 0.0001) {
            vec4 color = vec4(0.0, 0.0, 0.0, 1.0);
            if (normalColor == true) {
                vec3 normal = normal(p, dist);
            //gl_FragColor = vec4(normal.x * uv.x, normal.y * uv.y ,0.5,1);
                float nL = normal.x * normal.y * normal.z * 0.5 + 0.5;
                color = vec4(uv.x * nL,uv.y * nL,nL,1);
            }
            else {
                color = vec4(uv.x, uv.y, 0.5, 1.0) ;
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
    // Cloud rendering following this tutorial
    // https://www.youtube.com/watch?v=Qj_tK_mdRcA
    else {
        // p2 is where ray exits the object. For now it assumes the object does not have holes.
        vec3 p2 = cameraPos + dir * 100.0;
        float dist2 = 0.0;
        for (int i = 0; i < 50; i++) {
            dist2 = sdf(p2);
            p2 = p2 - dir * dist2;
            if (dist2 < 0.0001 || dist2 > 1000.0) {
                break;
            }
        }
        float enterExitDist = 0.0;
        float absorption = 0.2;
        float lightTransmittance = 1.0;
        if (dist < 0.0001 && dist2 < 0.0001)  {
            enterExitDist = length(p-p2);
            // ideally, one should fix the step size. step size used to change with distance.
            // To accomodate, before accumulating distance, the noise was scaled by the size of the step.
            // The 'denser' areas got amplified more.
            // fixed : used a fixed step size, and find a way to determine whether or not the next step taken is outside the cloud
            float step = 0.01;
            float iterations = enterExitDist / step;
            // dist3 is distance from point of entry into the cloud (from eye) to the point of exit from the cloud (in direction of camera view 'ray')
            float dist3 = 0.0;
            for(float i = 0.0; i < iterations; i++) {
                if(i * step > enterExitDist) {
                    break;
                }
                vec3 p3 = p + dir * step * i;
                
                if(lightTransmittance > 0.0) {
                    // At each point p3, I now need to compute how much light is reached. 
                    // low total sum of density cumulated while going through the cloud towards the light source  :==  brighter color
                    // assume light source is outside the cloud
                    // first find the point where light reaches the cloud, so we can stop cumulating when we reach that point.

                    
                    vec3 newDir = normalize(p3-lightPos);   // target = p3, source = lightPos
                    vec3 lightReachFacePos = lightPos;
                    float newStep = 0.01;
                    float lightReachFacePos_DistToFace = 5.0;
                    for(float j = 0.0; j < 50.0; j++) {
                        lightReachFacePos = lightPos + newDir * newStep * j;
                        lightReachFacePos_DistToFace = sdf(lightReachFacePos);
                        if(lightReachFacePos_DistToFace < 0.1)
                            break;
                    }
                    

                    /*
                    vec3 newDir = normalize(lightPos); // taking light source as directional light
                    vec3 lightReachFacePos = p3;
                    float newStep = 0.01;
                    float lightReachFacePos_DistToFace = 100.0;
                    // now we know where light first comes in contact with the cloud when apporaching to p3
                    for(float j = 0.0; j < 50.0; j++) {
                        lightReachFacePos = p3 + newDir * 0.01 * j;
                        lightReachFacePos_DistToFace = sdf(lightReachFacePos);
                        if(lightReachFacePos_DistToFace < 0.1) {
                            break;
                        }
                    }
                    */


                    vec3 p4 = p3;
                    float distTo_lightReachFacePos = length(p3-lightReachFacePos);
                    float iterationsToLight = distTo_lightReachFacePos / newStep;
                    float lightTravelDistPoint = 0.0;
                    float travelled = 0.0;
                    if (iterationsToLight > 10.0) {
                        newStep = distTo_lightReachFacePos / 10.0;
                        iterationsToLight = 10.0;
                    }
                    for(float j = 0.0; j < iterationsToLight; j++) {
                        p4 = p3 - newDir * newStep * j;
                        travelled += newStep;
                        // sample noise at p4
                        if(travelled < distTo_lightReachFacePos)
                            lightTravelDistPoint += max(cnoise(p4*5.0),0.0) ;
                        else
                        {
                            break;
                        }
                        // dist3 += dist4;
                    }

                    /*
                    // cloud gets less denser as we go away from center. No cloud if furhter than 0.5 units from center.
                    float distFromCenter = length(p3);
                    if(distFromCenter < 1.0) {
                        dist3 += abs(cnoise(p3*5.0) * (1.0 - distFromCenter));
                    }
                    */
                    dist3 += max(cnoise(p3*5.0) * sdfCube(p3, vec3(0.8)),0.0) * 0.25;
                    lightTransmittance -= (exp(-absorption * lightTravelDistPoint * iterations * 0.5));
                    if(lightTransmittance < 0.0) {
                        lightTransmittance = 0.0;
                    }
                }
            }


            // bear lambert law
            //float transmittance = min(max(1.0 - exp(-absorption * dist3), 0.0),1.0);
            float transmittance = 1.0 - exp(-absorption * dist3);
            lightTransmittance = 1.0 - lightTransmittance;


            vec4 color = vec4(0.0);
            if(normalColor == true) {
                color = vec4(uv.x * lightTransmittance, uv.y * lightTransmittance, lightTransmittance, lightTransmittance*transmittance);
            }
            else {
                color = vec4(lightTransmittance, lightTransmittance,lightTransmittance, lightTransmittance*transmittance + 0.01 );
            }
            gl_FragColor = color;
            return;
            /*
            float step = enterExitDist / 10.0;
            for(int i = 0; i < 10; i++) {
                vec3 p3 = p + dir * step * float(i);
                
            }
            */
        }
        else {
            discard;
        }
    }


}